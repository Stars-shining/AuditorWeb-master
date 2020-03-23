using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using APLibrary.DataObject;
using APLibrary;
using APLibrary.Utility;
using System.Drawing;
using System.IO;
using System.Drawing.Imaging;
using System.Threading;

/// <summary>
///WebCommon 的摘要说明
/// </summary>
public class WebCommon
{
	public WebCommon()
	{
		//
		//TODO: 在此处添加构造函数逻辑
		//
	}

    public static void SendCreateProjectNotice(int relatedID, int acceptUserID, string name)
    {
        string relatedUrl = "http://" + HttpContext.Current.Request.Url.Host + ":" + HttpContext.Current.Request.Url.Port + HttpContext.Current.Request.ApplicationPath + "/Pages/ProjectInfo.htm?st=1&id=" + relatedID;
        APMessageDO msgDO = new APMessageDO();
        msgDO.RelatedID = relatedID;
        msgDO.RelatedUrl = relatedUrl;
        msgDO.Title = "建项通知 - 已创建项目:" + name;
        msgDO.Content = "已创建新项目: " + name + "，请查看相关信息。";
        msgDO.CreateTime = DateTime.Now;
        msgDO.CreateUserID = WebSiteContext.CurrentUserID;
        msgDO.FromUserID = -1;
        msgDO.TypeID = (int)Enums.MessageType.建项通知;
        msgDO.AcceptUserID = acceptUserID;
        msgDO.Status = (int)Enums.MessageStatus.未读;
        BusinessLogicBase.Default.Insert(msgDO);
        APMessageManager.SendMessageViaEmail(msgDO);
    }

    public static void SendDeleteProjectNotice(int relatedID, int acceptUserID, string name)
    {
        APMessageDO msgDO = new APMessageDO();
        msgDO.RelatedID = relatedID;
        msgDO.RelatedUrl = "";
        msgDO.Title = "删除通知 - 已删除项目:" + name;
        msgDO.Content = "已删除项目: " + name + "，请知悉。";
        msgDO.CreateTime = DateTime.Now;
        msgDO.CreateUserID = WebSiteContext.CurrentUserID;
        msgDO.FromUserID = -1;
        msgDO.TypeID = (int)Enums.MessageType.删除通知;
        msgDO.AcceptUserID = acceptUserID;
        msgDO.Status = (int)Enums.MessageStatus.未读;
        BusinessLogicBase.Default.Insert(msgDO);
        APMessageManager.SendMessageViaEmail(msgDO);
    }

    public static void SendVisitDeliveryNotice(int projectID, int questionnaireID,int clientID, int acceptUserID, DateTime fromDate, DateTime toDate, int typeID)
    {
        APClientsDO clientDO = APClientManager.GetClientDOByID(clientID);
        string clientName = clientDO.Name;
        APQuestionnairesDO questionnaireDO = APQuestionnaireManager.GetQuestionnaireByID(questionnaireID);
        string questionnaireName = questionnaireDO.Name;

        string title = "任务通知 - 执行核查任务";
        string content = "核查对象：" + clientName;
        content += "<br/>执行问卷：" + questionnaireName;
        content += "<br/>执行周期：" + fromDate.ToString("yyyy年MM月dd日") + " - " + toDate.ToString("yyyy年MM月dd日");
        string relatedUrl = string.Empty;
        int taskTypeID = (int)Enums.MessageType.任务通知;
        if (typeID == 2)
        {
            content += "<br/>任务内容：负责该机构下所有子机构的执行分配和审核修改工作。";
            relatedUrl = "QuestionnairePL2.htm";
        }
        else if (typeID == 3)
        {
            content += "<br/>任务内容：负责该机构下所有子机构的执行分配和审核修改工作。";
            relatedUrl = "QuestionnairePL3.htm";
        }
        else if (typeID == 4)
        {
            content += "<br/>任务内容：负责该机构的访问核查和问卷上传工作。";
            relatedUrl = "QuestionnaireUL.htm";
        }
        else if (typeID == 6)
        {
            content += "<br/>任务内容：负责该机构的质量审核工作。";
            relatedUrl = "QuestionnaireCheckList.htm";
        }
        string fullUrl = "http://" + HttpContext.Current.Request.Url.Host + ":" +
                                        HttpContext.Current.Request.Url.Port +
                                        HttpContext.Current.Request.ApplicationPath + "/Pages/" + relatedUrl + "?returnProjectID=" + projectID;
        APMessageDO msgDO = new APMessageDO();
        msgDO.RelatedID = clientID;
        msgDO.ProjectID = projectID;
        msgDO.RelatedUrl = fullUrl;
        msgDO.Title = title;
        msgDO.Content = content;
        msgDO.CreateTime = DateTime.Now;
        msgDO.CreateUserID = WebSiteContext.CurrentUserID;
        msgDO.FromUserID = -1;
        msgDO.TypeID = taskTypeID;
        msgDO.AcceptUserID = acceptUserID;
        msgDO.Status = (int)Enums.MessageStatus.未读;
        BusinessLogicBase.Default.Insert(msgDO);
        APMessageManager.SendMessageViaEmail(msgDO);
    }

