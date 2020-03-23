using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace APLibrary.DataObject
{

    public class APClientStructureDO :DataObjectBase
    {
        private int iD;
        public int ID
        {
            get { return iD; }
            set { iD = value; }
        }

        private int levelID;
        public int LevelID
        {
            get { return levelID; }
            set { levelID = value; }
        }

        private string name;
        public string Name
        {
            get { return name; }
            set { name = value; }
        }

        private int projectID;
        public int ProjectID
        {
            get { return projectID; }
            set { projectID = value; }
        }


        public APClientStructureDO()
        {
            this.BO_Name = "APClientStructure";
            this.PK_Name = "ID";
        }
    }
}
