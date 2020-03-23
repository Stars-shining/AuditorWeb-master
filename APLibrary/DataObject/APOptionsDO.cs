using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace APLibrary.DataObject
{

    public class APOptionsDO :DataObjectBase
    {
        private int iD;
        public int ID
        {
            get { return iD; }
            set { iD = value; }
        }

        private string title;
        public string Title
        {
            get { return title; }
            set { title = value; }
        }

        private decimal score;
        public decimal Score
        {
            get { return score; }
            set { score = value; }
        }

        private int optionImageID;
        public int OptionImageID
        {
            get { return optionImageID; }
            set { optionImageID = value; }
        }


        private bool bMustImage;
        public bool BMustImage
        {
            get { return bMustImage; }
            set { bMustImage = value; }
        }

        private bool bAllowText;
        public bool BAllowText
        {
            get { return bAllowText; }
            set { bAllowText = value; }
        }

        private bool bCorrectOption;
        public bool BCorrectOption
        {
            get { return bCorrectOption; }
            set { bCorrectOption = value; }
        }

        private string jumpQuestionCode;
        public string JumpQuestionCode
        {
            get { return jumpQuestionCode; }
            set { jumpQuestionCode = value; }
        }

        private string showQuestionCode;
        public string ShowQuestionCode
        {
            get { return showQuestionCode; }
            set { showQuestionCode = value; }
        }

        private int questionID;
        public int QuestionID
        {
            get { return questionID; }
            set { questionID = value; }
        }

        public APOptionsDO()
        {
            this.BO_Name = "APOptions";
            this.PK_Name = "ID";
        }
    }
}
