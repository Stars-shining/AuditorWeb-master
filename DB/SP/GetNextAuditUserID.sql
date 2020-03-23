IF OBJECT_ID('dbo.GetNextAuditUserID', 'P') IS NULL EXEC('Create Procedure dbo.GetNextAuditUserID AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[GetNextAuditUserID]
	@ProjectID int,
	@QuestionnaireID int,
	@FromDate datetime,
	@ToDate datetime,
	@TypeID int,
	@ClientID int
AS
BEGIN
/*
declare @ProjectID int
declare @QuestionnaireID int
declare @FromDate datetime
declare @ToDate datetime
declare @TypeID int
declare @ClientID int

set @ProjectID=2
set @QuestionnaireID=1
set @FromDate='2017-1-1'
set @ToDate='2017-1-31'
set @TypeID=3
set @ClientID=8
*/

select ClientID,AcceptUserID into #tempDelivery from APQuestionnaireDelivery where QuestionnaireID=@QuestionnaireID
and FromDate=@FromDate
and ToDate=@ToDate
and ProjectID=@ProjectID
and TypeID=@TypeID

declare @delivery table(
	clientID int,
	acceptUserID int
)

while exists(select ClientID from #tempDelivery)
begin
	
	declare @tempClientID int
	declare @acceptUserID int
	
	set rowcount 1
	select @tempClientID=ClientID,@acceptUserID=AcceptUserID from #tempDelivery 
	set rowcount 0
	
	
	insert into @delivery
	select ID,@acceptUserID from dbo.GetTerminalClients(@ProjectID,@tempClientID)	
	
	delete from #tempDelivery where ClientID=@tempClientID and AcceptUserID=@acceptUserID
end

select AcceptUserID from @delivery where clientID=@ClientID

drop table #tempDelivery

END