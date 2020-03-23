IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetAnswerScore]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[GetAnswerScore]
GO
CREATE FUNCTION [dbo].[GetAnswerScore]
(
	@QuestionID int,
	@ResultID int
)
RETURNS decimal(38,18) AS
BEGIN
	declare @Value decimal(38,18)
	
	select @Value=isnull(aa.TotalScore,0) from APQuestions ap
	inner join APQuestionnaireResults rr on rr.QuestionnaireID=ap.QuestionnaireID
	left join APAnswers aa on aa.QuestionID=ap.ID and aa.ResultID=@ResultID and aa.Status=1
	where ap.ID=@QuestionID
	and rr.ID=@ResultID
	
	return @Value
END
