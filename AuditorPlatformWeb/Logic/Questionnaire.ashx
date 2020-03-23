<%@ WebHandler Language="C#" Class="Questionnaire" %>

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
using System.IO;
using APLibrary;
using APLibrary.DataObject;
using APLibrary.Utility;

public class Questionnaire : IHttpHandler, IRequiresSessionState
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
                    GetQuestionnaires();
                    break;
                case 2:
                    GetQuestionnaireInfo();
                    break;
                case 3:
                    SubmitQuestionnaire();
                    break;
                case 4:
                    DeleteQuestionnaire();
                    break;
                case 5:
                    GetAllQuestionsByQID();
                    break;
                case 6:
                    GetQuestionInfo();
                    break;
                case 7:
                    SubmitQuestion();
                    break;
                case 8:
                    SubmitOption();
                    break;
                case 9:
                    ClearQuestionOptions();
                    break;
                case 10:
                    GetLinkedQuestions();
                    break;
                case 11:
                    GetLinkedOptions();
                    break;
                case 12:
                    DeleteQuestion();
                    break;
                case 13:
                    GetPreviewQuestionsByQID();
                    break;
                case 14:
                    DeleteAllQuestions();
                    break;
                case 15:
                    GetNextQuestion();
                    break;
                case 16:
                    LoginQuestionnaire();
                    break;
                case 17:
                    GetPreviousQuestion();
                    break;
                case 18:
                    GetQuestionnairePeriods();
                    break;
                case 19:
                    GetQuestionnaireResults();
                    break;
                case 20:
                    GetQuestionnaireResultsDownload();
                    break;
                case 21:
                    FixQuestionOptions();
                    break;
                case 22:
                    SubmitCopyQuestionnaire();
                    break;
                case 23:
                    DownloadPreviewQuestionsByQID();
                    break;
                case 24:
                    GetQuestionnaireResultsDownloadFile();
                    break;
                case 25:
                    MoveQuestionnaireToProject();
                    break;
                default: 
                    break;
            }
        }
        catch { }
    }

    public void MoveQuestionnaireToProject() 
    {
        string result = "1";
        string questionnaireID = HttpContext.Current.Request.Params["questionnaireID"];
        string projectID = HttpContext.Current.Request.Params["projectID"];
        try
        {
            int _projectID = 0;
            int _questionnaireID = 0;
            int.TryParse(projectID, out _projectID);
            int.TryParse(questionnaireID, out _questionnaireID);
            APQuestionnairesDO qdo = APQuestionnaireManager.GetQuestionnaireByID(_questionnaireID);
            if (qdo != null && qdo.ID > 0)
            {
                qdo.ProjectID = _projectID;
                BusinessLogicBase.Default.Update(qdo);
            }
        }
        catch {
            result = "0";
        }
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(result);
    }

    public void DownloadPreviewQuestionsByQID()
    {
        string id = HttpContext.Current.Request.QueryString["id"];
        int _id = 0;
        int.TryParse(id, out _id);
        APQuestionnairesDO ado = APQuestionnaireManager.GetQuestionnaireByID(_id);
        string questionnaireName = ado.Name;
        DataTable dt = APQuestionnaireManager.GetPreviewQuestionsByQID(_id);
        DataTable dtOutput = new DataTable();
        dtOutput.TableName = ParseExcel.TableName.Data;
        
        dtOutput.Columns.Add("编号", typeof(string));
        dtOutput.Columns.Add("问题名称", typeof(string));
        dtOutput.Columns.Add("分值", typeof(string));
        dtOutput.Columns.Add("选项", typeof(string));
        dtOutput.Columns.Add("扣分项", typeof(string));

        string strCol_RowIndex = Constants.RowStyle.RowUniqueID;
        string strCol_RowFontBold = Constants.RowStyle.RowStyleContent;
        DataTable dtrowstyle = ParseExcel.GetRowStyleTable();
        dtOutput.Columns.Add(strCol_RowIndex);
        if (dt != null && dt.Rows.Count > 0)
        {
            foreach (DataRow row in dt.Rows)
            {
                DataRow newRow = dtOutput.NewRow();
                int questionType = 0;
                int.TryParse(row["QuestionType"].ToString(), out questionType);
                string questionID =  row["ID"].ToString();
                if (questionType == (int)Enums.QuestionType.段落) 
                {
                    string rowstylevalue = "FONTBOLD:True;";
                    DataRow stylerow = dtrowstyle.NewRow();
                    stylerow[strCol_RowIndex] = questionID;
                    stylerow[strCol_RowFontBold] = rowstylevalue;
                    dtrowstyle.Rows.Add(stylerow);
                }
                newRow[Constants.RowStyle.RowUniqueID] = questionID;
                newRow["编号"] = row["Code"].ToString();
                newRow["问题名称"] = row["Title"].ToString();
                decimal score = 0;
                decimal.TryParse(row["TotalScore"].ToString(), out score);
                newRow["分值"] = score.ToString("N2");
                newRow["选项"] = row["Options"].ToString().Replace("<br/>", "\r\n");
                newRow["扣分项"] = row["WrongOptions"].ToString().Replace("<br/>", "\r\n");
                dtOutput.Rows.Add(newRow);
            }
        }

        DataSet ds = new DataSet();
        ds.Tables.Add(dtOutput.Copy());
        ds.Tables.Add(dtrowstyle);
        string fileName = string.Format("问卷题目_" + questionnaireName + "_{0:yyyyMMddHHmmss}.xlsx", DateTime.Now);
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
            DataTable dtStyle = ParseExcel.GetStyleTable();
            
            DataRow drStyle = ParseExcel.AppendBlankRow(ref dtStyle, ParseExcel.RowType.Alignment);
            drStyle[ParseExcel.C_ColumnIndex] = 0;
            drStyle[ParseExcel.C_CustomStyle] = ParseExcel.CellStyle.ALIGN_LEFT;
            
            drStyle = ParseExcel.AppendBlankRow(ref dtStyle, ParseExcel.RowType.Alignment);
            drStyle[ParseExcel.C_ColumnIndex] = 1;
            drStyle[ParseExcel.C_CustomStyle] = ParseExcel.CellStyle.ALIGN_LEFT;
            
            drStyle = ParseExcel.AppendBlankRow(ref dtStyle, ParseExcel.RowType.Alignment);
            drStyle[ParseExcel.C_ColumnIndex] = 2;
            drStyle[ParseExcel.C_CustomStyle] = ParseExcel.CellStyle.ALIGN_LEFT;
            
            drStyle = ParseExcel.AppendBlankRow(ref dtStyle, ParseExcel.RowType.Alignment);
            drStyle[ParseExcel.C_ColumnIndex] = 3;
            drStyle[ParseExcel.C_CustomStyle] = ParseExcel.CellStyle.ALIGN_LEFT;
            drStyle = ParseExcel.AppendBlankRow(ref dtStyle, ParseExcel.RowType.Alignment);
            drStyle[ParseExcel.C_ColumnIndex] = 3;
            drStyle[ParseExcel.C_CustomStyle] = ParseExcel.CellStyle.TEXTWRAPPED;
            
            drStyle = ParseExcel.AppendBlankRow(ref dtStyle, ParseExcel.RowType.Alignment);
            drStyle[ParseExcel.C_ColumnIndex] = 4;
            drStyle[ParseExcel.C_CustomStyle] = ParseExcel.CellStyle.ALIGN_LEFT;
            drStyle = ParseExcel.AppendBlankRow(ref dtStyle, ParseExcel.RowType.Alignment);
            drStyle[ParseExcel.C_ColumnIndex] = 4;
            drStyle[ParseExcel.C_CustomStyle] = ParseExcel.CellStyle.TEXTWRAPPED;
            
            ds.Tables.Add(dtStyle);
            float[] widths = { 10f, 50f, 20f, 60f, 60f};
            
            APLibrary.ParseExcel.CreateExcel(filePath, ds, widths);
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

    public void SubmitCopyQuestionnaire() 
    {
        string qid = HttpContext.Current.Request.Params["qid"];
        int questionnaireID = 0;
        int.TryParse(qid, out questionnaireID);
        string result = "1";
        try
        {
            APQuestionnairesDO questionnaireDO = APQuestionnaireManager.GetQuestionnaireByID(questionnaireID);
            questionnaireDO.ID = -1;
            questionnaireDO.CreateTime = DateTime.Now;
            questionnaireDO.CreateUserID = WebSiteContext.CurrentUserID;
            int newID = BusinessLogicBase.Default.Insert(questionnaireDO);

            DataTable dt = APQuestionnaireManager.GetAllQuestionsByQID(questionnaireID);
            if (dt != null && dt.Rows.Count > 0)
            {
                foreach (DataRow row in dt.Rows)
                {
                    string id = row["ID"].ToString();
                    int questionID = 0;
                    int.TryParse(id, out questionID);
                    APQuestionsDO questionDO = APQuestionnaireManager.GetQuestionDOByID(questionID);
                    if (questionDO == null || questionDO.ID <= 0)
                    {
                        continue;
                    }
                    questionDO.ID = -1;
                    questionDO.CreateTime = DateTime.Now;
                    questionDO.CreateUserID = WebSiteContext.CurrentUserID;
                    questionDO.QuestionnaireID = newID;

                    int newQuestionID = BusinessLogicBase.Default.Insert(questionDO);

                    DataTable optionsDt = APQuestionnaireManager.GetQuestionOptions(questionID);
                    if (optionsDt != null && optionsDt.Rows.Count > 0)
                    {
                        foreach (DataRow optionRow in optionsDt.Rows)
                        {
                            string optionid = optionRow["ID"].ToString();
                            int _optionid = 0;
                            int.TryParse(optionid, out _optionid);
                            APOptionsDO optionDO = APQuestionManager.GetOptionDO(_optionid);
                            if (optionDO == null || optionDO.ID <= 0)
                            {
                                continue;
                            }
                            optionDO.ID = -1;
                            optionDO.QuestionID = newQuestionID;
                            int newOptionID = BusinessLogicBase.Default.Insert(optionDO);
                            //if (optionDO.OptionImageID > 0) 
                            //{
                            //    DocumentFilesDO doc = new DocumentFilesDO();
                            //    doc = (DocumentFilesDO)BusinessLogicBase.Default.Select(doc, optionDO.OptionImageID);
                            //    if (doc == null || doc.ID <= 0)
                            //    {
                            //        continue;
                            //    }

                            //}
                        }
                    }

                }
            }
            result = "1";
        }
        catch {
            result = "0";
        }
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(result);
    }

    public void FixQuestionOptions() 
    {
        string qid = HttpContext.Current.Request.Params["qid"];
        string allids = HttpContext.Current.Request.Params["allids"];
        string sql = "delete from dbo.APOptions where QuestionID=" + qid + " and ID not in (" + allids + ")";
        try 
        {
            BusinessLogicBase.Default.Execute(sql);
        }
        catch { }
        string result = "1";
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(result);
    }

    public void GetQuestionnaireResultsDownload()
    {
        string qid = HttpContext.Current.Request.QueryString["qid"];
        string clientID = HttpContext.Current.Request.QueryString["clientID"];
        string period = HttpContext.Current.Request.QueryString["period"];
        string status = HttpContext.Current.Request.QueryString["status"];
        string typeid = HttpContext.Current.Request.QueryString["typeid"];
        bool hasLink = HttpContext.Current.Request.QueryString["hasLink"].ToBoolean(true);
        bool hasDescription = HttpContext.Current.Request.QueryString["hasDescription"].ToBoolean(true);
        int _qid = 0;
        int.TryParse(qid, out _qid);
        int _clientID = 0;
        int.TryParse(clientID, out _clientID);
        int _status = 0;
        int.TryParse(status, out _status);
        int _typeID = 0;
        int.TryParse(typeid, out _typeID);

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
        DataTable dt = new DataTable();
        int totalCount = APQuestionnaireManager.GetQuestionnaireResultsCount(_qid, _clientID, fromDate, toDate, _status);
        if (_typeID == 1)
        {
            dt = APQuestionnaireManager.GetQuestionnaireResults_Answers(projectID, _qid, _clientID, fromDate, toDate, _status, 1, totalCount, hasLink, hasDescription);
        }
        else if (_typeID == 2)
        {
            dt = APQuestionnaireManager.GetQuestionnaireResultsScore(projectID, _qid, _clientID, fromDate, toDate, _status, 1, totalCount);
        }
        //处理excel自动格式问题
        foreach (DataColumn dc in dt.Columns)
        {
            //此处隐患代码，因为总分可能不在得分列以及信息列中间，但是目前没有找到比较好的解决办法，此方法可以暂时解决问题，以后再修改
            if (dc.ColumnName == "总分")
            {
                break;
            }
            if (dc.ColumnName.Contains("时间") == false && dc.ColumnName.Contains("日期") == false)
            {
                dc.ColumnName = dc.ColumnName + ParseExcel.CellStyle.A_AFNP + ParseExcel.CellStyle.A_LA;
            }
        }
        
        DataSet ds = new DataSet();
        ds.Tables.Add(dt.Copy());
        string fileName = string.Format("问卷结果列表_{0:yyyyMMddHHmmss}.xlsx", DateTime.Now);
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
            //NPOIHelper.ExportDTtoExcel(dt.Copy(), "", filePath);
        }
        catch 
        {
        
        }
        string result = "0";
        if (System.IO.File.Exists(filePath))
        {
            result = System.Web.VirtualPathUtility.ToAbsolute(fileRelevantPath);
        }
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(result);
    }

    public void GetQuestionnaireResultsDownloadFile()
    {
        string qid = HttpContext.Current.Request.QueryString["qid"];
        string clientID = HttpContext.Current.Request.QueryString["clientID"];
        string period = HttpContext.Current.Request.QueryString["period"];
        string status = HttpContext.Current.Request.QueryString["status"];
        string typeid = HttpContext.Current.Request.QueryString["typeid"];
        int _qid = 0;
        int.TryParse(qid, out _qid);
        int _clientID = 0;
        int.TryParse(clientID, out _clientID);
        int _status = 0;
        int.TryParse(status, out _status);
        int _typeID = 0;
        int.TryParse(typeid, out _typeID);

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
        DataTable dt = APQuestionnaireManager.GetQuestionnaireResultsFiles(projectID, _qid, _clientID, fromDate, toDate, _status);
        string fileName = string.Format("项目问卷文件包_{0:yyyyMMddHHmmss}.zip", DateTime.Now);
        string timestamp = DateTime.Now.ToString("yyyyMMddhhmmss");
        
        string folderRelevantPath = Constants.RelevantTempPath;
        string folderPath = HttpContext.Current.Server.MapPath(folderRelevantPath).TrimEnd('\\') + "\\" + timestamp;
        if (System.IO.Directory.Exists(folderPath) == false)
        {
            System.IO.Directory.CreateDirectory(folderPath);
        }
        string fileRelevantPath = folderRelevantPath + timestamp + "/" + fileName;
        string filePath = folderPath.TrimEnd('\\') + "\\" + fileName;
        if (dt == null || dt.Rows.Count <= 0)
        {
            HttpContext.Current.Response.ContentType = "text/plain";
            HttpContext.Current.Response.Write("-1");//没有找到任何文件
            return;
        }
        System.Collections.ArrayList filelist = new System.Collections.ArrayList();
        foreach (DataRow dr in dt.Rows)
        {
            //Diego changed at 2018-4-26
            if (dr["FileType"].ToString() != "1")
            {
                continue;
            }
            string fixedFileName = dr["FileName"].ToString();
            if (Path.HasExtension(fixedFileName) == false)
            {
                string originalFileName = dr["OriginalFileName"].ToString();
                string extension = Path.GetExtension(originalFileName);
                fixedFileName = fixedFileName + extension;
            }
            string diskFilePath = dr["PhysicalPath"].ToString();
            string tempFilePath = folderPath.TrimEnd('\\') + "\\" + fixedFileName;
            if (File.Exists(tempFilePath))
            {
                tempFilePath = CommonFunction.GetNewPathForDuplicates(tempFilePath);
            }
            try
            {
                System.IO.File.Copy(diskFilePath, tempFilePath, true);
                filelist.Add(tempFilePath);
            }
            catch { }
        }

        ZipHelper.ZipFiles(filelist, filePath);
        
        string result = "0";
        if (System.IO.File.Exists(filePath))
        {
            result = System.Web.VirtualPathUtility.ToAbsolute(fileRelevantPath);
        }
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(result);
    }

    public void GetQuestionnaireResults() 
    {
        string qid = HttpContext.Current.Request.QueryString["qid"];
        string clientID = HttpContext.Current.Request.QueryString["clientID"];
        string period = HttpContext.Current.Request.QueryString["period"];
        string status = HttpContext.Current.Request.QueryString["status"];
        string typeid = HttpContext.Current.Request.QueryString["typeid"];
        string pageNumber = HttpContext.Current.Request.QueryString["pageNumber"];
        string pageLimit = HttpContext.Current.Request.QueryString["pageLimit"];
        int _qid = 0;
        int.TryParse(qid, out _qid);
        int _clientID = 0;
        int.TryParse(clientID, out _clientID);
        int _status = 0;
        int.TryParse(status, out _status);
        int _typeID = 0;
        int.TryParse(typeid, out _typeID);

        DateTime fromDate = Constants.Date_Min;
        DateTime toDate = Constants.Date_Max;
        if (period.Contains("|")) 
        {
            string strFrom = period.Split('|')[0];
            string strTo = period.Split('|')[1];
            DateTime.TryParse(strFrom, out fromDate);
            DateTime.TryParse(strTo, out toDate);
        }

        int page = 0;
        int limit = 0;
        int.TryParse(pageNumber, out page);
        int.TryParse(pageLimit, out limit);
        int pageFrom = (page - 1) * limit + 1;
        int pageTo = pageFrom + limit - 1;

        int totalCount = APQuestionnaireManager.GetQuestionnaireResultsCount(_qid, _clientID, fromDate, toDate, _status);
        
        int projectID = WebSiteContext.CurrentProjectID;
        DataTable dt = new DataTable();
        if (_typeID == 1)
        {
            dt = APQuestionnaireManager.GetQuestionnaireResults_Answers(projectID, _qid, _clientID, fromDate, toDate, _status, pageFrom, pageTo);
        }
        else if (_typeID == 2)
        {
            dt = APQuestionnaireManager.GetQuestionnaireResultsScore(projectID, _qid, _clientID, fromDate, toDate, _status, pageFrom, pageTo);
        }
        DataTable dtColumns = new DataTable();
        dtColumns.Columns.Add("Name", typeof(string));
        foreach (DataColumn dc in dt.Columns) 
        {
            dtColumns.Rows.Add(dc.ColumnName);
        }
        string jsonColumns = JSONHelper.DataTableToJSON(dtColumns);
        string jsonResult = JSONHelper.DataTableToJSON(dt);
        string result = "{\"Columns\":" + jsonColumns + ",\"Data\":" + jsonResult + ",\"Count\":" + totalCount + "}";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(result);
    }

    public void GetQuestionnairePeriods() 
    {
        string qid = HttpContext.Current.Request.QueryString["qid"];
        int _qid = 0;
        int.TryParse(qid, out _qid);
        DataTable dt = APQuestionnaireManager.GetQuestionnairePeriods(_qid);
        string jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    } 

    public void LoginQuestionnaire() 
    {
        string qid = HttpContext.Current.Request.Params["questionnaireID"];
        int _qid = 0;
        int.TryParse(qid, out _qid);
        DataTable dt = APQuestionnaireManager.GetAllQuestionsByQID(_qid);
        
        List<APQuestionsDO> questionList = new List<APQuestionsDO>();
        foreach (DataRow dr in dt.Rows)
        {
            int questionID = 0;
            int.TryParse(dr["ID"].ToString(), out questionID);
            APQuestionsDO que = APQuestionnaireManager.GetQuestionDOByID(questionID);
            questionList.Add(que);
        }
        WebSiteContext.Current.CurrentQuestionList = questionList;
        WebSiteContext.Current.CurrentQuestionnaire = APQuestionnaireManager.GetQuestionnaireByID(_qid);
        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetPreviousQuestion() 
    {
        string id = HttpContext.Current.Request.QueryString["currentQuestionID"];
        int _id = 0;
        int.TryParse(id, out _id);
        List<APQuestionsDO> questionList = WebSiteContext.Current.CurrentQuestionList;
        int prevQuestionID = 0;
        int prevQuestionTypeID = 0;
        if (_id == questionList[0].ID)
        {
            prevQuestionID = -1;
            prevQuestionTypeID = -1;
        }
        else
        {
            for (int i = 0; i < questionList.Count; i++)
            {
                APQuestionsDO qdo = questionList[i];
                if (qdo.ID == _id)
                {
                    prevQuestionID = questionList[i - 1].ID;
                    prevQuestionTypeID = questionList[i - 1].QuestionType;
                    break;
                }
            }
        }
        string jsonResult = "{\"PrevQuestionID\":" + prevQuestionID + ",\"PrevQuestionTypeID\":" + prevQuestionTypeID + "}";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetNextQuestion()
    {
        string resultID = HttpContext.Current.Request.QueryString["currentResultID"];
        string qid = HttpContext.Current.Request.QueryString["currentQuestionnaireID"];
        string id = HttpContext.Current.Request.QueryString["currentQuestionID"];
        int _resultID = 0;
        int.TryParse(resultID, out _resultID);
        int _qid = 0;
        int.TryParse(qid, out _qid);
        int _id = 0;
        int.TryParse(id, out _id);

        int nextQuestionID = 0;
        int nextQuestionTypeID = 0;

        //有可能需要扩展，如有跳题情况发生，需要调整题目顺序或剔除部分题目
        List<APQuestionsDO> questionList = WebSiteContext.Current.CurrentQuestionList;
        if (_id <= 0)
        {
            //get first question
            nextQuestionID = questionList[0].ID;
            nextQuestionTypeID = questionList[0].QuestionType;
            string jsonResult = "{\"NextQuestionID\":" + nextQuestionID + ",\"NextQuestionTypeID\":" + nextQuestionTypeID + "}";
            HttpContext.Current.Response.ContentType = "application/json";
            HttpContext.Current.Response.Write(jsonResult);
            return;
        }
        else if (_id == questionList[questionList.Count - 1].ID)
        {
            //if current is the last question
            nextQuestionID = -1;
            nextQuestionTypeID = -1;
            string jsonResult = "{\"NextQuestionID\":" + nextQuestionID + ",\"NextQuestionTypeID\":" + nextQuestionTypeID + "}";
            HttpContext.Current.Response.ContentType = "application/json";
            HttpContext.Current.Response.Write(jsonResult);
            return;
        }
        //1) handle currrent question option jump 
        APQuestionsDO currentQuestion = APQuestionnaireManager.GetQuestionDOByID(_id);
        DataTable options = APQuestionnaireManager.GetQuestionOptions(_id);
        if (currentQuestion.QuestionType == (int)Enums.QuestionType.单选题 || currentQuestion.QuestionType == (int)Enums.QuestionType.是非题)
        {
            APAnswersDO ado = APQuestionManager.GetAnwserDO(_resultID, _id);
            if (ado != null && ado.ID > 0)
            {
                int selectedOptionID = APQuestionManager.GetSingleAnswerOptionID(ado.ID);
                APOptionsDO optionDO = APQuestionManager.GetOptionDO(selectedOptionID);
                if (string.IsNullOrEmpty(optionDO.JumpQuestionCode) == false)
                {
                    List<APQuestionsDO> jumpedQuestions = new List<APQuestionsDO>();
                    string jumpCode = optionDO.JumpQuestionCode;
                    int currentQuestionPosition = -1;
                    for (int i = 0; i < questionList.Count; i++)
                    {
                        APQuestionsDO qdo = questionList[i];
                        if (qdo.ID == _id)
                        {
                            currentQuestionPosition = i;
                        }
                        else if (currentQuestionPosition >= 0 && i > currentQuestionPosition)
                        {
                            if (qdo.Code == jumpCode)
                            {
                                nextQuestionID = qdo.ID;
                                nextQuestionTypeID = qdo.QuestionType;
                                break;
                            }
                            else
                            {
                                jumpedQuestions.Add(qdo);
                            }
                        }
                    }

                    if (jumpedQuestions.Count > 0)
                    {
                        List<APQuestionsDO> currentList = WebSiteContext.Current.CurrentQuestionList;
                        foreach (APQuestionsDO q in jumpedQuestions)
                        {
                            currentList.Remove(q);
                        }
                        WebSiteContext.Current.CurrentQuestionList = currentList;
                    }
                    string jsonResult = "{\"NextQuestionID\":" + nextQuestionID + ",\"NextQuestionTypeID\":" + nextQuestionTypeID + "}";
                    HttpContext.Current.Response.ContentType = "application/json";
                    HttpContext.Current.Response.Write(jsonResult);
                    return;
                }
            }
        }
        //2)handle next question's option
        List<APQuestionsDO> linkedQuestions = new List<APQuestionsDO>();
        int currentPosition = -1;
        for (int i = 0; i < questionList.Count; i++)
        {
            APQuestionsDO qdo = questionList[i];
            if (_id <= 0)
            {
                nextQuestionID = questionList[0].ID;
                nextQuestionTypeID = questionList[0].QuestionType;
                break;
            }
            if (qdo.ID == _id)
            {
                currentPosition = i;
                continue;
            }
            if (currentPosition >= 0 && i > currentPosition)
            {
                //找到当前题目，然后去找下一题的位置
                if (i < questionList.Count)
                {
                    APQuestionsDO aqo = questionList[i];
                    if (aqo.LinkOptionID > 0 && aqo.LinkQuestionID > 0)
                    {
                        APAnswersDO ado = APQuestionManager.GetAnwserDO(_resultID, aqo.LinkQuestionID);
                        int selectedOptionID = APQuestionManager.GetSingleAnswerOptionID(ado.ID);
                        if (selectedOptionID != aqo.LinkOptionID)
                        {
                            linkedQuestions.Add(aqo);
                        }
                        else
                        {
                            nextQuestionID = aqo.ID;
                            nextQuestionTypeID = aqo.QuestionType;
                            break;
                        }
                    }
                    else
                    {
                        nextQuestionID = aqo.ID;
                        nextQuestionTypeID = aqo.QuestionType;
                        break;
                    }
                }
            }
        }
        //去除不符合关联逻辑的题目
        if (linkedQuestions.Count > 0)
        {
            int number = linkedQuestions.Count;
            for (int i = 0; i < number; i++)
            {
                APQuestionsDO linkedDO = linkedQuestions[i];
                int questionID = linkedDO.ID;
                if (questionID == (int)Enums.QuestionType.段落)
                {
                    DataTable dt = APQuestionManager.GetAllSubQuestionsByID(questionID);
                    if (dt != null && dt.Rows.Count > 0) 
                    {
                        foreach (DataRow dr in dt.Rows) 
                        {
                            int subID = 0;
                            int.TryParse(dr["ID"].ToString(), out subID);
                            APQuestionsDO subDO = new APQuestionsDO();
                            subDO.ID = subID;
                            linkedQuestions.Add(subDO);
                        }
                    }
                }
            }
            
            List<APQuestionsDO> currentList = WebSiteContext.Current.CurrentQuestionList;
            foreach (APQuestionsDO q in linkedQuestions)
            {
                int linkedID = q.ID;
                for (int j = currentList.Count - 1; j >= 0; j--) 
                {
                    if (linkedID == currentList[j].ID) 
                    {
                        currentList.RemoveAt(j);
                    }
                }
            }
            WebSiteContext.Current.CurrentQuestionList = currentList;
        }
        string result = "{\"NextQuestionID\":" + nextQuestionID + ",\"NextQuestionTypeID\":" + nextQuestionTypeID + "}";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(result);
    }
    
    public void DeleteAllQuestions()
    {
        string qid = HttpContext.Current.Request.Params["qid"];
        int _qid = 0;
        int.TryParse(qid, out _qid);
        APQuestionnaireManager.DeleteAllQuestions(_qid);
        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }
    
    public void DeleteQuestion()
    {
        string id = HttpContext.Current.Request.Params["id"];
        int _id = 0;
        int.TryParse(id, out _id);
        APQuestionnaireManager.DeleteQuestion(_id);
        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void ClearQuestionOptions()
    {
        string qid = HttpContext.Current.Request.Params["qid"];
        int _qid = 0;
        int.TryParse(qid, out _qid);
        APQuestionnaireManager.ClearQuestionOptions(_qid);
        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetLinkedQuestions() {
        string qid = HttpContext.Current.Request.QueryString["qid"];
        string id = HttpContext.Current.Request.QueryString["id"];
        int _qid = 0;
        int.TryParse(qid, out _qid);
        int _id = 0;
        int.TryParse(id, out _id);
        DataTable dt = APQuestionnaireManager.GetAllLinkedQuestionsByQID(_qid, _id);
        string jsonResult = JSONHelper.DataTableToJSON(dt);

        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetLinkedOptions()
    {
        string qid = HttpContext.Current.Request.QueryString["qid"];
        int _qid = 0;
        int.TryParse(qid, out _qid);
        DataTable dt = APQuestionnaireManager.GetAllLinkedOptionsByQID(_qid);
        string jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void SubmitOption()
    {
        string qid = HttpContext.Current.Request.Params["qid"];
        string title = HttpContext.Current.Request.Params["title"];
        string jumpQID = HttpContext.Current.Request.Params["jumpQID"];
        string showQuestionCode = HttpContext.Current.Request.Params["showQuestionCode"];
        string bIsAnswer = HttpContext.Current.Request.Params["bIsAnswer"];
        string imageID = HttpContext.Current.Request.Params["imageID"];
        string bAllowInput = HttpContext.Current.Request.Params["bAllowInput"];
        string optionScore = HttpContext.Current.Request.Params["optionScore"];
        string bMustImage = HttpContext.Current.Request.Params["bMustImage"];
        string id = HttpContext.Current.Request.Params["id"];

        int _id = 0;
        int.TryParse(id, out _id);
        
        int _qid = 0;
        int.TryParse(qid, out _qid);
        int _imageID = 0;
        int.TryParse(imageID, out _imageID);
        bool _bIsAnswer = false;
        bool.TryParse(bIsAnswer, out _bIsAnswer);
        bool _bAllowInput = false;
        bool.TryParse(bAllowInput, out _bAllowInput);
        decimal score = 0;
        decimal.TryParse(optionScore, out score);
        bool _bMustImage = false;
        bool.TryParse(bMustImage, out _bMustImage);
        
        APOptionsDO optionDO = new APOptionsDO();
        if (_id > 0)
        {
            optionDO = APQuestionManager.GetOptionDO(_id);
        }
        optionDO.Title = title;
        optionDO.BAllowText = _bAllowInput;
        optionDO.BMustImage = _bMustImage;
        optionDO.BCorrectOption = _bIsAnswer;
        optionDO.JumpQuestionCode = jumpQID;
        optionDO.OptionImageID = _imageID;
        optionDO.QuestionID = _qid;
        optionDO.Score = score;
        optionDO.ShowQuestionCode = showQuestionCode;
        if (optionDO.ID > 0)
        {
            BusinessLogicBase.Default.Update(optionDO);
        }
        else
        {
            _id = BusinessLogicBase.Default.Insert(optionDO);
        }
        string jsonResult = _id.ToString();
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void SubmitQuestion()
    {
        string id = HttpContext.Current.Request.Params["id"];
        string qid = HttpContext.Current.Request.Params["qid"];
        string code = HttpContext.Current.Request.Params["code"];
        string parentCode = HttpContext.Current.Request.Params["parentCode"];
        string score = HttpContext.Current.Request.Params["score"];
        string countType = HttpContext.Current.Request.Params["countType"];
        string questionType = HttpContext.Current.Request.Params["questionType"];
        string title = HttpContext.Current.Request.Params["title"];
        string linkQuestionID = HttpContext.Current.Request.Params["linkQuestionID"];
        string linkOptionID = HttpContext.Current.Request.Params["linkOptionID"];
        string description = HttpContext.Current.Request.Params["description"];
        string bAllowImage = HttpContext.Current.Request.Params["bAllowImage"];
        string bAllowAudio = HttpContext.Current.Request.Params["bAllowAudio"];
        string bAllowVideo = HttpContext.Current.Request.Params["bAllowVideo"];
        string bMustImage = HttpContext.Current.Request.Params["bMustImage"];
        string bMustAudio = HttpContext.Current.Request.Params["bMustAudio"];
        string bMustVideo = HttpContext.Current.Request.Params["bMustVideo"];
        bool bHidden = HttpContext.Current.Request.Params["bHidden"].ToBoolean(false);

        int _id = 0;
        int.TryParse(id, out _id);
        int _qid = 0;
        int.TryParse(qid, out _qid);
        int _countType = 0;
        int.TryParse(countType, out _countType);
        int _questionType = 0;
        int.TryParse(questionType, out _questionType);


        int _linkQuestionID = 0;
        int.TryParse(linkQuestionID, out _linkQuestionID);
        int _linkOptionID = 0;
        int.TryParse(linkOptionID, out _linkOptionID);
        
        decimal _score = 0;
        decimal.TryParse(score, out _score);
        bool _bAllowImage = false;
        bool _bAllowAudio = false;
        bool _bAllowVideo = false;
        bool _bMustImage = false;
        bool _bMustAudio = false;
        bool _bMustVideo = false;
        bool.TryParse(bAllowImage, out _bAllowImage);
        bool.TryParse(bAllowAudio, out _bAllowAudio);
        bool.TryParse(bAllowVideo, out _bAllowVideo);
        bool.TryParse(bMustImage, out _bMustImage);
        bool.TryParse(bMustAudio, out _bMustAudio);
        bool.TryParse(bMustVideo, out _bMustVideo);

        APQuestionsDO qdo = new APQuestionsDO();
        if (_id > 0)
        {
            qdo = APQuestionnaireManager.GetQuestionDOByID(_id);
            qdo.LastModifiedTime = DateTime.Now;
            qdo.LastModifiedUserID = WebSiteContext.CurrentUserID;
        }
        else
        {
            qdo.QuestionnaireID = _qid;
            qdo.Status = 1;
            qdo.CreateTime = DateTime.Now;
            qdo.CreateUserID = WebSiteContext.CurrentUserID;
        }
        qdo.Code = code;
        qdo.ParentCode = parentCode;
        qdo.QuestionType = _questionType;
        qdo.Title = title;
        qdo.TotalScore = _score;
        qdo.CountType = _countType;
        qdo.LinkQuestionID = _linkQuestionID;
        qdo.LinkOptionID = _linkOptionID;
        qdo.Description = description;
        qdo.Status = 1;
        qdo.BAllowAudio = _bAllowAudio;
        qdo.BAllowImage = _bAllowImage;
        qdo.BAllowVideo = _bAllowVideo;
        qdo.BMustImage = _bMustImage;
        qdo.BMustAudio = _bMustAudio;
        qdo.BMustVideo = _bMustVideo;
        qdo.BHidden = bHidden;
        if (_id > 0)
        {
            BusinessLogicBase.Default.Update(qdo);
        }
        else
        {
            _id = BusinessLogicBase.Default.Insert(qdo);
        }
        string jsonResult = _id.ToString();

        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }
    
    public void GetAllQuestionsByQID() 
    {
        string id = HttpContext.Current.Request.QueryString["id"];
        int _id = 0;
        int.TryParse(id, out _id);
        DataTable dt = APQuestionnaireManager.GetAllQuestionsByQID(_id);

        string jsonResult = JSONHelper.DataTableToJSON(dt);

        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetPreviewQuestionsByQID()
    {
        string id = HttpContext.Current.Request.QueryString["id"];
        int _id = 0;
        int.TryParse(id, out _id);
        DataTable dt = APQuestionnaireManager.GetPreviewQuestionsByQID(_id);

        string jsonResult = JSONHelper.DataTableToJSON(dt);

        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void SubmitQuestionnaire()
    {
        string success = "0";
        try
        {
            string id = HttpContext.Current.Request.Params["id"];
            string name = HttpContext.Current.Request.Params["name"];
            string from = HttpContext.Current.Request.Params["fromdate"];
            string to = HttpContext.Current.Request.Params["todate"];
            string description = HttpContext.Current.Request.Params["description"];
            string score = HttpContext.Current.Request.Params["score"];
            string sampleNumber = HttpContext.Current.Request.Params["sampleNumber"];
            string frequency = HttpContext.Current.Request.Params["frequency"];
            string bAutoTickCorrectOption = HttpContext.Current.Request.Params["bAutoTickCorrectOption"];
            string bAutoRefreshPage = HttpContext.Current.Request.Params["bAutoRefreshPage"];
            string uploadType = HttpContext.Current.Request.Params["uploadType"];

            bool _bAutoTickCorrectOption = false;
            bool.TryParse(bAutoTickCorrectOption, out _bAutoTickCorrectOption);
            bool _bAutoRefreshPage = false;
            bool.TryParse(bAutoRefreshPage, out _bAutoRefreshPage);

            DateTime fromdate = Constants.Date_Null;
            DateTime todate = Constants.Date_Null;
            DateTime.TryParse(from, out fromdate);
            DateTime.TryParse(to, out todate);
            int _score = 0;
            int.TryParse(score, out _score);
            int _sampleNumber = 0;
            int.TryParse(sampleNumber, out _sampleNumber);
            int _frequency = 0;
            int.TryParse(frequency, out _frequency);
            int _id = 0;
            int.TryParse(id, out _id);
            int _uploadType = 0;
            int.TryParse(uploadType, out _uploadType);
            APQuestionnairesDO apo = new APQuestionnairesDO();
            if (_id > 0)
            {
                apo = APQuestionnaireManager.GetQuestionnaireByID(_id);
                apo.LastModifiedTime = DateTime.Now;
                apo.LastModifiedUserID = WebSiteContext.CurrentUserID;
            }
            else
            {
                apo.Status = 1;
                apo.CreateTime = DateTime.Now;
                apo.CreateUserID = WebSiteContext.CurrentUserID;
            }
            apo.Name = name;
            apo.FromDate = fromdate;
            apo.ToDate = todate;
            apo.Description = description;
            apo.TotalScore = _score;
            apo.SampleNumber = _sampleNumber;
            apo.Frequency = _frequency;
            apo.ProjectID = WebSiteContext.CurrentProjectID;
            apo.BAutoTickCorrectOption = _bAutoTickCorrectOption;
            apo.BAutoRefreshPage = _bAutoRefreshPage;
            apo.UploadType = _uploadType;
            apo.DeleteFlag = false;
            if (_id > 0)
            {
                BusinessLogicBase.Default.Update(apo);
            }
            else
            {
                _id = BusinessLogicBase.Default.Insert(apo);
            }
            success = _id.ToString();

        }
        catch {
            success = "0";
        }
        
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(success);    
    }

    public void GetQuestionnaires()
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
        
        int projectID = WebSiteContext.CurrentProjectID;
        if (name == null) {
            name = string.Empty;
        }

        int userID = WebSiteContext.CurrentUserID;
        int roleID = WebSiteContext.Current.CurrentUser.RoleID;
        
        DataTable dt = APQuestionnaireManager.GetQuestionnaires(projectID, name, fromdate, todate, _statusID, userID, roleID);
        jsonResult = JSONHelper.DataTableToJSON(dt);

        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetQuestionnaireInfo() 
    {
        string id = HttpContext.Current.Request.QueryString["id"];
        int _id = 0;
        int.TryParse(id, out _id);
        DataTable dt = APQuestionnaireManager.GetQuestionnaireInfoByID(_id);

        string jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetQuestionInfo()
    {
        string id = HttpContext.Current.Request.QueryString["id"];
        int _id = 0;
        int.TryParse(id, out _id);
        APQuestionsDO apo = APQuestionnaireManager.GetQuestionDOByID(_id);
        DataTable dt = APQuestionnaireManager.GetQuestionOptions(_id);        
        string jsonQuestion = JSONHelper.ObjectToJSON(apo);
        string jsonOptions = JSONHelper.DataTableToJSON(dt);
        string jsonResult = "{\"Question\":" + jsonQuestion + ",\"Options\":" + jsonOptions + "}";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void DeleteQuestionnaire()
    {
        string id = HttpContext.Current.Request.Params["id"];
        int _id = 0;
        int.TryParse(id, out _id);
        string jsonResult = string.Empty;
        try
        {
            APQuestionnaireManager.DeleteQuestionnaire(_id);
            jsonResult = "1";
        }
        catch {
            jsonResult = "0";
        }
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }
 
    public bool IsReusable {
        get {
            return false;
        }
    }

}