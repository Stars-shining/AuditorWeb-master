IF OBJECT_ID('dbo.GetTerminalClientIDs', 'TF') IS NULL EXEC('CREATE FUNCTION [dbo].GetTerminalClientIDs (	
	@ProjectID int,
	@ClientID int
) 
RETURNS @ret TABLE
(
    ID int
) AS  BEGIN RETURN END')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER FUNCTION [dbo].[GetTerminalClientIDs]
(
	@ProjectID int,
	@ClientID int
)
RETURNS @ret TABLE
(
    ID int
)
AS
BEGIN
/*
declare @ProjectID int
declare @ClientID int
set @ProjectID=6
set @ClientID=6444
*/

declare @MaxLevelID int
declare @CurrentLevelID int
select @MaxLevelID=MAX(LevelID) from APClientStructure where ProjectID=@ProjectID
select @CurrentLevelID=LevelID from APClients where ID=@ClientID
if @CurrentLevelID=@MaxLevelID
begin
	insert into @ret
	select @ClientID
end
else
begin
	declare @temp table(
		ID int,
		LevelID int
	)

	insert into @temp 
	select @ClientID,@CurrentLevelID

	while @CurrentLevelID<>@MaxLevelID
	begin
		insert into @temp 
		select ID,LevelID from APClients where ProjectID=@ProjectID and ParentID in (select ID from @temp)

		delete from @temp where LevelID=@CurrentLevelID

		set @CurrentLevelID=@CurrentLevelID+1
	end
	
	insert into @ret
	select ID from @temp
end

return

END