IF OBJECT_ID('dbo.GetQuestionnaires', 'P') IS NULL EXEC('Create Procedure dbo.GetQuestionnaires AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[GetQuestionnaires]
	@Name nvarchar(50),
	@FromDate datetime,
	@ToDate datetime,
	@Status int,
	@UserID int,
	@RoleID int,
	@ProjectID int
AS
BEGIN
/*
declare @Name nvarchar(50)
declare @FromDate datetime
declare @ToDate datetime
declare @Status int
declare @UserID int
declare @RoleID int
declare @ProjectID int

set @Name=''
set @FromDate=NULL
set @ToDate=NULL
set @Status=NULL
set @UserID=6
set @RoleID=4
set @ProjectID=2
*/

select app.ID,
app.Name,
app.FromDate,
app.ToDate,
app.SampleNumber,
bc.ItemValue as 'QuestionnaireStatus'
into #tempResult
from [dbo].APQuestionnaires app
left join BusinessConfiguration bc on app.[Status]=bc.ItemKey and bc.ItemDesc='QuestionnaireStatus'
where app.ProjectID=isnull(@ProjectID,app.ProjectID)
and app.[Status]=ISNULL(@Status,app.[Status])
and isnull(app.DeleteFlag,0)=0

if isnull(@Name,'')<>''
begin
	delete from #tempResult where ID not in (select ID from #tempResult where Name like '%'+@Name+'%')
end

if @FromDate<>NULL
begin
	delete from #tempResult where ToDate<@FromDate
end

if @ToDate<>NULL
begin
	delete from #tempResult where FromDate>@ToDate
end

--区控 = 2, -- 区控页面太卡了，所以先不用过滤区控
--执行督导 = 3,
--访问员 = 4,
if @RoleID=3 or @RoleID=4
begin
	declare @AllClients table (
		ID int,
		FromDate datetime,
		ToDate datetime,
		QuestionnaireID int
	)
	select ClientID,FromDate,ToDate,QuestionnaireID into #allClients from dbo.APQuestionnaireDelivery where TypeID=@RoleID
	and ProjectID=@ProjectID
	and AcceptUserID=@UserID
	
	while exists(select ClientID from #allClients)
	begin
		declare @tempClientID int
		declare @tempFrom datetime
		declare @tempTo datetime
		declare @tempQuestionnaireID int
		set rowcount 1
		select @tempClientID=ClientID,@tempFrom=FromDate,@tempTo=ToDate,@tempQuestionnaireID=QuestionnaireID from #allClients
		set rowcount 0
		
		insert into @AllClients
		select ID,@tempFrom,@tempTo,@tempQuestionnaireID from dbo.GetTerminalClients(@ProjectID,@tempClientID)
		
		delete from #allClients where ClientID=@tempClientID and FromDate=@tempFrom and ToDate=@tempTo and QuestionnaireID=@tempQuestionnaireID
	end
	
	drop table #allClients
	
	delete from #tempResult where ID not in (select distinct QuestionnaireID from @AllClients)
end

	
select * from #tempResult

drop table #tempResult

END