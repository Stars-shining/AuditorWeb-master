IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetClientCode]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[GetClientCode]
GO
CREATE FUNCTION [dbo].[GetClientCode]
(
	@ClientID int,
	@LevelID int
)
RETURNS nvarchar(50) AS
BEGIN
	declare @Value nvarchar(50)
	declare @Code nvarchar(50)
	declare @TempLevelID int
	declare @ID int
	set @ID=@ClientID
	while isnull(@ID,0)>0
	begin
		select @ID=ParentID,@Code=Code,@TempLevelID=LevelID from APClients where ID=@ID
		if @TempLevelID=@LevelID
		begin
			set @Value=@Code
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
