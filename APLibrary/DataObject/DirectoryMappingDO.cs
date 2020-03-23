using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace APLibrary.DataObject
{

    public class DirectoryMappingDO : DataObjectBase
    {
        private int iD;
        public int ID
        {
            get { return iD; }
            set { iD = value; }
        }

        private string physicalPath;
        public string PhysicalPath
        {
            get { return physicalPath; }
            set { physicalPath = value; }
        }

        private string vituralPath;
        public string VituralPath
        {
            get { return vituralPath; }
            set { vituralPath = value; }
        }

        private bool isCurrent;
        public bool IsCurrent
        {
            get { return isCurrent; }
            set { isCurrent = value; }
        }

        public DirectoryMappingDO()
        {
            this.BO_Name = "DirectoryMapping";
            this.PK_Name = "ID";
        }
    }
}
