<%@ WebHandler Language="C#" Class="Upload" %>

using System;
using System.Web;
using System.Data;
using System.Data.SqlClient;
using System.Collections.Generic;
using System.Net;
using System.Net.Mail;
using System.Text;
using System.Configuration;
using System.Web.SessionState;
using System.Text.RegularExpressions;
using APLibrary;
using APLibrary.DataObject;
using APLibrary.Utility;
using System.IO;

public class Upload : IHttpHandler, IRequiresSessionState
{
    public void ProcessRequest (HttpContext context) {
        if (string.IsNullOrEmpty(context.Request["type"]))
        {
            return;
        }
        try
        {
            int requestType = Convert.ToInt32(context.Request["type"]);
            switch (requestType)
            {
                case 1:
                    UploadImage();
                    break;
                case 2:
                    GetFiles();
                    break;
                case 3:
                    GetFileTypeName();
                    break;
                case 4:
                    DeleteFile();
                    break;
                case 5:
                    DownloadPicture();
                    break;
                case 6:
                    ShowPicture();
                    break;
                case 7:
                    UploadQuestions();
                    break;
                case 8:
                    GetFileTypeID();
                    break;
                case 9:
                    GetFileTypes();
                    break;
                case 10:
                    GetDeletedFiles();
                    break;
                case 11:
                    RecoverFile();
                    break;
                case 12:
                    DeleteFiles();
                    break;
                case 13:
                    UploadUserPhoto();
                    break;
                case 14:
                    UploadClientList();
                    break;
                case 15:
                    UploadEmployee();
                    break;
                case 16:
                    UploadQuestionnaireResultFiles();
                    break;
                case 17:
                    UploadQuestionnaireResultFilesOnce();
                    break;
                case 18:
                    UploadClientVideo();
                    break;
                default:
                    break;
            }
        }
        catch { }
    }

    public void UploadClientVideo() 
    {
        string resultID = HttpContext.Current.Request["resultID"];
        int _resultID = 0;
        int.TryParse(resultID, out _resultID);

        HttpPostedFile file = HttpContext.Current.Request.Files[0];
        string fileName = Path.GetFileName(file.FileName);
        string extension = Path.GetExtension(file.FileName).ToLower();
        int fileType = CommonFunction.GetFileType(fileName);

        APQuestionnaireResultsDO resultDO = APQuestionnaireManager.GetQuestionnaireResultDOByID(_resultID);
        string fromDate = resultDO.FromDate.ToString("yyyy-MM-dd");
        APClientsDO clientDO = APClientManager.GetClientDOByID(resultDO.ClientID);
        string clientCode = clientDO.Code;

        DirectoryMappingDO dmDO = DocumentManager.GetCurrentDirMappingDO();
        string physicalPath = dmDO.PhysicalPath;
        string vituralPath = dmDO.VituralPath;

        string originalName = fileName;
        int projectID = WebSiteContext.CurrentProjectID;
        if (projectID <= 0)
        {
            HttpContext.Current.Response.ContentType = "text/plain";
            HttpContext.Current.Response.Write("-1");
            return;
        }

        string diskFolderPath = physicalPath.TrimEnd('\\') + "\\" + projectID + "\\" + fromDate + "\\" + clientCode + "\\" + fileType + "\\";
        if (Directory.Exists(diskFolderPath) == false)
        {
            Directory.CreateDirectory(diskFolderPath);
        }
        string diskFilePath = diskFolderPath + originalName;
        diskFilePath = CommonFunction.GetNewPathForDuplicates(diskFilePath);
        file.SaveAs(diskFilePath);

        string webDirPath = vituralPath.TrimEnd('/') + "/" + projectID + "/" + fromDate + "/" + clientCode + "/" + fileType + "/";
        string fixedFileName = Path.GetFileName(diskFilePath);
        string webFilePath = webDirPath + fixedFileName;

        string thumbRelevantPath = string.Empty;
        string thumbPhysicalPath = string.Empty;
        string timeLength = string.Empty;
        if (fileType == (int)Enums.FileType.录像)
        {
            //视频缩略图
            thumbPhysicalPath = WebCommon.CatchVideoCoverImage(diskFilePath);
            string fixedThumbFileName = Path.GetFileName(thumbPhysicalPath);
            thumbRelevantPath = webDirPath + fixedThumbFileName;

            string videoCode = string.Empty;
            string audioCode = string.Empty;
            WebCommon.GetVideoInfo(diskFilePath, ref timeLength, ref videoCode, ref audioCode);
            if (extension != ".mp4" || videoCode != "h264" || audioCode != "aac")
            {
                string fixedDiskFilePath = WebCommon.GetVideoConvertedPath(diskFilePath);
                if (string.IsNullOrEmpty(fixedDiskFilePath) == false)
                {
                    File.Delete(diskFilePath);
                    diskFilePath = Path.ChangeExtension(diskFilePath, "mp4");
                    diskFilePath = CommonFunction.GetNewPathForDuplicates(diskFilePath);
                    fixedFileName = Path.GetFileName(diskFilePath);
                    webFilePath = webDirPath + fixedFileName;
                    File.Move(fixedDiskFilePath, diskFilePath);
                }
            }
        }
        else if (fileType == (int)Enums.FileType.录音)
        {
            string videoCode = string.Empty;
            string audioCode = string.Empty;
            WebCommon.GetVideoInfo(diskFilePath, ref timeLength, ref videoCode, ref audioCode);
            if (extension != ".mp3" || audioCode != "mp3")
            {
                string fixedDiskFilePath = WebCommon.GetAudioConvertedPath(diskFilePath);
                if (string.IsNullOrEmpty(fixedDiskFilePath) == false)
                {
                    File.Delete(diskFilePath);
                    diskFilePath = Path.ChangeExtension(diskFilePath, "mp3");
                    diskFilePath = CommonFunction.GetNewPathForDuplicates(diskFilePath);
                    fixedFileName = Path.GetFileName(diskFilePath);
                    webFilePath = webDirPath + fixedFileName;
                    File.Move(fixedDiskFilePath, diskFilePath);
                }

            }
        }
        resultDO.VideoPath = fixedFileName;
        if (string.IsNullOrEmpty(timeLength) == false)
        {
            resultDO.VideoLength = timeLength;
        }
        BusinessLogicBase.Default.Update(resultDO);

        DocumentFilesDO doc = DocumentManager.GetDOcumentFileDOByRelatedID(_resultID, (int)Enums.DocumentType.执行全程录像);
        if (doc == null) {
            doc = new DocumentFilesDO();
        }
        int docid = doc.ID;

        doc.FileName = fixedFileName;
        doc.OriginalFileName = originalName;
        doc.RelatedID = _resultID;
        doc.TypeID = (int)Enums.DocumentType.执行全程录像;
        doc.FileSize = file.ContentLength;
        doc.Status = (int)Enums.DocumentStatus.正常;
        doc.RelevantPath = webFilePath;
        doc.ThumbRelevantPath = thumbRelevantPath;
        doc.PhysicalPath = diskFilePath;
        doc.TimeLength = timeLength;
        doc.FileType = fileType;
        doc.UserID = WebSiteContext.CurrentUserID;
        doc.InputDate = DateTime.Now;
        if (doc.ID > 0)
        {
            BusinessLogicBase.Default.Update(doc);
        }
        else
        {
            docid = BusinessLogicBase.Default.Insert(doc);
        }
        string success = docid.ToString();
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(success);
    }

