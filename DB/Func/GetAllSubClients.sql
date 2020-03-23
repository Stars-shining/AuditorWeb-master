IF OBJECT_ID('dbo.GetAllSubClients', 'TF') IS NULL EXEC('CREATE FUNCTION [dbo].GetAllSubClients (	
	@ProjectID int,
	@ClientID int
) 
RETURNS @ret TABLE
(
    ID int,
    ParentID int,
    Code nvarchar(50),
	Name nvarchar(50),
	Province nvarchar(50),
	City nvarchar(50),
	District nvarchar(50)
) AS  BEGIN RETURN END')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER FUNCTION [dbo].[GetAllSubClients]
(
	@ProjectID int,
	@ClientID int
)
RETURNS @ret TABLE
(
    ID int,
    ParentID int,
    Code nvarchar(50),
	Name nvarchar(50),
	Province nvarchar(50),
	City nvarchar(50),
	District nvarchar(50),
	IsTerminal bit
)
AS
BEGIN
	declare @TerminalLevelID int
	select @TerminalLevelID=MAX(levelID) from APClientStructure where ProjectID=@ProjectID
	
	;with portClients as(
	select * from APClients  where (id=@ClientID or (isnull(@ClientID,0)=0 and ParentID=0)) and ProjectID=@ProjectID
		union all select APClients.* from portClients, APClients where portClients.id = APClients.ParentID and APClients.ProjectID=@ProjectID
	)
	
	insert into @ret(ID,ParentID,Code,Name,Province,City,District,IsTerminal)
	select cc.ID,cc.ParentID,cc.Code,cc.Name,cc.Province,cc.City,cc.District,
	case when cc.LevelID=@TerminalLevelID then 1 else 0 end
	from portClients cc

	return
END

