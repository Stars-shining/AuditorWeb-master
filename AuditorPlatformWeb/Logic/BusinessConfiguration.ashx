<%@ WebHandler Language="C#" Class="BusinessConfiguration" %>

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

public class BusinessConfiguration : IHttpHandler, IRequiresSessionState
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
                    GetBusinessConfigValues();
                    break;
                case 2:
                    GetAreas();
                    break;
                case 3:
                    GetProvinces();
                    break;
                case 4:
                    GetCities();
                    break;
                case 5:
                    GetDistricts();
                    break;
                case 6:
                    GetQuestionnaireStageStatus();
                    break;
                case 7:
                    GetClientAppealStatus();
                    break;
                case 8:
                    GetBusinessConfigValue();
                    break;
                default: 
                    break;
            }
        }
        catch { }
    }

    public void GetClientAppealStatus() 
    {
        DataTable dt = APClientManager.GetClientAppealStatus(WebSiteContext.CurrentProjectID);
        string jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetQuestionnaireStageStatus() 
    {
        string jsonResult = string.Empty;
        DataTable dt = BusinessConfigurationManager.GetDictListByDesc("QuestionnaireStageStatus");
        DataView dv = dt.DefaultView;
        dv.Sort = "ItemOrder asc";
        dt = dv.ToTable();
        jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }
    
    /// <summary>
    /// get config values by item desc 
    /// </summary>
    public void GetBusinessConfigValues()
    {
        string jsonResult = string.Empty;
        string name = HttpContext.Current.Request.QueryString["name"];
        DataTable dt = BusinessConfigurationManager.GetDictListByDesc(name);
        jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }

    /// <summary>
    /// get config value by key name 
    /// </summary>
    public void GetBusinessConfigValue()
    {
        string jsonResult = string.Empty;
        string name = HttpContext.Current.Request.QueryString["name"];
        string key = HttpContext.Current.Request.QueryString["key"];
        int _key = 0;
        int.TryParse(key, out _key);
        string value = BusinessConfigurationManager.GetItemValueByItemKey(_key, name);
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(value);
    }

    public void GetAreas()
    {
        DataTable dt = BusinessConfigurationManager.GetDictListByDesc("AreaDivision");
        APUsersDO userDO = WebSiteContext.Current.CurrentUser;
        if (userDO != null && userDO.AreaID >0)
        {
            DataView dv = dt.DefaultView;
            dv.RowFilter = "ID='" + userDO.AreaID + "'";
            dt = dv.ToTable();
        }
        string jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }
    
    public void GetProvinces() 
    {
        string jsonResult = string.Empty;
        string areaID = HttpContext.Current.Request.QueryString["areaID"];
        int _areaID = 0;
        int.TryParse(areaID, out _areaID);
        APUsersDO userDO = WebSiteContext.Current.CurrentUser;
        if (_areaID <= 0) {
            if (userDO != null && userDO.AreaID > 0)
            {
                _areaID = userDO.AreaID;
            }
        }
        DataTable dt = BusinessConfigurationManager.GetProvinces(_areaID);

        if (userDO != null && !string.IsNullOrEmpty(userDO.Province) && userDO.Province != "-999")
        {
            DataView dv = dt.DefaultView;
            dv.RowFilter = "code='" + userDO.Province + "'";
            dt = dv.ToTable();
        }
        jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetCities()
    {
        string provinceCode = HttpContext.Current.Request.QueryString["provinceCode"];
        DataTable dt = BusinessConfigurationManager.GetCities(provinceCode);
        string jsonResult = JSONHelper.DataTableToJSON(dt);
        APUsersDO userDO = WebSiteContext.Current.CurrentUser;
        if (userDO != null && !string.IsNullOrEmpty(userDO.City) && userDO.City != "-999")
        {
            DataView dv = dt.DefaultView;
            dv.RowFilter = "code='" + userDO.City + "'";
            dt = dv.ToTable();
        }
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetDistricts()
    {
        string cityCode = HttpContext.Current.Request.QueryString["cityCode"];
        DataTable dt = BusinessConfigurationManager.GetDistricts(cityCode);
        string jsonResult = JSONHelper.DataTableToJSON(dt);
        APUsersDO userDO = WebSiteContext.Current.CurrentUser;
        if (userDO != null && !string.IsNullOrEmpty(userDO.District) && userDO.District != "-999")
        {
            DataView dv = dt.DefaultView;
            dv.RowFilter = "code='" + userDO.District + "'";
            dt = dv.ToTable();
        }
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }
    
    public bool IsReusable {
        get {
            return false;
        }
    }

}