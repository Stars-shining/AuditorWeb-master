IF OBJECT_ID('dbo.SearchClients', 'P') IS NULL EXEC('Create Procedure dbo.SearchClients AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[SearchClients]
	@Name nvarchar(50),
	@TypeID int,
	@Province nvarchar(50),
	@City nvarchar(50),
	@District nvarchar(50),
	@ProjectID int
AS
BEGIN

/*
declare @Name nvarchar(50)
declare @TypeID int
declare @Province nvarchar(50)
declare @City nvarchar(50)
declare @District nvarchar(50)
declare @ProjectID int

set @Name=NULL
set @TypeID=-999
set @Province='-999'
set @City='-999'
set @District='-999'
set @ProjectID=2
*/

if @Name=''
begin
	set @Name=NULL
end

if @TypeID=-999
begin
	set @TypeID=NULL
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

select client.ID,
client.Code,
client.Name, 
clientStruct.Name as TypeName,
client.Province,
client.City,
client.District,
isnull(province.Name,'') as ProvinceName,
isnull(city.Name,'') as CityName,
isnull(district.Name,'') as DistrictName
into #tempResult
from APClients client 
left join APClientStructure clientStruct on client.LevelID=clientStruct.levelID and clientStruct.ProjectID=@ProjectID
left join APCity province on client.Province=province.Code
left join APCity city on client.City=city.Code
left join APCity district on client.District=district.Code
where client.LevelID=ISNULL(@TypeID, client.LevelID)
and client.ProjectID=ISNULL(@ProjectID, client.ProjectID)

if @Name is not null
begin
	delete from #tempResult where ID not in (select ID from #tempResult where Name like '%'+@Name+'%' or Code like '%'+@Name+'%')
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

select * from #tempResult

drop table #tempResult

END