    public void UploadQuestionnaireResultFilesOnce() 
    {
        string typeID = HttpContext.Current.Request["typeID"];
        int _typeID = 0;
        int.TryParse(typeID, out _typeID);
        
        HttpPostedFile file = HttpContext.Current.Request.Files[0];
        string fileName = Path.GetFileName(file.FileName);
        string extension = Path.GetExtension(file.FileName);
        string result = "0";
        if (extension != ".zip")
        {
            result = "0无法处理非zip压缩文件";
            HttpContext.Current.Response.ContentType = "text/plain";
            HttpContext.Current.Response.Write(result);
            return;
        }
        string vituralPath = Constants.RelevantTempPath;
        string physicalPath = HttpContext.Current.Server.MapPath(vituralPath);
        string originalName = fileName;
        string name = fileName;
        string diskFolderPath = physicalPath.TrimEnd('\\') + "\\";
        if (Directory.Exists(diskFolderPath) == false)
        {
            Directory.CreateDirectory(diskFolderPath);
        }
        string diskFilePath = diskFolderPath + originalName;
        diskFilePath = CommonFunction.GetNewPathForDuplicates(diskFilePath);
        file.SaveAs(diskFilePath);

        string zipFolderPath = diskFilePath.Substring(0, diskFilePath.LastIndexOf('.'));
        ZipHelper zip = new ZipHelper();
        zip.UnZip(diskFilePath, zipFolderPath, "", true);
        if (!Directory.Exists(zipFolderPath))
        {
            result = "0文件包解压失败，请联系技术人员解决";
            HttpContext.Current.Response.ContentType = "text/plain";
            HttpContext.Current.Response.Write(result);
            return;
        }
        try
        {
            string folderName = originalName.Substring(0, originalName.LastIndexOf('.'));
            if (folderName.Contains("-") == false)
            {
                result = "0当前文件包命名格式不正确";
                HttpContext.Current.Response.ContentType = "text/plain";
                HttpContext.Current.Response.Write(result);
                return;
            }
            string strFromDate = folderName.Substring(0, folderName.IndexOf('-'));
            string questionnaireName = folderName.Substring(folderName.IndexOf('-') + 1);
            DateTime fromDate = Constants.Date_Null;
            try
            {
                fromDate = DateTime.ParseExact(strFromDate, "yyyyMMdd", System.Globalization.CultureInfo.CurrentCulture);
            }
            catch { }
            if (fromDate < Constants.Date_Min) 
            {
                result = "0当前文件包命名格式可能不正确，系统无法识别执行期次";
                HttpContext.Current.Response.ContentType = "text/plain";
                HttpContext.Current.Response.Write(result);
                return;
            }
            int projectID = WebSiteContext.CurrentProjectID;
            APQuestionnairesDO questionnaireDO = APQuestionnaireManager.GetQuestionnaireDOByName(projectID, questionnaireName);
            if (questionnaireDO == null || questionnaireDO.ID <= 0)
            {
                result = "0当前文件包命名格式可能不正确，系统无法识别执行问卷";
                HttpContext.Current.Response.ContentType = "text/plain";
                HttpContext.Current.Response.Write(result);
                return;
            }
            StringBuilder message = new StringBuilder();
            List<string> msgList = new List<string>();
            int questionnaireID = questionnaireDO.ID;
            string[] allfolders = Directory.GetDirectories(zipFolderPath);
            if (allfolders != null && allfolders.Length == 1)
            {
                string tempFolderPath = allfolders[0];
                string tempFolderName = tempFolderPath.Substring(tempFolderPath.LastIndexOf('\\') + 1);
                if (tempFolderName == folderName)
                {
                    allfolders = Directory.GetDirectories(tempFolderPath);
                }
            }
            if (allfolders != null && allfolders.Length > 0)
            {
                foreach (string subFolderPath in allfolders) 
                {
                    string subFolderName = subFolderPath.Substring(subFolderPath.LastIndexOf('\\') + 1);
                    string clientCode = subFolderName.Substring(0, subFolderName.IndexOf('-'));
                    string clientName = subFolderName.Substring(subFolderName.IndexOf('-') + 1);
                    APClientsDO clientDO = APClientManager.GetClientByCode(clientCode, projectID);
                    if (clientDO == null || clientDO.ID <= 0) 
                    {
                        msgList.Add("未识别的网点：" + subFolderName);
                        continue;
                    }
                    int clientID = clientDO.ID;
                    APQuestionnaireResultsDO resultDO = APQuestionnaireManager.GetQuestionnaireResultDO(questionnaireID, clientID, fromDate);
                    if (resultDO == null || resultDO.ID <= 0)
                    {
                        msgList.Add("未识别到该网点该期次有录入过问卷：" + subFolderName);
                        continue;
                    }
                    SaveResultFile(subFolderPath, resultDO.ID, _typeID, ref msgList);
                }
                if (msgList.Count > 0)
                {
                    foreach (string msg in msgList) 
                    {
                        message.AppendLine(msg);
                        message.AppendLine("<br/>");
                    }
                }
            }
            
            if (Directory.Exists(zipFolderPath))
            {
                Directory.Delete(zipFolderPath, true);
            }
            result = "1" + message.ToString();
            HttpContext.Current.Response.ContentType = "text/plain";
            HttpContext.Current.Response.Write(result);
        }
        catch (Exception ex)
        {
            result = "0" + ex.ToString();
            HttpContext.Current.Response.ContentType = "text/plain";
            HttpContext.Current.Response.Write(result);
        }
    }

    public void UploadQuestionnaireResultFiles()
    {
        HttpPostedFile file = HttpContext.Current.Request.Files[0];
        string resultID = HttpContext.Current.Request["resultID"];
        string typeID = HttpContext.Current.Request["typeID"];

        int _resultID = 0;
        int.TryParse(resultID, out _resultID);
        int _typeID = 0;
        int.TryParse(typeID, out _typeID);
        string result = "0";
        string fileName = Path.GetFileName(file.FileName);
        string extension = Path.GetExtension(file.FileName);
        if (extension != ".zip")
        {
            result = "0无法处理非zip压缩文件";
            HttpContext.Current.Response.ContentType = "text/plain";
            HttpContext.Current.Response.Write(result);
            return;
        }
        string vituralPath = Constants.RelevantTempPath;
        string physicalPath = HttpContext.Current.Server.MapPath(vituralPath);
        string originalName = fileName;
        string name = fileName;
        string diskFolderPath = physicalPath.TrimEnd('\\') + "\\";
        if (Directory.Exists(diskFolderPath) == false)
        {
            Directory.CreateDirectory(diskFolderPath);
        }
        string diskFilePath = diskFolderPath + originalName;
        diskFilePath = CommonFunction.GetNewPathForDuplicates(diskFilePath);
        file.SaveAs(diskFilePath);

        string zipFolderPath = diskFilePath.Substring(0, diskFilePath.LastIndexOf('.'));
        ZipHelper zip = new ZipHelper();
        zip.UnZip(diskFilePath, zipFolderPath, "", true);
        if (!Directory.Exists(zipFolderPath))
        {
            result = "0文件包解压失败，请联系技术人员解决";
            HttpContext.Current.Response.ContentType = "text/plain";
            HttpContext.Current.Response.Write(result);
            return;
        }
        try
        {
            List<string> msgList = new List<string>();
            SaveResultFile(zipFolderPath, _resultID, _typeID, ref msgList);
            if (Directory.Exists(zipFolderPath))
            {
                Directory.Delete(zipFolderPath, true);
            }
            StringBuilder message = new StringBuilder();
            if (msgList.Count > 0)
            {
                foreach (string msg in msgList)
                {
                    message.AppendLine(msg);
                    message.AppendLine("<br/>");
                }
            }
            result = "1" + message.ToString();
            HttpContext.Current.Response.ContentType = "text/plain";
            HttpContext.Current.Response.Write(result);
        }
        catch (Exception ex)
        {
            result = "0" + ex.ToString();
            HttpContext.Current.Response.ContentType = "text/plain";
            HttpContext.Current.Response.Write(result);
        }
    }

