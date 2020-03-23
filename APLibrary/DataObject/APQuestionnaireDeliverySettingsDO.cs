using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace APLibrary.DataObject
{

    public class APQuestionnaireDeliverySettingsDO :DataObjectBase
    {
        private int iD;
        public int ID
        {
            get { return iD; }
            set { iD = value; }
        }

        private int areaLevelID;
        public int AreaLevelID
        {
            get { return areaLevelID; }
            set { areaLevelID = value; }
        }

        private int cityLevelID;
        public int CityLevelID
        {
            get { return cityLevelID; }
            set { cityLevelID = value; }
        }

        private int visitLevelID;
        public int VisitLevelID
        {
            get { return visitLevelID; }
            set { visitLevelID = value; }
        }

        private int qcLevelID;
        public int QCLevelID
        {
            get { return qcLevelID; }
            set { qcLevelID = value; }
        }

        private int projectID;
        public int ProjectID
        {
            get { return projectID; }
            set { projectID = value; }
        }

        public APQuestionnaireDeliverySettingsDO()
        {
            this.BO_Name = "APQuestionnaireDeliverySettings";
            this.PK_Name = "ID";
        }
    }
}
