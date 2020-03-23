IF OBJECT_ID('dbo.GetQuestionnaireAnswers', 'P') IS NULL EXEC('Create Procedure dbo.GetQuestionnaireAnswers AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[GetQuestionnaireAnswers]
	@ResultID int
AS
BEGIN
/*
declare @ResultID int
set @ResultID=34
*/

select 
ap.ID,
ap.ParentCode,
ap.Code,
ap.Title,
aa.TotalScore,
ap.QuestionType,
aa.ID as AnswerID,
case when ap.QuestionType=4 then ao.OptionText
	 when isnull(ao.OptionText,'')<>'' then isnull(oo.Title,'') +' ('+ ao.OptionText+')' 
	else oo.Title 
end as OptionText,
ap.bAllowImage,
ap.bAllowAudio,
ap.bAllowVideo
into #tempQuestions
from APQuestions ap
inner join APQuestionnaireResults rr on rr.QuestionnaireID=ap.QuestionnaireID
left join APAnswers aa on aa.QuestionID=ap.ID and aa.ResultID=@ResultID and aa.Status=1
left join APAnswerOptions ao on ao.AnswerID=aa.ID
left join APOptions oo on oo.ID=ao.OptionID
where rr.ID=@ResultID

select ID,ParentCode,Code,Title,TotalScore,QuestionType,AnswerID,
stuff(
(
	select '\r\n' + OptionText
	from #tempQuestions
	where ID=que.ID
	and Code=que.Code
	and Title=que.Title
	and TotalScore=que.TotalScore
	and AnswerID=que.AnswerID
	order by Code
	for xml path('')
),1,4,'') as OptionText,
bAllowImage,
bAllowAudio,
bAllowVideo
into #tempResult
from #tempQuestions que
group by ID,ParentCode,Code,Title,TotalScore,QuestionType,AnswerID,bAllowImage,bAllowAudio,bAllowVideo

/*calculate parent question score*/
declare @zeroDecimal decimal(38,18)
set @zeroDecimal=0
select parentcode, SUM(totalscore) as totalscore into #scores from #tempResult where questiontype<>7 group by parentCode
while exists(select * from #scores)
begin
	declare @code nvarchar(50)
	declare @score decimal(38,18)
	set rowcount 1
	select @code=parentcode,@score=totalscore from #scores
	set rowcount 0
	
	update #tempResult set totalscore=@score where code=@code
	
	declare @parentcode nvarchar(50)
	select @parentcode=parentcode from #tempResult where code=@code
	while isnull(@parentcode,'')<>''
	begin
		update #tempResult set totalscore=isnull(totalscore,@zeroDecimal)+@score where code=@parentcode
		select @parentcode=parentcode from #tempResult where code=@parentcode
	end
	
	delete from #scores where parentcode=@code
end


select rr.ID,rr.ParentCode,rr.Code,rr.Title,rr.TotalScore,rr.QuestionType,rr.AnswerID,rr.OptionText,rr.bAllowImage,rr.bAllowAudio,rr.bAllowVideo,
(select COUNT(doc.ID) from DocumentFiles doc where doc.RelatedID=rr.AnswerID and doc.TypeID=3 and doc.Status=0) as UploadFileNumber,
(select COUNT(doc.ID) from DocumentFiles doc where doc.RelatedID=rr.AnswerID and doc.TypeID=4 and doc.Status=0) as AuditFileNumber,
(select COUNT(doc.ID) from DocumentFiles doc where doc.RelatedID=rr.AnswerID and doc.TypeID=5 and doc.Status=0) as ClientFileNumber
into #tempResultAuditNotes
from #tempResult rr
group by rr.ID,rr.ParentCode,rr.Code,rr.Title,rr.TotalScore,rr.QuestionType,rr.AnswerID,rr.OptionText,rr.bAllowImage,rr.bAllowAudio,rr.bAllowVideo
order by rr.Code

/*
declare @auditNotes nvarchar(max)
declare @clientNotes nvarchar(max)
set @auditNotes=''
set @clientNotes=''
*/

select rr.ID,rr.ParentCode,rr.Code,rr.Title,rr.TotalScore,rr.QuestionType,rr.AnswerID,rr.OptionText,rr.bAllowImage,rr.bAllowAudio,rr.bAllowVideo,
rr.UploadFileNumber,rr.AuditFileNumber,rr.ClientFileNumber,
stuff(
(
	select '\r\n' + ('[' + uu.Name + ']: ' + aa.AuditNotes + ' ' + CONVERT(nvarchar(16), aa.CreateTime, 120))
	from dbo.APQuestionAuditNotes aa
	left join APUserRole uu on uu.ID=aa.UserTypeID
	where aa.QuestionID=rr.ID and aa.ResultID=@ResultID and aa.AuditTypeID=3
	order by aa.CreateTime
	for xml path('')
),1,4,'') as AuditNotes,
stuff(
(
	select '\r\n' + ('[' + uu.UserName + ']: ' + aa.AuditNotes + ' ' + CONVERT(nvarchar(16), aa.CreateTime, 120))
	from dbo.APQuestionAuditNotes aa
	left join APUsers uu on uu.ID=aa.CreateUserID
	where aa.QuestionID=rr.ID and aa.ResultID=@ResultID and aa.AuditTypeID in (4,5)
	order by aa.CreateTime
	for xml path('')
),1,4,'') as ClientNotes

from #tempResultAuditNotes rr
group by rr.ID,rr.ParentCode,rr.Code,rr.Title,rr.TotalScore,rr.QuestionType,rr.AnswerID,rr.OptionText,rr.bAllowImage,rr.bAllowAudio,rr.bAllowVideo,
rr.UploadFileNumber,rr.AuditFileNumber,rr.ClientFileNumber
order by rr.Code

drop table #tempQuestions
drop table #tempResult
drop table #scores
drop table #tempResultAuditNotes

END
