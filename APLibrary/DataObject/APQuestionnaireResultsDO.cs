using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace APLibrary.DataObject
{

    public class APQuestionnaireResultsDO : DataObjectBase
    {
        private int iD;
        public int ID
        {
            get { return iD; }
            set { iD = value; }
        }

        private int deliveryID;
        public int DeliveryID
        {
            get { return deliveryID; }
            set { deliveryID = value; }
        }

        private int questionnaireID;
        public int QuestionnaireID
        {
            get { return questionnaireID; }
            set { questionnaireID = value; }
        }

        private int clientID;
        public int ClientID
        {
            get { return clientID; }
            set { clientID = value; }
        }

        private int projectID;
        public int ProjectID
        {
            get { return projectID; }
            set { projectID = value; }
        }

        private DateTime fromDate;
        public DateTime FromDate
        {
            get { return fromDate; }
            set { fromDate = value; }
        }

        private DateTime toDate;
        public DateTime ToDate
        {
            get { return toDate; }
            set { toDate = value; }
        }

        private decimal score;
        public decimal Score
        {
            get { return score; }
            set { score = value; }
        }

        private DateTime visitBeginTime;
        public DateTime VisitBeginTime
        {
            get { return visitBeginTime; }
            set { visitBeginTime = value; }
        }

        private DateTime visitEndTime;
        public DateTime VisitEndTime
        {
            get { return visitEndTime; }
            set { visitEndTime = value; }
        }

        private string videoPath;
        public string VideoPath
        {
            get { return videoPath; }
            set { videoPath = value; }
        }

        private string videoLength;
        public string VideoLength
        {
            get { return videoLength; }
            set { videoLength = value; }
        }

        private string description;
        public string Description
        {
            get { return description; }
            set { description = value; }
        }

        private int currentQuestionID;
        public int CurrentQuestionID
        {
            get { return currentQuestionID; }
            set { currentQuestionID = value; }
        }

        private decimal currentProgress;
        public decimal CurrentProgress
        {
            get { return currentProgress; }
            set { currentProgress = value; }
        }

        private DateTime uploadBeginTime;
        public DateTime UploadBeginTime
        {
            get { return uploadBeginTime; }
            set { uploadBeginTime = value; }
        }

        private DateTime uploadEndTime;
        public DateTime UploadEndTime
        {
            get { return uploadEndTime; }
            set { uploadEndTime = value; }
        }

        private bool bOverTime;
        public bool BOverTime
        {
            get { return bOverTime; }
            set { bOverTime = value; }
        }

        private int visitUserUploadStatus;
        public int VisitUserUploadStatus
        {
            get { return visitUserUploadStatus; }
            set { visitUserUploadStatus = value; }
        }

        private int visitUserID;
        public int VisitUserID
        {
            get { return visitUserID; }
            set { visitUserID = value; }
        }

        private int cityUserAuditStatus;
        public int CityUserAuditStatus
        {
            get { return cityUserAuditStatus; }
            set { cityUserAuditStatus = value; }
        }

        private DateTime cityUserAuditTime;
        public DateTime CityUserAuditTime
        {
            get { return cityUserAuditTime; }
            set { cityUserAuditTime = value; }
        }

        private int cityUserID;
        public int CityUserID
        {
            get { return cityUserID; }
            set { cityUserID = value; }
        }

        private int areaUserAuditStatus;
        public int AreaUserAuditStatus
        {
            get { return areaUserAuditStatus; }
            set { areaUserAuditStatus = value; }
        }

        private DateTime areaUserAuditTime;
        public DateTime AreaUserAuditTime
        {
            get { return areaUserAuditTime; }
            set { areaUserAuditTime = value; }
        }

        private int areaUserID;
        public int AreaUserID
        {
            get { return areaUserID; }
            set { areaUserID = value; }
        }

        private int qCUserAuditStatus;
        public int QCUserAuditStatus
        {
            get { return qCUserAuditStatus; }
            set { qCUserAuditStatus = value; }
        }

        private DateTime qCUserAuditTime;
        public DateTime QCUserAuditTime
        {
            get { return qCUserAuditTime; }
            set { qCUserAuditTime = value; }
        }

        private int qCUserID;
        public int QCUserID
        {
            get { return qCUserID; }
            set { qCUserID = value; }
        }

        private int qCLeaderAuditStatusFirst;
        public int QCLeaderAuditStatusFirst
        {
            get { return qCLeaderAuditStatusFirst; }
            set { qCLeaderAuditStatusFirst = value; }
        }

        private DateTime qCLeaderAuditTimeFirst;
        public DateTime QCLeaderAuditTimeFirst
        {
            get { return qCLeaderAuditTimeFirst; }
            set { qCLeaderAuditTimeFirst = value; }
        }

        private int qCLeaderUserIDFirst;
        public int QCLeaderUserIDFirst
        {
            get { return qCLeaderUserIDFirst; }
            set { qCLeaderUserIDFirst = value; }
        }

        private int clientUserAuditStatus;
        public int ClientUserAuditStatus
        {
            get { return clientUserAuditStatus; }
            set { clientUserAuditStatus = value; }
        }

        private DateTime clientUserAuditTime;
        public DateTime ClientUserAuditTime
        {
            get { return clientUserAuditTime; }
            set { clientUserAuditTime = value; }
        }

        private int clientUserID;
        public int ClientUserID
        {
            get { return clientUserID; }
            set { clientUserID = value; }
        }

        private int currentClientUserID;
        public int CurrentClientUserID
        {
            get { return currentClientUserID; }
            set { currentClientUserID = value; }
        }

        private int qCLeaderAuditStatus;
        public int QCLeaderAuditStatus
        {
            get { return qCLeaderAuditStatus; }
            set { qCLeaderAuditStatus = value; }
        }

        private int qCLeaderUserID;
        public int QCLeaderUserID
        {
            get { return qCLeaderUserID; }
            set { qCLeaderUserID = value; }
        }

        private DateTime qCLeaderAuditTime;
        public DateTime QCLeaderAuditTime
        {
            get { return qCLeaderAuditTime; }
            set { qCLeaderAuditTime = value; }
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

        private int reAuditStatus;
        public int ReAuditStatus
        {
            get { return reAuditStatus; }
            set { reAuditStatus = value; }
        }

        private int timePeriodID;
        public int TimePeriodID
        {
            get { return timePeriodID; }
            set { timePeriodID = value; }
        }
        private int timeLength;
        public int TimeLength
        {
            get { return timeLength; }
            set { timeLength = value; }
        }
        private int weekNum;
        public int WeekNum
        {
            get { return weekNum; }
            set { weekNum = value; }
        }
        private double locationX;
        public double LocationX
        {
            get { return locationX; }
            set { locationX = value; }
        }
        private double locationY;
        public double LocationY
        {
            get { return locationY; }
            set { locationY = value; }
        }

        private string otherPlatformID;
        public string OtherPlatformID {
            get { return otherPlatformID; }
            set { otherPlatformID = value; }
        }

        private string address;
        public string Address
        {
            get { return address; }
            set { address = value; }
        }

        private string lastAuditNote;
        public string LastAuditNote
        {
            get { return lastAuditNote; }
            set { lastAuditNote = value; }
        }

        private string questionnaireVersion;
        public string QuestionnaireVersion
        {
            get { return questionnaireVersion; }
            set { questionnaireVersion = value; }
        }

        public APQuestionnaireResultsDO()
        {
            this.BO_Name = "APQuestionnaireResults";
            this.PK_Name = "ID";
        }
    }
}
