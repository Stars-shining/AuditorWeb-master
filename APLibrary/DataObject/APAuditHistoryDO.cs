using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace APLibrary.DataObject
{

    public class APAuditHistoryDO :DataObjectBase
    {
        private int iD;
        public int ID
        {
            get { return iD; }
            set { iD = value; }
        }

        private int auditUserID;
        public int AuditUserID
        {
            get { return auditUserID; }
            set { auditUserID = value; }
        }

        private int auditStatus;
        public int AuditStatus
        {
            get { return auditStatus; }
            set { auditStatus = value; }
        }

        private DateTime auditTime;
        public DateTime AuditTime
        {
            get { return auditTime; }
            set { auditTime = value; }
        }

        private string auditNotes;
        public string AuditNotes
        {
            get { return auditNotes; }
            set { auditNotes = value; }
        }

        private bool auditResult;
        public bool AuditResult
        {
            get { return auditResult; }
            set { auditResult = value; }
        }

        private int returnUserType;
        public int ReturnUserType
        {
            get { return returnUserType; }
            set { returnUserType = value; }
        }

        private int returnUserID;
        public int ReturnUserID
        {
            get { return returnUserID; }
            set { returnUserID = value; }
        }

        private int typeID;
        public int TypeID
        {
            get { return typeID; }
            set { typeID = value; }
        }

        private int questionnaireResultID;
        public int QuestionnaireResultID
        {
            get { return questionnaireResultID; }
            set { questionnaireResultID = value; }
        }

        private int clientID;
        public int ClientID
        {
            get { return clientID; }
            set { clientID = value; }
        }

        private int projectID;
        public int ProjectID
        {
            get { return projectID; }
            set { projectID = value; }
        }

        public APAuditHistoryDO()
        {
            this.BO_Name = "APAuditHistory";
            this.PK_Name = "ID";
        }
    }
}
