IF OBJECT_ID('dbo.GetAllSubQuestionsByID', 'P') IS NULL EXEC('Create Procedure dbo.GetAllSubQuestionsByID AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[GetAllSubQuestionsByID]
	@ID int
AS
BEGIN
/*
declare @ID int
set @ID=1
*/
declare @questionID int
declare @questionnaireID int
declare @parentcode nvarchar(50)
declare @questionType int

declare @SubQuestions table(
	ID int
)

select @questionID=ID, @parentcode=Code, @questionType=QuestionType, @questionnaireID=QuestionnaireID from APQuestions where ID=@ID
if isnull(@parentcode,'')<>''
begin
	
	select ID,Code,QuestionType into #subQuestions from APQuestions where ParentCode=@parentcode and QuestionnaireID=@questionnaireID
	
	while exists (select ID from #subQuestions)
	begin
		declare @subID int
		declare @subTypeID int
		set rowcount 1
		select @subID=ID,@subTypeID=QuestionType from #subQuestions
		set rowcount 0
		
		insert into @SubQuestions (ID)
		select @subID
		
		if @subTypeID=7 --段落才会有子节点
		begin
			INSERT INTO @SubQuestions(ID)
			EXEC [GetAllSubQuestionsByID] @subID
		end
		
		delete from #subQuestions where ID=@subID
	end
	drop table #subQuestions
end

select ID from @SubQuestions

End