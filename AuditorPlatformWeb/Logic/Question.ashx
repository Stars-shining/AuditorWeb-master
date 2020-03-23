<%@ WebHandler Language="C#" Class="Question" %>

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

public class Question : IHttpHandler, IRequiresSessionState
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
                case 15:
                    GetQ7ForUpload();
                    break;
                case 16:
                    GoNextQ7();
                    break;
                case 17:
                    GetQuestionnaireProgressForUpload();
                    break;
                case 18:
                    GetQ1ForUpload();
                    break;
                case 19:
                    SubmitQ1Upload();
                    break;
                case 20:
                    GetQ1Answer();
                    break;
                case 21:
                    SubmitQ7Upload();
                    break;
                case 22:
                    GetQ7Answer();
                    break;
                case 23:
                    SubmitQ3Upload();
                    break;
                case 24:
                    SubmitQ4Upload();
                    break;
                case 25:
                    SubmitQuestionnaireUpload();
                    break;
                case 26:
                    GetQuestionnaireAnswers();
                    break;
                case 27:
                    SetFullScore();
                    break;
                case 28:
                    SaveUploadStartInfo();
                    break;
                case 29:
                    GetQuestionnaireAnswersWithCorrectOptions();
                    break;
                case 30:
                    GetQuestionnaireAnswersInfoPart();
                    break;
                case 31:
                    GetQuestionnaireAnswersPart();
                    break;
                case 32:
                    GetQuestionsByResultID();
                    break;
                case 33:
                    DownloadQuestionnaireAnswers();
                    break;
                case 34:
                    GetQuestionsByQuestionnaireID();
                    break;
                case 35:
                    GetSelectQuestionsByQuestionnaireID();
                    break;
                case 36:
                    GetQuestionAnswerOptions();
                    break;
                case 37:
                    GetSubClientAnswerOptionStatistics();
                    break;
                case 38:
                    SubmitQ8Upload();
                    break;
                default:
                    break;
            }
        }
        catch { }
    }

    public void GetSubClientAnswerOptionStatistics() 
    {
        string questionnaireID = HttpContext.Current.Request.QueryString["questionnaireID"];
        string questionID = HttpContext.Current.Request.QueryString["questionID"];
        string period = HttpContext.Current.Request.QueryString["period"];
        string clientID = HttpContext.Current.Request.QueryString["clientID"];
        int _questionnaireID = 0;
        int _questionID = 0;
        int _clientID = 0;
        int.TryParse(questionnaireID, out _questionnaireID);
        int.TryParse(questionID, out _questionID);
        int.TryParse(clientID, out _clientID);
        int projectID = WebSiteContext.CurrentProjectID;
        if (_clientID == 0)
        {
            _clientID = WebSiteContext.Current.CurrentUser.ClientID;
        }
        DateTime fromDate = Constants.Date_Null;
        DateTime toDate = Constants.Date_Null;
        string[] values = period.Split(new char[] { '|' }, StringSplitOptions.RemoveEmptyEntries);
        string strFrom = values[0];
        string strTo = values[1];
        DateTime.TryParse(strFrom, out fromDate);
        DateTime.TryParse(strTo, out toDate);

        DataTable dt = APQuestionManager.GetSubClientAnswerOptionStatistics(projectID, _questionnaireID, _questionID, fromDate, toDate, _clientID);
        string jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetQuestionAnswerOptions() 
    {
        string questionnaireID = HttpContext.Current.Request.QueryString["questionnaireID"];
        string questionID = HttpContext.Current.Request.QueryString["questionID"];
        string period = HttpContext.Current.Request.QueryString["period"];
        string clientID = HttpContext.Current.Request.QueryString["clientID"];
        int _questionnaireID = 0;
        int _questionID = 0;
        int _clientID = 0;
        int.TryParse(questionnaireID, out _questionnaireID);
        int.TryParse(questionID, out _questionID);
        int.TryParse(clientID, out _clientID);
        int projectID = WebSiteContext.CurrentProjectID;
        if (_clientID == 0)
        {
            _clientID = WebSiteContext.Current.CurrentUser.ClientID;
        }
        DateTime fromDate = Constants.Date_Null;
        DateTime toDate = Constants.Date_Null;
        string[] values = period.Split(new char[] { '|' }, StringSplitOptions.RemoveEmptyEntries);
        string strFrom = values[0];
        string strTo = values[1];
        DateTime.TryParse(strFrom, out fromDate);
        DateTime.TryParse(strTo, out toDate);

        DataTable dt = APQuestionManager.GetAnswerOptionStatistics(projectID, _questionnaireID, _questionID, fromDate, toDate, _clientID);
        string jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    //获取问卷中所有带选项的题目（单选题，多选题，是非题）
    public void GetSelectQuestionsByQuestionnaireID() 
    {
        string questionnaireID = HttpContext.Current.Request.QueryString["questionnaireID"];
        int _questionnaireID = 0;
        int.TryParse(questionnaireID, out _questionnaireID);
        DataTable dt = APQuestionManager.GetSelectQuestionsByQuestionnaireID(_questionnaireID);
        string jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetQuestionsByQuestionnaireID() 
    {

        string questionnaireID = HttpContext.Current.Request.QueryString["questionnaireID"];
        int _questionnaireID = 0;
        int.TryParse(questionnaireID, out _questionnaireID);

        DataSet ds = APQuestionManager.GetQuestionsByQuestionnaireID(_questionnaireID);
        DataTable dtQuestions = ds.Tables[0];
        DataTable dtOptions = ds.Tables[1];

        StringBuilder sb = new StringBuilder();
        sb.Append("[");  
        
        if (dtQuestions != null)
        {
            DataColumnCollection columnList = dtQuestions.Columns;
            DataColumnCollection optionColumnList = dtOptions.Columns;

            for (int i = 0; i < dtQuestions.Rows.Count; i++)
            {
                DataRow row = dtQuestions.Rows[i];
                int questionID = 0;
                int questionType = 0;
                int.TryParse(row["ID"].ToString(), out questionID);
                int.TryParse(row["QuestionType"].ToString(), out questionType);
                
                sb.Append("{");
                foreach (DataColumn dc in columnList)
                {
                    string columnName = dc.ColumnName;
                    string value = row[columnName].ToString();
                    sb.Append("\"" + columnName + "\":" + "\"" + value + "\",");
                }
                if (questionType == (int)Enums.QuestionType.单选题 ||
                    questionType == (int)Enums.QuestionType.多选题 ||
                    questionType == (int)Enums.QuestionType.是非题)
                {
                    sb.Append("\"Options\":[");

                    DataRow[] optionRows = dtOptions.Select("QuestionID=" + questionID);
                    if (optionRows != null)
                    {
                        for (int j = 0; j < optionRows.Length;j++ )
                        {
                            DataRow oRow = optionRows[j];
                            sb.Append("{");
                            for (int oIndex = 0; oIndex < optionColumnList.Count; oIndex++)
                            {
                                DataColumn dcOption = optionColumnList[oIndex];
                                string optionColumnName = dcOption.ColumnName;
                                string optionValue = oRow[optionColumnName].ToString();
                                if (oIndex < optionColumnList.Count - 1)
                                {
                                    sb.Append("\"" + optionColumnName + "\":" + "\"" + optionValue + "\",");
                                }
                                else
                                {
                                    sb.Append("\"" + optionColumnName + "\":" + "\"" + optionValue + "\"");
                                }
                            }

                            if (j < optionRows.Length - 1)
                            {
                                sb.Append("},");
                            }
                            else
                            {
                                sb.Append("}");
                            }
                        }
                    }
                    sb.Append("]");
                }
                else
                {
                    sb.Append("\"Options\":[]");
                }

                if (i < dtQuestions.Rows.Count - 1)
                {
                    sb.Append("},");
                }
                else
                {
                    sb.Append("}");
                }
            }
        }

        sb.Append("]");
        string strQuestions = sb.ToString();
        strQuestions = Regex.Replace(strQuestions, @"[\n\r]", "");
        strQuestions = strQuestions.Replace(@"\", @"\\");
        strQuestions = strQuestions.Replace(@"\\\\", @"\\");

        string jsonResult = "{\"Questions\":" + strQuestions + "}";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetQuestionsByResultID() 
    {
        string resultID = HttpContext.Current.Request.QueryString["resultID"];
        int _resultID = 0;
        int.TryParse(resultID, out _resultID);
        
        DataSet ds = APQuestionManager.GetQuestionsByResultIDWithOptions(_resultID);
        DataTable dtQuestions = ds.Tables[0];
        DataTable dtOptions = ds.Tables[1];
        DataTable dtAnswerOptions = ds.Tables[2];

        APQuestionnairesDO ado = APQuestionnaireManager.GetQuestionnaireByResultID(_resultID);
        string tickCorrectOption = ado.BAutoTickCorrectOption ? "1" : "0";

        StringBuilder sb = new StringBuilder();
        sb.Append("[");  
        
        if (dtQuestions != null)
        {
            DataColumnCollection columnList = dtQuestions.Columns;
            DataColumnCollection optionColumnList = dtOptions.Columns;

            for (int i = 0; i < dtQuestions.Rows.Count; i++)
            {
                DataRow row = dtQuestions.Rows[i];
                int questionID = 0;
                int questionType = 0;
                int.TryParse(row["ID"].ToString(), out questionID);
                int.TryParse(row["QuestionType"].ToString(), out questionType);
                
                sb.Append("{");
                foreach (DataColumn dc in columnList)
                {
                    string columnName = dc.ColumnName;
                    string value = row[columnName].ToString();
                    sb.Append("\"" + columnName + "\":" + "\"" + value + "\",");
                }
                if (questionType == (int)Enums.QuestionType.单选题 ||
                    questionType == (int)Enums.QuestionType.多选题 ||
                    questionType == (int)Enums.QuestionType.是非题)
                {
                    sb.Append("\"Options\":[");

                    DataRow[] optionRows = dtOptions.Select("QuestionID=" + questionID);
                    if (optionRows != null)
                    {
                        for (int j = 0; j < optionRows.Length;j++ )
                        {
                            DataRow oRow = optionRows[j];
                            sb.Append("{");
                            for (int oIndex = 0; oIndex < optionColumnList.Count; oIndex++)
                            {
                                DataColumn dcOption = optionColumnList[oIndex];
                                string optionColumnName = dcOption.ColumnName;
                                string optionValue = oRow[optionColumnName].ToString();
                                if (oIndex < optionColumnList.Count - 1)
                                {
                                    sb.Append("\"" + optionColumnName + "\":" + "\"" + optionValue + "\",");
                                }
                                else
                                {
                                    sb.Append("\"" + optionColumnName + "\":" + "\"" + optionValue + "\"");
                                }
                            }

                            if (j < optionRows.Length - 1)
                            {
                                sb.Append("},");
                            }
                            else
                            {
                                sb.Append("}");
                            }
                        }
                    }
                    sb.Append("]");
                }
                else
                {
                    sb.Append("\"Options\":[]");
                }

                if (i < dtQuestions.Rows.Count - 1)
                {
                    sb.Append("},");
                }
                else
                {
                    sb.Append("}");
                }
            }
        }

        sb.Append("]");
        string strQuestions = sb.ToString();
        strQuestions = Regex.Replace(strQuestions, @"[\n\r]", "");
        strQuestions = strQuestions.Replace(@"\", @"\\");
        strQuestions = strQuestions.Replace(@"\\\\", @"\\");

        string strAnswerOptions = JSONHelper.DataTableToJSON(dtAnswerOptions);
        string jsonResult = "{\"BAutoTickCorrectOption\":" + tickCorrectOption + ",\"Questions\":" + strQuestions + ",\"AnswerOptions\":" + strAnswerOptions + "}";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetQuestionnaireAnswersInfoPart()
    {
        string resultID = HttpContext.Current.Request.QueryString["resultID"];
        int _resultID = 0;
        int.TryParse(resultID, out _resultID);

        DataTable dtInfo = APQuestionManager.GetQuestionnaireResultInfo(_resultID);
        dtInfo.Columns.Add("CoverImage");
        if (dtInfo != null && dtInfo.Rows.Count > 0) 
        {
            string playType = dtInfo.Rows[0]["PlayType"].ToString();
            string playPath = dtInfo.Rows[0]["PlayPath"].ToString();
            if (playType == "3") 
            {
                //录像，需要判断视频封面截图是否存在
                string relevantPath = playPath.Replace("../", "~/");
                string diskPath = HttpContext.Current.Server.MapPath(relevantPath);
                string coverPath = System.IO.Path.ChangeExtension(diskPath, ".jpg");
                if (System.IO.File.Exists(coverPath))
                {
                    dtInfo.Rows[0]["CoverImage"] = System.IO.Path.ChangeExtension(playPath, ".jpg");
                }
                else
                {
                    dtInfo.Rows[0]["CoverImage"] = "";
                }
            }
        }
        
        string jsonInfo = JSONHelper.DataTableToJSON(dtInfo);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonInfo);
    }

    public void GetQuestionnaireAnswersPart()
    {
        string resultID = HttpContext.Current.Request.QueryString["resultID"];
        int _resultID = 0;
        int.TryParse(resultID, out _resultID);

        DataTable dtAnswers = APQuestionManager.GetQuestionnaireAnswers(_resultID);
        string jsonAnswers = JSONHelper.DataTableToJSON(dtAnswers);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonAnswers);
    }

    public void GetQuestionnaireAnswersWithCorrectOptions()
    {
        string resultID = HttpContext.Current.Request.QueryString["resultID"];
        int _resultID = 0;
        int.TryParse(resultID, out _resultID);

        DataTable dtInfo = APQuestionManager.GetQuestionnaireResultInfo(_resultID);
        DataTable dtAnswers = APQuestionManager.GetQuestionnaireAnswers(_resultID);
        string jsonInfo = JSONHelper.DataTableToJSON(dtInfo);
        string jsonAnswers = JSONHelper.DataTableToJSON(dtAnswers);
        string jsonResult = "{\"Info\":" + jsonInfo + ",\"Answers\":" + jsonAnswers + "}";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void SaveUploadStartInfo()
    {
        string deliveryID = HttpContext.Current.Request.Params["deliveryID"];
        string clientID = HttpContext.Current.Request.Params["clientID"];
        int _deliveryID = 0;
        int _clientID = 0;
        int.TryParse(deliveryID, out _deliveryID);
        int.TryParse(clientID, out _clientID);

        APQuestionnaireResultsDO resultsDO = APQuestionnaireManager.GetQuestionnaireResultDOByDeliveryIDAndClientID(_deliveryID, _clientID, (int)Enums.QuestionnaireUploadStatus.未录入);
        if (resultsDO != null && resultsDO.ID > 0)
        {
            HttpContext.Current.Response.ContentType = "text/plain";
            HttpContext.Current.Response.Write(resultsDO.ID.ToString());
            return;
        }

        APQuestionnaireDeliveryDO deliveryDO = new APQuestionnaireDeliveryDO();
        deliveryDO = (APQuestionnaireDeliveryDO)BusinessLogicBase.Default.Select(deliveryDO, _deliveryID);
        DateTime fromDate = deliveryDO.FromDate;
        DateTime toDate = deliveryDO.ToDate;

        resultsDO = new APQuestionnaireResultsDO();
        resultsDO.QuestionnaireID = deliveryDO.QuestionnaireID;
        resultsDO.DeliveryID = _deliveryID;
        resultsDO.ClientID = _clientID;
        resultsDO.VisitUserID = WebSiteContext.CurrentUserID;
        resultsDO.VisitUserUploadStatus = (int)Enums.QuestionnaireUploadStatus.未录入;
        resultsDO.UploadBeginTime = DateTime.Now;
        resultsDO.FromDate = fromDate;
        resultsDO.ToDate = toDate;
        resultsDO.ProjectID = deliveryDO.ProjectID;
        int resultID = BusinessLogicBase.Default.Insert(resultsDO);

        decimal totalScore = 0m;
        APQuestionnairesDO questionnaireDO = APQuestionnaireManager.GetQuestionnaireByID(deliveryDO.QuestionnaireID);
        if (questionnaireDO.BAutoTickCorrectOption == true) 
        {
            DataSet ds = APQuestionnaireManager.GetQuestionnaireDefaultCorrectOptions(deliveryDO.QuestionnaireID);
            DataTable dtQuestions = ds.Tables[0];
            DataTable dtOptions = ds.Tables[1];

            if (dtQuestions != null && dtQuestions.Rows.Count > 0) 
            {
                for (int i = 0; i < dtQuestions.Rows.Count; i++) 
                {
                    DataRow row = dtQuestions.Rows[i];
                    int questionID = 0;
                    int.TryParse(row["ID"].ToString(), out questionID);

                    List<int> selectedOptionList = new List<int>();
                    DataRow[] optionRows = dtOptions.Select("QuestionID=" + questionID);
                    if (optionRows != null && optionRows.Length > 0) 
                    {
                        foreach (DataRow optionRow in optionRows) 
                        {
                            int optionID = 0;
                            int.TryParse(optionRow["ID"].ToString(), out optionID);
                            selectedOptionList.Add(optionID);
                        }
                    }
                    decimal score = APQuestionManager.CalculateQuestionScore(questionID, selectedOptionList.ToArray());
                    totalScore += score;
                    APAnswersDO answerDO = new APAnswersDO();
                    answerDO.ResultID = resultID;
                    answerDO.QuestionID = questionID;
                    answerDO.TotalScore = score;
                    answerDO.Status = 1;
                    answerDO.CreateTime = DateTime.Now;
                    answerDO.CreateUserID = WebSiteContext.CurrentUserID;
                    int answerID = BusinessLogicBase.Default.Insert(answerDO);
                    foreach (int optionID in selectedOptionList) 
                    {
                        APAnswerOptionsDO answerOptionDO = new APAnswerOptionsDO();
                        answerOptionDO.AnswerID = answerID;
                        answerOptionDO.OptionID = optionID;
                        answerOptionDO.OptionText = "";
                        int answerOptionID = BusinessLogicBase.Default.Insert(answerOptionDO);
                    }
                    
                }
            }
        }
        
        resultsDO.ID = resultID;
        resultsDO.Score = totalScore;
        BusinessLogicBase.Default.Update(resultsDO);
        
        string jsonResult = resultID.ToString();
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void SetFullScore()
    {
        string questionID = HttpContext.Current.Request.Params["questionID"];
        string resultID = HttpContext.Current.Request.Params["resultID"];
        string answerID = HttpContext.Current.Request.Params["answerID"];

        int _questionID = 0;
        int _resultID = 0;
        int _answerID = 0;

        int.TryParse(questionID, out _questionID);
        int.TryParse(resultID, out _resultID);
        int.TryParse(answerID, out _answerID);

        decimal oldScore = 0m;
        //save answer information
        APAnswersDO ado = new APAnswersDO();
        APQuestionsDO qdo = APQuestionnaireManager.GetQuestionDOByID(_questionID);
        decimal score = qdo.TotalScore;
        if (qdo.CountType == (int)Enums.QuestionCountType.错误扣分)
        {
            score = 0m;
        }
        if (_answerID > 0)
        {
            ado = (APAnswersDO)BusinessLogicBase.Default.Select(ado, _answerID);
            oldScore = ado.TotalScore;
            ado.TotalScore = score;
            ado.LastModifiedTime = DateTime.Now;
            ado.LastModifiedUserID = WebSiteContext.CurrentUserID;
            BusinessLogicBase.Default.Update(ado);

            APQuestionnaireResultsDO resultDO = APQuestionnaireManager.GetQuestionnaireResultDOByID(_resultID);
            resultDO.Score = resultDO.Score - oldScore + score;
            resultDO.LastModifiedTime = DateTime.Now;
            resultDO.LastModifiedUserID = WebSiteContext.CurrentUserID;
            BusinessLogicBase.Default.Update(resultDO);

            //update questionnaire result
            string editNote = string.Format("未修改");
            string scoreNote = string.Format("从 {0} 修改为 {1}", oldScore.ToString("0.0"), score.ToString("0.0"));
            APAnswerEditHistoryDO ehDO = new APAnswerEditHistoryDO();
            ehDO.AnswerID = ado.ID;
            ehDO.ResultID = _resultID;
            ehDO.StageStatusID = resultDO.Status;
            ehDO.UserID = WebSiteContext.CurrentUserID;
            ehDO.InputDate = DateTime.Now;
            ehDO.EditNote = editNote;
            ehDO.ScoreNote = scoreNote;
            BusinessLogicBase.Default.Insert(ehDO);
        }

        

        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetQ7Answer()
    {
        string questionID = HttpContext.Current.Request.QueryString["questionID"];
        string resultID = HttpContext.Current.Request.QueryString["resultID"];

        int _questionID = 0;
        int _resultID = 0;
        int.TryParse(questionID, out _questionID);
        int.TryParse(resultID, out _resultID);
        APAnswersDO ado = APQuestionManager.GetAnwserDO(_resultID, _questionID);
        string strAnswer = JSONHelper.ObjectToJSON(ado);
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(strAnswer);
    }

    public void GetQ1Answer()
    {
        string questionID = HttpContext.Current.Request.QueryString["questionID"];
        string resultID = HttpContext.Current.Request.QueryString["resultID"];

        int _questionID = 0;
        int _resultID = 0;
        int.TryParse(questionID, out _questionID);
        int.TryParse(resultID, out _resultID);
        APAnswersDO ado = APQuestionManager.GetAnwserDO(_resultID, _questionID);
        string strAnswer = JSONHelper.ObjectToJSON(ado);
        string strOptions = "[]";
        if (ado != null && ado.ID > 0)
        {
            DataTable dt = APQuestionManager.GetAnswerOptions(ado.ID);
            strOptions = JSONHelper.DataTableToJSON(dt);
        }
        string jsonResult = "{\"Answer\":" + strAnswer + ",\"Options\":" + strOptions + "}";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }
    /// <summary>
    /// for both Q1 and Q2
    /// </summary>
    public void SubmitQ1Upload()
    {
        string questionID = HttpContext.Current.Request.Params["questionID"];
        string resultID = HttpContext.Current.Request.Params["resultID"];
        string answerID = HttpContext.Current.Request.Params["answerID"];
        string tempCode = HttpContext.Current.Request.Params["tempCode"];
        string description = HttpContext.Current.Request.Params["description"];
        string selectOptionID = HttpContext.Current.Request.Params["selectOptionID"];
        string additionalText = HttpContext.Current.Request.Params["additionalText"];
        string editFlag = HttpContext.Current.Request.Params["editFlag"];

        int _questionID = 0;
        int _resultID = 0;
        int _answerID = 0;
        int _selectOptionID = 0;

        int.TryParse(questionID, out _questionID);
        int.TryParse(resultID, out _resultID);
        int.TryParse(answerID, out _answerID);
        int.TryParse(selectOptionID, out _selectOptionID);

        if (WebSiteContext.CurrentUserID <= 0)
        {
            HttpContext.Current.Response.ContentType = "text/plain";
            HttpContext.Current.Response.Write("0");
            return;
        }

        decimal oldScore = 0m;
        //save answer information  
        APAnswersDO ado = new APAnswersDO();      
        if (_answerID > 0)
        {
            ado = (APAnswersDO)BusinessLogicBase.Default.Select(ado, _answerID);
            oldScore = ado.TotalScore;
        }
        else 
        {
            ado = APQuestionManager.GetAnwserDO(_resultID, _questionID);
            if (ado != null && ado.ID > 0) 
            {
                HttpContext.Current.Response.ContentType = "text/plain";
                HttpContext.Current.Response.Write("0");
                return;
            }
            else
            {
                ado = new APAnswersDO();
            }
        }
        
        string oldOptionText = string.Empty;
        if (_answerID > 0)
        {
            oldOptionText = APQuestionManager.GetAnswerOptionText(_answerID);
        }
        
        ado.ResultID = _resultID;
        ado.QuestionID = _questionID;
        ado.Description = description;
        ado.Status = (int)Enums.DeleteStatus.正常;
        decimal score = APQuestionManager.CalculateQuestionScore(_questionID,_selectOptionID);
        ado.TotalScore = score;

        if (_answerID<=0)
        {
            ado.CreateTime = DateTime.Now;
            ado.CreateUserID = WebSiteContext.CurrentUserID;

            _answerID = BusinessLogicBase.Default.Insert(ado);

        }
        else if (_answerID > 0)
        {
            ado.LastModifiedTime = DateTime.Now;
            ado.LastModifiedUserID = WebSiteContext.CurrentUserID;

            BusinessLogicBase.Default.Update(ado);
        }

        //save options information
        APQuestionManager.ClearAnswerOptions(_answerID);
        APAnswerOptionsDO answerOptionDO = new APAnswerOptionsDO();
        answerOptionDO.AnswerID = _answerID;
        answerOptionDO.OptionID = _selectOptionID;
        answerOptionDO.OptionText = additionalText;
        BusinessLogicBase.Default.Insert(answerOptionDO);
        //save attachment information
        if (ado.ID <= 0)
        {
            APQuestionManager.UpdateAttachmentRelatedIDByTempCode(_answerID, tempCode);
        }
        //update questionnaire result
        APQuestionnaireResultsDO resultDO = APQuestionnaireManager.GetQuestionnaireResultDOByID(_resultID);
        if (ado.ID > 0 && resultDO != null && resultDO.Status > 0)
        {
            string newOptionText = APQuestionManager.GetAnswerOptionText(ado.ID);
            string editNote = string.Format("从 {0} 修改为 {1}", oldOptionText, newOptionText);
            string scoreNote = string.Format("从 {0} 修改为 {1}", oldScore.ToString("0.0"), score.ToString("0.0"));
            APAnswerEditHistoryDO ehDO = new APAnswerEditHistoryDO();
            ehDO.AnswerID = ado.ID;
            ehDO.ResultID = _resultID;
            ehDO.StageStatusID = resultDO.Status;
            ehDO.UserID = WebSiteContext.CurrentUserID;
            ehDO.InputDate = DateTime.Now;
            ehDO.EditNote = editNote;
            ehDO.ScoreNote = scoreNote;
            BusinessLogicBase.Default.Insert(ehDO);
        }
        
        resultDO.Score = resultDO.Score - oldScore + score;
        if (ado.ID <= 0 && editFlag != "1")
        {
            resultDO.CurrentQuestionID = _questionID;
            int totalNumber = WebSiteContext.Current.CurrentQuestionList.Count;
            int completedNumber = APQuestionManager.GetQuestionnaireCompletedQuestionNumber(_resultID);
            decimal progress = completedNumber * 1m / totalNumber;
            resultDO.CurrentProgress = progress;
            if (progress >= 1m)
            {
                //全部题目已答完
                resultDO.UploadEndTime = DateTime.Now;
                resultDO.VisitUserUploadStatus = (int)Enums.QuestionnaireUploadStatus.录入完成;
            }
        }
        resultDO.LastModifiedTime = DateTime.Now;
        resultDO.LastModifiedUserID = WebSiteContext.CurrentUserID;
        BusinessLogicBase.Default.Update(resultDO);
        APQuestionManager.FixQuestionnaireResultAnswers(resultDO.QuestionnaireID,_questionID, _answerID, _resultID);
        //APQuestionnaireManager.DeleteAllQuestions(_qid);
        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }

    /// <summary>
    /// for both Q3 - 多选题
    /// </summary>
    public void SubmitQ3Upload()
    {
        string questionID = HttpContext.Current.Request.Params["questionID"];
        string resultID = HttpContext.Current.Request.Params["resultID"];
        string answerID = HttpContext.Current.Request.Params["answerID"];
        string tempCode = HttpContext.Current.Request.Params["tempCode"];
        string description = HttpContext.Current.Request.Params["description"];
        string selectOptions = HttpContext.Current.Request.Params["selectOptions"];
        string editFlag = HttpContext.Current.Request.Params["editFlag"];

        int _questionID = 0;
        int _resultID = 0;
        int _answerID = 0;

        int.TryParse(questionID, out _questionID);
        int.TryParse(resultID, out _resultID);
        int.TryParse(answerID, out _answerID);

        if (WebSiteContext.CurrentUserID <= 0)
        {
            HttpContext.Current.Response.ContentType = "text/plain";
            HttpContext.Current.Response.Write("0");
            return;
        }

        decimal oldScore = 0m;
        //save answer information
        APAnswersDO ado = new APAnswersDO();
        if (_answerID > 0)
        {
            ado = (APAnswersDO)BusinessLogicBase.Default.Select(ado, _answerID);
            oldScore = ado.TotalScore;
        }
        else
        {
            ado = APQuestionManager.GetAnwserDO(_resultID, _questionID);
            if (ado != null && ado.ID > 0)
            {
                HttpContext.Current.Response.ContentType = "text/plain";
                HttpContext.Current.Response.Write("0");
                return;
            }
            else 
            {
                ado = new APAnswersDO();
            }
        }
        string oldOptionText = string.Empty;
        if (_answerID > 0)
        {
            oldOptionText = APQuestionManager.GetAnswerOptionText(_answerID);
        }
        ado.ResultID = _resultID;
        ado.QuestionID = _questionID;
        ado.Description = description;
        ado.Status = 1;

        List<int> selectedOptionList = new List<int>();
        if (string.IsNullOrEmpty(selectOptions) == false)
        {
            string[] options = selectOptions.Split(',');
            foreach (string option in options)
            {
                string id = option.Split('|')[0];
                int optionID = 0;
                int.TryParse(id, out optionID);
                selectedOptionList.Add(optionID);
            }
        }
        decimal score = APQuestionManager.CalculateQuestionScore(_questionID, selectedOptionList.ToArray());
        ado.TotalScore = score;       
        
        if (_answerID > 0)
        {
            ado.LastModifiedTime = DateTime.Now;
            ado.LastModifiedUserID = WebSiteContext.CurrentUserID;

            BusinessLogicBase.Default.Update(ado);
        }
        else
        {
            ado.CreateTime = DateTime.Now;
            ado.CreateUserID = WebSiteContext.CurrentUserID;

            _answerID = BusinessLogicBase.Default.Insert(ado);
        }

        //save options information
        APQuestionManager.ClearAnswerOptions(_answerID);
        if (string.IsNullOrEmpty(selectOptions) == false)
        {
            string[] options = selectOptions.Split(',');
            foreach (string option in options)
            {
                string id = option.Split('|')[0];
                string text = option.Split('|')[1];
                int optionID = 0;
                int.TryParse(id, out optionID);
                APAnswerOptionsDO answerOptionDO = new APAnswerOptionsDO();
                answerOptionDO.AnswerID = _answerID;
                answerOptionDO.OptionID = optionID;
                answerOptionDO.OptionText = text;
                BusinessLogicBase.Default.Insert(answerOptionDO);
            }
        }

        //save attachment information
        if (ado.ID <= 0)
        {
            APQuestionManager.UpdateAttachmentRelatedIDByTempCode(_answerID, tempCode);
        }
        //update questionnaire result
        APQuestionnaireResultsDO resultDO = APQuestionnaireManager.GetQuestionnaireResultDOByID(_resultID);
        if (ado.ID > 0 && resultDO != null && resultDO.Status > 0)
        {
            string newOptionText = APQuestionManager.GetAnswerOptionText(ado.ID);
            string editNote = string.Format("从 {0} 修改为 {1}", oldOptionText, newOptionText);
            string scoreNote = string.Format("从 {0} 修改为 {1}", oldScore.ToString("0.0"), score.ToString("0.0"));
            APAnswerEditHistoryDO ehDO = new APAnswerEditHistoryDO();
            ehDO.AnswerID = ado.ID;
            ehDO.ResultID = _resultID;
            ehDO.StageStatusID = resultDO.Status;
            ehDO.UserID = WebSiteContext.CurrentUserID;
            ehDO.InputDate = DateTime.Now;
            ehDO.EditNote = editNote;
            ehDO.ScoreNote = scoreNote;
            BusinessLogicBase.Default.Insert(ehDO);
        }
        
        if (ado.ID <= 0)
        {
            resultDO.Score = resultDO.Score + score;
        }
        else
        {
            resultDO.Score = resultDO.Score - oldScore + score;
        }
        if (ado.ID <= 0 && editFlag != "1")
        {
            resultDO.CurrentQuestionID = _questionID;
            int totalNumber = WebSiteContext.Current.CurrentQuestionList.Count;
            int completedNumber = APQuestionManager.GetQuestionnaireCompletedQuestionNumber(_resultID);
            decimal progress = completedNumber * 1m / totalNumber;
            resultDO.CurrentProgress = progress;
            if (progress >= 1m)
            {
                //全部题目已答完
                resultDO.UploadEndTime = DateTime.Now;
                resultDO.VisitUserUploadStatus = (int)Enums.QuestionnaireUploadStatus.录入完成;
            }
        }
        resultDO.LastModifiedTime = DateTime.Now;
        resultDO.LastModifiedUserID = WebSiteContext.CurrentUserID;
        resultDO.VisitUserID = WebSiteContext.CurrentUserID;
        BusinessLogicBase.Default.Update(resultDO);



        APQuestionManager.FixQuestionnaireResultAnswers(resultDO.QuestionnaireID, _questionID, _answerID, _resultID);
        //APQuestionnaireManager.DeleteAllQuestions(_qid);
        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }

    /// <summary>
    /// for both Q4 - 填空题
    /// </summary>
    public void SubmitQ4Upload()
    {
        string questionID = HttpContext.Current.Request.Params["questionID"];
        string resultID = HttpContext.Current.Request.Params["resultID"];
        string answerID = HttpContext.Current.Request.Params["answerID"];
        string tempCode = HttpContext.Current.Request.Params["tempCode"];
        string description = HttpContext.Current.Request.Params["description"];
        string answerText = HttpContext.Current.Request.Params["answerText"];
        string editFlag = HttpContext.Current.Request.Params["editFlag"];

        int _questionID = 0;
        int _resultID = 0;
        int _answerID = 0;

        int.TryParse(questionID, out _questionID);
        int.TryParse(resultID, out _resultID);
        int.TryParse(answerID, out _answerID);

        if (WebSiteContext.CurrentUserID <= 0)
        {
            HttpContext.Current.Response.ContentType = "text/plain";
            HttpContext.Current.Response.Write("0");
            return;
        }

        //save answer information
        APAnswersDO ado = new APAnswersDO();
        if (_answerID > 0)
        {
            ado = (APAnswersDO)BusinessLogicBase.Default.Select(ado, _answerID);
        }
        else
        {
            ado = APQuestionManager.GetAnwserDO(_resultID, _questionID);
            if (ado != null && ado.ID > 0)
            {
                HttpContext.Current.Response.ContentType = "text/plain";
                HttpContext.Current.Response.Write("0");
                return;
            }
            else
            {
                ado = new APAnswersDO();
            }
        }
        
        string oldOptionText = string.Empty;
        if (_answerID > 0)
        {
            oldOptionText = APQuestionManager.GetAnswerOptionText(_answerID);
        }
        
        ado.ResultID = _resultID;
        ado.QuestionID = _questionID;
        ado.Description = description;
        ado.Status = 1;

        decimal score = 0m;
        ado.TotalScore = score;
        if (_answerID > 0)
        {
            ado.LastModifiedTime = DateTime.Now;
            ado.LastModifiedUserID = WebSiteContext.CurrentUserID;

            BusinessLogicBase.Default.Update(ado);
        }
        else
        {
            ado.CreateTime = DateTime.Now;
            ado.CreateUserID = WebSiteContext.CurrentUserID;

            _answerID = BusinessLogicBase.Default.Insert(ado);
        }

        //save options information
        APQuestionManager.ClearAnswerOptions(_answerID);
        APAnswerOptionsDO answerOptionDO = new APAnswerOptionsDO();
        answerOptionDO.AnswerID = _answerID;
        answerOptionDO.OptionID = -1;
        answerOptionDO.OptionText = answerText;
        BusinessLogicBase.Default.Insert(answerOptionDO);

        //save attachment information
        if (ado.ID <= 0)
        {
            APQuestionManager.UpdateAttachmentRelatedIDByTempCode(_answerID, tempCode);
        }
        
        //update questionnaire result
        APQuestionnaireResultsDO resultDO = APQuestionnaireManager.GetQuestionnaireResultDOByID(_resultID);
        if (ado.ID > 0 && resultDO != null && resultDO.Status > 0)
        {
            string newOptionText = APQuestionManager.GetAnswerOptionText(ado.ID);
            string editNote = string.Format("从 {0} 修改为 {1}", oldOptionText, newOptionText);
            string scoreNote = string.Empty;
            APAnswerEditHistoryDO ehDO = new APAnswerEditHistoryDO();
            ehDO.AnswerID = ado.ID;
            ehDO.ResultID = _resultID;
            ehDO.StageStatusID = resultDO.Status;
            ehDO.UserID = WebSiteContext.CurrentUserID;
            ehDO.InputDate = DateTime.Now;
            ehDO.EditNote = editNote;
            ehDO.ScoreNote = scoreNote;
            BusinessLogicBase.Default.Insert(ehDO);
        }
        
        if (ado.ID <= 0 && editFlag != "1")
        {
            resultDO.CurrentQuestionID = _questionID;
            int totalNumber = WebSiteContext.Current.CurrentQuestionList.Count;
            int completedNumber = APQuestionManager.GetQuestionnaireCompletedQuestionNumber(_resultID);
            decimal progress = completedNumber * 1m / totalNumber;
            resultDO.CurrentProgress = progress;
            if (progress >= 1m)
            {
                //全部题目已答完
                resultDO.UploadEndTime = DateTime.Now;
                resultDO.VisitUserUploadStatus = (int)Enums.QuestionnaireUploadStatus.录入完成;
            }
        }
        resultDO.LastModifiedTime = DateTime.Now;
        resultDO.LastModifiedUserID = WebSiteContext.CurrentUserID;
        resultDO.VisitUserID = WebSiteContext.CurrentUserID;
        BusinessLogicBase.Default.Update(resultDO);
        //APQuestionnaireManager.DeleteAllQuestions(_qid);
        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }

    /// <summary>
    /// for both Q4 - 填空题
    /// </summary>
    public void SubmitQ8Upload()
    {
        string questionID = HttpContext.Current.Request.Params["questionID"];
        string resultID = HttpContext.Current.Request.Params["resultID"];
        string answerID = HttpContext.Current.Request.Params["answerID"];
        string tempCode = HttpContext.Current.Request.Params["tempCode"];
        string description = HttpContext.Current.Request.Params["description"];
        string editFlag = HttpContext.Current.Request.Params["editFlag"];

        int _questionID = 0;
        int _resultID = 0;
        int _answerID = 0;

        int.TryParse(questionID, out _questionID);
        int.TryParse(resultID, out _resultID);
        int.TryParse(answerID, out _answerID);

        if (WebSiteContext.CurrentUserID <= 0)
        {
            HttpContext.Current.Response.ContentType = "text/plain";
            HttpContext.Current.Response.Write("0");
            return;
        }

        //save answer information
        APAnswersDO ado = new APAnswersDO();
        if (_answerID > 0)
        {
            ado = (APAnswersDO)BusinessLogicBase.Default.Select(ado, _answerID);
        }
        else
        {
            ado = APQuestionManager.GetAnwserDO(_resultID, _questionID);
            if (ado != null && ado.ID > 0)
            {
                HttpContext.Current.Response.ContentType = "text/plain";
                HttpContext.Current.Response.Write("0");
                return;
            }
            else
            {
                ado = new APAnswersDO();
            }
        }

        ado.ResultID = _resultID;
        ado.QuestionID = _questionID;
        ado.Description = description;
        ado.Status = 1;

        decimal score = 0m;
        ado.TotalScore = score;
        if (_answerID > 0)
        {
            ado.LastModifiedTime = DateTime.Now;
            ado.LastModifiedUserID = WebSiteContext.CurrentUserID;

            BusinessLogicBase.Default.Update(ado);
        }
        else
        {
            ado.CreateTime = DateTime.Now;
            ado.CreateUserID = WebSiteContext.CurrentUserID;

            _answerID = BusinessLogicBase.Default.Insert(ado);
        }

        //save attachment information
        if (ado.ID <= 0)
        {
            APQuestionManager.UpdateAttachmentRelatedIDByTempCode(_answerID, tempCode);
        }

        //update questionnaire result
        APQuestionnaireResultsDO resultDO = APQuestionnaireManager.GetQuestionnaireResultDOByID(_resultID);
        if (ado.ID <= 0 && editFlag != "1")
        {
            resultDO.CurrentQuestionID = _questionID;
            int totalNumber = WebSiteContext.Current.CurrentQuestionList.Count;
            int completedNumber = APQuestionManager.GetQuestionnaireCompletedQuestionNumber(_resultID);
            decimal progress = completedNumber * 1m / totalNumber;
            resultDO.CurrentProgress = progress;
            if (progress >= 1m)
            {
                //全部题目已答完
                resultDO.UploadEndTime = DateTime.Now;
                resultDO.VisitUserUploadStatus = (int)Enums.QuestionnaireUploadStatus.录入完成;
            }
        }
        resultDO.LastModifiedTime = DateTime.Now;
        resultDO.LastModifiedUserID = WebSiteContext.CurrentUserID;
        resultDO.VisitUserID = WebSiteContext.CurrentUserID;
        BusinessLogicBase.Default.Update(resultDO);
        //APQuestionnaireManager.DeleteAllQuestions(_qid);
        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }

    /// <summary>
    /// for Q7
    /// </summary>
    public void SubmitQ7Upload()
    {
        string questionID = HttpContext.Current.Request.Params["questionID"];
        string resultID = HttpContext.Current.Request.Params["resultID"];
        string answerID = HttpContext.Current.Request.Params["answerID"];

        int _questionID = 0;
        int _resultID = 0;
        int _answerID = 0;

        int.TryParse(questionID, out _questionID);
        int.TryParse(resultID, out _resultID);
        int.TryParse(answerID, out _answerID);

        if (WebSiteContext.CurrentUserID <= 0)
        {
            HttpContext.Current.Response.ContentType = "text/plain";
            HttpContext.Current.Response.Write("0");
            return;
        }

        decimal oldScore = 0m;
        decimal score = 0m;
        //save answer information
        APAnswersDO ado = new APAnswersDO();
        if (_answerID > 0)
        {
            ado = (APAnswersDO)BusinessLogicBase.Default.Select(ado, _answerID);
            oldScore = ado.TotalScore;
        }
        else
        {
            ado = APQuestionManager.GetAnwserDO(_resultID, _questionID);
            if (ado != null && ado.ID > 0)
            {
                HttpContext.Current.Response.ContentType = "text/plain";
                HttpContext.Current.Response.Write("0");
                return;
            }
            else
            {
                ado = new APAnswersDO();
            }
        }
        
        ado.ResultID = _resultID;
        ado.QuestionID = _questionID;
        ado.Status = 1;
        ado.TotalScore = score;
        if (_answerID > 0)
        {
            ado.LastModifiedTime = DateTime.Now;
            ado.LastModifiedUserID = WebSiteContext.CurrentUserID;

            BusinessLogicBase.Default.Update(ado);
        }
        else
        {
            ado.CreateTime = DateTime.Now;
            ado.CreateUserID = WebSiteContext.CurrentUserID;

            _answerID = BusinessLogicBase.Default.Insert(ado);
        }

        //update questionnaire result
        APQuestionnaireResultsDO resultDO = APQuestionnaireManager.GetQuestionnaireResultDOByID(_resultID);
        if (ado.ID <= 0)
        {
            resultDO.Score = resultDO.Score + score;
        }
        else
        {
            resultDO.Score = resultDO.Score - oldScore + score;
        }
        resultDO.CurrentQuestionID = _questionID;

        int totalNumber = WebSiteContext.Current.CurrentQuestionList.Count;
        int completedNumber = APQuestionManager.GetQuestionnaireCompletedQuestionNumber(_resultID);
        decimal progress  = completedNumber * 1m / totalNumber;
        resultDO.CurrentProgress = progress;
        resultDO.LastModifiedTime = DateTime.Now;
        resultDO.LastModifiedUserID = WebSiteContext.CurrentUserID;
        resultDO.VisitUserID = WebSiteContext.CurrentUserID;
        if (progress >= 1m)
        {
            //全部题目已答完
            resultDO.UploadEndTime = DateTime.Now;
            resultDO.VisitUserUploadStatus = (int)Enums.QuestionnaireUploadStatus.录入完成;
        }
        BusinessLogicBase.Default.Update(resultDO);
        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }

    /// <summary>
    /// 获取答题时候的段落信息
    /// </summary>
    public void GetQ7ForUpload()
    {
        string id = HttpContext.Current.Request.QueryString["id"];
        int _id = 0;
        int.TryParse(id, out _id);
        APQuestionsDO apo = APQuestionnaireManager.GetQuestionDOByID(_id);
        string jsonQuestion = JSONHelper.ObjectToJSON(apo);
        string jsonQuestionPath = APQuestionManager.GetQuestionPath(_id);
        string jsonResult = "{\"Question\":" + jsonQuestion + ",\"QuestionPath\":\"" + jsonQuestionPath + "\"}";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetQ1ForUpload()
    {
        string id = HttpContext.Current.Request.QueryString["id"];
        int _id = 0;
        int.TryParse(id, out _id);
        APQuestionsDO apo = APQuestionnaireManager.GetQuestionDOByID(_id);
        APQuestionnairesDO ado = APQuestionnaireManager.GetQuestionnaireByID(apo.QuestionnaireID);
        string tickCorrentOption = ado.BAutoTickCorrectOption ? "1" : "0";
        string jsonQuestion = JSONHelper.ObjectToJSON(apo);
        DataTable dt = APQuestionnaireManager.GetQuestionOptions(_id);
        string jsonOptions = JSONHelper.DataTableToJSON(dt);
        string jsonQuestionPath = apo.Title;
        try
        {
            jsonQuestionPath = APQuestionManager.GetQuestionPath(_id);
            jsonQuestionPath = CommonFunction.StringToJsonString(jsonQuestionPath);
        }
        catch { }
        string jsonResult = "{\"Question\":" + jsonQuestion + ",\"QuestionPath\":\"" + jsonQuestionPath + "\",\"Options\":" + jsonOptions + ",\"TickCorrentOption\":" + tickCorrentOption + "}";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }
    /// <summary>
    /// 下一步后更新问卷进度
    /// </summary>
    public void GoNextQ7() {
        string answerID = HttpContext.Current.Request.Params["answerID"];
        string questionID = HttpContext.Current.Request.Params["questionID"];
        string questionnaireID = HttpContext.Current.Request.Params["questionnaireID"];
        string resultID = HttpContext.Current.Request.Params["resultID"];
        int _answerID = 0;
        int.TryParse(answerID, out _answerID);
        int _questionID = 0;
        int.TryParse(questionID, out _questionID);
        int _questionnaireID = 0;
        int.TryParse(questionnaireID, out _questionnaireID);
        int _resultID = 0;
        int.TryParse(resultID, out _resultID);

        APQuestionnaireResultsDO resultDO = new APQuestionnaireResultsDO();
        resultDO = (APQuestionnaireResultsDO)BusinessLogicBase.Default.Select(resultDO, _resultID);

        decimal oldProgress = resultDO.CurrentProgress;
        decimal progress = 0;
        int totalNumber = WebSiteContext.Current.CurrentQuestionList.Count;
        if (oldProgress <= 0m)
        {
            progress = 1m / totalNumber;
        }
        else
        {
            progress = (oldProgress * totalNumber + 1) / totalNumber;
        }
        if (_answerID <= 0)
        {
            resultDO.CurrentQuestionID = _questionID;
            resultDO.CurrentProgress = progress;
        }
        resultDO.LastModifiedTime = DateTime.Now;
        resultDO.LastModifiedUserID = WebSiteContext.CurrentUserID;

        if (progress >= 1m)
        {
            //全部题目已答完
            resultDO.UploadEndTime = DateTime.Now;
            resultDO.VisitUserUploadStatus = (int)Enums.QuestionnaireUploadStatus.录入完成;
            resultDO.VisitUserID = WebSiteContext.CurrentUserID;
        }
        BusinessLogicBase.Default.Update(resultDO);

        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }
    /// <summary>
    /// 获取答题时候的问卷进度
    /// </summary>
    public void GetQuestionnaireProgressForUpload()
    {
        string questionID = HttpContext.Current.Request.QueryString["questionID"];
        string resultID = HttpContext.Current.Request.QueryString["resultID"];
        int _questionID = 0;
        int.TryParse(questionID, out _questionID);
        int _resultID = 0;
        int.TryParse(resultID, out _resultID);
        APQuestionnaireResultsDO resultDO = new APQuestionnaireResultsDO();
        resultDO = (APQuestionnaireResultsDO)BusinessLogicBase.Default.Select(resultDO, _resultID);

        int totalNumber = WebSiteContext.Current.CurrentQuestionList.Count;
        decimal currentIndex = resultDO.CurrentProgress * totalNumber;
        decimal progress = resultDO.CurrentProgress * 100;
        string strProgress = progress.ToString("N0") + "%";
        string percentage = currentIndex.ToString("N0") + " / " + totalNumber.ToString();
        if (currentIndex == totalNumber)
        {
            strProgress = "100%";
        }
        string jsonResult = "{\"Progress\":\"" + strProgress + "\",\"Percentage\":\"" + percentage + "\"}";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void SubmitQuestionnaireUpload()
    {
        string resultID = HttpContext.Current.Request.Params["resultID"];
        int _resultID = 0;
        int.TryParse(resultID, out _resultID);

        APQuestionnaireResultsDO resultDO = new APQuestionnaireResultsDO();
        resultDO = (APQuestionnaireResultsDO)BusinessLogicBase.Default.Select(resultDO, _resultID);
        resultDO.VisitUserUploadStatus = (int)Enums.QuestionnaireUploadStatus.已提交审核;
        resultDO.Status = (int)Enums.QuestionnaireStageStatus.执行督导审核中;
        resultDO.LastModifiedTime = DateTime.Now;
        resultDO.LastModifiedUserID = WebSiteContext.CurrentUserID;
        BusinessLogicBase.Default.Update(resultDO);

        WebCommon.SendAuditNotice(resultDO, (int)Enums.UserType.执行督导, (int)Enums.QuestionnaireAuditType.执行督导审核);

        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void DownloadQuestionnaireAnswers() 
    {
        string resultID = HttpContext.Current.Request.Params["resultID"];
        int _resultID = 0;
        int.TryParse(resultID, out _resultID);
        
        DataTable dt = APQuestionManager.GetQuestionnaireAnswers(_resultID);

        DataTable dtOutput = new DataTable();
        dtOutput.TableName = "问卷结果";
        dtOutput.Columns.Add("正文信息", typeof(string));
        dtOutput.Columns.Add("回答", typeof(string));
        dtOutput.Columns.Add("申诉信息", typeof(string));
        dtOutput.Columns.Add("标准分", typeof(string));
        dtOutput.Columns.Add("得分", typeof(string));
        if (dt != null && dt.Rows.Count > 0)
        {
            foreach (DataRow row in dt.Rows)
            {
                DataRow newRow = dtOutput.NewRow();
                newRow["正文信息"] = row["Code"].ToString() + " " + row["Title"].ToString();
                newRow["回答"] = row["OptionText"].ToString();
                newRow["申诉信息"] = row["ClientNotes"].ToString();
                newRow["标准分"] = row["Score"].ToString();
                newRow["得分"] = row["TotalScore"].ToString();
                dtOutput.Rows.Add(newRow);
            }
            List<string> fixedColumnNames = new List<string>();
            foreach (DataColumn dc in dtOutput.Columns)
            {
                if (fixedColumnNames.Contains(dc.ColumnName))
                {
                    dc.ColumnName = dc.ColumnName + ParseExcel.CellStyle.A_AFNP + ParseExcel.CellStyle.A_LA;
                }
            }
        }

        DataSet ds = new DataSet();
        ds.Tables.Add(dtOutput.Copy());
        string fileName = string.Format("问卷结果_{0:yyyyMMddHHmmss}.xlsx", DateTime.Now);
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

    public void GetQuestionnaireAnswers()
    {
        string resultID = HttpContext.Current.Request.QueryString["resultID"];
        string bOnlyDeduction = HttpContext.Current.Request.QueryString["bOnlyDeduction"];
        string bOnlyAppeal = HttpContext.Current.Request.QueryString["bOnlyAppeal"];
        
        int _resultID = 0;
        int.TryParse(resultID, out _resultID);
        bool _bOnlyDeduction = false;
        bool _bOnlyAppeal = false;
        bool.TryParse(bOnlyDeduction, out _bOnlyDeduction);
        bool.TryParse(bOnlyAppeal, out _bOnlyAppeal);

        DataTable dtInfo = APQuestionManager.GetQuestionnaireResultInfo(_resultID);
        dtInfo.Columns.Add("CoverImage");
        if (dtInfo != null && dtInfo.Rows.Count > 0)
        {
            string playType = dtInfo.Rows[0]["PlayType"].ToString();
            string playPath = dtInfo.Rows[0]["PlayPath"].ToString();
            if (playType == "3")
            {
                //录像，需要判断视频封面截图是否存在
                string relevantPath = playPath.Replace("../", "~/");
                string diskPath = HttpContext.Current.Server.MapPath(relevantPath);
                string coverPath = System.IO.Path.ChangeExtension(diskPath, ".jpg");
                if (System.IO.File.Exists(coverPath))
                {
                    dtInfo.Rows[0]["CoverImage"] = System.IO.Path.ChangeExtension(playPath, ".jpg");
                }
                else
                {
                    dtInfo.Rows[0]["CoverImage"] = "";
                }
            }
        }
        DataTable dtAnswers =  APQuestionManager.GetQuestionnaireAnswers(_resultID);

        if (_bOnlyDeduction == true) 
        {
            //申诉过后的问卷，部分扣分题目会被改成得分答案或者直接得分
            APQuestionnaireResultsDO resultDO = APQuestionnaireManager.GetQuestionnaireResultDOByID(_resultID);
            if (resultDO.Status == (int)Enums.QuestionnaireStageStatus.申诉中 || resultDO.Status == (int)Enums.QuestionnaireStageStatus.复审中 || resultDO.Status == (int)Enums.QuestionnaireStageStatus.完成)
            {
                DataView dv = dtAnswers.DefaultView;
                dv.RowFilter = "QuestionType<>7 and (ClientNotes<>'' or Score<>TotalScore or (WrongOptionNumber>0 and QuestionType=2))";
                dtAnswers = dv.ToTable();
            }
            else
            {
                DataView dv = dtAnswers.DefaultView;
                dv.RowFilter = "QuestionType<>7 and (Score<>TotalScore or (WrongOptionNumber>0 and QuestionType=2))";
                dtAnswers = dv.ToTable();
            }
        }
        if (_bOnlyAppeal == true)
        {
            DataView dv = dtAnswers.DefaultView;
            dv.RowFilter = "QuestionType<>7 and ClientNotes<>''";
            dtAnswers = dv.ToTable();
        }
        string jsonInfo = JSONHelper.DataTableToJSON(dtInfo);
        string jsonAnswers = JSONHelper.DataTableToJSON(dtAnswers);
        string jsonResult = "{\"Info\":" + jsonInfo + ",\"Answers\":" + jsonAnswers + "}";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }


    public bool IsReusable {
        get {
            return false;
        }
    }

}