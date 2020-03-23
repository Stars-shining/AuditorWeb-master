using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace CopyFiles
{

    public class DocumentFilesDO : DataObjectBase
    {
        private int iD;
        public int ID
        {
            get { return iD; }
            set { iD = value; }
        }

        private string fileName;
        public string FileName
        {
            get { return fileName; }
            set { fileName = value; }
        }

        private decimal fileSize;
        public decimal FileSize
        {
            get { return fileSize; }
            set { fileSize = value; }
        }

        private string originalFileName;
        public string OriginalFileName
        {
            get { return originalFileName; }
            set { originalFileName = value; }
        }

        private string thumbRelevantPath;
        public string ThumbRelevantPath
        {
            get { return thumbRelevantPath; }
            set { thumbRelevantPath = value; }
        }

        private string relevantPath;
        public string RelevantPath
        {
            get { return relevantPath; }
            set { relevantPath = value; }
        }

        private string physicalPath;
        public string PhysicalPath
        {
            get { return physicalPath; }
            set { physicalPath = value; }
        }

        private int fileType;
        public int FileType
        {
            get { return fileType; }
            set { fileType = value; }
        }

        private DateTime fromDate;
        public DateTime FromDate
        {
            get { return fromDate; }
            set { fromDate = value; }
        }

        private DateTime toDate;
        public DateTime ToDate
        {
            get { return toDate; }
            set { toDate = value; }
        }

        private int relatedID;
        public int RelatedID
        {
            get { return relatedID; }
            set { relatedID = value; }
        }

        private string tempCode;
        public string TempCode
        {
            get { return tempCode; }
            set { tempCode = value; }
        }

        private int typeID;
        public int TypeID
        {
            get { return typeID; }
            set { typeID = value; }
        }

        private DateTime inputDate;
        public DateTime InputDate
        {
            get { return inputDate; }
            set { inputDate = value; }
        }

        private int userID;
        public int UserID
        {
            get { return userID; }
            set { userID = value; }
        }

        private int status;
        public int Status
        {
            get { return status; }
            set { status = value; }
        }

        private int backupStatus;
        public int BackupStatus
        {
            get { return backupStatus; }
            set { backupStatus = value; }
        }

        public DocumentFilesDO()
        {
            this.BO_Name = "DocumentFiles";
            this.PK_Name = "ID";
        }
    }
}