    public static void SendCancelDeliveryNotice(int projectID, int questionnaireID, int clientID, int acceptUserID, DateTime fromDate, DateTime toDate, int typeID)
    {
        APClientsDO clientDO = APClientManager.GetClientDOByID(clientID);
        string clientName = clientDO.Name;
        APQuestionnairesDO questionnaireDO = APQuestionnaireManager.GetQuestionnaireByID(questionnaireID);
        string questionnaireName = questionnaireDO.Name;

        string title = "取消任务通知 - 取消执行核查任务";
        string content = "核查对象：" + clientName;
        content += "<br/>执行问卷：" + questionnaireName;
        content += "<br/>执行周期：" + fromDate.ToString("yyyy年MM月dd日") + " - " + toDate.ToString("yyyy年MM月dd日");
        string relatedUrl = string.Empty;
        if (typeID == 2)
        {
            content += "<br/>任务内容：负责该机构下所有子机构的执行分配和审核修改工作。任务已取消。";
            relatedUrl = "QuestionnairePL2.htm";
        }
        else if (typeID == 3)
        {
            content += "<br/>任务内容：负责该机构下所有子机构的执行分配和审核修改工作。任务已取消。";
            relatedUrl = "QuestionnairePL3.htm";
        }
        else if (typeID == 4)
        {
            content += "<br/>任务内容：负责该机构的访问核查和问卷上传工作。任务已取消。";
            relatedUrl = "QuestionnaireUL.htm";
        }
        else if (typeID == 6)
        {
            content += "<br/>任务内容：负责该机构的质量审核工作。任务已取消。";
            relatedUrl = "QuestionnaireCheckList.htm";
        }
        string fullUrl = "http://" + HttpContext.Current.Request.Url.Host + ":" +
                                        HttpContext.Current.Request.Url.Port +
                                        HttpContext.Current.Request.ApplicationPath + "/Pages/" + relatedUrl + "?returnProjectID=" + projectID;
        APMessageDO msgDO = new APMessageDO();
        msgDO.RelatedID = clientID;
        msgDO.ProjectID = projectID;
        msgDO.RelatedUrl = fullUrl;
        msgDO.Title = title;
        msgDO.Content = content;
        msgDO.CreateTime = DateTime.Now;
        msgDO.CreateUserID = WebSiteContext.CurrentUserID;
        msgDO.FromUserID = -1;
        msgDO.TypeID = (int)Enums.MessageType.任务通知;
        msgDO.AcceptUserID = acceptUserID;
        msgDO.Status = (int)Enums.MessageStatus.未读;
        BusinessLogicBase.Default.Insert(msgDO);
        APMessageManager.SendMessageViaEmail(msgDO);
    }

    public static void SendAuditNotice(APQuestionnaireResultsDO resultDO, int typeID, int auditType)
    {
        int resultID = resultDO.ID;
        int projectID = WebSiteContext.CurrentProjectID;
        int questionnaireID = resultDO.QuestionnaireID;
        DateTime fromDate = resultDO.FromDate;
        DateTime toDate = resultDO.ToDate;
        int clientID = resultDO.ClientID;

        APClientsDO clientDO = APClientManager.GetClientDOByID(clientID);
        string clientName = clientDO.Name;
        APQuestionnairesDO questionnaireDO = APQuestionnaireManager.GetQuestionnaireByID(questionnaireID);
        string questionnaireName = questionnaireDO.Name;
        int acceptUserID = 0;
        if (auditType == (int)Enums.QuestionnaireAuditType.质控督导审核)
        {
            acceptUserID = WebSiteContext.Current.CurrentProject.QCLeaderUserID;
        }
        else
        {
            acceptUserID = APQuestionnaireManager.GetNextAuditUserID(projectID, questionnaireID, fromDate, toDate, typeID, clientID);
        }
        string title = "审核通知 - 您有一份新问卷需要审核";
        string content = "核查对象：" + clientName;
        content += "<br/>执行问卷：" + questionnaireName;
        content += "<br/>执行周期：" + fromDate.ToString("yyyy年MM月dd日") + " - " + toDate.ToString("yyyy年MM月dd日");
        content += "<br/>任务内容：审核或修改。";
        string relatedUrl = "http://" + HttpContext.Current.Request.Url.Host + ":"
            + HttpContext.Current.Request.Url.Port
            + HttpContext.Current.Request.ApplicationPath
            + "/Pages/QuestionnaireAuditing.htm?returnProjectID=" + projectID + "&resultID=" + CommonFunction.EncodeBase64(resultID.ToString(), 5) + "&auditType=" + CommonFunction.EncodeBase64(auditType.ToString(), 5);
        APMessageDO msgDO = new APMessageDO();
        msgDO.RelatedID = resultID;
        msgDO.ProjectID = projectID;
        msgDO.RelatedUrl = relatedUrl;
        msgDO.Title = title;
        msgDO.Content = content;
        msgDO.CreateTime = DateTime.Now;
        msgDO.CreateUserID = WebSiteContext.CurrentUserID;
        msgDO.FromUserID = -1;
        msgDO.TypeID = (int)Enums.MessageType.审核通知;
        msgDO.AcceptUserID = acceptUserID;
        msgDO.Status = (int)Enums.MessageStatus.未读;
        BusinessLogicBase.Default.Insert(msgDO);
        APMessageManager.SendMessageViaEmail(msgDO);
    }

