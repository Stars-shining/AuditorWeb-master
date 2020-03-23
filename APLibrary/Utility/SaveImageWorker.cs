using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using APLibrary.DataObject;

namespace APLibrary.Utility
{
    public class SaveImageWorker
    {
        public SaveImageModel model;
        public SaveImageWorker(SaveImageModel s)
        {
            model = s;
        }
        public void SaveResultImageFileInstance()
        {
            string tempfilePath = model.tempfilePath;
            string physicalPath = model.physicalPath;
            string vituralPath = model.vituralPath;
            int projectID = model.projectID;
            int resultID = model.resultID;
            int questionID = model.questionID;
            int answerID = model.answerID;
            string fromDate = model.fromDate;
            string clientCode = model.clientCode;
            string formatFileName = model.formatFileName;
            int fileType = model.fileType;
            string watermark = model.watermark;
            int typeID = model.typeID;
            int userID = model.userID;
            string imageUrl = model.imageUrl;


            CommonFunction.DownloadFile(imageUrl, tempfilePath);
            formatFileName = CommonFunction.FixedSpecialCharsInFileName(formatFileName);

            string diskFolderPath = physicalPath.TrimEnd('\\') + "\\" + projectID + "\\" + fromDate + "\\" + clientCode + "\\" + fileType + "\\";
            if (Directory.Exists(diskFolderPath) == false)
            {
                Directory.CreateDirectory(diskFolderPath);
            }
            string diskFilePath = diskFolderPath + formatFileName;
            diskFilePath = CommonFunction.GetNewPathForDuplicates(diskFilePath);
            File.Copy(tempfilePath, diskFilePath);
            FileInfo file = new FileInfo(diskFilePath);
            long fileLength = file.Length;

            string webDirPath = vituralPath.TrimEnd('/') + "/" + projectID + "/" + fromDate + "/" + clientCode + "/" + fileType + "/";
            string fixedFileName = Path.GetFileName(diskFilePath);
            string webFilePath = webDirPath + fixedFileName;

            string thumbRelevantPath = string.Empty;
            string thumbPhysicalPath = string.Empty;
            string timeLength = string.Empty;
            string extension = Path.GetExtension(diskFilePath).ToLower();
            if (fileType == (int)Enums.FileType.图片)
            {
                if (fileLength > 0)
                {
                    if (string.IsNullOrEmpty(watermark) == false)
                    {
                        CommonFunction.AddImageSignText(diskFilePath, diskFilePath, watermark, 7, 100, 12);
                    }

                    thumbRelevantPath = CommonFunction.GetThumbPathForImageFile(webFilePath);
                    thumbPhysicalPath = CommonFunction.GetThumbPathForImageFile(diskFilePath);
                    CommonFunction.MakeThumbnail(diskFilePath, thumbPhysicalPath, Constants.ThumbnailWidth, Constants.ThumbnailHeight, "");
                }
            }

            string tempCode = resultID * 100 + " " + questionID * 100;

            DocumentFilesDO doc = new DocumentFilesDO();
            doc.FileName = formatFileName;
            doc.OriginalFileName = formatFileName;
            doc.TempCode = tempCode;
            doc.RelatedID = answerID;
            doc.ResultID = resultID;
            doc.TypeID = typeID;
            doc.FileSize = fileLength;
            doc.TimeLength = timeLength;
            doc.Status = (int)Enums.DocumentStatus.正常;
            doc.RelevantPath = webFilePath;
            doc.PhysicalPath = diskFilePath;
            doc.ThumbRelevantPath = thumbRelevantPath;
            doc.FileType = fileType;
            doc.UserID = userID;
            doc.InputDate = DateTime.Now;
            int docid = BusinessLogicBase.Default.Insert(doc);
        }
    }

    public class SaveImageModel
    {
        public string tempfilePath;
        public string physicalPath;
        public string vituralPath;
        public int projectID;
        public int resultID;
        public int questionID;
        public int answerID;
        public string fromDate;
        public string clientCode;
        public string formatFileName;
        public int fileType;
        public string watermark;
        public int typeID;
        public int userID;
        public string imageUrl;
    }
}
