<%@ WebHandler Language="C#" Class="UserMenu" %>

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

public class UserMenu : IHttpHandler, IRequiresSessionState
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
                    GetUserMenusByCurrentUser();
                    break;
                case 2:
                    
                    break;
                default: 
                    break;
            }
        }
        catch { }
    }

    public void GetUserMenusByCurrentUser()
    {
        string jsonResult = string.Empty;
        string bIsInProject = HttpContext.Current.Request.QueryString["IsInProject"];
        bool _bIsInProject = false;
        bool.TryParse(bIsInProject, out _bIsInProject);
        int userType = WebSiteContext.Current.CurrentUser.RoleID;

        APUserRoleDO userRoleDO = APUserManager.GetUserRoleByID(userType);
        string menuPage = userRoleDO.MenuPage;
        if (_bIsInProject)
        {
            menuPage = userRoleDO.ProjectMenuPage;
            if (WebSiteContext.Current.CurrentUser.ClientID > 0) 
            {
                APClientsDO clientDO = APClientManager.GetClientDOByID(WebSiteContext.Current.CurrentUser.ClientID);
                int minLevelID = APClientManager.GetClientMinLevel(WebSiteContext.CurrentProjectID);
                if (clientDO.LevelID == minLevelID) 
                {
                    //总行账号
                    menuPage = "CommonProjectLeftClient2.htm";
                }
            }
        }
        
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(menuPage);
    }

    public void GetUserMenusByUserTypeID()
    {
        string jsonResult = string.Empty;
        string userTypeID = HttpContext.Current.Request.QueryString["userTypeID"];
        int _userTypeID = 0;
        int.TryParse(userTypeID, out _userTypeID);

        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }
 
    public bool IsReusable {
        get {
            return false;
        }
    }

}