    public static void SendAuditRejectNoticeVisitor(APQuestionnaireResultsDO resultDO, int acceptUserID, string auditNote)
    {
        int resultID = resultDO.ID;
        int projectID = WebSiteContext.CurrentProjectID;
        int questionnaireID = resultDO.QuestionnaireID;
        DateTime fromDate = resultDO.FromDate;
        DateTime toDate = resultDO.ToDate;
        int clientID = resultDO.ClientID;

        APClientsDO clientDO = APClientManager.GetClientDOByID(clientID);
        string clientName = clientDO.Name;
        APQuestionnairesDO questionnaireDO = APQuestionnaireManager.GetQuestionnaireByID(questionnaireID);
        string questionnaireName = questionnaireDO.Name;

        string title = "审核通知 - 您有一份问卷审核不通过，请重新审核或修改";
        string content = "核查对象：" + clientName;
        content += "<br/>执行问卷：" + questionnaireName;
        content += "<br/>执行周期：" + fromDate.ToString("yyyy年MM月dd日") + " - " + toDate.ToString("yyyy年MM月dd日");
        content += "<br/>审核批注：" + auditNote;
        content += "<br/>任务内容：审核或修改";
        string relatedUrl = "http://" + HttpContext.Current.Request.Url.Host + ":"
            + HttpContext.Current.Request.Url.Port
            + HttpContext.Current.Request.ApplicationPath
            + "/Pages/QuestionnaireEditing.htm?returnProjectID=" + projectID + "&resultID=" + CommonFunction.EncodeBase64(resultID.ToString(), 5);
        APMessageDO msgDO = new APMessageDO();
        msgDO.RelatedID = resultID;
        msgDO.ProjectID = projectID;
        msgDO.RelatedUrl = relatedUrl;
        msgDO.Title = title;
        msgDO.Content = content;
        msgDO.CreateTime = DateTime.Now;
        msgDO.CreateUserID = WebSiteContext.CurrentUserID;
        msgDO.FromUserID = -1;
        msgDO.TypeID = (int)Enums.MessageType.审核通知;
        msgDO.AcceptUserID = acceptUserID;
        msgDO.Status = (int)Enums.MessageStatus.未读;
        BusinessLogicBase.Default.Insert(msgDO);
        APMessageManager.SendMessageViaEmail(msgDO);
    }

    public static void SendAuditRejectNotice(APQuestionnaireResultsDO resultDO, int acceptUserID, int auditType, string auditNote)
    {
        int resultID = resultDO.ID;
        int projectID = WebSiteContext.CurrentProjectID;
        int questionnaireID = resultDO.QuestionnaireID;
        DateTime fromDate = resultDO.FromDate;
        DateTime toDate = resultDO.ToDate;
        int clientID = resultDO.ClientID;

        APClientsDO clientDO = APClientManager.GetClientDOByID(clientID);
        string clientName = clientDO.Name;
        APQuestionnairesDO questionnaireDO = APQuestionnaireManager.GetQuestionnaireByID(questionnaireID);
        string questionnaireName = questionnaireDO.Name;

        string title = "审核通知 - 您有一份问卷审核不通过，请重新审核或修改";
        string content = "核查对象：" + clientName;
        content += "<br/>执行问卷：" + questionnaireName;
        content += "<br/>执行周期：" + fromDate.ToString("yyyy年MM月dd日") + " - " + toDate.ToString("yyyy年MM月dd日");
        content += "<br/>审核批注：" + auditNote;
        content += "<br/>任务内容：审核或修改。";
        string relatedUrl = "http://" + HttpContext.Current.Request.Url.Host + ":"
            + HttpContext.Current.Request.Url.Port
            + HttpContext.Current.Request.ApplicationPath
            + "/Pages/QuestionnaireAuditing.htm?returnProjectID=" + projectID + "&resultID=" + CommonFunction.EncodeBase64(resultID.ToString(), 5) + "&auditType=" + CommonFunction.EncodeBase64(auditType.ToString(), 5);
        APMessageDO msgDO = new APMessageDO();
        msgDO.RelatedID = resultID;
        msgDO.ProjectID = projectID;
        msgDO.RelatedUrl = relatedUrl;
        msgDO.Title = title;
        msgDO.Content = content;
        msgDO.CreateTime = DateTime.Now;
        msgDO.CreateUserID = WebSiteContext.CurrentUserID;
        msgDO.FromUserID = -1;
        msgDO.TypeID = (int)Enums.MessageType.审核通知;
        msgDO.AcceptUserID = acceptUserID;
        msgDO.Status = (int)Enums.MessageStatus.未读;
        BusinessLogicBase.Default.Insert(msgDO);
        APMessageManager.SendMessageViaEmail(msgDO);
    }

    public static void SendAppealStartNotice(APQuestionnaireResultsDO resultDO,int acceptUserID, int auditType)
    {
        int resultID = resultDO.ID;
        int projectID = WebSiteContext.CurrentProjectID;
        int questionnaireID = resultDO.QuestionnaireID;
        DateTime fromDate = resultDO.FromDate;
        DateTime toDate = resultDO.ToDate;
        int clientID = resultDO.ClientID;

        APClientsDO clientDO = APClientManager.GetClientDOByID(clientID);
        string clientName = clientDO.Name;
        APQuestionnairesDO questionnaireDO = APQuestionnaireManager.GetQuestionnaireByID(questionnaireID);
        string questionnaireName = questionnaireDO.Name;

        string title = "申诉通知 - 您的门店已进入申诉状态，如有异议请尽快提交申诉";
        string content = "门店名称：" + clientName;
        content += "<br/>执行问卷：" + questionnaireName;
        content += "<br/>执行周期：" + fromDate.ToString("yyyy年MM月dd日") + " - " + toDate.ToString("yyyy年MM月dd日");
        string relatedUrl = "http://" + HttpContext.Current.Request.Url.Host + ":"
            + HttpContext.Current.Request.Url.Port
            + HttpContext.Current.Request.ApplicationPath
            + "/Pages/CLogin.htm?g="+ WebSiteContext.Current.CurrentProject.GroupID;
        APMessageDO msgDO = new APMessageDO();
        msgDO.RelatedID = resultID;
        msgDO.ProjectID = projectID;
        msgDO.RelatedUrl = relatedUrl;
        msgDO.Title = title;
        msgDO.Content = content;
        msgDO.CreateTime = DateTime.Now;
        msgDO.CreateUserID = WebSiteContext.CurrentUserID;
        msgDO.FromUserID = -1;
        msgDO.TypeID = (int)Enums.MessageType.申诉通知;
        msgDO.AcceptUserID = acceptUserID;
        msgDO.Status = (int)Enums.MessageStatus.未读;
        BusinessLogicBase.Default.Insert(msgDO);
        APMessageManager.SendMessageViaEmail(msgDO);
    }

