IF OBJECT_ID('dbo.GetQuestionnaireResults_Answers', 'P') IS NULL EXEC('Create Procedure dbo.GetQuestionnaireResults_Answers AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[GetQuestionnaireResults_Answers]
	@ProjectID int,
	@QuestionnaireID int,
	@ClientID int,
	@FromDate datetime,
	@ToDate datetime,
	@Status int,
	@PageFrom int,
	@PageTo int
AS
BEGIN
/*
declare @ProjectID int
declare @QuestionnaireID int
declare @ClientID int
declare @FromDate datetime
declare @ToDate datetime
declare @Status int
declare @PageFrom int
declare @PageTo int

set @ProjectID=40
set @QuestionnaireID=1131
set @ClientID=0
set @FromDate='2019-7-1'
set @ToDate='2019-7-31'
set @Status = 8

set @PageFrom=1
set @PageTo=10000
*/

declare @columntable table(
	Name nvarchar(50),
	Value int,
	TypeID int
)

select LevelID,Name into #clientStructure
from APClientStructure where ProjectID=@ProjectID
order by LevelID

while exists(select name from #clientStructure)
begin
	declare @levelID int
	declare @name nvarchar(50)
	set rowcount 1
	select @levelID=LevelID,@name=Name from #clientStructure
	set rowcount 0
	
	insert into @columntable (Name,Value,TypeID)
	select @name,@levelID,1
	
	delete from #clientStructure where @levelID=LevelID and @name=Name
end
drop table #clientStructure

select ID,Code,Title,QuestionType into #questions
from APQuestions where QuestionnaireID=@QuestionnaireID and QuestionType<>7
order by Code

select * into #tempQuestions from #questions

while exists(select ID from #tempQuestions)
begin
	declare @ID int
	declare @Code nvarchar(50)
	set rowcount 1
	select @ID=ID,@Code=Code from #tempQuestions
	set rowcount 0
	
	insert into @columntable (Name,Value,TypeID)
	select @Code,@ID,2
	
	delete from #tempQuestions where @ID=ID
end

drop table #tempQuestions

select 
rr.ID as '编号',
uu.UserName as '访问员',
CONVERT(nvarchar(10),rr.VisitBeginTime, 120 ) as '访问日期',
CONVERT(varchar(5),rr.VisitBeginTime, 108) as '开始时间',
CONVERT(varchar(5),rr.VisitEndTime, 108) as '结束时间',
rr.ClientID as '客户编号',
rr.[Status],
bc.ItemValue as '执行状态',
cc.Code,
rr.[Address] as '地理信息',
rr.[LastAuditNote] as '最近审核备注',
cc.Postcode,
rr.OtherPlatformID,
rr.Description as '备注'
into #baseDataTemp
from APQuestionnaireResults rr
inner join APClients cc on cc.ID=rr.ClientID
left join APUsers uu on uu.ID=rr.VisitUserID
left join BusinessConfiguration bc on bc.ItemKey=rr.[Status] and bc.ItemDesc='QuestionnaireStageStatus'
where rr.QuestionnaireID=@QuestionnaireID
and rr.ToDate>=@FromDate
and rr.FromDate<=@ToDate
order by rr.ID

if @ClientID>0
begin
	delete from #baseDataTemp where [客户编号] not in 
	(
		select distinct ID from GetTerminalClientIDs(cast(@ProjectID as nvarchar(50)),cast(@ClientID as nvarchar(50)))
	)
end

if @Status=-1
begin
	delete from #baseDataTemp where [编号] not in (select [编号] from #baseDataTemp where [Status]>1)
end
else if @Status>-1
begin
	delete from #baseDataTemp where [编号] not in (select [编号] from #baseDataTemp where [Status]=@Status)
end

select [编号],[访问员],[访问日期],[开始时间],[结束时间],[客户编号],[执行状态],[地理信息],[最近审核备注],Postcode,OtherPlatformID,[备注]
into #baseData
from (
	select row_number()over(order by [编号]) as rownumber,*
	from #baseDataTemp
) a
where rownumber>=@PageFrom and rownumber<=@PageTo

drop table #baseDataTemp



select  
aa.ID as AnswerID,
rr.[编号] as ResultID,
ap.ID as QuestionID,
ap.Code as Code,
case when ap.QuestionType=4 then ao.OptionText
	when isnull(ao.OptionText,'')<>'' then isnull(oo.Title,'') +' ('+ ao.OptionText+')' 
	else oo.Title 
end as OptionText,
aa.Description
into #tempAnswers
from APAnswers aa
inner join #baseData rr on rr.[编号]=aa.ResultID
inner join #questions ap on aa.QuestionID=ap.ID
left join APAnswerOptions ao on ao.AnswerID=aa.ID
left join APOptions oo on ao.OptionID=oo.ID
order by rr.[编号],ap.ID



select 
AnswerID,
ResultID,
QuestionID,
Code,
Description,
stuff(
	(
		select ';' + OptionText
		from #tempAnswers t2
		where t1.ResultID=t2.ResultID and t1.QuestionID=t2.QuestionID
		for xml path('')
),1,1,'') as AnswerText
into #baseAnswers
from #tempAnswers t1
group by AnswerID,ResultID,QuestionID,Code,Description

drop table #tempAnswers

--update #baseAnswers set AnswerText=AnswerText + '(扣分描述：' + Description +  ')' where Description is not NULL and Description<>''

select Name,Value into #columnClients
from @columntable
where TypeID=1

declare @sql_str varchar(max)
set @sql_str = N'Select *'
while exists(select name from #columnClients)
begin
	declare @levelName nvarchar(50)
	declare @tempLevelID int
	set rowcount 1
	select @levelName=Name,@tempLevelID=Value from #columnClients
	set rowcount 0
	
	set @sql_str = @sql_str + N',dbo.GetClientName([客户编号],'+cast(@tempLevelID as nvarchar(50))+') as ''' + @levelName + '''' + ',dbo.GetClientCode([客户编号],'+cast(@tempLevelID as nvarchar(50))+') as ''' + @levelName + '代码'''
	delete from #columnClients where value=@tempLevelID
end

--select Value as ID, Name as Code into #columnQuestions
--from @columntable
--where TypeID=2

set @sql_str = @sql_str + N' from #baseData'

exec (@sql_str)
select * from #baseAnswers
select * from #questions
--取所有图片
select dd.ID, dd.RelatedID, dd.FileName, dd.RelevantPath 
from DocumentFiles dd 
inner join #baseAnswers aa on aa.ResultID=dd.ResultID and aa.AnswerID=dd.RelatedID

drop table #columnClients
drop table #questions
drop table #baseData
drop table #baseAnswers

END