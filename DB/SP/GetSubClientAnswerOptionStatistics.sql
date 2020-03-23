IF OBJECT_ID('dbo.GetSubClientAnswerOptionStatistics', 'P') IS NULL EXEC('Create Procedure dbo.GetSubClientAnswerOptionStatistics AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[GetSubClientAnswerOptionStatistics]
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

create table #clientStatus(
	clientID int, 
	clientCode nvarchar(50),
	clientName nvarchar(50),
	levelName nvarchar(50),
	TotalCount int,
	OptionID int,
	OptionTitle nvarchar(500),
	OptionCount int,
	OptionPercentage decimal(38,18)
)


declare @subClients table(
	ID int,
	Code nvarchar(50),
	Name nvarchar(50),
	LevelName nvarchar(50)
)

if @currentClientID>0
begin
	insert into @subClients
	select cc.ID,cc.Code,cc.Name,ss.Name as LevelName
	from APClients cc
	inner join APClientStructure ss on ss.LevelID=cc.LevelID
	where cc.ParentID=@currentClientID and cc.ProjectID=@projectID
end
else
begin
	declare @topClientID int
	select @topClientID=ID from APClients where projectID=@ProjectID and levelID=(select min(levelID) from dbo.APClientStructure where projectID=@ProjectID)

	insert into @subClients
	select cc.ID,cc.Code,cc.Name,ss.Name as LevelName
	from APClients cc
	inner join APClientStructure ss on ss.LevelID=cc.LevelID
	where cc.ParentID=@topClientID and cc.ProjectID=@projectID

	insert into @subClients
	select cc.ID,cc.Code,cc.Name,ss.Name as LevelName from APClients cc
	inner join APClientStructure ss on ss.LevelID=cc.LevelID
	where cc.LevelID=(select MAX(LevelID) from APClients where ProjectID=@projectID) and cc.ProjectID=@projectID and isnull(cc.ParentID,0)=0
end

while exists(select ID from @subClients)
begin
	declare @tempClientID int
	declare @clientCode nvarchar(50)
	declare @tempName nvarchar(50)
	declare @tempLevelName nvarchar(50)
	set rowcount 1
	select @tempClientID=ID,@clientCode=Code,@tempName=Name,@tempLevelName=LevelName from @subClients	
	set rowcount 0
		
	declare @allClients table(
		ID int
	)
	insert into @allClients
	select ID  from dbo.GetTerminalClients(@projectID,@tempClientID)

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

	delete  from @allClients

	declare @totalCount decimal(38,18)
	select @totalCount=cast(count(ID) as decimal(38,18)) from #answerOptions

	select oo.ID, oo.Title,
	sum(case when isnull(ao.OptionID,0)=0 then 0 else 1 end) as OptionCount 
	into #optionCount
	from APOptions oo
	left join #answerOptions ao on oo.ID=ao.OptionID
	where oo.QuestionID=@questionID
	group by  oo.ID, oo.Title

	insert into #clientStatus
	select @tempClientID,@clientCode,@tempName,@tempLevelName,@totalCount as TotalCount,ID,Title,OptionCount, case when @totalCount>0 then Cast(OptionCount as decimal(38,18)) / @totalCount else 0 end as OptionPercentage from #optionCount

	drop table #optionCount
	drop table #answerOptions
	
	delete from @subClients where ID=@tempClientID
end

declare @sql varchar(max)
set @sql='select ClientID,ClientCode,ClientName,TotalCount,'

select ID into #options from APOptions where QuestionID=@questionID order by ID
while exists(select ID from #options)
begin
	declare @tempOptionID int
	set rowcount 1
	select @tempOptionID=ID from #options
	set rowcount 0

	set @sql=@sql + 'sum(case when OptionID=' + cast(@tempOptionID as nvarchar(50)) + ' then OptionCount else 0 end) as ''' + cast(@tempOptionID as nvarchar(50)) + '_Count'','
	set @sql=@sql + 'sum(case when OptionID=' + cast(@tempOptionID as nvarchar(50)) + ' then OptionPercentage else 0 end) as ''' + cast(@tempOptionID as nvarchar(50)) + '_Percentage'','

	delete from #options where ID=@tempOptionID
end

drop table #options

set @sql= @sql+'1 as ''1'' from #clientStatus group by ClientID,ClientCode,ClientName,TotalCount'

exec (@sql)

drop table #clientStatus

END