    public static void SendAppealAuditNotice(APQuestionnaireResultsDO resultDO, int acceptUserID, int auditType)
    {
        int resultID = resultDO.ID;
        int projectID = WebSiteContext.CurrentProjectID;
        int questionnaireID = resultDO.QuestionnaireID;
        DateTime fromDate = resultDO.FromDate;
        DateTime toDate = resultDO.ToDate;
        int clientID = resultDO.ClientID;

        APClientsDO clientDO = APClientManager.GetClientDOByID(clientID);
        string clientName = clientDO.Name;
        APQuestionnairesDO questionnaireDO = APQuestionnaireManager.GetQuestionnaireByID(questionnaireID);
        string questionnaireName = questionnaireDO.Name;

        string title = "申诉审核通知 - 您的下属机构已提交申诉，请您尽快审核";
        string content = "门店名称：" + clientName;
        content += "<br/>执行问卷：" + questionnaireName;
        content += "<br/>执行周期：" + fromDate.ToString("yyyy年MM月dd日") + " - " + toDate.ToString("yyyy年MM月dd日");
        string relatedUrl = "http://" + HttpContext.Current.Request.Url.Host + ":"
            + HttpContext.Current.Request.Url.Port
            + HttpContext.Current.Request.ApplicationPath
            + "/Pages/CLogin.htm?g=" + WebSiteContext.Current.CurrentProject.GroupID;
        APMessageDO msgDO = new APMessageDO();
        msgDO.RelatedID = resultID;
        msgDO.ProjectID = projectID;
        msgDO.RelatedUrl = relatedUrl;
        msgDO.Title = title;
        msgDO.Content = content;
        msgDO.CreateTime = DateTime.Now;
        msgDO.CreateUserID = WebSiteContext.CurrentUserID;
        msgDO.FromUserID = -1;
        msgDO.TypeID = (int)Enums.MessageType.审核通知;
        msgDO.AcceptUserID = acceptUserID;
        msgDO.Status = (int)Enums.MessageStatus.未读;
        BusinessLogicBase.Default.Insert(msgDO);
        APMessageManager.SendMessageViaEmail(msgDO);
    }

    public static void SendAppealRejectNotice(APQuestionnaireResultsDO resultDO, int acceptUserID, int auditType, string auditNote)
    {
        int resultID = resultDO.ID;
        int projectID = WebSiteContext.CurrentProjectID;
        int questionnaireID = resultDO.QuestionnaireID;
        DateTime fromDate = resultDO.FromDate;
        DateTime toDate = resultDO.ToDate;
        int clientID = resultDO.ClientID;

        APClientsDO clientDO = APClientManager.GetClientDOByID(clientID);
        string clientName = clientDO.Name;
        APQuestionnairesDO questionnaireDO = APQuestionnaireManager.GetQuestionnaireByID(questionnaireID);
        string questionnaireName = questionnaireDO.Name;

        string title = "申诉审核通知 - 您的申诉未通过上级审核";
        string content = "门店名称：" + clientName;
        content += "<br/>执行问卷：" + questionnaireName;
        content += "<br/>执行周期：" + fromDate.ToString("yyyy年MM月dd日") + " - " + toDate.ToString("yyyy年MM月dd日");
        content += "<br/>审核批注：" + auditNote;
        string relatedUrl = "http://" + HttpContext.Current.Request.Url.Host + ":"
            + HttpContext.Current.Request.Url.Port
            + HttpContext.Current.Request.ApplicationPath
             + "/Pages/CLogin.htm?g=" + WebSiteContext.Current.CurrentProject.GroupID;
        APMessageDO msgDO = new APMessageDO();
        msgDO.RelatedID = resultID;
        msgDO.ProjectID = projectID;
        msgDO.RelatedUrl = relatedUrl;
        msgDO.Title = title;
        msgDO.Content = content;
        msgDO.CreateTime = DateTime.Now;
        msgDO.CreateUserID = WebSiteContext.CurrentUserID;
        msgDO.FromUserID = -1;
        msgDO.TypeID = (int)Enums.MessageType.审核通知;
        msgDO.AcceptUserID = acceptUserID;
        msgDO.Status = (int)Enums.MessageStatus.未读;
        BusinessLogicBase.Default.Insert(msgDO);
        APMessageManager.SendMessageViaEmail(msgDO);
    }

