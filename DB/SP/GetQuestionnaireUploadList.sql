IF OBJECT_ID('dbo.GetQuestionnaireUploadList', 'P') IS NULL EXEC('Create Procedure dbo.GetQuestionnaireUploadList AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[GetQuestionnaireUploadList]
	@ProjectID int,
	@QuestionnaireID int,
	@FromDate datetime,
	@ToDate datetime,
	@StatusID int,
	@AreaID int,
	@Province nvarchar(50),
	@City nvarchar(50),
	@District nvarchar(50),
	@RoleID int,
	@UserID int,
	@Keyword nvarchar(50)
AS
BEGIN
/*

declare @ProjectID int
declare @QuestionnaireID int
declare @FromDate datetime
declare @ToDate datetime
declare @StatusID int

declare @AreaID int
declare @Province nvarchar(50)
declare @City nvarchar(50)
declare @District nvarchar(50)
declare @RoleID int
declare @UserID int
declare @Keyword nvarchar(50)

set @ProjectID=6
set @QuestionnaireID=-999
set @FromDate='1900-1-2'
set @ToDate='2099-1-2'
set @StatusID=-999
set @AreaID=-999
set @Province='-999'
set @City='-999'
set @District='-999'
set @RoleID=7
set @UserID=9
set @Keyword=''

*/

if @QuestionnaireID=-999
begin
	set @QuestionnaireID=NULL
end

if @AreaID=-999
begin
	set @AreaID=NULL
end
if @Province='-999'
begin
	set @Province=NULL
end
if @City='-999'
begin
	set @City=NULL
end
if @District='-999'
begin
	set @District=NULL
end


declare @devClients table(
	ID int,
	DeliveryID int
)

select dev.ID,dev.ClientID
into #tempClients
from dbo.APQuestionnaireDelivery dev
where dev.TypeID=4
and dev.ProjectID=@ProjectID 
and dev.QuestionnaireID=isnull(@QuestionnaireID,dev.QuestionnaireID)
and dev.ToDate>=@FromDate
and dev.FromDate<=@ToDate


while exists(select ClientID from #tempClients)
begin
	declare @tempDevID int
	declare @tempID int
	
	set rowcount 1
	select @tempDevID=ID,@tempID=ClientID from #tempClients
	set rowcount 0
	
	insert into @devClients
	select ID,@tempDevID from dbo.GetTerminalClientIDs(@ProjectID,@tempID) 
	
	delete from #tempClients where ClientID=@tempID and ID=@tempDevID
end
drop table #tempClients

select 
ROW_NUMBER() OVER (ORDER BY devClient.DeliveryID DESC) as RowID,
devClient.DeliveryID,
dev.FromDate,
dev.ToDate,
CONVERT(nvarchar(50),dev.FromDate,102) + ' - ' + CONVERT(nvarchar(50),dev.ToDate,102) as Period,
client.ID as ClientID, 
client.Code as ClientCode, 
client.Name as ClientName,
case when province.bDirectCity=1 then province.Name else city.Name end as CityName,
que.Name as QuestionnaireName,
que.UploadType,
--res.ID,
dev.QuestionnaireID,
dev.SampleNumber as SampleNumber,
--res.Score,
--isnull(res.VisitUserUploadStatus,0) as StatusID,
--bc.ItemValue as StatusName,
--res.Status as StageStatusID,
province.AreaID,
client.Province,
client.City,
client.District
into #tempResult2
from @devClients devClient
inner join APClients client on client.ID=devClient.ID
inner join APQuestionnaireDelivery dev on devClient.DeliveryID=dev.ID
inner join APQuestionnaires que on que.ID=dev.QuestionnaireID
left join APCity province on province.Code=client.Province
left join APCity city on city.Code=client.City
--left join APQuestionnaireResults res on res.DeliveryID=dev.ID and res.ClientID=devClient.ID
--left join BusinessConfiguration bc on bc.ItemKey=isnull(res.VisitUserUploadStatus,0) and bc.ItemDesc='QuestionnaireUploadStatus'
where isnull(que.DeleteFlag,0)=0

select dev.RowID,
dev.DeliveryID,
dev.FromDate,
dev.ToDate,
dev.Period,
dev.ClientID, 
dev.ClientCode, 
dev.ClientName,
dev.CityName,
dev.QuestionnaireName,
dev.UploadType,
dev.QuestionnaireID,
dev.SampleNumber,
dev.AreaID,
dev.Province,
dev.City,
dev.District,
COUNT(res.ID) as ResultCount
into #tempResult
from #tempResult2 dev
left join APQuestionnaireResults res on res.DeliveryID=dev.DeliveryID and res.ClientID=dev.ClientID and res.Status>0
left join BusinessConfiguration bc on bc.ItemKey=isnull(res.VisitUserUploadStatus,0) and bc.ItemDesc='QuestionnaireUploadStatus'
group by dev.RowID,
dev.DeliveryID,
dev.FromDate,
dev.ToDate,
dev.Period,
dev.ClientID, 
dev.ClientCode, 
dev.ClientName,
dev.CityName,
dev.QuestionnaireName,
dev.UploadType,
dev.QuestionnaireID,
dev.SampleNumber,
dev.AreaID,
dev.Province,
dev.City,
dev.District

drop table #tempResult2

if isnull(@Keyword,'')<>''
begin
	delete from #tempResult where RowID not in (select RowID from #tempResult where ClientCode like '%'+@Keyword+'%' or ClientName like '%'+@Keyword+'%')
end
if isnull(@AreaID,0)>0
begin
	delete from #tempResult where RowID not in (select RowID from #tempResult where AreaID=@AreaID)
end
if isnull(@Province,'')<>''
begin
	delete from #tempResult where RowID not in (select RowID from #tempResult where Province=@Province)
end
if isnull(@City,'')<>''
begin
	delete from #tempResult where RowID not in (select RowID from #tempResult where City=@City)
end
if isnull(@District,'')<>''
begin
	delete from #tempResult where RowID not in (select RowID from #tempResult where District=@District)
end

if @StatusID=0--未录入
begin
	delete from #tempResult where RowID not in (select RowID from #tempResult where ResultCount=0)
end
else if @StatusID=1--已完成录入
begin
	delete from #tempResult where RowID not in (select RowID from #tempResult where ResultCount>0 and ResultCount=SampleNumber)
end
else if @StatusID>0--已录入但未完成
begin
	delete from #tempResult where RowID not in (select RowID from #tempResult where ResultCount>0 and ResultCount<>SampleNumber)
end

--区控 = 2,
--执行督导 = 3,
--访问员 = 4,
if @RoleID=2 or @RoleID=3 or @RoleID=4
begin
	declare @AllClients table (
		ID int,
		FromDate datetime,
		ToDate datetime,
		QuestionnaireID int
	)
	select ClientID,FromDate,ToDate,QuestionnaireID into #allClients from dbo.APQuestionnaireDelivery where TypeID=@RoleID
	and ProjectID=@ProjectID
	and AcceptUserID=@UserID
	and QuestionnaireID=isnull(@QuestionnaireID,QuestionnaireID)
	
	while exists(select ClientID from #allClients)
	begin
		declare @tempClientID int
		declare @tempFrom datetime
		declare @tempTo datetime
		declare @tempQuestionnaireID int
		set rowcount 1
		select @tempClientID=ClientID,@tempFrom=FromDate,@tempTo=ToDate,@tempQuestionnaireID=QuestionnaireID from #allClients
		set rowcount 0
		
		insert into @AllClients
		select ID,@tempFrom,@tempTo,@tempQuestionnaireID from dbo.GetTerminalClientIDs(@ProjectID,@tempClientID)
		where ID not in (select ID from @AllClients where FromDate=@tempFrom and ToDate=@ToDate and QuestionnaireID=@tempQuestionnaireID)
		
		delete from #allClients where ClientID=@tempClientID and FromDate=@tempFrom and ToDate=@tempTo and QuestionnaireID=@tempQuestionnaireID
	end
	drop table #allClients

	delete from #tempResult where QuestionnaireID not in (select distinct QuestionnaireID from @AllClients)

	--select * from #tempResult

	select distinct dev.* from #tempResult dev
	inner join @AllClients allclient on allclient.ID=dev.ClientID 
		and allclient.FromDate=dev.FromDate 
		and allclient.ToDate=dev.ToDate
		and allclient.QuestionnaireID=dev.QuestionnaireID
end
else
begin
	select * from #tempResult
end

drop table #tempResult

END