IF OBJECT_ID('dbo.GetQuestionnaireCheckListClient', 'P') IS NULL EXEC('Create Procedure dbo.GetQuestionnaireCheckListClient AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[GetQuestionnaireCheckListClient]
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
	@ClientLevelID int,
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
declare @ClientLevelID int
declare @Keyword nvarchar(50)

set @ProjectID=1
set @ClientID=3093
set @QuestionnaireID=NULL
set @StatusID=-999
set @Province='-999'
set @City='-999'
set @District='-999'
set @FromDate='1900-01-01'
set @ToDate='2900-01-01'
set @StageStatusID=5
set @ClientLevelID=0
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


select 
dd.ID as ResultID, 
dd.ClientID,
dd.QuestionnaireID,
dbo.GetQuestionnairePeriodName(dd.FromDate,dd.ToDate,dd.QuestionnaireID) as Period,
qq.UploadType,
qq.Name,
dd.FromDate,
dd.ToDate,
dd.DeliveryID as DeliveryID,
isnull(dd.ClientUserAuditStatus,0) as ClientUserAuditStatus,
dd.Status as StatusID,
ISNULL(dd.Score,0) as Score,
dd.CurrentClientUserID,
dd.ClientUserID,
dd.UploadBeginTime
into #tempResults
from  dbo.APQuestionnaireResults dd 
inner join APQuestionnaires qq on qq.ID=dd.QuestionnaireID
where dd.ProjectID=@ProjectID
and  dd.FromDate>=@FromDate and dd.ToDate<=@ToDate


select distinct client.ID as ClientID,
client.Code,
client.Name as ClientName,
bc.ItemValue as AreaName,
isnull(province.Name,'') as ProvinceName,
isnull(city.Name,'') as CityName,
isnull(district.Name,'') as DistrictName,
client.Province,
client.City,
client.District
into #tempClients
from #tempResults rr inner join (select * from GetTerminalClients(@ProjectID,@ClientID)) client on rr.ClientID=client.ID
left join dbo.APCity province on province.Code=client.Province
left join dbo.APCity city on city.Code=client.City
left join dbo.APCity district on district.Code=client.District
left join dbo.BusinessConfiguration bc on bc.ItemDesc='AreaDivision' and bc.ItemKey=province.AreaID


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


select dd.ResultID, 
dd.QuestionnaireID,
dd.ClientID,
dd.Period,
dd.UploadType,
dd.Name,
dd.FromDate,
dd.ToDate,
dd.DeliveryID as DeliveryID,
dd.ClientUserAuditStatus,
dd.StatusID,
dd.Score,
dd.CurrentClientUserID,
dd.ClientUserID,
dd.UploadBeginTime,
client.Code,
client.ClientName,
client.AreaName,
client.ProvinceName,
client.CityName,
client.DistrictName,
ISNULL(cc.LevelID,-1) as LevelID
into #result
from #tempResults dd
inner join #tempClients client on dd.ClientID=client.ClientID
left join APUsers uu on uu.ID=dd.CurrentClientUserID
left join APClients cc on cc.ID=uu.ClientID


declare @TerminalClientLevelID int
select @TerminalClientLevelID=MAX(LevelID) from APClientStructure where ProjectID=@projectID

select rr.*,
case when rr.StatusID=5 and rr.LevelID=@TerminalClientLevelID then cc.Name+bc1.ItemValue
     when rr.StatusID=5 and rr.LevelID<>@TerminalClientLevelID then cc.Name+'审核中'
else bc1.ItemValue end as StatusName,
case when rr.ClientUserAuditStatus=2 or rr.ClientUserAuditStatus=3 then uu.UserName + bc2.ItemValue 
else bc2.ItemValue end as ClientUserAuditStatusName
into #resultstatus
from #result rr
left join BusinessConfiguration bc1 on bc1.ItemKey=rr.StatusID and bc1.ItemDesc='QuestionnaireStageStatus'
left join BusinessConfiguration bc2 on bc2.ItemKey=rr.ClientUserAuditStatus and bc2.ItemDesc='QuestionnaireClientStatus'
left join APClientStructure cc on cc.LevelID=rr.LevelID and cc.ProjectID=@ProjectID
left join APUsers uu on uu.ID=rr.ClientUserID

if @StatusID>=0
begin
	if @StatusID=1
	begin
		delete from #resultstatus where ClientUserAuditStatus not in (1,2,3)
	end
	else
	begin
		delete from #resultstatus where ClientUserAuditStatus<>@StatusID
	end
end

if @StageStatusID>=0
begin
	delete from #resultstatus where StatusID<>@StageStatusID
end

/**通过Levelid筛选处于哪个客户级别的审核**/
if isnull(@ClientLevelID,0)>0
begin
	delete from #resultstatus where LevelID<>@ClientLevelID
end
	
select * from #resultstatus where FromDate>=@FromDate and ToDate<=@ToDate
order by Period,ClientName

drop table #tempClients
drop table #tempResults
drop table #result
drop table #resultstatus

END