    public static void SendAppealFinalNotice(APQuestionnaireResultsDO resultDO, int acceptUserID, int auditType)
    {
        int resultID = resultDO.ID;
        int projectID = WebSiteContext.CurrentProjectID;
        int questionnaireID = resultDO.QuestionnaireID;
        DateTime fromDate = resultDO.FromDate;
        DateTime toDate = resultDO.ToDate;
        int clientID = resultDO.ClientID;

        APClientsDO clientDO = APClientManager.GetClientDOByID(clientID);
        string clientName = clientDO.Name;
        APQuestionnairesDO questionnaireDO = APQuestionnaireManager.GetQuestionnaireByID(questionnaireID);
        string questionnaireName = questionnaireDO.Name;

        string title = "申诉通知 - 客户已提交申诉并已经过其上级最终审核";
        string content = "门店名称：" + clientName;
        content += "<br/>执行问卷：" + questionnaireName;
        content += "<br/>执行周期：" + fromDate.ToString("yyyy年MM月dd日") + " - " + toDate.ToString("yyyy年MM月dd日");
        content += "<br/>任务内容：审核裁定或修改。";
        string relatedUrl = "http://" + HttpContext.Current.Request.Url.Host + ":"
            + HttpContext.Current.Request.Url.Port
            + HttpContext.Current.Request.ApplicationPath
            + "/Pages/QuestionnaireClient.htm?returnProjectID=" + projectID + "&resultID=" + CommonFunction.EncodeBase64(resultID.ToString(), 5) + "&auditType=" + CommonFunction.EncodeBase64(auditType.ToString(), 5);
        APMessageDO msgDO = new APMessageDO();
        msgDO.RelatedID = resultID;
        msgDO.ProjectID = projectID;
        msgDO.RelatedUrl = relatedUrl;
        msgDO.Title = title;
        msgDO.Content = content;
        msgDO.CreateTime = DateTime.Now;
        msgDO.CreateUserID = WebSiteContext.CurrentUserID;
        msgDO.FromUserID = -1;
        msgDO.TypeID = (int)Enums.MessageType.申诉通知;
        msgDO.AcceptUserID = acceptUserID;
        msgDO.Status = (int)Enums.MessageStatus.未读;
        BusinessLogicBase.Default.Insert(msgDO);
        APMessageManager.SendMessageViaEmail(msgDO);
    }

    public static void SendAppealFinishNotice(APQuestionnaireResultsDO resultDO, int auditType, string result, string auditNote)
    {
        int resultID = resultDO.ID;
        int projectID = WebSiteContext.CurrentProjectID;
        int questionnaireID = resultDO.QuestionnaireID;
        DateTime fromDate = resultDO.FromDate;
        DateTime toDate = resultDO.ToDate;
        int clientID = resultDO.ClientID;

        APClientsDO clientDO = APClientManager.GetClientDOByID(clientID);
        APUsersDO userDO = APUserManager.GetClientUserDO(clientID, projectID);
        int clientUserID = userDO.ID;
        string clientName = clientDO.Name;
        APQuestionnairesDO questionnaireDO = APQuestionnaireManager.GetQuestionnaireByID(questionnaireID);
        string questionnaireName = questionnaireDO.Name;

        string title = "申诉裁定结果 - 您的门店申诉已处理";
        string content = "门店名称：" + clientName;
        content += "<br/>执行问卷：" + questionnaireName;
        content += "<br/>执行周期：" + fromDate.ToString("yyyy年MM月dd日") + " - " + toDate.ToString("yyyy年MM月dd日");
        content += "<br/>裁定结果：" + result;
        content += "<br/>裁定依据：" + auditNote;
        string relatedUrl = "http://" + HttpContext.Current.Request.Url.Host + ":"
            + HttpContext.Current.Request.Url.Port
            + HttpContext.Current.Request.ApplicationPath
             + "/Pages/CLogin.htm?g=" + WebSiteContext.Current.CurrentProject.GroupID;
        APMessageDO msgDO = new APMessageDO();
        msgDO.RelatedID = resultID;
        msgDO.ProjectID = projectID;
        msgDO.RelatedUrl = relatedUrl;
        msgDO.Title = title;
        msgDO.Content = content;
        msgDO.CreateTime = DateTime.Now;
        msgDO.CreateUserID = WebSiteContext.CurrentUserID;
        msgDO.FromUserID = -1;
        msgDO.TypeID = (int)Enums.MessageType.申诉裁定;
        msgDO.AcceptUserID = clientUserID;
        msgDO.Status = (int)Enums.MessageStatus.未读;
        BusinessLogicBase.Default.Insert(msgDO);
        APMessageManager.SendMessageViaEmail(msgDO);
    }