    public void SaveResultFile(string folerPath, int resultID, int typeID, ref List<string> msgList)
    {
        string[] allfiles = Directory.GetFiles(folerPath);
        if (allfiles != null && allfiles.Length > 0)
        {
            DirectoryMappingDO dmDO = DocumentManager.GetCurrentDirMappingDO();
            string physicalPath = dmDO.PhysicalPath;
            string vituralPath = dmDO.VituralPath;
            int projectID = WebSiteContext.CurrentProjectID;

            APQuestionnaireResultsDO resultDO = APQuestionnaireManager.GetQuestionnaireResultDOByID(resultID);
            string strDate = resultDO.FromDate.ToString("yyyy-MM-dd");
            
            foreach (string filePath in allfiles)
            {
                string fileName = Path.GetFileName(filePath);
                int fileType = CommonFunction.GetFileType(fileName);
                string originalName = fileName;
                string[] strParts = originalName.Split('-');
                if (strParts.Length < 4)
                {
                    msgList.Add("未识别的文件：" + fileName);
                    continue;
                }
                string clientCode = strParts[0];
                string clientName = strParts[1];
                string questionCode = strParts[2];
                

                string diskFolderPath = physicalPath.TrimEnd('\\') + "\\" + projectID + "\\" + strDate + "\\" + clientCode + "\\" + fileType + "\\";
                
                int questionID = APQuestionManager.GetQuestionIDByCode(resultID, questionCode);
                APAnswersDO ado = APQuestionManager.GetAnwserDO(resultID, questionID);
                int relatedID = 0;
                if (ado != null && ado.ID > 0)
                {
                    relatedID = ado.ID;
                }
                try
                {
                    if (Directory.Exists(diskFolderPath) == false)
                    {
                        Directory.CreateDirectory(diskFolderPath);
                    }
                    string diskFilePath = diskFolderPath + originalName;
                    diskFilePath = CommonFunction.GetNewPathForDuplicates(diskFilePath);
                    string realName = Path.GetFileName(diskFilePath);
                    if (File.Exists(diskFilePath))
                    {
                        msgList.Add("已存在的文件：" + fileName);
                    }
                    else
                    {
                        File.Copy(filePath, diskFilePath, false);
                    }

                    FileInfo file = new FileInfo(diskFilePath);
                    decimal fileSize = file.Length;

                    string webDirPath = vituralPath.TrimEnd('/') + "/" + projectID + "/" + strDate + "/" + clientCode + "/" + fileType + "/";
                    string fixedFileName = Path.GetFileName(diskFilePath);
                    string webFilePath = webDirPath + fixedFileName;

                    string tempCode = resultID * 100 + " " + questionID * 100;

                    string thumbRelevantPath = string.Empty;
                    string thumbPhysicalPath = string.Empty;
                    string timeLength = string.Empty;
                    string extension = Path.GetExtension(diskFilePath).ToLower();
                    if (fileType == (int)Enums.FileType.图片)
                    {
                        thumbRelevantPath = CommonFunction.GetThumbPathForImageFile(webFilePath);
                        thumbPhysicalPath = CommonFunction.GetThumbPathForImageFile(diskFilePath);
                        WebCommon.MakeThumbnail(diskFilePath, thumbPhysicalPath, Constants.ThumbnailWidth, Constants.ThumbnailHeight, "");
                    }
                    else if (fileType == (int)Enums.FileType.录音)
                    {
                        string videoCode = string.Empty;
                        string audioCode = string.Empty;
                        WebCommon.GetVideoInfo(diskFilePath, ref timeLength, ref videoCode, ref audioCode);
                        if (extension != ".mp3" || audioCode != "mp3")
                        {
                            string fixedDiskFilePath = WebCommon.GetAudioConvertedPath(diskFilePath);
                            if (string.IsNullOrEmpty(fixedDiskFilePath) == false)
                            {
                                File.Delete(diskFilePath);
                                diskFilePath = Path.ChangeExtension(diskFilePath, "mp3");
                                diskFilePath = CommonFunction.GetNewPathForDuplicates(diskFilePath);
                                fixedFileName = Path.GetFileName(diskFilePath);
                                webFilePath = webDirPath + fixedFileName;
                                File.Move(fixedDiskFilePath, diskFilePath);
                            }

                        }
                    }
                    if (fileType == (int)Enums.FileType.录像)
                    {
                        //视频缩略图
                        thumbPhysicalPath = WebCommon.CatchVideoCoverImage(diskFilePath);
                        string fixedThumbFileName = Path.GetFileName(thumbPhysicalPath);
                        thumbRelevantPath = webDirPath + fixedThumbFileName;

                        string videoCode = string.Empty;
                        string audioCode = string.Empty;
                        WebCommon.GetVideoInfo(diskFilePath, ref timeLength, ref videoCode, ref audioCode);
                        if (extension != ".mp4" || videoCode != "h264" || audioCode != "aac")
                        {
                            string fixedDiskFilePath = WebCommon.GetVideoConvertedPath(diskFilePath);
                            if (string.IsNullOrEmpty(fixedDiskFilePath) == false)
                            {
                                File.Delete(diskFilePath);
                                diskFilePath = Path.ChangeExtension(diskFilePath, "mp4");
                                diskFilePath = CommonFunction.GetNewPathForDuplicates(diskFilePath);
                                fixedFileName = Path.GetFileName(diskFilePath);
                                webFilePath = webDirPath + fixedFileName;
                                File.Move(fixedDiskFilePath, diskFilePath);
                            }
                        }
                    }
                    
                    DocumentFilesDO doc = new DocumentFilesDO();
                    doc.FileName = fixedFileName;
                    doc.OriginalFileName = originalName;
                    doc.TempCode = tempCode;
                    doc.RelatedID = relatedID;
                    doc.TypeID = typeID;
                    doc.FileSize = fileSize;
                    doc.Status = (int)Enums.DocumentStatus.正常;
                    doc.RelevantPath = webFilePath;
                    doc.PhysicalPath = diskFilePath;
                    doc.ThumbRelevantPath = thumbRelevantPath;
                    doc.TimeLength = timeLength;
                    doc.FileType = fileType;
                    doc.UserID = WebSiteContext.CurrentUserID;
                    doc.InputDate = DateTime.Now;
                    int docid = BusinessLogicBase.Default.Insert(doc);
                }
                catch (Exception ex) 
                {
                    msgList.Add("文件写入异常：" + fileName + "，异常信息：" + ex.ToString());
                }
            }
        }
    }

