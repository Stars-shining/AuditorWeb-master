<%@ WebHandler Language="C#" Class="Clients" %>

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

public class Clients : IHttpHandler, IRequiresSessionState
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
                    GetClientNodeList();
                    break;
                case 2:
                    GetClientNode();
                    break;
                case 3:
                    SubmitClientNode();
                    break;
                case 4:
                    DeleteClientNode();
                    break;
                case 5:
                    SubmitClientInfo();
                    break;
                case 6:
                    GetClientInfo();
                    break;
                case 7:
                    SearchClients();
                    break;
                case 8:
                    DeleteClientInfo();
                    break;
                case 9:
                    GetClientsByLevelID();
                    break;
                case 10:
                    GetClientGroup();
                    break;
                case 11:
                    GetSubClients();
                    break;
                case 12:
                    GetQuestionnaireResultClient();
                    break;
                case 13:
                    DownloadClients();
                    break;
                default: 
                    break;
            }
        }
        catch { }
    }

    public void GetQuestionnaireResultClient() 
    {
        string resultID = HttpContext.Current.Request.QueryString["resultID"];
        int _resultID = 0;
        int.TryParse(resultID, out _resultID);
        APClientsDO clientDO = new APClientsDO();
        APQuestionnaireResultsDO resultDO = APQuestionnaireManager.GetQuestionnaireResultDOByID(_resultID);
        if (resultDO != null) 
        {
            int clientID = resultDO.ClientID;
            clientDO = APClientManager.GetClientDOByID(clientID);
        }
        string jsonResult = JSONHelper.ObjectToJSON(clientDO);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetSubClients() 
    {
        int projectID = WebSiteContext.CurrentProjectID;
        string parentid = HttpContext.Current.Request.QueryString["parentID"];
        int _parentid = 0;
        int.TryParse(parentid, out _parentid);
        DataTable dt = APClientManager.GetSubClientsByParentID(_parentid, projectID);
        string jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetClientGroup() 
    {
        int projectID = WebSiteContext.CurrentProjectID;
        DataTable dt = APClientManager.GetClientListByProjectID(projectID);
        DataTable topClients = APClientManager.GetTopClients(projectID);
        
        string jsonResult = JSONHelper.DataTableToJSON(dt);
        string jsonClients = JSONHelper.DataTableToJSON(topClients);
        string result = "{\"Result\":" + jsonResult + ",\"Clients\":" + jsonClients + "}";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(result);
    }

    public void SearchClients() 
    {
        string name = HttpContext.Current.Request.QueryString["name"];
        string typeID = HttpContext.Current.Request.QueryString["typeID"];
        string province = HttpContext.Current.Request.QueryString["province"];
        string city = HttpContext.Current.Request.QueryString["city"];
        string district = HttpContext.Current.Request.QueryString["district"];

        int _typeID = 0;
        int.TryParse(typeID, out _typeID);
        int projectID = WebSiteContext.CurrentProjectID;
        
        DataTable dt = APClientManager.SearchClients(name, _typeID, province, city, district, projectID);
        string jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void DownloadClients() 
    {
        string name = HttpContext.Current.Request.QueryString["name"];
        string typeID = HttpContext.Current.Request.QueryString["typeID"];
        string province = HttpContext.Current.Request.QueryString["province"];
        string city = HttpContext.Current.Request.QueryString["city"];
        string district = HttpContext.Current.Request.QueryString["district"];

        int _typeID = 0;
        int.TryParse(typeID, out _typeID);
        int projectID = WebSiteContext.CurrentProjectID;

        DataTable dt = APClientManager.SearchClients(name, _typeID, province, city, district, projectID);
        //string jsonResult = JSONHelper.DataTableToJSON(dt);
        DataTable dtOutput = new DataTable();
        dtOutput.TableName = "机构列表";
        dtOutput.Columns.Add("编号", typeof(string));
        dtOutput.Columns.Add("名称", typeof(string));
        dtOutput.Columns.Add("类型", typeof(string));
        dtOutput.Columns.Add("省份", typeof(string));
        dtOutput.Columns.Add("城市", typeof(string));
        dtOutput.Columns.Add("区县", typeof(string));
        if (dt != null && dt.Rows.Count > 0)
        {
            foreach (DataRow row in dt.Rows)
            {
                DataRow newRow = dtOutput.NewRow();
                newRow["编号"] = row["ID"].ToString();
                newRow["名称"] = row["Name"].ToString();
                newRow["类型"] = row["TypeName"].ToString();
                newRow["省份"] = row["ProvinceName"].ToString();
                newRow["城市"] = row["CityName"].ToString();
                newRow["区县"] = row["DistrictName"].ToString();
                dtOutput.Rows.Add(newRow);
            }
        }

        DataSet ds = new DataSet();
        ds.Tables.Add(dtOutput.Copy());
        string fileName = string.Format("机构列表_{0:yyyyMMddHHmmss}.xlsx", DateTime.Now);
        string folderRelevantPath = Constants.RelevantTempPath;
        string folderPath = HttpContext.Current.Server.MapPath(folderRelevantPath);
        if (System.IO.Directory.Exists(folderPath) == false)
        {
            System.IO.Directory.CreateDirectory(folderPath);
        }
        string fileRelevantPath = folderRelevantPath + fileName;
        string filePath = folderPath.TrimEnd('\\') + "\\" + fileName;
        try
        {
            APLibrary.ParseExcel.CreateExcel(filePath, ds);
        }
        catch { }
        string result = "0";
        if (System.IO.File.Exists(filePath))
        {
            result = System.Web.VirtualPathUtility.ToAbsolute(fileRelevantPath);
        }
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(result);
    }

    public void GetClientNodeList()
    {
        int projectID = WebSiteContext.CurrentProjectID;
        DataTable dt = APClientManager.GetClientListByProjectID(projectID);
        string jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetClientNode()
    {
        string id = HttpContext.Current.Request.QueryString["id"];
        int _nodeID = 0;
        int.TryParse(id, out _nodeID);
        APClientStructureDO sdo = APClientManager.GetClientNodeByID(_nodeID);
        string jsonResult = JSONHelper.ObjectToJSON(sdo);
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void DeleteClientNode()
    {
        string id = HttpContext.Current.Request.Params["id"];
        int _nodeID = 0;
        int.TryParse(id, out _nodeID);
        APClientManager.DeleteClientStructure(_nodeID);
        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void SubmitClientNode()
    {
        string nodeID = HttpContext.Current.Request.Params["id"];
        string levelID = HttpContext.Current.Request.Params["levelID"];
        string name = HttpContext.Current.Request.Params["name"];
        
        int _nodeID = 0;
        int _levelID = 0;
        int.TryParse(nodeID, out _nodeID);
        int.TryParse(levelID, out _levelID);
        APClientStructureDO sdo = new APClientStructureDO();
        sdo.LevelID = _levelID;
        sdo.Name = name;
        sdo.ProjectID = WebSiteContext.CurrentProjectID;
        if (_nodeID > 0)
        {
            sdo.ID = _nodeID;
            BusinessLogicBase.Default.Update(sdo);
        }
        else
        {
            BusinessLogicBase.Default.Insert(sdo);
        }
        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void SubmitClientInfo()
    {
        string id = HttpContext.Current.Request.Params["id"];
        string code = HttpContext.Current.Request.Params["code"];
        string name = HttpContext.Current.Request.Params["name"];
        string typeID = HttpContext.Current.Request.Params["typeID"];
        string province = HttpContext.Current.Request.Params["province"];
        string city = HttpContext.Current.Request.Params["city"];
        string district = HttpContext.Current.Request.Params["district"];
        string address = HttpContext.Current.Request.Params["address"];
        string openingTime = HttpContext.Current.Request.Params["openingTime"];
        string parentid = HttpContext.Current.Request.Params["parentid"];
        string description = HttpContext.Current.Request.Params["description"];
        string locationCodeX = HttpContext.Current.Request.Params["locationCodeX"];
        string locationCodeY = HttpContext.Current.Request.Params["locationCodeY"];
        
        string email = HttpContext.Current.Request.Params["email"];
        string phoneNumber = HttpContext.Current.Request.Params["phoneNumber"];
        string postcode = HttpContext.Current.Request.Params["postcode"];

        int _id = 0;
        int _typeID = 0;
        int _parentID = 0;
        int.TryParse(id, out _id);
        int.TryParse(typeID, out _typeID);
        int.TryParse(parentid, out _parentID);

        APClientsDO cdo = new APClientsDO();

        if (_id > 0)
        {
            cdo = APClientManager.GetClientDOByID(_id);
        }        
        cdo.LevelID = _typeID;
        cdo.Name = name;
        cdo.Code = code;
        cdo.Province = province;
        cdo.City = city;
        cdo.District = district;
        cdo.Address = address;
        cdo.OpeningTime = openingTime;
        cdo.ParentID = _parentID;
        cdo.Description = description;
        cdo.LocationCodeX = locationCodeX;
        cdo.LocationCodeY = locationCodeY;
        cdo.ProjectID = WebSiteContext.CurrentProjectID;

        cdo.Email = email;
        cdo.PhoneNumber = phoneNumber;
        cdo.Postcode = postcode;
        
        if (_id > 0)
        {
            cdo.LastModifiedUserID = WebSiteContext.CurrentUserID;
            cdo.LastModifiedTime = DateTime.Now;
            BusinessLogicBase.Default.Update(cdo);

            APUsersDO clientUser = APUserManager.GetClientUserDO(_id, WebSiteContext.CurrentProjectID);
            if (clientUser != null)
            {
                clientUser.LoginName = code;
                clientUser.UserName = name;
                clientUser.Province = province;
                clientUser.City = city;
                clientUser.District = district;
                clientUser.Address = address;
                clientUser.Email = email;
                clientUser.Postcode = postcode;
                clientUser.Telephone = phoneNumber;
                clientUser.LastModifiedTime = DateTime.Now;
                clientUser.LastModifiedUserID = WebSiteContext.CurrentUserID;
                BusinessLogicBase.Default.Update(clientUser);
            }
        }
        else
        {
            cdo.CreateUserID = WebSiteContext.CurrentUserID;
            cdo.CreateTime = DateTime.Now;
            int clientID = BusinessLogicBase.Default.Insert(cdo);

            APUsersDO clientUser = new APUsersDO();
            clientUser.ClientID = clientID;
            clientUser.ProjectID = WebSiteContext.CurrentProjectID;
            clientUser.RoleID = (int)Enums.UserType.客户;
            clientUser.LoginName = code;
            clientUser.UserName = name;
            clientUser.Password = code;
            clientUser.CreateTime = DateTime.Now;
            clientUser.CreateUserID = WebSiteContext.CurrentUserID;
            clientUser.Province = province;
            clientUser.City = city;
            clientUser.District = district;
            clientUser.Address = address;
            clientUser.Email = email;
            clientUser.Postcode = postcode;
            clientUser.Telephone = phoneNumber;
            BusinessLogicBase.Default.Insert(clientUser);
        }
        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetClientInfo()
    {
        string id = HttpContext.Current.Request.QueryString["id"];
        int _id = 0;
        int.TryParse(id, out _id);
        APClientsDO sdo = APClientManager.GetClientDOByID(_id);
        string jsonResult = JSONHelper.ObjectToJSON(sdo);
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }
    
    public void DeleteClientInfo()
    {
        string ids = HttpContext.Current.Request.Params["ids"];
        string[] allids = ids.Split(',');
        foreach (string id in allids)
        {
            int _id = 0;
            int.TryParse(id, out _id);
            APClientManager.DeleteClient(_id);
            APUsersDO clientUser = APUserManager.GetClientUserDO(_id, WebSiteContext.CurrentProjectID);
            BusinessLogicBase.Default.Delete(clientUser);
        }      
        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetClientsByLevelID() 
    {
        string typeID = HttpContext.Current.Request.QueryString["typeID"];
        int _typeID = 0;
        int.TryParse(typeID, out _typeID);
        int projectID = WebSiteContext.CurrentProjectID;
        DataTable dt = APClientManager.GetClientsByLevelID(_typeID, projectID);
        string jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }
 
    public bool IsReusable {
        get {
            return false;
        }
    }

}