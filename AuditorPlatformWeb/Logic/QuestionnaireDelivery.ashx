<%@ WebHandler Language="C#" Class="QuestionnaireDelivery" %>

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

public class QuestionnaireDelivery : IHttpHandler, IRequiresSessionState
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
                    GetQuestionnaireDelivery();
                    break;
                case 2:
                    SubmitQuestionnaireDelivery();
                    break;
                case 3:
                    ChangeDeliveryPerson();
                    break;
                case 4:
                    DeleteDelivery();
                    break;
                case 5:
                    GetQuestionnaireDeliverySettings();
                    break;
                case 6:
                    SubmitQuestionnaireDeliverySettings();
                    break;
                case 7:
                    GetQuestionnaireUploadList();
                    break;
                case 8:
                    GetQuestionnaireDeliveryInfo();
                    break;
                case 9:
                    GetQuestionnaireResultInfo();
                    break;
                case 10:
                    SubmitQuestionnaireResult();
                    break;
                case 11:
                    UploadQuestionnaireDelivery();
                    break;
                case 12:
                    CheckQuestionnaireDelivery();
                    break;
                default: 
                    break;
            }
        }
        catch { }
    }

    public void CheckQuestionnaireDelivery() 
    {
        int deliveryID = HttpContext.Current.Request.QueryString["deliveryID"].ToInt(0);
        bool bFull = APQuestionnaireManager.CheckDeliveryFull(deliveryID);
        string result = bFull ? "1" : "0";
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(result);
        
    }

    public void UploadQuestionnaireDelivery()
    {
        string typeID = HttpContext.Current.Request["typeID"];
        int _typeID = 0;
        int.TryParse(typeID, out _typeID);
        
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
        doc.TypeID = (int)Enums.DocumentType.上传执行计划;
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
            ReadDelivery(diskFilePath, projectID, _typeID);
            success = "1";
        }
        catch
        {
            success = "0";
        }
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(success);
    }

    private void ReadDelivery(string filePath, int projectID, int typeID) 
    {
        DataSet ds = ParseExcel.GetDataSetFromExcelFile(filePath);
        if (ds == null || ds.Tables.Count <= 0)
        {
            return;
        }
        DataTable dt = ds.Tables["上传执行计划$"];
        if (dt == null || dt.Rows.Count <= 0)
        {
            return;
        }
        for (int i = 0; i < dt.Rows.Count; i++)
        {
            DataRow row = dt.Rows[i];
            string code = row["机构编号"].ToString();
            string name = row["机构名称"].ToString();
            string questionnaireName = row["问卷名称"].ToString();
            string beginDate = row["开始日期"].ToString();
            string endDate = row["结束日期"].ToString();
            string acceptUserName = row["访问员姓名"].ToString();
            string sampleNumber = row["样本数量"].ToString();

            if (!string.IsNullOrEmpty(code))
            {
                APClientsDO clientDO = APClientManager.GetClientByCode(code, projectID);
                if (clientDO == null || clientDO.ID <= 0)
                {
                    continue;
                }
                APUsersDO userDO = APUserManager.GetUserDOByUserName(acceptUserName, typeID);
                if (userDO == null || userDO.ID <= 0)
                {
                    continue;
                }
                APQuestionnairesDO apo = APQuestionnaireManager.GetQuestionnaireDOByName(projectID, questionnaireName);
                if (apo == null || apo.ID <= 0)
                {
                    continue;
                }
                int clienID = clientDO.ID;
                int acceptUserID = userDO.ID;
                int questionnaireID = apo.ID;
                DateTime fromDate = Constants.Date_Min;
                DateTime toDate = Constants.Date_Max;
                DateTime.TryParse(beginDate, out fromDate);
                DateTime.TryParse(endDate, out toDate);

                int _sampleNumber = 0;
                int.TryParse(sampleNumber, out _sampleNumber);

                APQuestionnaireDeliveryDO deliveryDO = APQuestionnaireManager.GetQuestionnaireDeliveryDO(questionnaireID, clienID, fromDate, toDate, typeID);
                if (deliveryDO == null)
                {
                    deliveryDO = new APQuestionnaireDeliveryDO();
                }
                deliveryDO.AcceptUserID = acceptUserID;
                deliveryDO.SampleNumber = _sampleNumber;
                deliveryDO.ClientID = clienID;
                deliveryDO.CreateTime = DateTime.Now;
                deliveryDO.CreateUserID = WebSiteContext.CurrentUserID;
                deliveryDO.FromDate = fromDate;
                deliveryDO.ToDate = toDate;
                deliveryDO.TypeID = typeID;
                deliveryDO.QuestionnaireID = questionnaireID;
                deliveryDO.ProjectID = projectID;
                if (deliveryDO.ID > 0)
                {
                    BusinessLogicBase.Default.Update(deliveryDO);
                }
                else
                {
                    BusinessLogicBase.Default.Insert(deliveryDO);
                }
            }
        }
    }

    public void SubmitQuestionnaireResult() 
    {
        string resultID = HttpContext.Current.Request.Params["resultID"];
        string deliveryID = HttpContext.Current.Request.Params["deliveryID"];
        string clientID = HttpContext.Current.Request.Params["clientID"];
        string visitFromTime = HttpContext.Current.Request.Params["visitFromTime"];
        string visitToTime = HttpContext.Current.Request.Params["visitToTime"];
        string description = HttpContext.Current.Request.Params["description"];
        string videoPath = HttpContext.Current.Request.Params["videoPath"];
        string videoLength = HttpContext.Current.Request.Params["videoLength"];

        int _resultID = 0;
        int.TryParse(resultID, out _resultID);
        int _deliveryID = 0;
        int.TryParse(deliveryID, out _deliveryID);
        int _clientID = 0;
        int.TryParse(clientID, out _clientID);
        
        DateTime fromTime = Constants.Date_Null;
        DateTime toTime = Constants.Date_Null;
        DateTime.TryParse(visitFromTime, out fromTime);
        DateTime.TryParse(visitToTime, out toTime);

        APQuestionnaireResultsDO resultDO = new APQuestionnaireResultsDO();
        if (_resultID > 0)
        {
            resultDO = (APQuestionnaireResultsDO)APQuestionnaireManager.Default.Select(resultDO, _resultID);
            resultDO.VideoPath = videoPath;
            resultDO.VideoLength = videoLength;
            resultDO.Description = description;
            resultDO.VisitBeginTime = fromTime;
            resultDO.VisitEndTime = toTime;
            
            resultDO.LastModifiedTime = DateTime.Now;
            resultDO.LastModifiedUserID = WebSiteContext.CurrentUserID;
            BusinessLogicBase.Default.Update(resultDO);
        }
        else 
        {
            APQuestionnaireDeliveryDO deliveryDO = new APQuestionnaireDeliveryDO();
            deliveryDO = (APQuestionnaireDeliveryDO)APQuestionnaireManager.Default.Select(deliveryDO, _deliveryID);
            resultDO.ClientID = _clientID;
            resultDO.FromDate = deliveryDO.FromDate;
            resultDO.ToDate = deliveryDO.ToDate;
            resultDO.QuestionnaireID = deliveryDO.QuestionnaireID;
            resultDO.DeliveryID = _deliveryID;
            
            resultDO.VideoPath = videoPath;
            resultDO.VideoLength = videoLength;
            resultDO.Description = description;
            resultDO.VisitBeginTime = fromTime;
            resultDO.VisitEndTime = toTime;

            resultDO.UploadBeginTime = DateTime.Now;
            
            resultDO.VisitUserID = deliveryDO.AcceptUserID;
            resultDO.VisitUserUploadStatus = (int)Enums.QuestionnaireUploadStatus.录入未完成;
            resultDO.Status = (int)Enums.QuestionnaireStageStatus.录入中;
            resultDO.ProjectID = WebSiteContext.CurrentProjectID;
            _resultID = BusinessLogicBase.Default.Insert(resultDO);
        }

        string jsonResult = _resultID.ToString();
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetQuestionnaireResultInfo()
    {
        string resultID = HttpContext.Current.Request.QueryString["resultID"];
        int _resultID = 0;
        int.TryParse(resultID, out _resultID);
        DataTable dt = APQuestionnaireManager.GetQuestionnaireResultInfo(_resultID);
        string jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetQuestionnaireDeliveryInfo() 
    {
        string deliveryID = HttpContext.Current.Request.QueryString["deliveryID"];
        string clientID = HttpContext.Current.Request.QueryString["clientID"];
        int _deliveryID = 0;
        int.TryParse(deliveryID, out _deliveryID);
        int _clientID = 0;
        int.TryParse(clientID, out _clientID);
        DataTable dt = APQuestionnaireManager.GetQuestionnaireDeliveryInfo(_deliveryID, _clientID);
        string jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void SubmitQuestionnaireDeliverySettings() 
    {
        string areaLevelType = HttpContext.Current.Request.Params["areaLevelID"];
        string cityLevelType = HttpContext.Current.Request.Params["cityLevelID"];
        string visitLevelType = HttpContext.Current.Request.Params["visitLevelID"];
        string qcLevelType = HttpContext.Current.Request.Params["qcLevelID"];

        int _areaLevelType = 0;
        int _cityLevelType = 0;
        int _visitLevelType = 0;
        int _qcLevelType = 0;
        int.TryParse(areaLevelType, out _areaLevelType);
        int.TryParse(cityLevelType, out _cityLevelType);
        int.TryParse(visitLevelType, out _visitLevelType);
        int.TryParse(qcLevelType, out _qcLevelType);

        int projectID = WebSiteContext.CurrentProjectID;
        APQuestionnaireDeliverySettingsDO settingDO = APQuestionnaireManager.GetAPQuestionnaireDeliverySettingsDOByProjectID(projectID);
        if (settingDO == null) {
            settingDO = new APQuestionnaireDeliverySettingsDO();
        }
        settingDO.AreaLevelID = _areaLevelType;
        settingDO.CityLevelID = _cityLevelType;
        settingDO.VisitLevelID = _visitLevelType;
        settingDO.QCLevelID = _qcLevelType;

        if (settingDO.ProjectID > 0)
        {
            BusinessLogicBase.Default.Update(settingDO);
        }
        else
        {
            settingDO.ProjectID = projectID;
            BusinessLogicBase.Default.Insert(settingDO);
        }
        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }
    
    public void GetQuestionnaireDeliverySettings() 
    {
        int projectID = WebSiteContext.CurrentProjectID;
        APQuestionnaireDeliverySettingsDO settingDO = APQuestionnaireManager.GetAPQuestionnaireDeliverySettingsDOByProjectID(projectID);
        string jsonResult = JSONHelper.ObjectToJSON(settingDO);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void SubmitQuestionnaireDelivery()
    {
        string clientID = HttpContext.Current.Request.Params["clientID"];
        string questionnaireID = HttpContext.Current.Request.Params["questionnaireID"];
        string fromdate = HttpContext.Current.Request.Params["fromdate"];
        string todate = HttpContext.Current.Request.Params["todate"];
        string typeID = HttpContext.Current.Request.Params["typeID"];
        string acceptUserID = HttpContext.Current.Request.Params["acceptUserID"];
        string sampleNumber = HttpContext.Current.Request.Params["sampleNumber"];

        int _clientID = 0;
        int _questionnaireID = 0;
        int _typeID = 0;
        int _acceptUserID = 0;
        int _sampleNumber = 0;
        DateTime _fromDate = Constants.Date_Null;
        DateTime _toDate = Constants.Date_Null;
        
        int.TryParse(clientID, out _clientID);
        int.TryParse(questionnaireID, out _questionnaireID);
        int.TryParse(typeID, out _typeID);
        int.TryParse(acceptUserID, out _acceptUserID);
        int.TryParse(sampleNumber, out _sampleNumber);
        DateTime.TryParse(fromdate, out _fromDate);
        DateTime.TryParse(todate, out _toDate);
        
        APQuestionnaireDeliveryDO ddo = new APQuestionnaireDeliveryDO();
        ddo.ClientID = _clientID;
        ddo.QuestionnaireID = _questionnaireID;
        ddo.FromDate = _fromDate;
        ddo.ToDate = _toDate;
        ddo.TypeID = _typeID;
        ddo.AcceptUserID = _acceptUserID;
        ddo.SampleNumber = _sampleNumber;
        ddo.ProjectID = WebSiteContext.CurrentProjectID;
        ddo.CreateTime = DateTime.Now;
        ddo.CreateUserID = WebSiteContext.CurrentUserID;
        BusinessLogicBase.Default.Insert(ddo);

        WebCommon.SendVisitDeliveryNotice(WebSiteContext.CurrentProjectID, _questionnaireID, _clientID, _acceptUserID, _fromDate, _toDate, _typeID);
        
        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void ChangeDeliveryPerson() 
    {
        string id = HttpContext.Current.Request.Params["id"];
        string acceptUserID = HttpContext.Current.Request.Params["acceptUserID"];
        string sampleNumber = HttpContext.Current.Request.Params["sampleNumber"];
        int _id = 0;
        int _acceptUserID = 0;
        int.TryParse(id, out _id);
        int.TryParse(acceptUserID, out _acceptUserID);

        int _sampleNumber = 0;
        int.TryParse(sampleNumber, out _sampleNumber);

        APQuestionnaireDeliveryDO ddo = new APQuestionnaireDeliveryDO();
        ddo = (APQuestionnaireDeliveryDO)BusinessLogicBase.Default.Select(ddo, _id);
        int oldUserID = ddo.AcceptUserID;
        ddo.AcceptUserID = _acceptUserID;
        ddo.SampleNumber = _sampleNumber;
        BusinessLogicBase.Default.Update(ddo);

        WebCommon.SendCancelDeliveryNotice(WebSiteContext.CurrentProjectID, ddo.QuestionnaireID, ddo.ClientID, oldUserID, ddo.FromDate, ddo.ToDate, ddo.TypeID);
        WebCommon.SendVisitDeliveryNotice(WebSiteContext.CurrentProjectID, ddo.QuestionnaireID, ddo.ClientID, _acceptUserID, ddo.FromDate, ddo.ToDate, ddo.TypeID);
        
        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void DeleteDelivery()
    {
        string id = HttpContext.Current.Request.Params["id"];
        int _id = 0;
        int.TryParse(id, out _id);

        APQuestionnaireDeliveryDO ddo = new APQuestionnaireDeliveryDO();
        ddo.ID = _id;
        BusinessLogicBase.Default.Delete(ddo);

        WebCommon.SendCancelDeliveryNotice(WebSiteContext.CurrentProjectID, ddo.QuestionnaireID, ddo.ClientID, ddo.AcceptUserID, ddo.FromDate, ddo.ToDate, ddo.TypeID);
        
        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetQuestionnaireDelivery()
    {
        string qid = HttpContext.Current.Request.QueryString["qid"];
        string areaID = HttpContext.Current.Request.QueryString["areaID"];
        string levelID = HttpContext.Current.Request.QueryString["levelID"];
        string typeID = HttpContext.Current.Request.QueryString["typeID"];
        string statusID = HttpContext.Current.Request.QueryString["statusID"];
        string province = HttpContext.Current.Request.QueryString["province"];
        string city = HttpContext.Current.Request.QueryString["city"];
        string district = HttpContext.Current.Request.QueryString["district"];
        string period = HttpContext.Current.Request.QueryString["period"];
        string keyword = HttpContext.Current.Request.QueryString["keyword"];
        if (province == null)
        {
            province = "-999"; ;
        }
        if (city == null)
        {
            city = "-999"; ;
        }
        if (district == null)
        {
            district = "-999"; ;
        }
        
        int _qid = 0;
        int _areaID = 0;
        int _levelID = 0;
        int _typeID = 0;
        int _statusID = 0;
        int.TryParse(qid, out _qid);
        int.TryParse(areaID, out _areaID);
        int.TryParse(levelID, out _levelID);
        int.TryParse(typeID, out _typeID);
        int.TryParse(statusID, out _statusID);

        DateTime fromDate = Constants.Date_Min;
        DateTime toDate = Constants.Date_Max;
        if (period.Contains("|"))
        {
            string strFrom = period.Split('|')[0];
            string strTo = period.Split('|')[1];
            DateTime.TryParse(strFrom, out fromDate);
            DateTime.TryParse(strTo, out toDate);
        }
        
        int projectID = WebSiteContext.CurrentProjectID;
        int roleID = WebSiteContext.Current.CurrentUser.RoleID;
        int userID = WebSiteContext.CurrentUserID;
        DataTable dt = APQuestionnaireManager.GetQuestionnaireDelivery(projectID, _qid, _areaID, _levelID, _typeID, _statusID, province, city, district, roleID, userID, fromDate, toDate, keyword);
        string jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetQuestionnaireUploadList()
    {
        string qid = HttpContext.Current.Request.QueryString["qid"];
        string period = HttpContext.Current.Request.QueryString["period"];
        string statusID = HttpContext.Current.Request.QueryString["statusID"];
        string areaID = HttpContext.Current.Request.QueryString["areaID"];
        string province = HttpContext.Current.Request.QueryString["province"];
        string city = HttpContext.Current.Request.QueryString["city"];
        string district = HttpContext.Current.Request.QueryString["district"];
        string keyword = HttpContext.Current.Request.QueryString["keyword"];
        int _qid = 0;
        int _areaID = 0;
        int _statusID = 0;
        int.TryParse(qid, out _qid);
        int.TryParse(areaID, out _areaID);
        int.TryParse(statusID, out _statusID);

        DateTime fromdate = Constants.Date_Min;
        DateTime todate = Constants.Date_Max;
        if (period != "-999") 
        {
            int splitCharIndex =  period.IndexOf('|');
            string strFromDate = period.Substring(0, splitCharIndex).Trim();
            string strToDate = period.Substring(splitCharIndex + 1).Trim();
            DateTime.TryParse(strFromDate, out fromdate);
            DateTime.TryParse(strToDate, out todate);
        }
        int projectID = WebSiteContext.CurrentProjectID;
        int roleID = WebSiteContext.Current.CurrentUser.RoleID;
        int userID = WebSiteContext.CurrentUserID;
        DataTable dt = APQuestionnaireManager.GetQuestionnaireUploadList(projectID, _qid, fromdate, todate, _statusID, _areaID, province, city, district, roleID, userID, keyword);
        if (WebSiteContext.CurrentClientID > 0) 
        {
            DataView dv = dt.DefaultView;
            dv.RowFilter = "ClientID=" + WebSiteContext.CurrentClientID;
            dt = dv.ToTable();
        }
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