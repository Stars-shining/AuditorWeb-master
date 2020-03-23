<%@ WebHandler Language="C#" Class="Training" %>

using System;
using System.Web;
using System.Web.SessionState;
using System.Data;
using System.Collections.Generic;
using System.IO;
using APLibrary;
using APLibrary.DataObject;
using APLibrary.Utility;

public class Training : IHttpHandler, IRequiresSessionState
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
                    GetTrainingInfo();
                    break;
                case 2:
                    GetTrainingFiles();
                    break;
                case 3:
                    GetTrainings();
                    break;
                case 4:
                    SubmitTraining();
                    break;
                case 5:
                    DeleteTraining();
                    break;
                case 6:
                    UploadTrainingFile();
                    break;
                case 7:
                    DownloadPicture();
                    break;
                case 8:
                    DoDeleteTrainingFile();
                    break;
                default:
                    break;
            }
        }
        catch { }
    }

    public void DoDeleteTrainingFile() 
    {
        string fileID = HttpContext.Current.Request.Params["FileID"];
        int id = 0;
        int.TryParse(fileID, out id);
        APTrainingFilesDO doc = new APTrainingFilesDO();
        doc = (APTrainingFilesDO)BusinessLogicBase.Default.Select(doc, id);
        doc.Status = (int)Enums.DocumentStatus.删除;
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
        APTrainingFilesDO doc = new APTrainingFilesDO();
        doc = (APTrainingFilesDO)BusinessLogicBase.Default.Select(doc, docID);
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

    private void UploadTrainingFile()
    {
        HttpPostedFile file = HttpContext.Current.Request.Files[0];
        string trainingID = HttpContext.Current.Request["id"];

        int _trainingID = 0;
        int.TryParse(trainingID, out _trainingID);
        string fileName = Path.GetFileName(file.FileName);
        string extension = Path.GetExtension(file.FileName);
        string originalName = fileName;
        string name = fileName;
        if (_trainingID <= 0)
        {
            HttpContext.Current.Response.ContentType = "text/plain";
            HttpContext.Current.Response.Write("0");
            return;
        }

        DirectoryMappingDO dmDO = DocumentManager.GetCurrentDirMappingDO();
        string physicalPath = dmDO.PhysicalPath;
        string vituralPath = dmDO.VituralPath;

        string diskFolderPath = physicalPath.TrimEnd('\\') + "\\" + trainingID + "\\";
        if (Directory.Exists(diskFolderPath) == false)
        {
            Directory.CreateDirectory(diskFolderPath);
        }
        string diskFilePath = diskFolderPath + originalName;
        diskFilePath = CommonFunction.GetNewPathForDuplicates(diskFilePath);
        file.SaveAs(diskFilePath);

        int fileType = CommonFunction.GetFileType(fileName);

        string webDirPath = vituralPath.TrimEnd('/') + "/" + trainingID + "/";
        string fixedFileName = Path.GetFileName(diskFilePath);
        string webFilePath = webDirPath + fixedFileName;

        string thumbRelevantPath = string.Empty;
        string thumbPhysicalPath = string.Empty;
        string timeLength = string.Empty;
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
        
        APTrainingFilesDO doc = new APTrainingFilesDO();
        doc.FileName = name;
        doc.OriginalFileName = originalName;
        doc.TrainingID = _trainingID;
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

    private void GetTrainingFiles() 
    {
        string id = HttpContext.Current.Request.QueryString["trainingID"];
        int _id = 0;
        int.TryParse(id, out _id);
        DataTable dt = APTrainingManager.GetTrainingFiles(_id);
        string jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void DeleteTraining()
    {
        string id = HttpContext.Current.Request.Params["id"];
        int _id = 0;
        int.TryParse(id, out _id);
        string jsonResult = "1";
        APTrainingManager.DeleteTrainingByID(_id);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    private void GetTrainingInfo() 
    {
        string id = HttpContext.Current.Request.QueryString["id"];
        int _id = 0;
        int.TryParse(id, out _id);
        APTrainingDO trainingDO = APTrainingManager.GetTrainingDOByID(_id);
        string jsonResult = JSONHelper.ObjectToJSON(trainingDO);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    private void SubmitTraining() 
    {
        string id = HttpContext.Current.Request.Params["id"];
        string name = HttpContext.Current.Request.Params["name"];
        string projectID = HttpContext.Current.Request.Params["projectID"];
        string typeID = HttpContext.Current.Request.Params["typeID"];
        string fromDate = HttpContext.Current.Request.Params["fromDate"];
        string toDate = HttpContext.Current.Request.Params["toDate"];
        string description = HttpContext.Current.Request.Params["description"];

        DateTime _fromDate = Constants.Date_Null;
        DateTime _toDate = Constants.Date_Null;
        DateTime.TryParse(fromDate, out _fromDate);
        DateTime.TryParse(toDate, out _toDate);
        int _id = 0;
        int _projectID = 0;
        int _typeID = 0;
        int.TryParse(id, out _id);
        int.TryParse(projectID, out _projectID);
        int.TryParse(typeID, out _typeID);

        APTrainingDO trainingDO = new APTrainingDO();
        if (_id > 0)
        {
            trainingDO = APTrainingManager.GetTrainingDOByID(_id);
            trainingDO.LastModifiedTime = DateTime.Now;
            trainingDO.LastModifiedUserID = WebSiteContext.CurrentUserID;
        }
        else
        {
            trainingDO.CreateTime = DateTime.Now;
            trainingDO.CreateUserID = WebSiteContext.CurrentUserID;
        }
        trainingDO.ProjectID = _projectID;
        trainingDO.Title = name;
        trainingDO.FromDate = _fromDate;
        trainingDO.ToDate = _toDate;
        trainingDO.TypeID = _typeID;
        trainingDO.Description = description;
        if (_id > 0)
        {
            BusinessLogicBase.Default.Update(trainingDO);
        }
        else 
        {
            _id = BusinessLogicBase.Default.Insert(trainingDO);
        }
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(_id);
    }

    private void GetTrainings() 
    {
        string name = HttpContext.Current.Request.QueryString["name"];
        string projectID = HttpContext.Current.Request.QueryString["projectID"];
        string typeID = HttpContext.Current.Request.QueryString["typeID"];
        string period = HttpContext.Current.Request.QueryString["period"];
        int _projectID = 0;
        int _typeID = 0;
        int.TryParse(typeID, out _typeID);
        int.TryParse(projectID, out _projectID);
        DateTime fromDate = Constants.Date_Min;
        DateTime toDate = Constants.Date_Max;
        if (period != "-999" && period.Contains("|"))
        {
            string strFrom = period.Split('|')[0];
            string strTo = period.Split('|')[1];
            DateTime.TryParse(strFrom, out fromDate);
            DateTime.TryParse(strTo, out toDate);
        }
        if (string.IsNullOrEmpty(name)) 
        {
            name = "";
        }
        DataTable dt = APTrainingManager.GetTrainings(name, _projectID,_typeID, fromDate, toDate);
        string jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

 
    public bool IsReusable {
        get {
            return false;
        }
    }

}