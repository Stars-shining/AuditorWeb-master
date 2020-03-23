IF OBJECT_ID('dbo.GetQuestionnaireResultsFiles', 'P') IS NULL EXEC('Create Procedure dbo.GetQuestionnaireResultsFiles AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[GetQuestionnaireResultsFiles]
	@ProjectID int,
	@QuestionnaireID int,
	@ClientID int,
	@FromDate datetime,
	@ToDate datetime,
	@Status int
AS

BEGIN
/*
declare @ProjectID int
declare @QuestionnaireID int
declare @ClientID int
declare @FromDate datetime
declare @ToDate datetime
declare @Status int

set @ProjectID=1
set @QuestionnaireID=2
set @ClientID=-999
set @FromDate='2017-9-1'
set @ToDate='2017-12-31'
set @Status = -999
*/

select rr.ID, rr.ClientID, rr.[Status] into #baseData
from APQuestionnaireResults rr
inner join APClients cc on cc.ID=rr.ClientID and cc.ProjectID=@ProjectID
left join APUsers uu on uu.ID=rr.VisitUserID
where rr.QuestionnaireID=@QuestionnaireID
and rr.ToDate>=@FromDate
and rr.FromDate<=@ToDate
--and rr.[Status]=ISNULL(@Status,rr.[Status])
order by cc.Code

if @Status=-1
begin
	delete from #baseData where ID not in (select ID from #baseData where [Status]>1)
end
else if @Status>-1
begin
	delete from #baseData where ID not in (select ID from #baseData where [Status]=@Status)
end

alter table #baseData drop column [Status]

if @ClientID>0
begin
	delete from #baseData where ClientID not in (select distinct ID from GetTerminalClientIDs(@ProjectID,@ClientID))
end


select ff.* from dbo.DocumentFiles ff
inner join dbo.APAnswers aa on ff.RelatedID=aa.ID
inner join #baseData rr on rr.ID=aa.ResultID
where ff.Status=0

drop table #baseData

END