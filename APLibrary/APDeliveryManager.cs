using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using APLibrary.DataObject;
using System.Data.SqlClient;
using System.Data;

namespace APLibrary
{
    public class APDeliveryManager : BusinessLogicBase
    {
        private static BusinessLogicBase baseLogic = new BusinessLogicBase();

        public static DataTable GetDeliveryByUserID(int userID)
        {
            string sql = @"
--declare @UserID int
--set @UserID=808206

select dd.ID,
dd.ProjectID,pp.Name as ProjectName,
dd.QuestionnaireID,
qq.Name as QuestionnaireName,
dd.FromDate,dd.ToDate,AcceptUserID,
dd.SampleNumber,
dd.ClientID,
cc.Code as ClientCode,
cc.Name as ClientName,
cc.Address,
cc.LocationCodeX,
cc.LocationCodeY,
province.Name as ProvinceName,
city.Name as CityName,
district.Name as DistrictName
from APQuestionnaireDelivery dd
inner join APProjects pp on pp.ID=dd.ProjectID
inner join APQuestionnaires qq on qq.ID=dd.QuestionnaireID
inner join APClients cc on cc.ID=dd.ClientID
left join APCity province on province.Code=cc.Province
left join APCity city on city.Code=cc.City
left join APCity district on district.Code=cc.District
where dd.AcceptUserID=@UserID";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@UserID", userID);
            DataTable dt = BusinessLogicBase.Default.Select(sql, pars);
            return dt;
        }
    }
}
