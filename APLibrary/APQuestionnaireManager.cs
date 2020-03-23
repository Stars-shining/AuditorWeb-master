using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using APLibrary.DataObject;
using System.Data.SqlClient;
using System.Data;

namespace APLibrary
{
    public class APQuestionnaireManager : BusinessLogicBase
    {
        private static BusinessLogicBase baseLogic = new BusinessLogicBase();

        public static APQuestionnairesDO GetQuestionnaireByID(int id)
        {
            APQuestionnairesDO qnDO = new APQuestionnairesDO();
            return (APQuestionnairesDO)baseLogic.Select(qnDO, id);
        }

        public static DataTable GetQuestionnaireInfoByID(int id)
        {
            string sql = @"
select app.*,
bc.ItemValue as QuestionnaireStatus,
CONVERT(nvarchar(16),app.CreateTime,20) + ' ' + createUser.UserName as CreatingInfo,
CONVERT(nvarchar(16),app.LastModifiedTime,20) + ' ' + editingUser.UserName as EditingInfo
from dbo.APQuestionnaires app
left join BusinessConfiguration bc on app.[Status]=bc.ItemKey and bc.ItemDesc='QuestionnaireStatus'
left join APUsers createUser on app.CreateUserID=createUser.ID
left join APUsers editingUser on app.LastModifiedUserID=editingUser.ID
where app.ID=@ID";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@ID", id);
            DataTable dt = baseLogic.Select(sql, pars);
            return dt;
        }

        public static APQuestionsDO GetQuestionDOByID(int id)
        {
            APQuestionsDO qnDO = new APQuestionsDO();
            return (APQuestionsDO)baseLogic.Select(qnDO, id);
        }

