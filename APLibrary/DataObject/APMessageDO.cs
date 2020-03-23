using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace APLibrary.DataObject
{

    public class APMessageDO : DataObjectBase
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

        private string content;
        public string Content
        {
            get { return content; }
            set { content = value; }
        }

        private int fromUserID;
        public int FromUserID
        {
            get { return fromUserID; }
            set { fromUserID = value; }
        }

        private int acceptUserID;
        public int AcceptUserID
        {
            get { return acceptUserID; }
            set { acceptUserID = value; }
        }

        private int typeID;
        public int TypeID
        {
            get { return typeID; }
            set { typeID = value; }
        }

        private int relatedID;
        public int RelatedID
        {
            get { return relatedID; }
            set { relatedID = value; }
        }

        private string relatedUrl;
        public string RelatedUrl
        {
            get { return relatedUrl; }
            set { relatedUrl = value; }
        }

        private int projectID;
        public int ProjectID
        {
            get { return projectID; }
            set { projectID = value; }
        }

        private int templateID;
        public int TemplateID
        {
            get { return templateID; }
            set { templateID = value; }
        }

        private int createUserID;
        public int CreateUserID
        {
            get { return createUserID; }
            set { createUserID = value; }
        }

        private DateTime createTime;
        public DateTime CreateTime
        {
            get { return createTime; }
            set { createTime = value; }
        }

        private int status;
        public int Status
        {
            get { return status; }
            set { status = value; }
        }

        public APMessageDO()
        {
            this.BO_Name = "APMessage";
            this.PK_Name = "ID";
        }
    }
}
