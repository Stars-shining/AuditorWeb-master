using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace APLibrary.DataObject
{

    public class APUserRoleDO : DataObjectBase
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

        private string firstPage;
        public string FirstPage
        {
            get { return firstPage; }
            set { firstPage = value; }
        }

        private string menuPage;
        public string MenuPage
        {
            get { return menuPage; }
            set { menuPage = value; }
        }

        private string projectMenuPage;
        public string ProjectMenuPage
        {
            get { return projectMenuPage; }
            set { projectMenuPage = value; }
        }

        public APUserRoleDO()
        {
            this.BO_Name = "APUserRole";
            this.PK_Name = "ID";
        }
    }
}