        public static DataTable GetAllQuestionsByQID(int id)
        {
            string sql = @"select ap.ID,
ap.Code,
ap.Title,
ap.TotalScore,
ap.QuestionType,
bc.ItemValue as 'QuestionTypeName'
from dbo.APQuestions ap 
left join BusinessConfiguration bc on ap.QuestionType=bc.ItemKey and bc.ItemDesc='QuestionType'
where ap.QuestionnaireID=@ID
order by ap.Code";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@ID", id);
            DataTable dt = baseLogic.Select(sql, pars);
            return dt;
        }

        public static DataTable GetPreviewQuestionsByQID(int id)
        {
            string sql = @"select ap.ID,ap.Code,ap.ParentCode,
ap.Title,
ap.TotalScore,
ap.QuestionType,
ap.CountType,
bc.ItemValue as 'CountTypeName',
bc2.ItemValue as 'QuestionTypeName',
REPLACE(stuff((select tb.Title + ';'+(case when tb.score<>0 then ' (' + cast( cast(tb.score as real) as nvarchar(50)) + ')' else '' end)+'<br/>' from APOptions tb where tb.QuestionID=ap.ID for xml path('')), 1, 0, ''),'&lt;br/&gt;','<br/>') as Options,
REPLACE(stuff((select tb.Title + ';<br/>' from APOptions tb where ((ap.CountType<>6 and tb.bCorrectOption=0) or (ap.CountType=6 and abs(isnull(tb.Score,0))>0)) and tb.QuestionID=ap.ID for xml path('')), 1, 0, ''),'&lt;br/&gt;','<br/>') as WrongOptions
from dbo.APQuestions ap 
left join APOptions op on ap.ID=op.QuestionID
left join BusinessConfiguration bc on bc.ItemKey=ap.CountType and bc.ItemDesc='CountType'
left join BusinessConfiguration bc2 on bc2.ItemKey=ap.QuestionType and bc2.ItemDesc='QuestionType'
where ap.QuestionnaireID=@ID
group by ap.ID,ap.Code,ap.ParentCode,
ap.Title,
ap.TotalScore,
ap.QuestionType,
ap.CountType,
bc.ItemValue,
bc2.ItemValue
order by ap.Code";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@ID", id);
            DataTable dt = baseLogic.Select(sql, pars);
            return dt;
        }

        public static DataTable GetAllLinkedQuestionsByQID(int qid, int currentQID)
        {
            string sql = @"select ID,
Code + Title as 'Title'
from dbo.APQuestions
where QuestionType in (1,2)
and QuestionnaireID=@QID and ID<>@currentQuestionID";
            SqlParameter[] pars = new SqlParameter[2];
            pars[0] = new SqlParameter("@QID", qid);
            pars[1] = new SqlParameter("@currentQuestionID", currentQID);
            DataTable dt = baseLogic.Select(sql, pars);
            return dt;
        }

        public static DataTable GetAllLinkedOptionsByQID(int questionID)
        {
            string sql = @"select ID,Title from dbo.APOptions where QuestionID=@QID";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@QID", questionID);
            DataTable dt = baseLogic.Select(sql, pars);
            return dt;
        }

        public static DataTable GetQuestionnaires(int projectID, string name, DateTime fromDate, DateTime toDate, int status, int userID, int roleID)
        {
            string spName = @"GetQuestionnaires";
            SqlParameter[] pars = new SqlParameter[7];
            pars[0] = new SqlParameter("@Name", name);
            if (fromDate <= Constants.Date_Min)
            {
                pars[1] = new SqlParameter("@FromDate", DBNull.Value);
            }
            else
            {
                pars[1] = new SqlParameter("@FromDate", fromDate);
            }
            if (toDate <= Constants.Date_Min)
            {
                pars[2] = new SqlParameter("@ToDate", DBNull.Value);
            }
            else
            {
                pars[2] = new SqlParameter("@ToDate", toDate);
            }
            if (status <= 0)
            {
                pars[3] = new SqlParameter("@Status", DBNull.Value);
            }
            else
            {
                pars[3] = new SqlParameter("@Status", status);
            }
            pars[4] = new SqlParameter("@UserID", userID);
            pars[5] = new SqlParameter("@RoleID", roleID);
            if (projectID <= 0)
            {
                pars[6] = new SqlParameter("@ProjectID", DBNull.Value);
            }
            else
            {
                pars[6] = new SqlParameter("@ProjectID", projectID);
            }
            return baseLogic.ExceuteStoredProcedure(spName, pars);
        }

        public static void DeleteQuestionnaire(int id)
        {
            APQuestionnairesDO apo = GetQuestionnaireByID(id);
            apo.DeleteFlag = true;
            apo.DeleteTime = DateTime.Now;
            baseLogic.Update(apo);
        }

        public static void DeleteQuestion(int id)
        {
            APQuestionsDO questionDO = new APQuestionsDO();
            questionDO.ID = id;
            baseLogic.Delete(questionDO);
        }

        public static void DeleteAllQuestions(int id)
        {
            string sql = "delete from APQuestions where QuestionnaireID=@QuestionnaireID";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@QuestionnaireID", id);
            baseLogic.Execute(sql, pars);
        }

        public static DataTable GetQuestionOptions(int questionID)
        {
            string sql = "select * from APOptions where QuestionID=@QuestionID";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@QuestionID", questionID);
            DataTable dt = baseLogic.Select(sql, pars);
            return dt;
        }

        public static DataTable GetQuestionCorrectOptions(int questionID)
        {
            string sql = "select * from APOptions where QuestionID=@QuestionID and bCorrectOption=1";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@QuestionID", questionID);
            DataTable dt = baseLogic.Select(sql, pars);
            return dt;
        }

        public static void ClearQuestionOptions(int questionID)
        {
            string sql = "delete from APOptions where QuestionID=@QuestionID";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@QuestionID", questionID);
            baseLogic.Execute(sql, pars);
        }

        public static void FixResultAttachments(int resultID)
        {
            string spName = "FixResultAttachments";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@ResultID", resultID);
            baseLogic.ExecuteSPNonQuery(spName, pars);
        }

        public static DataTable GetQuestionnaireDelivery(int projectID, int questionnaireID, int areaID, int levelID, int typeID, int statusID,
            string province, string city, string district, int roleID, int userID, DateTime fromDate, DateTime toDate, string keyword)
        {
            string spName = "GetQuestionnaireDelivery";
            SqlParameter[] pars = new SqlParameter[14];
            pars[0] = new SqlParameter("@ProjectID", projectID);
            if (questionnaireID <= 0)
            {
                pars[1] = new SqlParameter("@QuestionnaireID", DBNull.Value);
            }
            else
            {
                pars[1] = new SqlParameter("@QuestionnaireID", questionnaireID);
            }
            if (areaID <= 0)
            {
                pars[2] = new SqlParameter("@AreaID", DBNull.Value);
            }
            else
            {
                pars[2] = new SqlParameter("@AreaID", areaID);
            }
            if (levelID <= 0)
            {
                pars[3] = new SqlParameter("@LevelID", DBNull.Value);
            }
            else
            {
                pars[3] = new SqlParameter("@LevelID", levelID);
            }
            pars[4] = new SqlParameter("@TypeID", typeID);
            pars[5] = new SqlParameter("@StatusID", statusID);

            pars[6] = new SqlParameter("@Province", province);
            pars[7] = new SqlParameter("@City", city);
            pars[8] = new SqlParameter("@District", district);
            pars[9] = new SqlParameter("@RoleID", roleID);
            pars[10] = new SqlParameter("@UserID", userID);
            pars[11] = new SqlParameter("@FromDate", fromDate);
            pars[12] = new SqlParameter("@ToDate", toDate);
            pars[13] = new SqlParameter("@Keyword", keyword);
            DataTable dt = baseLogic.ExceuteStoredProcedure(spName, pars);
            return dt;
        }

        public static DataTable GetQuestionnaireCheckList(int projectID, int questionnaireID, int areaID, int levelID, int typeID, int statusID,
            string province, string city, string district, int roleID, int userID, DateTime fromDate, DateTime toDate, int stageStatusID, string keyword, int searchID, bool isDuplicate)
        {
            string spName = "GetQuestionnaireCheckList";
            SqlParameter[] pars = new SqlParameter[17];
            pars[0] = new SqlParameter("@ProjectID", projectID);
            if (questionnaireID <= 0)
            {
                pars[1] = new SqlParameter("@QuestionnaireID", DBNull.Value);
            }
            else
            {
                pars[1] = new SqlParameter("@QuestionnaireID", questionnaireID);
            }
            if (areaID <= 0)
            {
                pars[2] = new SqlParameter("@AreaID", DBNull.Value);
            }
            else
            {
                pars[2] = new SqlParameter("@AreaID", areaID);
            }
            if (levelID <= 0)
            {
                pars[3] = new SqlParameter("@LevelID", DBNull.Value);
            }
            else
            {
                pars[3] = new SqlParameter("@LevelID", levelID);
            }
            pars[4] = new SqlParameter("@TypeID", typeID);
            pars[5] = new SqlParameter("@StatusID", statusID);
            pars[6] = new SqlParameter("@Province", province);
            pars[7] = new SqlParameter("@City", city);
            pars[8] = new SqlParameter("@District", district);
            pars[9] = new SqlParameter("@RoleID", roleID);
            pars[10] = new SqlParameter("@UserID", userID);
            pars[11] = new SqlParameter("@FromDate", fromDate);
            pars[12] = new SqlParameter("@ToDate", toDate);
            pars[13] = new SqlParameter("@StageStatusID", stageStatusID);
            pars[14] = new SqlParameter("@Keyword", keyword);
            pars[15] = new SqlParameter("@SearchResultID", searchID);
            pars[16] = new SqlParameter("@IsDuplicate", isDuplicate);
            DataTable dt = baseLogic.ExceuteStoredProcedure(spName, pars);
            return dt;
        }

        public static DataTable GetQuestionnaireCheckListClient(int projectID, int questionnaireID, int statusID, string province, string city, string district, int clientID
            , DateTime fromDate, DateTime toDate, int stageStatusID, int clientLevelID, string keyword)
        {
            string spName = "GetQuestionnaireCheckListClient";
            SqlParameter[] pars = new SqlParameter[12];
            pars[0] = new SqlParameter("@ProjectID", projectID);
            if (clientID <= 0)
            {
                pars[1] = new SqlParameter("@ClientID", DBNull.Value);
            }
            else
            {
                pars[1] = new SqlParameter("@ClientID", clientID);
            }
            if (questionnaireID <= 0)
            {
                pars[2] = new SqlParameter("@QuestionnaireID", DBNull.Value);
            }
            else
            {
                pars[2] = new SqlParameter("@QuestionnaireID", questionnaireID);
            }

            pars[3] = new SqlParameter("@StatusID", statusID);
            pars[4] = new SqlParameter("@Province", province);
            pars[5] = new SqlParameter("@City", city);
            pars[6] = new SqlParameter("@District", district);
            pars[7] = new SqlParameter("@FromDate", fromDate);
            pars[8] = new SqlParameter("@ToDate", toDate);
            pars[9] = new SqlParameter("@StageStatusID", stageStatusID);
            pars[10] = new SqlParameter("@ClientLevelID", clientLevelID);
            pars[11] = new SqlParameter("@Keyword", keyword);
            DataTable dt = baseLogic.ExceuteStoredProcedure(spName, pars);
            return dt;
        }

        public static DataTable GetQuestionnaireCheckListQCLeader(int projectID, int questionnaireID, int statusID, string province, string city, string district, int clientID
            , DateTime fromDate, DateTime toDate, int stageStatusID, string keyword)
        {
            string spName = "GetQuestionnaireCheckListQCLeader";
            SqlParameter[] pars = new SqlParameter[11];
            pars[0] = new SqlParameter("@ProjectID", projectID);
            if (clientID <= 0)
            {
                pars[1] = new SqlParameter("@ClientID", DBNull.Value);
            }
            else
            {
                pars[1] = new SqlParameter("@ClientID", clientID);
            }
            if (questionnaireID <= 0)
            {
                pars[2] = new SqlParameter("@QuestionnaireID", DBNull.Value);
            }
            else
            {
                pars[2] = new SqlParameter("@QuestionnaireID", questionnaireID);
            }

            pars[3] = new SqlParameter("@StatusID", statusID);
            pars[4] = new SqlParameter("@Province", province);
            pars[5] = new SqlParameter("@City", city);
            pars[6] = new SqlParameter("@District", district);
            pars[7] = new SqlParameter("@FromDate", fromDate);
            pars[8] = new SqlParameter("@ToDate", toDate);
            pars[9] = new SqlParameter("@StageStatusID", stageStatusID);
            pars[10] = new SqlParameter("@Keyword", keyword);
            DataTable dt = baseLogic.ExceuteStoredProcedure(spName, pars);
            return dt;
        }

        public static DataTable GetQuestionnaireUploadList(int projectID, int questionnaireID, DateTime fromDate, DateTime toDate, int statusID,
            int areaID, string province, string city, string district, int roleID, int userID, string keyword)
        {
            string spName = "GetQuestionnaireUploadList";
            SqlParameter[] pars = new SqlParameter[12];
            pars[0] = new SqlParameter("@ProjectID", projectID);
            pars[1] = new SqlParameter("@QuestionnaireID", questionnaireID);
            pars[2] = new SqlParameter("@FromDate", fromDate);
            pars[3] = new SqlParameter("@ToDate", toDate);
            pars[4] = new SqlParameter("@StatusID", statusID);
            pars[5] = new SqlParameter("@AreaID", areaID);
            pars[6] = new SqlParameter("@Province", province);
            pars[7] = new SqlParameter("@City", city);
            pars[8] = new SqlParameter("@District", district);
            pars[9] = new SqlParameter("@RoleID", roleID);
            pars[10] = new SqlParameter("@UserID", userID);
            pars[11] = new SqlParameter("@Keyword", keyword);
            DataTable dt = baseLogic.ExceuteStoredProcedure(spName, pars);
            return dt;
        }

        public static APQuestionnaireDeliverySettingsDO GetAPQuestionnaireDeliverySettingsDOByProjectID(int projectID)
        {
            string sql = "select * from APQuestionnaireDeliverySettings where projectID=" + projectID;
            APQuestionnaireDeliverySettingsDO settingsDO = new APQuestionnaireDeliverySettingsDO();
            settingsDO = (APQuestionnaireDeliverySettingsDO)BusinessLogicBase.Default.Select(settingsDO, sql);
            return settingsDO;
        }

        public static APQuestionnairesDO GetQuestionnaireByResultID(int resultID)
        {
            string sql = @"select qn.* from APQuestionnaires qn
inner join APQuestionnaireResults qr on qr.QuestionnaireID=qn.ID
where qr.ID=@resultID";
            SqlParameter[] paras = new SqlParameter[1];
            paras[0] = new SqlParameter("@resultID", resultID);
            APQuestionnairesDO qdo = new APQuestionnairesDO();
            qdo = (APQuestionnairesDO)BusinessLogicBase.Default.Select(qdo, sql, paras);
            return qdo;
        }

        public static DataTable GetQuestionnaireDeliveryInfo(int deliveryID, int clientID)
        {
            string sql = @"
declare @clientName nvarchar(50)
select @clientName=Name from APClients where ID=@clientID

select que.Name as QuestionnaireName,
uu.UserName as UserName,
@clientName as ClientName,
CONVERT(varchar(50),dev.FromDate,102) + ' - ' + CONVERT(varchar(50),dev.ToDate,102) as Period,
dev.FromDate,
dev.ToDate,
dev.QuestionnaireID,
que.TotalScore
from dbo.APQuestionnaireDelivery dev 
left join APQuestionnaires que on dev.QuestionnaireID=que.ID
left join APUsers uu on uu.ID=dev.AcceptUserID
where dev.ID=@deliveryID";
            SqlParameter[] pars = new SqlParameter[2];
            pars[0] = new SqlParameter("@clientID", clientID);
            pars[1] = new SqlParameter("@deliveryID", deliveryID);
            DataTable dt = BusinessLogicBase.Default.Select(sql, pars);
            return dt;
        }

        public static APQuestionnaireDeliveryDO GetQuestionnaireDeliveryDO(int questionnaireID, int clientID, DateTime fromDate, DateTime toDate, int userType)
        {
            string sql = @"select * from APQuestionnaireDelivery where QuestionnaireID=@QuestionnaireID and ClientID=@ClientID and FromDate=@FromDate and ToDate=@ToDate and TypeID=@TypeID";
            SqlParameter[] pars = new SqlParameter[5];
            pars[0] = new SqlParameter("@QuestionnaireID", questionnaireID);
            pars[1] = new SqlParameter("@ClientID", clientID);
            pars[2] = new SqlParameter("@FromDate", fromDate);
            pars[3] = new SqlParameter("@ToDate", toDate);
            pars[4] = new SqlParameter("@TypeID", userType);
            APQuestionnaireDeliveryDO qdo = new APQuestionnaireDeliveryDO();
            qdo = (APQuestionnaireDeliveryDO)BusinessLogicBase.Default.Select(qdo, sql, pars);
            return qdo;
        }

        public static DataTable GetQuestionnaireResultInfo(int resultID)
        {
            string sql = @"select 
que.Name as QuestionnaireName,
client.Name as ClientName,
CONVERT(varchar(50),result.FromDate,102) + ' - ' + CONVERT(varchar(50),result.ToDate,102) as Period,
result.FromDate,
result.ToDate,
result.ID,
result.VisitBeginTime,
result.VisitEndTime,
uu.UserName as VisitUserName,
result.VideoPath,
result.VideoLength,
result.CurrentProgress,
result.CurrentQuestionID,
result.Description,
result.QuestionnaireID,
result.VisitUserUploadStatus,
result.Status
from APQuestionnaireResults result
left join APQuestionnaires que on result.QuestionnaireID=que.ID
left join APUsers uu on uu.ID=result.VisitUserID
left join APClients client on client.ID=result.ClientID
where result.ID=@resultID";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@resultID", resultID);
            DataTable dt = BusinessLogicBase.Default.Select(sql, pars);
            return dt;
        }


        public static APQuestionnaireResultsDO GetQuestionnaireResultDOByID(int id)
        {
            APQuestionnaireResultsDO qnDO = new APQuestionnaireResultsDO();
            return (APQuestionnaireResultsDO)baseLogic.Select(qnDO, id);
        }

        public static DataTable GetQuestionnairePeriods(int questionnaireID)
        {
            string spName = "GetQuestionnairePeriods";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@ID", questionnaireID);
            DataTable dt = baseLogic.ExceuteStoredProcedure(spName, pars);
            return dt;
        }

        public static DataSet GetQuestionnaireDefaultCorrectOptions(int questionnaireID)
        {
            string spName = "GetQuestionnaireDefaultCorrectOptions";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@QuestionnaireID", questionnaireID);
            return SqlHelper.ExecuteDataset(SqlHelper.ConnectionString, spName, pars);
        }

        public static DataTable GetClientAppeals(int questionnaireID, DateTime fromDate, DateTime toDate)
        {
            string spName = "dbo.GetClientAppeals";
            SqlParameter[] pars = new SqlParameter[3];
            pars[0] = new SqlParameter("@QuestionnaireID", questionnaireID);
            pars[1] = new SqlParameter("@FromDate", fromDate);
            pars[2] = new SqlParameter("@ToDate", toDate);
            DataTable dt = baseLogic.ExceuteStoredProcedure(spName, pars);
            return dt;
        }

        public static DataTable GetQuestionAppeals(int questionnaireID, DateTime fromDate, DateTime toDate, int stageStatusID, int statusID, int clientLevelID, string keyword, int currentClientID)
        {
            string spName = "dbo.GetQuestionAppeals";
            SqlParameter[] pars = new SqlParameter[8];
            pars[0] = new SqlParameter("@QuestionnaireID", questionnaireID);
            pars[1] = new SqlParameter("@FromDate", fromDate);
            pars[2] = new SqlParameter("@ToDate", toDate);
            pars[3] = new SqlParameter("@StageStatusID", stageStatusID);
            pars[4] = new SqlParameter("@StatusID", statusID);
            pars[5] = new SqlParameter("@ClientLevelID", clientLevelID);
            pars[6] = new SqlParameter("@Keyword", keyword);
            pars[7] = new SqlParameter("@CurrentClientID", currentClientID);
            DataTable dt = baseLogic.ExceuteStoredProcedure(spName, pars);
            return dt;
        }

        public static DataTable GetWrongQuestions(int questionnaireID, DateTime fromDate, DateTime toDate, int stageStatusID, int statusID, string keyword, int currentClientID)
        {
            string spName = "dbo.GetWrongQuestions";
            SqlParameter[] pars = new SqlParameter[7];
            pars[0] = new SqlParameter("@QuestionnaireID", questionnaireID);
            pars[1] = new SqlParameter("@FromDate", fromDate);
            pars[2] = new SqlParameter("@ToDate", toDate);
            pars[3] = new SqlParameter("@StageStatusID", stageStatusID);
            pars[4] = new SqlParameter("@StatusID", statusID);
            pars[5] = new SqlParameter("@Keyword", keyword);
            pars[6] = new SqlParameter("@CurrentClientID", currentClientID);
            DataTable dt = baseLogic.ExceuteStoredProcedure(spName, pars);
            return dt;
        }

        public static int GetQuestionnaireResultsCount(int questionnaireID, int clientID, DateTime fromDate, DateTime toDate, int status)
        {
            string spName = "dbo.GetQuestionnaireResultsCount";
            SqlParameter[] pars = new SqlParameter[5];
            pars[0] = new SqlParameter("@QuestionnaireID", questionnaireID);
            pars[1] = new SqlParameter("@ClientID", clientID);
            pars[2] = new SqlParameter("@FromDate", fromDate);
            pars[3] = new SqlParameter("@ToDate", toDate);
            pars[4] = new SqlParameter("@Status", status);
            DataTable dt = baseLogic.ExceuteStoredProcedure(spName, pars);
            int count = 0;
            if (dt != null && dt.Rows.Count > 0)
            {
                int.TryParse(dt.Rows[0][0].ToString(), out count);
            }
            return count;
        }

        public static DataTable GetQuestionnaireResults(int projectID, int questionnaireID, int clientID, DateTime fromDate, DateTime toDate, int status, int pageFrom, int pageTo)
        {
            string spName = "dbo.GetQuestionnaireResults";
            SqlParameter[] pars = new SqlParameter[8];
            pars[0] = new SqlParameter("@ProjectID", projectID);
            pars[1] = new SqlParameter("@QuestionnaireID", questionnaireID);
            pars[2] = new SqlParameter("@ClientID", clientID);
            pars[3] = new SqlParameter("@FromDate", fromDate);
            pars[4] = new SqlParameter("@ToDate", toDate);
            pars[5] = new SqlParameter("@Status", status);
            pars[6] = new SqlParameter("@PageFrom", pageFrom);
            pars[7] = new SqlParameter("@PageTo", pageTo);
            DataTable dt = baseLogic.ExceuteStoredProcedure(spName, pars);
            return dt;
        }

        public static DataTable GetQuestionnaireResults_Answers(int projectID, int questionnaireID, int clientID, DateTime fromDate, DateTime toDate, int status, int pageFrom, int pageTo, bool hasLink = true, bool hasDescription = true)
        {
            string spName = "dbo.GetQuestionnaireResults_Answers";
            SqlParameter[] pars = new SqlParameter[8];
            pars[0] = new SqlParameter("@ProjectID", projectID);
            pars[1] = new SqlParameter("@QuestionnaireID", questionnaireID);
            pars[2] = new SqlParameter("@ClientID", clientID);
            pars[3] = new SqlParameter("@FromDate", fromDate);
            pars[4] = new SqlParameter("@ToDate", toDate);
            pars[5] = new SqlParameter("@Status", status);
            pars[6] = new SqlParameter("@PageFrom", pageFrom);
            pars[7] = new SqlParameter("@PageTo", pageTo);
            DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.ConnectionString, CommandType.StoredProcedure, spName, pars);

            DataTable dtResults = ds.Tables[0];
            DataTable dtAnswers = ds.Tables[1];
            DataTable dtQuestions = ds.Tables[2];
            DataTable dtFiles = ds.Tables[3];

            if (dtResults != null && dtResults.Rows.Count > 0)
            {
               
               if (dtQuestions != null && dtQuestions.Rows.Count > 0)
                {
                    foreach (DataRow row in dtQuestions.Rows)
                    {
                        string code = row["Code"].ToString();
                        dtResults.Columns.Add(code);
                    }
                }
               if (dtResults.Columns.Contains("系统链接") == false)
               {
                   dtResults.Columns.Add("系统链接", typeof(string));
               }

                if (dtAnswers != null && dtAnswers.Rows.Count > 0)
                {
                    foreach (DataRow row in dtResults.Rows)
                    {
                        string resultID = row["编号"].ToString();
                        string rootUrl = Constants.CurrentSiteUrl;
                        string systemUrl = "系统链接@@@@" + string.Format("{0}Pages/QuestionnaireUpload3.htm?resultID={1}&auditType={2}", rootUrl,CommonFunction.EncodeBase64(resultID, 5), CommonFunction.EncodeBase64("4", 5));
                        row["系统链接"] = systemUrl;
                        foreach (DataRow queRow in dtQuestions.Rows)
                        {
                            string questionID = queRow["ID"].ToString();
                            string questionType = queRow["QuestionType"].ToString();
                            string code = queRow["Code"].ToString();
                            DataRow[] selectAnswer = dtAnswers.Select("ResultID=" + resultID + " and QuestionID=" + questionID);
                            if (selectAnswer != null && selectAnswer.Length > 0) 
                            {
                                string answerID = selectAnswer[0]["AnswerID"].ToString();
                                string answerText = selectAnswer[0]["AnswerText"].ToString();
                                string answerDescription = selectAnswer[0]["Description"].ToString();
                                if (hasDescription && string.IsNullOrEmpty(answerDescription) == false)
                                {
                                    answerText = string.Format("{0}(扣分描述:{1})", answerText, answerDescription);
                                }
                                if (questionType == "8") 
                                {
                                    DataRow[] selectFile = dtFiles.Select("RelatedID=" + answerID);
                                    if (selectFile != null && selectFile.Length > 0)
                                    {
                                        string fileName = selectFile[0]["FileName"].ToString();
                                        string relevantPath = selectFile[0]["RelevantPath"].ToString();
                                        string url = Constants.CurrentSiteUrl + relevantPath.Replace("../", "");
                                        url = Microsoft.JScript.GlobalObject.encodeURI(url);
                                        if (hasLink)
                                        {
                                            answerText = fileName + "@@@@" + url;
                                        }
                                        else 
                                        {
                                            answerText = url;
                                        }

                                    }
                                }
                                row[code] = answerText;

                            }
                        }
                    }
                }
            }

            return dtResults;
        }

        public static DataTable GetQuestionnaireResultsScore(int projectID, int questionnaireID, int clientID, DateTime fromDate, DateTime toDate, int status, int pageFrom, int pageTo)
        {
            string spName = "dbo.GetQuestionnaireResultsScore";
            SqlParameter[] pars = new SqlParameter[8];
            pars[0] = new SqlParameter("@ProjectID", projectID);
            pars[1] = new SqlParameter("@QuestionnaireID", questionnaireID);
            pars[2] = new SqlParameter("@ClientID", clientID);
            pars[3] = new SqlParameter("@FromDate", fromDate);
            pars[4] = new SqlParameter("@ToDate", toDate);
            pars[5] = new SqlParameter("@Status", status);
            pars[6] = new SqlParameter("@PageFrom", pageFrom);
            pars[7] = new SqlParameter("@PageTo", pageTo);
            DataTable dt = baseLogic.ExceuteStoredProcedure(spName, pars);
            return dt;
        }

        public static DataTable GetQuestionnaireResultsFiles(int projectID, int questionnaireID, int clientID, DateTime fromDate, DateTime toDate, int status)
        {
            string spName = "dbo.GetQuestionnaireResultsFiles";
            SqlParameter[] pars = new SqlParameter[6];
            pars[0] = new SqlParameter("@ProjectID", projectID);
            pars[1] = new SqlParameter("@QuestionnaireID", questionnaireID);
            pars[2] = new SqlParameter("@ClientID", clientID);
            pars[3] = new SqlParameter("@FromDate", fromDate);
            pars[4] = new SqlParameter("@ToDate", toDate);
            pars[5] = new SqlParameter("@Status", status);
            DataTable dt = baseLogic.ExceuteStoredProcedure(spName, pars);
            return dt;
        }

        public static int GetNextAuditUserID(int projectID, int questionnaireID, DateTime fromDate, DateTime toDate, int typeID, int clientID)
        {
            string spName = "GetNextAuditUserID";
            SqlParameter[] pars = new SqlParameter[6];
            pars[0] = new SqlParameter("@ProjectID", projectID);
            pars[1] = new SqlParameter("@QuestionnaireID", questionnaireID);
            pars[2] = new SqlParameter("@FromDate", fromDate);
            pars[3] = new SqlParameter("@ToDate", toDate);
            pars[4] = new SqlParameter("@TypeID", typeID);
            pars[5] = new SqlParameter("@ClientID", clientID);
            DataTable dt = baseLogic.ExceuteStoredProcedure(spName, pars);
            int userID = 0;
            if (dt != null && dt.Rows.Count > 0)
            {
                int.TryParse(dt.Rows[0][0].ToString(), out userID);
            }
            return userID;
        }

        public static DataTable GetAuditNoteHistory(int resultID)
        {
            string sql = @"select distinct hh.ID,
uu.UserName,
case when isnull(hh.AuditResult,0)=1 then '审核通过' else '审核不通过' end as Result,
hh.AuditNotes,
hh.AuditTime,
hh.TypeID
from dbo.APAuditHistory hh 
left join APUsers uu on uu.ID=hh.AuditUserID
where hh.QuestionnaireResultID=@ResultID
order by hh.AuditTime asc";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@ResultID", resultID);
            DataTable dt = BusinessLogicBase.Default.Select(sql, pars);
            return dt;
        }

        public static APQuestionnaireResultsDO GetQuestionnaireResultDOByDeliveryIDAndClientID(int deliveryID, int clientID)
        {
            APQuestionnaireResultsDO resultsDO = new APQuestionnaireResultsDO();
            string sql = "select * from [APQuestionnaireResults] where DeliveryID=@deliveryID and ClientID=@clientID";
            SqlParameter[] paras = new SqlParameter[2];
            paras[0] = new SqlParameter("@deliveryID", deliveryID);
            paras[1] = new SqlParameter("@clientID", clientID);
            resultsDO = (APQuestionnaireResultsDO)BusinessLogicBase.Default.Select(resultsDO, sql, paras);
            return resultsDO;
        }

        public static APQuestionnaireResultsDO GetQuestionnaireResultDOByDeliveryIDAndClientID(int deliveryID, int clientID, int visitUserUploadStatus)
        {
            APQuestionnaireResultsDO resultsDO = new APQuestionnaireResultsDO();
            string sql = "select * from [APQuestionnaireResults] where DeliveryID=@deliveryID and ClientID=@clientID and VisitUserUploadStatus=@visitUserUploadStatus";
            SqlParameter[] paras = new SqlParameter[3];
            paras[0] = new SqlParameter("@deliveryID", deliveryID);
            paras[1] = new SqlParameter("@clientID", clientID);
            paras[2] = new SqlParameter("@visitUserUploadStatus", visitUserUploadStatus);
            resultsDO = (APQuestionnaireResultsDO)BusinessLogicBase.Default.Select(resultsDO, sql, paras);
            return resultsDO;
        }

        public static APQuestionnaireResultsDO GetQuestionnaireResultDO(int questionnaireID, int clientID, DateTime fromDate)
        {
            APQuestionnaireResultsDO resultsDO = new APQuestionnaireResultsDO();
            string sql = "select * from [APQuestionnaireResults] where QuestionnaireID=@questionnaireID and ClientID=@clientID and FromDate=@fromDate";
            SqlParameter[] paras = new SqlParameter[3];
            paras[0] = new SqlParameter("@questionnaireID", questionnaireID);
            paras[1] = new SqlParameter("@clientID", clientID);
            paras[2] = new SqlParameter("@fromDate", fromDate);
            resultsDO = (APQuestionnaireResultsDO)BusinessLogicBase.Default.Select(resultsDO, sql, paras);
            return resultsDO;
        }

        public static APQuestionnairesDO GetQuestionnaireDOByName(int projectID, string questionnaireName)
        {
            APQuestionnairesDO questionnaireDO = new APQuestionnairesDO();
            string sql = "select * from [APQuestionnaires] where ProjectID=@projectID and Name=@questionnaireName";
            SqlParameter[] paras = new SqlParameter[2];
            paras[0] = new SqlParameter("@projectID", projectID);
            paras[1] = new SqlParameter("@questionnaireName", questionnaireName);
            questionnaireDO = (APQuestionnairesDO)BusinessLogicBase.Default.Select(questionnaireDO, sql, paras);
            return questionnaireDO;
        }

        public static APAppealAuditDO GetAppealAuditDO(int resultID, int questionID)
        {
            APAppealAuditDO auditDO = new APAppealAuditDO();
            string sql = "select * from APAppealAudit where ResultID=@resultID and QuestionID=@questionID";
            SqlParameter[] paras = new SqlParameter[2];
            paras[0] = new SqlParameter("@resultID", resultID);
            paras[1] = new SqlParameter("@questionID", questionID);
            auditDO = (APAppealAuditDO)BusinessLogicBase.Default.Select(auditDO, sql, paras);
            return auditDO;
        }

        public static bool CheckDeliveryFull(int deliveryID)
        {
            bool bFull = false;
            APQuestionnaireDeliveryDO deliveryDO = new APQuestionnaireDeliveryDO();
            deliveryDO = (APQuestionnaireDeliveryDO)baseLogic.Select(deliveryDO, deliveryID);
            if (deliveryDO == null || deliveryDO.ID <= 0)
            {
                return true;
            }

            int sampleNumber = deliveryDO.SampleNumber;
            int resultCount = 0;
            string sql = "select count(ID) from APQuestionnaireResults where deliveryID=@deliveryID and Status>0";
            SqlParameter[] paras = new SqlParameter[1];
            paras[0] = new SqlParameter("@deliveryID", deliveryID);
            DataTable dt = baseLogic.Select(sql, paras);
            if (dt != null && dt.Rows.Count > 0)
            {
                int.TryParse(dt.Rows[0][0].ToString(), out resultCount);
            }
            bFull = (sampleNumber == resultCount);
            return bFull;
        }

        public static void DeleteQuestionnaireResult(int resultID)
        {
            string sql = @"
delete from APAnswerOptions where AnswerID in (select ID from APAnswers where ResultID=@resultID)
delete from APAnswers where ResultID=@resultID
delete from APAuditHistory where QuestionnaireResultID=@resultID
delete from APQuestionAuditNotes where ResultID=@resultID
delete from APQuestionnaireResults where id=@resultID";
            SqlParameter[] paras = new SqlParameter[1];
            paras[0] = new SqlParameter("@resultID", resultID);
            baseLogic.Execute(sql, paras);
        }

        public static DataTable GetQuestionAuditNote(int resultID, int questionID)
        {
            string sql = @"select rr.Name, nn.* from [dbo].[APQuestionAuditNotes] nn
left join [dbo].[APUserRole] rr on rr.ID=nn.UserTypeID
where ResultID=@resultID and QuestionID=@questionID
order by CreateTime asc";
            SqlParameter[] pars = new SqlParameter[2];
            pars[0] = new SqlParameter("@resultID", resultID);
            pars[1] = new SqlParameter("@questionID", questionID);
            DataTable dt = BusinessLogicBase.Default.Select(sql, pars);
            return dt;
        }

        public static DataTable GetAnswersForResult(int resultID)
        {
            string sql = @"select aa.ID,aa.QuestionID,aa.TotalScore,aa.Description from APAnswers aa
inner join APQuestions que on que.ID=aa.QuestionID
where ResultID=@resultID
order by que.Code";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@resultID", resultID);
            DataTable dt = BusinessLogicBase.Default.Select(sql, pars);
            return dt;
        }

        public static DataTable GetResultAuditNote(int resultID)
        {
            string sql = @"select rr.Name, nn.* from [dbo].[APQuestionAuditNotes] nn
left join [dbo].[APUserRole] rr on rr.ID=nn.UserTypeID
where ResultID=@resultID
order by CreateTime asc";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@resultID", resultID);
            DataTable dt = BusinessLogicBase.Default.Select(sql, pars);
            return dt;
        }
    }
}
