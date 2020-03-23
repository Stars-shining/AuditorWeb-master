IF OBJECT_ID('dbo.SearchUsers', 'P') IS NULL EXEC('Create Procedure dbo.SearchUsers AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[SearchUsers]
	@Name nvarchar(50),
	@RoleID int,
	@FromDate datetime,
	@ToDate datetime,
	@StatusID int,
	@Province nvarchar(50),
	@City nvarchar(50),
	@District nvarchar(50),
	@CurrentUserID int,
	@CurrentUserType int
AS
BEGIN

/*
declare @Name nvarchar(50)
declare @RoleID int
declare @FromDate datetime
declare @ToDate datetime
declare @StatusID int

declare @Province nvarchar(50)
declare @City nvarchar(50)
declare @District nvarchar(50)
declare @CurrentUserID int
declare @CurrentUserType int

set @Name=''
set @RoleID=NULL
set @FromDate=NULL
set @ToDate=NULL
set @StatusID=NULL

set @Province=NULL
set @City=NULL
set @District=NULL
set @CurrentUserID=24
set @CurrentUserType=7
*/

select uu.*,
province.Name as ProvinceName,
city.Name as CityName,
district.Name as DistrictName,
bc.ItemValue as StatusName,
ur.Name as RoleName
into #tempResult
from APUsers uu 
left join APCity province on province.Code=uu.Province
left join APCity city on city.Code=uu.City
left join APCity district on district.Code=uu.District
left join BusinessConfiguration bc on bc.ItemKey=uu.Status and bc.ItemDesc='UserStatus'
left join APUserRole ur on ur.ID=uu.RoleID
where RoleID=ISNULL(@RoleID,RoleID)
and [Status]=ISNULL(@StatusID,[Status])
--and DeleteFlag=0
--and isnull(UserName,'') like '%'+@Name+'%' 
--and CreateTime>=ISNULL(@FromDate,'1900-1-1')
--and CreateTime<ISNULL(@ToDate,'2099-1-1')
--and isnull(Province,'')=isnull(@Province,isnull(Province,''))
--and isnull(City,'')=isnull(@City,isnull(City,''))
--and isnull(District,'')=isnull(@District,isnull(District,''))

if @Name<>''
begin
	delete from #tempResult where ID not in (select ID from #tempResult where UserName like '%'+@Name+'%')
end

if @FromDate<>NULL
begin
	delete from #tempResult where ID not in (select ID from #tempResult where CreateTime>=@FromDate)
end
if @ToDate<>NULL
begin
	delete from #tempResult where ID not in (select ID from #tempResult where CreateTime<@ToDate)
end

if isnull(@Province,'')<>''
begin
	delete from #tempResult where ID not in (select ID from #tempResult where Province=@Province)
end
if isnull(@City,'')<>''
begin
	delete from #tempResult where ID not in (select ID from #tempResult where City=@City)
end
if isnull(@District,'')<>''
begin
	delete from #tempResult where ID not in (select ID from #tempResult where District=@District)
end



if @CurrentUserType=3
begin
--执行督导只能看到访问员
	delete from #tempResult where roleID <> 4
end
else if @CurrentUserType=5
begin
--QC督导只能看到QC人员
	delete from #tempResult where roleID <> 6
end
else if @CurrentUserType=9
begin
--客户机构只能看到下级机构
	delete from #tempResult where roleID <> 9
	declare @currentClientID int
	declare @currentProjectID int
	select @currentClientID=ClientID, @currentProjectID=ProjectID from APUsers where ID=@CurrentUserID
	
	if isnull(@currentClientID,0)>0
	begin
		select ID into #allSubClients from GetAllSubClients(@currentProjectID,@currentClientID)
		delete from #tempResult where clientID not in (select ID from #allSubClients)
		drop table #allSubClients
	end

end

select rr.*,ss.Name as LevelName from #tempResult rr
left join APClients cc on cc.ID=rr.ClientID and cc.ProjectID=rr.ProjectID
left join APClientStructure ss on ss.LevelID=cc.LevelID and ss.ProjectID=cc.ProjectID

drop table #tempResult


END