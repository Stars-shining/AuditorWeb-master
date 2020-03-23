IF OBJECT_ID('dbo.GetQuestionnaireDefaultCorrectOptions', 'P') IS NULL EXEC('Create Procedure dbo.GetQuestionnaireDefaultCorrectOptions AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[GetQuestionnaireDefaultCorrectOptions]
	@QuestionnaireID int
AS
BEGIN

/*
declare @QuestionnaireID int
set @QuestionnaireID=15
*/

select ID,Code,TotalScore,LinkQuestionID,LinkOptionID,QuestionType into #tempQuestions from APQuestions where QuestionnaireID=@QuestionnaireID order by Code
select oo.*,que.Code into #tempOptions from APOptions oo
inner join #tempQuestions que on que.ID=oo.QuestionID
where oo.bCorrectOption=1
order by que.Code,oo.ID

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


select * from #tempQuestions where QuestionType in (1,2,3)
select * from #tempOptions

drop table #tempQuestions
drop table #tempOptions

END