    public static void SendAppealCloseNotice(APQuestionnaireResultsDO resultDO, int auditType)
    {
        int resultID = resultDO.ID;
        int projectID = WebSiteContext.CurrentProjectID;
        int questionnaireID = resultDO.QuestionnaireID;
        DateTime fromDate = resultDO.FromDate;
        DateTime toDate = resultDO.ToDate;
        int clientID = resultDO.ClientID;

        APClientsDO clientDO = APClientManager.GetClientDOByID(clientID);
        APUsersDO userDO = APUserManager.GetClientUserDO(clientID, projectID);
        int clientUserID = userDO.ID;
        string clientName = clientDO.Name;
        APQuestionnairesDO questionnaireDO = APQuestionnaireManager.GetQuestionnaireByID(questionnaireID);
        string questionnaireName = questionnaireDO.Name;

        string title = "申诉关闭通知 - 您的门店申诉已关闭";
        string content = "门店名称：" + clientName;
        content += "<br/>执行问卷：" + questionnaireName;
        content += "<br/>执行周期：" + fromDate.ToString("yyyy年MM月dd日") + " - " + toDate.ToString("yyyy年MM月dd日");
        string relatedUrl = "http://" + HttpContext.Current.Request.Url.Host + ":"
            + HttpContext.Current.Request.Url.Port
            + HttpContext.Current.Request.ApplicationPath
             + "/Pages/CLogin.htm?g=" + WebSiteContext.Current.CurrentProject.GroupID;
        APMessageDO msgDO = new APMessageDO();
        msgDO.RelatedID = resultID;
        msgDO.ProjectID = projectID;
        msgDO.RelatedUrl = relatedUrl;
        msgDO.Title = title;
        msgDO.Content = content;
        msgDO.CreateTime = DateTime.Now;
        msgDO.CreateUserID = WebSiteContext.CurrentUserID;
        msgDO.FromUserID = -1;
        msgDO.TypeID = (int)Enums.MessageType.申诉关闭;
        msgDO.AcceptUserID = clientUserID;
        msgDO.Status = (int)Enums.MessageStatus.未读;
        BusinessLogicBase.Default.Insert(msgDO);
        APMessageManager.SendMessageViaEmail(msgDO);
    }

    /// <summary>
    /// 生成缩略图
    /// </summary>
    /// <param name="originalImagePath">源图路径（物理路径）</param>
    /// <param name="thumbnailPath">缩略图路径（物理路径）</param>
    /// <param name="width">缩略图宽度</param>
    /// <param name="height">缩略图高度</param>
    /// <param name="mode">生成缩略图的方式</param>    
    public static void MakeThumbnail(string originalImagePath, string thumbnailPath, int width, int height, string mode)
    {
        Image originalImage = Image.FromFile(originalImagePath);

        int towidth = width;
        int toheight = height;

        int x = 0;
        int y = 0;
        int ow = originalImage.Width;
        int oh = originalImage.Height;

        if (string.IsNullOrEmpty(mode))
        {
            if (ow > oh)
            {
                mode = "W";
            }
            else
            {
                mode = "H";
            }
        }

        switch (mode)
        {
            case "HW"://指定高宽缩放（可能变形）                
                break;
            case "W"://指定宽，高按比例                    
                toheight = originalImage.Height * width / originalImage.Width;
                break;
            case "H"://指定高，宽按比例
                towidth = originalImage.Width * height / originalImage.Height;
                break;
            case "Cut"://指定高宽裁减（不变形）                
                if ((double)originalImage.Width / (double)originalImage.Height > (double)towidth / (double)toheight)
                {
                    oh = originalImage.Height;
                    ow = originalImage.Height * towidth / toheight;
                    y = 0;
                    x = (originalImage.Width - ow) / 2;
                }
                else
                {
                    ow = originalImage.Width;
                    oh = originalImage.Width * height / towidth;
                    x = 0;
                    y = (originalImage.Height - oh) / 2;
                }
                break;
            default:
                break;
        }

        //新建一个bmp图片
        Image bitmap = new System.Drawing.Bitmap(towidth, toheight);
        //新建一个画板
        Graphics g = System.Drawing.Graphics.FromImage(bitmap);
        try
        {
            //设置高质量插值法
            g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.High;

            //设置高质量,低速度呈现平滑程度
            g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.HighQuality;

            //清空画布并以透明背景色填充
            g.Clear(Color.Transparent);

            //在指定位置并且按指定大小绘制原图片的指定部分
            g.DrawImage(originalImage, new Rectangle(0, 0, towidth, toheight),
                new Rectangle(x, y, ow, oh),
                GraphicsUnit.Pixel);

            //以jpg格式保存缩略图
            bitmap.Save(thumbnailPath, System.Drawing.Imaging.ImageFormat.Jpeg);
        }
        catch (System.Exception e)
        {
            throw e;
        }
        finally
        {
            originalImage.Dispose();
            bitmap.Dispose();
            g.Dispose();
        }
    }


    public static void GetVideoInfo(string sourceFile, ref string duration, ref string videoCode, ref string audioCode)
    {
        try
        {
            string ffmpegfile = Constants.RelevantFFmpegPath;
            ffmpegfile = HttpContext.Current.Server.MapPath(ffmpegfile);
            if ((!System.IO.File.Exists(ffmpegfile)) || (!System.IO.File.Exists(sourceFile)))
            {
                return;
            }
            using (System.Diagnostics.Process ffmpeg = new System.Diagnostics.Process())
            {
                String result;  // temp variable holding a string representation of our video's duration
                StreamReader errorreader;  // StringWriter to hold output from ffmpeg

                // we want to execute the process without opening a shell
                ffmpeg.StartInfo.UseShellExecute = false;
                //ffmpeg.StartInfo.ErrorDialog = false;
                ffmpeg.StartInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Hidden;
                // redirect StandardError so we can parse it
                // for some reason the output comes through over StandardError
                ffmpeg.StartInfo.RedirectStandardError = true;

                // set the file name of our process, including the full path
                // (as well as quotes, as if you were calling it from the command-line)
                ffmpeg.StartInfo.FileName = ffmpegfile;

                // set the command-line arguments of our process, including full paths of any files
                // (as well as quotes, as if you were passing these arguments on the command-line)
                ffmpeg.StartInfo.Arguments = "-i \"" + sourceFile + "\"";

                // start the process
                ffmpeg.Start();

                // now that the process is started, we can redirect output to the StreamReader we defined
                errorreader = ffmpeg.StandardError;

                // wait until ffmpeg comes back
                ffmpeg.WaitForExit();

                // read the output from ffmpeg, which for some reason is found in Process.StandardError
                result = errorreader.ReadToEnd();

                // a little convoluded, this string manipulation...
                // working from the inside out, it:
                // takes a substring of result, starting from the end of the "Duration: " label contained within,
                // (execute "ffmpeg.exe -i somevideofile" on the command-line to verify for yourself that it is there)
                // and going the full length of the timestamp

                duration = result.Substring(result.IndexOf("Duration: ") + ("Duration: ").Length, ("00:00:00").Length);
                if (result.IndexOf("Video: ") > 0)
                {
                    try
                    {
                        int startPosition = result.IndexOf("Video: ") + ("Video: ").Length;
                        int endPosition = result.IndexOf(' ', startPosition + 1);
                        videoCode = result.Substring(startPosition, endPosition - startPosition);
                    }
                    catch { }
                }
                if (result.IndexOf("Audio: ") > 0)
                {
                    try
                    {
                        int startPosition = result.IndexOf("Audio: ") + ("Audio: ").Length;
                        int endPosition = result.IndexOf(' ', startPosition + 1);
                        audioCode = result.Substring(startPosition, endPosition - startPosition);
                    }
                    catch { }
                }
                return;
            }
        }
        catch
        {
            return;
        }
    }

