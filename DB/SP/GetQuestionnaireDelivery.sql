IF OBJECT_ID('dbo.GetQuestionnaireDelivery', 'P') IS NULL EXEC('Create Procedure dbo.GetQuestionnaireDelivery AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[GetQuestionnaireDelivery]
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
	@FromDatePeriod datetime,
	@ToDatePeriod datetime,
	@Keyword nvarchar(50)
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
declare @FromDatePeriod datetime
declare @ToDatePeriod datetime
declare @Keyword nvarchar(50)

set @ProjectID=2
set @QuestionnaireID=NULL
set @AreaID=NULL
set @LevelID=2
set @TypeID=2 -- 2 as 区控 , 3 as 执行督导, 4 as 访问员
set @StatusID=-999
set @Province='-999'
set @City='-999'
set @District='-999'
set @RoleID=2
set @UserID=4
set @FromDatePeriod='1900-1-1'
set @ToDatePeriod='2999-1-1'
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



select client.ID as ClientID,
client.Code,
client.Name as ClientName,
bc.ItemValue as AreaName,
isnull(province.Name,'') as ProvinceName,
isnull(city.Name,'') as CityName,
isnull(district.Name,'') as DistrictName,
isnull(province.AreaID,0) as AreaID,
isnull(client.Province,0) as Province,
isnull(client.City,0) as City,
isnull(client.District,0) as District,
[Description]
into #tempClients
from dbo.APClients client
left join dbo.APCity province on province.Code=client.Province
left join dbo.APCity city on city.Code=client.City
left join dbo.APCity district on district.Code=client.District
left join dbo.BusinessConfiguration bc on bc.ItemDesc='AreaDivision' and bc.ItemKey=province.AreaID
where client.ProjectID=@ProjectID and (client.LevelID=@LevelID or @LevelID is null)
--and isnull(province.AreaID,0)=ISNULL(@AreaID,isnull(province.AreaID,0))
--and isnull(client.Province,0)=ISNULL(@Province, isnull(client.Province,0))
--and isnull(client.City,0)=ISNULL(@City, isnull(client.City,0))
--and isnull(client.District,0)=ISNULL(@District, isnull(client.District,0))

if ISNULL(@AreaID,0)>0
begin
	delete from #tempClients where AreaID<>@AreaID
end
if ISNULL(@Province,0)>0
begin
	delete from #tempClients where Province<>@Province
end
if ISNULL(@City,0)>0
begin
	delete from #tempClients where City<>@City
end
if ISNULL(@District,0)>0
begin
	delete from #tempClients where District<>@District
end


if isnull(@Keyword,'')<>''
begin
	delete from #tempClients where ClientID not in (select ClientID from #tempClients where  Code like '%'+@Keyword+'%' or ClientName like '%'+@Keyword+'%' or [Description] like '%'+@Keyword+'%')
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

select * into #tempDelivery
from #tempClients cross join @QuestionnairePeriods
order by Period,ClientName


declare @delveryClients table(
	ID int,
	FromDate datetime,
	ToDate datetime
)

if (@TypeID=3 and @RoleID=2) or (@TypeID=4 and @RoleID=3) or (@TypeID=4 and @RoleID=2)
begin
	select ClientID,FromDate,ToDate into #allClients from dbo.APQuestionnaireDelivery where TypeID=@RoleID
	and ProjectID=@ProjectID
	and AcceptUserID=@UserID
	
	while exists(select ClientID from #allClients)
	begin
		declare @tempClientID int
		declare @tempFrom datetime
		declare @tempTo datetime
		set rowcount 1
		select @tempClientID=ClientID,@tempFrom=FromDate,@tempTo=ToDate from #allClients
		set rowcount 0
		
		insert into @delveryClients
		select ID, @tempFrom,@tempTo from dbo.GetAllSubClients(@ProjectID,@tempClientID)
		
		delete from #allClients where ClientID=@tempClientID and FromDate=@tempFrom and ToDate=@tempTo
	end
	
	
	select tt.* into #tempDeliveryCopy from #tempDelivery tt inner join @delveryClients dd on dd.ID=tt.ClientID
	and dd.FromDate=tt.FromDate
	and dd.ToDate=tt.ToDate
	
	delete from #tempDelivery
	insert into #tempDelivery
	select * from #tempDeliveryCopy
	
	delete from #tempDeliveryCopy
	drop table #tempDeliveryCopy
	drop table #allClients
end


select tt.*, 
dd.ID as DeliveryID, 
dd.AcceptUserID,
dd.SampleNumber,
uu.UserName as AcceptUserName,
case when ISNULL(dd.ID,0)<=0 then 1 else 2 end as StatusID,
case when ISNULL(dd.ID,0)<=0 then '未分配' else '已分配' end as StatusName
into #result
from #tempDelivery tt 
left join dbo.APQuestionnaireDelivery dd on tt.QuestionnaireID=dd.QuestionnaireID  
			and dd.TypeID=@TypeID
			and tt.ClientID=dd.ClientID 
			and tt.FromDate=dd.FromDate
			and tt.ToDate=dd.ToDate
left join dbo.APUsers uu on dd.AcceptUserID=uu.ID
where tt.ToDate>=@FromDatePeriod
	  and tt.FromDate<=@ToDatePeriod

if @StatusID>0
begin
	delete from #result where StatusID<>@StatusID
end

select * from #result
order by [Period],[Name],Code

drop table #tempQuestionnaires
drop table #tempClients
drop table #tempDelivery
drop table #result


END