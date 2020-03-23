using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace APLibrary.DataObject
{

    public class APQuestionsDO : DataObjectBase
    {
        private int iD;
        public int ID
        {
            get { return iD; }
            set { iD = value; }
        }

        private string code;
        public string Code
        {
            get { return code; }
            set { code = value; }
        }

        private string title;
        public string Title
        {
            get { return title; }
            set { title = value; }
        }

        private string parentCode;
        public string ParentCode
        {
            get { return parentCode; }
            set { parentCode = value; }
        }

        private decimal totalScore;
        public decimal TotalScore
        {
            get { return totalScore; }
            set { totalScore = value; }
        }

        private int countType;
        public int CountType
        {
            get { return countType; }
            set { countType = value; }
        }

        private int questionType;
        public int QuestionType
        {
            get { return questionType; }
            set { questionType = value; }
        }

        private bool bAllowImage;
        public bool BAllowImage
        {
            get { return bAllowImage; }
            set { bAllowImage = value; }
        }

        private bool bAllowAudio;
        public bool BAllowAudio
        {
            get { return bAllowAudio; }
            set { bAllowAudio = value; }
        }

        private bool bAllowVideo;
        public bool BAllowVideo
        {
            get { return bAllowVideo; }
            set { bAllowVideo = value; }
        }

        private bool bMustImage;
        public bool BMustImage
        {
            get { return bMustImage; }
            set { bMustImage = value; }
        }
        private bool bMustAudio;
        public bool BMustAudio
        {
            get { return bMustAudio; }
            set { bMustAudio = value; }
        }
        private bool bMustVideo;
        public bool BMustVideo
        {
            get { return bMustVideo; }
            set { bMustVideo = value; }
        }

        private string description;
        public string Description
        {
            get { return description; }
            set { description = value; }
        }

        private int questionnaireID;
        public int QuestionnaireID
        {
            get { return questionnaireID; }
            set { questionnaireID = value; }
        }

        private int linkQuestionID;
        public int LinkQuestionID
        {
            get { return linkQuestionID; }
            set { linkQuestionID = value; }
        }

        private int linkOptionID;
        public int LinkOptionID
        {
            get { return linkOptionID; }
            set { linkOptionID = value; }
        }

        private DateTime createTime;
        public DateTime CreateTime
        {
            get { return createTime; }
            set { createTime = value; }
        }

        private int createUserID;
        public int CreateUserID
        {
            get { return createUserID; }
            set { createUserID = value; }
        }

        private DateTime lastModifiedTime;
        public DateTime LastModifiedTime
        {
            get { return lastModifiedTime; }
            set { lastModifiedTime = value; }
        }

        private int lastModifiedUserID;
        public int LastModifiedUserID
        {
            get { return lastModifiedUserID; }
            set { lastModifiedUserID = value; }
        }

        private int status;
        public int Status
        {
            get { return status; }
            set { status = value; }
        }

        public bool BHidden { get; set; }

        public APQuestionsDO()
        {
            this.BO_Name = "APQuestions";
            this.PK_Name = "ID";
        }
    }
}
