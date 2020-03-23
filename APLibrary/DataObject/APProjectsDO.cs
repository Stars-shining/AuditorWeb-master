using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace APLibrary.DataObject
{

    public class APProjectsDO :DataObjectBase
    {
        private int iD;
        public int ID
        {
            get { return iD; }
            set { iD = value; }
        }

        private string name;
        public string Name
        {
            get { return name; }
            set { name = value; }
        }

        private int typeID;
        public int TypeID
        {
            get { return typeID; }
            set { typeID = value; }
        }

        private string background;
        public string Background
        {
            get { return background; }
            set { background = value; }
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

        private string description;
        public string Description
        {
            get { return description; }
            set { description = value; }
        }

        private int sampleNumber;
        public int SampleNumber
        {
            get { return sampleNumber; }
            set { sampleNumber = value; }
        }

        private int frequency;
        public int Frequency
        {
            get { return frequency; }
            set { frequency = value; }
        }

        private int coreUserID;
        public int CoreUserID
        {
            get { return coreUserID; }
            set { coreUserID = value; }
        }

        private int primaryApplyUserID;
        public int PrimaryApplyUserID
        {
            get { return primaryApplyUserID; }
            set { primaryApplyUserID = value; }
        }

        private int qCLeaderUserID;
        public int QCLeaderUserID
        {
            get { return qCLeaderUserID; }
            set { qCLeaderUserID = value; }
        }

        private bool bHasAreaUser;
        public bool BHasAreaUser
        {
            get { return bHasAreaUser; }
            set { bHasAreaUser = value; }
        }

        private bool bAutoAppeal;
        public bool BAutoAppeal
        {
            get { return bAutoAppeal; }
            set { bAutoAppeal = value; }
        }

        private int groupID;
        public int GroupID
        {
            get { return groupID; }
            set { groupID = value; }
        }

        private DateTime createTime;
        public DateTime CreateTime
        {
            get { return createTime; }
            set { createTime = value; }
        }

        private int createUserID;
        public int CreateUserID
        {
            get { return createUserID; }
            set { createUserID = value; }
        }

        private DateTime lastModifiedTime;
        public DateTime LastModifiedTime
        {
            get { return lastModifiedTime; }
            set { lastModifiedTime = value; }
        }

        private int lastModifiedUserID;
        public int LastModifiedUserID
        {
            get { return lastModifiedUserID; }
            set { lastModifiedUserID = value; }
        }

        private int status;
        public int Status
        {
            get { return status; }
            set { status = value; }
        }

        private int uploadValidationType;
        public int UploadValidationType
        {
            get { return uploadValidationType; }
            set { uploadValidationType = value; }
        }

        private bool deleteflag;
        public bool DeleteFlag
        {
            get { return deleteflag; }
            set { deleteflag = value; }
        }

        private DateTime deleteTime;
        public DateTime DeleteTime
        {
            get { return deleteTime; }
            set { deleteTime = value; }
        }

        public APProjectsDO()
        {
            this.BO_Name = "APProjects";
            this.PK_Name = "ID";
        }
    }
}
