using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace APLibrary.DataObject
{

    public class APAnswerEditHistoryDO : DataObjectBase
    {
        private int iD;
        public int ID
        {
            get { return iD; }
            set { iD = value; }
        }

        private int answerID;
        public int AnswerID
        {
            get { return answerID; }
            set { answerID = value; }
        }

        private string editNote;
        public string EditNote
        {
            get { return editNote; }
            set { editNote = value; }
        }

        private string scoreNote;
        public string ScoreNote
        {
            get { return scoreNote; }
            set { scoreNote = value; }
        }

        private int resultID;
        public int ResultID
        {
            get { return resultID; }
            set { resultID = value; }
        }

        private int stageStatusID;
        public int StageStatusID
        {
            get { return stageStatusID; }
            set { stageStatusID = value; }
        }

        private int userID;
        public int UserID
        {
            get { return userID; }
            set { userID = value; }
        }

        private DateTime inputDate;
        public DateTime InputDate
        {
            get { return inputDate; }
            set { inputDate = value; }
        }


        public APAnswerEditHistoryDO()
        {
            this.BO_Name = "APAnswerEditHistory";
            this.PK_Name = "ID";
        }
    }
}
