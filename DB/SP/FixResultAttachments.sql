IF OBJECT_ID('dbo.FixResultAttachments', 'P') IS NULL EXEC('Create Procedure dbo.FixResultAttachments AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[FixResultAttachments]
	@ResultID int
AS
BEGIN
/*
declare @ResultID int
set @ResultID=69
*/

	select ID,
	cast(ResultID * 100 as nvarchar(50)) + ' ' + cast(QuestionID * 100 as nvarchar(50)) as TempCode
	into #temp
	from APAnswers where ResultID=@ResultID

	update Documentfiles set RelatedID=tt.ID
	from DocumentFiles ff inner join #temp tt on ff.TempCode=tt.TempCode
	where isnull(ff.RelatedID,0)<=0

	drop table #temp

END