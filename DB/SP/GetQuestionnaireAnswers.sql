IF OBJECT_ID('dbo.GetQuestionnaireAnswers', 'P') IS NULL EXEC('Create Procedure dbo.GetQuestionnaireAnswers AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[GetQuestionnaireAnswers]
	@resultID int
AS
BEGIN

/*
declare @resultID int
set @resultID=2914
*/

declare @NULLString nvarchar(max)
set @NULLString=''

declare @QustionnaireID int
select @QustionnaireID=QuestionnaireID from [APQuestionnaireResults] where ID=@resultID
select * into #tempAnswers from APAnswers where ResultID=@resultID
select * into #tempAnswerOptions from APAnswerOptions where AnswerID in (select ID from #tempAnswers)

select que.ID,que.Code,que.ParentCode,que.Title,
case when que.CountType<>2 then que.TotalScore 
else 0 end as Score,
aa.TotalScore,que.QuestionType,que.CountType,que.bAllowImage,que.bAllowAudio,que.bAllowVideo,que.bMustImage,que.bMustAudio,que.bMustVideo,
aa.ID as AnswerID,
case when que.QuestionType=4 then ao.OptionText
	 when isnull(ao.OptionText,'')<>'' then isnull(oo.Title,'') +' ('+ ao.OptionText+')' 
	else oo.Title 
end as OptionText,
isnull(oo.bCorrectOption,0) as bCorrectOption,
isnull(aa.Description,'') as AnswerDescription
into #tempQuestions
from APQuestions que 
left join #tempAnswers aa on aa.QuestionID=que.ID
left join #tempAnswerOptions ao on ao.AnswerID=aa.ID
left join [dbo].[APOptions] oo on oo.ID=ao.OptionID
where que.QuestionnaireID=@QustionnaireID
order by que.Code


select que.ID,que.ParentCode,que.Code,que.Title,que.Score,que.TotalScore,que.QuestionType,que.CountType,que.AnswerID,que.AnswerDescription,
sum(case when que.bCorrectOption=0 then 1 else 0 end) as WrongOptionNumber,
stuff(
(
	select '\r\n' + OptionText
	from #tempQuestions
	where ID=que.ID
	and Code=que.Code
	and Title=que.Title
	and TotalScore=que.TotalScore
	and AnswerID=que.AnswerID
	order by Code
	for xml path('')
),1,4,'') as OptionText,
--REPLACE(stuff((select tb.Title + ';'+(case when tb.score<>0 then ' (' + cast( cast(tb.score as real) as nvarchar(50)) + ')' else '' end)+'<br/>' from APOptions tb where tb.QuestionID=que.ID for xml path('')), 1, 0, ''),'&lt;br/&gt;','<br/>') as Options,
--REPLACE(stuff((select tb.Title + ';<br/>' from APOptions tb where ((que.CountType<>6 and tb.bCorrectOption=0) or (que.CountType=6 and abs(isnull(tb.Score,0))>0)) and tb.QuestionID=que.ID for xml path('')), 1, 0, ''),'&lt;br/&gt;','<br/>') as WrongOptions,
@NULLString as Options,
@NULLString as WrongOptions,
que.bAllowImage,
que.bAllowAudio,
que.bAllowVideo,
@NULLString as OptionIDs
into #tempResult
from #tempQuestions que
group by que.ID,que.ParentCode,que.Code,que.Title,que.Score,que.TotalScore,que.QuestionType,que.CountType,que.AnswerID,que.AnswerDescription,que.bAllowImage,que.bAllowAudio,que.bAllowVideo

update #tempResult set WrongOptionNumber=0
from #tempResult tt inner join 
(
	--判断单选题是否存在正确选项
	select oo.QuestionID,sum(case when oo.bCorrectOption=1 then 1 else 0 end) as correctNumber from APOptions oo inner join #tempResult tr on oo.QuestionID=tr.ID
	where tr.QuestionType=2
	group by oo.QuestionID
) oo2 on oo2.QuestionID=tt.ID
where oo2.correctNumber<=0


/*

declare @tempDeleteIDs table (ID int)
--跳转逻辑处理
select rr.ID, oo.ID as OptionID, oo.JumpQuestionCode, rr.OptionIDs, rr.AnswerID into #options from #tempResult rr
inner join APOptions oo on oo.QuestionID=rr.ID
where isnull(oo.JumpQuestionCode,'')<>''

select ROW_NUMBER() over(order by Code) as RowIndex,*
into #jumpTempResult
from #tempResult


while exists(select OptionID from #options)
begin
	declare @tmpID int
	declare @tmpOptionID int
	declare @tmpOptionIDs nvarchar(max)
	declare @tmpCode nvarchar(50)
	declare @tmpAnswerID int
	set rowcount 1
	select @tmpID=ID,@tmpOptionID=OptionID,@tmpOptionIDs=OptionIDs,@tmpCode=JumpQuestionCode,@tmpAnswerID=AnswerID from #options
	set rowcount 0

	--跳转题目验证分4步：1）确认当前题目的答案是否选中需要跳转的选项 2）从当前题目开始向后查找到跳转的题目 3）记录从当前题目到找到的跳转题目中间的所有题目 4）删除记录的中间题目
	declare @tickJumpOption bit
	set @tickJumpOption=1
	if CHARINDEX(cast(@tmpOptionID as nvarchar(50)),@tmpOptionIDs)<=0
	begin
		if not exists(select ID from APAnswerOptions where AnswerID=@tmpAnswerID and OptionID=@tmpOptionID)
		begin
			set @tickJumpOption=0
		end
	end
	
	if @tickJumpOption=1
	begin
		declare @tempIndex int
		select @tempIndex=RowIndex from #jumpTempResult where ID=@tmpID

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
		--select * from @tempDeleteIDs

		if @findJumpFlag=1
		begin
			delete from #tempResult where ID in (select ID from @tempDeleteIDs)
		end
		delete from @tempDeleteIDs
	end
	delete from #options where OptionID=@tmpOptionID
end
drop table #options
drop table #jumpTempResult

--关联逻辑处理
select rr.ID,que.LinkQuestionID,que.LinkOptionID into #linkQuestions from #tempResult rr
inner join APQuestions que on que.ID=rr.ID
where que.LinkOptionID>0

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
	--关联题目验证分3步：1）验证关联的题目是否在结果中存在 2）验证关联的选项是否在默认正确选项（OptionIDs）中存在 3）验证Answer中是否有相应选项
	if not exists(select ID from #tempResult where ID=@tempQuestionID)
	begin
		set @deleteFlag=1
	end
	else
	begin
		declare @tempOptionIDs nvarchar(max)
		declare @tempAnswerID int
		select @tempOptionIDs=OptionIDs,@tempAnswerID=AnswerID from #tempResult where ID=@tempQuestionID
		if CHARINDEX(cast(@tempOptionID as nvarchar(50)),@tempOptionIDs)<=0
		begin
			if not exists(select ID from APAnswerOptions where AnswerID=@tempAnswerID and OptionID=@tempOptionID)
			begin
				set @deleteFlag=1
			end
		end
	end

	if @deleteFlag=1
	begin
		insert into @tempDeleteIDs
		exec [dbo].[GetAllSubQuestionsByID] @tempID

		insert into @tempDeleteIDs
		select @tempID
	end

	delete from #linkQuestions where ID=@tempID
end
delete from #tempResult where ID in (select ID from @tempDeleteIDs)
delete from @tempDeleteIDs
drop table #linkQuestions
*/

/*calculate parent question score*/
declare @zeroDecimal decimal(38,18)
set @zeroDecimal=0
select parentcode, SUM(totalscore) as totalscore into #scores from #tempResult where questiontype<>7 group by parentCode
while exists(select * from #scores)
begin
	declare @code nvarchar(50)
	declare @score decimal(38,18)
	set rowcount 1
	select @code=parentcode,@score=totalscore from #scores
	set rowcount 0
	
	update #tempResult set totalscore=@score where code=@code
	
	declare @parentcode nvarchar(50)
	select @parentcode=parentcode from #tempResult where code=@code
	while isnull(@parentcode,'')<>''
	begin
		update #tempResult set totalscore=isnull(totalscore,@zeroDecimal)+@score where code=@parentcode
		select @parentcode=parentcode from #tempResult where code=@parentcode
	end
	
	delete from #scores where parentcode=@code
end
drop table #scores
 
select doc.* into #tempDocs from DocumentFiles doc
--left join #tempAnswers tt on tt.ID=doc.RelatedID
where doc.ResultID=@resultID

select rr.ID,rr.ParentCode,rr.Code,rr.Title,rr.Score,rr.TotalScore,rr.QuestionType,rr.CountType,rr.AnswerID,rr.AnswerDescription,rr.Options,rr.WrongOptions,rr.OptionText,rr.OptionIDs,
rr.bAllowImage,rr.bAllowAudio,rr.bAllowVideo,rr.WrongOptionNumber,
(select COUNT(doc.ID) from #tempDocs doc where (doc.RelatedID=rr.AnswerID or (doc.TempCode=(cast(@resultID*100 as nvarchar(50)) + ' ' + cast(rr.ID*100 as nvarchar(50))))) and doc.TypeID=3 and doc.Status=0) as UploadFileNumber,
(select COUNT(doc.ID) from #tempDocs doc where doc.RelatedID=rr.AnswerID and doc.TypeID=4 and doc.Status=0) as AuditFileNumber,
(select COUNT(doc.ID) from #tempDocs doc where doc.RelatedID=rr.AnswerID and doc.TypeID=5 and doc.Status=0) as ClientFileNumber
into #tempResultAuditNotes
from #tempResult rr
group by rr.ID,rr.ParentCode,rr.Code,rr.Title,rr.Score,rr.TotalScore,rr.QuestionType,rr.CountType,rr.AnswerID,rr.AnswerDescription,rr.Options,
rr.WrongOptions,rr.OptionText,rr.OptionIDs,rr.bAllowImage,rr.bAllowAudio,rr.bAllowVideo,rr.WrongOptionNumber
order by rr.Code

drop table #tempDocs
drop table #tempAnswers
drop table #tempAnswerOptions

/*
declare @auditNotes nvarchar(max)
declare @clientNotes nvarchar(max)
set @auditNotes=''
set @clientNotes=''
*/

select * into #tempAuditNotes from APQuestionAuditNotes where ResultID=@resultID

select rr.ID,rr.ParentCode,rr.Code,rr.Title,rr.Score,rr.TotalScore,rr.QuestionType,rr.CountType,rr.AnswerID,rr.AnswerDescription,rr.Options,rr.WrongOptions,rr.OptionText,rr.OptionIDs,rr.bAllowImage,rr.bAllowAudio,rr.bAllowVideo,
rr.UploadFileNumber,rr.AuditFileNumber,rr.ClientFileNumber,rr.WrongOptionNumber,
stuff(
(
	select '\r\n' + ('[' + uu.Name + ']: ' + aa.AuditNotes + ' ' + CONVERT(nvarchar(16), aa.CreateTime, 120))
	from #tempAuditNotes aa
	left join APUserRole uu on uu.ID=aa.UserTypeID
	where aa.QuestionID=rr.ID and aa.ResultID=@ResultID and aa.AuditTypeID in (3,6) --Diego changed at 2018-4-25
	order by aa.CreateTime
	for xml path('')
),1,4,'') as AuditNotes,
stuff(
(
	select '\r\n' + ('[' + uu.UserName + ']: ' + aa.AuditNotes + ' ' + CONVERT(nvarchar(16), aa.CreateTime, 120))
	from #tempAuditNotes aa
	left join APUsers uu on uu.ID=aa.CreateUserID
	where aa.QuestionID=rr.ID and aa.ResultID=@ResultID and aa.AuditTypeID in (4,5)
	order by aa.CreateTime
	for xml path('')
),1,4,'') as ClientNotes

from #tempResultAuditNotes rr
group by rr.ID,rr.ParentCode,rr.Code,rr.Title,rr.Score,rr.TotalScore,rr.QuestionType,rr.CountType,rr.AnswerID,rr.AnswerDescription,rr.Options,rr.WrongOptions,rr.OptionText,rr.OptionIDs,rr.bAllowImage,rr.bAllowAudio,rr.bAllowVideo,
rr.UploadFileNumber,rr.AuditFileNumber,rr.ClientFileNumber,rr.WrongOptionNumber
order by rr.Code

drop table #tempAuditNotes
drop table #tempQuestions
drop table #tempResult
drop table #tempResultAuditNotes

END