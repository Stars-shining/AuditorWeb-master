IF OBJECT_ID('dbo.GetClientStatus', 'P') IS NULL EXEC('Create Procedure dbo.GetClientStatus AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[GetClientStatus]
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

set @questionnaireID=19
set @fromDate='2017-9-1'
set @toDate='2017-9-30'
set @currentClientID=0
set @projectID=7
*/
declare @allClients table(
	ID int
)

if @currentClientID>0
begin
	insert into @allClients
	select ID from dbo.GetTerminalClientIDs(@projectID,@currentClientID)
end
else
begin
	insert into @allClients
	select ID from APClients where LevelID=(select MAX(LevelID) from APClients where ProjectID=@projectID) and ProjectID=@projectID
end

declare @totalNumber int
select @totalNumber=sum(SampleNumber) 
from APQuestionnaireDelivery
where TypeID=4
and QuestionnaireID=@questionnaireID
and FromDate=@fromDate
and ToDate=@toDate
and ClientID in (Select ID from @allClients)

select 
sum(case when ISNULL(rr.status,0)=0 then 1 else 0 end) as StartStatus,
sum(case when ISNULL(rr.status,0)=1 then 1 else 0 end) as UploadStatus,
sum(case when ISNULL(rr.status,0)=2 then 1 else 0 end) as CityUserStatus,
sum(case when ISNULL(rr.status,0)=3 then 1 else 0 end) as AreaUserStatus,
sum(case when ISNULL(rr.status,0)=4 then 1 else 0 end) as QCUserStatus,
sum(case when ISNULL(rr.status,0)=8 then 1 else 0 end) as QCLeaderStatusFirst,
sum(case when ISNULL(rr.status,0)=5 then 1 else 0 end) as ClientUserStatus,
sum(case when ISNULL(rr.status,0)=5 and ISNULL(rr.ClientUserAuditStatus,0)=0 then 1 else 0 end) as ClientUnAuditStatus,
sum(case when ISNULL(rr.status,0)=6 then 1 else 0 end) as QCLeaderStatus,
sum(case when ISNULL(rr.ClientUserAuditStatus,0)=4 then 1 else 0 end) as QCLeaderStatusSuccess,
sum(case when ISNULL(rr.ClientUserAuditStatus,0)=5 then 1 else 0 end) as QCLeaderStatusFailed,
sum(case when ISNULL(rr.status,0)=7 then 1 else 0 end) as Finish,
@totalNumber as TotalNumber
into #allstatus
from @allClients cc
left join APQuestionnaireResults rr on rr.ClientID=cc.ID
and rr.QuestionnaireID=@questionnaireID
and rr.FromDate=@fromDate
and rr.ToDate=@toDate

update #allstatus set StartStatus=TotalNumber-UploadStatus-CityUserStatus-AreaUserStatus-QCUserStatus-QCLeaderStatusFirst-ClientUserStatus-QCLeaderStatus-Finish

select * from #allstatus

drop table #allstatus

declare @tempClientUserID int
declare @TerminalClientLevelID int
select @TerminalClientLevelID=MAX(LevelID) from APClientStructure where ProjectID=@projectID


select 
cc.ID,
case when cc.ID=client.ID then ss.Name + '…ÍÀﬂ÷–' else ss.Name + '…Û∫À÷–' end as Name
into #tempClientStatus
from @allClients cc
left join APQuestionnaireResults rr on cc.ID=rr.ClientID 
and rr.QuestionnaireID=@questionnaireID
and rr.FromDate=@fromDate
and rr.ToDate=@toDate
left join APUsers uu on uu.ID=rr.CurrentClientUserID
left join APClients client on client.ID=uu.ClientID
left join APClientStructure ss on ss.LevelID=client.LevelID and ss.ProjectID=client.ProjectID
where rr.Status=5

select LevelID,
Name + case when levelID=@TerminalClientLevelID then '…ÍÀﬂ÷–' else '…Û∫À÷–' end as Name
into #tempLevels
from APClientStructure
where ProjectID=@projectID

select tt.LevelID,tt.Name,count(ss.ID) as StatusCount from #tempLevels tt
left join #tempClientStatus ss on ss.Name=tt.Name
group by tt.LevelID,tt.Name
order by tt.LevelID desc

drop table #tempClientStatus
drop table #tempLevels

END