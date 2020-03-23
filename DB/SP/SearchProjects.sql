IF OBJECT_ID('dbo.SearchProjects', 'P') IS NULL EXEC('Create Procedure dbo.SearchProjects AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[SearchProjects]
	@Name nvarchar(50),
	@FromDate datetime,
	@ToDate datetime,
	@Status int,
	@UserID int,
	@UserType int
AS
BEGIN
/*
declare @Name nvarchar(50)
declare @FromDate datetime
declare @ToDate datetime
declare @Status int
declare @UserID int
declare @UserType int

set @Name=''
set @FromDate=NULL
set @ToDate=NULL
set @Status=NULL
set @UserID=4
set @UserType=2
*/

select app.ID,
app.Name,
app.FromDate,
app.ToDate,
bc.ItemValue as 'ProjectStatus',
bcType.ItemValue as 'ProjectType',
app.CoreUserID,
app.PrimaryApplyUserID,
app.QCLeaderUserID
into #allProjects
from [dbo].[APProjects] app
left join BusinessConfiguration bc on app.[Status]=bc.ItemKey and bc.ItemDesc='ProjectStatus'
left join BusinessConfiguration bcType on app.TypeID=bcType.ItemKey and bcType.ItemDesc='ProjectType'
where app.FromDate<=isnull(@ToDate,app.FromDate) 
and app.ToDate>=isnull(@FromDate,app.ToDate) 
and app.[Status]=ISNULL(@Status,app.[Status])
and isnull(app.Name,'') like '%'+@Name+'%'
and isnull(app.DeleteFlag,0)=0

if @UserType=1	--总控
begin
	delete from #allProjects where PrimaryApplyUserID<>@UserID
end
else if @UserType=5	--QC督导
begin
	delete from #allProjects where QCLeaderUserID<>@UserID
end
else if @UserType=7	--研究员
begin
	delete from #allProjects where CoreUserID<>@UserID
end
else if @UserType in (4,6) --4 访问员,6 质控员
begin
	select distinct ProjectID into #involvedProjects from dbo.APProjectUsers where UserID=@UserID
	delete from #allProjects where ID not in (select ProjectID from #involvedProjects)
	drop table #involvedProjects
end
else if @UserType not in (8,10) --8 系统管理员,10 质管员
begin
	select distinct ProjectID into #projectUsers from dbo.APQuestionnaireDelivery where AcceptUserID=@UserID
	delete from #allProjects where ID not in (select ProjectID from #projectUsers)
	drop table #projectUsers
end

select * from #allProjects

drop table #allProjects

END