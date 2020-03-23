using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using APLibrary.DataObject;
using System.Data.SqlClient;
using System.Data;
using System.Threading;

namespace APLibrary
{
    public class APQuestionManager : BusinessLogicBase
    {
        private static BusinessLogicBase baseLogic = new BusinessLogicBase();

        public static string GetQuestionPath(int questionID)
        {
            string path = string.Empty;
            string spName = "GetQuestionPath";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@QuestionID", questionID);
            DataTable dt = BusinessLogicBase.Default.ExceuteStoredProcedure(spName, pars);
            if (dt != null && dt.Rows.Count > 0)
            {
                path = dt.Rows[0][0].ToString();
            }
            return path;
        }

        public static decimal CalculateQuestionScore(int questionID, int selectedOptionID)
        {
            int[] selectedOptions = { selectedOptionID };
            return CalculateQuestionScore(questionID, selectedOptions);
        }

        public static decimal CalculateQuestionScore(int questionID, int[] selectedOptions)
        {
            decimal score = 0m;
            APQuestionsDO questionDO = APQuestionnaireManager.GetQuestionDOByID(questionID);
            int questionTypeID = questionDO.QuestionType;
            int countType = questionDO.CountType;
            if (countType == (int)Enums.QuestionCountType.不得分不扣分)
            {
                return score;
            }

            bool success = false;
            int matchedNumber = 0;
            DataTable dtOptions = APQuestionnaireManager.GetQuestionCorrectOptions(questionID);
            if (dtOptions != null && dtOptions.Rows.Count > 0 && dtOptions.Rows.Count == selectedOptions.Length)
            {
                foreach (DataRow dr in dtOptions.Rows)
                {
                    int optionID = 0;
                    int.TryParse(dr["ID"].ToString(), out optionID);
                    if (selectedOptions.Contains(optionID))
                    {
                        matchedNumber++;
                    }
                }
                if (matchedNumber == selectedOptions.Length)
                {
                    success = true;
                }
            }


            if (countType == (int)Enums.QuestionCountType.正确得分 || countType == (int)Enums.QuestionCountType.全部正确得分)
            {
                if (success == true)
                {
                    score = questionDO.TotalScore;
                }
            }
            else if (countType == (int)Enums.QuestionCountType.错误扣分)
            {
                if (success == false)
                {
                    score = -Math.Abs(questionDO.TotalScore);
                }
            }
            else if (countType == (int)Enums.QuestionCountType.选项分总和)
            {
                decimal totalScore = questionDO.TotalScore;
                foreach (int selectID in selectedOptions)
                {
                    APOptionsDO optionDO = APQuestionManager.GetOptionDO(selectID);
                    if (optionDO.BCorrectOption == true)
                    {
                        score += optionDO.Score;
                    }
                }

                if (totalScore < score)
                {
                    score = totalScore;
                }
                if (score < 0)
                {
                    score = 0;
                }
            }
            else if (countType == (int)Enums.QuestionCountType.选项叠加扣分)
            {
                if (success == false)
                {
                    score = questionDO.TotalScore;
                    foreach (int selectID in selectedOptions)
                    {
                        APOptionsDO optionDO = APQuestionManager.GetOptionDO(selectID);
                        if (optionDO.BCorrectOption == false)
                        {
                            score -= Math.Abs(optionDO.Score);
                        }
                    }

                    if (score < 0)
                    {
                        score = 0;
                    }
                }
                else
                {
                    score = questionDO.TotalScore;
                }
            }
            else if (countType == (int)Enums.QuestionCountType.等于选项分)
            {
                if (selectedOptions.Length > 0)
                {
                    int selectID = selectedOptions[0];
                    APOptionsDO optionDO = APQuestionManager.GetOptionDO(selectID);
                    score = optionDO.Score;
                }
            }
            return score;
        }

        public static void ClearAnswerOptions(int answerID)
        {
            string sql = @"delete from APAnswerOptions where answerID=@answerID";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@answerID", answerID);
            BusinessLogicBase.Default.Execute(sql, pars);
        }

        public static void UpdateAttachmentRelatedIDByTempCode(int relatedID, string tempCode) 
        {
            string sql = @"update DocumentFiles set RelatedID=@RelatedID where TempCode=@TempCode";
            SqlParameter[] pars = new SqlParameter[2];
            pars[0] = new SqlParameter("@RelatedID", relatedID);
            pars[1] = new SqlParameter("@TempCode", tempCode);
            BusinessLogicBase.Default.Execute(sql, pars);
        }

