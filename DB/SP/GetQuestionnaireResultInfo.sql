IF OBJECT_ID('dbo.GetQuestionnaireResultInfo', 'P') IS NULL EXEC('Create Procedure dbo.GetQuestionnaireResultInfo AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[GetQuestionnaireResultInfo]
	@resultID int
AS
BEGIN
/*
declare @resultID int
set @resultID=71
*/

select client.Code as ClientCode,
client.Name as ClientName,
qq.Name as QuestionnaireName,
CONVERT(varchar(100), rr.FromDate, 102) + ' - ' + CONVERT(varchar(100), rr.ToDate, 102) as Period,
uu.UserName as VisitUserName,
convert(nvarchar(10),rr.VisitBeginTime,120) as VisitDate, 
right('00'+ Datename(hour,rr.VisitBeginTime),2) + ':' + right('00'+ Datename(minute,rr.VisitBeginTime),2) as VisitBeginTime,
right('00'+ Datename(hour,rr.VisitEndTime),2) + ':' + right('00'+ Datename(minute,rr.VisitEndTime),2) as VisitEndTime,
rr.VisitUserUploadStatus,
rr.VideoPath,
rr.VideoLength,
rr.[Description],
isnull(doc.RelevantPath,'') as PlayPath,
isnull(doc.FileType,'') as PlayType,
qq.TotalScore as FullScore,
rr.Score as Score,
qq.BAutoRefreshPage,
rr.TimeLength,
rr.TimePeriodID,
rr.WeekNum,
client.[Address],
parentClient.Name as ParentClientName
from APQuestionnaireResults rr
inner join APClients client on client.ID=rr.ClientID
inner join APQuestionnaires qq on qq.ID=rr.QuestionnaireID
left join DocumentFiles doc on doc.RelatedID=rr.ID and doc.TypeID=7
left join APUsers uu on uu.ID=rr.VisitUserID
left join APClients parentClient on parentClient.ID=client.ParentID
where rr.ID=@resultID

END