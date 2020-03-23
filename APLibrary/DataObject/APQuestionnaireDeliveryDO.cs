using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace APLibrary.DataObject
{

    public class APQuestionnaireDeliveryDO : DataObjectBase
    {
        private int iD;
        public int ID
        {
            get { return iD; }
            set { iD = value; }
        }

        private int questionnaireID;
        public int QuestionnaireID
        {
            get { return questionnaireID; }
            set { questionnaireID = value; }
        }

        private int clientID;
        public int ClientID
        {
            get { return clientID; }
            set { clientID = value; }
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

        private int typeID;
        public int TypeID
        {
            get { return typeID; }
            set { typeID = value; }
        }

        private int acceptUserID;
        public int AcceptUserID
        {
            get { return acceptUserID; }
            set { acceptUserID = value; }
        }

        private int sampleNumber;
        public int SampleNumber
        {
            get { return sampleNumber; }
            set { sampleNumber = value; }
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

        public APQuestionnaireDeliveryDO()
        {
            this.BO_Name = "APQuestionnaireDelivery";
            this.PK_Name = "ID";
        }
    }
}
