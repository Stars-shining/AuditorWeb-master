IF OBJECT_ID('dbo.GetQuestionnaireCheckList', 'P') IS NULL EXEC('Create Procedure dbo.GetQuestionnaireCheckList AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[GetQuestionnaireCheckList]
	@ProjectID int,
	@QuestionnaireID int,
	@AreaID int,
	@LevelID int,
	@TypeID int,
	@StatusID int,
	@Province nvarchar(50),
	@City nvarchar(50),
	@District nvarchar(50),
	@RoleID int,
	@UserID int,
	@FromDate datetime,
	@ToDate datetime,
	@StageStatusID int,
	@Keyword nvarchar(50),
	@SearchResultID int,
	@IsDuplicate bit
AS
BEGIN
/*

declare @ProjectID int
declare @QuestionnaireID int
declare @AreaID int
declare @LevelID int
declare @TypeID int
declare @StatusID int
declare @Province nvarchar(50)
declare @City nvarchar(50)
declare @District nvarchar(50)
declare @RoleID int
declare @UserID int
declare @FromDate datetime
declare @ToDate datetime
declare @StageStatusID int
declare @Keyword nvarchar(50)
declare @SearchResultID int
declare @IsDuplicate bit

set @ProjectID=2
set @QuestionnaireID=2
set @AreaID=NULL
set @LevelID=3
set @TypeID=3 -- 1 as 执行督导审核, 2 as 区控审核, 3 as 质控员审核, 6 as 质控督导审核,5 as 质控督导复审
set @StatusID=-999
set @Province='-999'
set @City='-999'
set @District='-999'
set @RoleID=7
set @UserID=5218
set @FromDate='2019-10-01'
set @ToDate='2019-10-31'
set @StageStatusID=4
set @Keyword=''
set @SearchResultID=0
set @IsDuplicate=0

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
isnull(dd.CityUserAuditStatus,0) as CityUserAuditStatus,
isnull(dd.AreaUserAuditStatus,0) as AreaUserAuditStatus,
isnull(dd.QCUserAuditStatus,0) as QCUserAuditStatus,
isnull(dd.QCLeaderAuditStatusFirst,0) as QCLeaderAuditStatusFirst,
isnull(dd.QCLeaderAuditStatus,0) as QCLeaderAuditStatus,
dd.Status as StatusID,
ISNULL(dd.Score,0) as Score,
dd.UploadBeginTime
into #tempResults
from  dbo.APQuestionnaireResults dd 
inner join APQuestionnaires qq on qq.ID=dd.QuestionnaireID
where dd.ProjectID=@ProjectID
and  dd.FromDate>=@FromDate and dd.ToDate<=@ToDate

if @SearchResultID>0
begin
	delete from #tempResults where ResultID<>@SearchResultID
end

select distinct client.ID as ClientID,
client.Code,
client.Name as ClientName,
client.Province,
client.City,
client.District
into #tempClients_NoCityName
from #tempResults rr 
inner join dbo.APClients client on rr.ClientID=client.ID
where client.LevelID=ISNULL(@LevelID, client.LevelID)
and client.ProjectID=@ProjectID

if isnull(@Keyword,'')<>''
begin
	delete from #tempClients_NoCityName where ClientID not in (select ClientID from #tempClients_NoCityName where Code like '%'+@Keyword+'%' or ClientName like '%'+@Keyword+'%')
end
if isnull(@Province,'')<>''
begin
	delete from #tempClients_NoCityName where ClientID not in (select ClientID from #tempClients_NoCityName where Province=@Province)
end
if isnull(@City,'')<>''
begin
	delete from #tempClients_NoCityName where ClientID not in (select ClientID from #tempClients_NoCityName where City=@City)
end
if isnull(@District,'')<>''
begin
	delete from #tempClients_NoCityName where ClientID not in (select ClientID from #tempClients_NoCityName where District=@District)
end

select client.*,
bc.ItemValue as AreaName,
isnull(province.Name,'') as ProvinceName,
isnull(city.Name,'') as CityName,
isnull(district.Name,'') as DistrictName,
province.AreaID
into #tempClients
from #tempClients_NoCityName client
left join dbo.APCity province on province.Code=client.Province
left join dbo.APCity city on city.Code=client.City
left join dbo.APCity district on district.Code=client.District
left join dbo.BusinessConfiguration bc on bc.ItemDesc='AreaDivision' and bc.ItemKey=province.AreaID

if isnull(@AreaID,0)>0
begin
	delete from #tempClients where ClientID not in (select ClientID from #tempClients where AreaID=@AreaID)
end

drop table #tempClients_NoCityName

select dd.ResultID, 
dd.QuestionnaireID,
dd.ClientID,
dd.Period,
dd.UploadType,
dd.Name,
dd.FromDate,
dd.ToDate,
dd.DeliveryID as DeliveryID,
dd.CityUserAuditStatus,
dd.AreaUserAuditStatus,
dd.QCUserAuditStatus,
dd.QCLeaderAuditStatusFirst,
dd.QCLeaderAuditStatus,
dd.StatusID,
dd.Score,
dd.UploadBeginTime,
client.Code,
client.ClientName,
client.AreaName,
client.ProvinceName,
client.CityName,
client.DistrictName
into #result
from #tempResults dd
inner join #tempClients client on dd.ClientID=client.ClientID

select rr.*,
bc1.ItemValue as StatusName,
bc2.ItemValue as CityUserAuditStatusName,
bc3.ItemValue as AreaUserAuditStatusName,
bc4.ItemValue as QCUserAuditStatusName,
bc5.ItemValue as QCLeaderAuditStatusName
into #resultstatus
from #result rr
left join BusinessConfiguration bc1 on bc1.ItemKey=rr.StatusID and bc1.ItemDesc='QuestionnaireStageStatus'
left join BusinessConfiguration bc2 on bc2.ItemKey=rr.CityUserAuditStatus and bc2.ItemDesc='QuestionnaireAuditStatus'
left join BusinessConfiguration bc3 on bc3.ItemKey=rr.AreaUserAuditStatus and bc3.ItemDesc='QuestionnaireAuditStatus'
left join BusinessConfiguration bc4 on bc4.ItemKey=rr.QCUserAuditStatus and bc4.ItemDesc='QuestionnaireAuditStatus'
left join BusinessConfiguration bc5 on bc5.ItemKey=rr.QCLeaderAuditStatusFirst and bc5.ItemDesc='QuestionnaireAuditStatus'

if @StatusID>=0
	begin
	if @TypeID=1
	begin
	--执行督导审核
		delete from #resultstatus where CityUserAuditStatus<>@StatusID
	end
	else if @TypeID=2
	begin
	--区控审核
		delete from #resultstatus where AreaUserAuditStatus<>@StatusID
	end
	else if @TypeID=3
	begin
	--质控员审核
		delete from #resultstatus where QCUserAuditStatus<>@StatusID
	end
	else if @TypeID=6
	begin
	--质控督导审核
		delete from #resultstatus where QCLeaderAuditStatusFirst<>@StatusID
	end
	else if @TypeID=5
	begin
	--质控督导复审
		delete from #resultstatus where QCLeaderAuditStatus<>@StatusID
	end
end

if @StageStatusID>=0
begin
	delete from #resultstatus where StatusID<>@StageStatusID
end

if @StageStatusID=-2 --需要修改的问卷
begin
	delete from #resultstatus where isnull(ResultID,0)<=0
	delete from #resultstatus where StatusID>1
end

--区控 = 2,
if @RoleID=2
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

	delete from #resultstatus where QuestionnaireID not in (select distinct QuestionnaireID from @AllClients)

	if @IsDuplicate=1
	begin
		select ClientID,count(ResultID) as ResultCount into #resultcount from #resultstatus group by ClientID
		delete from #resultstatus where ClientID in (select ClientID from #resultcount where ResultCount<2)
		drop table #resultcount

		select distinct dev.* from #resultstatus dev
		inner join @AllClients allclient on allclient.ID=dev.ClientID 
			and allclient.FromDate=dev.FromDate 
			and allclient.ToDate=dev.ToDate
			and allclient.QuestionnaireID=dev.QuestionnaireID
		order by dev.ClientID
	end
	else
	begin
		select distinct dev.* from #resultstatus dev
		inner join @AllClients allclient on allclient.ID=dev.ClientID 
			and allclient.FromDate=dev.FromDate 
			and allclient.ToDate=dev.ToDate
			and allclient.QuestionnaireID=dev.QuestionnaireID
		order by dev.ResultID
	end
end
else
begin
	if @IsDuplicate=1
	begin
		select ClientID,count(ResultID) as ResultCount into #resultcount2 from #resultstatus group by ClientID
		delete from #resultstatus where ClientID in (select ClientID from #resultcount2 where ResultCount<2)
		drop table #resultcount2

		select * from #resultstatus
		order by ClientID
	end
	else
	begin
		select * from #resultstatus
		order by ResultID
	end
	
end
	

--order by Period,ClientName

drop table #tempClients
drop table #tempResults
drop table #result
drop table #resultstatus


END