<%@ WebHandler Language="C#" Class="Messages" %>

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

public class Messages : IHttpHandler, IRequiresSessionState
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
                    SearchMessages();
                    break;
                case 2:
                    GetMessageInfo();
                    break;
                default: 
                    break;
            }
        }
        catch { }
    }

    public void GetMessageInfo()
    {
        string id = HttpContext.Current.Request.QueryString["id"];
        int msgID = 0;
        int.TryParse(id, out msgID);

        APMessageDO msgDO = APMessageManager.GetMessageByID(msgID);
        msgDO.Status = (int)Enums.MessageStatus.已读;
        BusinessLogicBase.Default.Update(msgDO);
        
        DataTable dt = APMessageManager.GetMessageInfo(msgID);
        string jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }
    
    public void SearchMessages()
    {
        string jsonResult = string.Empty;
        string name = HttpContext.Current.Request.QueryString["Name"];
        string period = HttpContext.Current.Request.QueryString["Period"];
        string status = HttpContext.Current.Request.QueryString["Status"];
        int _status = 0;
        int.TryParse(status, out _status);
        DateTime _fromDate = Constants.Date_Null;
        DateTime _toDate = Constants.Date_Max;
        if (period != "-999")
        {
            string fromDate = period.Split('|')[0];
            string toDate = period.Split('|')[1];
            DateTime.TryParse(fromDate, out  _fromDate);
            DateTime.TryParse(toDate, out _toDate);
            _toDate = _toDate.AddDays(1);
        }
        int acceptUserID = WebSiteContext.CurrentUserID;
        int projectID = WebSiteContext.CurrentProjectID;
        DataTable dt = APMessageManager.SearchMessages(acceptUserID, name, _fromDate, _toDate, _status, projectID);
        jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public bool IsReusable {
        get {
            return false;
        }
    }

}