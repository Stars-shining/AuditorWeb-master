IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetAnswerName]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[GetAnswerName]
GO
CREATE FUNCTION [dbo].[GetAnswerName]
(
	@QuestionID int,
	@ResultID int
)
RETURNS nvarchar(max) AS
BEGIN
	declare @Value nvarchar(max)
	
	declare @Options table (
		optiontext nvarchar(max)
	)
	
	insert into @Options(optiontext)
	select 
	case when ap.QuestionType=4 then ao.OptionText
		 when isnull(ao.OptionText,'')<>'' then isnull(oo.Title,'') +' ('+ ao.OptionText+')' 
		 else oo.Title 
	end as OptionText
	from APQuestions ap
	inner join APQuestionnaireResults rr on rr.QuestionnaireID=ap.QuestionnaireID
	left join APAnswers aa on aa.QuestionID=ap.ID and aa.ResultID=@ResultID and aa.Status=1
	left join APAnswerOptions ao on ao.AnswerID=aa.ID
	left join APOptions oo on ao.OptionID=oo.ID
	where ap.ID=@QuestionID
	and rr.ID=@ResultID
	
	
	select @Value=stuff(
	(
		select ';' + OptionText
		from @Options
		for xml path('')
	),1,1,'')
	from @Options
	
	return @Value
END
