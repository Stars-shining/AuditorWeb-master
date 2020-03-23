IF OBJECT_ID('dbo.GetTerminalClients', 'TF') IS NULL EXEC('CREATE FUNCTION [dbo].GetTerminalClients (	
	@ProjectID int,
	@ClientID int
) 
RETURNS @ret TABLE
(
    ID int,
    Code nvarchar(50),
	Name nvarchar(50),
	Province nvarchar(50),
	City nvarchar(50),
	District nvarchar(50)
) AS  BEGIN RETURN END')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER FUNCTION [dbo].[GetTerminalClients]
(
	@ProjectID int,
	@ClientID int
)
RETURNS @ret TABLE
(
    ID int,
    Code nvarchar(50),
	Name nvarchar(50),
	Province nvarchar(50),
	City nvarchar(50),
	District nvarchar(50)
)
AS
BEGIN
	
	;with portClients as(
	select * from APClients  where (id=@ClientID or (isnull(@ClientID,0)=0 and ParentID=0)) and ProjectID=@ProjectID
		union all select APClients.* from portClients, APClients where portClients.id = APClients.ParentID and APClients.ProjectID=@ProjectID
	)
	
	insert into @ret(ID,Code,Name,Province,City,District)
	select cc.ID,cc.Code,cc.Name,cc.Province,cc.City,cc.District from portClients cc
	where cc.levelID=(select MAX(levelID) from APClientStructure where ProjectID=@ProjectID)

	return
END

