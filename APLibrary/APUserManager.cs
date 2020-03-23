using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using APLibrary.DataObject;
using System.Data.SqlClient;
using System.Data;

namespace APLibrary
{
    public class APUserManager : BusinessLogicBase
    {
        private static BusinessLogicBase baseLogic = new BusinessLogicBase();

        public static APUsersDO GetUserByID(int id)
        {
            APUsersDO userDO = new APUsersDO();
            return (APUsersDO)baseLogic.Select(userDO, id);
        }

        public static APUserRoleDO GetUserRoleByID(int id)
        {
            APUserRoleDO userRoleDO = new APUserRoleDO();
            return (APUserRoleDO)baseLogic.Select(userRoleDO, id);
        }

        public static DataTable GetUserInfoByID(int id)
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

        public static DataTable SearchUsers(string name, string province, string city, string district, int roleID)
        {
            string sql = @"
/*
declare @Name nvarchar(50)
declare @Province nvarchar(50)
declare @City nvarchar(50)
declare @District nvarchar(50)
declare @RoleID int

set @Name=''
set @Province=''
set @City=''
set @District=''
set @RoleID=NULL
*/


select uu.*,
province.Name as ProvinceName,
city.Name as CityName,
district.Name as DistrictName
from APUsers uu 
left join APCity province on province.Code=uu.Province
left join APCity city on city.Code=uu.City
left join APCity district on district.Code=uu.District
where RoleID=ISNULL(@RoleID,RoleID)
and isnull(UserName,'') like '%'+@Name+'%' 
and isnull(Province,'')=isnull(@Province,isnull(Province,''))
and isnull(City,'')=isnull(@City,isnull(City,''))
and isnull(District,'')=isnull(@District,isnull(District,''))
and isnull(deleteflag,0)<>1
";

            SqlParameter[] pars = new SqlParameter[5];
            pars[0] = new SqlParameter("@Name", name);
            if (province == "-999")
            {
                pars[1] = new SqlParameter("@Province", DBNull.Value);
            }
            else
            {
                pars[1] = new SqlParameter("@Province", province);
            }
            if (city == "-999") 
            {
                pars[2] = new SqlParameter("@City", DBNull.Value);
            }
            else
            {
                pars[2] = new SqlParameter("@City", city);
            }
            if (district == "-999")
            {
                pars[3] = new SqlParameter("@District", DBNull.Value);
            }
            else
            {
                pars[3] = new SqlParameter("@District", district);
            }
            if (roleID <= 0)
            {
                pars[4] = new SqlParameter("@RoleID", DBNull.Value);
            }
            else
            {
                pars[4] = new SqlParameter("@RoleID", roleID);
            }
            return baseLogic.Select(sql, pars);
        }

        public static DataTable SearchProjectUsers(int projectID, string name, string province, string city, string district, int roleID, int currentUserID, int currentUserType)
        {
            string spName = @"SearchProjectUsers";
            SqlParameter[] pars = new SqlParameter[8];
            pars[0] = new SqlParameter("@Name", name);
            if (roleID <= 0)
            {
                pars[1] = new SqlParameter("@RoleID", DBNull.Value);
            }
            else
            {
                pars[1] = new SqlParameter("@RoleID", roleID);
            }
            pars[2] = new SqlParameter("@ProjectID", projectID);
            if (province == "-999")
            {
                pars[3] = new SqlParameter("@Province", DBNull.Value);
            }
            else
            {
                pars[3] = new SqlParameter("@Province", province);
            }
            if (city == "-999")
            {
                pars[4] = new SqlParameter("@City", DBNull.Value);
            }
            else
            {
                pars[4] = new SqlParameter("@City", city);
            }
            if (district == "-999")
            {
                pars[5] = new SqlParameter("@District", DBNull.Value);
            }
            else
            {
                pars[5] = new SqlParameter("@District", district);
            }
            pars[6] = new SqlParameter("@CurrentUserID", currentUserID);
            pars[7] = new SqlParameter("@CurrentUserType", currentUserType);
            return baseLogic.ExceuteStoredProcedure(spName, pars);
        }

        public static DataTable SearchUsers(string name, int roleID, DateTime fromDate, DateTime toDate, string province, string city, string district, int statusID,int currentUserID, int currentUserType)
        {
            string spName = @"SearchUsers";
            SqlParameter[] pars = new SqlParameter[10];
            pars[0] = new SqlParameter("@Name", name);
            if (roleID <= 0)
            {
                pars[1] = new SqlParameter("@RoleID", DBNull.Value);
            }
            else
            {
                pars[1] = new SqlParameter("@RoleID", roleID);
            }
            pars[2] = new SqlParameter("@FromDate", fromDate);
            pars[3] = new SqlParameter("@ToDate", toDate);
            if (statusID < 0)
            {
                pars[4] = new SqlParameter("@StatusID", DBNull.Value);
            }
            else
            {
                pars[4] = new SqlParameter("@StatusID", statusID);
            }
            if (province == "-999")
            {
                pars[5] = new SqlParameter("@Province", DBNull.Value);
            }
            else
            {
                pars[5] = new SqlParameter("@Province", province);
            }
            if (city == "-999")
            {
                pars[6] = new SqlParameter("@City", DBNull.Value);
            }
            else
            {
                pars[6] = new SqlParameter("@City", city);
            }
            if (district == "-999")
            {
                pars[7] = new SqlParameter("@District", DBNull.Value);
            }
            else
            {
                pars[7] = new SqlParameter("@District", district);
            }
            pars[8] = new SqlParameter("@CurrentUserID", currentUserID);
            pars[9] = new SqlParameter("@CurrentUserType", currentUserType);
            return baseLogic.ExceuteStoredProcedure(spName, pars);
        }

