using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace APLibrary.DataObject
{

    public class APAnswerOptionsDO : DataObjectBase
    {
        private int iD;
        public int ID
        {
            get { return iD; }
            set { iD = value; }
        }

        private int optionID;
        public int OptionID
        {
            get { return optionID; }
            set { optionID = value; }
        }

        private string optionText;
        public string OptionText
        {
            get { return optionText; }
            set { optionText = value; }
        }

        private int answerID;
        public int AnswerID
        {
            get { return answerID; }
            set { answerID = value; }
        }

        public APAnswerOptionsDO()
        {
            this.BO_Name = "APAnswerOptions";
            this.PK_Name = "ID";
        }
    }
}
