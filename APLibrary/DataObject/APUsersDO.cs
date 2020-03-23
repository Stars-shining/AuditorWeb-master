using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace APLibrary.DataObject
{

    public class APUsersDO :DataObjectBase
    {
        private int iD;
        public int ID
        {
            get { return iD; }
            set { iD = value; }
        }

        private string loginName;
        public string LoginName
        {
            get { return loginName; }
            set { loginName = value; }
        }

        private string userName;
        public string UserName
        {
            get { return userName; }
            set { userName = value; }
        }

        private string password;
        public string Password
        {
            get { return password; }
            set { password = value; }
        }

        private DateTime dateOfBirth;
        public DateTime DateOfBirth
        {
            get { return dateOfBirth; }
            set { dateOfBirth = value; }
        }

        private int sex;
        public int Sex
        {
            get { return sex; }
            set { sex = value; }
        }

        private string address;
        public string Address
        {
            get { return address; }
            set { address = value; }
        }

        private string postcode;
        public string Postcode
        {
            get { return postcode; }
            set { postcode = value; }
        }

        private string email;
        public string Email
        {
            get { return email; }
            set { email = value; }
        }

        private string mobilePhone;
        public string MobilePhone
        {
            get { return mobilePhone; }
            set { mobilePhone = value; }
        }

        private string telephone;
        public string Telephone
        {
            get { return telephone; }
            set { telephone = value; }
        }

        private string photoPath;
        public string PhotoPath
        {
            get { return photoPath; }
            set { photoPath = value; }
        }

        private int areaID;
        public int AreaID
        {
            get { return areaID; }
            set { areaID = value; }
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

        private int degree;
        public int Degree
        {
            get { return degree; }
            set { degree = value; }
        }

        private string iDCardNumber;
        public string IDCardNumber
        {
            get { return iDCardNumber; }
            set { iDCardNumber = value; }
        }

        private int region;
        public int Region
        {
            get { return region; }
            set { region = value; }
        }

        private int houseHoldRegistration;
        public int HouseHoldRegistration
        {
            get { return houseHoldRegistration; }
            set { houseHoldRegistration = value; }
        }

        private string houseHoldAddress;
        public string HouseHoldAddress
        {
            get { return houseHoldAddress; }
            set { houseHoldAddress = value; }
        }
        private string department;
        public string Department
        {
            get { return department; }
            set { department = value; }
        }
        private string position;
        public string Position
        {
            get { return position; }
            set { position = value; }
        }

        private string bankAccount;
        public string BankAccount
        {
            get { return bankAccount; }
            set { bankAccount = value; }
        }

        private string openingBankName;
        public string OpeningBankName
        {
            get { return openingBankName; }
            set { openingBankName = value; }
        }

        private decimal trainingScore;
        public decimal TrainingScore
        {
            get { return trainingScore; }
            set { trainingScore = value; }
        }

        private DateTime trainingTime;
        public DateTime TrainingTime
        {
            get { return trainingTime; }
            set { trainingTime = value; }
        }

        private string trainingComment;
        public string TrainingComment
        {
            get { return trainingComment; }
            set { trainingComment = value; }
        }

        private int groupID;
        public int GroupID
        {
            get { return groupID; }
            set { groupID = value; }
        }

        private int companyID;
        public int CompanyID
        {
            get { return companyID; }
            set { companyID = value; }
        }

        private DateTime entryTime;
        public DateTime EntryTime
        {
            get { return entryTime; }
            set { entryTime = value; }
        }

        private int roleID;
        public int RoleID
        {
            get { return roleID; }
            set { roleID = value; }
        }

        private bool bHasProtocol;
        public bool BHasProtocol
        {
            get { return bHasProtocol; }
            set { bHasProtocol = value; }
        }

        private int protocolType;
        public int ProtocolType
        {
            get { return protocolType; }
            set { protocolType = value; }
        }

        private bool bHasExperience;
        public bool BHasExperience
        {
            get { return bHasExperience; }
            set { bHasExperience = value; }
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

        private int projectID;
        public int ProjectID
        {
            get { return projectID; }
            set { projectID = value; }
        }

        private int clientID;
        public int ClientID
        {
            get { return clientID; }
            set { clientID = value; }
        }

        private DateTime lastLoginTime;
        public DateTime LastLoginTime
        {
            get { return lastLoginTime; }
            set { lastLoginTime = value; }
        }

        private string lastLoginIP;
        public string LastLoginIP
        {
            get { return lastLoginIP; }
            set { lastLoginIP = value; }
        }

        private bool deleteFlag;
        public bool DeleteFlag
        {
            get { return deleteFlag; }
            set { deleteFlag = value; }
        }

        private DateTime deleteTime;
        public DateTime DeleteTime
        {
            get { return deleteTime; }
            set { deleteTime = value; }
        }

        public APUsersDO()
        {
            this.BO_Name = "APUsers";
            this.PK_Name = "ID";
        }
    }
}