    public static string GetAudioConvertedPath(string sourceFile)
    {
        try
        {
            string ffmpegfile = Constants.RelevantFFmpegPath;
            ffmpegfile = HttpContext.Current.Server.MapPath(ffmpegfile);
            if ((!System.IO.File.Exists(ffmpegfile)) || (!System.IO.File.Exists(sourceFile)))
            {
                return "";
            }
            string fixedFilePath = sourceFile.Substring(0, sourceFile.LastIndexOf('.')) + "_temp.mp3";
            using (System.Diagnostics.Process ffmpeg = new System.Diagnostics.Process())
            {
                String result;  // temp variable holding a string representation of our video's duration
                StreamReader errorreader;  // StringWriter to hold output from ffmpeg

                // we want to execute the process without opening a shell
                ffmpeg.StartInfo.UseShellExecute = false;
                //ffmpeg.StartInfo.ErrorDialog = false;
                ffmpeg.StartInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Hidden;
                // redirect StandardError so we can parse it
                // for some reason the output comes through over StandardError
                ffmpeg.StartInfo.RedirectStandardError = true;

                // set the file name of our process, including the full path
                // (as well as quotes, as if you were calling it from the command-line)
                ffmpeg.StartInfo.FileName = ffmpegfile;

                // set the command-line arguments of our process, including full paths of any files
                // (as well as quotes, as if you were passing these arguments on the command-line)
                ffmpeg.StartInfo.Arguments = string.Format("-i \"{0}\" -acodec mp3 \"{1}\"", sourceFile, fixedFilePath);

                // start the process
                ffmpeg.Start();

                // now that the process is started, we can redirect output to the StreamReader we defined
                errorreader = ffmpeg.StandardError;

                // wait until ffmpeg comes back
                //ffmpeg.WaitForExit();

                // read the output from ffmpeg, which for some reason is found in Process.StandardError
                result = errorreader.ReadToEnd();

                // a little convoluded, this string manipulation...
                // working from the inside out, it:
                // takes a substring of result, starting from the end of the "Duration: " label contained within,
                // (execute "ffmpeg.exe -i somevideofile" on the command-line to verify for yourself that it is there)
                // and going the full length of the timestamp

                return fixedFilePath;
            }
        }
        catch
        {
            return "";
        }
    }

    public static string GetVideoConvertedPath(string sourceFile)
    {
        try
        {
            string ffmpegfile = Constants.RelevantFFmpegPath;
            ffmpegfile = HttpContext.Current.Server.MapPath(ffmpegfile);
            if ((!System.IO.File.Exists(ffmpegfile)) || (!System.IO.File.Exists(sourceFile)))
            {
                return "";
            }
            //string fixedFilePath = Path.ChangeExtension(sourceFile, "mp4");
            string fixedFilePath = sourceFile.Substring(0, sourceFile.LastIndexOf('.')) + "_temp.mp4";
            using (System.Diagnostics.Process ffmpeg = new System.Diagnostics.Process())
            {
                String result;  // temp variable holding a string representation of our video's duration
                StreamReader errorreader;  // StringWriter to hold output from ffmpeg

                // we want to execute the process without opening a shell
                ffmpeg.StartInfo.UseShellExecute = false;
                //ffmpeg.StartInfo.ErrorDialog = false;
                ffmpeg.StartInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Hidden;
                // redirect StandardError so we can parse it
                // for some reason the output comes through over StandardError
                ffmpeg.StartInfo.RedirectStandardError = true;

                // set the file name of our process, including the full path
                // (as well as quotes, as if you were calling it from the command-line)
                ffmpeg.StartInfo.FileName = ffmpegfile;

                // set the command-line arguments of our process, including full paths of any files
                // (as well as quotes, as if you were passing these arguments on the command-line)
                ffmpeg.StartInfo.Arguments = string.Format("-i \"{0}\" -c:v libx264 -preset ultrafast -crf 20 -acodec aac \"{1}\"", sourceFile, fixedFilePath);

                // start the process
                ffmpeg.Start();

                // now that the process is started, we can redirect output to the StreamReader we defined
                errorreader = ffmpeg.StandardError;

                // wait until ffmpeg comes back
                //ffmpeg.WaitForExit();

                // read the output from ffmpeg, which for some reason is found in Process.StandardError
                result = errorreader.ReadToEnd();

                // a little convoluded, this string manipulation...
                // working from the inside out, it:
                // takes a substring of result, starting from the end of the "Duration: " label contained within,
                // (execute "ffmpeg.exe -i somevideofile" on the command-line to verify for yourself that it is there)
                // and going the full length of the timestamp

                return fixedFilePath;
            }
        }
        catch
        {
            return "";
        }
    }

