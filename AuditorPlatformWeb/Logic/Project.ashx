<%@ WebHandler Language="C#" Class="Project" %>

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

public class Project : IHttpHandler, IRequiresSessionState
{
    public void ProcessRequest (HttpContext context) 
    {
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
                    GetAllProjects();
                    break;
                case 2:
                    GetProjectInfo();
                    break;
                case 3:
                    SubmitProject();
                    break;
                case 4:
                    DeleteProject();
                    break;
                case 5:
                    GetProjectTypes();
                    break;
                case 6:
                    LoginProject();
                    break;
                case 7:
                    LoadProjectName();
                    break;
                case 8:
                    QuitProject();
                    break;
                case 9:
                    LoadProjectFrequency();
                    break;
                case 10:
                    LoadProjectPeriod();
                    break;
                case 11:
                    LoadCurrentProject();
                    break;
                case 12:
                    CreateProjectQRCode();
                    break;
                case 13:
                    GetProjectAppealPeriods();
                    break;
                case 14:
                    GetProjectAppealPeriodDO();
                    break;
                case 15:
                    SubmitProjectAppealPeriodDO();
                    break;
                case 16:
                    DeleteProjectAppealPeriodDO();
                    break;
                case 17:
                    GetAllProjectsForLogin();
                    break;
                case 18:
                    ClearAllInProject();
                    break;
                case 19:
                    GetCurrentProjectTimePeriod();
                    break;
                case 20:
                    GetProjectTimePeriodInfo();
                    break;
                case 21:
                    SubmitProjectTimePeriodInfo();
                    break;
                case 22:
                    DeleteProjectTimePeriod();
                    break;
                default: 
                    break;
            }
        }
        catch { }
    }

    public void DeleteProjectTimePeriod()
    {
        string id = HttpContext.Current.Request.Params["id"];
        int _id = 0;
        int.TryParse(id, out _id);
        APProjectTimePeriodDO timeDO = new APProjectTimePeriodDO();
        timeDO.ID = _id;
        BusinessLogicBase.Default.Delete(timeDO);
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write("1");
    }

    public void GetProjectTimePeriodInfo() 
    {
        string id = HttpContext.Current.Request.QueryString["id"];
        int _id = 0;
        int.TryParse(id, out _id);
        APProjectTimePeriodDO timeDO = new APProjectTimePeriodDO();
        timeDO = (APProjectTimePeriodDO)BusinessLogicBase.Default.Select(timeDO, _id);
        string jsonResult = JSONHelper.ObjectToJSON(timeDO);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void SubmitProjectTimePeriodInfo() 
    {
        string id = HttpContext.Current.Request.Params["id"];
        string title = HttpContext.Current.Request.Params["title"];
        string beginTime = HttpContext.Current.Request.Params["beginTime"];
        string endTime = HttpContext.Current.Request.Params["endTime"];

        TimeSpan tsStart = TimeSpan.MinValue;
        TimeSpan tsEnd = TimeSpan.MaxValue;
        TimeSpan.TryParse(beginTime, out tsStart);
        TimeSpan.TryParse(endTime, out tsEnd);
        
        int _id = 0;
        int.TryParse(id, out _id);
        APProjectTimePeriodDO apo = new APProjectTimePeriodDO();
        if (_id > 0)
        {
            apo = APProjectManager.GetProjectTimePeriodByID(_id);
        }
        apo.Title = title;
        apo.TimeStart = tsStart;
        apo.TimeEnd = tsEnd;
        apo.ProjectID = WebSiteContext.CurrentProjectID;
        if (_id > 0)
        {
            BusinessLogicBase.Default.Update(apo);
        }
        else
        {
            _id = BusinessLogicBase.Default.Insert(apo);
        }
        
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(_id);    
    }

    public void GetCurrentProjectTimePeriod() 
    {
        int projectID = WebSiteContext.CurrentProjectID;
        DataTable dt = APProjectManager.GetProjectTimePeriod(projectID);
        string jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void ClearAllInProject()
    {
        int projectID = WebSiteContext.CurrentProjectID;
        APProjectManager.ClearAllInProject(projectID);
        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetAllProjectsForLogin()
    {
        string groupID = HttpContext.Current.Request.Params["groupID"];
        int _groupID = 0;
        int.TryParse(groupID, out _groupID);

        DataTable dt = APProjectManager.GetAllProjectsByGroupID(_groupID);
        string jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void SubmitProjectAppealPeriodDO()
    {
        string id = HttpContext.Current.Request.Params["id"];
        string qid = HttpContext.Current.Request.Params["qid"];
        string period = HttpContext.Current.Request.Params["period"];

        int _id = 0;
        int _qid = 0;
        int.TryParse(id, out _id);
        int.TryParse(qid, out _qid);
        DateTime fromDate = Constants.Date_Min;
        DateTime toDate = Constants.Date_Max;
        if (period.Contains("-"))
        {
            string strFrom = period.Split('-')[0];
            string strTo = period.Split('-')[1];
            DateTime.TryParse(strFrom, out fromDate);
            DateTime.TryParse(strTo, out toDate);
        }
        
        APAppealPeriodDO periodDO = new APAppealPeriodDO();
        if (_id > 0)
        {
            periodDO = (APAppealPeriodDO)BusinessLogicBase.Default.Select(periodDO, _id);
        }
        periodDO.FromDate = fromDate;
        periodDO.ToDate = toDate;
        periodDO.QuestionnaireID = _qid;
        periodDO.ProjectID = WebSiteContext.CurrentProjectID;
        periodDO.CreateTime = DateTime.Now;
        periodDO.CreateUserID = WebSiteContext.CurrentUserID;
        if (_id > 0)
        {
            BusinessLogicBase.Default.Update(periodDO);
        }
        else
        {
            BusinessLogicBase.Default.Insert(periodDO);
        }
        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void DeleteProjectAppealPeriodDO()
    {
        string id = HttpContext.Current.Request.Params["id"];

        int _id = 0;
        int.TryParse(id, out _id);

        APAppealPeriodDO periodDO = new APAppealPeriodDO();
        periodDO = (APAppealPeriodDO)BusinessLogicBase.Default.Select(periodDO, _id);
        BusinessLogicBase.Default.Delete(periodDO);
        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }


    public void GetProjectAppealPeriodDO()
    {
        string id = HttpContext.Current.Request.QueryString["id"];

        int _id = 0;
        int.TryParse(id, out _id);

        APAppealPeriodDO periodDO = new APAppealPeriodDO();
        periodDO = (APAppealPeriodDO)BusinessLogicBase.Default.Select(periodDO, _id);
        string jsonResult = JSONHelper.ObjectToJSON(periodDO);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetProjectAppealPeriods()
    {
        string qid = HttpContext.Current.Request.QueryString["qid"];
        string period = HttpContext.Current.Request.QueryString["period"];

        int _qid = 0;
        int.TryParse(qid, out _qid);

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
        DataTable dt = APProjectManager.GetProjectAppealPeriods(projectID, _qid, fromDate, toDate);
        string jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void CreateProjectQRCode()
    {
        string id = HttpContext.Current.Request.Params["id"];
        string refresh = HttpContext.Current.Request.Params["refresh"];

        bool bNew = false;
        bool.TryParse(refresh, out bNew);

        string fileName = string.Format("项目二维码_" + id + ".jpg");
        string folderRelevantPath = Constants.RelevantQRCodePath;
        string folderPath = HttpContext.Current.Server.MapPath(folderRelevantPath);
        if (System.IO.Directory.Exists(folderPath) == false)
        {
            System.IO.Directory.CreateDirectory(folderPath);
        }
        string fileRelevantPath = folderRelevantPath + fileName;
        string filePath = folderPath.TrimEnd('\\') + "\\" + fileName;
        string webDirPath = fileRelevantPath.Replace("~", "..");
        if (bNew || !System.IO.File.Exists(filePath))
        {
            string expireTime = DateTime.Now.AddDays(1).ToString("yyyy-MM-dd hh:mm:ss");
            string paras = "?pid=" + CommonFunction.EncodeBase64(id, 2) + "&et=" + CommonFunction.EncodeBase64(expireTime, 2);
            string url = HttpContext.Current.Request.UrlReferrer.ToString().Replace("Pages/ProjectList.htm", "Mobile/searchVisitor.htm") + paras;
            QRCodeLib.ImageUtility util = new QRCodeLib.ImageUtility();
            string logoPath = HttpContext.Current.Server.MapPath(Constants.SysLogoWithoutName);
            System.Drawing.Bitmap img = QRCodeLib.QRCodeHelper.CreateQRCodeWithLogo(url, logoPath);
            if (System.IO.File.Exists(filePath))
            {
                System.IO.File.Delete(filePath);
            }
            img.Save(filePath);
        }
        string jsonResult = webDirPath;
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void LoadCurrentProject() 
    {
        APProjectsDO apDO = WebSiteContext.Current.CurrentProject;
        string jsonResult = JSONHelper.ObjectToJSON(apDO);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void LoadProjectPeriod()
    {
        APProjectsDO apDO = WebSiteContext.Current.CurrentProject;

        if (apDO != null)
        {
            DateTime fromdate = apDO.FromDate;
            DateTime todate = apDO.ToDate;
            int frequency = apDO.Frequency;
            DataTable dt = CommonFunction.GetPeriod(frequency, fromdate, todate);
            string jsonResult = JSONHelper.DataTableToJSON(dt);
            HttpContext.Current.Response.ContentType = "application/json";
            HttpContext.Current.Response.Write(jsonResult);
        }
        else
        {
            HttpContext.Current.Response.ContentType = "application/json";
            HttpContext.Current.Response.Write("0");
        }
    }

    public void LoadProjectFrequency()
    {
        DataTable dt = BusinessConfigurationManager.GetDictListByDesc("ProjectFrequency");
        string jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }
 

    public void LoadProjectName()
    {
        string projectName = string.Empty;
        if (WebSiteContext.Current.CurrentProject != null) 
        {
            projectName = WebSiteContext.Current.CurrentProject.Name;
        }
        HttpContext.Current.Response.ContentType = "plain/text";
        HttpContext.Current.Response.Write(projectName);
    }

    public void QuitProject()
    {
        WebSiteContext.Current.CurrentProject = null;
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write("1");
    }

    public void LoginProject() 
    {
        string id = HttpContext.Current.Request.Params["id"];
        int _id = 0;
        int.TryParse(id, out _id);
        APProjectsDO apDO = APProjectManager.GetProjectByID(_id);
        WebSiteContext.Current.CurrentProject = apDO;
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write("1");    
    }

    public void SubmitProject() {
        string success = "0";
        try
        {
            string id = HttpContext.Current.Request.Params["id"];
            string name = HttpContext.Current.Request.Params["name"];
            string from = HttpContext.Current.Request.Params["fromdate"];
            string to = HttpContext.Current.Request.Params["todate"];
            string typeID = HttpContext.Current.Request.Params["typeID"];
            string coreUserID = HttpContext.Current.Request.Params["coreUserID"];
            string primaryApplyUserID = HttpContext.Current.Request.Params["primaryApplyUserID"];
            string qcLeaderUserID = HttpContext.Current.Request.Params["qcLeaderUserID"];

            string background = HttpContext.Current.Request.Params["background"];
            string description = HttpContext.Current.Request.Params["description"];
            string sampleNumber = HttpContext.Current.Request.Params["sampleNumber"];
            string frequency = HttpContext.Current.Request.Params["frequency"];
            string hasAreaUser = HttpContext.Current.Request.Params["hasAreaUser"];
            string autoAppeal = HttpContext.Current.Request.Params["autoAppeal"];

            DateTime fromdate = Constants.Date_Null;
            DateTime todate = Constants.Date_Null;
            DateTime.TryParse(from, out fromdate);
            DateTime.TryParse(to, out todate);
            int _typeID = 0;
            int.TryParse(typeID, out _typeID);
            int _coreUserID = 0;
            int.TryParse(coreUserID, out _coreUserID);
            int _primaryApplyUserID = 0;
            int.TryParse(primaryApplyUserID, out _primaryApplyUserID);
            int _qcLeaderUserID = 0;
            int.TryParse(qcLeaderUserID, out _qcLeaderUserID);
            
            int _sampleNumber = 0;
            int.TryParse(sampleNumber, out _sampleNumber);
            int _frequency = 0;
            int.TryParse(frequency, out _frequency);
            bool _hasAreaUser = false;
            bool.TryParse(hasAreaUser, out _hasAreaUser);

            bool _autoAppeal = false;
            bool.TryParse(autoAppeal, out _autoAppeal);
            
            int _id = 0;
            int.TryParse(id, out _id);
            APProjectsDO apo = new APProjectsDO();
            if (_id > 0)
            {
                apo = APProjectManager.GetProjectByID(_id);
                apo.LastModifiedTime = DateTime.Now;
                apo.LastModifiedUserID = WebSiteContext.CurrentUserID;
            }
            else
            {
                apo.GroupID = 0;//暂时为0
                apo.Status = 1;
                apo.CreateTime = DateTime.Now;
                apo.CreateUserID = WebSiteContext.CurrentUserID;
            }
            apo.Name = name;
            apo.FromDate = fromdate;
            apo.ToDate = todate;
            apo.TypeID = _typeID;
            apo.CoreUserID = _coreUserID;
            apo.PrimaryApplyUserID = _primaryApplyUserID;
            apo.QCLeaderUserID = _qcLeaderUserID;
            apo.Background = background;
            apo.Description = description;
            apo.SampleNumber = _sampleNumber;
            apo.Frequency = _frequency;
            apo.BHasAreaUser = _hasAreaUser;
            apo.BAutoAppeal = _autoAppeal;
            apo.DeleteFlag = false;
            if (_id > 0)
            {
                BusinessLogicBase.Default.Update(apo);
            }
            else
            {
                _id = BusinessLogicBase.Default.Insert(apo);

                WebCommon.SendCreateProjectNotice(_id, _coreUserID, name);
                WebCommon.SendCreateProjectNotice(_id, _primaryApplyUserID, name);
                WebCommon.SendCreateProjectNotice(_id, _qcLeaderUserID, name);
            }
            success = _id.ToString();
        }
        catch {
            success = "0";
        }
        
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(success);    
    }

    public void GetAllProjects()
    {
        string jsonResult = string.Empty;
        string name = HttpContext.Current.Request.QueryString["name"];
        string from = HttpContext.Current.Request.QueryString["fromdate"];
        string to = HttpContext.Current.Request.QueryString["todate"];
        string statusID = HttpContext.Current.Request.QueryString["statusID"];

        DateTime fromdate = Constants.Date_Null;
        DateTime todate = Constants.Date_Null;
        DateTime.TryParse(from, out fromdate);
        DateTime.TryParse(to, out todate);
        int _statusID = 0;
        int.TryParse(statusID, out _statusID);

        int currentUserID = WebSiteContext.CurrentUserID;
        int currentUserType = WebSiteContext.Current.CurrentUser.RoleID;

        DataTable dt = APProjectManager.GetAllProjects(name, fromdate, todate, _statusID, currentUserID, currentUserType);
        jsonResult = JSONHelper.DataTableToJSON(dt);

        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetProjectInfo() 
    {
        string id = HttpContext.Current.Request.QueryString["id"];
        int _id = 0;
        int.TryParse(id, out _id);
        if (_id <= 0)
        {
            _id = WebSiteContext.CurrentProjectID;
        }
        DataTable dt = APProjectManager.GetProjectInfoByID(_id);

        string jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void DeleteProject()
    {
        string id = HttpContext.Current.Request.Params["id"];
        int _id = 0;
        int.TryParse(id, out _id);
        string jsonResult = string.Empty;
        try
        {
            APProjectsDO apo = APProjectManager.GetProjectByID(_id);
            apo.Status = (int)Enums.DeleteStatus.删除;
            apo.DeleteFlag = true;
            apo.DeleteTime = DateTime.Now;
            BusinessLogicBase.Default.Update(apo);

            WebCommon.SendDeleteProjectNotice(_id, apo.CoreUserID, apo.Name);
            WebCommon.SendDeleteProjectNotice(_id, apo.PrimaryApplyUserID, apo.Name);
            WebCommon.SendDeleteProjectNotice(_id, apo.QCLeaderUserID, apo.Name);
            
            jsonResult = "1";
        }
        catch {
            jsonResult = "0";
        }
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetProjectTypes()
    {
        DataTable dt = BusinessConfigurationManager.GetDictListByDesc("ProjectType");
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