    public void UploadEmployee()
    {
        HttpPostedFile file = HttpContext.Current.Request.Files[0];

        string vituralPath = Constants.RelevantEmployeeListDocumentPath;
        string physicalPath = HttpContext.Current.Server.MapPath(vituralPath);

        string fileName = Path.GetFileName(file.FileName);
        string extension = Path.GetExtension(file.FileName);
        if (extension != ".xlsx" && extension != ".xls" && extension != ".zip")
        {
            HttpContext.Current.Response.ContentType = "text/plain";
            HttpContext.Current.Response.Write("0");
            return;
        }
        string originalName = fileName;
        string name = fileName;
        string diskFolderPath = physicalPath.TrimEnd('\\') + "\\";
        if (Directory.Exists(diskFolderPath) == false)
        {
            Directory.CreateDirectory(diskFolderPath);
        }
        string diskFilePath = diskFolderPath + originalName;
        diskFilePath = CommonFunction.GetNewPathForDuplicates(diskFilePath);
        file.SaveAs(diskFilePath);

        string webDirPath = vituralPath.TrimEnd('/') + "/";
        string fixedFileName = Path.GetFileName(diskFilePath);
        string webFilePath = webDirPath + fixedFileName;
        string success = "0";
        if (extension == ".zip")
        {
            string zipFolderPath = diskFilePath.Substring(0, diskFilePath.LastIndexOf('.'));
            ZipHelper zip = new ZipHelper();
            zip.UnZip(diskFilePath, zipFolderPath, "", true);
            if (!Directory.Exists(zipFolderPath))
            {
                HttpContext.Current.Response.ContentType = "text/plain";
                HttpContext.Current.Response.Write("2");
                return;
            }
            DocumentFilesDO doc = new DocumentFilesDO();
            doc.FileName = name;
            doc.OriginalFileName = originalName;
            doc.RelatedID = -1;
            doc.TypeID = (int)Enums.DocumentType.用户上传;
            doc.FileSize = file.ContentLength;
            doc.RelevantPath = webFilePath;
            doc.PhysicalPath = diskFilePath;
            doc.FileType = (int)Enums.FileType.其他;
            doc.Status = (int)Enums.DocumentStatus.正常;
            doc.UserID = WebSiteContext.CurrentUserID;
            doc.InputDate = DateTime.Now;
            BusinessLogicBase.Default.Insert(doc);

            try
            {
                SaveEmployeePhoto(zipFolderPath);
                if (Directory.Exists(zipFolderPath))
                {
                    Directory.Delete(zipFolderPath, true);
                }
                success = "1";
            }
            catch
            {
                success = "0";
            }
        }
        else
        {
            DocumentFilesDO doc = new DocumentFilesDO();
            doc.FileName = name;
            doc.OriginalFileName = originalName;
            doc.RelatedID = -1;
            doc.TypeID = (int)Enums.DocumentType.用户上传;
            doc.FileSize = file.ContentLength;
            doc.RelevantPath = webFilePath;
            doc.PhysicalPath = diskFilePath;
            doc.FileType = (int)Enums.FileType.文档;
            doc.Status = (int)Enums.DocumentStatus.正常;
            doc.UserID = WebSiteContext.CurrentUserID;
            doc.InputDate = DateTime.Now;
            int docid = BusinessLogicBase.Default.Insert(doc);

            try
            {
                ReadEmployeeList(diskFilePath);
                success = "1";
            }
            catch
            {
                success = "0";
            }
        }
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(success);
    }

    public void SaveEmployeePhoto(string folerPath)
    {
        string[] allfiles = Directory.GetFiles(folerPath);
        if (allfiles != null && allfiles.Length > 0)
        {
            DirectoryMappingDO dmDO = DocumentManager.GetCurrentDirMappingDO();
            string physicalPath = dmDO.PhysicalPath;
            string vituralPath = dmDO.VituralPath;

            foreach (string filePath in allfiles)
            {
                string fileName = Path.GetFileName(filePath);
                string folderName = Constants.UserPhotoFolderName;
                string timestamp = DateTime.Now.Year.ToString();
                string originalName = fileName;
                string diskFolderPath = physicalPath.TrimEnd('\\') + "\\" + folderName + "\\" + timestamp + "\\";
                if (Directory.Exists(diskFolderPath) == false)
                {
                    Directory.CreateDirectory(diskFolderPath);
                }
                string diskFilePath = diskFolderPath + originalName;
                diskFilePath = CommonFunction.GetNewPathForDuplicates(diskFilePath);
                string realName = Path.GetFileName(diskFilePath);

                File.Copy(filePath, diskFilePath, true);

                string webDirPath = vituralPath.TrimEnd('/') + "/" + folderName + "/" + timestamp + "/" + realName;

                string name = Path.GetFileNameWithoutExtension(filePath);
                APUsersDO userDO = APUserManager.GetUserDOByLoginName(name);
                if (userDO != null && userDO.ID > 0)
                {
                    userDO.PhotoPath = webDirPath;
                    BusinessLogicBase.Default.Update(userDO);
                }
            }
        }
    }

