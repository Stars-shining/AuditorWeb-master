IF OBJECT_ID('dbo.GetClientAppealStatus', 'P') IS NULL EXEC('Create Procedure dbo.GetClientAppealStatus AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[GetClientAppealStatus]
	@projectID int
AS
BEGIN
/*
declare @projectID int
set @projectID=7
*/

declare @TerminalClientLevelID int
declare @TopClientLevelID int
select @TerminalClientLevelID=MAX(LevelID),@TopClientLevelID=MIN(LevelID) from APClientStructure where ProjectID=@projectID

select LevelID,
Name + case when levelID=@TerminalClientLevelID then '…ÍÀﬂ÷–' else '…Û∫À÷–' end as Name
into #tempLevels
from APClientStructure
where ProjectID=@projectID
order by LevelID desc

select * from #tempLevels

drop table #tempLevels

END