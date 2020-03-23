IF OBJECT_ID('dbo.GetQuestionPath', 'P') IS NULL EXEC('Create Procedure dbo.GetQuestionPath AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[GetQuestionPath]
	@QuestionID int
AS
BEGIN
/*
declare @QuestionID int
set @QuestionID=917
*/

declare @QuestionnaireID int
declare @code nvarchar(50)
declare @parentcode nvarchar(50)
declare @title nvarchar(50)
declare @questionType int
declare @questionpath nvarchar(500)

select @QuestionnaireID=QuestionnaireID,@parentcode=ParentCode,@code=Code,@title=Title,@questionType=QuestionType from APQuestions where ID=@QuestionID
if @questionType=7
begin
	set @questionpath=@title
end
else
begin
	set @questionpath=@title
end
while isnull(@parentcode,'')<>'' and isnull(@code,'')<>isnull(@parentcode,'')
begin
	if exists(select code from APQuestions where Code=@parentcode and QuestionnaireID=@QuestionnaireID)
	begin
		select @parentcode=ParentCode,@code=Code,@title=Title from APQuestions where Code=@parentcode and QuestionnaireID=@QuestionnaireID
		set @questionpath= @title + ' > ' + @questionpath
	end
	else
	begin
		break
	end
end

select @questionpath as QuestionPath

End