    public static string CatchVideoCoverImage(string vFileName)
    {
        try
        {
            string ffmpeg = Constants.RelevantFFmpegPath;
            ffmpeg = HttpContext.Current.Server.MapPath(ffmpeg);
            if ((!System.IO.File.Exists(ffmpeg)) || (!System.IO.File.Exists(vFileName)))
            {
                return "";
            }
            string flv_img = System.IO.Path.ChangeExtension(vFileName, ".jpg");
            System.Diagnostics.ProcessStartInfo startInfo = new System.Diagnostics.ProcessStartInfo(ffmpeg);
            startInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Normal;
            startInfo.Arguments = "-ss 00:00:05 -i \"" + vFileName + "\" -f image2 -y \"" + flv_img + "\" -r 1 -vframes 1 -an -vcodec mjpeg";
            try
            {
                System.Diagnostics.Process.Start(startInfo);
            }
            catch
            {
                return "";
            }
            return flv_img;
        }
        catch
        {
            return "";
        }
    }

    /// <summary>
    /// 文字水印
    /// </summary>
    /// <param name="imgPath">服务器图片相对路径</param>
    /// <param name="filename">保存文件名</param>
    /// <param name="watermarkText">水印文字</param>
    /// <param name="watermarkStatus">图片水印位置 0=不使用 1=左上 2=中上 3=右上 4=左中  9=右下</param>
    /// <param name="quality">附加水印图片质量,0-100</param>
    /// <param name="fontsize">字体大小</param>
    /// <param name="fontname">字体</param>
    public static void AddImageSignText(string imgPath, string filename, string watermarkText, int watermarkStatus, int quality, int fontsize, string fontname = "微软雅黑")
    {
        try
        {
            byte[] _ImageBytes = File.ReadAllBytes(imgPath);
            Image img = Image.FromStream(new System.IO.MemoryStream(_ImageBytes));

            int sizeTimes = img.Width / 150;
            fontsize = fontsize + sizeTimes * 2;

            Graphics g = Graphics.FromImage(img);
            Font drawFont = new Font(fontname, fontsize, FontStyle.Regular, GraphicsUnit.Pixel);
            SizeF crSize;
            crSize = g.MeasureString(watermarkText, drawFont);

            float xpos = 0;
            float ypos = 0;

            switch (watermarkStatus)
            {
                case 1:
                    xpos = (float)img.Width * (float).01;
                    ypos = (float)img.Height * (float).01;
                    break;
                case 2:
                    xpos = ((float)img.Width * (float).50) - (crSize.Width / 2);
                    ypos = (float)img.Height * (float).01;
                    break;
                case 3:
                    xpos = ((float)img.Width * (float).99) - crSize.Width;
                    ypos = (float)img.Height * (float).01;
                    break;
                case 4:
                    xpos = (float)img.Width * (float).01;
                    ypos = ((float)img.Height * (float).50) - (crSize.Height / 2);
                    break;
                case 5:
                    xpos = ((float)img.Width * (float).50) - (crSize.Width / 2);
                    ypos = ((float)img.Height * (float).50) - (crSize.Height / 2);
                    break;
                case 6:
                    xpos = ((float)img.Width * (float).99) - crSize.Width;
                    ypos = ((float)img.Height * (float).50) - (crSize.Height / 2);
                    break;
                case 7:
                    xpos = (float)img.Width * (float).01;
                    ypos = ((float)img.Height * (float).99) - crSize.Height;
                    break;
                case 8:
                    xpos = ((float)img.Width * (float).50) - (crSize.Width / 2);
                    ypos = ((float)img.Height * (float).99) - crSize.Height;
                    break;
                case 9:
                    xpos = ((float)img.Width * (float).99) - crSize.Width;
                    ypos = ((float)img.Height * (float).99) - crSize.Height;
                    break;
            }

            g.DrawString(watermarkText, drawFont, new SolidBrush(Color.Black), xpos + 1, ypos + 1);
            g.DrawString(watermarkText, drawFont, new SolidBrush(Color.White), xpos, ypos);

            ImageCodecInfo[] codecs = ImageCodecInfo.GetImageEncoders();
            ImageCodecInfo ici = null;
            foreach (ImageCodecInfo codec in codecs)
            {
                if (codec.MimeType.IndexOf("jpeg") > -1)
                    ici = codec;
            }
            EncoderParameters encoderParams = new EncoderParameters();
            long[] qualityParam = new long[1];
            if (quality < 0 || quality > 100)
                quality = 80;

            qualityParam[0] = quality;

            EncoderParameter encoderParam = new EncoderParameter(System.Drawing.Imaging.Encoder.Quality, qualityParam);
            encoderParams.Param[0] = encoderParam;

            if (ici != null)
                img.Save(filename, ici, encoderParams);
            else
                img.Save(filename);

            g.Dispose();
            img.Dispose();
        }
        catch { }
    }

}
