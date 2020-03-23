IF OBJECT_ID('dbo.GetAnswerOptionStatistics', 'P') IS NULL EXEC('Create Procedure dbo.GetAnswerOptionStatistics AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[GetAnswerOptionStatistics]
	@projectID int,
	@questionnaireID int,
	@questionID int,
	@fromDate datetime,
	@toDate datetime,
	@currentClientID int
AS
BEGIN

/*
declare @projectID int
declare @questionnaireID int
declare @questionID int
declare @fromDate datetime
declare @toDate datetime
declare @currentClientID int

set @projectID=35
set @questionnaireID=1119
set @questionID=18998
set @fromDate='2019-5-1'
set @toDate='2019-5-31'
set @currentClientID=0
*/

declare @allClients table(
	ID int
)

if @currentClientID>0
begin
	insert into @allClients
	select ID from dbo.GetTerminalClientIDs(@projectID,@currentClientID)
end
else
begin
	insert into @allClients
	select ID from APClients where LevelID=(select MAX(LevelID) from APClients where ProjectID=@projectID) and ProjectID=@projectID
end

select rr.ID,ao.OptionID 
into #answerOptions
from APAnswerOptions ao 
inner join APAnswers aa on aa.ID=ao.AnswerID
inner join APQuestionnaireResults rr on rr.ID=aa.ResultID
inner join @allClients cc on rr.ClientID=cc.ID
where aa.QuestionID=@questionID
and rr.QuestionnaireID=@questionnaireID 
and rr.FromDate=@fromDate 
and rr.ToDate=@toDate

declare @totalCount decimal(38,18)
select @totalCount=cast(count(ID) as decimal(38,18)) from #answerOptions

select oo.ID, oo.Title,
sum(case when isnull(ao.OptionID,0)=0 then 0 else 1 end) as OptionCount 
into #optionCount
from APOptions oo
left join #answerOptions ao on oo.ID=ao.OptionID
where oo.QuestionID=@questionID
group by  oo.ID, oo.Title

select *,@totalCount as TotalCount, case when @totalCount>0 then Cast(OptionCount as decimal(38,18)) / @totalCount else 0 end as OptionPercentage from #optionCount

drop table #optionCount
drop table #answerOptions

END