        public static int GetFileNumberByTempCode(string tempCode)
        {
            int number = 0;
            string sql = @"select count(ID) from DocumentFiles where TempCode=@TempCode";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@TempCode", tempCode);
            DataTable dt = BusinessLogicBase.Default.Select(sql, pars);
            if (dt != null && dt.Rows.Count > 0) 
            {
                int.TryParse(dt.Rows[0][0].ToString(), out number);
            }
            return number;
        }

        public static int GetFileNumberByTempCodeFileType(string tempCode, int fileType)
        {
            int number = 0;
            string sql = @"select count(ID) from DocumentFiles where TempCode=@TempCode and FileType=@FileType";
            SqlParameter[] pars = new SqlParameter[2];
            pars[0] = new SqlParameter("@TempCode", tempCode);
            pars[1] = new SqlParameter("@FileType", fileType);
            DataTable dt = BusinessLogicBase.Default.Select(sql, pars);
            if (dt != null && dt.Rows.Count > 0)
            {
                int.TryParse(dt.Rows[0][0].ToString(), out number);
            }
            return number;
        }

        public static APAnswersDO GetAnwserDO(int answerID) 
        {
            APAnswersDO ado = new APAnswersDO();
            ado = (APAnswersDO)BusinessLogicBase.Default.Select(ado, answerID);
            return ado;
        }

        public static APAnswersDO GetAnwserDO(int resultID, int questionID)
        {
            APAnswersDO ado = new APAnswersDO();
            SqlParameter[] pars = new SqlParameter[2];
            pars[0] = new SqlParameter("@ResultID", resultID);
            pars[1] = new SqlParameter("@QuestionID", questionID);
            ado = (APAnswersDO)BusinessLogicBase.Default.Select(ado, "select * from dbo.APAnswers where ResultID=@ResultID and QuestionID=@QuestionID and status=1", pars);
            return ado;
        }

        public static DataTable GetAnswerOptions(int answerID)
        {
            string sql = "select * from dbo.APAnswerOptions where AnswerID=@AnswerID";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@AnswerID", answerID);
            DataTable dt = BusinessLogicBase.Default.Select(sql, pars);
            return dt;
        }

        public static APAnswerOptionsDO GetAnswerOption(int answerID, int optionID)
        {
            string sql = "select * from dbo.APAnswerOptions where AnswerID=@AnswerID and OptionID=@OptionID";
            SqlParameter[] pars = new SqlParameter[2];
            pars[0] = new SqlParameter("@AnswerID", answerID);
            pars[1] = new SqlParameter("@OptionID", optionID);
            APAnswerOptionsDO answerOptionDO = new APAnswerOptionsDO();
            answerOptionDO = (APAnswerOptionsDO)BusinessLogicBase.Default.Select(answerOptionDO, sql, pars);
            return answerOptionDO;
        }

        public static APAnswerOptionsDO GetAnswerOption(int resultID, int questionID, int optionID)
        {
            string sql = @"select ao.* from dbo.APAnswerOptions ao
	 inner join APAnswers aa on aa.ID=ao.AnswerID
	 where aa.ResultID=@ResultID 
	 and aa.QuestionID=@QuestionID 
	 and ao.OptionID=@OptionID";
            SqlParameter[] pars = new SqlParameter[3];
            pars[0] = new SqlParameter("@ResultID", resultID);
            pars[1] = new SqlParameter("@QuestionID", questionID);
            pars[2] = new SqlParameter("@OptionID", optionID);
            APAnswerOptionsDO answerOptionDO = new APAnswerOptionsDO();
            answerOptionDO = (APAnswerOptionsDO)BusinessLogicBase.Default.Select(answerOptionDO, sql, pars);
            return answerOptionDO;
        }

        public static void DeleteAnswerOption(int answerID, int optionID)
        {
            string sql = "delete from dbo.APAnswerOptions where AnswerID=@AnswerID and OptionID=@OptionID";
            SqlParameter[] pars = new SqlParameter[2];
            pars[0] = new SqlParameter("@AnswerID", answerID);
            pars[1] = new SqlParameter("@OptionID", optionID);
            BusinessLogicBase.Default.Execute(sql, pars);
        }

        public static int GetSingleAnswerOptionID(int answerID) 
        {
            string sql = "select * from dbo.APAnswerOptions where AnswerID=@AnswerID";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@AnswerID", answerID);
            DataTable dt = BusinessLogicBase.Default.Select(sql, pars);
            int optionID = 0;
            if (dt != null && dt.Rows.Count > 0)
            {
                int.TryParse(dt.Rows[0]["OptionID"].ToString(), out optionID);
            }
            return optionID;
        }

