IF OBJECT_ID('dbo.GetClientAppeals', 'P') IS NULL EXEC('Create Procedure dbo.GetClientAppeals AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[GetClientAppeals]
	@QuestionnaireID int,
	@FromDate datetime,
	@ToDate datetime
AS
BEGIN
/*
declare @QuestionnaireID int
declare @FromDate datetime
declare @ToDate datetime
set @QuestionnaireID=15
set @FromDate='2017-09-01'
set @ToDate='2017-09-30'
*/

declare @topClientID int
select @topClientID=cc.ID from APClients cc
inner join APQuestionnaires que on que.ProjectID=cc.ProjectID
where que.ID=@QuestionnaireID 
and isnull(cc.ParentID,0)=0

select nn.ResultID,nn.QuestionID,rr.ClientID,
stuff(
(
	select ';' + aa.AuditNotes
	from [APQuestionAuditNotes] aa 
	where aa.ResultID=nn.ResultID
	and aa.QuestionID=nn.QuestionID
	and aa.CreateUserID=uu.ID
	order by aa.ID
	for xml path('')
),1,1,'') as AuditNotes,
stuff(
(
	select ';' + aa.AuditNotes
	from [APQuestionAuditNotes] aa 
	where aa.ResultID=nn.ResultID
	and aa.QuestionID=nn.QuestionID
	and aa.CreateUserID=uu2.ID
	order by aa.ID
	for xml path('')
),1,1,'') as AuditNotes2,
stuff(
(
	select ';' + aa.AuditNotes
	from [APQuestionAuditNotes] aa
	where aa.ResultID=nn.ResultID
	and aa.QuestionID=nn.QuestionID
	and aa.CreateUserID=pp.QCLeaderUserID
	order by aa.ID
	for xml path('')
),1,1,'') as AuditNotes3,
stuff(
(
	select ';' + aa.AuditNotes
	from [APQuestionAuditNotes] aa
	where aa.ResultID=nn.ResultID
	and aa.QuestionID=nn.QuestionID
	and aa.CreateUserID=uu3.ID
	order by aa.ID
	for xml path('')
),1,1,'') as AuditNotes4
into #temp
from [dbo].[APQuestionAuditNotes] nn
inner join APQuestionnaireResults rr on rr.ID=nn.ResultID
inner join APClients cc on cc.ID=rr.ClientID
inner join APusers uu on uu.ClientID=cc.ID
inner join APUsers uu2 on uu2.ClientID=cc.ParentID
inner join APusers uu3 on uu3.ClientID=@topClientID
inner join APProjects pp on pp.ID=cc.ProjectID
where rr.Status in (6,7) and nn.AuditTypeID=4 and nn.UserTypeID=9
and rr.FromDate<=@FromDate
and rr.ToDate>=@ToDate
and rr.QuestionnaireID=@QuestionnaireID 
group by nn.ResultID,nn.QuestionID,rr.ClientID,uu.ID,uu2.ID,pp.QCLeaderUserID,uu3.ID

select parentCC.Code as 'ParentCode',
parentCC.Name as 'ParentName', 
cc.Code,
cc.Name, 
queParent.Code + ' ' + queParent.Title as 'ParentQuestion', 
que.Code + ' ' + que.Title as 'Question', 
que.Code  as QuestionCode,
stuff(
(
	select ';' + (case when isnull(ao.OptionText,'')<>'' then isnull(oo.Title,'') +' ('+ ao.OptionText+')' 
	else oo.Title  end)
	from #temp aa
	inner join APAnswers an on an.QuestionID=aa.QuestionID and an.ResultID=aa.ResultID
	inner join APAnswerOptions ao on ao.AnswerID=an.ID
	inner join APOptions oo on oo.ID=ao.OptionID
	where aa.ClientID=tt.ClientID
	and aa.QuestionID=tt.QuestionID
	and aa.ResultID=tt.ResultID
	order by oo.ID
	for xml path('')
),1,1,'') as OptionText,
tt.ResultID,tt.QuestionID,tt.ClientID,tt.AuditNotes,tt.AuditNotes2,AuditNotes3,AuditNotes4,
que.TotalScore as TotalScore,
ans.TotalScore as Score
from #temp tt
inner join APClients cc on cc.ID=tt.ClientID
inner join APClients parentCC on parentCC.ID=cc.ParentID
inner join APQuestions que on que.ID=tt.QuestionID
inner join APQuestions queParent on queParent.Code=que.ParentCode and que.QuestionnaireID=queParent.QuestionnaireID
inner join APAnswers ans on ans.ResultID=tt.ResultID and ans.QuestionID=tt.QuestionID
group by parentCC.Code,parentCC.Name,cc.Code,cc.Name, 
queParent.Code,queParent.Title, que.Code,que.Title, 
tt.ResultID,tt.QuestionID,tt.ClientID,tt.AuditNotes,tt.AuditNotes2,AuditNotes3,AuditNotes4,que.TotalScore,ans.TotalScore
order by cc.Code,que.Code

drop table #temp

END