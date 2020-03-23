IF OBJECT_ID('dbo.GetQuestionnaireResultsCount', 'P') IS NULL EXEC('Create Procedure dbo.GetQuestionnaireResultsCount AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[GetQuestionnaireResultsCount]
	@QuestionnaireID int,
	@ClientID int,
	@FromDate datetime,
	@ToDate datetime,
	@Status int
AS
BEGIN
/*
declare @QuestionnaireID int
declare @ClientID int
declare @FromDate datetime
declare @ToDate datetime
declare @Status int

set @QuestionnaireID=15
set @ClientID=0
set @FromDate='2017-9-1'
set @ToDate='2017-12-31'
set @Status = -999
*/

select
rr.ID,
rr.ClientID,
rr.[Status]
into #baseData
from APQuestionnaireResults rr
where rr.QuestionnaireID=@QuestionnaireID
and rr.ToDate>=@FromDate
and rr.FromDate<=@ToDate

if @ClientID>0
begin
	declare @ProjectID int 
	select @ProjectID=ProjectID from APClients where ID=@ClientID

	delete from #baseData where ClientID not in 
	(
		select distinct ID from GetTerminalClientIDs(cast(@ProjectID as nvarchar(50)),cast(@ClientID as nvarchar(50)))
	)
end

if @Status=-1
begin
	delete from #baseData where ID not in (select ID from #baseData where [Status]>1)
end
else if @Status>-1
begin
	delete from #baseData where ID not in (select ID from #baseData where [Status]=@Status)
end

select count(ID) as dataCount from #baseData

drop table #baseData

END