IF OBJECT_ID('dbo.SearchProjectUsers', 'P') IS NULL EXEC('Create Procedure dbo.SearchProjectUsers AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[SearchProjectUsers]
	@Name nvarchar(50),
	@RoleID int,
	@ProjectID int,
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
declare @ProjectID int

declare @Province nvarchar(50)
declare @City nvarchar(50)
declare @District nvarchar(50)
declare @CurrentUserID int
declare @CurrentUserType int

set @Name=''
set @RoleID=NULL
set @ProjectID=1

set @Province=NULL
set @City=NULL
set @District=NULL
set @CurrentUserID=2
set @CurrentUserType=7
*/

select uu.*,
province.Name as ProvinceName,
city.Name as CityName,
district.Name as DistrictName,
bc.ItemValue as StatusName,
ur.Name as RoleName
into #tempResult
from APProjectUsers pu
inner join APUsers uu on pu.UserID=uu.ID
left join APCity province on province.Code=uu.Province
left join APCity city on city.Code=uu.City
left join APCity district on district.Code=uu.District
left join BusinessConfiguration bc on bc.ItemKey=uu.Status and bc.ItemDesc='UserStatus'
left join APUserRole ur on ur.ID=uu.RoleID
where pu.RoleID=ISNULL(@RoleID,pu.RoleID)
and pu.ProjectID=@ProjectID

if @Name<>''
begin
	delete from #tempResult where ID not in (select ID from #tempResult where UserName like '%'+@Name+'%')
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


select * from #tempResult

drop table #tempResult


END