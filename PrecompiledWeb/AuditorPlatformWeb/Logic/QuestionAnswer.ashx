<%@ WebHandler Language="C#" Class="QuestionAnswer" %>

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

public class QuestionAnswer : IHttpHandler, IRequiresSessionState
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
                    SelectedOptionChanged();
                    break;
                case 2:
                    GetFileNumberByTempCode();
                    break;
                case 3:
                    OptionTextChanged();
                    break;
                case 4:
                    GetClientAppealDownload();
                    break;
                case 5:
                    GetQuestionAppeals();
                    break;
                case 6:
                    SubmitAppealReply();
                    break;
                case 7:
                    GetQuestionAppealsDownload();
                    break;
                case 8:
                    UpdateQuestionnaireStatus();
                    break;
                case 9:
                    UploaAppealReply();
                    break;
                default:
                    break;
            }
        }
        catch { }
    }

    public void UploaAppealReply()
    {
        string typeID = HttpContext.Current.Request["typeID"];
        int _typeID = 0;
        int.TryParse(typeID, out _typeID);

        HttpPostedFile file = HttpContext.Current.Request.Files[0];
        string fileName = Path.GetFileName(file.FileName);
        string fileNameWithoutExtension = Path.GetFileNameWithoutExtension(file.FileName);
        string extension = Path.GetExtension(file.FileName);
        string result = "0";
        if (extension != ".xlsx")
        {
            result = "0无法处理非Excel文件";
            HttpContext.Current.Response.ContentType = "text/plain";
            HttpContext.Current.Response.Write(result);
            return;
        }
        if (fileNameWithoutExtension.Contains("-") == false)
        {
            result = "0文件命名格式不正确，无法识别日期和问卷,请按照{yyyyMMdd}-{问卷名称}格式命名需要上传的复核文件。";
            HttpContext.Current.Response.ContentType = "text/plain";
            HttpContext.Current.Response.Write(result);
            return;
        }
        string strFromDate = fileNameWithoutExtension.Substring(0, fileNameWithoutExtension.IndexOf('-'));
        string strQuestionnaireName = fileNameWithoutExtension.Substring(fileNameWithoutExtension.IndexOf('-') + 1);
        DateTime fromDate = Constants.Date_Min;
        try
        {
            fromDate = DateTime.ParseExact(strFromDate, "yyyyMMdd", System.Globalization.CultureInfo.CurrentCulture);
        }
        catch { }
        APQuestionnairesDO qdo = APQuestionnaireManager.GetQuestionnaireDOByName(WebSiteContext.CurrentProjectID, strQuestionnaireName);
        if (fromDate <= Constants.Date_Min || qdo == null || qdo.ID <= 0)
        {
            result = "0无法识别的日期或问卷，请仔细检查文件命名是否正确。";
            HttpContext.Current.Response.ContentType = "text/plain";
            HttpContext.Current.Response.Write(result);
            return;
        }
        string vituralPath = Constants.RelevantTempPath;
        string physicalPath = HttpContext.Current.Server.MapPath(vituralPath);
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
        try
        {
            DataSet ds = ParseExcel.GetDataSetFromExcelFile(diskFilePath);
            if (ds == null || ds.Tables.Count == 0)
            {
                result = "0未能找到数据，请调整文件重试";
                HttpContext.Current.Response.ContentType = "text/plain";
                HttpContext.Current.Response.Write(result);
                return;
            }
            if (ds.Tables.Contains("申诉指标$") == false)
            {
                result = "0没有找到表单\"申诉指标\"，请调整文件重试";
                HttpContext.Current.Response.ContentType = "text/plain";
                HttpContext.Current.Response.Write(result);
                return;
            }

            DataTable dt = ds.Tables["申诉指标$"];
            foreach (DataRow row in dt.Rows)
            {
                string clientCode = row["网点编号"].ToString();
                string questionCode = row["题号"].ToString();
                string bNeedUpdateAuditText = row["是否需要更新三方反馈"].ToString().Trim();
                APClientsDO clientDO = APClientManager.GetClientByCode(clientCode, WebSiteContext.CurrentProjectID);
                APQuestionnaireResultsDO resultDO = APQuestionnaireManager.GetQuestionnaireResultDO(qdo.ID, clientDO.ID, fromDate);
                int resultID = resultDO.ID;
                int questionID = APQuestionManager.GetQuestionIDByCode(resultID, questionCode);
                if (bNeedUpdateAuditText == "是")
                {
                    string auditText = row["三方反馈"].ToString();
                    if (string.IsNullOrEmpty(auditText) == false)
                    {
                        APQuestionManager.DeleteQuestionAppealAuditNotes(resultID, questionID, WebSiteContext.Current.CurrentProject.QCLeaderUserID);

                        APQuestionAuditNotesDO auditNoteDO = new APQuestionAuditNotesDO();
                        auditNoteDO.ResultID = resultID;
                        auditNoteDO.QuestionID = questionID;
                        auditNoteDO.UserTypeID = (int)Enums.UserType.质控督导;
                        auditNoteDO.AuditTypeID = (int)Enums.QuestionnaireAuditType.客户审核;
                        auditNoteDO.AuditNotes = auditText;
                        auditNoteDO.CreateTime = DateTime.Now;
                        auditNoteDO.CreateUserID = WebSiteContext.Current.CurrentProject.QCLeaderUserID;
                        BusinessLogicBase.Default.Insert(auditNoteDO);
                    }
                    
                    string resultText = row["三方意见"].ToString();
                    int appealStatus = 0;
                    if (resultText == "还分")
                    {
                        APAnswersDO answerDO = APQuestionManager.GetAnwserDO(resultID, questionID);
                        if (answerDO != null && answerDO.ID > 0)
                        {
                            decimal oldScore = answerDO.TotalScore;
                            string oldOptionText = APQuestionManager.GetAnswerOptionText(answerDO.ID);
                            
                            APQuestionManager.ClearAnswerOptions(answerDO.ID);
                            APOptionsDO correctOptionDO = APQuestionManager.GetCorrectOptionDO(questionID);
                            APQuestionsDO questionDO = APQuestionnaireManager.GetQuestionDOByID(questionID);
                            answerDO.TotalScore = questionDO.TotalScore;
                            answerDO.LastModifiedUserID = WebSiteContext.Current.CurrentProject.QCLeaderUserID;
                            answerDO.LastModifiedTime = DateTime.Now;
                            BusinessLogicBase.Default.Update(answerDO);

                            APAnswerOptionsDO answerOptionDO = new APAnswerOptionsDO();
                            answerOptionDO.AnswerID = answerDO.ID;
                            answerOptionDO.OptionID = correctOptionDO.ID;
                            BusinessLogicBase.Default.Insert(answerOptionDO);

                            resultDO.Score = resultDO.Score - oldScore + questionDO.TotalScore;
                            BusinessLogicBase.Default.Update(resultDO);

                            string newOptionText = APQuestionManager.GetAnswerOptionText(answerDO.ID);
                            string editNote = string.Format("还分：从 {0} 修改为 {1}", oldOptionText, newOptionText);
                            string scoreNote = string.Format("从 {0} 修改为 {1}", oldScore.ToString("0.0"), questionDO.TotalScore.ToString("0.0"));
                            APAnswerEditHistoryDO ehDO = new APAnswerEditHistoryDO();
                            ehDO.AnswerID = answerDO.ID;
                            ehDO.ResultID = resultID;
                            ehDO.StageStatusID = resultDO.Status;
                            ehDO.UserID = WebSiteContext.Current.CurrentProject.QCLeaderUserID;
                            ehDO.InputDate = DateTime.Now;
                            ehDO.EditNote = editNote;
                            ehDO.ScoreNote = scoreNote;
                            BusinessLogicBase.Default.Insert(ehDO);
                        }

                        appealStatus = 2;
                        
                    }
                    else if (resultText == "维持扣分")
                    {
                        appealStatus = 1;
                    }
                    else if (resultText == "未裁决")
                    {
                        appealStatus = 3;
                    }
                    if (appealStatus > 0)
                    {
                        APAppealAuditDO appealDO = APQuestionnaireManager.GetAppealAuditDO(resultID, questionID);
                        if (appealDO == null || appealDO.ID <= 0)
                        {
                            appealDO = new APAppealAuditDO();
                        }
                        appealDO.AppealStatus = appealStatus;
                        appealDO.InputDate = DateTime.Now;
                        appealDO.QuestionID = questionID;
                        appealDO.ResultID = resultID;
                        appealDO.UserID = WebSiteContext.Current.CurrentProject.QCLeaderUserID;
                        if (appealDO.ID <= 0)
                        {
                            BusinessLogicBase.Default.Insert(appealDO);
                        }
                        else
                        {
                            BusinessLogicBase.Default.Update(appealDO);
                        }
                    }
                }
                string bNeedUpdateClientText = row["是否需要总行裁定"].ToString().Trim();
                if (bNeedUpdateClientText == "是")
                {
                    string clientText = row["总行裁定结果"].ToString().Trim();
                    if (string.IsNullOrEmpty(clientText) == false)
                    {
                        int topClientID = APClientManager.GetTopClientID(WebSiteContext.CurrentProjectID);
                        APUsersDO topClientUserDO = APUserManager.GetClientUserDO(topClientID, WebSiteContext.CurrentProjectID);
                        APQuestionManager.DeleteQuestionAppealAuditNotes(resultID, questionID, topClientUserDO.ID);

                        APQuestionAuditNotesDO auditNoteDO = new APQuestionAuditNotesDO();
                        auditNoteDO.ResultID = resultID;
                        auditNoteDO.QuestionID = questionID;
                        auditNoteDO.UserTypeID = (int)Enums.UserType.客户;
                        auditNoteDO.AuditTypeID = (int)Enums.QuestionnaireAuditType.客户审核;
                        auditNoteDO.AuditNotes = clientText;
                        auditNoteDO.CreateTime = DateTime.Now;
                        auditNoteDO.CreateUserID = topClientUserDO.ID;
                        BusinessLogicBase.Default.Insert(auditNoteDO);

                        int appealStatus = 0;
                        if (clientText == "还分")
                        {
                            APAnswersDO answerDO = APQuestionManager.GetAnwserDO(resultID, questionID);
                            if (answerDO != null && answerDO.ID > 0)
                            {
                                decimal oldScore = answerDO.TotalScore;
                                string oldOptionText = APQuestionManager.GetAnswerOptionText(answerDO.ID);
                                
                                APQuestionManager.ClearAnswerOptions(answerDO.ID);
                                APOptionsDO correctOptionDO = APQuestionManager.GetCorrectOptionDO(questionID);
                                APQuestionsDO questionDO = APQuestionnaireManager.GetQuestionDOByID(questionID);
                                answerDO.TotalScore = questionDO.TotalScore;
                                answerDO.LastModifiedUserID = topClientUserDO.ID;
                                answerDO.LastModifiedTime = DateTime.Now;
                                BusinessLogicBase.Default.Update(answerDO);

                                APAnswerOptionsDO answerOptionDO = new APAnswerOptionsDO();
                                answerOptionDO.AnswerID = answerDO.ID;
                                answerOptionDO.OptionID = correctOptionDO.ID;
                                BusinessLogicBase.Default.Insert(answerOptionDO);

                                resultDO.Score = resultDO.Score - oldScore + questionDO.TotalScore;
                                BusinessLogicBase.Default.Update(resultDO);

                                string newOptionText = APQuestionManager.GetAnswerOptionText(answerDO.ID);
                                string editNote = string.Format("还分：从 {0} 修改为 {1}", oldOptionText, newOptionText);
                                string scoreNote = string.Format("从 {0} 修改为 {1}", oldScore.ToString("0.0"), questionDO.TotalScore.ToString("0.0"));
                                APAnswerEditHistoryDO ehDO = new APAnswerEditHistoryDO();
                                ehDO.AnswerID = answerDO.ID;
                                ehDO.ResultID = resultID;
                                ehDO.StageStatusID = resultDO.Status;
                                ehDO.UserID = topClientUserDO.ID;
                                ehDO.InputDate = DateTime.Now;
                                ehDO.EditNote = editNote;
                                ehDO.ScoreNote = scoreNote;
                                BusinessLogicBase.Default.Insert(ehDO);
                            }
                            appealStatus = 2;
                        }
                        else if (clientText == "维持扣分")
                        {
                            appealStatus = 1;
                        }

                        if (appealStatus > 0)
                        {
                            APAppealAuditDO appealDO = APQuestionnaireManager.GetAppealAuditDO(resultID, questionID);
                            if (appealDO == null || appealDO.ID <= 0)
                            {
                                appealDO = new APAppealAuditDO();
                            }
                            appealDO.AppealStatus = appealStatus;
                            appealDO.InputDate = DateTime.Now;
                            appealDO.QuestionID = questionID;
                            appealDO.ResultID = resultID;
                            appealDO.UserID = topClientUserDO.ID;
                            if (appealDO.ID <= 0)
                            {
                                BusinessLogicBase.Default.Insert(appealDO);
                            }
                            else
                            {
                                BusinessLogicBase.Default.Update(appealDO);
                            }
                        }
                    }
                }
            }
            result = "1";
            HttpContext.Current.Response.ContentType = "text/plain";
            HttpContext.Current.Response.Write(result);
        }
        catch (Exception ex)
        {
            result = "0" + ex.ToString();
            HttpContext.Current.Response.ContentType = "text/plain";
            HttpContext.Current.Response.Write(result);
        }
    }

    public void UpdateQuestionnaireStatus()
    {
        string qid = HttpContext.Current.Request.Params["qid"];
        string period = HttpContext.Current.Request.Params["period"];
        string stageStatus = HttpContext.Current.Request.Params["stageStatus"];
        string statusID = HttpContext.Current.Request.Params["statusID"];
        string keyword = HttpContext.Current.Request.Params["keyword"];
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
        int _stageStatus = 0;
        int _levelID = 0;
        string[] strStage = stageStatus.Split('|');
        if (strStage.Length <= 1)
        {
            int.TryParse(stageStatus, out _stageStatus);
        }
        else
        {
            int.TryParse(strStage[0], out _stageStatus);
            int.TryParse(strStage[1], out _levelID);
        }
        int _statusID = 0;
        int.TryParse(statusID, out _statusID);
        DataTable dt = APQuestionnaireManager.GetQuestionAppeals(_qid, fromDate, toDate, _stageStatus, _statusID, _levelID, keyword);
        int finished = 0;
        int leaveClient = 0;
        if (dt != null && dt.Rows.Count > 0) 
        {
            DataView dv = dt.DefaultView;
            DataTable dtResultID = dv.ToTable(true, "ResultID", "Code", "Name");
            foreach (DataRow dr in dtResultID.Rows) 
            {
                string strResultID = dr["ResultID"].ToString();
                int resultID = 0;
                int.TryParse(strResultID, out resultID);
                string code = dr["Code"].ToString();
                string name = dr["Name"].ToString();
                DataRow[] rows = dt.Select("Status<7 and ResultID=" + strResultID);
                if (rows != null && rows.Length > 0)
                {
                    int finishCount = 0;
                    int leaveCount = 0;
                    foreach (DataRow row in rows)
                    {
                        int appealStatus = 0;
                        int.TryParse(row["AppealStatus"].ToString(), out appealStatus);
                        if (appealStatus == 1 || appealStatus == 2)
                        {
                            finishCount++;
                        }
                        else if (appealStatus == 3)
                        {
                            leaveCount++;
                        }
                    }
                    if (finishCount + leaveCount == rows.Length)
                    {
                        APQuestionnaireResultsDO resultDO = APQuestionnaireManager.GetQuestionnaireResultDOByID(resultID);
                        resultDO.QCLeaderAuditTime = DateTime.Now;
                        resultDO.QCLeaderUserID = WebSiteContext.Current.CurrentProject.QCLeaderUserID;
                        resultDO.ClientUserID = WebSiteContext.Current.CurrentProject.QCLeaderUserID;
                        resultDO.ClientUserAuditTime = DateTime.Now;
                        //所有已申诉的指标都处理过了
                        if (leaveCount > 0)
                        {
                            //未裁决状态
                            int topClientID = APClientManager.GetTopClientID(WebSiteContext.CurrentProjectID);
                            APUsersDO topUserDO = APUserManager.GetClientUserDO(topClientID, WebSiteContext.CurrentProjectID);
                            resultDO.QCLeaderAuditStatus = (int)Enums.QuestionnaireAuditStatus.未裁决;
                            resultDO.ClientUserAuditStatus = (int)Enums.QuestionnaireClientStatus.申诉未裁决;
                            resultDO.CurrentClientUserID = topUserDO.ID;
                            resultDO.Status = (int)Enums.QuestionnaireStageStatus.复审中;
                            WebCommon.SendAppealStartNotice(resultDO, topUserDO.ID, (int)Enums.QuestionnaireAuditType.质控督导复审);

                            leaveClient++;
                        }
                        else
                        {
                            //完成状态
                            resultDO.QCLeaderAuditStatus = (int)Enums.QuestionnaireAuditStatus.通过;
                            resultDO.ClientUserAuditStatus = (int)Enums.QuestionnaireClientStatus.申诉已处理;
                            resultDO.ReAuditStatus = 0;
                            resultDO.Status = (int)Enums.QuestionnaireStageStatus.完成;
                            WebCommon.SendAppealFinishNotice(resultDO, (int)Enums.QuestionnaireAuditType.客户审核, "申诉已处理", "");

                            finished++;
                        }
                        BusinessLogicBase.Default.Update(resultDO);
                    }
                    else
                    {
                        //存在未处理的指标，不能更新，但是需要提示用户
                    }
                }
            }
        }
        string result = "{ \"finished\": " + finished + ",\"leave\": " + leaveClient + " }";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(result);
    }

    public void SubmitAppealReply()
    {
        string resultID = HttpContext.Current.Request.Params["resultID"];
        string questionID = HttpContext.Current.Request.Params["questionID"];
        string approved = HttpContext.Current.Request.Params["approved"];

        int _resultID = 0;
        int _questionID = 0;
        int.TryParse(resultID, out _resultID);
        int.TryParse(questionID, out _questionID);
        int appealStatus = 0;
        int.TryParse(approved, out appealStatus);

        APQuestionnaireResultsDO resultDO = APQuestionnaireManager.GetQuestionnaireResultDOByID(_resultID);
        APClientsDO currentClientDO = APClientManager.GetClientDOByID(resultDO.ClientID);
        if (currentClientDO.ProjectID != WebSiteContext.CurrentProjectID)
        {
            string result = "-1";
            HttpContext.Current.Response.ContentType = "application/json";
            HttpContext.Current.Response.Write(result);
            return;
        }

        APAppealAuditDO appealDO = APQuestionnaireManager.GetAppealAuditDO(_resultID, _questionID);
        if (appealDO == null || appealDO.ID <= 0)
        {
            appealDO = new APAppealAuditDO();
        }
        appealDO.AppealStatus = appealStatus;
        appealDO.InputDate = DateTime.Now;
        appealDO.QuestionID = _questionID;
        appealDO.ResultID = _resultID;
        appealDO.UserID = WebSiteContext.CurrentUserID;
        if (appealDO.ID <= 0)
        {
            BusinessLogicBase.Default.Insert(appealDO);
        }
        else
        {
            BusinessLogicBase.Default.Update(appealDO);
        }
        
        if (appealStatus == 2)
        {
            //还分
            APAnswersDO answerDO = APQuestionManager.GetAnwserDO(_resultID, _questionID);
            if (answerDO != null && answerDO.ID > 0)
            {
                decimal oldScore = answerDO.TotalScore;
                APQuestionManager.ClearAnswerOptions(answerDO.ID);
                APOptionsDO correctOptionDO = APQuestionManager.GetCorrectOptionDO(_questionID);
                APQuestionsDO questionDO = APQuestionnaireManager.GetQuestionDOByID(_questionID);
                answerDO.TotalScore = questionDO.TotalScore;
                answerDO.LastModifiedUserID = WebSiteContext.CurrentUserID;
                answerDO.LastModifiedTime = DateTime.Now;
                BusinessLogicBase.Default.Update(answerDO);

                APAnswerOptionsDO answerOptionDO = new APAnswerOptionsDO();
                answerOptionDO.AnswerID = answerDO.ID;
                answerOptionDO.OptionID = correctOptionDO.ID;
                BusinessLogicBase.Default.Insert(answerOptionDO);

                resultDO.Score = resultDO.Score - oldScore + questionDO.TotalScore;
                BusinessLogicBase.Default.Update(resultDO);
            }
        }

        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write("1");
    }

    public void GetQuestionAppeals()
    {
        string qid = HttpContext.Current.Request.QueryString["qid"];
        string period = HttpContext.Current.Request.QueryString["period"];
        string stageStatus = HttpContext.Current.Request.QueryString["stageStatus"];
        string statusID = HttpContext.Current.Request.QueryString["statusID"];
        string keyword = HttpContext.Current.Request.QueryString["keyword"];
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
        int _stageStatus = 0;
        int _levelID = 0;
        string[] strStage = stageStatus.Split('|');
        if (strStage.Length <= 1)
        {
            int.TryParse(stageStatus, out _stageStatus);
        }
        else
        {
            int.TryParse(strStage[0], out _stageStatus);
            int.TryParse(strStage[1], out _levelID);
        }
        int _statusID = 0;
        int.TryParse(statusID, out _statusID);
        DataTable dt = APQuestionnaireManager.GetQuestionAppeals(_qid, fromDate, toDate, _stageStatus, _statusID, _levelID, keyword);
        string result = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(result);
    }

    public void GetQuestionAppealsDownload()
    {
        string qid = HttpContext.Current.Request.QueryString["qid"];
        string period = HttpContext.Current.Request.QueryString["period"];
        string stageStatus = HttpContext.Current.Request.QueryString["stageStatus"];
        string statusID = HttpContext.Current.Request.QueryString["statusID"];
        string keyword = HttpContext.Current.Request.QueryString["keyword"];
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
        int _stageStatus = 0;
        int _levelID = 0;
        string[] strStage = stageStatus.Split('|');
        if (strStage.Length <= 1)
        {
            int.TryParse(stageStatus, out _stageStatus);
        }
        else
        {
            int.TryParse(strStage[0], out _stageStatus);
            int.TryParse(strStage[1], out _levelID);
        }
        int _statusID = 0;
        int.TryParse(statusID, out _statusID);
        DataTable dt = APQuestionnaireManager.GetQuestionAppeals(_qid, fromDate, toDate, _stageStatus, _statusID, _levelID, keyword);
        DataTable dtOutput = new DataTable();
        dtOutput.TableName = "申诉指标";
        dtOutput.Columns.Add("分行编号", typeof(string));
        dtOutput.Columns.Add("分行名称", typeof(string));
        dtOutput.Columns.Add("网点编号", typeof(string));
        dtOutput.Columns.Add("网点名称", typeof(string));
        dtOutput.Columns.Add("二级指标", typeof(string));
        dtOutput.Columns.Add("三级指标", typeof(string));
        dtOutput.Columns.Add("题号", typeof(string));
        dtOutput.Columns.Add("标准分", typeof(string));
        dtOutput.Columns.Add("实际得分", typeof(string));
        dtOutput.Columns.Add("原始扣分原因", typeof(string));
        dtOutput.Columns.Add("网点复议理由", typeof(string));
        dtOutput.Columns.Add("分行意见", typeof(string));
        dtOutput.Columns.Add("三方反馈", typeof(string));
        if (dt != null && dt.Rows.Count > 0)
        {
            foreach (DataRow row in dt.Rows)
            {
                DataRow newRow = dtOutput.NewRow();
                newRow["分行编号"] = row["ParentCode"].ToString();
                newRow["分行名称"] = row["ParentName"].ToString();
                newRow["网点编号"] = row["Code"].ToString();
                newRow["网点名称"] = row["Name"].ToString();
                newRow["二级指标"] = row["ParentQuestion"].ToString();
                newRow["三级指标"] = row["Question"].ToString();
                newRow["题号"] = row["QuestionCode"].ToString();
                newRow["标准分"] = row["TotalScore"].ToString();
                newRow["实际得分"] = row["Score"].ToString();
                newRow["原始扣分原因"] = row["OptionText"].ToString();
                newRow["网点复议理由"] = row["AuditNotes"].ToString();
                newRow["分行意见"] = row["AuditNotes2"].ToString();
                newRow["三方反馈"] = row["AuditNotes3"].ToString();
                if (string.IsNullOrEmpty(row["AuditNotes2"].ToString()))
                {
                    newRow["分行意见"] = "未填写内容";
                }
                if (string.IsNullOrEmpty(row["AuditNotes3"].ToString()))
                {
                    newRow["三方反馈"] = "未填写内容";
                }
                dtOutput.Rows.Add(newRow);
            }
        }
        //处理excel自动格式问题
        foreach (DataColumn dc in dtOutput.Columns)
        {
            if (dc.ColumnName != "标准分" && dc.ColumnName != "实际得分")
            {
                dc.ColumnName = dc.ColumnName + ParseExcel.CellStyle.A_AFNP + ParseExcel.CellStyle.A_LA;
            }
        }
        DataSet ds = new DataSet();
        ds.Tables.Add(dtOutput);

        string fileName = string.Format("申诉指标_{0:yyyyMMddHHmmss}.xlsx", DateTime.Now);
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
    
    public void GetClientAppealDownload()
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

        DataTable dt = APQuestionnaireManager.GetClientAppeals(_qid, fromDate, toDate);       
        DataTable dtOutput = new DataTable();
        dtOutput.TableName = "申诉指标";
        dtOutput.Columns.Add("分行编号", typeof(string));
        dtOutput.Columns.Add("分行名称", typeof(string));
        dtOutput.Columns.Add("网点编号", typeof(string));
        dtOutput.Columns.Add("网点名称", typeof(string));
        dtOutput.Columns.Add("二级指标", typeof(string));
        dtOutput.Columns.Add("三级指标", typeof(string));
        dtOutput.Columns.Add("题号", typeof(string));
        dtOutput.Columns.Add("标准分", typeof(string));
        dtOutput.Columns.Add("实际得分", typeof(string));
        dtOutput.Columns.Add("原始扣分原因", typeof(string));
        dtOutput.Columns.Add("网点复议理由", typeof(string));
        dtOutput.Columns.Add("分行意见", typeof(string));
        dtOutput.Columns.Add("三方反馈", typeof(string));
        
        if (dt != null && dt.Rows.Count > 0)
        {
            foreach (DataRow row in dt.Rows)
            {
                DataRow newRow = dtOutput.NewRow();
                newRow["分行编号"] = row["ParentCode"].ToString();
                newRow["分行名称"] = row["ParentName"].ToString();
                newRow["网点编号"] = row["Code"].ToString();
                newRow["网点名称"] = row["Name"].ToString();
                newRow["二级指标"] = row["ParentQuestion"].ToString();
                newRow["三级指标"] = row["Question"].ToString();
                newRow["题号"] = row["QuestionCode"].ToString();
                newRow["标准分"] = row["TotalScore"].ToString();
                newRow["实际得分"] = row["Score"].ToString();
                newRow["原始扣分原因"] = row["OptionText"].ToString();
                newRow["网点复议理由"] = row["AuditNotes"].ToString();
                newRow["分行意见"] = row["AuditNotes2"].ToString();
                newRow["三方反馈"] = row["AuditNotes3"].ToString();
                if (string.IsNullOrEmpty(row["AuditNotes2"].ToString()))
                {
                    newRow["分行意见"] = "未填写内容";
                }
                if (string.IsNullOrEmpty(row["AuditNotes3"].ToString()))
                {
                    newRow["三方反馈"] = "未填写内容";
                }
                dtOutput.Rows.Add(newRow);
            }
        }
        //处理excel自动格式问题
        foreach (DataColumn dc in dtOutput.Columns)
        {
            if (dc.ColumnName != "标准分" && dc.ColumnName != "实际得分")
            {
                dc.ColumnName = dc.ColumnName + ParseExcel.CellStyle.A_AFNP + ParseExcel.CellStyle.A_LA;
            }
        }
        DataSet ds = new DataSet();
        ds.Tables.Add(dtOutput);
        
        string fileName = string.Format("申诉指标_{0:yyyyMMddHHmmss}.xlsx", DateTime.Now);
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

    public void OptionTextChanged() 
    {
        string resultID = HttpContext.Current.Request.Params["resultID"];
        string questionID = HttpContext.Current.Request.Params["questionID"];
        string optionID = HttpContext.Current.Request.Params["optionID"];
        string optionText = HttpContext.Current.Request.Params["optionText"];

        int _resultID = 0;
        int _questionID = 0;
        int _optionID = 0;
        int.TryParse(resultID, out _resultID);
        int.TryParse(questionID, out _questionID);
        int.TryParse(optionID, out _optionID);

        APAnswerOptionsDO answerOptionDO = APQuestionManager.GetAnswerOption(_resultID, _questionID, _optionID);
        if (answerOptionDO != null && answerOptionDO.ID > 0)
        {
            answerOptionDO.OptionText = optionText;
            BusinessLogicBase.Default.Update(answerOptionDO);
        }
        else if (_optionID == -1) 
        {
            APAnswersDO answerDO = new APAnswersDO();
            decimal score = APQuestionManager.CalculateQuestionScore(_questionID, _optionID);
            answerDO.ResultID = _resultID;
            answerDO.QuestionID = _questionID;
            answerDO.TotalScore = score;
            answerDO.CreateTime = DateTime.Now;
            answerDO.CreateUserID = WebSiteContext.CurrentUserID;
            answerDO.Status = (int)Enums.DeleteStatus.正常;
            int answerID = BusinessLogicBase.Default.Insert(answerDO);
            
            answerOptionDO = new APAnswerOptionsDO();
            answerOptionDO.AnswerID = answerID;
            answerOptionDO.OptionID = _optionID;
            answerOptionDO.OptionText = optionText;
            BusinessLogicBase.Default.Insert(answerOptionDO);
        }
        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetFileNumberByTempCode() 
    {
        string tempCode = HttpContext.Current.Request.QueryString["tempCode"];
        int fileNumber = APQuestionManager.GetFileNumberByTempCode(tempCode);
        string jsonResult = fileNumber.ToString();
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void SelectedOptionChanged()
    {
        string resultID = HttpContext.Current.Request.Params["resultID"];
        string questionID = HttpContext.Current.Request.Params["questionID"];
        string selectOptions = HttpContext.Current.Request.Params["selectOptions"];

        int _resultID = 0;
        int _questionID = 0;

        int.TryParse(resultID, out _resultID);
        int.TryParse(questionID, out _questionID);

        int answerID = 0;
        decimal oldScore = 0;
        APAnswersDO answerDO = APQuestionManager.GetAnwserDO(_resultID, _questionID);
        if (answerDO != null && answerDO.ID > 0)
        {
            answerID = answerDO.ID;
            answerDO.LastModifiedTime = DateTime.Now;
            answerDO.LastModifiedUserID = WebSiteContext.CurrentUserID;
            oldScore = answerDO.TotalScore;
        }
        else
        {
            answerDO = new APAnswersDO();
            answerDO.ResultID = _resultID;
            answerDO.QuestionID = _questionID;
            answerDO.TotalScore = 0;
            answerDO.CreateTime = DateTime.Now;
            answerDO.CreateUserID = WebSiteContext.CurrentUserID;
            answerDO.Description = "";
            answerDO.Status = (int)Enums.DeleteStatus.正常;
            answerID = BusinessLogicBase.Default.Insert(answerDO);
            answerDO.ID = answerID;
        }

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
        APQuestionManager.ClearAnswerOptions(answerID);
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
                answerOptionDO.AnswerID = answerID;
                answerOptionDO.OptionID = optionID;
                answerOptionDO.OptionText = text;
                BusinessLogicBase.Default.Insert(answerOptionDO);
            }
        }
        decimal score = APQuestionManager.CalculateQuestionScore(_questionID, selectedOptionList.ToArray());
        answerDO.TotalScore = score;
        BusinessLogicBase.Default.Update(answerDO);

        APQuestionnaireResultsDO resultDO = APQuestionnaireManager.GetQuestionnaireResultDOByID(_resultID);
        resultDO.Score = resultDO.Score - oldScore + score;
        BusinessLogicBase.Default.Update(resultDO);
        string jsonResult = score.ToString("0.0");
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public bool IsReusable {
        get {
            return false;
        }
    }

}