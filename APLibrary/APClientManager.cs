using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using APLibrary.DataObject;
using System.Data.SqlClient;
using System.Data;

namespace APLibrary
{
    public class APClientManager : BusinessLogicBase
    {
        private static BusinessLogicBase baseLogic = new BusinessLogicBase();

        public static APClientsDO GetClientDOByID(int id)
        {
            APClientsDO clientDO = new APClientsDO();
            return (APClientsDO)baseLogic.Select(clientDO, id);
        }

        public static APClientStructureDO GetClientNodeByID(int id)
        {
            APClientStructureDO clientDO = new APClientStructureDO();
            return (APClientStructureDO)baseLogic.Select(clientDO, id);
        }

        public static DataTable GetClientListByProjectID(int id)
        {
            string sql = @"select ss.ID,ss.LevelID,ss.Name,count(cc.ID) as ClientNumber from dbo.APClientStructure ss left join dbo.APClients cc on ss.LevelID=cc.LevelID and cc.ProjectID=@ProjectID 
where ss.ProjectID=@ProjectID
group by ss.ID,ss.LevelID,ss.Name
order by ss.LevelID";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@ProjectID", id);
            DataTable dt = baseLogic.Select(sql, pars);
            return dt;
        }

        public static APClientStructureDO GetTerminalClient(int id)
        {
            APClientStructureDO structDO = new APClientStructureDO();
            string sql = @"select * from dbo.APClientStructure
where ProjectID=@ProjectID and LevelID=(select max(LevelID) from APClientStructure where ProjectID=@ProjectID)";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@ProjectID", id);
            try
            {
                structDO = (APClientStructureDO)baseLogic.Select(structDO, sql, pars);
            }
            catch { }
            return structDO;
        }

        public static int GetClientMaxLevel(int projectID)
        {
            string sql = @"select max(LevelID) from APClientStructure where ProjectID=@ProjectID";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@ProjectID", projectID);
            DataTable dt = BusinessLogicBase.Default.Select(sql, pars);
            int level = 0;
            if (dt != null && dt.Rows.Count > 0) 
            {
                int.TryParse(dt.Rows[0][0].ToString(), out level);
            }
            return level;
        }

        public static int GetClientMinLevel(int projectID)
        {
            string sql = @"select min(LevelID) from APClientStructure where ProjectID=@ProjectID";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@ProjectID", projectID);
            DataTable dt = BusinessLogicBase.Default.Select(sql, pars);
            int level = 0;
            if (dt != null && dt.Rows.Count > 0)
            {
                int.TryParse(dt.Rows[0][0].ToString(), out level);
            }
            return level;
        }

        public static APClientsDO GetClientByName(string name, int projectID, int levelID)
        {
            APClientsDO clientDO = new APClientsDO();
            string sql = @"select * from dbo.APClients where Name=@Name and ProjectID=@ProjectID and LevelID=@LevelID";
            SqlParameter[] pars = new SqlParameter[3];
            pars[0] = new SqlParameter("@Name", name);
            pars[1] = new SqlParameter("@ProjectID", projectID);
            pars[2] = new SqlParameter("@LevelID", levelID);
            try
            {
                clientDO = (APClientsDO)baseLogic.Select(clientDO, sql, pars);
            }
            catch { }
            return clientDO;
        }

        public static APClientsDO GetClientByCode(string code, int projectID)
        {
            APClientsDO clientDO = new APClientsDO();
            string sql = @"select * from dbo.APClients where Code=@Code and ProjectID=@ProjectID";
            SqlParameter[] pars = new SqlParameter[2];
            pars[0] = new SqlParameter("@Code", code);
            pars[1] = new SqlParameter("@ProjectID", projectID);
            try
            {
                clientDO = (APClientsDO)baseLogic.Select(clientDO, sql, pars);
            }
            catch { }
            return clientDO;
        }

        public static APClientsDO GetClientByPostcode(string postcode, int projectID)
        {
            APClientsDO clientDO = new APClientsDO();
            string sql = @"select * from dbo.APClients where Postcode=@Postcode and ProjectID=@ProjectID";
            SqlParameter[] pars = new SqlParameter[2];
            pars[0] = new SqlParameter("@Postcode", postcode);
            pars[1] = new SqlParameter("@ProjectID", projectID);
            try
            {
                clientDO = (APClientsDO)baseLogic.Select(clientDO, sql, pars);
            }
            catch { }
            return clientDO;
        }

        public static DataTable GetClientsByLevelID(int levelID, int projectID)
        {
            string sql = @"select ID, Code, Name from dbo.APClients
where ProjectID=@ProjectID and LevelID=@LevelID
order by Code";
            SqlParameter[] pars = new SqlParameter[2];
            pars[0] = new SqlParameter("@ProjectID", projectID);
            pars[1] = new SqlParameter("@LevelID", levelID);
            DataTable dt = baseLogic.Select(sql, pars);
            return dt;
        }

        public static int GetDeliveryClientID(string clientCode, int projectID, int userID)
        {
            string spName = @"GetDeliveryClientID";
            SqlParameter[] pars = new SqlParameter[3];
            pars[0] = new SqlParameter("@ClientCode", clientCode);
            pars[1] = new SqlParameter("@ProjectID", projectID);
            pars[2] = new SqlParameter("@UserID", userID);
            DataTable dt = baseLogic.ExceuteStoredProcedure(spName, pars);
            int clientID = 0;
            if (dt != null && dt.Rows.Count > 0) 
            {
                int.TryParse(dt.Rows[0][0].ToString(), out clientID);
            }
            return clientID;
        }

        public static DataTable GetTopClients(int projectID)
        {
            string sql = @"select * from APClients where projectID=@ProjectID and levelID=(select min(levelID) from dbo.APClientStructure where projectID=@ProjectID)";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@ProjectID", projectID);
            DataTable dt = baseLogic.Select(sql, pars);
            return dt;
        }

        public static int GetTopClientID(int projectID) 
        {
            string sql = @"select ID from APClients where projectID=@ProjectID and levelID=(select min(levelID) from dbo.APClientStructure where projectID=@ProjectID)";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@ProjectID", projectID);
            DataTable dt = baseLogic.Select(sql, pars);
            int clientID = 0;
            if (dt != null && dt.Rows.Count > 0) 
            {
                int.TryParse(dt.Rows[0][0].ToString(), out clientID);
            }
            return clientID;
        }

        public static DataTable SearchClients(string name, int typeID, string province, string city, string district, int projectID)
        {
            string spName = "SearchClients";
            SqlParameter[] pars = new SqlParameter[6];
            pars[0] = new SqlParameter("@Name", name);
            pars[1] = new SqlParameter("@TypeID", typeID);
            pars[2] = new SqlParameter("@Province", province);
            pars[3] = new SqlParameter("@City", city);
            pars[4] = new SqlParameter("@District", district);
            pars[5] = new SqlParameter("@ProjectID", projectID);
            DataTable dt = baseLogic.ExceuteStoredProcedure(spName, pars);
            return dt;
        }

        public static DataSet GetClientStatus(int projectID, int questionnaireID, DateTime fromDate, DateTime toDate, int currentClientID)
        {
            string spName = "GetClientStatus";
            SqlParameter[] pars = new SqlParameter[5];
            pars[0] = new SqlParameter("@projectID", projectID);
            pars[1] = new SqlParameter("@questionnaireID", questionnaireID);
            pars[2] = new SqlParameter("@fromDate", fromDate);
            pars[3] = new SqlParameter("@toDate", toDate);
            pars[4] = new SqlParameter("@currentClientID", currentClientID);
            DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.ConnectionString, spName, pars);
            return ds;
        }

        public static DataTable GetSubClientStatus(int projectID, int questionnaireID, DateTime fromDate, DateTime toDate, int currentClientID)
        {
            string spName = "GetSubClientStatus";
            SqlParameter[] pars = new SqlParameter[5];
            pars[0] = new SqlParameter("@projectID", projectID);
            pars[1] = new SqlParameter("@questionnaireID", questionnaireID);
            pars[2] = new SqlParameter("@fromDate", fromDate);
            pars[3] = new SqlParameter("@toDate", toDate);
            pars[4] = new SqlParameter("@currentClientID", currentClientID);
            DataTable dt = baseLogic.ExceuteStoredProcedure(spName, pars);
            return dt;
        }

        public static DataTable GetClientAppealStatus(int projectID)
        {
            string spName = "GetClientAppealStatus";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@projectID", projectID);
            DataTable dt = baseLogic.ExceuteStoredProcedure(spName, pars);
            return dt;
        }

        public static void DeleteClientStructure(int id) 
        {
            APClientStructureDO sdo = new APClientStructureDO();
            sdo.ID = id;
            baseLogic.Delete(sdo);
        }

        public static void DeleteClient(int id)
        {
            APClientsDO sdo = new APClientsDO();
            sdo.ID = id;
            baseLogic.Delete(sdo);
        }

        public static string GetCityCodeByName(string name, int level)
        {
            string sql = @"select Code from APCity where Name=@Name and Level=@Level";
            SqlParameter[] pars = new SqlParameter[2];
            pars[0] = new SqlParameter("@Name", name);
            pars[1] = new SqlParameter("@Level", level);
            DataTable dt = baseLogic.Select(sql, pars);
            string code = string.Empty;
            if (dt != null && dt.Rows.Count > 0)
            {
                code = dt.Rows[0][0].ToString();
            }
            return code;
        }

        public static DataTable GetSubClientsByParentID(int parentID, int projectID)
        {
            string sql = @"select * from APClients where ProjectID=@projectID and ParentID=@parentID";
            SqlParameter[] pars = new SqlParameter[2];
            pars[0] = new SqlParameter("@projectID", projectID);
            pars[1] = new SqlParameter("@parentID", parentID);
            DataTable dt = baseLogic.Select(sql, pars);
            return dt;
        }

        public static string GetFormatFileName(int clientID) 
        {
            List<string> clients = new List<string>();
            APClientsDO clientDO = APClientManager.GetClientDOByID(clientID);
            while (clientDO != null && clientDO.ParentID > 0)
            {
                clients.Add(clientDO.Name);
                clientDO = APClientManager.GetClientDOByID(clientDO.ParentID);
            }
            clients.Reverse();
            string path = string.Join("-", clients.ToArray());
            return path;
        }
    }
}
