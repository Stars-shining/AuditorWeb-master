IF OBJECT_ID('dbo.ClearAllInProject', 'P') IS NULL EXEC('Create Procedure dbo.ClearAllInProject AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[ClearAllInProject]
	@projectID int
AS
BEGIN

/*
declare @projectID int
set @projectID=30
*/

delete from APAnswerOptions where AnswerID in (select ID from APAnswers where ResultID in (select ID from APQuestionnaireResults where QuestionnaireID in (select ID from APQuestionnaires where ProjectID=@projectID)))
delete from APAnswers where ResultID in (select ID from APQuestionnaireResults where QuestionnaireID in (select ID from APQuestionnaires where ProjectID=@projectID))
delete from APQuestionnaireResults where QuestionnaireID in (select ID from APQuestionnaires where ProjectID=@projectID)
delete from APQuestionnaireDelivery where ProjectID=@projectID


END