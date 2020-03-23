using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace APLibrary.DataObject
{

    public class APQuestionAuditNotesDO :DataObjectBase
    {
        private int iD;
        public int ID
        {
            get { return iD; }
            set { iD = value; }
        }

        private string auditNotes;
        public string AuditNotes
        {
            get { return auditNotes; }
            set { auditNotes = value; }
        }

        private int auditTypeID;
        public int AuditTypeID
        {
            get { return auditTypeID; }
            set { auditTypeID = value; }
        }

        private int userTypeID;
        public int UserTypeID
        {
            get { return userTypeID; }
            set { userTypeID = value; }
        }

        private int questionID;
        public int QuestionID
        {
            get { return questionID; }
            set { questionID = value; }
        }

        private int resultID;
        public int ResultID
        {
            get { return resultID; }
            set { resultID = value; }
        }

        private int createUserID;
        public int CreateUserID
        {
            get { return createUserID; }
            set { createUserID = value; }
        }

        private DateTime createTime;
        public DateTime CreateTime
        {
            get { return createTime; }
            set { createTime = value; }
        }

        public APQuestionAuditNotesDO()
        {
            this.BO_Name = "APQuestionAuditNotes";
            this.PK_Name = "ID";
        }
    }
}
