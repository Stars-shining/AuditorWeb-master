using System;
using System.Collections.Generic;

namespace APLibrary
{

    public class Constants
    {
        public static readonly DateTime Date_Max = new DateTime(2999, 1, 2);
        public static readonly DateTime Date_Min = new DateTime(1900, 1, 2);
        public static readonly DateTime Date_Null = new DateTime(1900, 1, 1);
        public static readonly Int32 AllValue = -999;
        public static readonly Int32 ThumbnailWidth = 200;
        public static readonly Int32 ThumbnailHeight = 200;
        public static readonly string InitialPassword = "1111";
        public static readonly string RelevantDocumentPath = "~/Upload/Documents/";
        public static readonly string RelevantTempPath = "~/Upload/Temp/";
        public static readonly string RelevantChunkTempPath = "~/Upload/ChunkTemp/";
        public static readonly string RelevantQRCodePath = "~/Upload/QRCode/";

        public static readonly string UserPhotoFolderName = "UserPhoto";
        public static readonly string SysLogoWithName = "~/Mobile/images/logo.jpg";
        public static readonly string SysLogoWithoutName = "~/Mobile/images/logo3.jpg";
        public static readonly string RelevantAudiencesDocumentPath = "~/Upload/Documents/Audiences/";
        public static readonly string RelevantExcutedDocumentPath = "~/Upload/Documents/Excuted/";
        public static readonly string RelevantFeedbackDocumentPath = "~/Upload/Documents/Feedbacks/";
        public static readonly string RelevantBaseDataDocumentPath = "~/Upload/Documents/BaseData/";
        public static readonly string RelevantScheduleDocumentPath = "~/Upload/Documents/Schedule/";
        public static readonly string RelevantQuestionnaireDocumentPath = "~/Upload/Documents/Questionnaires/";
        public static readonly string RelevantClientListDocumentPath = "~/Upload/Documents/ClientList/";
        public static readonly string RelevantEmployeeListDocumentPath = "~/Upload/Documents/EmployeeList/";
        public static readonly string RelevantTrainingDocumentPath = "~/Upload/Documents/Training/";

        public static readonly string RelevantFFmpegPath = "~/Templates/ffmpeg.exe";
        public static readonly string LoginRandCode = "LoginRandCode";
        public static readonly double MinDistance = 10;
        public static readonly int SystemUserID = -1;
        public static readonly string CurrentSiteUrl = "http://218.241.201.168:30008/";

        public class RowStyle
        {
            public const string RowUniqueID = "Row_Key";
            public const string RowStyleContent = "Row_Style";
        }
    }
}