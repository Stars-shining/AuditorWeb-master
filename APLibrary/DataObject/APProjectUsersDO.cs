using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace APLibrary.DataObject
{

    public class APProjectUsersDO :DataObjectBase
    {
        private int iD;
        public int ID
        {
            get { return iD; }
            set { iD = value; }
        }

        private int userID;
        public int UserID
        {
            get { return userID; }
            set { userID = value; }
        }

        private int roleID;
        public int RoleID
        {
            get { return roleID; }
            set { roleID = value; }
        }

        private int projectID;
        public int ProjectID
        {
            get { return projectID; }
            set { projectID = value; }
        }

        public APProjectUsersDO()
        {
            this.BO_Name = "APProjectUsers";
            this.PK_Name = "ID";
        }
    }
}