        public static int GetQuestionIDByCode(int resultID, string questionCode) 
        {
            string sql = @"select que.ID from APQuestions que 
inner join APQuestionnaireResults rr on que.QuestionnaireID=rr.QuestionnaireID
where rr.ID=@ResultID and que.Code=@Code";
            SqlParameter[] pars = new SqlParameter[2];
            pars[0] = new SqlParameter("@ResultID", resultID);
            pars[1] = new SqlParameter("@Code", questionCode);
            DataTable dt = BusinessLogicBase.Default.Select(sql, pars);
            int id = 0;
            if (dt != null && dt.Rows.Count > 0)
            {
                int.TryParse(dt.Rows[0]["ID"].ToString(), out id);
            }
            return id;
        }

        public static int GetQuestionIDByCode2(int questionnaireID, string questionCode)
        {
            string sql = @"select ID from APQuestions where QuestionnaireID=@questionnaireID and Code=@questionCode";
            SqlParameter[] pars = new SqlParameter[2];
            pars[0] = new SqlParameter("@questionnaireID", questionnaireID);
            pars[1] = new SqlParameter("@questionCode", questionCode);
            DataTable dt = BusinessLogicBase.Default.Select(sql, pars);
            int id = 0;
            if (dt != null && dt.Rows.Count > 0)
            {
                int.TryParse(dt.Rows[0]["ID"].ToString(), out id);
            }
            return id;
        }

        public static APOptionsDO GetOptionDO(int optionID)
        {
            APOptionsDO optionDO = new APOptionsDO();
            optionDO = (APOptionsDO)BusinessLogicBase.Default.Select(optionDO, optionID);
            return optionDO;
        }

        public static APOptionsDO GetOptionDO(int questionID, string optionText)
        {
            string sql = @"select * from APOptions where QuestionID=@QuestionID and Title=@OptionText";
            SqlParameter[] pars = new SqlParameter[2];
            pars[0] = new SqlParameter("@QuestionID", questionID);
            pars[1] = new SqlParameter("@OptionText", optionText);
            APOptionsDO optionDO = new APOptionsDO();
            optionDO = (APOptionsDO)BusinessLogicBase.Default.Select(optionDO, sql, pars);
            return optionDO;
        }

        public static APOptionsDO GetCorrectOptionDO(int questionID)
        {
            string sql = @"select * from APOptions where bCorrectOption=1 and QuestionID=@QuestionID";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@QuestionID", questionID);
            APOptionsDO optionDO = new APOptionsDO();
            optionDO = (APOptionsDO)BusinessLogicBase.Default.Select(optionDO, sql, pars);
            return optionDO;
        }

        public static DataTable GetAllSubQuestionsByID(int questionID) 
        {
            string spName = "GetAllSubQuestionsByID";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@ID", questionID);
            DataTable dt = BusinessLogicBase.Default.ExceuteStoredProcedure(spName, pars);
            return dt;
        }

        public static int GetQuestionnaireCompletedQuestionNumber(int resultID) 
        {
            string sql = "select count(ID) from dbo.APAnswers where ResultID=@ResultID";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@ResultID", resultID);
            DataTable dt = BusinessLogicBase.Default.Select(sql, pars);
            int count = 0;
            if (dt != null && dt.Rows.Count > 0) 
            {
                int.TryParse(dt.Rows[0][0].ToString(), out count);
            }
            return count;
        }

        public static DataTable GetQuestionnaireResultInfo (int resultID)
        {
            string spName = "GetQuestionnaireResultInfo";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@ResultID", resultID);
            DataTable dt = BusinessLogicBase.Default.ExceuteStoredProcedure(spName, pars);
            return dt;
        }

        public static DataTable GetQuestionnaireAnswersWithCorrectOptions(int resultID)
        {
            string spName = "GetQuestionnaireAnswersWithCorrectOptions";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@ResultID", resultID);
            DataTable dt = BusinessLogicBase.Default.ExceuteStoredProcedure(spName, pars);
            return dt;
        }

        public static DataTable GetQuestionnaireAnswers(int resultID)
        {
            string spName = "GetQuestionnaireAnswers";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@ResultID", resultID);
            DataTable dt = BusinessLogicBase.Default.ExceuteStoredProcedure(spName, pars);
            return dt;
        }

