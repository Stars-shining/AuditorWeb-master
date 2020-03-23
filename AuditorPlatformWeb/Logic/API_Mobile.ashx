<%@ WebHandler Language="C#" Class="API_Mobile" %>

using System;
using System.Web;
using System.Web.SessionState;
using APLibrary;
using APLibrary.DataObject;
using System.Data;

public class API_Mobile : IHttpHandler, IRequiresSessionState
{
    public void ProcessRequest(HttpContext context) {
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
                    DoLogin();
                    break;
                case 2:
                    GetDeliveryListByUserID();
                    break;
                case 3:
                    GetQuestionsByQuestionnaireID();
                    break;
                case 4:
                    GetClientsByVisitUserID();
                    break;
                
                default:
                    break;
            }
        }
        catch { }
    }

    public void DoLogin()
    {
        string userName = HttpContext.Current.Request.Params["userName"];
        string password = HttpContext.Current.Request.Params["password"];

        APUsersDO userDO = APUserManager.TryLoginUser(userName, password);
        string userDisplayName = userDO.UserName;
        int userID = userDO.ID;
        string code = "0";
        string message = "";
        if (userDO != null && userDO.ID > 0)
        {
            //success

            if (userDO.Status == (int)Enums.UserStatus.停用)
            {
                code = "2";
                message = "账号已停用";
            }
            else
            {
                //record login client ip and time
                userDO.LastLoginIP = CommonFunction.GetHostAddress();
                userDO.LastLoginTime = DateTime.Now;
                BusinessLogicBase.Default.Update(userDO);

                code = "1";
                message = "验证成功";
            }
        }
        else
        {
            //failed
            code = "0";
            message = "用户名或密码错误";
        }
        string result = "{\"Code\":" + code + ",\"Message\":\"" + message + "\",\"Info\":{ \"UserID\": " + userID + ",\"UserName\":\"" + userDisplayName + "\"}}";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(result);
    }

    public void GetDeliveryListByUserID()
    {
        int userID = HttpContext.Current.Request.Params["userID"].ToInt(0);
        string code = "0";
        string message = "";
        string strDataResult = "[]";
        try
        {
            DataTable dt = APDeliveryManager.GetDeliveryByUserID(userID);
            strDataResult = JSONHelper.DataTableToJSON(dt);
            code = "1";
            message = "返回成功";
        }
        catch (Exception ex)
        {
            code = "0";
            message = "异常信息："+ex.ToString();
        }
        string result = "{\"Code\":" + code + ",\"Message\":\"" + message + "\",\"Result\":[" + strDataResult + "]}";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(result);
    }

    public void GetQuestionsByQuestionnaireID()
    {
        int questionnaireID = HttpContext.Current.Request.Params["questionnaireID"].ToInt(0);
        string code = "0";
        string message = "";
        string strInfo = "";
        string strDataResult = "[]";
        try
        {
            APQuestionnairesDO qdo = APQuestionnaireManager.GetQuestionnaireByID(questionnaireID);
            strInfo = JSONHelper.ObjectToJSON(qdo);
            DataSet ds = APQuestionManager.GetQuestionsByQuestionnaireID(questionnaireID);
            DataTable dtQuestions = ds.Tables[0];
            DataTable dtOptions = ds.Tables[1];
            string strQuestions = JSONHelper.DataTableToJSON(dtQuestions);
            string strOptions = JSONHelper.DataTableToJSON(dtOptions);
            strDataResult = "{ \"Questions\": [" + strQuestions + "], \"Options\": [" + strOptions + "]}";

            code = "1";
            message = "返回成功";
        }
        catch (Exception ex)
        {
            code = "0";
            message = "异常信息："+ex.ToString();
        }
        string result = "{\"Code\":" + code + ",\"Message\":\"" + message + "\",\"Info\": " + strInfo + ",\"Result\":" + strDataResult + "}";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(result);
    }

    public void GetClientsByVisitUserID()
    {
        int userID = HttpContext.Current.Request.Params["userID"].ToInt(0);
        string code = "0";
        string message = "";
        string strDataResult = "[]";
        try
        {
            DataTable dt = APDeliveryManager.GetDeliveryByUserID(userID);
            strDataResult = JSONHelper.DataTableToJSON(dt);
            code = "1";
            message = "返回成功";
        }
        catch (Exception ex)
        {
            code = "0";
            message = "异常信息："+ex.ToString();
        }
        string result = "{\"Code\":" + code + ",\"Message\":\"" + message + "\",\"Result\":[" + strDataResult + "]}";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(result);
    }

    public bool IsReusable {
        get {
            return false;
        }
    }

}