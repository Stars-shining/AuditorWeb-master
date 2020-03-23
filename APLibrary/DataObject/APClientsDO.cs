using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace APLibrary.DataObject
{

    public class APClientsDO :DataObjectBase
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

        private string name;
        public string Name
        {
            get { return name; }
            set { name = value; }
        }

        private string province;
        public string Province
        {
            get { return province; }
            set { province = value; }
        }

        private string city;
        public string City
        {
            get { return city; }
            set { city = value; }
        }

        private string district;
        public string District
        {
            get { return district; }
            set { district = value; }
        }

        private string address;
        public string Address
        {
            get { return address; }
            set { address = value; }
        }

        private string locationCodeX;
        public string LocationCodeX
        {
            get { return locationCodeX; }
            set { locationCodeX = value; }
        }

        private string locationCodeY;
        public string LocationCodeY
        {
            get { return locationCodeY; }
            set { locationCodeY = value; }
        }

        private string openingTime;
        public string OpeningTime
        {
            get { return openingTime; }
            set { openingTime = value; }
        }

        private int parentID;
        public int ParentID
        {
            get { return parentID; }
            set { parentID = value; }
        }

        private string description;
        public string Description
        {
            get { return description; }
            set { description = value; }
        }

        private string email;
        public string Email
        {
            get { return email; }
            set { email = value; }
        }

        private string phoneNumber;
        public string PhoneNumber
        {
            get { return phoneNumber; }
            set { phoneNumber = value; }
        }

        private string postcode;
        public string Postcode
        {
            get { return postcode; }
            set { postcode = value; }
        }

        private int levelID;
        public int LevelID
        {
            get { return levelID; }
            set { levelID = value; }
        }

        private int projectID;
        public int ProjectID
        {
            get { return projectID; }
            set { projectID = value; }
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

        public APClientsDO()
        {
            this.BO_Name = "APClients";
            this.PK_Name = "ID";
        }
    }
}
