using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using APLibrary.DataObject;

namespace APLibrary
{
    public class DocumentManager : BusinessLogicBase
    {
        private static BusinessLogicBase baseLogic = new BusinessLogicBase();

        public static DataTable GetDocuments(DateTime fromDate, DateTime toDate, int statusid,int typeid)
        {
            string sql = @"
                select dd.ID,
                dd.OriginalFileName,
                Convert(varchar(100), dd.InputDate,20) as InputDate,
                bc.ItemValue as StatusName,
                bc2.ItemValue as TypeName,
                dd.TypeID as TypeID
                from dbo.DocumentFiles dd
                LEFT Join  BusinessConfiguration bc on bc.ItemKey=dd.Status and bc.ItemDesc='UploadStatus'
                LEFT Join  BusinessConfiguration bc2 on bc2.ItemKey=dd.TypeID and bc2.ItemDesc='DocumentType'
                where dd.status=ISNULL(@status, dd.status) 
                and dd.typeid=ISNULL(@typeid, dd.typeid) 
                and DATEDIFF(DAY,dd.InputDate,isnull(@startDate,'2000-1-1'))<=0
                and DATEDIFF(DAY,dd.InputDate,isnull(@endDate,'2099-1-1'))>=0
                and dd.TypeID<>8
order by dd.InputDate desc";
            SqlParameter[] pars = new SqlParameter[4];
            if (statusid == Constants.AllValue)
            {
                pars[0] = new SqlParameter("@status", DBNull.Value);
            }
            else
            {
                pars[0] = new SqlParameter("@status", statusid);
            }
            if (typeid == Constants.AllValue)
            {
                pars[1] = new SqlParameter("@typeid", DBNull.Value);
            }
            else
            {
                pars[1] = new SqlParameter("@typeid", typeid);
            }
            if (fromDate <= Constants.Date_Min)
            {
                pars[2] = new SqlParameter("@startDate", DBNull.Value);
            }
            else
            {
                pars[2] = new SqlParameter("@startDate", fromDate);
            }
            if (toDate <= Constants.Date_Min)
            {
                pars[3] = new SqlParameter("@endDate", DBNull.Value);
            }
            else
            {
                pars[3] = new SqlParameter("@endDate", toDate);
            }
            return baseLogic.Select(sql, pars);
        }

        public static DataTable GetFilesByRelatedID(int relatedid, int typeid, int statusID, bool bIncludeAll, string tempCode)
        {
            //Diego changed at 2018-4-24
            //1 get file by related ID，2 when  related id is mising, then get file by tempcode
            string sql = @"select d.*,b.ItemValue as 'FileTypeName' 
from DocumentFiles d
left join BusinessConfiguration b on b.ItemDesc='FileType' and b.ItemKey=d.FileType 
where 
(
		(isnull(@RelatedID,0)>0 and d.RelatedID=@RelatedID)
		or
		(isnull(@TempCode,'')<>'' and d.TempCode=@TempCode)
) 
and d.TypeID=@TypeID 
and isnull(d.Status,0)=@StatusID";
            if (typeid == 4 && bIncludeAll == true)
            {
                sql = @"select d.*,b.ItemValue as 'FileTypeName' 
from DocumentFiles d
left join BusinessConfiguration b on b.ItemDesc='FileType' and b.ItemKey=d.FileType 
where 
(
		(isnull(@RelatedID,0)>0 and d.RelatedID=@RelatedID)
		or
		(isnull(@TempCode,'')<>'' and d.TempCode=@TempCode)
) 
and d.TypeID in (3, @TypeID) 
and isnull(d.Status,0)=@StatusID";
            }
            SqlParameter[] pars = new SqlParameter[4];
            if (relatedid > 0)
            {
                pars[0] = new SqlParameter("@RelatedID", relatedid);
            }
            else 
            {
                pars[0] = new SqlParameter("@RelatedID", DBNull.Value);
            }
            pars[1] = new SqlParameter("@TypeID", typeid);
            pars[2] = new SqlParameter("@StatusID", statusID);
            if (tempCode == "")
            {
                pars[3] = new SqlParameter("@TempCode", DBNull.Value);
            }
            else
            {
                pars[3] = new SqlParameter("@TempCode", tempCode);
            }
            return baseLogic.Select(sql, pars);
        }

        public static DocumentFilesDO GetDOcumentFileDOByRelatedID(int relatedid, int typeid)
        {
            string sql = @"select * from DocumentFiles where RelatedID=@RelatedID and TypeID=@TypeID";
            SqlParameter[] pars = new SqlParameter[2];
            pars[0] = new SqlParameter("@RelatedID", relatedid);
            pars[1] = new SqlParameter("@TypeID", typeid);
            DocumentFilesDO doc = new DocumentFilesDO();
            return (DocumentFilesDO)baseLogic.Select(doc, sql, pars);
        }

        public static DataTable GetFilesByTempCode(string tempCode, int typeid, bool bIncludeAll)
        {
            string sql = @"select d.*,b.ItemValue as 'FileTypeName' 
from DocumentFiles d
left join BusinessConfiguration b on b.ItemDesc='FileType' and b.ItemKey=d.FileType 
where d.TempCode=@TempCode and d.TypeID=@TypeID and isnull(d.Status,0)=0";

            if (typeid == 4 && bIncludeAll == true)
            {
                sql = @"select d.*,b.ItemValue as 'FileTypeName' 
from DocumentFiles d
left join BusinessConfiguration b on b.ItemDesc='FileType' and b.ItemKey=d.FileType 
where d.TempCode=@TempCode and d.TypeID in (3, @TypeID) and isnull(d.Status,0)=0";
            }
            SqlParameter[] pars = new SqlParameter[2];
            pars[0] = new SqlParameter("@TempCode", tempCode);
            pars[1] = new SqlParameter("@TypeID", typeid);
            return baseLogic.Select(sql, pars);
        }

        public static DirectoryMappingDO GetCurrentDirMappingDO()
        {
            string sql = "select * from dbo.DirectoryMapping where isCurrent=1";
            DirectoryMappingDO dmDO = new DirectoryMappingDO();
            dmDO = (DirectoryMappingDO)baseLogic.Select(dmDO, sql);
            return dmDO;
        }

        public static DataTable GetAllUnCopyFilesByFileType()
        {
            string sql = @"select * from DocumentFiles where isnull(backupStatus,0)=0 and fileType=3";
            return baseLogic.Select(sql);
        }
    }
}
