using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace APLibrary.DataObject
{

    public class APAppealPeriodDO : DataObjectBase
    {
        private int iD;
        public int ID
        {
            get { return iD; }
            set { iD = value; }
        }

        private int projectID;
        public int ProjectID
        {
            get { return projectID; }
            set { projectID = value; }
        }

        private int questionnaireID;
        public int QuestionnaireID
        {
            get { return questionnaireID; }
            set { questionnaireID = value; }
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

        public APAppealPeriodDO()
        {
            this.BO_Name = "APAppealPeriod";
            this.PK_Name = "ID";
        }
    }
}
