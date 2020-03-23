<%@ WebHandler Language="C#" Class="Upload_ICTR2" %>

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
using System.Diagnostics;

public class Upload_ICTR2 : IHttpHandler, IRequiresSessionState
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
                    UploadGongjiaoResultDataByUrl();
                    break;
                case 11:
                    UploadGongjiaoResultDataByUrl_Add();
                    break;
                case 2:
                    UploadShangquanResultDataByUrl();
                    break;
                case 22:
                    UploadShangquanResultDataByUrl_Add();
                    break;
                case 3:
                    UploadChaoshiResultDataByUrl();
                    break;
                case 33:
                    UploadChaoshiResultDataByUrl_Add();
                    break;
                case 25:
                    GetShanghuMoreImages();
                    break;
                case 99:
                    FixImageInResult();
                    break;
                default:
                    break;
            }
        }
        catch 
        { 
        
        }
    }


    public void FixImageInResult() 
    {
        byte[] byts = new byte[HttpContext.Current.Request.InputStream.Length];
        HttpContext.Current.Request.InputStream.Read(byts, 0, byts.Length);
        string jsonData = System.Text.Encoding.Default.GetString(byts);
        Newtonsoft.Json.Linq.JObject resultObj = (Newtonsoft.Json.Linq.JObject)Newtonsoft.Json.JsonConvert.DeserializeObject(jsonData);
        string downUrl = resultObj["downUrl"].ToString();
        int projectID = resultObj["projectID"].ToString().ToInt(0);
        int questionnaireID = resultObj["questionnaireID"].ToString().ToInt(0);
        
        string otherPlatformID = resultObj["otherPlatformID"].ToString();
        int questionID = resultObj["questionID"].ToString().ToInt(0);
        
        DateTime fromDate = resultObj["fromDate"].ToString().ToDateTime(Constants.Date_Min);
        DateTime toDate = resultObj["toDate"].ToString().ToDateTime(Constants.Date_Max);

        string fileName = downUrl.Substring(downUrl.LastIndexOf('/') + 1);
        string folderName = Path.GetFileNameWithoutExtension(fileName);
        string extension = Path.GetExtension(fileName);
        string result = "0";
        string vituralPath = Constants.RelevantTempPath;
        string physicalPath = HttpContext.Current.Server.MapPath(vituralPath);
        string originalName = fileName;
        string name = fileName;
        string diskFolderPath = physicalPath.TrimEnd('\\') + "\\" + folderName + "\\";
        if (Directory.Exists(diskFolderPath) == false)
        {
            Directory.CreateDirectory(diskFolderPath);
        }
        string diskFilePath = diskFolderPath + originalName;
        diskFilePath = CommonFunction.GetNewPathForDuplicates(diskFilePath);
        CommonFunction.DownloadFile(downUrl, diskFilePath);

        try
        {
            DataTable dt = NPOIHelper.ImportExceltoDt(diskFilePath, "Data", 0);
            DataTable dtGPS = NPOIHelper.ImportExceltoDt(diskFilePath, "Geographical", 0);
            if (dt == null || dt.Rows.Count <= 1)
            {
                result = "0没有数据";
                HttpContext.Current.Response.ContentType = "text/plain";
                HttpContext.Current.Response.Write(result);
                return;
            }

            DirectoryMappingDO dmDO = DocumentManager.GetCurrentDirMappingDO();
            string file_physicalPath = dmDO.PhysicalPath;
            string file_vituralPath = dmDO.VituralPath;
            string fileNameWithoutExtension = Path.GetFileNameWithoutExtension(fileName).Trim();
            if (dt != null && dt.Rows.Count > 0)
            {
                //从第2行开始读
                for (int i = 1; i < dt.Rows.Count; i++)
                {
                    DataRow row = dt.Rows[i];
                    string sampleType = row["LX"].ToString();
                    string b1 = row["B1"].ToString();
                    if (sampleType != "正式样本")
                    {
                        continue;
                    }
                    if (b1 == "不支持")
                    {
                        continue;
                    }
                    string id = row["链接标识"].ToString();
                    if (id != otherPlatformID)
                    {
                        continue;
                    }

                    LocateInfo info = GetLngLatByID(id, dtGPS);
                    string watermark = GetWatermarkByID(id, row["开始填答时间"].ToString(), dtGPS);
                    string clientCode = row["NO"].ToString();//商场编号

                    APClientsDO clientDO = APClientManager.GetClientByPostcode(clientCode, projectID);
                    if (clientDO == null || clientDO.ID < 0)
                    {
                        continue;
                    }
                    DataTable dtResult = APResultManager.GetResult(projectID, questionnaireID, id);
                    if (dtResult == null || dtResult.Rows.Count <= 0)
                    {
                        continue;
                    }
                    int resultID = dtResult.Rows[0][0].ToString().ToInt(0);
                    if (resultID <= 0)
                    {
                        continue;
                    }
                    string shopName = row["A6"].ToString();//商户名称

                    APQuestionsDO qdo = new APQuestionsDO();
                    qdo = (APQuestionsDO)BusinessLogicBase.Default.Select(qdo, questionID);
                    if (qdo == null || qdo.ID <= 0) 
                    {
                        continue;
                    }

                    string questionCode = qdo.Code;
                    string questionName = qdo.Title;
                    int questionType = qdo.QuestionType;

                    if (dt.Columns.Contains(questionCode.Trim()) == false)
                    {
                        continue;
                    }
                    //答案为空时，直接跳过
                    string value = row[questionCode].ToString();
                    if (string.IsNullOrEmpty(value))
                    {
                        continue;
                    }

                    int answerID = 0;
                    APAnswersDO answerDO = APQuestionManager.GetAnwserDO(resultID, questionID);
                    if (answerDO == null || answerDO.ID <= 0)
                    {
                        answerDO = new APAnswersDO();
                    }
                    answerID = answerDO.ID;
                    answerDO.ResultID = resultID;
                    answerDO.QuestionID = questionID;
                    answerDO.CreateTime = DateTime.Now;
                    answerDO.Status = (int)Enums.DeleteStatus.正常;
                    answerDO.CreateUserID = WebSiteContext.CurrentUserID;
                    answerDO.TotalScore = 0;
                    if (answerID > 0)
                    {
                        BusinessLogicBase.Default.Update(answerDO);
                    }
                    else
                    {
                        answerID = BusinessLogicBase.Default.Insert(answerDO);
                    }

                    if (questionType == (int)Enums.QuestionType.上传题)
                    {
                        string imageUrl = value;
                        string signature = imageUrl.Substring(imageUrl.LastIndexOf("&Signature=") + 11);
                        string encodingSignature = HttpUtility.UrlEncode(signature);
                        imageUrl = imageUrl.Replace(signature, encodingSignature);
                        string imageFileName = CommonFunction.GetFileNameInUrl(imageUrl);
                        string tempFilePath = diskFolderPath + imageFileName;
                        CommonFunction.DownloadFile(imageUrl, tempFilePath);

                        string extestion = Path.GetExtension(tempFilePath);
                        //分公司-城市-商圈名称-商场名称-商户名称-指标名称.jpg
                        string formatFileName = APClientManager.GetFormatFileName(clientDO.ID) + "-" + shopName + "-" + questionName + extestion;
                        formatFileName = CommonFunction.FixedSpecialCharsInFileName(formatFileName);
                        SaveResultImageFile(tempFilePath, file_physicalPath, file_vituralPath, projectID, resultID, questionID, answerID,
                            fromDate.ToString("yyyy-MM-dd"), clientDO.Code, formatFileName, (int)Enums.FileType.图片, watermark, (int)Enums.DocumentType.执行上传);

                    }
                }

                try
                {
                    Directory.Delete(diskFolderPath, true);
                }
                catch { }

                StringBuilder message = new StringBuilder();
                List<string> msgList = new List<string>();

                result = "1" + message.ToString();
                HttpContext.Current.Response.ContentType = "text/plain";
                HttpContext.Current.Response.Write(result);
            }
        }
        catch (Exception ex)
        {
            result = "0" + ex.ToString();
            HttpContext.Current.Response.ContentType = "text/plain";
            HttpContext.Current.Response.Write(result);
        }
    }

    public void UploadShangquanResultDataByUrl_Add()
    {
        byte[] byts = new byte[HttpContext.Current.Request.InputStream.Length];
        HttpContext.Current.Request.InputStream.Read(byts, 0, byts.Length);
        string jsonData = System.Text.Encoding.Default.GetString(byts);
        Newtonsoft.Json.Linq.JObject resultObj = (Newtonsoft.Json.Linq.JObject)Newtonsoft.Json.JsonConvert.DeserializeObject(jsonData);
        string downUrl = resultObj["downUrl"].ToString();
        int projectID = resultObj["projectID"].ToString().ToInt(0);
        int questionnaireID = resultObj["questionnaireID"].ToString().ToInt(0);
        DateTime fromDate = resultObj["fromDate"].ToString().ToDateTime(Constants.Date_Min);
        DateTime toDate = resultObj["toDate"].ToString().ToDateTime(Constants.Date_Max);

        string fileName = downUrl.Substring(downUrl.LastIndexOf('/') + 1);
        string folderName = Path.GetFileNameWithoutExtension(fileName);
        string extension = Path.GetExtension(fileName);
        string result = "0";
        string vituralPath = Constants.RelevantTempPath;
        string physicalPath = HttpContext.Current.Server.MapPath(vituralPath);
        string originalName = fileName;
        string name = fileName;
        string diskFolderPath = physicalPath.TrimEnd('\\') + "\\" + folderName + "\\";
        if (Directory.Exists(diskFolderPath) == false)
        {
            Directory.CreateDirectory(diskFolderPath);
        }
        string diskFilePath = diskFolderPath + originalName;
        diskFilePath = CommonFunction.GetNewPathForDuplicates(diskFilePath);
        CommonFunction.DownloadFile(downUrl, diskFilePath);

        try
        {
            DataTable dt = NPOIHelper.ImportExceltoDt(diskFilePath, "Data", 0);
            if (dt == null || dt.Rows.Count <= 1)
            {
                result = "0没有数据";
                HttpContext.Current.Response.ContentType = "text/plain";
                HttpContext.Current.Response.Write(result);
                return;
            }
            if (dt != null && dt.Columns.Count > 0)
            {
                for (int i = 0; i < dt.Columns.Count; i++)
                {
                    dt.Columns[i].ColumnName = dt.Columns[i].ColumnName.Trim().Replace("#", "_");
                    //处理收银台编号问题
                    //E01_1-2 到 E02_1
                    if (dt.Columns[i].ColumnName.Contains("-"))
                    {
                        string columnName = dt.Columns[i].ColumnName;
                        string currentQuestionCode = columnName.Substring(0, columnName.LastIndexOf('-'));//E01_1
                        string realNum = columnName.Substring(columnName.LastIndexOf('-') + 1);//2
                        if (realNum != "")
                        {
                            string realQuestionCode = "E" + realNum.PadLeft(2, '0');//E02
                            string fixedQuestionCode = currentQuestionCode.Replace("E01", realQuestionCode);
                            dt.Columns[i].ColumnName = fixedQuestionCode;
                        }
                    }
                }
            }

            DirectoryMappingDO dmDO = DocumentManager.GetCurrentDirMappingDO();
            string file_physicalPath = dmDO.PhysicalPath;
            string file_vituralPath = dmDO.VituralPath;
            string fileNameWithoutExtension = Path.GetFileNameWithoutExtension(fileName).Trim();
            if (dt != null && dt.Rows.Count > 0)
            {
                DataTable dtQuestions = APQuestionManager.GetQuestionsTableByQuestionnaireID(questionnaireID);
                //从第2行开始读
                for (int i = 1; i < dt.Rows.Count; i++)
                {
                    DataRow row = dt.Rows[i];
                    string sampleType = row["LX"].ToString();
                    string b1 = row["B1"].ToString();
                    if (sampleType != "正式样本")
                    {
                        continue;
                    }
                    if (b1 == "不支持")
                    {
                        continue;
                    }
                    string id = row["链接标识"].ToString();
                    string versionId = row["版本编号"].ToString();

                    string photoAddress = row["09"].ToString();
                    string photoTime = row["10"].ToString();
                    string watermark = photoAddress + " " + photoTime;

                    DateTime visitBeginTime = row["开始填答时间"].ToString().ToDateTime(Constants.Date_Min);
                    DateTime visitEndTime = row["结束填答时间"].ToString().ToDateTime(Constants.Date_Max);
                    int timeLength = row["访问时长"].ToString().Replace("秒", "").ToInt(0);//秒为单位
                    timeLength = timeLength / 60;//转化为分钟
                    string clientCode = row["NO"].ToString();//商场编号

                    APClientsDO clientDO = APClientManager.GetClientByPostcode(clientCode, projectID);
                    if (clientDO == null || clientDO.ID < 0)
                    {
                        continue;
                    }
                    APQuestionnaireDeliveryDO deliveryDO = APQuestionnaireManager.GetQuestionnaireDeliveryDO(questionnaireID, clientDO.ID, fromDate, toDate, (int)Enums.UserType.访问员);
                    int deliveryID = deliveryDO.ID;
                    int visitUserID = deliveryDO.AcceptUserID;

                    DataTable dtResult = APResultManager.GetResult(projectID, questionnaireID, clientDO.ID, id);
                    if (dtResult != null && dtResult.Rows.Count > 0)
                    {
                        continue;
                    }

                    APQuestionnaireResultsDO resultDO = new APQuestionnaireResultsDO();
                    resultDO.QuestionnaireID = questionnaireID;
                    resultDO.ClientID = clientDO.ID;
                    resultDO.DeliveryID = deliveryID;
                    resultDO.VisitUserID = visitUserID;
                    resultDO.Status = (int)Enums.QuestionnaireStageStatus.质控审核中;
                    resultDO.VisitUserUploadStatus = (int)Enums.QuestionnaireUploadStatus.已提交审核;
                    resultDO.VisitBeginTime = visitBeginTime;
                    resultDO.VisitEndTime = visitEndTime;
                    resultDO.UploadBeginTime = visitBeginTime;
                    resultDO.UploadEndTime = visitEndTime;
                    resultDO.TimeLength = timeLength;
                    resultDO.FromDate = fromDate;
                    resultDO.ToDate = toDate;
                    resultDO.WeekNum = CommonFunction.GetWeekNum(visitBeginTime);
                    resultDO.ProjectID = projectID;
                    resultDO.OtherPlatformID = id;
                    resultDO.Address = watermark;
                    resultDO.QuestionnaireVersion = versionId;
                    string gpsTip = "后补样本";
                    resultDO.Description = gpsTip;

                    int resultID = BusinessLogicBase.Default.Insert(resultDO);

                    string shopName = "商户名称";

                    for (int j = 0; j < dtQuestions.Rows.Count; j++)
                    {
                        int questionID = dtQuestions.Rows[j]["ID"].ToString().ToInt(0);
                        string questionCode = dtQuestions.Rows[j]["Code"].ToString();
                        string questionName = dtQuestions.Rows[j]["Title"].ToString();
                        int questionType = dtQuestions.Rows[j]["QuestionType"].ToString().ToInt(0);

                        if (dt.Columns.Contains(questionCode.Trim()) == false)
                        {
                            continue;
                        }
                        //答案为空时，直接跳过
                        string value = row[questionCode].ToString();
                        if (string.IsNullOrEmpty(value))
                        {
                            continue;
                        }

                        int answerID = 0;
                        APAnswersDO answerDO = APQuestionManager.GetAnwserDO(resultID, questionID);
                        if (answerDO == null || answerDO.ID <= 0)
                        {
                            answerDO = new APAnswersDO();
                        }
                        answerID = answerDO.ID;
                        answerDO.ResultID = resultID;
                        answerDO.QuestionID = questionID;
                        answerDO.CreateTime = DateTime.Now;
                        answerDO.Status = (int)Enums.DeleteStatus.正常;
                        answerDO.CreateUserID = WebSiteContext.CurrentUserID;
                        answerDO.TotalScore = 0;
                        if (answerID > 0)
                        {
                            BusinessLogicBase.Default.Update(answerDO);
                        }
                        else
                        {
                            answerID = BusinessLogicBase.Default.Insert(answerDO);
                        }

                        if (questionType == (int)Enums.QuestionType.填空题)
                        {
                            APAnswerOptionsDO optionDO = APQuestionManager.GetAnswerOption(answerID, -1);
                            if (optionDO == null || optionDO.ID <= 0)
                            {
                                optionDO = new APAnswerOptionsDO();
                            }
                            optionDO.AnswerID = answerID;
                            optionDO.OptionID = -1;
                            optionDO.OptionText = value;
                            if (optionDO.ID > 0)
                            {
                                BusinessLogicBase.Default.Update(optionDO);
                            }
                            else
                            {
                                BusinessLogicBase.Default.Insert(optionDO);
                            }
                        }
                        else if (questionType == (int)Enums.QuestionType.上传题)
                        {
                            string imageUrl = value;
                            string signature = imageUrl.Substring(imageUrl.LastIndexOf("&Signature=") + 11);
                            string encodingSignature = HttpUtility.UrlEncode(signature);
                            imageUrl = imageUrl.Replace(signature, encodingSignature);
                            string imageFileName = CommonFunction.GetFileNameInUrl(imageUrl);
                            string tempFilePath = diskFolderPath + imageFileName;
                            CommonFunction.DownloadFile(imageUrl, tempFilePath);

                            string extestion = Path.GetExtension(tempFilePath);
                            //分公司-城市-商圈名称-商场名称-商户名称-指标名称.jpg
                            string formatFileName = APClientManager.GetFormatFileName(clientDO.ID) + "-" + shopName + "-" + questionName + extestion;
                            formatFileName = CommonFunction.FixedSpecialCharsInFileName(formatFileName);
                            SaveResultImageFile(tempFilePath, file_physicalPath, file_vituralPath, projectID, resultID, questionID, answerID,
                                fromDate.ToString("yyyy-MM-dd"), clientDO.Code, formatFileName, (int)Enums.FileType.图片, watermark, (int)Enums.DocumentType.执行上传);

                        }
                        else if (questionType == (int)Enums.QuestionType.单选题)
                        {
                            APOptionsDO option = APQuestionManager.GetOptionDO(questionID, value);
                            if (option != null && option.ID > 0)
                            {
                                APAnswerOptionsDO optionDO = APQuestionManager.GetAnswerOption(answerID, option.ID);
                                if (optionDO == null || optionDO.ID <= 0)
                                {
                                    optionDO = new APAnswerOptionsDO();
                                }
                                optionDO.AnswerID = answerID;
                                optionDO.OptionID = option.ID;
                                //optionDO.OptionText = value;
                                if (optionDO.ID > 0)
                                {
                                    BusinessLogicBase.Default.Update(optionDO);
                                }
                                else
                                {
                                    BusinessLogicBase.Default.Insert(optionDO);
                                }
                            }
                        }
                        else if (questionType == (int)Enums.QuestionType.多选题 || questionType == (int)Enums.QuestionType.是非题)
                        {
                            string[] optionTexts = value.Split(new char[] { '~' }, StringSplitOptions.RemoveEmptyEntries);
                            if (optionTexts != null && optionTexts.Length > 0)
                            {
                                foreach (string optionText in optionTexts)
                                {
                                    APOptionsDO option = APQuestionManager.GetOptionDO(questionID, optionText.Trim());
                                    if (option != null && option.ID > 0)
                                    {
                                        APAnswerOptionsDO optionDO = APQuestionManager.GetAnswerOption(answerID, option.ID);
                                        if (optionDO == null || optionDO.ID <= 0)
                                        {
                                            optionDO = new APAnswerOptionsDO();
                                        }
                                        optionDO.AnswerID = answerID;
                                        optionDO.OptionID = option.ID;
                                        //optionDO.OptionText = value;
                                        if (optionDO.ID > 0)
                                        {
                                            BusinessLogicBase.Default.Update(optionDO);
                                        }
                                        else
                                        {
                                            BusinessLogicBase.Default.Insert(optionDO);
                                        }
                                    }
                                }
                            }
                        }
                    }


                    int counterNum = row["D2_0"].ToString().Trim().ToInt(0);
                    if (counterNum > 0 && counterNum < 15)
                    {
                        for (int k = counterNum + 1; k <= 15; k++)
                        {
                            string questionCode = "E" + k.ToString().PadLeft(2, '0') + "_1";
                            string value = "无";
                            int questionID = APQuestionManager.GetQuestionIDByCode2(questionnaireID, questionCode);
                            int answerID = 0;
                            APAnswersDO answerDO = APQuestionManager.GetAnwserDO(resultID, questionID);
                            if (answerDO == null || answerDO.ID <= 0)
                            {
                                answerDO = new APAnswersDO();
                            }
                            answerID = answerDO.ID;
                            answerDO.ResultID = resultID;
                            answerDO.QuestionID = questionID;
                            answerDO.CreateTime = DateTime.Now;
                            answerDO.Status = (int)Enums.DeleteStatus.正常;
                            answerDO.CreateUserID = WebSiteContext.CurrentUserID;
                            answerDO.TotalScore = 0;
                            if (answerID > 0)
                            {
                                BusinessLogicBase.Default.Update(answerDO);
                            }
                            else
                            {
                                answerID = BusinessLogicBase.Default.Insert(answerDO);
                            }
                            APOptionsDO option = APQuestionManager.GetOptionDO(questionID, value);
                            if (option != null && option.ID > 0)
                            {
                                APAnswerOptionsDO optionDO = APQuestionManager.GetAnswerOption(answerID, option.ID);
                                if (optionDO == null || optionDO.ID <= 0)
                                {
                                    optionDO = new APAnswerOptionsDO();
                                }
                                optionDO.AnswerID = answerID;
                                optionDO.OptionID = option.ID;
                                if (optionDO.ID > 0)
                                {
                                    BusinessLogicBase.Default.Update(optionDO);
                                }
                                else
                                {
                                    BusinessLogicBase.Default.Insert(optionDO);
                                }
                            }
                        }
                    }
                }
            }

            try
            {
                Directory.Delete(diskFolderPath, true);
            }
            catch { }

            StringBuilder message = new StringBuilder();
            List<string> msgList = new List<string>();

            result = "1" + message.ToString();
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

    public void UploadChaoshiResultDataByUrl_Add()
    {
        byte[] byts = new byte[HttpContext.Current.Request.InputStream.Length];
        HttpContext.Current.Request.InputStream.Read(byts, 0, byts.Length);
        string jsonData = System.Text.Encoding.Default.GetString(byts);
        Newtonsoft.Json.Linq.JObject resultObj = (Newtonsoft.Json.Linq.JObject)Newtonsoft.Json.JsonConvert.DeserializeObject(jsonData);
        string downUrl = resultObj["downUrl"].ToString();
        DateTime fromDate = resultObj["fromDate"].ToString().ToDateTime(Constants.Date_Min);
        DateTime toDate = resultObj["toDate"].ToString().ToDateTime(Constants.Date_Max);

        string fileName = downUrl.Substring(downUrl.LastIndexOf('/') + 1);
        string folderName = Path.GetFileNameWithoutExtension(fileName);
        string extension = Path.GetExtension(fileName);
        string result = "0";
        string vituralPath = Constants.RelevantTempPath;
        string physicalPath = HttpContext.Current.Server.MapPath(vituralPath);
        string originalName = fileName;
        string name = fileName;
        string diskFolderPath = physicalPath.TrimEnd('\\') + "\\" + folderName + "\\";
        if (Directory.Exists(diskFolderPath) == false)
        {
            Directory.CreateDirectory(diskFolderPath);
        }
        string diskFilePath = diskFolderPath + originalName;
        diskFilePath = CommonFunction.GetNewPathForDuplicates(diskFilePath);
        CommonFunction.DownloadFile(downUrl, diskFilePath);

        try
        {
            DataTable dt = NPOIHelper.ImportExceltoDt(diskFilePath, "Data", 0);
            if (dt == null || dt.Rows.Count <= 1)
            {
                result = "0没有数据";
                HttpContext.Current.Response.ContentType = "text/plain";
                HttpContext.Current.Response.Write(result);
                return;
            }
            if (dt != null && dt.Columns.Count > 0)
            {
                for (int i = 0; i < dt.Columns.Count; i++)
                {
                    dt.Columns[i].ColumnName = dt.Columns[i].ColumnName.Trim().Replace("#", "_");
                    //处理收银台编号问题
                    //E01_1-2 到 E02_1
                    if (dt.Columns[i].ColumnName.Contains("-"))
                    {
                        string columnName = dt.Columns[i].ColumnName;
                        string currentQuestionCode = columnName.Substring(0, columnName.LastIndexOf('-'));//E01_1
                        string realNum = columnName.Substring(columnName.LastIndexOf('-') + 1);//2
                        if (realNum != "")
                        {
                            string realQuestionCode = "E" + realNum.PadLeft(2, '0');//E02
                            string fixedQuestionCode = currentQuestionCode.Replace("E01", realQuestionCode);
                            dt.Columns[i].ColumnName = fixedQuestionCode;
                        }
                    }
                }
            }

            DirectoryMappingDO dmDO = DocumentManager.GetCurrentDirMappingDO();
            string file_physicalPath = dmDO.PhysicalPath;
            string file_vituralPath = dmDO.VituralPath;
            string fileNameWithoutExtension = Path.GetFileNameWithoutExtension(fileName).Trim();
            if (dt != null && dt.Rows.Count > 0)
            {

                //从第2行开始读
                for (int i = 1; i < dt.Rows.Count; i++)
                {
                    DataRow row = dt.Rows[i];
                    string sampleType = row["LX"].ToString();
                    string b1 = row["B1"].ToString();
                    if (sampleType != "正式样本")
                    {
                        continue;
                    }
                    if (b1 == "不支持")
                    {
                        continue;
                    }
                    int projectID = 0;
                    int questionnaireID = 0;
                    string projectType = row["WJTYPE"].ToString();
                    if (projectType == "餐饮")
                    {
                        projectID = 5;
                        questionnaireID = 5;
                    }
                    else
                    {
                        //商超便利店
                        projectID = 4;
                        questionnaireID = 4;
                    }
                    DataTable dtQuestions = APQuestionManager.GetQuestionsTableByQuestionnaireID(questionnaireID);

                    string id = row["链接标识"].ToString();
                    string versionId = row["版本编号"].ToString();

                    string photoAddress = row["09"].ToString();
                    string photoTime = row["10"].ToString();
                    string watermark = photoAddress + " " + photoTime;
                    
                    DateTime visitBeginTime = row["开始填答时间"].ToString().ToDateTime(Constants.Date_Min);
                    DateTime visitEndTime = row["结束填答时间"].ToString().ToDateTime(Constants.Date_Max);
                    int timeLength = row["访问时长"].ToString().Replace("秒", "").ToInt(0);//秒为单位
                    timeLength = timeLength / 60;//转化为分钟

                    DataTable dtResult = APResultManager.GetResult(projectID, questionnaireID, id);
                    if (dtResult != null && dtResult.Rows.Count > 0)
                    {
                        continue;
                    }
                    //提示; 先获取城市，然后将该地址加入到城市下面
                    string clientCode = row["NO"].ToString();//超市便利店或餐饮店编号
                    string shopName = row["na6"].ToString();//门店名称
                    string cityName = row["05"].ToString();//城市名称
                    string address = row["A7"].ToString();//门店地址
                    string[] locationInfo = row["na9"].ToString().Split(',');//经纬度
                    string locationCodeX = string.Empty;
                    string locationCodeY = string.Empty;
                    if (locationInfo != null && locationInfo.Length == 2)
                    {
                        locationCodeX = locationInfo[0];
                        locationCodeY = locationInfo[1];
                        if (!string.IsNullOrEmpty(locationCodeX) && !string.IsNullOrEmpty(locationCodeY))
                        {
                            LocateInfo bdLocate = MapHelper.gcj02_To_Bd09(locationCodeY.ToDouble(0), locationCodeX.ToDouble(0));
                            locationCodeX = bdLocate.Longitude.ToString();
                            locationCodeY = bdLocate.Latitude.ToString();
                        }
                    }
                    APClientsDO clientDO = APClientManager.GetClientByPostcode(clientCode, projectID);
                    if (clientDO == null || clientDO.ID < 0)
                    {
                        APClientsDO parentClientDO = APClientManager.GetClientByName(cityName, projectID, 3);
                        if (parentClientDO == null || parentClientDO.ID < 0)
                        {
                            continue;
                        }

                        clientDO = new APClientsDO();
                        clientDO.Address = address;
                        clientDO.City = parentClientDO.City;
                        clientDO.Code = clientCode;
                        clientDO.CreateTime = DateTime.Now;
                        clientDO.CreateUserID = 1;
                        clientDO.Description = "系统自动生成";
                        clientDO.LocationCodeX = locationCodeX;
                        clientDO.LocationCodeY = locationCodeY;
                        clientDO.Name = shopName;
                        clientDO.ParentID = parentClientDO.ID;
                        clientDO.LevelID = 4;
                        clientDO.Postcode = clientCode;
                        clientDO.ProjectID = projectID;
                        clientDO.Province = parentClientDO.Province;
                        clientDO.Status = parentClientDO.Status;
                        int clientID = BusinessLogicBase.Default.Insert(clientDO);
                        clientDO.ID = clientID;
                    }

                    APQuestionnaireDeliveryDO deliveryDO = APQuestionnaireManager.GetQuestionnaireDeliveryDO(questionnaireID, clientDO.ID, fromDate, toDate, (int)Enums.UserType.访问员);
                    if (deliveryDO == null || deliveryDO.ID <= 0)
                    {
                        deliveryDO = new APQuestionnaireDeliveryDO();
                        deliveryDO.AcceptUserID = 6;
                        deliveryDO.ClientID = clientDO.ID;
                        deliveryDO.CreateTime = DateTime.Now;
                        deliveryDO.FromDate = fromDate;
                        deliveryDO.ToDate = toDate;
                        deliveryDO.ProjectID = projectID;
                        deliveryDO.QuestionnaireID = questionnaireID;
                        deliveryDO.SampleNumber = 1;
                        deliveryDO.TypeID = (int)Enums.UserType.访问员;
                        int deliveryID = BusinessLogicBase.Default.Insert(deliveryDO);
                        deliveryDO.ID = deliveryID;
                    }

                    APQuestionnaireResultsDO resultDO = new APQuestionnaireResultsDO();
                    resultDO.QuestionnaireID = questionnaireID;
                    resultDO.ClientID = clientDO.ID;
                    resultDO.DeliveryID = deliveryDO.ID;
                    resultDO.VisitUserID = deliveryDO.AcceptUserID;
                    resultDO.Status = (int)Enums.QuestionnaireStageStatus.质控审核中;
                    resultDO.VisitUserUploadStatus = (int)Enums.QuestionnaireUploadStatus.已提交审核;
                    resultDO.VisitBeginTime = visitBeginTime;
                    resultDO.VisitEndTime = visitEndTime;
                    resultDO.UploadBeginTime = visitBeginTime;
                    resultDO.UploadEndTime = visitEndTime;
                    resultDO.TimeLength = timeLength;
                    resultDO.FromDate = fromDate;
                    resultDO.ToDate = toDate;
                    resultDO.WeekNum = CommonFunction.GetWeekNum(visitBeginTime);
                    resultDO.ProjectID = projectID;
                    resultDO.OtherPlatformID = id;
                    resultDO.Address = watermark;
                    resultDO.QuestionnaireVersion = versionId;
                    string gpsTip = "后补样本";
                    resultDO.Description = gpsTip;

                    int resultID = BusinessLogicBase.Default.Insert(resultDO);

                    for (int j = 0; j < dtQuestions.Rows.Count; j++)
                    {
                        int questionID = dtQuestions.Rows[j]["ID"].ToString().ToInt(0);
                        string questionCode = dtQuestions.Rows[j]["Code"].ToString();
                        string questionName = dtQuestions.Rows[j]["Title"].ToString();
                        int questionType = dtQuestions.Rows[j]["QuestionType"].ToString().ToInt(0);

                        if (dt.Columns.Contains(questionCode.Trim()) == false)
                        {
                            continue;
                        }
                        //答案为空时，直接跳过
                        string value = row[questionCode].ToString();
                        //if (questionCode == "01")
                        //{
                        //    value = row["na1"].ToString();
                        //}
                        //else if (questionCode == "A7") 
                        //{
                        //    value = row["01"].ToString();
                        //}
                        if (string.IsNullOrEmpty(value))
                        {
                            continue;
                        }

                        int answerID = 0;
                        APAnswersDO answerDO = APQuestionManager.GetAnwserDO(resultID, questionID);
                        if (answerDO == null || answerDO.ID <= 0)
                        {
                            answerDO = new APAnswersDO();
                        }
                        answerID = answerDO.ID;
                        answerDO.ResultID = resultID;
                        answerDO.QuestionID = questionID;
                        answerDO.CreateTime = DateTime.Now;
                        answerDO.Status = (int)Enums.DeleteStatus.正常;
                        answerDO.CreateUserID = WebSiteContext.CurrentUserID;
                        answerDO.TotalScore = 0;
                        if (answerID > 0)
                        {
                            BusinessLogicBase.Default.Update(answerDO);
                        }
                        else
                        {
                            answerID = BusinessLogicBase.Default.Insert(answerDO);
                        }

                        if (questionType == (int)Enums.QuestionType.填空题)
                        {
                            APAnswerOptionsDO optionDO = APQuestionManager.GetAnswerOption(answerID, -1);
                            if (optionDO == null || optionDO.ID <= 0)
                            {
                                optionDO = new APAnswerOptionsDO();
                            }
                            optionDO.AnswerID = answerID;
                            optionDO.OptionID = -1;
                            optionDO.OptionText = value;
                            if (optionDO.ID > 0)
                            {
                                BusinessLogicBase.Default.Update(optionDO);
                            }
                            else
                            {
                                BusinessLogicBase.Default.Insert(optionDO);
                            }
                        }
                        else if (questionType == (int)Enums.QuestionType.上传题)
                        {
                            string imageUrl = value;
                            string signature = imageUrl.Substring(imageUrl.LastIndexOf("&Signature=") + 11);
                            string encodingSignature = HttpUtility.UrlEncode(signature);
                            imageUrl = imageUrl.Replace(signature, encodingSignature);
                            string imageFileName = CommonFunction.GetFileNameInUrl(imageUrl);
                            string tempFilePath = diskFolderPath + imageFileName;
                            CommonFunction.DownloadFile(imageUrl, tempFilePath);

                            string extestion = Path.GetExtension(tempFilePath);
                            //分公司-城市-商户名称-指标名称.jpg
                            string formatFileName = APClientManager.GetFormatFileName(clientDO.ID) + "-" + questionName + extestion;
                            formatFileName = CommonFunction.FixedSpecialCharsInFileName(formatFileName);
                            SaveResultImageFile(tempFilePath, file_physicalPath, file_vituralPath, projectID, resultID, questionID, answerID,
                                fromDate.ToString("yyyy-MM-dd"), clientDO.Code, formatFileName, (int)Enums.FileType.图片, watermark, (int)Enums.DocumentType.执行上传);

                        }
                        else if (questionType == (int)Enums.QuestionType.单选题)
                        {
                            APOptionsDO option = APQuestionManager.GetOptionDO(questionID, value);
                            if (option != null && option.ID > 0)
                            {
                                APAnswerOptionsDO optionDO = APQuestionManager.GetAnswerOption(answerID, option.ID);
                                if (optionDO == null || optionDO.ID <= 0)
                                {
                                    optionDO = new APAnswerOptionsDO();
                                }
                                optionDO.AnswerID = answerID;
                                optionDO.OptionID = option.ID;
                                //optionDO.OptionText = value;
                                if (optionDO.ID > 0)
                                {
                                    BusinessLogicBase.Default.Update(optionDO);
                                }
                                else
                                {
                                    BusinessLogicBase.Default.Insert(optionDO);
                                }
                            }
                        }
                        else if (questionType == (int)Enums.QuestionType.多选题 || questionType == (int)Enums.QuestionType.是非题)
                        {
                            string[] optionTexts = value.Split(new char[] { '~' }, StringSplitOptions.RemoveEmptyEntries);
                            if (optionTexts != null && optionTexts.Length > 0)
                            {
                                foreach (string optionText in optionTexts)
                                {
                                    APOptionsDO option = APQuestionManager.GetOptionDO(questionID, optionText.Trim());
                                    if (option != null && option.ID > 0)
                                    {
                                        APAnswerOptionsDO optionDO = APQuestionManager.GetAnswerOption(answerID, option.ID);
                                        if (optionDO == null || optionDO.ID <= 0)
                                        {
                                            optionDO = new APAnswerOptionsDO();
                                        }
                                        optionDO.AnswerID = answerID;
                                        optionDO.OptionID = option.ID;
                                        //optionDO.OptionText = value;
                                        if (optionDO.ID > 0)
                                        {
                                            BusinessLogicBase.Default.Update(optionDO);
                                        }
                                        else
                                        {
                                            BusinessLogicBase.Default.Insert(optionDO);
                                        }
                                    }
                                }
                            }
                        }
                    }


                    int counterNum = row["D2_0"].ToString().Trim().ToInt(0);
                    if (counterNum > 0 && counterNum < 20)
                    {
                        for (int k = counterNum + 1; k <= 20; k++)
                        {
                            string questionCode = "E" + k.ToString().PadLeft(2, '0') + "_1";
                            string value = "无";
                            int questionID = APQuestionManager.GetQuestionIDByCode2(questionnaireID, questionCode);
                            int answerID = 0;
                            APAnswersDO answerDO = APQuestionManager.GetAnwserDO(resultID, questionID);
                            if (answerDO == null || answerDO.ID <= 0)
                            {
                                answerDO = new APAnswersDO();
                            }
                            answerID = answerDO.ID;
                            answerDO.ResultID = resultID;
                            answerDO.QuestionID = questionID;
                            answerDO.CreateTime = DateTime.Now;
                            answerDO.Status = (int)Enums.DeleteStatus.正常;
                            answerDO.CreateUserID = WebSiteContext.CurrentUserID;
                            answerDO.TotalScore = 0;
                            if (answerID > 0)
                            {
                                BusinessLogicBase.Default.Update(answerDO);
                            }
                            else
                            {
                                answerID = BusinessLogicBase.Default.Insert(answerDO);
                            }
                            APOptionsDO option = APQuestionManager.GetOptionDO(questionID, value);
                            if (option != null && option.ID > 0)
                            {
                                APAnswerOptionsDO optionDO = APQuestionManager.GetAnswerOption(answerID, option.ID);
                                if (optionDO == null || optionDO.ID <= 0)
                                {
                                    optionDO = new APAnswerOptionsDO();
                                }
                                optionDO.AnswerID = answerID;
                                optionDO.OptionID = option.ID;
                                if (optionDO.ID > 0)
                                {
                                    BusinessLogicBase.Default.Update(optionDO);
                                }
                                else
                                {
                                    BusinessLogicBase.Default.Insert(optionDO);
                                }
                            }
                        }
                    }
                }
            }

            try
            {
                Directory.Delete(diskFolderPath, true);
            }
            catch { }

            StringBuilder message = new StringBuilder();
            List<string> msgList = new List<string>();

            result = "1" + message.ToString();
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

    public void UploadChaoshiResultDataByUrl()
    {
        byte[] byts = new byte[HttpContext.Current.Request.InputStream.Length];
        HttpContext.Current.Request.InputStream.Read(byts, 0, byts.Length);
        string jsonData = System.Text.Encoding.Default.GetString(byts);
        Newtonsoft.Json.Linq.JObject resultObj = (Newtonsoft.Json.Linq.JObject)Newtonsoft.Json.JsonConvert.DeserializeObject(jsonData);
        string downUrl = resultObj["downUrl"].ToString();
        DateTime fromDate = resultObj["fromDate"].ToString().ToDateTime(Constants.Date_Min);
        DateTime toDate = resultObj["toDate"].ToString().ToDateTime(Constants.Date_Max);

        string fileName = downUrl.Substring(downUrl.LastIndexOf('/') + 1);
        string folderName = Path.GetFileNameWithoutExtension(fileName);
        string extension = Path.GetExtension(fileName);
        string result = "0";
        string vituralPath = Constants.RelevantTempPath;
        string physicalPath = HttpContext.Current.Server.MapPath(vituralPath);
        string originalName = fileName;
        string name = fileName;
        string diskFolderPath = physicalPath.TrimEnd('\\') + "\\" + folderName + "\\";
        if (Directory.Exists(diskFolderPath) == false)
        {
            Directory.CreateDirectory(diskFolderPath);
        }
        string diskFilePath = diskFolderPath + originalName;
        diskFilePath = CommonFunction.GetNewPathForDuplicates(diskFilePath);
        CommonFunction.DownloadFile(downUrl, diskFilePath);

        try
        {
            DataTable dt = NPOIHelper.ImportExceltoDt(diskFilePath, "Data", 0);
            DataTable dtGPS = NPOIHelper.ImportExceltoDt(diskFilePath, "Geographical", 0);
            if (dt == null || dt.Rows.Count <= 1)
            {
                result = "0没有数据";
                HttpContext.Current.Response.ContentType = "text/plain";
                HttpContext.Current.Response.Write(result);
                return;
            }
            if (dt != null && dt.Columns.Count > 0)
            {
                for (int i = 0; i < dt.Columns.Count; i++)
                {
                    dt.Columns[i].ColumnName = dt.Columns[i].ColumnName.Trim().Replace("#", "_");
                    //处理收银台编号问题
                    //E01_1-2 到 E02_1
                    if (dt.Columns[i].ColumnName.Contains("-"))
                    {
                        string columnName = dt.Columns[i].ColumnName;
                        string currentQuestionCode = columnName.Substring(0, columnName.LastIndexOf('-'));//E01_1
                        string realNum = columnName.Substring(columnName.LastIndexOf('-') + 1);//2
                        if (realNum != "")
                        {
                            string realQuestionCode = "E" + realNum.PadLeft(2, '0');//E02
                            string fixedQuestionCode = currentQuestionCode.Replace("E01", realQuestionCode);
                            dt.Columns[i].ColumnName = fixedQuestionCode;
                        }
                    }
                }
            }

            DirectoryMappingDO dmDO = DocumentManager.GetCurrentDirMappingDO();
            string file_physicalPath = dmDO.PhysicalPath;
            string file_vituralPath = dmDO.VituralPath;
            string fileNameWithoutExtension = Path.GetFileNameWithoutExtension(fileName).Trim();
            if (dt != null && dt.Rows.Count > 0)
            {
               
                //从第2行开始读
                for (int i = 1; i < dt.Rows.Count; i++)
                {
                    DataRow row = dt.Rows[i];
                    string sampleType = row["LX"].ToString();
                    string b1 = row["B1"].ToString();
                    if (sampleType != "正式样本")
                    {
                        continue;
                    }
                    if (b1 == "不支持")
                    {
                        continue;
                    }
                    int projectID = 0;
                    int questionnaireID = 0;
                    string projectType = row["WJTYPE"].ToString();
                    if (projectType == "餐饮")
                    {
                        projectID = 5;
                        questionnaireID = 5;
                    }
                    else
                    {
                        //商超便利店
                        projectID = 4;
                        questionnaireID = 4;
                    }
                    DataTable dtQuestions = APQuestionManager.GetQuestionsTableByQuestionnaireID(questionnaireID);
                    
                    string id = row["链接标识"].ToString();
                    string versionId = row["版本编号"].ToString();
                    LocateInfo info = GetLngLatByID(id, dtGPS);
                    string watermark = GetWatermarkByID(id, row["开始填答时间"].ToString(), dtGPS);

                    DateTime visitBeginTime = row["开始填答时间"].ToString().ToDateTime(Constants.Date_Min);
                    DateTime visitEndTime = row["结束填答时间"].ToString().ToDateTime(Constants.Date_Max);
                    int timeLength = row["访问时长"].ToString().Replace("秒", "").ToInt(0);//秒为单位
                    timeLength = timeLength / 60;//转化为分钟
                    
                    DataTable dtResult = APResultManager.GetResult(projectID, questionnaireID, id);
                    if (dtResult != null && dtResult.Rows.Count > 0)
                    {
                        continue;
                    }
                    //提示; 先获取城市，然后将该地址加入到城市下面
                    string clientCode = row["NO"].ToString();//超市便利店或餐饮店编号
                    string shopName = row["na6"].ToString();//门店名称
                    string cityName = row["05"].ToString();//城市名称
                    string address = row["A7"].ToString();//门店地址
                    string[] locationInfo = row["na9"].ToString().Split(',');//经纬度
                    string locationCodeX = string.Empty;
                    string locationCodeY = string.Empty;
                    if (locationInfo != null && locationInfo.Length == 2)
                    {
                        locationCodeX = locationInfo[0];
                        locationCodeY = locationInfo[1];
                        if (!string.IsNullOrEmpty(locationCodeX) && !string.IsNullOrEmpty(locationCodeY))
                        {
                            LocateInfo bdLocate = MapHelper.gcj02_To_Bd09(locationCodeY.ToDouble(0), locationCodeX.ToDouble(0));
                            locationCodeX = bdLocate.Longitude.ToString();
                            locationCodeY = bdLocate.Latitude.ToString();
                        }
                    }
                    APClientsDO clientDO = APClientManager.GetClientByPostcode(clientCode, projectID);
                    if (clientDO == null || clientDO.ID < 0)
                    {
                        APClientsDO parentClientDO = APClientManager.GetClientByName(cityName, projectID, 3);
                        if (parentClientDO == null || parentClientDO.ID < 0)
                        {
                            continue;
                        }

                        clientDO = new APClientsDO();
                        clientDO.Address = address;
                        clientDO.City = parentClientDO.City;
                        clientDO.Code = clientCode;
                        clientDO.CreateTime = DateTime.Now;
                        clientDO.CreateUserID = 1;
                        clientDO.Description = "系统自动生成";
                        clientDO.LocationCodeX = locationCodeX;
                        clientDO.LocationCodeY = locationCodeY;
                        clientDO.Name = shopName;
                        clientDO.ParentID = parentClientDO.ID;
                        clientDO.LevelID = 4;
                        clientDO.Postcode = clientCode;
                        clientDO.ProjectID = projectID;
                        clientDO.Province = parentClientDO.Province;
                        clientDO.Status = parentClientDO.Status;
                        int clientID = BusinessLogicBase.Default.Insert(clientDO);
                        clientDO.ID = clientID;
                    }

                    APQuestionnaireDeliveryDO deliveryDO = APQuestionnaireManager.GetQuestionnaireDeliveryDO(questionnaireID, clientDO.ID, fromDate, toDate, (int)Enums.UserType.访问员);
                    if (deliveryDO == null || deliveryDO.ID <= 0)
                    {
                        deliveryDO = new APQuestionnaireDeliveryDO();
                        deliveryDO.AcceptUserID = 6;
                        deliveryDO.ClientID = clientDO.ID;
                        deliveryDO.CreateTime = DateTime.Now;
                        deliveryDO.FromDate = fromDate;
                        deliveryDO.ToDate = toDate;
                        deliveryDO.ProjectID = projectID;
                        deliveryDO.QuestionnaireID = questionnaireID;
                        deliveryDO.SampleNumber = 1;
                        deliveryDO.TypeID = (int)Enums.UserType.访问员;
                        int deliveryID = BusinessLogicBase.Default.Insert(deliveryDO);
                        deliveryDO.ID = deliveryID;
                    }

                    APQuestionnaireResultsDO resultDO = new APQuestionnaireResultsDO();
                    resultDO.QuestionnaireID = questionnaireID;
                    resultDO.ClientID = clientDO.ID;
                    resultDO.DeliveryID = deliveryDO.ID;
                    resultDO.VisitUserID = deliveryDO.AcceptUserID;
                    resultDO.Status = (int)Enums.QuestionnaireStageStatus.质控审核中;
                    resultDO.VisitUserUploadStatus = (int)Enums.QuestionnaireUploadStatus.已提交审核;
                    resultDO.VisitBeginTime = visitBeginTime;
                    resultDO.VisitEndTime = visitEndTime;
                    resultDO.UploadBeginTime = visitBeginTime;
                    resultDO.UploadEndTime = visitEndTime;
                    resultDO.TimeLength = timeLength;
                    resultDO.FromDate = fromDate;
                    resultDO.ToDate = toDate;
                    resultDO.WeekNum = CommonFunction.GetWeekNum(visitBeginTime);
                    resultDO.ProjectID = projectID;
                    resultDO.OtherPlatformID = id;
                    resultDO.Address = watermark;
                    resultDO.QuestionnaireVersion = versionId;
                    string gpsTip = string.Empty;

                    if (info != null && info.Latitude > 0 && info.Longitude > 0)
                    {
                        //LocateInfo bdLocate = MapHelper.wgs84_To_Bd(info.Latitude, info.Longitude);
                        double lon = clientDO.LocationCodeX.ToDouble(0);
                        double lat = clientDO.LocationCodeY.ToDouble(0);
                        double distance = MapHelper.GetDistance(lat, lon, info.Latitude, info.Longitude);
                        resultDO.LocationX = info.Longitude;
                        resultDO.LocationY = info.Latitude;
                        gpsTip = "GPS位置偏差值：" + distance + "(米)";
                    }
                    else
                    {
                        gpsTip = "没有GPS位置信息";
                        resultDO.Status = (int)Enums.QuestionnaireStageStatus.录入中;
                        resultDO.VisitUserUploadStatus = (int)Enums.QuestionnaireUploadStatus.录入完成;
                    }
                    resultDO.Description = gpsTip;

                    int resultID = BusinessLogicBase.Default.Insert(resultDO);

                    try
                    {
                        int questionID = APQuestionManager.GetQuestionIDByCode2(questionnaireID, "A6");
                        if (questionID > 0 && resultDO.LocationX > 0 && resultDO.LocationY > 0)
                        {
                            GPSValication vObj = new GPSValication();
                            vObj.Longitude = resultDO.LocationX;
                            vObj.Latitude = resultDO.LocationY;
                            vObj.questionID = questionID;
                            vObj.resultID = resultID;
                            vObj.questionnaireID = questionnaireID;
                            APQuestionManager.StartGPSThead(vObj);
                        }
                    }
                    catch { }

                    for (int j = 0; j < dtQuestions.Rows.Count; j++)
                    {
                        int questionID = dtQuestions.Rows[j]["ID"].ToString().ToInt(0);
                        string questionCode = dtQuestions.Rows[j]["Code"].ToString();
                        string questionName = dtQuestions.Rows[j]["Title"].ToString();
                        int questionType = dtQuestions.Rows[j]["QuestionType"].ToString().ToInt(0);

                        if (dt.Columns.Contains(questionCode.Trim()) == false)
                        {
                            continue;
                        }
                        //答案为空时，直接跳过
                        string value = row[questionCode].ToString();
                        //if (questionCode == "01")
                        //{
                        //    value = row["na1"].ToString();
                        //}
                        //else if (questionCode == "A7") 
                        //{
                        //    value = row["01"].ToString();
                        //}
                        if (string.IsNullOrEmpty(value))
                        {
                            continue;
                        }

                        int answerID = 0;
                        APAnswersDO answerDO = APQuestionManager.GetAnwserDO(resultID, questionID);
                        if (answerDO == null || answerDO.ID <= 0)
                        {
                            answerDO = new APAnswersDO();
                        }
                        answerID = answerDO.ID;
                        answerDO.ResultID = resultID;
                        answerDO.QuestionID = questionID;
                        answerDO.CreateTime = DateTime.Now;
                        answerDO.Status = (int)Enums.DeleteStatus.正常;
                        answerDO.CreateUserID = WebSiteContext.CurrentUserID;
                        answerDO.TotalScore = 0;
                        if (answerID > 0)
                        {
                            BusinessLogicBase.Default.Update(answerDO);
                        }
                        else
                        {
                            answerID = BusinessLogicBase.Default.Insert(answerDO);
                        }

                        if (questionType == (int)Enums.QuestionType.填空题)
                        {
                            APAnswerOptionsDO optionDO = APQuestionManager.GetAnswerOption(answerID, -1);
                            if (optionDO == null || optionDO.ID <= 0)
                            {
                                optionDO = new APAnswerOptionsDO();
                            }
                            optionDO.AnswerID = answerID;
                            optionDO.OptionID = -1;
                            optionDO.OptionText = value;
                            if (optionDO.ID > 0)
                            {
                                BusinessLogicBase.Default.Update(optionDO);
                            }
                            else
                            {
                                BusinessLogicBase.Default.Insert(optionDO);
                            }
                        }
                        else if (questionType == (int)Enums.QuestionType.上传题)
                        {
                            string imageUrl = value;
                            string signature = imageUrl.Substring(imageUrl.LastIndexOf("&Signature=") + 11);
                            string encodingSignature = HttpUtility.UrlEncode(signature);
                            imageUrl = imageUrl.Replace(signature, encodingSignature);
                            string imageFileName = CommonFunction.GetFileNameInUrl(imageUrl);
                            string tempFilePath = diskFolderPath + imageFileName;
                            CommonFunction.DownloadFile(imageUrl, tempFilePath);

                            string extestion = Path.GetExtension(tempFilePath);
                            //分公司-城市-商户名称-指标名称.jpg
                            string formatFileName = APClientManager.GetFormatFileName(clientDO.ID) + "-" + questionName + extestion;
                            formatFileName = CommonFunction.FixedSpecialCharsInFileName(formatFileName);
                            SaveResultImageFile(tempFilePath, file_physicalPath, file_vituralPath, projectID, resultID, questionID, answerID,
                                fromDate.ToString("yyyy-MM-dd"), clientDO.Code, formatFileName, (int)Enums.FileType.图片, watermark, (int)Enums.DocumentType.执行上传);

                        }
                        else if (questionType == (int)Enums.QuestionType.单选题)
                        {
                            APOptionsDO option = APQuestionManager.GetOptionDO(questionID, value);
                            if (option != null && option.ID > 0)
                            {
                                APAnswerOptionsDO optionDO = APQuestionManager.GetAnswerOption(answerID, option.ID);
                                if (optionDO == null || optionDO.ID <= 0)
                                {
                                    optionDO = new APAnswerOptionsDO();
                                }
                                optionDO.AnswerID = answerID;
                                optionDO.OptionID = option.ID;
                                //optionDO.OptionText = value;
                                if (optionDO.ID > 0)
                                {
                                    BusinessLogicBase.Default.Update(optionDO);
                                }
                                else
                                {
                                    BusinessLogicBase.Default.Insert(optionDO);
                                }
                            }
                        }
                        else if (questionType == (int)Enums.QuestionType.多选题 || questionType == (int)Enums.QuestionType.是非题)
                        {
                            string[] optionTexts = value.Split(new char[] { '~' }, StringSplitOptions.RemoveEmptyEntries);
                            if (optionTexts != null && optionTexts.Length > 0)
                            {
                                foreach (string optionText in optionTexts)
                                {
                                    APOptionsDO option = APQuestionManager.GetOptionDO(questionID, optionText.Trim());
                                    if (option != null && option.ID > 0)
                                    {
                                        APAnswerOptionsDO optionDO = APQuestionManager.GetAnswerOption(answerID, option.ID);
                                        if (optionDO == null || optionDO.ID <= 0)
                                        {
                                            optionDO = new APAnswerOptionsDO();
                                        }
                                        optionDO.AnswerID = answerID;
                                        optionDO.OptionID = option.ID;
                                        //optionDO.OptionText = value;
                                        if (optionDO.ID > 0)
                                        {
                                            BusinessLogicBase.Default.Update(optionDO);
                                        }
                                        else
                                        {
                                            BusinessLogicBase.Default.Insert(optionDO);
                                        }
                                    }
                                }
                            }
                        }
                    }


                    int counterNum = row["D2_0"].ToString().Trim().ToInt(0);
                    if (counterNum > 0 && counterNum < 20)
                    {
                        for (int k = counterNum + 1; k <= 20; k++)
                        {
                            string questionCode = "E" + k.ToString().PadLeft(2, '0') + "_1";
                            string value = "无";
                            int questionID = APQuestionManager.GetQuestionIDByCode2(questionnaireID, questionCode);
                            int answerID = 0;
                            APAnswersDO answerDO = APQuestionManager.GetAnwserDO(resultID, questionID);
                            if (answerDO == null || answerDO.ID <= 0)
                            {
                                answerDO = new APAnswersDO();
                            }
                            answerID = answerDO.ID;
                            answerDO.ResultID = resultID;
                            answerDO.QuestionID = questionID;
                            answerDO.CreateTime = DateTime.Now;
                            answerDO.Status = (int)Enums.DeleteStatus.正常;
                            answerDO.CreateUserID = WebSiteContext.CurrentUserID;
                            answerDO.TotalScore = 0;
                            if (answerID > 0)
                            {
                                BusinessLogicBase.Default.Update(answerDO);
                            }
                            else
                            {
                                answerID = BusinessLogicBase.Default.Insert(answerDO);
                            }
                            APOptionsDO option = APQuestionManager.GetOptionDO(questionID, value);
                            if (option != null && option.ID > 0)
                            {
                                APAnswerOptionsDO optionDO = APQuestionManager.GetAnswerOption(answerID, option.ID);
                                if (optionDO == null || optionDO.ID <= 0)
                                {
                                    optionDO = new APAnswerOptionsDO();
                                }
                                optionDO.AnswerID = answerID;
                                optionDO.OptionID = option.ID;
                                if (optionDO.ID > 0)
                                {
                                    BusinessLogicBase.Default.Update(optionDO);
                                }
                                else
                                {
                                    BusinessLogicBase.Default.Insert(optionDO);
                                }
                            }
                        }
                    }
                }
            }

            try
            {
                Directory.Delete(diskFolderPath, true);
            }
            catch { }

            StringBuilder message = new StringBuilder();
            List<string> msgList = new List<string>();

            result = "1" + message.ToString();
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

    public void UploadShangquanResultDataByUrl() 
    {
        byte[] byts = new byte[HttpContext.Current.Request.InputStream.Length];
        HttpContext.Current.Request.InputStream.Read(byts, 0, byts.Length);
        string jsonData = System.Text.Encoding.Default.GetString(byts);
        Newtonsoft.Json.Linq.JObject resultObj = (Newtonsoft.Json.Linq.JObject)Newtonsoft.Json.JsonConvert.DeserializeObject(jsonData);
        string downUrl = resultObj["downUrl"].ToString();
        int projectID = resultObj["projectID"].ToString().ToInt(0);
        int questionnaireID = resultObj["questionnaireID"].ToString().ToInt(0);
        DateTime fromDate = resultObj["fromDate"].ToString().ToDateTime(Constants.Date_Min);
        DateTime toDate = resultObj["toDate"].ToString().ToDateTime(Constants.Date_Max);

        string fileName = downUrl.Substring(downUrl.LastIndexOf('/') + 1);
        string folderName = Path.GetFileNameWithoutExtension(fileName);
        string extension = Path.GetExtension(fileName);
        string result = "0";
        string vituralPath = Constants.RelevantTempPath;
        string physicalPath = HttpContext.Current.Server.MapPath(vituralPath);
        string originalName = fileName;
        string name = fileName;
        string diskFolderPath = physicalPath.TrimEnd('\\') + "\\" + folderName + "\\";
        if (Directory.Exists(diskFolderPath) == false)
        {
            Directory.CreateDirectory(diskFolderPath);
        }
        string diskFilePath = diskFolderPath + originalName;
        diskFilePath = CommonFunction.GetNewPathForDuplicates(diskFilePath);
        CommonFunction.DownloadFile(downUrl, diskFilePath);

        try
        {
            DataTable dt = NPOIHelper.ImportExceltoDt(diskFilePath, "Data", 0);
            DataTable dtGPS = NPOIHelper.ImportExceltoDt(diskFilePath, "Geographical", 0);
            if (dt == null || dt.Rows.Count <= 1)
            {
                result = "0没有数据";
                HttpContext.Current.Response.ContentType = "text/plain";
                HttpContext.Current.Response.Write(result);
                return;
            }
            if (dt != null && dt.Columns.Count > 0)
            {
                for (int i = 0; i < dt.Columns.Count; i++)
                {
                    dt.Columns[i].ColumnName = dt.Columns[i].ColumnName.Trim().Replace("#", "_");
                    //处理收银台编号问题
                    //E01_1-2 到 E02_1
                    if (dt.Columns[i].ColumnName.Contains("-"))
                    {
                        string columnName = dt.Columns[i].ColumnName;
                        string currentQuestionCode = columnName.Substring(0, columnName.LastIndexOf('-'));//E01_1
                        string realNum = columnName.Substring(columnName.LastIndexOf('-') + 1);//2
                        if (realNum != "")
                        {
                            string realQuestionCode = "E" + realNum.PadLeft(2, '0');//E02
                            string fixedQuestionCode = currentQuestionCode.Replace("E01", realQuestionCode);
                            dt.Columns[i].ColumnName = fixedQuestionCode;
                        }
                    }
                }
            }

            DirectoryMappingDO dmDO = DocumentManager.GetCurrentDirMappingDO();
            string file_physicalPath = dmDO.PhysicalPath;
            string file_vituralPath = dmDO.VituralPath;
            string fileNameWithoutExtension = Path.GetFileNameWithoutExtension(fileName).Trim();
            if (dt != null && dt.Rows.Count > 0)
            {
                DataTable dtQuestions = APQuestionManager.GetQuestionsTableByQuestionnaireID(questionnaireID);
                //从第2行开始读
                for (int i = 1; i < dt.Rows.Count; i++)
                {
                    DataRow row = dt.Rows[i];
                    string sampleType = row["LX"].ToString();
                    string b1 = row["B1"].ToString();
                    if (sampleType != "正式样本")
                    {
                        continue;
                    }
                    if (b1 == "不支持")
                    {
                        continue;
                    }
                    string id = row["链接标识"].ToString();
                    string versionId = row["版本编号"].ToString();
                    LocateInfo info = GetLngLatByID(id, dtGPS);
                    string watermark = GetWatermarkByID(id, row["开始填答时间"].ToString(), dtGPS);

                    DateTime visitBeginTime = row["开始填答时间"].ToString().ToDateTime(Constants.Date_Min);
                    DateTime visitEndTime = row["结束填答时间"].ToString().ToDateTime(Constants.Date_Max);
                    int timeLength = row["访问时长"].ToString().Replace("秒", "").ToInt(0);//秒为单位
                    timeLength = timeLength / 60;//转化为分钟
                    string clientCode = row["NO"].ToString();//商场编号

                    APClientsDO clientDO = APClientManager.GetClientByPostcode(clientCode, projectID);
                    if (clientDO == null || clientDO.ID < 0)
                    {
                        continue;
                    }
                    APQuestionnaireDeliveryDO deliveryDO = APQuestionnaireManager.GetQuestionnaireDeliveryDO(questionnaireID, clientDO.ID, fromDate, toDate, (int)Enums.UserType.访问员);
                    int deliveryID = deliveryDO.ID;
                    int visitUserID = deliveryDO.AcceptUserID;

                    DataTable dtResult = APResultManager.GetResult(projectID, questionnaireID, clientDO.ID, id);
                    if (dtResult != null && dtResult.Rows.Count > 0)
                    {
                        continue;
                    }

                    APQuestionnaireResultsDO resultDO = new APQuestionnaireResultsDO();
                    resultDO.QuestionnaireID = questionnaireID;
                    resultDO.ClientID = clientDO.ID;
                    resultDO.DeliveryID = deliveryID;
                    resultDO.VisitUserID = visitUserID;
                    resultDO.Status = (int)Enums.QuestionnaireStageStatus.质控审核中;
                    resultDO.VisitUserUploadStatus = (int)Enums.QuestionnaireUploadStatus.已提交审核;
                    resultDO.VisitBeginTime = visitBeginTime;
                    resultDO.VisitEndTime = visitEndTime;
                    resultDO.UploadBeginTime = visitBeginTime;
                    resultDO.UploadEndTime = visitEndTime;
                    resultDO.TimeLength = timeLength;
                    resultDO.FromDate = fromDate;
                    resultDO.ToDate = toDate;
                    resultDO.WeekNum = CommonFunction.GetWeekNum(visitBeginTime);
                    resultDO.ProjectID = projectID;
                    resultDO.OtherPlatformID = id;
                    resultDO.Address = watermark;
                    resultDO.QuestionnaireVersion = versionId;
                    string gpsTip = string.Empty;
                    if (info != null && info.Latitude > 0 && info.Longitude > 0)
                    {
                        LocateInfo bdLocate = MapHelper.wgs84_To_Bd(info.Latitude, info.Longitude);
                        resultDO.LocationX = bdLocate.Longitude;
                        resultDO.LocationY = bdLocate.Latitude;
                        gpsTip = "实际执行的经纬度：" + resultDO.LocationX + "," + resultDO.LocationY;
                    }
                    else
                    {
                        gpsTip = "没有GPS位置信息";
                        resultDO.Status = (int)Enums.QuestionnaireStageStatus.录入中;
                        resultDO.VisitUserUploadStatus = (int)Enums.QuestionnaireUploadStatus.录入完成;
                    }
                    resultDO.Description = gpsTip;

                    int resultID = BusinessLogicBase.Default.Insert(resultDO);

                    string shopName = "商户名称";
                    try
                    {
                        shopName = row["A6"].ToString();//商户名称
                        int questionID = APQuestionManager.GetQuestionIDByCode2(questionnaireID, "A6");
                        if (questionID > 0 && resultDO.LocationX > 0 && resultDO.LocationY > 0)
                        {
                            GPSValication vObj = new GPSValication();
                            vObj.Longitude = resultDO.LocationX;
                            vObj.Latitude = resultDO.LocationY;
                            vObj.questionID = questionID;
                            vObj.resultID = resultID;
                            vObj.questionnaireID = questionnaireID;
                            APQuestionManager.StartGPSThead(vObj);
                        }
                    }
                    catch { }

                    for (int j = 0; j < dtQuestions.Rows.Count; j++)
                    {
                        int questionID = dtQuestions.Rows[j]["ID"].ToString().ToInt(0);
                        string questionCode = dtQuestions.Rows[j]["Code"].ToString();
                        string questionName = dtQuestions.Rows[j]["Title"].ToString();
                        int questionType = dtQuestions.Rows[j]["QuestionType"].ToString().ToInt(0);

                        if (dt.Columns.Contains(questionCode.Trim()) == false)
                        {
                            continue;
                        }
                        //答案为空时，直接跳过
                        string value = row[questionCode].ToString();
                        if (string.IsNullOrEmpty(value))
                        {
                            continue;
                        }

                        int answerID = 0;
                        APAnswersDO answerDO = APQuestionManager.GetAnwserDO(resultID, questionID);
                        if (answerDO == null || answerDO.ID <= 0)
                        {
                            answerDO = new APAnswersDO();
                        }
                        answerID = answerDO.ID;
                        answerDO.ResultID = resultID;
                        answerDO.QuestionID = questionID;
                        answerDO.CreateTime = DateTime.Now;
                        answerDO.Status = (int)Enums.DeleteStatus.正常;
                        answerDO.CreateUserID = WebSiteContext.CurrentUserID;
                        answerDO.TotalScore = 0;
                        if (answerID > 0)
                        {
                            BusinessLogicBase.Default.Update(answerDO);
                        }
                        else
                        {
                            answerID = BusinessLogicBase.Default.Insert(answerDO);
                        }

                        if (questionType == (int)Enums.QuestionType.填空题)
                        {
                            APAnswerOptionsDO optionDO = APQuestionManager.GetAnswerOption(answerID, -1);
                            if (optionDO == null || optionDO.ID <= 0)
                            {
                                optionDO = new APAnswerOptionsDO();
                            }
                            optionDO.AnswerID = answerID;
                            optionDO.OptionID = -1;
                            optionDO.OptionText = value;
                            if (optionDO.ID > 0)
                            {
                                BusinessLogicBase.Default.Update(optionDO);
                            }
                            else
                            {
                                BusinessLogicBase.Default.Insert(optionDO);
                            }
                        }
                        else if (questionType == (int)Enums.QuestionType.上传题)
                        {
                            string imageUrl = value;
                            string signature = imageUrl.Substring(imageUrl.LastIndexOf("&Signature=") + 11);
                            string encodingSignature = HttpUtility.UrlEncode(signature);
                            imageUrl = imageUrl.Replace(signature, encodingSignature);
                            string imageFileName = CommonFunction.GetFileNameInUrl(imageUrl);
                            string tempFilePath = diskFolderPath + imageFileName;
                            CommonFunction.DownloadFile(imageUrl, tempFilePath);

                            string extestion = Path.GetExtension(tempFilePath);
                            //分公司-城市-商圈名称-商场名称-商户名称-指标名称.jpg
                            string formatFileName = APClientManager.GetFormatFileName(clientDO.ID) + "-" + shopName + "-" + questionName + extestion;
                            formatFileName = CommonFunction.FixedSpecialCharsInFileName(formatFileName);
                            SaveResultImageFile(tempFilePath, file_physicalPath, file_vituralPath, projectID, resultID, questionID, answerID,
                                fromDate.ToString("yyyy-MM-dd"), clientDO.Code, formatFileName, (int)Enums.FileType.图片, watermark, (int)Enums.DocumentType.执行上传);

                        }
                        else if (questionType == (int)Enums.QuestionType.单选题)
                        {
                            APOptionsDO option = APQuestionManager.GetOptionDO(questionID, value);
                            if (option != null && option.ID > 0)
                            {
                                APAnswerOptionsDO optionDO = APQuestionManager.GetAnswerOption(answerID, option.ID);
                                if (optionDO == null || optionDO.ID <= 0)
                                {
                                    optionDO = new APAnswerOptionsDO();
                                }
                                optionDO.AnswerID = answerID;
                                optionDO.OptionID = option.ID;
                                //optionDO.OptionText = value;
                                if (optionDO.ID > 0)
                                {
                                    BusinessLogicBase.Default.Update(optionDO);
                                }
                                else
                                {
                                    BusinessLogicBase.Default.Insert(optionDO);
                                }
                            }
                        }
                        else if (questionType == (int)Enums.QuestionType.多选题 || questionType == (int)Enums.QuestionType.是非题)
                        {
                            string[] optionTexts = value.Split(new char[] { '~' }, StringSplitOptions.RemoveEmptyEntries);
                            if (optionTexts != null && optionTexts.Length > 0)
                            {
                                foreach (string optionText in optionTexts)
                                {
                                    APOptionsDO option = APQuestionManager.GetOptionDO(questionID, optionText.Trim());
                                    if (option != null && option.ID > 0)
                                    {
                                        APAnswerOptionsDO optionDO = APQuestionManager.GetAnswerOption(answerID, option.ID);
                                        if (optionDO == null || optionDO.ID <= 0)
                                        {
                                            optionDO = new APAnswerOptionsDO();
                                        }
                                        optionDO.AnswerID = answerID;
                                        optionDO.OptionID = option.ID;
                                        //optionDO.OptionText = value;
                                        if (optionDO.ID > 0)
                                        {
                                            BusinessLogicBase.Default.Update(optionDO);
                                        }
                                        else
                                        {
                                            BusinessLogicBase.Default.Insert(optionDO);
                                        }
                                    }
                                }
                            }
                        }
                    }


                    int counterNum = row["D2_0"].ToString().Trim().ToInt(0);
                    if (counterNum > 0 && counterNum < 15)
                    {
                        for (int k = counterNum + 1; k <= 15; k++)
                        {
                            string questionCode = "E" + k.ToString().PadLeft(2, '0') + "_1";
                            string value = "无";
                            int questionID = APQuestionManager.GetQuestionIDByCode2(questionnaireID, questionCode);
                            int answerID = 0;
                            APAnswersDO answerDO = APQuestionManager.GetAnwserDO(resultID, questionID);
                            if (answerDO == null || answerDO.ID <= 0)
                            {
                                answerDO = new APAnswersDO();
                            }
                            answerID = answerDO.ID;
                            answerDO.ResultID = resultID;
                            answerDO.QuestionID = questionID;
                            answerDO.CreateTime = DateTime.Now;
                            answerDO.Status = (int)Enums.DeleteStatus.正常;
                            answerDO.CreateUserID = WebSiteContext.CurrentUserID;
                            answerDO.TotalScore = 0;
                            if (answerID > 0)
                            {
                                BusinessLogicBase.Default.Update(answerDO);
                            }
                            else
                            {
                                answerID = BusinessLogicBase.Default.Insert(answerDO);
                            }
                            APOptionsDO option = APQuestionManager.GetOptionDO(questionID, value);
                            if (option != null && option.ID > 0)
                            {
                                APAnswerOptionsDO optionDO = APQuestionManager.GetAnswerOption(answerID, option.ID);
                                if (optionDO == null || optionDO.ID <= 0)
                                {
                                    optionDO = new APAnswerOptionsDO();
                                }
                                optionDO.AnswerID = answerID;
                                optionDO.OptionID = option.ID;
                                if (optionDO.ID > 0)
                                {
                                    BusinessLogicBase.Default.Update(optionDO);
                                }
                                else
                                {
                                    BusinessLogicBase.Default.Insert(optionDO);
                                }
                            }
                        }
                    }
                }
            }

            try
            {
                Directory.Delete(diskFolderPath, true);
            }
            catch { }

            StringBuilder message = new StringBuilder();
            List<string> msgList = new List<string>();

            result = "1" + message.ToString();
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

    public void UploadGongjiaoResultDataByUrl_Add()
    {
        byte[] byts = new byte[HttpContext.Current.Request.InputStream.Length];
        HttpContext.Current.Request.InputStream.Read(byts, 0, byts.Length);
        string jsonData = System.Text.Encoding.Default.GetString(byts);
        Newtonsoft.Json.Linq.JObject resultObj = (Newtonsoft.Json.Linq.JObject)Newtonsoft.Json.JsonConvert.DeserializeObject(jsonData);
        string downUrl = resultObj["downUrl"].ToString();
        int projectID = resultObj["projectID"].ToString().ToInt(0);
        int questionnaireID = resultObj["questionnaireID"].ToString().ToInt(0);
        DateTime fromDate = resultObj["fromDate"].ToString().ToDateTime(Constants.Date_Min);
        DateTime toDate = resultObj["toDate"].ToString().ToDateTime(Constants.Date_Max);


        string fileName = downUrl.Substring(downUrl.LastIndexOf('/') + 1);
        string folderName = Path.GetFileNameWithoutExtension(fileName);
        string extension = Path.GetExtension(fileName);
        string result = "0";
        string vituralPath = Constants.RelevantTempPath;
        string physicalPath = HttpContext.Current.Server.MapPath(vituralPath);
        string originalName = fileName;
        string name = fileName;
        string diskFolderPath = physicalPath.TrimEnd('\\') + "\\" + folderName + "\\";
        if (Directory.Exists(diskFolderPath) == false)
        {
            Directory.CreateDirectory(diskFolderPath);
        }
        string diskFilePath = diskFolderPath + originalName;
        diskFilePath = CommonFunction.GetNewPathForDuplicates(diskFilePath);
        CommonFunction.DownloadFile(downUrl, diskFilePath);

        try
        {
            DataTable dt = NPOIHelper.ImportExceltoDt(diskFilePath, "Data", 0);
            DataTable dtGPS = NPOIHelper.ImportExceltoDt(diskFilePath, "Geographical", 0);
            if (dt == null || dt.Rows.Count <= 1)
            {
                result = "0没有数据";
                HttpContext.Current.Response.ContentType = "text/plain";
                HttpContext.Current.Response.Write(result);
                return;
            }
            if (dt != null && dt.Columns.Count > 0)
            {
                for (int i = 0; i < dt.Columns.Count; i++)
                {
                    dt.Columns[i].ColumnName = dt.Columns[i].ColumnName.Trim().Replace("-", "_").Replace("#", "_");
                }
            }

            DirectoryMappingDO dmDO = DocumentManager.GetCurrentDirMappingDO();
            string file_physicalPath = dmDO.PhysicalPath;
            string file_vituralPath = dmDO.VituralPath;
            string fileNameWithoutExtension = Path.GetFileNameWithoutExtension(fileName).Trim();
            if (dt != null && dt.Rows.Count > 0)
            {
                DataTable dtQuestions = APQuestionManager.GetQuestionsTableByQuestionnaireID(questionnaireID);
                //从第2行开始读
                for (int i = 1; i < dt.Rows.Count; i++)
                {
                    DataRow row = dt.Rows[i];
                    string sampleType = row["type"].ToString();
                    if (sampleType != "正式样本")
                    {
                        continue;
                    }
                    string id = row["链接标识"].ToString();
                    string versionId = row["版本编号"].ToString();

                    string photoAddress = row["Q32"].ToString();
                    string photoTime = row["Q33"].ToString();
                    string watermark = photoAddress + " " + photoTime;
                    
                    DateTime visitBeginTime = row["开始填答时间"].ToString().ToDateTime(Constants.Date_Min);
                    DateTime visitEndTime = row["结束填答时间"].ToString().ToDateTime(Constants.Date_Max);
                    int timeLength = row["访问时长"].ToString().Replace("秒", "").ToInt(0);//秒为单位
                    timeLength = timeLength / 60;//转化为分钟
                    string clientCode = row["05"].ToString();//城市编号
                    string lineName = row["A2"].ToString();//公交线路
                    string stationName = row["A3"].ToString();//公交站牌名
                    string licenseNumber = row["D6"].ToString();//公交车牌号


                    if (string.IsNullOrEmpty(licenseNumber))
                    {
                        licenseNumber = stationName;
                    }
                    //提示; 唯一编号存在邮政编码字段中
                    APClientsDO clientDO = APClientManager.GetClientByPostcode(clientCode, projectID);
                    if (clientDO == null || clientDO.ID < 0)
                    {
                        clientDO = APClientManager.GetClientByName(clientCode, projectID, 3);
                        if (clientDO == null || clientDO.ID < 0)
                        {
                            continue;
                        }
                    }

                    APQuestionnaireDeliveryDO deliveryDO = APQuestionnaireManager.GetQuestionnaireDeliveryDO(questionnaireID, clientDO.ID, fromDate, toDate, (int)Enums.UserType.访问员);
                    int deliveryID = deliveryDO.ID;
                    int visitUserID = deliveryDO.AcceptUserID;

                    DataTable dtResult = APResultManager.GetResult(projectID, questionnaireID, clientDO.ID, id);
                    if (dtResult != null && dtResult.Rows.Count > 0)
                    {
                        continue;
                    }

                    APQuestionnaireResultsDO resultDO = new APQuestionnaireResultsDO();
                    resultDO.QuestionnaireID = questionnaireID;
                    resultDO.ClientID = clientDO.ID;
                    resultDO.DeliveryID = deliveryID;
                    resultDO.VisitUserID = visitUserID;
                    resultDO.Status = (int)Enums.QuestionnaireStageStatus.质控审核中;
                    resultDO.VisitUserUploadStatus = (int)Enums.QuestionnaireUploadStatus.已提交审核;
                    resultDO.VisitBeginTime = visitBeginTime;
                    resultDO.VisitEndTime = visitEndTime;
                    resultDO.UploadBeginTime = visitBeginTime;
                    resultDO.UploadEndTime = visitEndTime;
                    resultDO.TimeLength = timeLength;
                    resultDO.FromDate = fromDate;
                    resultDO.ToDate = toDate;
                    resultDO.WeekNum = CommonFunction.GetWeekNum(visitBeginTime);
                    resultDO.ProjectID = projectID;
                    resultDO.OtherPlatformID = id;
                    resultDO.Address = watermark;
                    resultDO.QuestionnaireVersion = versionId;
                   
                    resultDO.Description = "后补样本";

                    int resultID = BusinessLogicBase.Default.Insert(resultDO);

                    for (int j = 0; j < dtQuestions.Rows.Count; j++)
                    {
                        int questionID = dtQuestions.Rows[j]["ID"].ToString().ToInt(0);
                        string questionCode = dtQuestions.Rows[j]["Code"].ToString();
                        string questionName = dtQuestions.Rows[j]["Title"].ToString();
                        int questionType = dtQuestions.Rows[j]["QuestionType"].ToString().ToInt(0);

                        if (dt.Columns.Contains(questionCode.Trim()) == false)
                        {
                            continue;
                        }
                        //答案为空时，直接跳过
                        string value = row[questionCode].ToString();
                        if (string.IsNullOrEmpty(value))
                        {
                            continue;
                        }
                        int answerID = 0;
                        APAnswersDO answerDO = APQuestionManager.GetAnwserDO(resultID, questionID);
                        if (answerDO == null || answerDO.ID <= 0)
                        {
                            answerDO = new APAnswersDO();
                        }
                        answerID = answerDO.ID;
                        answerDO.ResultID = resultID;
                        answerDO.QuestionID = questionID;
                        answerDO.CreateTime = DateTime.Now;
                        answerDO.Status = (int)Enums.DeleteStatus.正常;
                        answerDO.CreateUserID = WebSiteContext.CurrentUserID;
                        answerDO.TotalScore = 0;
                        if (answerID > 0)
                        {
                            BusinessLogicBase.Default.Update(answerDO);
                        }
                        else
                        {
                            answerID = BusinessLogicBase.Default.Insert(answerDO);
                        }


                        if (questionType == (int)Enums.QuestionType.填空题)
                        {
                            APAnswerOptionsDO optionDO = APQuestionManager.GetAnswerOption(answerID, -1);
                            if (optionDO == null || optionDO.ID <= 0)
                            {
                                optionDO = new APAnswerOptionsDO();
                            }
                            optionDO.AnswerID = answerID;
                            optionDO.OptionID = -1;
                            optionDO.OptionText = value;
                            if (optionDO.ID > 0)
                            {
                                BusinessLogicBase.Default.Update(optionDO);
                            }
                            else
                            {
                                BusinessLogicBase.Default.Insert(optionDO);
                            }
                        }
                        else if (questionType == (int)Enums.QuestionType.上传题)
                        {
                            string imageUrl = value;
                            string signature = imageUrl.Substring(imageUrl.LastIndexOf("&Signature=") + 11);
                            string encodingSignature = HttpUtility.UrlEncode(signature);
                            imageUrl = imageUrl.Replace(signature, encodingSignature);
                            string imageFileName = CommonFunction.GetFileNameInUrl(imageUrl);
                            string tempFilePath = diskFolderPath + imageFileName;
                            CommonFunction.DownloadFile(imageUrl, tempFilePath);

                            string extestion = Path.GetExtension(tempFilePath);
                            //分公司-城市-线路-站台名称-指标名称.jpg
                            string formatFileName = APClientManager.GetFormatFileName(clientDO.ID) + "-" + lineName + "-" + licenseNumber + "-" + questionName + extestion;
                            formatFileName = CommonFunction.FixedSpecialCharsInFileName(formatFileName);
                            SaveResultImageFile(tempFilePath, file_physicalPath, file_vituralPath, projectID, resultID, questionID, answerID,
                                fromDate.ToString("yyyy-MM-dd"), clientDO.Code, formatFileName, (int)Enums.FileType.图片, watermark, (int)Enums.DocumentType.执行上传);

                        }
                        else if (questionType == (int)Enums.QuestionType.单选题)
                        {
                            APOptionsDO option = APQuestionManager.GetOptionDO(questionID, value);
                            if (option != null && option.ID > 0)
                            {
                                APAnswerOptionsDO optionDO = APQuestionManager.GetAnswerOption(answerID, option.ID);
                                if (optionDO == null || optionDO.ID <= 0)
                                {
                                    optionDO = new APAnswerOptionsDO();
                                }
                                optionDO.AnswerID = answerID;
                                optionDO.OptionID = option.ID;
                                if (optionDO.ID > 0)
                                {
                                    BusinessLogicBase.Default.Update(optionDO);
                                }
                                else
                                {
                                    BusinessLogicBase.Default.Insert(optionDO);
                                }
                            }
                        }
                        else if (questionType == (int)Enums.QuestionType.多选题 || questionType == (int)Enums.QuestionType.是非题)
                        {
                            string[] optionTexts = value.Split(new char[] { '~' }, StringSplitOptions.RemoveEmptyEntries);
                            if (optionTexts != null && optionTexts.Length > 0)
                            {
                                foreach (string optionText in optionTexts)
                                {
                                    APOptionsDO option = APQuestionManager.GetOptionDO(questionID, optionText.Trim());
                                    if (option != null && option.ID > 0)
                                    {
                                        APAnswerOptionsDO optionDO = APQuestionManager.GetAnswerOption(answerID, option.ID);
                                        if (optionDO == null || optionDO.ID <= 0)
                                        {
                                            optionDO = new APAnswerOptionsDO();
                                        }
                                        optionDO.AnswerID = answerID;
                                        optionDO.OptionID = option.ID;
                                        if (optionDO.ID > 0)
                                        {
                                            BusinessLogicBase.Default.Update(optionDO);
                                        }
                                        else
                                        {
                                            BusinessLogicBase.Default.Insert(optionDO);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            try
            {
                Directory.Delete(diskFolderPath, true);
            }
            catch { }

            StringBuilder message = new StringBuilder();
            List<string> msgList = new List<string>();

            result = "1" + message.ToString();
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
   
    public void UploadGongjiaoResultDataByUrl()
    {
        byte[] byts = new byte[HttpContext.Current.Request.InputStream.Length];
        HttpContext.Current.Request.InputStream.Read(byts, 0, byts.Length);
        string jsonData = System.Text.Encoding.Default.GetString(byts);
        Newtonsoft.Json.Linq.JObject resultObj = (Newtonsoft.Json.Linq.JObject)Newtonsoft.Json.JsonConvert.DeserializeObject(jsonData);
        string downUrl = resultObj["downUrl"].ToString();
        int projectID = resultObj["projectID"].ToString().ToInt(0);
        int questionnaireID = resultObj["questionnaireID"].ToString().ToInt(0);
        DateTime fromDate = resultObj["fromDate"].ToString().ToDateTime(Constants.Date_Min);
        DateTime toDate = resultObj["toDate"].ToString().ToDateTime(Constants.Date_Max);


        string fileName = downUrl.Substring(downUrl.LastIndexOf('/') + 1);
        string folderName = Path.GetFileNameWithoutExtension(fileName);
        string extension = Path.GetExtension(fileName);
        string result = "0";
        string vituralPath = Constants.RelevantTempPath;
        string physicalPath = HttpContext.Current.Server.MapPath(vituralPath);
        string originalName = fileName;
        string name = fileName;
        string diskFolderPath = physicalPath.TrimEnd('\\') + "\\" + folderName + "\\";
        if (Directory.Exists(diskFolderPath) == false)
        {
            Directory.CreateDirectory(diskFolderPath);
        }
        string diskFilePath = diskFolderPath + originalName;
        diskFilePath = CommonFunction.GetNewPathForDuplicates(diskFilePath);
        CommonFunction.DownloadFile(downUrl, diskFilePath);
        
        try
        {
            DataTable dt = NPOIHelper.ImportExceltoDt(diskFilePath, "Data", 0);
            DataTable dtGPS = NPOIHelper.ImportExceltoDt(diskFilePath, "Geographical", 0);
            if (dt == null || dt.Rows.Count <= 1)
            {
                result = "0没有数据";
                HttpContext.Current.Response.ContentType = "text/plain";
                HttpContext.Current.Response.Write(result);
                return;
            }
            if (dt != null && dt.Columns.Count > 0)
            {
                for (int i = 0; i < dt.Columns.Count; i++)
                {
                    dt.Columns[i].ColumnName = dt.Columns[i].ColumnName.Trim().Replace("-", "_").Replace("#", "_");
                }
            }

            DirectoryMappingDO dmDO = DocumentManager.GetCurrentDirMappingDO();
            string file_physicalPath = dmDO.PhysicalPath;
            string file_vituralPath = dmDO.VituralPath;
            string fileNameWithoutExtension = Path.GetFileNameWithoutExtension(fileName).Trim();
            if (dt != null && dt.Rows.Count > 0)
            {
                DataTable dtQuestions = APQuestionManager.GetQuestionsTableByQuestionnaireID(questionnaireID);
                //从第2行开始读
                for (int i = 1; i < dt.Rows.Count; i++)
                {
                    DataRow row = dt.Rows[i];
                    string sampleType = row["type"].ToString();
                    if (sampleType != "正式样本")
                    {
                        continue;
                    }
                    string id = row["链接标识"].ToString();
                    string versionId = row["版本编号"].ToString();
                    LocateInfo info = GetLngLatByID(id, dtGPS);
                    string watermark = GetWatermarkByID(id, row["开始填答时间"].ToString(), dtGPS);
                    DateTime visitBeginTime = row["开始填答时间"].ToString().ToDateTime(Constants.Date_Min);
                    DateTime visitEndTime = row["结束填答时间"].ToString().ToDateTime(Constants.Date_Max);
                    int timeLength = row["访问时长"].ToString().Replace("秒", "").ToInt(0);//秒为单位
                    timeLength = timeLength / 60;//转化为分钟
                    string clientCode = row["04"].ToString();//城市编号
                    string lineName = row["A2"].ToString();//公交线路
                    string stationName = row["A3"].ToString();//公交站牌名
                    string licenseNumber = row["D6"].ToString();//公交车牌号
                    

                    if (string.IsNullOrEmpty(licenseNumber))
                    {
                        licenseNumber = stationName;
                    }
                    //提示; 唯一编号存在邮政编码字段中
                    APClientsDO clientDO = APClientManager.GetClientByPostcode(clientCode, projectID);
                    if (clientDO == null || clientDO.ID < 0)
                    {
                        clientDO = APClientManager.GetClientByName(clientCode, projectID, 3);
                        if (clientDO == null || clientDO.ID < 0)
                        {
                            continue;
                        }
                    }

                    APQuestionnaireDeliveryDO deliveryDO = APQuestionnaireManager.GetQuestionnaireDeliveryDO(questionnaireID, clientDO.ID, fromDate, toDate, (int)Enums.UserType.访问员);
                    int deliveryID = deliveryDO.ID;
                    int visitUserID = deliveryDO.AcceptUserID;

                    DataTable dtResult = APResultManager.GetResult(projectID, questionnaireID, clientDO.ID, id);
                    if (dtResult != null && dtResult.Rows.Count > 0)
                    {
                        continue;
                    }

                    APQuestionnaireResultsDO resultDO = new APQuestionnaireResultsDO();
                    resultDO.QuestionnaireID = questionnaireID;
                    resultDO.ClientID = clientDO.ID;
                    resultDO.DeliveryID = deliveryID;
                    resultDO.VisitUserID = visitUserID;
                    resultDO.Status = (int)Enums.QuestionnaireStageStatus.质控审核中;
                    resultDO.VisitUserUploadStatus = (int)Enums.QuestionnaireUploadStatus.已提交审核;
                    resultDO.VisitBeginTime = visitBeginTime;
                    resultDO.VisitEndTime = visitEndTime;
                    resultDO.UploadBeginTime = visitBeginTime;
                    resultDO.UploadEndTime = visitEndTime;
                    resultDO.TimeLength = timeLength;
                    resultDO.FromDate = fromDate;
                    resultDO.ToDate = toDate;
                    resultDO.WeekNum = CommonFunction.GetWeekNum(visitBeginTime);
                    resultDO.ProjectID = projectID;
                    resultDO.OtherPlatformID = id;
                    resultDO.Address = watermark;
                    resultDO.QuestionnaireVersion = versionId;
                    string gpsTip = string.Empty;

                    if (info != null && info.Latitude > 0 && info.Longitude > 0)
                    {
                        LocateInfo bdLocate = MapHelper.wgs84_To_Bd(info.Latitude, info.Longitude);
                        resultDO.LocationX = bdLocate.Longitude;
                        resultDO.LocationY = bdLocate.Latitude;
                        gpsTip = "实际执行的经纬度：" + resultDO.LocationX + "," + resultDO.LocationY;
                    }
                    else
                    {
                        gpsTip = "没有GPS位置信息";
                        resultDO.Status = (int)Enums.QuestionnaireStageStatus.录入中;
                        resultDO.VisitUserUploadStatus = (int)Enums.QuestionnaireUploadStatus.录入完成;
                    }
                    resultDO.Description = gpsTip;

                    int resultID = BusinessLogicBase.Default.Insert(resultDO);

                    //List<Process> imageResetEvents = new List<Process>();
                    
                    for (int j = 0; j < dtQuestions.Rows.Count; j++)
                    {
                        int questionID = dtQuestions.Rows[j]["ID"].ToString().ToInt(0);
                        string questionCode = dtQuestions.Rows[j]["Code"].ToString();
                        string questionName = dtQuestions.Rows[j]["Title"].ToString();
                        int questionType = dtQuestions.Rows[j]["QuestionType"].ToString().ToInt(0);

                        if (dt.Columns.Contains(questionCode.Trim()) == false)
                        {
                            continue;
                        }
                        //答案为空时，直接跳过
                        string value = row[questionCode].ToString();
                        if (string.IsNullOrEmpty(value))
                        {
                            continue;
                        }
                        int answerID = 0;
                        APAnswersDO answerDO = APQuestionManager.GetAnwserDO(resultID, questionID);
                        if (answerDO == null || answerDO.ID <= 0)
                        {
                            answerDO = new APAnswersDO();
                        }
                        answerID = answerDO.ID;
                        answerDO.ResultID = resultID;
                        answerDO.QuestionID = questionID;
                        answerDO.CreateTime = DateTime.Now;
                        answerDO.Status = (int)Enums.DeleteStatus.正常;
                        answerDO.CreateUserID = WebSiteContext.CurrentUserID;
                        answerDO.TotalScore = 0;
                        if (answerID > 0)
                        {
                            BusinessLogicBase.Default.Update(answerDO);
                        }
                        else
                        {
                            answerID = BusinessLogicBase.Default.Insert(answerDO);
                        }


                        if (questionType == (int)Enums.QuestionType.填空题)
                        {
                            APAnswerOptionsDO optionDO = APQuestionManager.GetAnswerOption(answerID, -1);
                            if (optionDO == null || optionDO.ID <= 0)
                            {
                                optionDO = new APAnswerOptionsDO();
                            }
                            optionDO.AnswerID = answerID;
                            optionDO.OptionID = -1;
                            optionDO.OptionText = value;
                            if (optionDO.ID > 0)
                            {
                                BusinessLogicBase.Default.Update(optionDO);
                            }
                            else
                            {
                                BusinessLogicBase.Default.Insert(optionDO);
                            }
                        }
                        else if (questionType == (int)Enums.QuestionType.上传题)
                        {
                            string imageUrl = value;
                            string signature = imageUrl.Substring(imageUrl.LastIndexOf("&Signature=") + 11);
                            string encodingSignature = HttpUtility.UrlEncode(signature);
                            imageUrl = imageUrl.Replace(signature, encodingSignature);
                            string imageFileName = CommonFunction.GetFileNameInUrl(imageUrl);
                            string tempFilePath = diskFolderPath + imageFileName;
                            CommonFunction.DownloadFile(imageUrl, tempFilePath);

                            string extestion = Path.GetExtension(tempFilePath);
                            //分公司-城市-线路-站台名称-指标名称.jpg
                            string formatFileName = APClientManager.GetFormatFileName(clientDO.ID) + "-" + lineName + "-" + licenseNumber + "-" + questionName + extestion;
                            formatFileName = CommonFunction.FixedSpecialCharsInFileName(formatFileName);
                            SaveResultImageFile(tempFilePath, file_physicalPath, file_vituralPath, projectID, resultID, questionID, answerID,
                                fromDate.ToString("yyyy-MM-dd"), clientDO.Code, formatFileName, (int)Enums.FileType.图片, watermark, (int)Enums.DocumentType.执行上传);

                        }
                        else if (questionType == (int)Enums.QuestionType.单选题)
                        {
                            APOptionsDO option = APQuestionManager.GetOptionDO(questionID, value);
                            if (option != null && option.ID > 0)
                            {
                                APAnswerOptionsDO optionDO = APQuestionManager.GetAnswerOption(answerID, option.ID);
                                if (optionDO == null || optionDO.ID <= 0)
                                {
                                    optionDO = new APAnswerOptionsDO();
                                }
                                optionDO.AnswerID = answerID;
                                optionDO.OptionID = option.ID;
                                if (optionDO.ID > 0)
                                {
                                    BusinessLogicBase.Default.Update(optionDO);
                                }
                                else
                                {
                                    BusinessLogicBase.Default.Insert(optionDO);
                                }
                            }
                        }
                        else if (questionType == (int)Enums.QuestionType.多选题 || questionType == (int)Enums.QuestionType.是非题)
                        {
                            string[] optionTexts = value.Split(new char[] { '~' }, StringSplitOptions.RemoveEmptyEntries);
                            if (optionTexts != null && optionTexts.Length > 0)
                            {
                                foreach (string optionText in optionTexts)
                                {
                                    APOptionsDO option = APQuestionManager.GetOptionDO(questionID, optionText.Trim());
                                    if (option != null && option.ID > 0)
                                    {
                                        APAnswerOptionsDO optionDO = APQuestionManager.GetAnswerOption(answerID, option.ID);
                                        if (optionDO == null || optionDO.ID <= 0)
                                        {
                                            optionDO = new APAnswerOptionsDO();
                                        }
                                        optionDO.AnswerID = answerID;
                                        optionDO.OptionID = option.ID;
                                        if (optionDO.ID > 0)
                                        {
                                            BusinessLogicBase.Default.Update(optionDO);
                                        }
                                        else
                                        {
                                            BusinessLogicBase.Default.Insert(optionDO);
                                        }
                                    }
                                }
                            }
                        }
                    }
                    //等待所有图片下载子线程结束后再执行下一个样本
                    //CommonFunction.WaitForProcess("ReadImageFromICTR", 20);
                    //foreach (Process item in imageResetEvents)
                    //{
                    //    item.WaitForExit();
                    //}
                }
            }

            try
            {
                Directory.Delete(diskFolderPath, true);
            }
            catch { }

            StringBuilder message = new StringBuilder();
            List<string> msgList = new List<string>();

            result = "1" + message.ToString();
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

    private int SaveResultImageFile(string tempfilePath, string physicalPath, string vituralPath, int projectID, int resultID, int questionID,
        int answerID, string fromDate, string clientCode, string formatFileName, int fileType, string watermark, int typeID)
    {
        string diskFolderPath = physicalPath.TrimEnd('\\') + "\\" + projectID + "\\" + fromDate + "\\" + clientCode + "\\" + fileType + "\\";
        if (Directory.Exists(diskFolderPath) == false)
        {
            Directory.CreateDirectory(diskFolderPath);
        }
        string diskFilePath = diskFolderPath + formatFileName;
        diskFilePath = CommonFunction.GetNewPathForDuplicates(diskFilePath);
        File.Copy(tempfilePath, diskFilePath);
        FileInfo file = new FileInfo(diskFilePath);
        long fileLength = file.Length;

        string webDirPath = vituralPath.TrimEnd('/') + "/" + projectID + "/" + fromDate + "/" + clientCode + "/" + fileType + "/";
        string fixedFileName = Path.GetFileName(diskFilePath);
        string webFilePath = webDirPath + fixedFileName;

        string thumbRelevantPath = string.Empty;
        string thumbPhysicalPath = string.Empty;
        string timeLength = string.Empty;
        string extension = Path.GetExtension(diskFilePath).ToLower();
        if (fileType == (int)Enums.FileType.图片)
        {
            if (fileLength > 0)
            {
                if (string.IsNullOrEmpty(watermark) == false)
                {
                    WebCommon.AddImageSignText(diskFilePath, diskFilePath, watermark, 7, 100, 12);
                }

                thumbRelevantPath = CommonFunction.GetThumbPathForImageFile(webFilePath);
                thumbPhysicalPath = CommonFunction.GetThumbPathForImageFile(diskFilePath);
                WebCommon.MakeThumbnail(diskFilePath, thumbPhysicalPath, Constants.ThumbnailWidth, Constants.ThumbnailHeight, "");
            }
        }
        else if (fileType == (int)Enums.FileType.录音)
        {
            string videoCode = string.Empty;
            string audioCode = string.Empty;
            WebCommon.GetVideoInfo(diskFilePath, ref timeLength, ref videoCode, ref audioCode);
            if (extension != ".mp3" || audioCode != "mp3")
            {
                string fixedDiskFilePath = WebCommon.GetAudioConvertedPath(diskFilePath);
                if (string.IsNullOrEmpty(fixedDiskFilePath) == false)
                {
                    File.Delete(diskFilePath);
                    diskFilePath = Path.ChangeExtension(diskFilePath, "mp3");
                    diskFilePath = CommonFunction.GetNewPathForDuplicates(diskFilePath);
                    fixedFileName = Path.GetFileName(diskFilePath);
                    webFilePath = webDirPath + fixedFileName;
                    File.Move(fixedDiskFilePath, diskFilePath);
                }

            }
        }
        if (fileType == (int)Enums.FileType.录像)
        {
            //视频缩略图
            thumbPhysicalPath = WebCommon.CatchVideoCoverImage(diskFilePath);
            string fixedThumbFileName = Path.GetFileName(thumbPhysicalPath);
            thumbRelevantPath = webDirPath + fixedThumbFileName;

            string videoCode = string.Empty;
            string audioCode = string.Empty;
            WebCommon.GetVideoInfo(diskFilePath, ref timeLength, ref videoCode, ref audioCode);
            if (extension != ".mp4" || videoCode != "h264" || audioCode != "aac")
            {
                string fixedDiskFilePath = WebCommon.GetVideoConvertedPath(diskFilePath);
                if (string.IsNullOrEmpty(fixedDiskFilePath) == false)
                {
                    File.Delete(diskFilePath);
                    diskFilePath = Path.ChangeExtension(diskFilePath, "mp4");
                    diskFilePath = CommonFunction.GetNewPathForDuplicates(diskFilePath);
                    fixedFileName = Path.GetFileName(diskFilePath);
                    webFilePath = webDirPath + fixedFileName;
                    File.Move(fixedDiskFilePath, diskFilePath);
                }
            }
        }

        string tempCode = resultID * 100 + " " + questionID * 100;

        DocumentFilesDO doc = new DocumentFilesDO();
        doc.FileName = formatFileName;
        doc.OriginalFileName = formatFileName;
        doc.TempCode = tempCode;
        doc.RelatedID = answerID;
        doc.ResultID = resultID;
        doc.TypeID = typeID;
        doc.FileSize = fileLength;
        doc.TimeLength = timeLength;
        doc.Status = (int)Enums.DocumentStatus.正常;
        doc.RelevantPath = webFilePath;
        doc.PhysicalPath = diskFilePath;
        doc.ThumbRelevantPath = thumbRelevantPath;
        doc.FileType = fileType;
        doc.UserID = WebSiteContext.CurrentUserID;
        doc.InputDate = DateTime.Now;
        int docid = BusinessLogicBase.Default.Insert(doc);
        return docid;
    }
    

    public void GetShanghuMoreImages() 
    {
        int clientID = HttpContext.Current.Request.QueryString["clientID"].ToInt(0);
        APClientsDO clientDO = APClientManager.GetClientDOByID(clientID);
        APClientsDO parentDO = APClientManager.GetClientDOByID(clientDO.ParentID);
        string relevantRoot = "../MoreImages";
        string rootPath = HttpContext.Current.Server.MapPath("~/MoreImages");
        string cityName = parentDO.Name;
        string postCode = clientDO.Postcode;
        string[] codes = postCode.Split('_');
        DataTable dt = new DataTable();
        dt.Columns.Add("Name");
        dt.Columns.Add("Url");
        if (codes != null && codes.Length == 4) 
        {
            string shopCode = codes[2];
            string endpointCode = codes[3];
            string relevantFolderPath = relevantRoot + "/" + cityName + "/" + shopCode;
            string folderPath = rootPath.TrimEnd('\\') + "\\" + cityName + "\\" + shopCode;
            if (Directory.Exists(folderPath)) 
            {
                string[] files = Directory.GetFiles(folderPath);
                if (files != null && files.Length > 0) 
                {
                    foreach (string filePath in files) 
                    {
                        string fileName = Path.GetFileName(filePath);
                        if (fileName.Contains(endpointCode)) 
                        {
                            string fileUrl = relevantFolderPath + "/" + fileName;
                            dt.Rows.Add(fileName, fileUrl);
                        }
                    }
                }
            }
        }

        string jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }


    private LocateInfo GetLngLatByID(string id, DataTable dtGPS)
    {
        LocateInfo info = new LocateInfo();
        DataRow[] rows = dtGPS.Select("样本标识='" + id + "'");
        if (rows != null && rows.Length > 0)
        {
            double lng = rows[0]["经度"].ToString().ToDouble(0);
            double lat = rows[0]["纬度"].ToString().ToDouble(0);
            info = new LocateInfo(lng, lat);
        }
        return info;
    }

    private string GetWatermarkByID(string id, string time, DataTable dtGPS)
    {
        string watermark = string.Empty;
        DataRow[] rows = dtGPS.Select("样本标识='" + id + "'");
        if (rows != null && rows.Length > 0)
        {
            string country = rows[0]["国家"].ToString();
            string province = rows[0]["省份"].ToString();
            string city = rows[0]["城市"].ToString();
            string district = rows[0]["区县"].ToString();
            string street = rows[0]["街道"].ToString();
            string door = rows[0]["街道门牌号"].ToString();

            string address = country + province + city + district + street + door;

            watermark = address + " " + time;
        }
        return watermark;
    }

    private int SaveResultImageFile(string tempfilePath, string physicalPath, string vituralPath, int projectID, int resultID, int questionID,
        int answerID, string fromDate, string clientCode, string formatFileName, int fileType, string watermark, int typeID, int userID)
    {
        string diskFolderPath = physicalPath.TrimEnd('\\') + "\\" + projectID + "\\" + fromDate + "\\" + clientCode + "\\" + fileType + "\\";
        if (Directory.Exists(diskFolderPath) == false)
        {
            Directory.CreateDirectory(diskFolderPath);
        }
        string diskFilePath = diskFolderPath + formatFileName;
        diskFilePath = CommonFunction.GetNewPathForDuplicates(diskFilePath);
        File.Copy(tempfilePath, diskFilePath);
        FileInfo file = new FileInfo(diskFilePath);
        long fileLength = file.Length;

        string webDirPath = vituralPath.TrimEnd('/') + "/" + projectID + "/" + fromDate + "/" + clientCode + "/" + fileType + "/";
        string fixedFileName = Path.GetFileName(diskFilePath);
        string webFilePath = webDirPath + fixedFileName;

        string thumbRelevantPath = string.Empty;
        string thumbPhysicalPath = string.Empty;
        string timeLength = string.Empty;
        string extension = Path.GetExtension(diskFilePath).ToLower();
        if (fileType == (int)Enums.FileType.图片)
        {
            if (fileLength > 0)
            {
                if (string.IsNullOrEmpty(watermark) == false)
                {
                    WebCommon.AddImageSignText(diskFilePath, diskFilePath, watermark, 7, 100, 12);
                }

                thumbRelevantPath = CommonFunction.GetThumbPathForImageFile(webFilePath);
                thumbPhysicalPath = CommonFunction.GetThumbPathForImageFile(diskFilePath);
                WebCommon.MakeThumbnail(diskFilePath, thumbPhysicalPath, Constants.ThumbnailWidth, Constants.ThumbnailHeight, "");
            }
        }
        else if (fileType == (int)Enums.FileType.录音)
        {
            string videoCode = string.Empty;
            string audioCode = string.Empty;
            WebCommon.GetVideoInfo(diskFilePath, ref timeLength, ref videoCode, ref audioCode);
            if (extension != ".mp3" || audioCode != "mp3")
            {
                string fixedDiskFilePath = WebCommon.GetAudioConvertedPath(diskFilePath);
                if (string.IsNullOrEmpty(fixedDiskFilePath) == false)
                {
                    File.Delete(diskFilePath);
                    diskFilePath = Path.ChangeExtension(diskFilePath, "mp3");
                    diskFilePath = CommonFunction.GetNewPathForDuplicates(diskFilePath);
                    fixedFileName = Path.GetFileName(diskFilePath);
                    webFilePath = webDirPath + fixedFileName;
                    File.Move(fixedDiskFilePath, diskFilePath);
                }

            }
        }
        if (fileType == (int)Enums.FileType.录像)
        {
            //视频缩略图
            thumbPhysicalPath = WebCommon.CatchVideoCoverImage(diskFilePath);
            string fixedThumbFileName = Path.GetFileName(thumbPhysicalPath);
            thumbRelevantPath = webDirPath + fixedThumbFileName;

            string videoCode = string.Empty;
            string audioCode = string.Empty;
            WebCommon.GetVideoInfo(diskFilePath, ref timeLength, ref videoCode, ref audioCode);
            if (extension != ".mp4" || videoCode != "h264" || audioCode != "aac")
            {
                string fixedDiskFilePath = WebCommon.GetVideoConvertedPath(diskFilePath);
                if (string.IsNullOrEmpty(fixedDiskFilePath) == false)
                {
                    File.Delete(diskFilePath);
                    diskFilePath = Path.ChangeExtension(diskFilePath, "mp4");
                    diskFilePath = CommonFunction.GetNewPathForDuplicates(diskFilePath);
                    fixedFileName = Path.GetFileName(diskFilePath);
                    webFilePath = webDirPath + fixedFileName;
                    File.Move(fixedDiskFilePath, diskFilePath);
                }
            }
        }

        string tempCode = resultID * 100 + " " + questionID * 100;

        DocumentFilesDO doc = new DocumentFilesDO();
        doc.FileName = formatFileName;
        doc.OriginalFileName = formatFileName;
        doc.TempCode = tempCode;
        doc.RelatedID = answerID;
        doc.ResultID = resultID;
        doc.TypeID = typeID;
        doc.FileSize = fileLength;
        doc.TimeLength = timeLength;
        doc.Status = (int)Enums.DocumentStatus.正常;
        doc.RelevantPath = webFilePath;
        doc.PhysicalPath = diskFilePath;
        doc.ThumbRelevantPath = thumbRelevantPath;
        doc.FileType = fileType;
        doc.UserID = userID;
        doc.InputDate = DateTime.Now;
        int docid = BusinessLogicBase.Default.Insert(doc);
        return docid;
    }

    public bool IsReusable {
        get {
            return false;
        }
    }

}