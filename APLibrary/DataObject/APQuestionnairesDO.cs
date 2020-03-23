using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace APLibrary.DataObject
{

    public class APQuestionnairesDO :DataObjectBase
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

        private decimal totalScore;
        public decimal TotalScore
        {
            get { return totalScore; }
            set { totalScore = value; }
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

        private string description;
        public string Description
        {
            get { return description; }
            set { description = value; }
        }

        private int projectID;
        public int ProjectID
        {
            get { return projectID; }
            set { projectID = value; }
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

        private bool deleteFlag;
        public bool DeleteFlag
        {
            get { return deleteFlag; }
            set { deleteFlag = value; }
        }

        private DateTime deleteTime;
        public DateTime DeleteTime
        {
            get { return deleteTime; }
            set { deleteTime = value; }
        }

        private bool bAutoTickCorrectOption;
        public bool BAutoTickCorrectOption
        {
            get { return bAutoTickCorrectOption; }
            set { bAutoTickCorrectOption = value; }
        }
        private bool bAutoRefreshPage;
        public bool BAutoRefreshPage
        {
            get { return bAutoRefreshPage; }
            set { bAutoRefreshPage = value; }
        }

        private int uploadType;
        public int UploadType
        {
            get { return uploadType; }
            set { uploadType = value; }
        }
        public APQuestionnairesDO()
        {
            this.BO_Name = "APQuestionnaires";
            this.PK_Name = "ID";
        }
    }
}
