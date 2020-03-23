using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using APLibrary.DataObject;
using System.Data.SqlClient;
using System.Data;

namespace APLibrary
{
    public class APTrainingManager : BusinessLogicBase
    {
        private static BusinessLogicBase baseLogic = new BusinessLogicBase();

        public static APTrainingDO GetTrainingDOByID(int id)
        {
            APTrainingDO clientDO = new APTrainingDO();
            return (APTrainingDO)baseLogic.Select(clientDO, id);
        }

        public static void DeleteTrainingByID(int id)
        {
            string sql = "delete from APTraining where id=@id";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@id", id);
            BusinessLogicBase.Default.Execute(sql, pars);
        }

        public static DataTable GetTrainings(string title, int projectID, int typeID, DateTime fromDate, DateTime toDate)
        {
            string sql = @"select tt.*,bc.ItemValue as TrainingTypeName,pp.Name as ProjectName from APtraining tt
left join BusinessConfiguration bc on bc.ItemKey=tt.TypeID and bc.ItemDesc='TrainingType'
left join APProjects pp on pp.ID=tt.ProjectID
where tt.title like '%'+@title+'%' 
and tt.projectID=isnull(@projectID,tt.projectID) 
and tt.typeID=isnull(@typeID,tt.typeID) 
and tt.fromDate<=@toDate 
and tt.toDate>=@fromDate";
            SqlParameter[] pars = new SqlParameter[5];
            pars[0] = new SqlParameter("@title", title);
            if (projectID < 0)
            {
                pars[1] = new SqlParameter("@projectID", DBNull.Value);
            }
            else
            {
                pars[1] = new SqlParameter("@projectID", projectID);
            }
            if (typeID < 0)
            {
                pars[2] = new SqlParameter("@typeID", DBNull.Value);
            }
            else
            {
                pars[2] = new SqlParameter("@typeID", typeID);
            }
            pars[3] = new SqlParameter("@toDate", toDate);
            pars[4] = new SqlParameter("@fromDate", fromDate);
            DataTable dt = baseLogic.Select(sql, pars);
            return dt;
        }

        public static DataTable GetTrainingFiles(int trainingID) 
        {
            string sql = @"select tt.*,bc.ItemValue as FileTypeName
from APTrainingFiles tt 
left join BusinessConfiguration bc on bc.ItemKey=tt.FileType and bc.ItemDesc='FileType'
where tt.TrainingID=@trainingID and isnull(tt.status,0)<>1";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@trainingID", trainingID);
            DataTable dt = baseLogic.Select(sql, pars);
            return dt;
        }
    }
}
