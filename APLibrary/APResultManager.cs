using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using APLibrary.DataObject;
using System.Data.SqlClient;
using System.Data;

namespace APLibrary
{
    public class APResultManager : BusinessLogicBase
    {
        private static BusinessLogicBase baseLogic = new BusinessLogicBase();

        public static DataTable GetGongjiaoResult(int projectID, int questionnaireID, int clientID, int questionID_Line, int questionID_Stop, string answer_Line, string answer_Stop)
        {
            string spName = "GetGongjiaoResultID";
            SqlParameter[] paras = new SqlParameter[7];
            paras[0] = new SqlParameter("@projectID", projectID);
            paras[1] = new SqlParameter("@questionnaireID", questionnaireID);
            paras[2] = new SqlParameter("@clientID", clientID);
            paras[3] = new SqlParameter("@questionID_Line", questionID_Line);
            paras[4] = new SqlParameter("@questionID_Stop", questionID_Stop);
            paras[5] = new SqlParameter("@answer_Line", answer_Line);
            paras[6] = new SqlParameter("@answer_Stop", answer_Stop);
            return baseLogic.ExceuteStoredProcedure(spName, paras);
        }

        public static DataTable GetResult(int projectID, int questionnaireID, int clientID)
        {
            string sql = @"
             /*
 declare @projectID int
 declare @questionnaireID int
 declare @clientID int

 set @projectID=37
 set @questionnaireID=1127
 set @clientID=401999
 */
select ID,OtherPlatformID from APQuestionnaireResults rr
where rr.ProjectID=@projectID
and rr.QuestionnaireID=@questionnaireID
and rr.ClientID=@clientID
and rr.Status=8";
            SqlParameter[] paras = new SqlParameter[3];
            paras[0] = new SqlParameter("@projectID", projectID);
            paras[1] = new SqlParameter("@questionnaireID", questionnaireID);
            paras[2] = new SqlParameter("@clientID", clientID);
            return baseLogic.Select(sql, paras);
        }

        public static DataTable GetResult(int projectID, int questionnaireID, string otherPlatformID)
        {
            string sql = @"select ID,OtherPlatformID from APQuestionnaireResults rr
where rr.ProjectID=@projectID
and rr.QuestionnaireID=@questionnaireID
and rr.OtherPlatformID=@otherPlatformID";
            SqlParameter[] paras = new SqlParameter[3];
            paras[0] = new SqlParameter("@projectID", projectID);
            paras[1] = new SqlParameter("@questionnaireID", questionnaireID);
            paras[2] = new SqlParameter("@otherPlatformID", otherPlatformID);
            return baseLogic.Select(sql, paras);
        }

        public static DataTable GetResult(int projectID, int questionnaireID, int clientID, string otherPlatformID)
        {
            string sql = @"select ID,OtherPlatformID from APQuestionnaireResults rr
where rr.ProjectID=@projectID
and rr.QuestionnaireID=@questionnaireID
and rr.ClientID=@clientID
and rr.OtherPlatformID=@otherPlatformID";
            SqlParameter[] paras = new SqlParameter[4];
            paras[0] = new SqlParameter("@projectID", projectID);
            paras[1] = new SqlParameter("@questionnaireID", questionnaireID);
            paras[2] = new SqlParameter("@clientID", clientID);
            paras[3] = new SqlParameter("@otherPlatformID", otherPlatformID);
            return baseLogic.Select(sql, paras);
        }

        public static DataTable GetResult(string otherPlatformID)
        {
            string sql = @"select ID,OtherPlatformID from APQuestionnaireResults rr
where rr.OtherPlatformID=@otherPlatformID";
            SqlParameter[] paras = new SqlParameter[1];
            paras[0] = new SqlParameter("@otherPlatformID", otherPlatformID);
            return baseLogic.Select(sql, paras);
        }

        public static void UpdateOtherPlatformID(int resultID, string otherPlatformID) 
        {
            string sql = @"Update APQuestionnaireResults set OtherPlatformID=@OtherPlatformID where ID=@ID";
            SqlParameter[] paras = new SqlParameter[2];
            paras[0] = new SqlParameter("@OtherPlatformID", otherPlatformID);
            paras[1] = new SqlParameter("@ID", resultID);
            baseLogic.Execute(sql, paras);
        }

        public static DataTable GetTempClient(int projectID, string clientCode) 
        {
            string sql = "select * from Table2018 where Code=@code";
            if (projectID == 38) 
            {
                //新增商户
                sql = "select * from Table2019View where Code=@code";
            }
            else if (projectID == 40) 
            {
                //存量商户
                sql = "select * from Table2018 where Code=@code";
            }
            SqlParameter[] para = new SqlParameter[1];
            para[0] = new SqlParameter("@code", clientCode);
            string connectionString = "Data Source=116.62.142.234;Initial Catalog=GaoDeLocation;user id=ctrtest;password=123456;Connect Timeout=360; Asynchronous Processing=true";
            DataSet ds = SqlHelper.ExecuteDataset(connectionString, CommandType.Text, sql, para);
            if (ds != null && ds.Tables.Count > 0) 
            {
                return ds.Tables[0];
            }
            return null;
        }

        public static DataTable GetTempClientFromDP(int projectID, int clientCode)
        {
            string sql = "select * from 银联商户wave3 where [序号]=@code";
            if (projectID == 38)
            {
                //新增商户
                sql = "select * from 银联商户wave3 where [序号]=@code";
            }
            SqlParameter[] para = new SqlParameter[1];
            para[0] = new SqlParameter("@code", clientCode);
            return BusinessLogicBase.Default.Select(sql, para);
        }
    }
}
