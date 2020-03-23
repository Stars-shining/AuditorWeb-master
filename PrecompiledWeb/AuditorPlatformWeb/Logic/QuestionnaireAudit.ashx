﻿<%@ WebHandler Language="C#" Class="QuestionnaireAudit" %>

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

public class QuestionnaireAudit : IHttpHandler, IRequiresSessionState
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
                    GetQuestionnaireCheckList();
                    break;
                case 2:
                    SubmitQuestionnaireResultAuditing();
                    break;
                case 3:
                    GetQuestionnaireAuditStatus();
                    break;
                case 4:
                    SubmitQuestionnaireResultEditing();
                    break;
                case 5:
                    GetQuestionFiles();
                    break;
                case 6:
                    SubmitAuditNote();
                    break;
                case 7:
                    GetQuestionnaireCheckListClient();
                    break;
                case 8:
                    SubmitClientAuditCancel();
                    break;
                case 9:
                    GetQuestionnaireCheckListQCLeader();
                    break;
                case 10:
                    GetClientStatus();
                    break;
                case 11:
                    GetSubClientStatus();
                    break;
                case 12:
                    CloseAppeal();
                    break;
                case 13:
                    GetAuditNoteHistory();
                    break;
                case 14:
                    SubmitVisitInfo();
                    break;
                case 15:
                    SubmitQuestionnaireResultUpload();
                    break;
                case 16:
                    SubmitAppeal();
                    break;
                case 17:
                    OpenAppeal();
                    break;
                default:
                    break;
            }
        }
        catch { }
    }

    public void SubmitAppeal() 
    {
        string resultID = HttpContext.Current.Request.Params["resultID"];
        int _resultID = 0;
        int.TryParse(resultID, out _resultID);
        string jsonResult = "0";
        APQuestionnaireResultsDO resultDO = APQuestionnaireManager.GetQuestionnaireResultDOByID(_resultID);
        if (resultDO.Status == (int)Enums.QuestionnaireStageStatus.质控督导审核中 && resultDO.QCLeaderAuditStatusFirst == (int)Enums.QuestionnaireAuditStatus.通过) 
        {
            resultDO.Status = (int)Enums.QuestionnaireStageStatus.申诉中;
            resultDO.ClientUserAuditStatus = (int)Enums.QuestionnaireClientStatus.未申诉;
            APUsersDO clientUserDO = APUserManager.GetClientUserDO(resultDO.ClientID, WebSiteContext.CurrentProjectID);
            resultDO.CurrentClientUserID = clientUserDO.ID;
            resultDO.LastModifiedTime = DateTime.Now;
            resultDO.LastModifiedUserID = WebSiteContext.CurrentUserID;
            BusinessLogicBase.Default.Update(resultDO);
            WebCommon.SendAppealStartNotice(resultDO, clientUserDO.ID, (int)Enums.QuestionnaireAuditType.质控督导审核);
            jsonResult = "1";
        }
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void SubmitVisitInfo()
    {
        string resultID = HttpContext.Current.Request.Params["resultID"];
        string visitDate = HttpContext.Current.Request.Params["visitDate"];
        string visitBeginTime = HttpContext.Current.Request.Params["visitBeginTime"];
        string visitEndTime = HttpContext.Current.Request.Params["visitEndTime"];
        string videoPath = HttpContext.Current.Request.Params["videoPath"];
        string videoLength = HttpContext.Current.Request.Params["videoLength"];
        string description = HttpContext.Current.Request.Params["description"];
        int _resultID = 0;
        int.TryParse(resultID, out _resultID);
        visitBeginTime = visitDate + " " + visitBeginTime + ":00";
        visitEndTime = visitDate + " " + visitEndTime + ":00";

        DateTime beginTime = Constants.Date_Min;
        DateTime endTime = Constants.Date_Min;
        DateTime.TryParse(visitBeginTime, out beginTime);
        DateTime.TryParse(visitEndTime, out endTime);

        APQuestionnaireResultsDO resultDO = APQuestionnaireManager.GetQuestionnaireResultDOByID(_resultID);
        APClientsDO currentClientDO = APClientManager.GetClientDOByID(resultDO.ClientID);
        if (currentClientDO.ProjectID != WebSiteContext.CurrentProjectID)
        {
            string result = "-1";
            HttpContext.Current.Response.ContentType = "application/json";
            HttpContext.Current.Response.Write(result);
            return;
        }
        
        resultDO.VisitBeginTime = beginTime;
        resultDO.VisitEndTime = endTime;
        resultDO.VideoPath = videoPath;
        resultDO.VideoLength = videoLength;
        resultDO.Description = description;
        resultDO.LastModifiedTime = DateTime.Now;
        resultDO.LastModifiedUserID = WebSiteContext.CurrentUserID;
        BusinessLogicBase.Default.Update(resultDO);
        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetAuditNoteHistory()
    {
        string resultID = HttpContext.Current.Request.QueryString["resultID"];
        string typeID = HttpContext.Current.Request.QueryString["typeID"];
        int _resultID = 0;
        int.TryParse(resultID, out _resultID);
        int _typeID = 0;
        int.TryParse(typeID, out _typeID);
        DataTable dt = APQuestionnaireManager.GetAuditNoteHistory(_resultID);
        if (_typeID > 0)
        {
            DataView dv = dt.DefaultView;
            dv.RowFilter = "TypeID=" + _typeID;
            dt = dv.ToTable();
        }
        //else 
        //{
        //    DataView dv = dt.DefaultView;
        //    dv.RowFilter = "TypeID<>4";
        //    dt = dv.ToTable();
        //}
        string jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void CloseAppeal()
    {
        string ids = HttpContext.Current.Request.Params["ids"];
        string[] allids = ids.Split(',');
        foreach (string id in allids)
        {
            int resultID = 0;
            int.TryParse(id, out resultID);

            APQuestionnaireResultsDO resultDO = APQuestionnaireManager.GetQuestionnaireResultDOByID(resultID);
            if (resultDO.Status == (int)Enums.QuestionnaireStageStatus.申诉中)
            {
                bool hasAppeal = true;
                APUsersDO clientUserDO = APUserManager.GetClientUserDO(resultDO.ClientID, WebSiteContext.CurrentProjectID);
                if (clientUserDO.ID == resultDO.CurrentClientUserID) 
                {
                    //说明支行没有发起申诉
                    hasAppeal = false;
                }
                int currentClientUserID = resultDO.CurrentClientUserID;
                int currentStatus = resultDO.Status;
                bool bApproved = false;

                resultDO.ReAuditStatus = 1;
                resultDO.Status = (int)Enums.QuestionnaireStageStatus.完成;
                if (hasAppeal == true)
                {
                    resultDO.ClientUserAuditStatus = (int)Enums.QuestionnaireClientStatus.申诉已处理;
                }
                else
                {
                    resultDO.ClientUserAuditStatus = (int)Enums.QuestionnaireClientStatus.无申诉内容;
                }
                resultDO.CurrentClientUserID = 0;
                resultDO.LastModifiedTime = DateTime.Now;
                resultDO.LastModifiedUserID = WebSiteContext.CurrentUserID;
                BusinessLogicBase.Default.Update(resultDO);

                string auditNotes = "无异议扣分";
                if (hasAppeal)
                {
                    APUsersDO currentClientUserDO = APUserManager.GetUserByID(currentClientUserID);
                    string clientName = currentClientUserDO.UserName;
                    auditNotes = "已过申诉期，过期前该问卷处于" + clientName + "申诉中状态";
                }
                APAuditHistoryDO auditDO = new APAuditHistoryDO();
                auditDO.AuditTime = DateTime.Now;
                auditDO.AuditNotes = auditNotes;
                auditDO.AuditUserID = WebSiteContext.CurrentUserID;
                auditDO.ClientID = resultDO.ClientID;
                auditDO.QuestionnaireResultID = resultDO.ID;
                auditDO.AuditStatus = currentStatus;
                auditDO.AuditResult = bApproved;
                auditDO.ReturnUserType = 0;
                auditDO.ReturnUserID = 0;
                auditDO.TypeID = (int)Enums.QuestionnaireAuditType.客户审核;
                auditDO.ProjectID = WebSiteContext.CurrentProjectID;
                BusinessLogicBase.Default.Insert(auditDO);

                WebCommon.SendAppealCloseNotice(resultDO, (int)Enums.QuestionnaireAuditType.客户审核);
            }
        }
        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void OpenAppeal()
    {
        string ids = HttpContext.Current.Request.Params["ids"];
        string[] allids = ids.Split(',');
        foreach (string id in allids)
        {
            int resultID = 0;
            int.TryParse(id, out resultID);

            APQuestionnaireResultsDO resultDO = APQuestionnaireManager.GetQuestionnaireResultDOByID(resultID);
            if (resultDO.Status == (int)Enums.QuestionnaireStageStatus.完成)
            {
                int clientid = resultDO.ClientID;
                APUsersDO userDO = APUserManager.GetClientUserDO(clientid, WebSiteContext.CurrentProjectID);
                int clientUserID = userDO.ID;
                
                resultDO.ReAuditStatus = 1;
                resultDO.Status = (int)Enums.QuestionnaireStageStatus.申诉中;
                resultDO.ClientUserAuditStatus = (int)Enums.QuestionnaireClientStatus.未申诉;
                resultDO.CurrentClientUserID = clientUserID;
                resultDO.LastModifiedTime = DateTime.Now;
                resultDO.LastModifiedUserID = WebSiteContext.CurrentUserID;
                BusinessLogicBase.Default.Update(resultDO);
                WebCommon.SendAppealStartNotice(resultDO, clientUserID, (int)Enums.QuestionnaireAuditType.质控督导审核);
            }
        }
        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }
    
    public void GetClientStatus()
    {
        string qid = HttpContext.Current.Request.QueryString["qid"];
        string clientID = HttpContext.Current.Request.QueryString["clientID"];
        string period = HttpContext.Current.Request.QueryString["period"];
        int _qid = 0;
        int _clientID = 0;
        int.TryParse(qid, out _qid);
        int.TryParse(clientID, out _clientID);
        int projectID = WebSiteContext.CurrentProjectID;

        if (_clientID == 0)
        {
            _clientID = WebSiteContext.Current.CurrentUser.ClientID;
            //if (_clientID <= 0) {
            //    _clientID = APClientManager.GetTopClientID(projectID);
            //}
        }

        DateTime fromDate = Constants.Date_Null;
        DateTime toDate = Constants.Date_Null;
        string [] values = period.Split(new char[] { '|' }, StringSplitOptions.RemoveEmptyEntries);
        string strFrom = values[0];
        string strTo = values[1];
        DateTime.TryParse(strFrom, out fromDate);
        DateTime.TryParse(strTo, out toDate);
        DataSet ds = APClientManager.GetClientStatus(projectID, _qid, fromDate, toDate, _clientID);
        string jsonFullStatus = JSONHelper.DataTableToJSON(ds.Tables[0]);
        string jsonAppealStatus = JSONHelper.DataTableToJSON(ds.Tables[1]);
        string jsonResult = "{\"FullStatus\":" + jsonFullStatus + ",\"AppealStatus\":" + jsonAppealStatus + "}";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetSubClientStatus()
    {
        string qid = HttpContext.Current.Request.QueryString["qid"];
        string clientID = HttpContext.Current.Request.QueryString["clientID"];
        string period = HttpContext.Current.Request.QueryString["period"];
        int _qid = 0;
        int _clientID = 0;
        int.TryParse(qid, out _qid);
        int.TryParse(clientID, out _clientID);
        int projectID = WebSiteContext.CurrentProjectID;

        if (_clientID == 0)
        {
            _clientID = WebSiteContext.Current.CurrentUser.ClientID;
            //if (_clientID <= 0)
            //{
            //    _clientID = APClientManager.GetTopClientID(projectID);
            //}
        }

        DateTime fromDate = Constants.Date_Null;
        DateTime toDate = Constants.Date_Null;
        string[] values = period.Split(new char[] { '|' }, StringSplitOptions.RemoveEmptyEntries);
        string strFrom = values[0];
        string strTo = values[1];
        DateTime.TryParse(strFrom, out fromDate);
        DateTime.TryParse(strTo, out toDate);
        DataTable dt = APClientManager.GetSubClientStatus(projectID, _qid, fromDate, toDate, _clientID);
        string jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void SubmitAuditNote()
    {
        string resultID = HttpContext.Current.Request.Params["resultID"];
        string questionID = HttpContext.Current.Request.Params["questionID"];
        string auditType = HttpContext.Current.Request.Params["auditType"];
        string note = HttpContext.Current.Request.Params["note"];
        int _resultID = 0;
        int.TryParse(resultID, out _resultID);
        int _questionID = 0;
        int.TryParse(questionID, out _questionID);
        int _typeID = 0;
        int.TryParse(auditType, out _typeID);

        APQuestionnaireResultsDO resultDO = APQuestionnaireManager.GetQuestionnaireResultDOByID(_resultID);
        APClientsDO currentClientDO = APClientManager.GetClientDOByID(resultDO.ClientID);
        if (currentClientDO.ProjectID != WebSiteContext.CurrentProjectID)
        {
            string result = "-1";
            HttpContext.Current.Response.ContentType = "application/json";
            HttpContext.Current.Response.Write(result);
            return;
        }

        APQuestionAuditNotesDO ando = APQuestionManager.GetAPQuestionAuditNotesDO(_resultID, _questionID, _typeID, WebSiteContext.CurrentUserID);
        if (ando == null || ando.ID <= 0)
        {
            ando = new APQuestionAuditNotesDO();
        }
        ando.AuditNotes = note;
        ando.AuditTypeID = _typeID;
        ando.ResultID = _resultID;
        ando.QuestionID = _questionID;
        ando.CreateTime = DateTime.Now;
        ando.CreateUserID = WebSiteContext.CurrentUserID;
        ando.UserTypeID = WebSiteContext.Current.CurrentUser.RoleID;
        if (ando.ID > 0)
        {
            BusinessLogicBase.Default.Update(ando);
        }
        else
        {
            BusinessLogicBase.Default.Insert(ando);
        }
        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetQuestionFiles()
    {
        string relatedID = HttpContext.Current.Request.QueryString["relatedID"];
        string typeID = HttpContext.Current.Request.QueryString["typeID"];
        string tempCode = HttpContext.Current.Request.QueryString["tempCode"];

        int _relatedID = 0;
        int.TryParse(relatedID, out _relatedID);
        int _typeID = 0;
        int.TryParse(typeID, out _typeID);

        if (tempCode == null) {
            tempCode = "";
        }

        bool _include = false;
        if (_typeID == 6)
        {
            // 6 means 3 and 4, 执行文件和审核文件都要一起看
            _typeID = 4;
            _include = true;
        }
        DataTable dt = DocumentManager.GetFilesByRelatedID(_relatedID, _typeID, (int)Enums.DocumentStatus.正常, _include, tempCode);

        string jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void SubmitQuestionnaireResultEditing()
    {
        string resultID = HttpContext.Current.Request.Params["resultID"];
        int _resultID = 0;
        int.TryParse(resultID, out _resultID);
        APQuestionnaireResultsDO resultDO = APQuestionnaireManager.GetQuestionnaireResultDOByID(_resultID);
        resultDO.VisitUserUploadStatus = (int)Enums.QuestionnaireUploadStatus.已提交审核;
        resultDO.Status = (int)Enums.QuestionnaireStageStatus.执行督导审核中;
        resultDO.VisitUserID = WebSiteContext.CurrentUserID;
        resultDO.CityUserAuditStatus = (int)Enums.QuestionnaireAuditStatus.未审核;
        resultDO.LastModifiedTime = DateTime.Now;
        resultDO.LastModifiedUserID = WebSiteContext.CurrentUserID;
        BusinessLogicBase.Default.Update(resultDO);

        WebCommon.SendAuditNotice(resultDO, (int)Enums.UserType.执行督导, (int)Enums.QuestionnaireAuditType.执行督导审核);

        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void SubmitQuestionnaireResultUpload()
    {
        string resultID = HttpContext.Current.Request.Params["resultID"];
        int _resultID = 0;
        int.TryParse(resultID, out _resultID);

        //DataTable dt = APQuestionManager.GetQuestionnaireResultAnswers(_resultID);
        ////DataView dv = dt.DefaultView;
        ////dv.RowFilter = "AnswerID is null";
        ////dt = dv.ToTable();
        ////decimal totalScore = 0m;
        //if (dt != null && dt.Rows.Count > 0)
        //{
        //    foreach (DataRow row in dt.Rows)
        //    {
        //        int answerID = 0;
        //        int questionID = 0;
        //        int.TryParse(row["AnswerID"].ToString(), out answerID);
        //        int.TryParse(row["ID"].ToString(), out questionID);
        //        string tempCode = _resultID * 100 + " " + questionID * 100;
        //        APQuestionManager.UpdateAttachmentRelatedIDByTempCode(answerID, tempCode);
        //        //int.TryParse(row["QuestionType"].ToString(), out questionType);
        //        //decimal score = 0m;
        //        //decimal.TryParse(row["TotalScore"].ToString(), out score);
        //        //string optionIDs = row["OptionIDs"].ToString();
        //        //List<int> optionIDList = new List<int>();
        //        //if (string.IsNullOrEmpty(optionIDs) == false)
        //        //{
        //        //    string[] ids = optionIDs.Split(',');
        //        //    foreach (string id in ids)
        //        //    {
        //        //        int _id = 0;
        //        //        int.TryParse(id, out _id);
        //        //        optionIDList.Add(_id);
        //        //    }
        //        //}
        //        //if (questionType == (int)Enums.QuestionType.段落)
        //        //{
        //        //    APAnswersDO ado = new APAnswersDO();
        //        //    ado.QuestionID = questionID;
        //        //    ado.TotalScore = 0m;
        //        //    ado.ResultID = _resultID;
        //        //    ado.Status = (int)Enums.DeleteStatus.正常;
        //        //    ado.CreateTime = DateTime.Now;
        //        //    ado.CreateUserID = WebSiteContext.CurrentUserID;
        //        //    BusinessLogicBase.Default.Insert(ado);
        //        //}
        //        //else if (questionType == (int)Enums.QuestionType.填空题)
        //        //{
        //        //    APAnswersDO ado = new APAnswersDO();
        //        //    ado.QuestionID = questionID;
        //        //    ado.TotalScore = 0m;
        //        //    ado.ResultID = _resultID;
        //        //    ado.Status = (int)Enums.DeleteStatus.正常;
        //        //    ado.CreateTime = DateTime.Now;
        //        //    ado.CreateUserID = WebSiteContext.CurrentUserID;
        //        //    int answerID = BusinessLogicBase.Default.Insert(ado);
        //        //    APAnswerOptionsDO answerOptionDO = new APAnswerOptionsDO();
        //        //    answerOptionDO.AnswerID = answerID;
        //        //    answerOptionDO.OptionID = -1;
        //        //    answerOptionDO.OptionText = "";
        //        //    string tempCode = _resultID * 100 + " " + questionID * 100;
        //        //    APQuestionManager.UpdateAttachmentRelatedIDByTempCode(answerID, tempCode);
        //        //}
        //        //else if (questionType == (int)Enums.QuestionType.单选题 || questionType == (int)Enums.QuestionType.多选题 || questionType == (int)Enums.QuestionType.是非题)
        //        //{
        //        //    APAnswersDO ado = new APAnswersDO();
        //        //    ado.QuestionID = questionID;
        //        //    ado.TotalScore = score;
        //        //    ado.ResultID = _resultID;
        //        //    ado.Status = (int)Enums.DeleteStatus.正常;
        //        //    ado.CreateTime = DateTime.Now;
        //        //    ado.CreateUserID = WebSiteContext.CurrentUserID;
        //        //    int answerID = BusinessLogicBase.Default.Insert(ado);
        //        //    foreach (int optionID in optionIDList)
        //        //    {
        //        //        APAnswerOptionsDO answerOptionDO = new APAnswerOptionsDO();
        //        //        answerOptionDO.AnswerID = answerID;
        //        //        answerOptionDO.OptionID = optionID;
        //        //        answerOptionDO.OptionText = "";
        //        //        BusinessLogicBase.Default.Insert(answerOptionDO);
        //        //    }

        //        //    totalScore += score;
        //        //    string tempCode = _resultID * 100 + " " + questionID * 100;
        //        //    APQuestionManager.UpdateAttachmentRelatedIDByTempCode(answerID, tempCode);
        //        //}
        //    }
        //}

        APQuestionnaireResultsDO resultDO = APQuestionnaireManager.GetQuestionnaireResultDOByID(_resultID);
        //resultDO.Score += totalScore;
        resultDO.VisitUserUploadStatus = (int)Enums.QuestionnaireUploadStatus.已提交审核;
        resultDO.Status = (int)Enums.QuestionnaireStageStatus.执行督导审核中;
        resultDO.VisitUserID = WebSiteContext.CurrentUserID;
        resultDO.CityUserAuditStatus = (int)Enums.QuestionnaireAuditStatus.未审核;
        resultDO.CurrentProgress = 1;
        resultDO.UploadEndTime = DateTime.Now;
        resultDO.LastModifiedTime = DateTime.Now;
        resultDO.LastModifiedUserID = WebSiteContext.CurrentUserID;
        BusinessLogicBase.Default.Update(resultDO);

        WebCommon.SendAuditNotice(resultDO, (int)Enums.UserType.执行督导, (int)Enums.QuestionnaireAuditType.执行督导审核);

        APQuestionnaireManager.FixResultAttachments(_resultID);

        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetQuestionnaireAuditStatus()
    {
        string resultID = HttpContext.Current.Request.QueryString["resultID"];
        string typeID = HttpContext.Current.Request.QueryString["typeID"];

        int _resultID = 0;
        int.TryParse(resultID, out _resultID);
        int _typeID = 0;
        int.TryParse(typeID, out _typeID);

        APQuestionnaireResultsDO resultDO = APQuestionnaireManager.GetQuestionnaireResultDOByID(_resultID);
        int status = resultDO.Status;
        int auditStatus = 0;
        int userID = 0;
        DateTime auditTime = Constants.Date_Null;
        string auditInfo = string.Empty;
        if (_typeID == (int)Enums.QuestionnaireAuditType.执行督导审核)
        {
            auditStatus = resultDO.CityUserAuditStatus;
            userID = resultDO.CityUserID;
            auditTime = resultDO.CityUserAuditTime;
        }
        else if (_typeID == (int)Enums.QuestionnaireAuditType.区控审核)
        {
            auditStatus = resultDO.AreaUserAuditStatus;
            userID = resultDO.AreaUserID;
            auditTime = resultDO.AreaUserAuditTime;
        }
        else if (_typeID == (int)Enums.QuestionnaireAuditType.质控审核)
        {
            auditStatus = resultDO.QCUserAuditStatus;
            userID = resultDO.QCUserID;
            auditTime = resultDO.QCUserAuditTime;
        }
        else if (_typeID == (int)Enums.QuestionnaireAuditType.质控督导审核)
        {
            auditStatus = resultDO.QCLeaderAuditStatusFirst;
            userID = resultDO.QCLeaderUserIDFirst;
            auditTime = resultDO.QCLeaderAuditTimeFirst;
        }
        else if (_typeID == (int)Enums.QuestionnaireAuditType.客户审核 && status != (int)Enums.QuestionnaireStageStatus.复审中)
        {
            auditStatus = resultDO.ClientUserAuditStatus;
            userID = resultDO.ClientUserID;
            auditTime = resultDO.ClientUserAuditTime;
        }
        else if (_typeID == (int)Enums.QuestionnaireAuditType.质控督导复审 || resultDO.ReAuditStatus > 0)
        {
            auditStatus = resultDO.QCLeaderAuditStatus;
            userID = resultDO.QCLeaderUserID;
            auditTime = resultDO.QCLeaderAuditTime;
        }
        
        string statusName = BusinessConfigurationManager.GetItemValueByItemKey(auditStatus, "QuestionnaireAuditStatus");
        if (_typeID == (int)Enums.QuestionnaireAuditType.终审裁决 && resultDO.Status == (int)Enums.QuestionnaireStageStatus.完成)
        {
            auditStatus = resultDO.ClientUserAuditStatus;
            userID = resultDO.ClientUserID;
            auditTime = resultDO.ClientUserAuditTime;
            statusName = BusinessConfigurationManager.GetItemValueByItemKey(auditStatus, "QuestionnaireClientStatus");
        }
        auditInfo = CommonFunction.GetUserActionInfo(userID, auditTime);
        if (auditStatus > 0)
        {
            auditInfo = auditInfo + " " + statusName;
        }
        else
        {
            auditInfo = Enums.QuestionnaireAuditStatus.未审核.ToString();
        }

        if (_typeID == (int)Enums.QuestionnaireAuditType.客户审核 && status != (int)Enums.QuestionnaireStageStatus.复审中)
        {
            statusName = BusinessConfigurationManager.GetItemValueByItemKey(auditStatus, "QuestionnaireClientStatus");
            auditInfo = CommonFunction.GetUserActionInfo(userID, auditTime);
            if (auditStatus > 0)
            {
                auditInfo = auditInfo + " " + statusName;
            }
            else
            {
                auditInfo = Enums.QuestionnaireClientStatus.未申诉.ToString();
            }
        }
        if (resultDO.ReAuditStatus > 0)
        {
            auditInfo = "复审中，" + auditInfo;
        }

        int currentClientUserID = resultDO.CurrentClientUserID;
        int isTerminalClient = 0;
        APUsersDO terminalClientUser = APUserManager.GetClientUserDO(resultDO.ClientID, WebSiteContext.CurrentProjectID);
        if (terminalClientUser.ID == currentClientUserID)
        {
            isTerminalClient = 1;
        }
        string jsonResult = "{\"Info\":\"" + auditInfo + "\",\"Status\":\"" + status + "\",\"CurrentClientUserID\":\"" + currentClientUserID + "\",\"IsTerminalClient\":\"" + isTerminalClient + "\",\"AuditStatus\":\"" + auditStatus + "\"}";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void SubmitQuestionnaireResultAuditing()
    {
        string resultID = HttpContext.Current.Request.Params["resultID"];
        string auditNotes = HttpContext.Current.Request.Params["auditNotes"];
        string approved = HttpContext.Current.Request.Params["approved"];
        string returnUserType = HttpContext.Current.Request.Params["returnUserType"];
        string typeID = HttpContext.Current.Request.Params["typeID"];
        int _resultID = 0;
        int.TryParse(resultID, out _resultID);
        int _typeID = 0;
        int.TryParse(typeID, out _typeID);

        if (string.IsNullOrEmpty(auditNotes))
        {
            auditNotes = string.Empty;
        }
        APQuestionnaireResultsDO resultDO = APQuestionnaireManager.GetQuestionnaireResultDOByID(_resultID);
        APClientsDO currentClientDO = APClientManager.GetClientDOByID(resultDO.ClientID);
        if (currentClientDO.ProjectID != WebSiteContext.CurrentProjectID) 
        {
            string result = "-1";
            HttpContext.Current.Response.ContentType = "application/json";
            HttpContext.Current.Response.Write(result);
            return;
        }
        
        bool bApproved = false;
        bool.TryParse(approved, out bApproved);
        int _returnUserType = 0;
        int.TryParse(returnUserType, out _returnUserType);
        int nextStatus = CommonFunction.GetNextStatusByUserType(_returnUserType);
        
        
        DateTime currentTime = DateTime.Now;
        
        int currentStatus = resultDO.Status;
        
        //check whether the next status is unreachable
        if (nextStatus > 0 && nextStatus > currentStatus)
        {
            string result = "0";
            HttpContext.Current.Response.ContentType = "application/json";
            HttpContext.Current.Response.Write(result);
            return;
        }
        
        if (_typeID == (int)Enums.QuestionnaireAuditType.执行督导审核)
        {
            resultDO.CityUserAuditTime = currentTime;
            resultDO.CityUserID = WebSiteContext.CurrentUserID;
            if (bApproved == true)
            {
                resultDO.CityUserAuditStatus = (int)Enums.QuestionnaireAuditStatus.通过;
                if (WebSiteContext.Current.CurrentProject.BHasAreaUser)
                {
                    resultDO.Status = (int)Enums.QuestionnaireStageStatus.区控审核中;
                    resultDO.AreaUserAuditStatus = (int)Enums.QuestionnaireAuditStatus.未审核;
                    WebCommon.SendAuditNotice(resultDO, (int)Enums.UserType.区控, (int)Enums.QuestionnaireAuditType.区控审核);
                }
                else
                {
                    resultDO.Status = (int)Enums.QuestionnaireStageStatus.质控审核中;
                    resultDO.QCUserAuditStatus = (int)Enums.QuestionnaireAuditStatus.未审核;
                    WebCommon.SendAuditNotice(resultDO, (int)Enums.UserType.质控员, (int)Enums.QuestionnaireAuditType.质控审核);
                }
                resultDO.AreaUserAuditStatus = (int)Enums.QuestionnaireAuditStatus.未审核;

            }
            else
            {
                resultDO.CityUserAuditStatus = (int)Enums.QuestionnaireAuditStatus.不通过;
                resultDO.Status = nextStatus;
                if (nextStatus == (int)Enums.QuestionnaireStageStatus.录入中)
                {
                    resultDO.VisitUserUploadStatus = (int)Enums.QuestionnaireUploadStatus.录入待修改;
                }

                WebCommon.SendAuditRejectNoticeVisitor(resultDO, resultDO.VisitUserID, auditNotes);
            }
        }
        else if (_typeID == (int)Enums.QuestionnaireAuditType.区控审核)
        {
            resultDO.AreaUserAuditTime = currentTime;
            resultDO.AreaUserID = WebSiteContext.CurrentUserID;

            if (bApproved == true)
            {
                resultDO.AreaUserAuditStatus = (int)Enums.QuestionnaireAuditStatus.通过;
                resultDO.Status = (int)Enums.QuestionnaireStageStatus.质控审核中;
                resultDO.QCUserAuditStatus = (int)Enums.QuestionnaireAuditStatus.未审核;

                WebCommon.SendAuditNotice(resultDO, (int)Enums.UserType.质控员, (int)Enums.QuestionnaireAuditType.质控审核);
            }
            else
            {
                resultDO.AreaUserAuditStatus = (int)Enums.QuestionnaireAuditStatus.不通过;
                resultDO.Status = nextStatus;
                if (nextStatus == (int)Enums.QuestionnaireStageStatus.执行督导审核中)
                {
                    resultDO.CityUserAuditStatus = (int)Enums.QuestionnaireAuditStatus.未审核;

                    WebCommon.SendAuditRejectNotice(resultDO, resultDO.CityUserID, (int)Enums.QuestionnaireAuditType.执行督导审核, auditNotes);
                }
                else if (nextStatus == (int)Enums.QuestionnaireStageStatus.录入中)
                {
                    resultDO.CityUserAuditStatus = (int)Enums.QuestionnaireAuditStatus.未审核;
                    resultDO.VisitUserUploadStatus = (int)Enums.QuestionnaireUploadStatus.录入待修改;

                    WebCommon.SendAuditRejectNoticeVisitor(resultDO, resultDO.VisitUserID, auditNotes);
                }
            }
        }
        else if (_typeID == (int)Enums.QuestionnaireAuditType.质控审核)
        {
            resultDO.QCUserAuditTime = currentTime;
            resultDO.QCUserID = WebSiteContext.CurrentUserID;

            if (bApproved == true)
            {
                resultDO.QCUserAuditStatus = (int)Enums.QuestionnaireAuditStatus.通过;
                resultDO.Status = (int)Enums.QuestionnaireStageStatus.质控督导审核中;
                resultDO.QCLeaderAuditStatusFirst = (int)Enums.QuestionnaireAuditStatus.未审核;

                WebCommon.SendAuditNotice(resultDO, (int)Enums.UserType.质控督导, (int)Enums.QuestionnaireAuditType.质控督导审核);
            }
            else
            {
                resultDO.QCUserAuditStatus = (int)Enums.QuestionnaireAuditStatus.不通过;
                resultDO.Status = nextStatus;
                if (nextStatus == (int)Enums.QuestionnaireStageStatus.区控审核中)
                {
                    resultDO.AreaUserAuditStatus = (int)Enums.QuestionnaireAuditStatus.未审核;
                    WebCommon.SendAuditRejectNotice(resultDO, resultDO.AreaUserID, (int)Enums.QuestionnaireAuditType.区控审核, auditNotes);
                }
                else if (nextStatus == (int)Enums.QuestionnaireStageStatus.执行督导审核中)
                {
                    resultDO.AreaUserAuditStatus = (int)Enums.QuestionnaireAuditStatus.未审核;
                    resultDO.CityUserAuditStatus = (int)Enums.QuestionnaireAuditStatus.未审核;
                    WebCommon.SendAuditRejectNotice(resultDO, resultDO.CityUserID, (int)Enums.QuestionnaireAuditType.执行督导审核, auditNotes);
                }
                else if (nextStatus == (int)Enums.QuestionnaireStageStatus.录入中)
                {
                    resultDO.AreaUserAuditStatus = (int)Enums.QuestionnaireAuditStatus.未审核;
                    resultDO.CityUserAuditStatus = (int)Enums.QuestionnaireAuditStatus.未审核;
                    resultDO.VisitUserUploadStatus = (int)Enums.QuestionnaireUploadStatus.录入待修改;
                    WebCommon.SendAuditRejectNoticeVisitor(resultDO, resultDO.VisitUserID, auditNotes);
                }
            }
        }
        else if (_typeID == (int)Enums.QuestionnaireAuditType.质控督导审核)
        {
            resultDO.QCLeaderAuditTimeFirst = currentTime;
            resultDO.QCLeaderUserIDFirst = WebSiteContext.CurrentUserID;

            if (bApproved == true)
            {
                resultDO.QCLeaderAuditStatusFirst = (int)Enums.QuestionnaireAuditStatus.通过;
                if (WebSiteContext.Current.CurrentProject.BAutoAppeal == true)
                {
                    resultDO.Status = (int)Enums.QuestionnaireStageStatus.申诉中;
                    resultDO.ClientUserAuditStatus = (int)Enums.QuestionnaireAuditStatus.未审核;
                    APUsersDO clientUserDO = APUserManager.GetClientUserDO(resultDO.ClientID, WebSiteContext.CurrentProjectID);
                    resultDO.CurrentClientUserID = clientUserDO.ID;
                    WebCommon.SendAppealStartNotice(resultDO, clientUserDO.ID, (int)Enums.QuestionnaireAuditType.质控督导审核);
                }
            }
            else
            {
                resultDO.QCLeaderAuditStatusFirst = (int)Enums.QuestionnaireAuditStatus.不通过;
                resultDO.Status = nextStatus;
                if (nextStatus == (int)Enums.QuestionnaireStageStatus.质控督导审核中)
                {
                    resultDO.QCLeaderAuditStatusFirst = (int)Enums.QuestionnaireAuditStatus.未审核;
                    WebCommon.SendAuditRejectNotice(resultDO, resultDO.QCLeaderUserIDFirst, (int)Enums.QuestionnaireAuditType.研究员审核, auditNotes);
                }
                else if (nextStatus == (int)Enums.QuestionnaireStageStatus.质控审核中)
                {
                    resultDO.QCUserAuditStatus = (int)Enums.QuestionnaireAuditStatus.未审核;
                    WebCommon.SendAuditRejectNotice(resultDO, resultDO.QCUserID, (int)Enums.QuestionnaireAuditType.质控审核, auditNotes);
                }
                else if (nextStatus == (int)Enums.QuestionnaireStageStatus.区控审核中)
                {
                    resultDO.QCUserAuditStatus = (int)Enums.QuestionnaireAuditStatus.未审核;
                    resultDO.AreaUserAuditStatus = (int)Enums.QuestionnaireAuditStatus.未审核;
                    WebCommon.SendAuditRejectNotice(resultDO, resultDO.AreaUserID, (int)Enums.QuestionnaireAuditType.区控审核, auditNotes);
                }
                else if (nextStatus == (int)Enums.QuestionnaireStageStatus.执行督导审核中)
                {
                    resultDO.QCUserAuditStatus = (int)Enums.QuestionnaireAuditStatus.未审核;
                    resultDO.AreaUserAuditStatus = (int)Enums.QuestionnaireAuditStatus.未审核;
                    resultDO.CityUserAuditStatus = (int)Enums.QuestionnaireAuditStatus.未审核;
                    WebCommon.SendAuditRejectNotice(resultDO, resultDO.CityUserID, (int)Enums.QuestionnaireAuditType.执行督导审核, auditNotes);
                }
                else if (nextStatus == (int)Enums.QuestionnaireStageStatus.录入中)
                {
                    resultDO.QCUserAuditStatus = (int)Enums.QuestionnaireAuditStatus.未审核;
                    resultDO.AreaUserAuditStatus = (int)Enums.QuestionnaireAuditStatus.未审核;
                    resultDO.CityUserAuditStatus = (int)Enums.QuestionnaireAuditStatus.未审核;
                    resultDO.VisitUserUploadStatus = (int)Enums.QuestionnaireUploadStatus.录入待修改;
                    WebCommon.SendAuditRejectNoticeVisitor(resultDO, resultDO.VisitUserID, auditNotes);
                }
            }
        }
        else if (_typeID == (int)Enums.QuestionnaireAuditType.客户审核)
        {
            int currentClientID = WebSiteContext.Current.CurrentUser.ClientID;
            APClientsDO clientDO = APClientManager.GetClientDOByID(currentClientID);
            resultDO.ClientUserAuditTime = currentTime;
            resultDO.ClientUserID = WebSiteContext.CurrentUserID;

            if (bApproved == true)
            {
                //审核通过
                int topClientID = APClientManager.GetTopClientID(WebSiteContext.CurrentProjectID);
                if (topClientID == currentClientID)
                {
                    //总行已审核
                    _returnUserType = (int)Enums.UserType.质控督导;
                    resultDO.ReAuditStatus = 1;
                    resultDO.Status = (int)Enums.QuestionnaireStageStatus.复审中;
                    resultDO.CurrentClientUserID = 0;
                    WebCommon.SendAppealFinalNotice(resultDO, WebSiteContext.Current.CurrentProject.QCLeaderUserID, (int)Enums.QuestionnaireAuditType.质控督导复审);
                }
                else
                {
                    //继续下一级别客户审核
                    APUsersDO parentUserDO = APUserManager.GetClientUserDO(clientDO.ParentID, WebSiteContext.CurrentProjectID);
                    resultDO.CurrentClientUserID = parentUserDO.ID;
                    WebCommon.SendAppealAuditNotice(resultDO, parentUserDO.ID, (int)Enums.QuestionnaireAuditType.客户审核);
                }
                if (_returnUserType == -1)
                {
                    resultDO.ClientUserAuditStatus = (int)Enums.QuestionnaireClientStatus.已提交申诉;
                }
                else
                {
                    resultDO.ClientUserAuditStatus = (int)Enums.QuestionnaireClientStatus.审核通过;
                }
            }
            else
            {
                //审核不通过
                resultDO.ClientUserAuditStatus = (int)Enums.QuestionnaireClientStatus.审核不通过;
                resultDO.CurrentClientUserID = _returnUserType;//for client, this parameter means client user id
                WebCommon.SendAppealRejectNotice(resultDO, _returnUserType, (int)Enums.QuestionnaireAuditType.客户审核, auditNotes);
            }

        }
        else if (_typeID == (int)Enums.QuestionnaireAuditType.质控督导复审)
        {
            string leaveClient = HttpContext.Current.Request.Params["leaveClient"];
            bool bLeaveClient = false;
            bool.TryParse(leaveClient, out bLeaveClient);

            resultDO.QCLeaderAuditTime = currentTime;
            resultDO.QCLeaderUserID = WebSiteContext.CurrentUserID;
            resultDO.ClientUserID = WebSiteContext.CurrentUserID;
            resultDO.ClientUserAuditTime = currentTime;
            if(bLeaveClient == false)
            {
                resultDO.QCLeaderAuditStatus = (int)Enums.QuestionnaireAuditStatus.通过;
                resultDO.ClientUserAuditStatus = (int)Enums.QuestionnaireClientStatus.申诉已处理;
                resultDO.ReAuditStatus = 0;
                resultDO.Status = (int)Enums.QuestionnaireStageStatus.完成;
                WebCommon.SendAppealFinishNotice(resultDO, (int)Enums.QuestionnaireAuditType.客户审核, "申诉已处理", auditNotes);
            }
            else 
            {
                int topClientID = APClientManager.GetTopClientID(WebSiteContext.CurrentProjectID);
                APUsersDO topUserDO = APUserManager.GetClientUserDO(topClientID, WebSiteContext.CurrentProjectID);
                resultDO.QCLeaderAuditStatus = (int)Enums.QuestionnaireAuditStatus.未裁决;
                resultDO.ClientUserAuditStatus = (int)Enums.QuestionnaireClientStatus.申诉未裁决;
                resultDO.CurrentClientUserID = topUserDO.ID;
                resultDO.Status = (int)Enums.QuestionnaireStageStatus.复审中;
                WebCommon.SendAppealStartNotice(resultDO, topUserDO.ID, (int)Enums.QuestionnaireAuditType.质控督导复审);
            }
        }
        else if (_typeID == (int)Enums.QuestionnaireAuditType.终审裁决)
        {
            resultDO.ClientUserID = WebSiteContext.CurrentUserID;
            resultDO.ClientUserAuditTime = currentTime;
            if (bApproved == true)
            {
                resultDO.ClientUserAuditStatus = (int)Enums.QuestionnaireClientStatus.申诉已处理;
                resultDO.ReAuditStatus = 0;
                resultDO.Status = (int)Enums.QuestionnaireStageStatus.完成;
                WebCommon.SendAppealFinishNotice(resultDO, (int)Enums.QuestionnaireAuditType.客户审核, "申诉已处理", auditNotes);
            }
            else
            {
                resultDO.ClientUserAuditStatus = (int)Enums.QuestionnaireClientStatus.申诉已处理;
                resultDO.ReAuditStatus = 0;
                resultDO.Status = (int)Enums.QuestionnaireStageStatus.完成;
                WebCommon.SendAppealFinishNotice(resultDO, (int)Enums.QuestionnaireAuditType.客户审核, "申诉已处理", auditNotes);
            }
        }
        BusinessLogicBase.Default.Update(resultDO);

        int returnUserID = 0;
        if (_returnUserType == (int)Enums.UserType.访问员)
        {
            returnUserID = resultDO.VisitUserID;
        }
        else if (_returnUserType == (int)Enums.UserType.执行督导)
        {
            returnUserID = resultDO.CityUserID;
        }
        else if (_returnUserType == (int)Enums.UserType.区控)
        {
            returnUserID = resultDO.AreaUserID;
        }
        else if (_returnUserType == (int)Enums.UserType.质控员)
        {
            returnUserID = resultDO.QCUserID;
        }


        if (_typeID == (int)Enums.QuestionnaireAuditType.客户审核)
        {
            returnUserID = _returnUserType;
        }

        APAuditHistoryDO auditDO = new APAuditHistoryDO();
        auditDO.AuditTime = currentTime;
        auditDO.AuditNotes = auditNotes;
        auditDO.AuditUserID = WebSiteContext.CurrentUserID;
        auditDO.ClientID = resultDO.ClientID;
        auditDO.QuestionnaireResultID = resultDO.ID;
        auditDO.AuditStatus = currentStatus;
        auditDO.AuditResult = bApproved;
        auditDO.ReturnUserType = _returnUserType;
        auditDO.ReturnUserID = returnUserID;
        auditDO.TypeID = _typeID;
        auditDO.ProjectID = WebSiteContext.CurrentProjectID;
        BusinessLogicBase.Default.Insert(auditDO);

        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void SubmitClientAuditCancel()
    {
        string resultID = HttpContext.Current.Request.Params["resultID"];
        string auditNotes = HttpContext.Current.Request.Params["auditNotes"];
        string typeID = HttpContext.Current.Request.Params["typeID"];
        int _resultID = 0;
        int.TryParse(resultID, out _resultID);
        int _typeID = 0;
        int.TryParse(typeID, out _typeID);

        bool bApproved = false;
        int _returnUserType = (int)Enums.UserType.客户;

        APQuestionnaireResultsDO resultDO = APQuestionnaireManager.GetQuestionnaireResultDOByID(_resultID);
        APClientsDO currentClientDO = APClientManager.GetClientDOByID(resultDO.ClientID);
        if (currentClientDO.ProjectID != WebSiteContext.CurrentProjectID)
        {
            string result = "-1";
            HttpContext.Current.Response.ContentType = "application/json";
            HttpContext.Current.Response.Write(result);
            return;
        }

        DateTime currentTime = DateTime.Now;
        int currentStatus = resultDO.Status;
        resultDO.ClientUserAuditStatus = (int)Enums.QuestionnaireClientStatus.审核不通过;
        resultDO.Status = (int)Enums.QuestionnaireStageStatus.申诉中;
        resultDO.ClientUserID = WebSiteContext.CurrentUserID;
        resultDO.CurrentClientUserID = -1;
        BusinessLogicBase.Default.Update(resultDO);

        int returnUserID = resultDO.ClientUserID;
        APAuditHistoryDO auditDO = new APAuditHistoryDO();
        auditDO.AuditTime = currentTime;
        auditDO.AuditNotes = auditNotes;
        auditDO.AuditUserID = WebSiteContext.CurrentUserID;
        auditDO.ClientID = resultDO.ClientID;
        auditDO.QuestionnaireResultID = resultDO.ID;
        auditDO.AuditStatus = currentStatus;
        auditDO.AuditResult = bApproved;
        auditDO.ReturnUserType = _returnUserType;
        auditDO.ReturnUserID = returnUserID;
        auditDO.TypeID = _typeID;
        auditDO.ProjectID = WebSiteContext.CurrentProjectID;
        BusinessLogicBase.Default.Insert(auditDO);

        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetQuestionnaireCheckList()
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
        string stageStatus = HttpContext.Current.Request.QueryString["stageStatus"];
        string keyword = HttpContext.Current.Request.QueryString["keyword"];
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
        int projectID = WebSiteContext.CurrentProjectID;
        int roleID = WebSiteContext.Current.CurrentUser.RoleID;
        int userID = WebSiteContext.CurrentUserID;

        int _stageStatus = 0;
        int.TryParse(stageStatus, out _stageStatus);
        DateTime fromdate = Constants.Date_Min;
        DateTime todate = Constants.Date_Max;
        if (period != "-999")
        {
            int splitCharIndex = period.IndexOf('|');
            string strFromDate = period.Substring(0, splitCharIndex).Trim();
            string strToDate = period.Substring(splitCharIndex + 1).Trim();
            DateTime.TryParse(strFromDate, out fromdate);
            DateTime.TryParse(strToDate, out todate);
        }

        DataTable dt = APQuestionnaireManager.GetQuestionnaireCheckList(projectID, _qid, _areaID, _levelID, _typeID, _statusID, province, city, district, roleID, userID, fromdate, todate, _stageStatus, keyword);
        string jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetQuestionnaireCheckListClient()
    {
        string qid = HttpContext.Current.Request.QueryString["qid"];
        string statusID = HttpContext.Current.Request.QueryString["statusID"];
        string province = HttpContext.Current.Request.QueryString["province"];
        string city = HttpContext.Current.Request.QueryString["city"];
        string district = HttpContext.Current.Request.QueryString["district"];
        string period = HttpContext.Current.Request.QueryString["period"];
        string stageStatus = HttpContext.Current.Request.QueryString["stageStatus"];
        string keyword = HttpContext.Current.Request.QueryString["keyword"];
        int _qid = 0;
        int _statusID = 0;
        int.TryParse(qid, out _qid);
        int.TryParse(statusID, out _statusID);
        int projectID = WebSiteContext.CurrentProjectID;
        int clientID = WebSiteContext.Current.CurrentUser.ClientID;

        int _stageStatus = 0;
        int _levelID = 0;
        string[] strStage = stageStatus.Split('|');
        if (strStage.Length <= 1)
        {
            int.TryParse(stageStatus, out _stageStatus);
        }
        else {
            int.TryParse(strStage[0], out _stageStatus);
            int.TryParse(strStage[1], out _levelID);
        }
        DateTime fromdate = Constants.Date_Min;
        DateTime todate = Constants.Date_Max;
        if (period != "-999")
        {
            int splitCharIndex = period.IndexOf('|');
            string strFromDate = period.Substring(0, splitCharIndex).Trim();
            string strToDate = period.Substring(splitCharIndex + 1).Trim();
            DateTime.TryParse(strFromDate, out fromdate);
            DateTime.TryParse(strToDate, out todate);
        }

        DataTable dt = APQuestionnaireManager.GetQuestionnaireCheckListClient(projectID, _qid, _statusID, province, city, district, clientID, fromdate, todate, _stageStatus, _levelID, keyword);
        string jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetQuestionnaireCheckListQCLeader()
    {
        string qid = HttpContext.Current.Request.QueryString["qid"];
        string statusID = HttpContext.Current.Request.QueryString["statusID"];
        string province = HttpContext.Current.Request.QueryString["province"];
        string city = HttpContext.Current.Request.QueryString["city"];
        string district = HttpContext.Current.Request.QueryString["district"];
        string period = HttpContext.Current.Request.QueryString["period"];
        string stageStatus = HttpContext.Current.Request.QueryString["stageStatus"];
        string keyword = HttpContext.Current.Request.QueryString["keyword"];
        int _qid = 0;
        int _statusID = 0;
        int.TryParse(qid, out _qid);
        int.TryParse(statusID, out _statusID);
        int projectID = WebSiteContext.CurrentProjectID;
        int clientID = WebSiteContext.Current.CurrentUser.ClientID;

        int _stageStatus = 0;
        int.TryParse(stageStatus, out _stageStatus);
        DateTime fromdate = Constants.Date_Min;
        DateTime todate = Constants.Date_Max;
        if (period != "-999")
        {
            int splitCharIndex = period.IndexOf('|');
            string strFromDate = period.Substring(0, splitCharIndex).Trim();
            string strToDate = period.Substring(splitCharIndex + 1).Trim();
            DateTime.TryParse(strFromDate, out fromdate);
            DateTime.TryParse(strToDate, out todate);
        }

        DataTable dt = APQuestionnaireManager.GetQuestionnaireCheckListQCLeader(projectID, _qid, _statusID, province, city, district, clientID, fromdate, todate, _stageStatus, keyword);
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