    public void ReadEmployeeList(string filePath)
    {
        DataSet ds = ParseExcel.GetDataSetFromExcelFile(filePath);
        if (ds == null || ds.Tables.Count <= 0)
        {
            return;
        }
        DataTable dt = ds.Tables["人员列表$"];
        if (dt == null || dt.Rows.Count <= 0)
        {
            return;
        }
        for (int i = 0; i < dt.Rows.Count; i++)
        {
            DataRow row = dt.Rows[i];
            string loginName = row["登录账号"].ToString();
            string userName = row["姓名"].ToString();
            string roleName = row["角色类型"].ToString();
            string email = row["电子邮箱"].ToString();
            string groupName = row["所属组别"].ToString();
            string status = row["账号状态"].ToString();
            string area = row["区域"].ToString();
            string province = row["省份"].ToString();
            string city = row["城市"].ToString();
            string district = row["区县"].ToString();
            string sex = row["性别"].ToString();
            string degree = row["学历"].ToString();
            string birthday = row["出生日期"].ToString();
            string region = row["民族"].ToString();

            string houseHoldRegistration = row["户口性质"].ToString();
            string houseHoldAddress = row["户口地址"].ToString();
            string address = row["常住地址"].ToString();
            string idCardNumber = row["身份证号码"].ToString();
            string postCode = row["邮政编码"].ToString();
            string department = row["所属部门"].ToString();
            string position = row["公司职位"].ToString();
            string telephoneNumber = row["固定电话"].ToString();
            string mobilePhone = row["手机号码"].ToString();
            string bHasExperience = row["有无经验"].ToString();
            string bHasProtocol = row["有无协议"].ToString();
            string protocolType = row["协议类型"].ToString();
            string entryTime = row["入职日期"].ToString();
            string trainingTime = row["培训日期"].ToString();
            string trainingScore = row["培训得分"].ToString();
            string trainingComment = row["培训评语"].ToString();
            string openingBankName = row["开户行名称"].ToString();
            string bankAccount = row["银行账号"].ToString();


            if (!string.IsNullOrEmpty(loginName) && !string.IsNullOrEmpty(userName))
            {
                bool bExisting = APUserManager.CheckLoginNameExisting(loginName, -1);
                if (bExisting)
                {
                    continue;
                }

                int roleID = APUserManager.GetUserRoleIDByRoleName(roleName);
                if (roleID <= 0)
                {
                    continue;
                }

                int statusID = BusinessConfigurationManager.GetItemKeyByItemValue(status, "UserStatus");
                int areaID = BusinessConfigurationManager.GetItemKeyByItemValue(area, "AreaDivision");

                string provinceCode = APClientManager.GetCityCodeByName(province, 1);
                string cityCode = APClientManager.GetCityCodeByName(city, 2);
                string districtCode = APClientManager.GetCityCodeByName(district, 3);

                int sexID = BusinessConfigurationManager.GetItemKeyByItemValue(sex, "Sex");
                int degreeID = BusinessConfigurationManager.GetItemKeyByItemValue(degree, "Degree");
                int houseHoldID = BusinessConfigurationManager.GetItemKeyByItemValue(houseHoldRegistration, "HouseHold");
                int protocolTypeID = BusinessConfigurationManager.GetItemKeyByItemValue(protocolType, "ProtocolType");
                int regionID = BusinessConfigurationManager.GetItemKeyByItemValue(region, "Region");

                DateTime dateOfBirth = Constants.Date_Null;
                DateTime entryDate = Constants.Date_Null;
                DateTime trainingDate = Constants.Date_Null;
                DateTime.TryParse(birthday, out dateOfBirth);
                DateTime.TryParse(entryTime, out entryDate);
                DateTime.TryParse(trainingTime, out trainingDate);

                bool _bHasExperience = false;
                bool _bHasProtocol = false;
                bool.TryParse(bHasExperience, out _bHasExperience);
                bool.TryParse(bHasProtocol, out _bHasProtocol);

                string initialPassword = Constants.InitialPassword;
                if (!string.IsNullOrEmpty(idCardNumber) && idCardNumber.Length > 6)
                {
                    initialPassword = idCardNumber.Substring(idCardNumber.Length - 6);
                }
                decimal _trainingScore = 0;
                decimal.TryParse(trainingScore, out _trainingScore);

                APUsersDO clientUser = new APUsersDO();
                clientUser.RoleID = roleID;
                clientUser.LoginName = loginName;
                clientUser.UserName = userName;
                clientUser.Password = initialPassword;
                clientUser.Status = statusID;
                clientUser.CreateTime = DateTime.Now;
                clientUser.CreateUserID = WebSiteContext.CurrentUserID;

                clientUser.Sex = sexID;
                clientUser.Degree = degreeID;
                clientUser.DateOfBirth = dateOfBirth;
                clientUser.Region = regionID;
                clientUser.BHasExperience = _bHasExperience;
                clientUser.BHasProtocol = _bHasProtocol;
                clientUser.ProtocolType = protocolTypeID;
                clientUser.EntryTime = entryDate;
                clientUser.Position = position;
                clientUser.Department = department;
                clientUser.GroupID = 0;
                clientUser.HouseHoldRegistration = houseHoldID;
                clientUser.HouseHoldAddress = houseHoldAddress;
                clientUser.BankAccount = bankAccount;
                clientUser.OpeningBankName = openingBankName;
                clientUser.IDCardNumber = idCardNumber;

                clientUser.AreaID = areaID;
                clientUser.Province = provinceCode;
                clientUser.City = cityCode;
                clientUser.District = districtCode;
                clientUser.Address = address;
                clientUser.Email = email;
                clientUser.Postcode = postCode;
                clientUser.Telephone = telephoneNumber;
                clientUser.MobilePhone = mobilePhone;
                clientUser.TrainingTime = trainingDate;
                clientUser.TrainingComment = trainingComment;
                clientUser.TrainingScore = _trainingScore;
                BusinessLogicBase.Default.Insert(clientUser);
            }
        }
    }

    public void UploadClientList()
    {
        HttpPostedFile file = HttpContext.Current.Request.Files[0];

        string vituralPath = Constants.RelevantClientListDocumentPath;
        string physicalPath = HttpContext.Current.Server.MapPath(vituralPath);

        string fileName = Path.GetFileName(file.FileName);
        string originalName = fileName;
        string name = fileName;
        string diskFolderPath = physicalPath.TrimEnd('\\') + "\\";
        if (Directory.Exists(diskFolderPath) == false)
        {
            Directory.CreateDirectory(diskFolderPath);
        }
        string diskFilePath = diskFolderPath + originalName;
        diskFilePath = CommonFunction.GetNewPathForDuplicates(diskFilePath);
        file.SaveAs(diskFilePath);

        string webDirPath = vituralPath.TrimEnd('/') + "/";
        string fixedFileName = Path.GetFileName(diskFilePath);
        string webFilePath = webDirPath + fixedFileName;

        int projectID = WebSiteContext.CurrentProjectID;

        DocumentFilesDO doc = new DocumentFilesDO();
        doc.FileName = name;
        doc.OriginalFileName = originalName;
        doc.RelatedID = projectID;
        doc.TypeID = (int)Enums.DocumentType.客户列表;
        doc.FileSize = file.ContentLength;
        doc.RelevantPath = webFilePath;
        doc.PhysicalPath = diskFilePath;
        doc.FileType = (int)Enums.FileType.文档;
        doc.Status = (int)Enums.DocumentStatus.正常;
        doc.UserID = WebSiteContext.CurrentUserID;
        doc.InputDate = DateTime.Now;
        int docid = BusinessLogicBase.Default.Insert(doc);

        string success = "0";
        try
        {
            ReadClientList(diskFilePath, projectID);
            success = "1";
        }
        catch
        {
            success = "0";
        }
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(success);
    }

