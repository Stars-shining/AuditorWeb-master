using System;
using System.Collections.Generic;
using System.Text;

namespace APLibrary
{
    [Serializable]
    public class DataObjectBase
    {
        public static readonly DateTime Date_Min = new DateTime(1900, 1, 2);
        public static readonly DateTime Date_Null = new DateTime(1900, 1, 1);
        public string BO_Name = "";
        public string PK_Name = "";

        public DataObjectBase Clone()
        {
            Type ObjType = this.GetType();
            DataObjectBase newobj = BusinessLogicBase.CopyValue(ObjType, this) as DataObjectBase;
            return newobj;
        }

        public DataObjectBase CloneAll()
        {
            Type ObjType = this.GetType();
            DataObjectBase newobj = BusinessLogicBase.CopyValueAll(ObjType, this) as DataObjectBase;
            return newobj;
        }

        public DataObjectBase CloneFieldsAll()
        {
            Type ObjType = this.GetType();
            DataObjectBase newobj = BusinessLogicBase.CopyFieldsAll(ObjType, this) as DataObjectBase;
            return newobj;
        }
    }
}