        public static APUsersDO GetClientUserDO(int clientID, int projectID)
        {
            string sql = "select * from APUsers where ClientID=@ClientID and ProjectID=@ProjectID";
            SqlParameter[] pars = new SqlParameter[2];
            pars[0] = new SqlParameter("@ClientID", clientID);
            pars[1] = new SqlParameter("@ProjectID", projectID);
            APUsersDO userDO = new APUsersDO();
            userDO = (APUsersDO)BusinessLogicBase.Default.Select(userDO, sql, pars);
            return userDO;
        }

        public static int GetUserIDByIDCardNumber(string idCardNumber)
        {
            int id = 0;
            string sql = "select id from APUsers where IDCardNumber=@idCardNumber and RoleID=4 and isnull(deleteflag,0)=0";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@idCardNumber", idCardNumber);
            DataTable dt = BusinessLogicBase.Default.Select(sql, pars);
            if (dt != null && dt.Rows.Count > 0) 
            {
                int.TryParse(dt.Rows[0][0].ToString(), out id);
            }
            return id;
        }

        public static bool CheckLoginNameExisting(string loginName, int oldID)
        {
            string sql = "select ID from APUsers where LoginName=@LoginName and DeleteFlag=0";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@LoginName", loginName);
            DataTable dt = BusinessLogicBase.Default.Select(sql, pars);
            bool bExisting = false;
            if (dt != null && dt.Rows.Count > 0) 
            {
                if (oldID > 0)
                {
                    if (dt.Rows.Count > 1)
                    {
                        bExisting = true;
                    }
                    else if (dt.Rows.Count == 1)
                    {
                        int id = 0;
                        int.TryParse(dt.Rows[0][0].ToString(), out id);
                        if (id != oldID)
                        {
                            bExisting = true;
                        }
                    }
                }
                else
                {
                    bExisting = true;
                }
            }
            return bExisting;
        }

        public static int GetUserRoleIDByRoleName(string name)
        {
            string sql = "select ID from APUserRole where name=@name";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@name", name);
            DataTable dt = BusinessLogicBase.Default.Select(sql, pars);
            int roleID = 0;
            if (dt != null && dt.Rows.Count > 0)
            {
                int.TryParse(dt.Rows[0][0].ToString(), out roleID);
            }
            return roleID;
        }

        public static APUsersDO GetUserDOByLoginName(string name)
        {
            string sql = "select * from APUsers where LoginName=@name";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@name", name);
            DataTable dt = BusinessLogicBase.Default.Select(sql, pars);
            APUsersDO userDO = new APUsersDO();
            userDO = (APUsersDO)BusinessLogicBase.Default.Select(userDO, sql, pars);
            return userDO;
        }

        public static APUsersDO GetUserDOByUserName(string name, int roleID)
        {
            string sql = "select * from APUsers where UserName=@name and RoleID=@roleID";
            SqlParameter[] pars = new SqlParameter[2];
            pars[0] = new SqlParameter("@name", name);
            pars[1] = new SqlParameter("@roleID", roleID);
            DataTable dt = BusinessLogicBase.Default.Select(sql, pars);
            APUsersDO userDO = new APUsersDO();
            userDO = (APUsersDO)BusinessLogicBase.Default.Select(userDO, sql, pars);
            return userDO;
        }

        public static void DeleteUser(int id) 
        {
            APUsersDO upo = GetUserByID(id);
            upo.DeleteFlag = true;
            upo.DeleteTime = DateTime.Now;
            baseLogic.Update(upo);
        }

        public static APUsersDO TryLoginClientUser(string userName, string password, int projectID)
        {
            string sql = "select * from APUsers where LoginName=@username and password=@password and projectID=@projectID and isnull(DeleteFlag,0)=0";
            SqlParameter[] paras = new SqlParameter[3];
            paras[0] = new SqlParameter("@username", userName.Trim());
            paras[1] = new SqlParameter("@password", password);
            paras[2] = new SqlParameter("@projectID", projectID);
            APUsersDO userDO = new APUsersDO();
            userDO = (APUsersDO)BusinessLogicBase.Default.Select(userDO, sql, paras);
            return userDO;
        }

        public static APUsersDO TryLoginUser(string userName, string password)
        {
            string sql = "select * from APUsers where LoginName=@username and password=@password and isnull(DeleteFlag,0)=0";
            SqlParameter[] paras = new SqlParameter[2];
            paras[0] = new SqlParameter("@username", userName.Trim());
            paras[1] = new SqlParameter("@password", password);
            APUsersDO userDO = new APUsersDO();
            userDO = (APUsersDO)BusinessLogicBase.Default.Select(userDO, sql, paras);
            return userDO;
        }

        public static bool CheckIsInAppealPeriod(DateTime time, int projectID) 
        {
            string sql = @"select count(ID) from [dbo].[APAppealPeriod] 
                            where ProjectID=@ProjectID 
                            and @CurrentTime>=FromDate 
                            and @CurrentTime<DATEADD(day,1,ToDate)";
            SqlParameter[] paras = new SqlParameter[2];
            paras[0] = new SqlParameter("@ProjectID", projectID);
            paras[1] = new SqlParameter("@CurrentTime", time);
            DataTable dt = BusinessLogicBase.Default.Select(sql, paras);
            bool bFlag = false;
            if (dt != null && dt.Rows.Count > 0) 
            {
                int count = 0;
                int.TryParse(dt.Rows[0][0].ToString(), out count);
                if (count > 0)
                {
                    bFlag = true;
                }
            }
            return bFlag;
        }
    }
}
