using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using APLibrary.DataObject;
using System.Data.SqlClient;
using System.Data;

namespace APLibrary
{
    public class APProjectManager : BusinessLogicBase
    {
        private static BusinessLogicBase baseLogic = new BusinessLogicBase();

        public static APProjectsDO GetProjectByID(int id)
        {
            APProjectsDO userDO = new APProjectsDO();
            return (APProjectsDO)baseLogic.Select(userDO, id);
        }

        public static APProjectTimePeriodDO GetProjectTimePeriodByID(int id)
        {
            APProjectTimePeriodDO userDO = new APProjectTimePeriodDO();
            return (APProjectTimePeriodDO)baseLogic.Select(userDO, id);
        }

        public static DataTable GetProjectInfoByID(int id)
        {
            string sql = @"
select app.*,
bc.ItemValue as ProjectStatus,
CONVERT(nvarchar(16),app.CreateTime,20) + ' ' + createUser.UserName as CreatingInfo,
CONVERT(nvarchar(16),app.LastModifiedTime,20) + ' ' + editingUser.UserName as EditingInfo
from dbo.APProjects app
left join BusinessConfiguration bc on app.[Status]=bc.ItemKey and bc.ItemDesc='ProjectStatus'
left join APUsers createUser on app.CreateUserID=createUser.ID
left join APUsers editingUser on app.LastModifiedUserID=editingUser.ID
where app.ID=@ID";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@ID", id);
            DataTable dt = baseLogic.Select(sql, pars);
            return dt;
        }

        public static DataTable GetAllProjects(string name, DateTime fromDate, DateTime toDate, int status, int currentUserID, int currentUserType)
        {
            string spName = @"SearchProjects";
            SqlParameter[] pars = new SqlParameter[6];
            pars[0] = new SqlParameter("@Name", name);
            if (fromDate <= Constants.Date_Min)
            {
                pars[1] = new SqlParameter("@FromDate", DBNull.Value);
            }
            else {
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
            pars[4] = new SqlParameter("@currentUserID", currentUserID);
            pars[5] = new SqlParameter("@currentUserType", currentUserType);
            return baseLogic.ExceuteStoredProcedure(spName, pars);
        }

        public static DataTable GetAllProjectsByGroupID(int groupID)
        {
            string sql = @"select * from APProjects where status=1 and GroupID=isnull(@groupID,GroupID)";
            SqlParameter[] pars = new SqlParameter[1];
            if (groupID > 0)
            {
                pars[0] = new SqlParameter("@groupID", groupID);
            }
            else
            {
                pars[0] = new SqlParameter("@groupID", DBNull.Value);
            }
            return baseLogic.Select(sql, pars);
        }

        public static DataTable GetProjectTimePeriod(int projectID)
        {
            string sql = @"select * from APProjectTimePeriod where ProjectID=@projectID";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@projectID", projectID);
            return baseLogic.Select(sql, pars);
        }

        public static void ClearAllInProject(int projectID)
        {
            string spName = @"ClearAllInProject";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@projectID", projectID);
            baseLogic.ExecuteSPNonQuery(spName, pars);
        }

        public static void DeleteProject(int id) 
        {
            APProjectsDO apo = APProjectManager.GetProjectByID(id);
            apo.Status = (int)Enums.DeleteStatus.删除;
            apo.DeleteFlag = true;
            apo.DeleteTime = DateTime.Now;
            baseLogic.Update(apo);
        }

        public static DataTable GetProjectAppealPeriods(int projectID, int questionnaireID, DateTime fromDate, DateTime toDate) 
        {
            string sql = @"
/*
declare @ProjectID int
declare @QuestionnaireID int
declare @FromDate datetime
declare @ToDate datetime
set @FromDate='2017-10-1'
set @ToDate='2017-12-31'
set @ProjectID=5
set @QuestionnaireID=15
*/
select pp.*,que.Name as QuestionnaireName 
from [dbo].[APAppealPeriod] pp 
inner join APQuestionnaires que on que.ID=pp.QuestionnaireID
where pp.ProjectID=@ProjectID 
and pp.QuestionnaireID=isnull(@QuestionnaireID,pp.QuestionnaireID)
and pp.ToDate>=@FromDate 
and pp.FromDate<=@ToDate";
            SqlParameter [] paras  = new SqlParameter[4];
            paras[0] = new SqlParameter("@ProjectID", projectID);
            if (questionnaireID > 0)
            {
                paras[1] = new SqlParameter("@QuestionnaireID", questionnaireID);
            }
            else
            {
                paras[1] = new SqlParameter("@QuestionnaireID", DBNull.Value);
            }
            paras[2] = new SqlParameter("@FromDate", fromDate);
            paras[3] = new SqlParameter("@ToDate", toDate);
            return BusinessLogicBase.Default.Select(sql, paras);
        }
    }
}
