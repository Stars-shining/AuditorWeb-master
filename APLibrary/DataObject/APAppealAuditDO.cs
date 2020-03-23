using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace APLibrary.DataObject
{

    public class APAppealAuditDO : DataObjectBase
    {
        private int iD;
        public int ID
        {
            get { return iD; }
            set { iD = value; }
        }

        private int resultID;
        public int ResultID
        {
            get { return resultID; }
            set { resultID = value; }
        }

        private int questionID;
        public int QuestionID
        {
            get { return questionID; }
            set { questionID = value; }
        }

        private int appealStatus;
        public int AppealStatus
        {
            get { return appealStatus; }
            set { appealStatus = value; }
        }

        private int userID;
        public int UserID
        {
            get { return userID; }
            set { userID = value; }
        }

        private DateTime inputDate;
        public DateTime InputDate
        {
            get { return inputDate; }
            set { inputDate = value; }
        }

        public APAppealAuditDO()
        {
            this.BO_Name = "APAppealAudit";
            this.PK_Name = "ID";
        }
    }
}
