IF OBJECT_ID('dbo.GetQuestionnaireCheckListQCLeader', 'P') IS NULL EXEC('Create Procedure dbo.GetQuestionnaireCheckListQCLeader AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[GetQuestionnaireCheckListQCLeader]
	@ProjectID int,
	@ClientID int,
	@QuestionnaireID int,
	@StatusID int,
	@Province nvarchar(50),
	@City nvarchar(50),
	@District nvarchar(50),
	@FromDate datetime,
	@ToDate datetime,
	@StageStatusID int,
	@Keyword nvarchar(50)
AS
BEGIN
/*
declare @ProjectID int
declare @ClientID int
declare @QuestionnaireID int
declare @StatusID int
declare @Province nvarchar(50)
declare @City nvarchar(50)
declare @District nvarchar(50)
declare @FromDate datetime
declare @ToDate datetime
declare @StageStatusID int
declare @Keyword nvarchar(50)

set @ProjectID=2
set @ClientID=7
set @QuestionnaireID=NULL
set @StatusID=-999
set @Province='-999'
set @City='-999'
set @District='-999'
set @FromDate='1900-01-01'
set @ToDate='2900-01-01'
set @StageStatusID=2
set @Keyword=''
*/

if @Province='-999' or @Province=''
begin
	set @Province=NULL
end

if @City='-999' or @City=''
begin
	set @City=NULL
end

if @District='-999' or @District=''
begin
	set @District=NULL
end

select * into #tempTerminalClients from GetTerminalClients(@ProjectID,@ClientID)

select client.ID as ClientID,
client.Code,
client.Name as ClientName,
isnull(province.Name,'') as ProvinceName,
isnull(city.Name,'') as CityName,
isnull(district.Name,'') as DistrictName,
client.Province,
client.City,
client.District
into #tempClients
from #tempTerminalClients client
left join dbo.APCity province on province.Code=client.Province
left join dbo.APCity city on city.Code=client.City
left join dbo.APCity district on district.Code=client.District
--where isnull(client.Province,0)=ISNULL(@Province, isnull(client.Province,0))
--and isnull(client.City,0)=ISNULL(@City, isnull(client.City,0))
--and isnull(client.District,0)=ISNULL(@District, isnull(client.District,0))

drop table #tempTerminalClients

if isnull(@Keyword,'')<>''
begin
	delete from #tempClients where ClientID not in (select ClientID from #tempClients where Code like '%'+@Keyword+'%' or ClientName like '%'+@Keyword+'%')
end
if isnull(@Province,'')<>''
begin
	delete from #tempClients where ClientID not in (select ClientID from #tempClients where Province=@Province)
end
if isnull(@City,'')<>''
begin
	delete from #tempClients where ClientID not in (select ClientID from #tempClients where City=@City)
end
if isnull(@District,'')<>''
begin
	delete from #tempClients where ClientID not in (select ClientID from #tempClients where District=@District)
end

declare @EachFromDate datetime 
declare @EachToDate datetime 
declare @QuestionnairePeriods table
(	
	QuestionnaireID int,
	Name nvarchar(50),
	FromDate datetime,
	ToDate datetime,
	Period nvarchar(50)
)

select ID,Name,FromDate,ToDate,Frequency into #tempQuestionnaires from APQuestionnaires 
where ProjectID=@ProjectID 
and isnull(DeleteFlag,0)=0
and ISNULL(@QuestionnaireID,ID)=ID
order by FromDate

while exists(select ID from #tempQuestionnaires)
begin
	declare @tempID int
	declare @name nvarchar(50)
	SET ROWCOUNT 1
	select @tempID=ID,@name=Name from #tempQuestionnaires
	SET ROWCOUNT 0
	
	insert into @QuestionnairePeriods (FromDate,ToDate,Period)
	exec dbo.[GetQuestionnairePeriods] @tempID
		
	update @QuestionnairePeriods set QuestionnaireID=@tempID,Name=@name where QuestionnaireID is null
	
	delete from #tempQuestionnaires where ID=@tempID
end

select * into #tempResults
from #tempClients cross join @QuestionnairePeriods
order by Period,ClientName

select tt.*, 
dd.ID as ResultID, 
isnull(dd.QCLeaderAuditStatus,0) as QCLeaderAuditStatus,
case when ISNULL(dd.ID,0)<=0 then 0 else dd.Status end as StatusID,
ISNULL(dd.Score,0) as Score,
dd.UploadBeginTime
into #result
from #tempResults tt 
left join dbo.APQuestionnaireResults dd on tt.QuestionnaireID=dd.QuestionnaireID
and tt.ClientID=dd.ClientID
and tt.FromDate=dd.FromDate
and tt.ToDate=dd.ToDate
where dd.ProjectID=@ProjectID

select rr.*,
bc1.ItemValue as StatusName,
bc2.ItemValue as QCLeaderAuditStatusName
into #resultstatus
from #result rr
left join BusinessConfiguration bc1 on bc1.ItemKey=rr.StatusID and bc1.ItemDesc='QuestionnaireStageStatus'
left join BusinessConfiguration bc2 on bc2.ItemKey=rr.QCLeaderAuditStatus and bc2.ItemDesc='QuestionnaireAuditStatus'

if @StatusID>=0
begin
	delete from #resultstatus where QCLeaderAuditStatus<>@StatusID
end

if @StageStatusID>=0
begin
	delete from #resultstatus where StatusID<>@StageStatusID
end
	
select * from #resultstatus where FromDate>=@FromDate and ToDate<=@ToDate
order by Period,ClientName

drop table #tempQuestionnaires
drop table #tempClients
drop table #tempResults
drop table #result
drop table #resultstatus

END