IF OBJECT_ID('dbo.GetDeliveryClientID', 'P') IS NULL EXEC('Create Procedure dbo.GetDeliveryClientID AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[GetDeliveryClientID]
	@ClientCode nvarchar(50),
	@ProjectID int,
	@UserID int
AS
BEGIN
/*
declare @ClientCode nvarchar(50)
declare @ProjectID int
declare @UserID int
set @ClientCode='519'
set @ProjectID=2
set @UserID=2563
*/
declare @clients table(
	ID int
)

select clientid into #tempClients from APQuestionnaireDelivery where ProjectID=@ProjectID and AcceptUserID=@UserID and TypeID=4

while exists(select clientid from #tempClients)
begin
	declare @tempID int
	set rowcount 1
	select @tempID=clientid from #tempClients
	set rowcount 0
	
	insert into @clients
	select ID from GetTerminalClients(@ProjectID,@tempID)
	
	delete from #tempClients where clientid=@tempID
end

drop table #tempClients

select distinct cc.ID from @clients cc
inner join APClients bc on bc.ID=cc.ID
where bc.Code=@ClientCode

END