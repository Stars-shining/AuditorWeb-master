IF OBJECT_ID('dbo.GetQuestionAppeals', 'P') IS NULL EXEC('Create Procedure dbo.GetQuestionAppeals AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[GetQuestionAppeals]
	@QuestionnaireID int,
	@FromDate datetime,
	@ToDate datetime,
	@StageStatusID int,
	@StatusID int,
	@ClientLevelID int,
	@Keyword nvarchar(50),
	@CurrentClientID int
AS
BEGIN

/*
declare @QuestionnaireID int
declare @FromDate datetime
declare @ToDate datetime
declare @StageStatusID int
declare @StatusID int
declare @ClientLevelID int
declare @Keyword nvarchar(50)
set @QuestionnaireID=15
set @FromDate='2017-09-01'
set @ToDate='2017-09-30'
set @StageStatusID=5
set @StatusID=-999
set @ClientLevelID=0
set @Keyword=''
*/

declare @projectID int
select @projectID=ProjectID from APQuestionnaires where ID=@QuestionnaireID

declare @topClientID int
select @topClientID=ID from APClients where ProjectID=@projectID and isnull(ParentID,0)=0

declare @allClients table(
	ID int
)

if @CurrentClientID>0
begin
	insert into @allClients
	select ID from GetTerminalClientIDs(@projectID,@CurrentClientID)
end
else
begin
	insert into @allClients
	select ID from GetTerminalClientIDs(@projectID,@topClientID)
end

select nn.ResultID,nn.QuestionID,rr.ClientID,
rr.ClientUserAuditStatus,rr.Status, 
cc.Code as ClientCode,cc.Name as ClientName,
ISNULL(cc2.LevelID,-1) as LevelID,
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
inner join @allClients allClient on allClient.ID=rr.ClientID
inner join APClients cc on cc.ID=allClient.ID
inner join APusers uu on uu.ClientID=cc.ID
inner join APUsers uu2 on uu2.ClientID=cc.ParentID
inner join APusers uu3 on uu3.ClientID=@topClientID
inner join APProjects pp on pp.ID=cc.ProjectID
left join APUsers uu4 on uu4.ID=rr.CurrentClientUserID
left join APClients cc2 on cc2.ID=uu4.ClientID
where nn.AuditTypeID=4 and nn.UserTypeID=9
and rr.FromDate<=@FromDate
and rr.ToDate>=@ToDate
and rr.QuestionnaireID=@QuestionnaireID
group by nn.ResultID,nn.QuestionID,rr.ClientID,rr.ClientUserAuditStatus,rr.Status,cc.Code,cc.Name,cc2.LevelID,uu.ID,uu2.ID,pp.QCLeaderUserID,uu3.ID

if isnull(@Keyword,'')<>''
begin
	delete from #temp where ClientID not in (select ClientID from #temp where ClientCode=@Keyword or ClientName like '%'+@Keyword+'%')
end

if @StageStatusID>=0
begin
	delete from #temp where Status<>@StageStatusID
end

/**通过Levelid筛选处于哪个客户级别的审核**/
if isnull(@ClientLevelID,0)>0
begin
	delete from #temp where LevelID<>@ClientLevelID
end

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
ans.TotalScore as Score,
ans.ID as AnswerID,
que.QuestionType,

(select COUNT(doc.ID) from DocumentFiles doc where doc.RelatedID=ans.ID and doc.TypeID=3 and doc.Status=0) as UploadFileNumber,
(select COUNT(doc.ID) from DocumentFiles doc where doc.RelatedID=ans.ID and doc.TypeID=4 and doc.Status=0) as AuditFileNumber,
(select COUNT(doc.ID) from DocumentFiles doc where doc.RelatedID=ans.ID and doc.TypeID=5 and doc.Status=0) as ClientFileNumber,

tt.Status
into #tempResult
from #temp tt
inner join APClients cc on cc.ID=tt.ClientID
inner join APClients parentCC on parentCC.ID=cc.ParentID
inner join APQuestions que on que.ID=tt.QuestionID
inner join APQuestions queParent on queParent.Code=que.ParentCode and que.QuestionnaireID=queParent.QuestionnaireID
inner join APAnswers ans on ans.ResultID=tt.ResultID and ans.QuestionID=tt.QuestionID
group by parentCC.Code,parentCC.Name,cc.Code,cc.Name, 
queParent.Code,queParent.Title, que.Code,que.Title, 
tt.ResultID,tt.QuestionID,tt.ClientID,tt.AuditNotes,tt.AuditNotes2,AuditNotes3,AuditNotes4,que.TotalScore,ans.TotalScore,ans.ID,que.QuestionType,tt.Status
order by cc.Code,que.Code

select rr.*,
isnull(aa.AppealStatus,0) as AppealStatus,
bc.ItemValue as AppealStatusText
into #tempFinal
from #tempResult rr
left join APAppealAudit aa on aa.ResultID=rr.ResultID and aa.QuestionID=rr.QuestionID
left join BusinessConfiguration bc on bc.ItemKey=isnull(aa.AppealStatus,0) and bc.ItemDesc='QuestionAppealStatus'

if @StatusID>=0
begin
	delete from #tempFinal where AppealStatus<>@StatusID
end

select * from #tempFinal

drop table #temp
drop table #tempResult

END