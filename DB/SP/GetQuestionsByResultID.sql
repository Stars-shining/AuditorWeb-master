IF OBJECT_ID('dbo.GetQuestionsByResultID', 'P') IS NULL EXEC('Create Procedure dbo.GetQuestionsByResultID AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[GetQuestionsByResultID]
	@resultID int
AS
BEGIN
/*
declare @resultID int
set @resultID=3088
*/
	
	select que.*
	  ,(CAST(@resultID*100 as nvarchar(50)) + ' ' + CAST(que.ID*100 as nvarchar(50))) as TempCode
	  ,isnull(aa.TotalScore,0) as AnswerScore
	  into #temp
	from APQuestions que
	inner join APQuestionnaireResults rr on rr.QuestionnaireID=que.QuestionnaireID and rr.ID=@resultID
	left join APAnswers aa on aa.ResultID=@resultID and aa.QuestionID=que.ID
	where que.Status=1
	order by que.code

	select que.[ID]
      ,que.[Code]
      ,que.[Title]
      ,que.[ParentCode]
      ,que.[TotalScore]
      ,que.[CountType]
      ,que.[QuestionType]
      ,que.[bAllowImage]
      ,que.[bAllowAudio]
      ,que.[bAllowVideo]
      ,que.[bMustImage]
      ,que.[bMustAudio]
      ,que.[bMustVideo]
      ,que.[Description]
      ,que.[QuestionnaireID]
      ,que.[LinkQuestionID]
      ,que.[LinkOptionID]
      ,que.[CreateTime]
      ,que.[CreateUserID]
      ,que.[LastModifiedTime]
      ,que.[LastModifiedUserID]
      ,que.[Status]
	  ,que.[TempCode]
	  ,que.[AnswerScore]
	  ,COUNT(doc.ID) as UploadFileNumber
	  ,Sum(case when doc.FileType=1 then 1 else 0 end) as UploadFileNumber_Image
	  ,Sum(case when doc.FileType=2 then 1 else 0 end) as UploadFileNumber_Audio
	  ,Sum(case when doc.FileType=3 then 1 else 0 end) as UploadFileNumber_Video
	into #tempQuestions
	from #temp que
	left join DocumentFiles doc on doc.TempCode=que.TempCode
	group by  que.[ID]
      ,que.[Code]
      ,que.[Title]
      ,que.[ParentCode]
      ,que.[TotalScore]
      ,que.[CountType]
      ,que.[QuestionType]
      ,que.[bAllowImage]
      ,que.[bAllowAudio]
      ,que.[bAllowVideo]
      ,que.[bMustImage]
      ,que.[bMustAudio]
      ,que.[bMustVideo]
      ,que.[Description]
      ,que.[QuestionnaireID]
      ,que.[LinkQuestionID]
      ,que.[LinkOptionID]
      ,que.[CreateTime]
      ,que.[CreateUserID]
      ,que.[LastModifiedTime]
      ,que.[LastModifiedUserID]
      ,que.[Status]
	  ,que.[TempCode]
	  ,que.[AnswerScore]
	order by que.code

	select oo.* into #tempOptions
	from APOptions oo
	inner join APQuestions que on oo.QuestionID=que.ID
	inner join APQuestionnaireResults rr on rr.QuestionnaireID=que.QuestionnaireID and rr.ID=@resultID
	where que.Status=1
	order by que.code,oo.ID

	declare @tempDeleteIDs table (ID int)

	--跳转逻辑处理
	select ID,QuestionID,JumpQuestionCode into #options from #tempOptions
	where isnull(JumpQuestionCode,'')<>''

	select ROW_NUMBER() over(order by Code) as RowIndex,*
	into #jumpTempResult
	from #tempQuestions

	while exists(select ID from #options)
	begin
		declare @tmpID int
		declare @tmpQuestionID int
		declare @tmpCode nvarchar(50)
		set rowcount 1
		select @tmpID=ID,@tmpQuestionID=QuestionID,@tmpCode=JumpQuestionCode from #options
		set rowcount 0

		--跳转题目验证分4步：1）确认当前题目的答案是否选中需要跳转的选项 2）从当前题目开始向后查找到跳转的题目 3）记录从当前题目到找到的跳转题目中间的所有题目 4）删除记录的中间题目
		declare @tempIndex int
		select @tempIndex=RowIndex from #jumpTempResult where ID=@tmpQuestionID
		select ID,Code into #tempSearch from #jumpTempResult where RowIndex>@tempIndex
	
		declare @findJumpFlag bit
		set @findJumpFlag=0
		while exists(select ID from #tempSearch)
		begin
			declare @currentCode nvarchar(50)
			declare @currentID int
			set rowcount 1
			select @currentID=ID, @currentCode=Code from #tempSearch
			set rowcount 0

			if @currentCode=@tmpCode
			begin
				set @findJumpFlag=1
				break;
			end
			else
			begin
				insert into @tempDeleteIDs
				select @currentID
			end
			
			delete from #tempSearch where @currentID=ID and @currentCode=Code
		end

		drop table #tempSearch

		if @findJumpFlag=1
		begin
			delete from #tempQuestions where ID in (select ID from @tempDeleteIDs)
			delete from #tempOptions where QuestionID in (select ID from @tempDeleteIDs)
		end

		delete from @tempDeleteIDs
		delete from #options where ID=@tmpID
	end

	drop table #options
	drop table #jumpTempResult

		--关联逻辑处理
	select ID,LinkQuestionID,LinkOptionID into #linkQuestions from #tempQuestions
	where LinkOptionID>0

	while exists(select ID from #linkQuestions)
	begin
		declare @tempID int
		declare @tempQuestionID int
		declare @tempOptionID int
	
		set rowcount 1
		select @tempID=ID,@tempQuestionID=LinkQuestionID,@tempOptionID=LinkOptionID from #linkQuestions
		set rowcount 0

		declare @deleteFlag bit
		set @deleteFlag=0
		--关联题目验证，验证关联的题目是否在默认正确的结果中存在
		if not exists(select ID from #tempOptions where ID=@tempOptionID and QuestionID=@tempQuestionID)
		begin
			insert into @tempDeleteIDs
			exec [dbo].[GetAllSubQuestionsByID] @tempID

			insert into @tempDeleteIDs
			select @tempID
		end

		delete from #linkQuestions where ID=@tempID
	end
	delete from #tempQuestions where ID in (select ID from @tempDeleteIDs)
	delete from #tempOptions where QuestionID in (select ID from @tempDeleteIDs)
	delete from @tempDeleteIDs
	drop table #linkQuestions

	select * from #tempQuestions
	select * from #tempOptions

	select tt.ID,tt.QuestionType,ao.OptionID,isnull(ao.OptionText ,'') as OptionText
	from #tempQuestions tt 
	inner join APAnswers aa on aa.ResultID=@resultID and aa.QuestionID=tt.ID
	inner join APAnswerOptions ao on aa.ID=ao.AnswerID

	drop table #temp
	drop table #tempQuestions
	drop table #tempOptions
	 
END