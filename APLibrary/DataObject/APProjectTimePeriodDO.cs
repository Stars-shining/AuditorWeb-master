using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace APLibrary.DataObject
{

    public class APProjectTimePeriodDO :DataObjectBase
    {
        private int iD;
        public int ID
        {
            get { return iD; }
            set { iD = value; }
        }
        public int ProjectID { get; set; }
        public TimeSpan TimeStart { get; set; }
        public TimeSpan TimeEnd { get; set; }
        public string Title { get; set; }

        public APProjectTimePeriodDO()
        {
            this.BO_Name = "APProjectTimePeriod";
            this.PK_Name = "ID";
        }
    }
}
