IF OBJECT_ID('dbo.GetParentClients', 'TF') IS NULL EXEC('CREATE FUNCTION [dbo].GetParentClients (	
	@ClientID int
) 
RETURNS @ret TABLE
(
    ID int,
    Code nvarchar(50),
	Name nvarchar(50)
) AS  BEGIN RETURN END')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER FUNCTION [dbo].[GetParentClients]
(
	@ClientID int
)
RETURNS @ret TABLE
(
    ID int,
    Code nvarchar(50),
	Name nvarchar(50),
	LevelID int
)
AS
BEGIN
	
	declare @ID int
	set @ID=@ClientID
	while isnull(@ID,0)>0
	begin
		insert into @ret(ID,Code,Name,LevelID)
		select ID,Code,Name,LevelID from APClients where ID=@ID
		select @ID=ParentID from APClients where ID=@ID
	end
	return
END