        public static DataSet GetQuestionsByResultIDWithOptions(int resultID)
        {
            string spName = "GetQuestionsByResultID";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@ResultID", resultID);
            DataSet ds = SqlHelper.ExecuteDataset(spName, CommandType.StoredProcedure, pars);
            return ds;
        }

        public static string GetAnswerOptionText(int answerID)
        {
            string sql = @"select stuff(
(
	select ';' + isnull(oo.Title,'') + case when isnull(aa.OptionText,'')<>'' then '(' + aa.OptionText + ')' else '' end
	from APAnswerOptions aa 
	inner join APOptions oo on oo.ID=aa.OptionID
	where aa.AnswerID=@AnswerID
	order by aa.ID
	for xml path('')
),1,1,'') as OptionText";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@AnswerID", answerID);
            DataTable dt = BusinessLogicBase.Default.Select(sql, pars);
            string optionText = string.Empty;
            if (dt != null && dt.Rows.Count > 0)
            {
                optionText = dt.Rows[0][0].ToString();
            }
            return optionText;
        }

        public static void FixQuestionnaireResultAnswers(int questionnaireID, int questionID, int answerID, int resultID) 
        {
            string spName = "FixQuestionnaireResultAnswers";
            SqlParameter[] pars = new SqlParameter[4];
            pars[0] = new SqlParameter("@QuestionnaireID", questionnaireID);
            pars[1] = new SqlParameter("@QuestionID", questionID);
            pars[2] = new SqlParameter("@AnswerID", answerID);
            pars[3] = new SqlParameter("@ResultID", resultID);
            SqlHelper.ExecuteNonQuery(spName, pars);
        }

        public static void DeleteQuestionAppealAuditNotes(int resultID, int questionID, int auditTypeID, int userID)
        {
            string sql = @"delete from APQuestionAuditNotes
	where AuditTypeID=@AuditTypeID
	and ResultID=@ResultID
	and QuestionID=@QuestionID
	and CreateUserID=@UserID";
            SqlParameter[] pars = new SqlParameter[4];
            pars[0] = new SqlParameter("@ResultID", resultID);
            pars[1] = new SqlParameter("@QuestionID", questionID);
            pars[2] = new SqlParameter("@UserID", userID);
            pars[3] = new SqlParameter("@AuditTypeID", auditTypeID);
            BusinessLogicBase.Default.Execute(sql, pars);
        }

        public static APQuestionAuditNotesDO GetAPQuestionAuditNotesDO(int resultID, int questionID, int auditTypeID, int userID)
        {
            string sql = @"	select top 1 * from APQuestionAuditNotes nn 
	where AuditTypeID=@AuditTypeID
	and ResultID=@ResultID 
	and QuestionID=@QuestionID
    and CreateUserID=@UserID
order by CreateTime desc";
            SqlParameter[] pars = new SqlParameter[4];
            pars[0] = new SqlParameter("@AuditTypeID", auditTypeID);
            pars[1] = new SqlParameter("@ResultID", resultID);
            pars[2] = new SqlParameter("@QuestionID", questionID);
            pars[3] = new SqlParameter("@UserID", userID);
            APQuestionAuditNotesDO auditNotesDO = new APQuestionAuditNotesDO();
            auditNotesDO = (APQuestionAuditNotesDO)BusinessLogicBase.Default.Select(auditNotesDO, sql, pars);
            return auditNotesDO;
        }

        public static DataSet GetQuestionsByQuestionnaireID(int questionnaireID)
        {
            string sql = @"
/*
declare @QuestionnaireID int
set @QuestionnaireID=1116
*/
	select * into #tempQuestions from APQuestions
	where Status=1 and QuestionnaireID=@QuestionnaireID
	order by code
	
	select oo.* into #tempOptions
	from APOptions oo
	inner join #tempQuestions que on oo.QuestionID=que.ID
	order by que.code,oo.ID


	select * from #tempQuestions order by code
	select * from #tempOptions


	drop table #tempQuestions
	drop table #tempOptions";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@QuestionnaireID", questionnaireID);
            return SqlHelper.ExecuteDataset(sql, CommandType.Text, pars);
        }

        public static DataTable GetQuestionsTableByQuestionnaireID(int questionnaireID)
        {
            string sql = @"select * from APQuestions
	where Status=1 and QuestionnaireID=@QuestionnaireID
	order by code";
	
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@QuestionnaireID", questionnaireID);
            return baseLogic.Select(sql, pars);
        }

        public static DataTable GetSelectQuestionsByQuestionnaireID(int questionnaireID)
        {
            string sql = @"select * from APQuestions where QuestionnaireID=@QuestionnaireID and QuestionType in (1,2,3) and Status=1 order by code";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@QuestionnaireID", questionnaireID);
            return baseLogic.Select(sql, pars);
        }

        public static DataTable GetAnswerOptionStatistics(int projectID, int questionnaireID, int questionID, DateTime fromDate, DateTime toDate, int currentClientID)
        {
            string spName = "GetAnswerOptionStatistics";
            SqlParameter[] pars = new SqlParameter[6];
            pars[0] = new SqlParameter("@projectID", projectID);
            pars[1] = new SqlParameter("@questionnaireID", questionnaireID);
            pars[2] = new SqlParameter("@questionID", questionID);
            pars[3] = new SqlParameter("@fromDate", fromDate);
            pars[4] = new SqlParameter("@toDate", toDate);
            pars[5] = new SqlParameter("@currentClientID", currentClientID);
            return baseLogic.ExceuteStoredProcedure(spName, pars);
        }

        public static DataTable GetSubClientAnswerOptionStatistics(int projectID, int questionnaireID, int questionID, DateTime fromDate, DateTime toDate, int currentClientID)
        {
            string spName = "GetSubClientAnswerOptionStatistics";
            SqlParameter[] pars = new SqlParameter[6];
            pars[0] = new SqlParameter("@projectID", projectID);
            pars[1] = new SqlParameter("@questionnaireID", questionnaireID);
            pars[2] = new SqlParameter("@questionID", questionID);
            pars[3] = new SqlParameter("@fromDate", fromDate);
            pars[4] = new SqlParameter("@toDate", toDate);
            pars[5] = new SqlParameter("@currentClientID", currentClientID);
            return baseLogic.ExceuteStoredProcedure(spName, pars);
        }

        public static DataTable GetGPSInfoInResultByQuestionnaireID(int questionnaireID)
        {
            string sql = @"select ID,LocationX,LocationY from APQuestionnaireResults where QuestionnaireID=@QuestionnaireID";
            SqlParameter[] pars = new SqlParameter[1];
            pars[0] = new SqlParameter("@QuestionnaireID", questionnaireID);
            return baseLogic.Select(sql, pars);
        }

        public static void StartGPSThead(GPSValication gpsObj) 
        {
            Thread td = new Thread(new ParameterizedThreadStart(CheckSimillarGPS));
            td.Start(gpsObj);
        }

        public static void CheckSimillarGPS(object obj) 
        {
            GPSValication gpsObj = (GPSValication)obj;
            double latitude = gpsObj.Latitude;
            double longitude = gpsObj.Longitude;
            int resultID = gpsObj.resultID;
            int questionID = gpsObj.questionID;
            int questionnaireID = gpsObj.questionnaireID;

            DataTable dt = GetGPSInfoInResultByQuestionnaireID(questionnaireID);

            if (dt != null && dt.Rows.Count > 0) 
            {
                foreach (DataRow row in dt.Rows) 
                {
                    int id = row["ID"].ToString().ToInt(0);
                    if (resultID != id) 
                    {
                        //排除自己
                        double locationX = row["LocationX"].ToString().ToDouble(0);
                        double locationY = row["LocationY"].ToString().ToDouble(0);
                        double distance = MapHelper.GetDistance(latitude, longitude, locationY, locationX);
                        if (distance < Constants.MinDistance) 
                        {
                            int auditType = (int)Enums.QuestionnaireAuditType.质控审核;
                            string encodeResultID = CommonFunction.EncodeBase64(id.ToString(), 5);
                            string encodeAuditType = CommonFunction.EncodeBase64(auditType.ToString(), 5);
                            string url = string.Format("QuestionnaireUpload3.htm?resultID={0}&auditType={1}", encodeResultID, encodeAuditType);
                            APQuestionAuditNotesDO noteDO = new APQuestionAuditNotesDO();
                            noteDO.AuditNotes = "疑似相同商户地址： <a class=\"Allmb_Opera\" href=\"" + url + "\" target=\"_blank\">查看</a>";
                            noteDO.AuditTypeID = auditType;
                            noteDO.CreateTime = DateTime.Now;
                            noteDO.CreateUserID = Constants.SystemUserID;
                            noteDO.QuestionID = questionID;
                            noteDO.ResultID = resultID;
                            noteDO.UserTypeID = (int)Enums.UserType.质控员;
                            BusinessLogicBase.Default.Insert(noteDO);
                        }
                    }
                }
            }
            
        }
    }
}