    public void ReadClientList(string filePath, int projectID)
    {
        DataSet ds = ParseExcel.GetDataSetFromExcelFile(filePath);
        if (ds == null || ds.Tables.Count <= 0)
        {
            return;
        }
        DataTable dt = ds.Tables["网点信息$"];
        if (dt == null || dt.Rows.Count <= 0)
        {
            return;
        }
        for (int i = 0; i < dt.Rows.Count; i++)
        {
            DataRow row = dt.Rows[i];
            string code = row["机构编号"].ToString();
            string levelCode = row["层级编号"].ToString();
            string parentCode = row["上级编号"].ToString();
            string name = row["机构名称"].ToString();
            string address = row["机构地址"].ToString();
            string province = row["省份"].ToString();
            string provinceCode = row["省份代码"].ToString();
            string city = row["城市"].ToString();
            string cityCode = row["城市代码"].ToString();
            string district = row["区县"].ToString();
            string districtCode = row["区县代码"].ToString();
            string openingtime = row["营业时间"].ToString();
            string contactNumber = row["联系电话"].ToString();
            string postcode = row["邮政编码"].ToString();
            string email = row["电子邮箱"].ToString();
            string description = row["备注"].ToString();

            if (!string.IsNullOrEmpty(code))
            {
                APClientsDO existingDO = APClientManager.GetClientByCode(code, projectID);
                if (existingDO != null && existingDO.ID > 0)
                {
                    continue;
                }

                int levelID = 0;
                int.TryParse(levelCode, out levelID);

                int parentID = 0;
                if (string.IsNullOrEmpty(parentCode) == false)
                {
                    APClientsDO parentClientDO = APClientManager.GetClientByCode(parentCode, projectID);
                    if (parentClientDO != null && parentClientDO.ID > 0)
                    {
                        parentID = parentClientDO.ID;
                    }
                }

                if (string.IsNullOrEmpty(provinceCode) == true && string.IsNullOrEmpty(province) == false)
                {
                    provinceCode = APClientManager.GetCityCodeByName(province, 1);
                }
                if (string.IsNullOrEmpty(cityCode) == true && string.IsNullOrEmpty(city) == false)
                {
                    cityCode = APClientManager.GetCityCodeByName(city, 2);
                }
                if (string.IsNullOrEmpty(districtCode) == true && string.IsNullOrEmpty(district) == false)
                {
                    districtCode = APClientManager.GetCityCodeByName(district, 3);
                }

                APClientsDO cdo = new APClientsDO();
                cdo.Name = name;
                cdo.LevelID = levelID;
                cdo.Code = code;
                cdo.ProjectID = projectID;
                cdo.Status = (int)Enums.ClientStatus.正常;
                cdo.ParentID = parentID;
                cdo.Province = provinceCode;
                cdo.City = cityCode;
                cdo.District = districtCode;
                cdo.Address = address;

                cdo.OpeningTime = openingtime;
                cdo.PhoneNumber = contactNumber;
                cdo.Postcode = postcode;
                cdo.Email = email;
                cdo.Description = description;
                
                cdo.CreateTime = DateTime.Now;
                cdo.CreateUserID = WebSiteContext.CurrentUserID;
                int clientID = BusinessLogicBase.Default.Insert(cdo);

                APUsersDO clientUser = new APUsersDO();
                clientUser.ClientID = clientID;
                clientUser.ProjectID = projectID;
                clientUser.RoleID = (int)Enums.UserType.客户;
                clientUser.LoginName = code;
                clientUser.UserName = name;
                clientUser.Password = code;
                clientUser.CreateTime = DateTime.Now;
                clientUser.CreateUserID = WebSiteContext.CurrentUserID;
                clientUser.Province = provinceCode;
                clientUser.City = cityCode;
                clientUser.District = districtCode;
                clientUser.Address = address;
                clientUser.Email = email;
                clientUser.Postcode = postcode;
                clientUser.Telephone = contactNumber;
                BusinessLogicBase.Default.Insert(clientUser);
            }
        }
    }

