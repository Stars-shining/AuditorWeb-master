IF OBJECT_ID('dbo.GetWrongQuestions', 'P') IS NULL EXEC('Create Procedure dbo.GetWrongQuestions AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[GetWrongQuestions]
	@QuestionnaireID int,
	@FromDate datetime,
	@ToDate datetime,
	@StageStatusID int,
	@StatusID int,
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
declare @Keyword nvarchar(50)
declare @CurrentClientID int
set @QuestionnaireID=1116
set @FromDate='2019-01-01'
set @ToDate='2019-03-31'
set @StageStatusID=5
set @StatusID=-999
set @Keyword=''
set @CurrentClientID=27216
*/


declare @projectID int
select @projectID=ProjectID from APQuestionnaires where ID=@QuestionnaireID

select * into #QueResults from APQuestionnaireResults where QuestionnaireID=@QuestionnaireID and FromDate<=@FromDate and ToDate>=@ToDate
select aa.* into #QueAnswers from APAnswers aa inner join #QueResults rr on rr.ID=aa.ResultID
select * into #tempQuestions from APQuestions where QuestionnaireID=@QuestionnaireID
select * into #allUsers from APUsers where ProjectID=@projectID
select * into #allClients from APClients where ProjectID=@projectID

declare @topClientID int
declare @topUserID int
select @topClientID=ID from #allClients where isnull(ParentID,0)=0
select @topUserID=ID from #allUsers where ProjectID=@projectID and ClientID=@topClientID

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

select aa.ResultID,
aa.QuestionID,
rr.ClientID,
rr.Status,
cc.Code,
cc.Name,
cc2.Code as ParentCode,
cc2.Name as ParentName,
uu.ID as UserID,
uu2.ID as ParentUserID
into #temp
from #QueAnswers aa
inner join #QueResults rr on rr.ID=aa.ResultID
inner join @allClients allClient on allClient.ID=rr.ClientID
inner join #allClients cc on cc.ID=allClient.ID--支行机构
inner join #allClients cc2 on cc2.ID=cc.ParentID--分行机构
inner join #tempQuestions que on que.ID=aa.QuestionID
left join #allUsers uu on uu.ClientID=cc.ID --支行用户
left join #allUsers uu2 on uu2.ClientID=cc.ParentID--分行用户
where aa.TotalScore<>que.TotalScore

if isnull(@Keyword,'')<>''
begin
	delete from #temp where ClientID not in (select ClientID from #temp where Code like '%'+@Keyword+'%' or Name like '%'+@Keyword+'%')
end

if @StageStatusID>=0
begin
	delete from #temp where Status<>@StageStatusID
end


select aa.* into #allNotes from APQuestionAuditNotes aa
inner join #QueResults rr on rr.ID=aa.ResultID
where rr.QuestionnaireID=@QuestionnaireID
select dd.ID,dd.RelatedID,dd.TypeID into #allFiles from DocumentFiles dd
inner join #QueResults rr on rr.ID=dd.ResultID
where rr.QuestionnaireID=@QuestionnaireID and dd.Status=0

--找到所有申诉说明，以及文件的数量
select 
tt.Code,
tt.Name,
tt.ParentCode,
tt.ParentName,
queParent.Code + ' ' + queParent.Title as 'ParentQuestion', 
que.Code + ' ' + que.Title as 'Question', 
que.Code  as QuestionCode,
tt.ResultID,tt.QuestionID,tt.ClientID,
stuff(
(
	select ';' + nn.AuditNotes
	from #allNotes nn 
	where tt.ResultID=nn.ResultID
	and tt.QuestionID=nn.QuestionID
	and nn.CreateUserID=tt.UserID
	order by nn.ID
	for xml path('')
),1,1,'') as AuditNotes,
stuff(
(
	select ';' + nn.AuditNotes
	from #allNotes nn 
	where tt.ResultID=nn.ResultID
	and tt.QuestionID=nn.QuestionID
	and nn.CreateUserID=tt.ParentUserID
	order by nn.ID 
	for xml path('')
),1,1,'') as AuditNotes2,
stuff(
(
	select ';' + nn.AuditNotes
	from #allNotes nn
	where tt.ResultID=nn.ResultID
	and tt.QuestionID=nn.QuestionID
	and nn.CreateUserID=@topUserID
	order by nn.ID
	for xml path('')
),1,1,'') as AuditNotes4,
que.TotalScore as TotalScore,
ans.TotalScore as Score,
ans.ID as AnswerID,
ans.Description as Description,
que.QuestionType,

(select COUNT(doc.ID) from #allFiles doc where doc.RelatedID=ans.ID and doc.TypeID=3) as UploadFileNumber,
(select COUNT(doc.ID) from #allFiles doc where doc.RelatedID=ans.ID and doc.TypeID=4) as AuditFileNumber,
(select COUNT(doc.ID) from #allFiles doc where doc.RelatedID=ans.ID and doc.TypeID=5) as ClientFileNumber,

tt.Status
into #tempResult
from #temp tt
inner join #tempQuestions que on que.ID=tt.QuestionID
inner join #tempQuestions queParent on queParent.Code=que.ParentCode and que.QuestionnaireID=queParent.QuestionnaireID
inner join #QueAnswers ans on ans.ResultID=tt.ResultID and ans.QuestionID=tt.QuestionID
group by tt.Code,tt.Name,tt.ParentCode,tt.ParentName,queParent.Code,queParent.Title, que.Code,que.Title,tt.ResultID,
tt.QuestionID,tt.ClientID,que.TotalScore,ans.TotalScore,ans.ID,ans.Description,que.QuestionType,tt.Status,tt.UserID,tt.ParentUserID

select *, case when isnull(AuditNotes,'')='' then 0 else 1 end as HasAuditNotes into #result from #tempResult

--找到扣分选项以及补充的说明
select tt.*,
stuff(
(
	select ';' + (case when isnull(ao.OptionText,'')<>'' then isnull(oo.Title,'') +' ('+ ao.OptionText+')' 
	else oo.Title  end)
	from #temp aa
	inner join #QueAnswers an on an.QuestionID=aa.QuestionID and an.ResultID=aa.ResultID
	inner join APAnswerOptions ao on ao.AnswerID=an.ID
	inner join APOptions oo on oo.ID=ao.OptionID
	where aa.ClientID=tt.ClientID
	and aa.QuestionID=tt.QuestionID
	and aa.ResultID=tt.ResultID
	order by oo.ID
	for xml path('')
),1,1,'') 

+

case when tt.Description is not NULL and tt.Description<>'' then '(扣分描述：'+tt.Description+')'
else '' end as OptionText 
from #result tt 
group by tt.Code,tt.Name,tt.ParentCode,tt.ParentName,tt.ParentQuestion,tt.Question,tt.QuestionCode,tt.ResultID,tt.QuestionID,tt.ClientID,tt.TotalScore,tt.Score,tt.AnswerID,tt.Description,tt.QuestionType,tt.Status,
tt.HasAuditNotes,tt.AuditNotes,tt.AuditNotes2,tt.AuditNotes4,tt.UploadFileNumber,tt.AuditFileNumber,tt.ClientFileNumber
order by tt.HasAuditNotes desc, tt.Code, tt.QuestionCode

drop table #allClients
drop table #allUsers
drop table #tempQuestions
drop table #QueResults
drop table #QueAnswers
drop table #result
drop table #allFiles
drop table #allNotes
drop table #temp
drop table #tempResult
END