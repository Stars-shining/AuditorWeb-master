IF OBJECT_ID('dbo.GetSubClientStatus', 'P') IS NULL EXEC('Create Procedure dbo.GetSubClientStatus AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[GetSubClientStatus]
	@projectID int,
	@questionnaireID int,
	@fromDate datetime,
	@toDate datetime,
	@currentClientID int
AS
BEGIN
/*
declare @projectID int
declare @questionnaireID int
declare @fromDate datetime
declare @toDate datetime
declare @currentClientID int

set @questionnaireID=1
set @fromDate='2017-1-1'
set @toDate='2017-1-31'
set @currentClientID=1
set @projectID=2
*/


declare @clientStatus table(
	clientID int, 
	clientCode nvarchar(50),
	clientName nvarchar(50),
	levelName nvarchar(50),
	StartStatus int,
	UploadStatus int,
	CityUserStatus int,
	AreaUserStatus int,
	QCUserStatus int,
	QCLeaderStatusFirst int,
	ClientUserStatus int,
	ClientUnAuditStatus int,
	QCLeaderStatus int,
	QCLeaderStatusSuccess int,
	QCLeaderStatusFailed int,
	Finish int,
	TotalNumber int
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
		
	select * into #allClients from dbo.GetTerminalClients(@projectID,@tempClientID)

	declare @totalNumber int
	select @totalNumber=sum(SampleNumber) 
	from APQuestionnaireDelivery
	where TypeID=4
	and QuestionnaireID=@questionnaireID
	and FromDate=@fromDate
	and ToDate=@toDate
	and ClientID in (Select ID from #allClients)

	--insert into @clientStatus
	select
	@tempClientID as tempClientID,
	@clientCode as clientCode,
	@tempName as tempName,
	@tempLevelName as tempLevelName,
	sum(case when ISNULL(rr.status,0)=0 then 1 else 0 end) as StartStatus,
	sum(case when ISNULL(rr.status,0)=1 then 1 else 0 end) as UploadStatus,
	sum(case when ISNULL(rr.status,0)=2 then 1 else 0 end) as CityUserStatus,
	sum(case when ISNULL(rr.status,0)=3 then 1 else 0 end) as AreaUserStatus,
	sum(case when ISNULL(rr.status,0)=4 then 1 else 0 end) as QCUserStatus,
	sum(case when ISNULL(rr.status,0)=8 then 1 else 0 end) as QCLeaderStatusFirst,
	sum(case when ISNULL(rr.status,0)=5 then 1 else 0 end) as ClientUserStatus,
	sum(case when ISNULL(rr.status,0)=5 and ISNULL(rr.ClientUserAuditStatus,0)=0 then 1 else 0 end) as ClientUnAuditStatus,
	sum(case when ISNULL(rr.status,0)=6 then 1 else 0 end) as QCLeaderStatus,
	sum(case when ISNULL(rr.QCLeaderAuditStatus,0)=1 then 1 else 0 end) as QCLeaderStatusSuccess,
	sum(case when ISNULL(rr.QCLeaderAuditStatus,0)=2 then 1 else 0 end) as QCLeaderStatusFailed,
	sum(case when ISNULL(rr.status,0)=7 then 1 else 0 end) as Finish,
	@totalNumber as TotalNumber
	into #allStatus
	from #allClients cc
	left join APQuestionnaireResults rr on cc.ID=rr.ClientID 
	and rr.QuestionnaireID=@questionnaireID
	and rr.FromDate=@fromDate
	and rr.ToDate=@toDate

	update #allstatus set StartStatus=TotalNumber-UploadStatus-CityUserStatus-AreaUserStatus-QCUserStatus-QCLeaderStatusFirst-ClientUserStatus-QCLeaderStatus-Finish

	insert into @clientStatus
	select * from #allstatus

	drop table #allstatus

	delete from @subClients where ID=@tempClientID

	drop table #allClients

end

select * from @clientStatus order by clientCode

END