    public void GetFileTypes()
    {
        string filterTypes = HttpContext.Current.Request.QueryString["filterTypes"];
        DataTable dt = BusinessConfigurationManager.GetDictListByDesc("FileType");
        if (string.IsNullOrEmpty(filterTypes) == false)
        {
            filterTypes = filterTypes.Replace('|', ',');
            DataView dv = dt.DefaultView;
            dv.RowFilter = "ID in (" + filterTypes + ")";
            dt = dv.ToTable();
        }
        string jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void UploadQuestions()
    {
        HttpPostedFile file = HttpContext.Current.Request.Files[0];
        string qid = HttpContext.Current.Request["qid"];
        int questionnaireID = 0;
        int.TryParse(qid, out questionnaireID);

        string vituralPath = Constants.RelevantQuestionnaireDocumentPath;
        string physicalPath = HttpContext.Current.Server.MapPath(vituralPath);

        string fileName = Path.GetFileName(file.FileName);
        string originalName = fileName;
        string name = fileName;
        string diskFolderPath = physicalPath.TrimEnd('\\') + "\\";
        if (Directory.Exists(diskFolderPath) == false)
        {
            Directory.CreateDirectory(diskFolderPath);
        }
        string diskFilePath = diskFolderPath + originalName;
        diskFilePath = CommonFunction.GetNewPathForDuplicates(diskFilePath);
        file.SaveAs(diskFilePath);

        string webDirPath = vituralPath.TrimEnd('/') + "/";
        string fixedFileName = Path.GetFileName(diskFilePath);
        string webFilePath = webDirPath + fixedFileName;

        DocumentFilesDO doc = new DocumentFilesDO();
        doc.FileName = name;
        doc.OriginalFileName = originalName;
        doc.RelatedID = 0;
        doc.TypeID = (int)Enums.DocumentType.问卷模板;
        doc.FileSize = file.ContentLength;
        doc.RelevantPath = webFilePath;
        doc.PhysicalPath = diskFilePath;
        doc.FileType = (int)Enums.FileType.文档;
        doc.Status = (int)Enums.DocumentStatus.正常;
        doc.UserID = WebSiteContext.CurrentUserID;
        doc.InputDate = DateTime.Now;
        int docid = BusinessLogicBase.Default.Insert(doc);

        string success = "0";
        try
        {
            ReadQuestions(diskFilePath, questionnaireID);
            success = "1";
        }
        catch
        {
            success = "0";
        }
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(success);
    }

    private void ReadQuestions(string filePath, int questionnaireID)
    {
        DataSet ds = ParseExcel.GetDataSetFromExcelFile(filePath);
        if (ds == null || ds.Tables.Count <= 0)
        {
            return;
        }
        DataTable dt = ds.Tables["问卷模板$"];
        if (dt == null || dt.Rows.Count <= 0)
        {
            return;
        }
        int currentQuestionID = 0;
        for (int i = 0; i < dt.Rows.Count; i++)
        {
            DataRow row =dt.Rows[i];
            string questionType = row["题型"].ToString();
            string parentCode = row["父编号"].ToString();
            string code = row["题号"].ToString();
            string title = row["题目正文"].ToString();
            string totalScore = row["题目分值"].ToString();
            string strCountType = row["计分方式"].ToString();
            string strAllowImage = row["允许照片"].ToString();
            string strMustImage = row["必须照片"].ToString();
            string strAllowAudio = row["允许录音"].ToString();
            string strMustAudio = row["必须录音"].ToString();
            string strAllowVideo = row["允许录像"].ToString();
            string strMustVideo = row["必须录像"].ToString();
            if (!string.IsNullOrEmpty(questionType))
            {
                int questionTypeID = BusinessConfigurationManager.GetItemKeyByItemValue(questionType, "QuestionType");
                decimal score = 0;
                decimal.TryParse(totalScore, out score);
                int countType = BusinessConfigurationManager.GetItemKeyByItemValue(strCountType, "CountType");

                APQuestionsDO qdo = new APQuestionsDO();
                qdo.QuestionType = questionTypeID;
                qdo.Title = title;
                qdo.Code = code;
                qdo.ParentCode = parentCode;
                qdo.QuestionnaireID = questionnaireID;
                qdo.Status = 1;
                qdo.TotalScore = score;
                qdo.CountType = countType;

                qdo.BAllowAudio = strAllowAudio == "是";
                qdo.BAllowImage = strAllowImage == "是";
                qdo.BAllowVideo = strAllowVideo == "是";
                qdo.BMustAudio = strMustAudio == "是";
                qdo.BMustImage = strMustImage == "是";
                qdo.BMustVideo = strMustVideo == "是";

                qdo.CreateTime = DateTime.Now;
                qdo.CreateUserID = WebSiteContext.CurrentUserID;
                currentQuestionID = BusinessLogicBase.Default.Insert(qdo);
            }

            string optionTitle = row["选项"].ToString();
            string strOptionType = row["选项类型"].ToString();
            if (!string.IsNullOrEmpty(optionTitle) && !string.IsNullOrEmpty(strOptionType))
            {
                string strOptionScore = row["选项分值"].ToString();
                string strJumpQuestionCode = row["跳转题号"].ToString();
                string strAllowText = row["允许填空"].ToString();
                string strOptionMustImage = row["选项必须照片"].ToString();
                bool bAllowText = strAllowText == "是";
                bool bCorrectOption = strOptionType == "得分项";
                decimal optionScore = 0;
                decimal.TryParse(strOptionScore, out optionScore);
                APOptionsDO optionDO = new APOptionsDO();
                optionDO.Title = optionTitle;
                optionDO.QuestionID = currentQuestionID;
                optionDO.Score = optionScore;
                optionDO.JumpQuestionCode = strJumpQuestionCode;
                optionDO.BAllowText = bAllowText;
                optionDO.BCorrectOption = bCorrectOption;
                optionDO.BMustImage = strOptionMustImage == "是";
                BusinessLogicBase.Default.Insert(optionDO);
            }
        }
    }

    /// <summary>
    /// get config value by key name 
    /// </summary>
    public void UploadUserPhoto()
    {
        HttpPostedFile file = HttpContext.Current.Request.Files[0];
        DirectoryMappingDO dmDO = DocumentManager.GetCurrentDirMappingDO();
        string physicalPath = dmDO.PhysicalPath;
        string vituralPath = dmDO.VituralPath;

        string fileName = Path.GetFileName(file.FileName);
        string folderName = Constants.UserPhotoFolderName;
        string timestamp = DateTime.Now.Year.ToString();
        string originalName = fileName;
        string diskFolderPath = physicalPath.TrimEnd('\\') + "\\" + folderName + "\\" + timestamp + "\\";
        if (Directory.Exists(diskFolderPath) == false)
        {
            Directory.CreateDirectory(diskFolderPath);
        }
        string diskFilePath = diskFolderPath + originalName;
        diskFilePath = CommonFunction.GetNewPathForDuplicates(diskFilePath);
        string realName = Path.GetFileName(diskFilePath);

        file.SaveAs(diskFilePath);

        string webDirPath = vituralPath.TrimEnd('/') + "/" + folderName + "/" + timestamp + "/" + realName;
        string jsonResult = "{\"src\":\"" + webDirPath + "\"}";
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }

    /// <summary>
    /// get config value by key name 
    /// </summary>
    public void UploadImage()
    {
        HttpPostedFile file = HttpContext.Current.Request.Files[0];
        string name = HttpContext.Current.Request["FileName"];
        string typeID = HttpContext.Current.Request["TypeID"];
        string relatedID = HttpContext.Current.Request["RelatedID"];
        string tempCode = HttpContext.Current.Request["TempCode"];
        string relatedCode = HttpContext.Current.Request["RelatedCode"];
        string resultID = HttpContext.Current.Request["ResultID"];

        int _typeID = 0;
        int _relatedID = 0;
        int.TryParse(typeID, out _typeID);
        int.TryParse(relatedID, out _relatedID);

        int _resultID = 0;
        int.TryParse(resultID, out _resultID);

        APQuestionnaireResultsDO resultDO = APQuestionnaireManager.GetQuestionnaireResultDOByID(_resultID);
        string fromDate = resultDO.FromDate.ToString("yyyy-MM-dd");
        APClientsDO clientDO = APClientManager.GetClientDOByID(resultDO.ClientID);
        string clientCode = clientDO.Code;
        
        DirectoryMappingDO dmDO = DocumentManager.GetCurrentDirMappingDO();
        string physicalPath = dmDO.PhysicalPath;
        string vituralPath = dmDO.VituralPath;

        string fileName = Path.GetFileName(file.FileName);
        int fileType = CommonFunction.GetFileType(fileName);
        string originalName = fileName;
        if (string.IsNullOrEmpty(name)) {
            name = fileName;
        }
        int projectID = WebSiteContext.CurrentProjectID;
        if (projectID <= 0)
        {
            HttpContext.Current.Response.ContentType = "text/plain";
            HttpContext.Current.Response.Write("-1");
            return;
        }

        string diskFolderPath = physicalPath.TrimEnd('\\') + "\\" + projectID + "\\" + fromDate + "\\" + clientCode + "\\" + fileType + "\\";
        if (Directory.Exists(diskFolderPath) == false)
        {
            Directory.CreateDirectory(diskFolderPath);
        }
        string diskFilePath = diskFolderPath + originalName;
        diskFilePath = CommonFunction.GetNewPathForDuplicates(diskFilePath);
        file.SaveAs(diskFilePath);

        string webDirPath = vituralPath.TrimEnd('/') + "/" + projectID + "/" + fromDate + "/" + clientCode + "/" + fileType + "/";
        string fixedFileName = Path.GetFileName(diskFilePath);
        string webFilePath = webDirPath + fixedFileName;

        string thumbRelevantPath = string.Empty;
        string thumbPhysicalPath = string.Empty;
        string timeLength = string.Empty;
        string extension = Path.GetExtension(diskFilePath).ToLower();
        if (fileType == (int)Enums.FileType.图片)
        {
            thumbRelevantPath = CommonFunction.GetThumbPathForImageFile(webFilePath);
            thumbPhysicalPath = CommonFunction.GetThumbPathForImageFile(diskFilePath);
            WebCommon.MakeThumbnail(diskFilePath, thumbPhysicalPath, Constants.ThumbnailWidth, Constants.ThumbnailHeight, "");
        }
        else if (fileType == (int)Enums.FileType.录音)
        {
            string videoCode = string.Empty;
            string audioCode = string.Empty;
            WebCommon.GetVideoInfo(diskFilePath, ref timeLength, ref videoCode, ref audioCode);
            if (extension != ".mp3" || audioCode != "mp3")
            {
                string fixedDiskFilePath = WebCommon.GetAudioConvertedPath(diskFilePath);
                if (string.IsNullOrEmpty(fixedDiskFilePath) == false)
                {
                    File.Delete(diskFilePath);
                    diskFilePath = Path.ChangeExtension(diskFilePath, "mp3");
                    diskFilePath = CommonFunction.GetNewPathForDuplicates(diskFilePath);
                    fixedFileName = Path.GetFileName(diskFilePath);
                    webFilePath = webDirPath + fixedFileName;
                    File.Move(fixedDiskFilePath, diskFilePath);
                }

            }
        }
        if (fileType == (int)Enums.FileType.录像)
        {
            //视频缩略图
            thumbPhysicalPath = WebCommon.CatchVideoCoverImage(diskFilePath);
            string fixedThumbFileName = Path.GetFileName(thumbPhysicalPath);
            thumbRelevantPath = webDirPath + fixedThumbFileName;

            string videoCode = string.Empty;
            string audioCode = string.Empty;
            WebCommon.GetVideoInfo(diskFilePath, ref timeLength, ref videoCode, ref audioCode);
            if (extension != ".mp4" || videoCode != "h264" || audioCode != "aac")
            {
                string fixedDiskFilePath = WebCommon.GetVideoConvertedPath(diskFilePath);
                if (string.IsNullOrEmpty(fixedDiskFilePath) == false)
                {
                    File.Delete(diskFilePath);
                    diskFilePath = Path.ChangeExtension(diskFilePath, "mp4");
                    diskFilePath = CommonFunction.GetNewPathForDuplicates(diskFilePath);
                    fixedFileName = Path.GetFileName(diskFilePath);
                    webFilePath = webDirPath + fixedFileName;
                    File.Move(fixedDiskFilePath, diskFilePath);
                }
            }
        }

        DocumentFilesDO doc = new DocumentFilesDO();
        doc.FileName = name;
        doc.OriginalFileName = originalName;
        doc.TempCode = tempCode;
        doc.RelatedID = _relatedID;
        doc.TypeID = _typeID;
        doc.FileSize = file.ContentLength;
        doc.TimeLength = timeLength;
        doc.Status = (int)Enums.DocumentStatus.正常;
        doc.RelevantPath = webFilePath;
        doc.PhysicalPath = diskFilePath;
        doc.ThumbRelevantPath = thumbRelevantPath;
        doc.FileType = fileType;
        doc.UserID = WebSiteContext.CurrentUserID;
        doc.InputDate = DateTime.Now;
        int docid = BusinessLogicBase.Default.Insert(doc);

        string success = docid.ToString();
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(success);
    }

    public void GetFiles() {
        string typeID = HttpContext.Current.Request.QueryString["TypeID"];
        string relatedID = HttpContext.Current.Request.QueryString["RelatedID"];
        string tempCode = HttpContext.Current.Request.QueryString["TempCode"];
        int _typeID = 0;
        int _relatedID = 0;
        int.TryParse(typeID, out _typeID);
        int.TryParse(relatedID, out _relatedID);
        int statusID = (int)Enums.DocumentStatus.正常;
        DataTable dt = new DataTable();
        if (_relatedID > 0)
        {
            dt = DocumentManager.GetFilesByRelatedID(_relatedID, _typeID, statusID, true, tempCode);
        }
        else
        {
            dt = DocumentManager.GetFilesByTempCode(tempCode, _typeID, true);
        }
        string jsonResult = JSONHelper.DataTableToJSON(dt);

        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetDeletedFiles()
    {
        string typeID = HttpContext.Current.Request.QueryString["TypeID"];
        string relatedID = HttpContext.Current.Request.QueryString["RelatedID"];
        int _typeID = 0;
        int _relatedID = 0;
        int.TryParse(typeID, out _typeID);
        int.TryParse(relatedID, out _relatedID);
        int statusID = (int)Enums.DocumentStatus.删除;
        DataTable dt = DocumentManager.GetFilesByRelatedID(_relatedID, _typeID, statusID, true, "");
        string jsonResult = JSONHelper.DataTableToJSON(dt);

        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetFileTypeID()
    {
        string fileName = HttpContext.Current.Request.QueryString["FileName"];
        int fileTypeID = CommonFunction.GetFileType(fileName);
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(fileTypeID.ToString());
    }

    public void GetFileTypeName()
    {
        string fileName = HttpContext.Current.Request.QueryString["FileName"];
        string fileTypeName = CommonFunction.GetFileTypeName(fileName);
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(fileTypeName);
    }

    public void DeleteFiles()
    {
        string fileIDs = HttpContext.Current.Request.Params["FileIDs"];
        string[] ids = fileIDs.Split(',');
        foreach (string fileID in ids)
        {
            int id = 0;
            int.TryParse(fileID, out id);
            DocumentFilesDO doc = new DocumentFilesDO();
            doc = (DocumentFilesDO)BusinessLogicBase.Default.Select(doc, id);
            doc.Status = (int)Enums.DocumentStatus.删除;
            doc.UserID = WebSiteContext.CurrentUserID;
            doc.InputDate = DateTime.Now;
            BusinessLogicBase.Default.Update(doc);
        }
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write("1");
    }

    public void DeleteFile()
    {
        string fileID = HttpContext.Current.Request.Params["FileID"];
        int id = 0;
        int.TryParse(fileID, out id);
        DocumentFilesDO doc = new DocumentFilesDO();
        doc = (DocumentFilesDO)BusinessLogicBase.Default.Select(doc, id);
        doc.Status = (int)Enums.DocumentStatus.删除;
        doc.UserID = WebSiteContext.CurrentUserID;
        doc.InputDate = DateTime.Now;
        BusinessLogicBase.Default.Update(doc);
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write("1");
    }

    public void RecoverFile()
    {
        string fileID = HttpContext.Current.Request.Params["FileID"];
        int id = 0;
        int.TryParse(fileID, out id);
        DocumentFilesDO doc = new DocumentFilesDO();
        doc = (DocumentFilesDO)BusinessLogicBase.Default.Select(doc, id);
        doc.Status = (int)Enums.DocumentStatus.正常;
        doc.UserID = WebSiteContext.CurrentUserID;
        doc.InputDate = DateTime.Now;
        BusinessLogicBase.Default.Update(doc);
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write("1");
    }

    public void DownloadPicture()
    {
        string id = HttpContext.Current.Request.Params["id"];
        int docID = 0;
        int.TryParse(id, out docID);
        DocumentFilesDO doc = new DocumentFilesDO();
        doc = (DocumentFilesDO)BusinessLogicBase.Default.Select(doc, docID);
        string fileName = doc.FileName;
        string physicalPath = doc.PhysicalPath;
        try
        {
            if (File.Exists(physicalPath))
            {
                FileInfo info = new FileInfo(physicalPath);
                long fileSize = info.Length;
                HttpContext.Current.Response.Clear();
                HttpContext.Current.Response.ContentType = "application/octet-stream";
                HttpContext.Current.Response.AddHeader("Content-Disposition", "attachment;filename=" + HttpContext.Current.Server.UrlEncode(fileName));
                HttpContext.Current.Response.AddHeader("Content-Length", fileSize.ToString());
                HttpContext.Current.Response.TransmitFile(physicalPath, 0, fileSize);
                HttpContext.Current.Response.Flush();
            }
        }
        catch
        { }
        finally
        {
            HttpContext.Current.Response.Close();
        }
    }

    public void ShowPicture()
    {
        string id = HttpContext.Current.Request.QueryString["id"];
        int docID = 0;
        int.TryParse(id, out docID);
        DocumentFilesDO doc = new DocumentFilesDO();
        doc = (DocumentFilesDO)BusinessLogicBase.Default.Select(doc, docID);
        string fileName = doc.FileName;
        string url = doc.RelevantPath;
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(url);
    }

    public bool IsReusable {
        get {
            return false;
        }
    }

}