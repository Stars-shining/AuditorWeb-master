IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetClientName]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[GetClientName]
GO
CREATE FUNCTION [dbo].[GetClientName]
(
	@ClientID int,
	@LevelID int
)
RETURNS nvarchar(50) AS
BEGIN
	declare @Value nvarchar(50)
	declare @Name nvarchar(50)
	declare @TempLevelID int
	declare @ID int
	set @ID=@ClientID
	while isnull(@ID,0)>0
	begin
		select @ID=ParentID,@Name=Name,@TempLevelID=LevelID from APClients where ID=@ID
		if @TempLevelID=@LevelID
		begin
			set @Value=@Name
			break;
		end
		else if isnull(@TempLevelID,0)=0
		begin
			set @Value=''
			break;
		end
	end
	return @Value
END
