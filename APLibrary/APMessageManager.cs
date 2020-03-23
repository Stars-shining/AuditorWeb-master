using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using APLibrary.DataObject;
using System.Data.SqlClient;
using System.Data;
using System.Net.Mail;
using System.Net;
using System.Threading;

namespace APLibrary
{
    public class APMessageManager : BusinessLogicBase
    {
        private static BusinessLogicBase baseLogic = new BusinessLogicBase();

        public static APMessageDO GetMessageByID(int id)
        {
            APMessageDO qnDO = new APMessageDO();
            return (APMessageDO)baseLogic.Select(qnDO, id);
        }

        public static void SendMessageViaEmail(APMessageDO msgDO) 
        {
            APMessageManager apm = new APMessageManager();
            Thread td = new Thread(new ParameterizedThreadStart(apm.SendMessageViaEmailAsyn));
            td.IsBackground = true; 
            td.Start(msgDO);
        }

        public void SendMessageViaEmailAsyn(object obj)
        {
            APMessageDO msgDO = (APMessageDO)obj;

            string content = msgDO.Content;
            string title = msgDO.Title;
            int acceptUserID = msgDO.AcceptUserID;
            if (acceptUserID <= 0) {
                return;
            }
            APUsersDO userDO = APUserManager.GetUserByID(acceptUserID);
            if (userDO == null || string.IsNullOrEmpty(userDO.Email)) 
            {
                return;
            }
            string toMail = userDO.Email;
            string relatedUrl = msgDO.RelatedUrl;

            string mailserver = BusinessConfigurationManager.GetItemValueByItemKey(0, "ContactOnlineEmailServer");
            string mailport = BusinessConfigurationManager.GetItemValueByItemKey(0, "ContactOnlineEmailServerPort");
            string displayname = BusinessConfigurationManager.GetItemValueByItemKey(0, "ContactOnlineEmailDisplayName");
            string username = BusinessConfigurationManager.GetItemValueByItemKey(0, "ContactOnlineEmailUsername");
            string password = BusinessConfigurationManager.GetItemValueByItemKey(0, "ContactOnlineEmailPassword");
            try
            {
                int port = 25;
                if (string.IsNullOrEmpty(mailport) == false)
                {
                    int.TryParse(mailport, out port);
                }
                SmtpClient client = new SmtpClient(mailserver, port);
                client.UseDefaultCredentials = true;
                client.Credentials = new NetworkCredential(username, password);
                client.DeliveryMethod = SmtpDeliveryMethod.Network;
                //client.EnableSsl = true;
                
                MailMessage message = new MailMessage();
                MailAddress from = new MailAddress(username, displayname);
                MailAddress to = new MailAddress(toMail);
                message.From = from;
                message.To.Add(to);
                string subject = title;
                message.Subject = subject;
                message.IsBodyHtml = true;
                message.Priority = MailPriority.High;
                StringBuilder sb = new StringBuilder();
                sb.Append("<div>");
                sb.Append("<p style=\"font-weight: bold; margin: 10px;\">" + content + "</p>");
                if (msgDO.ProjectID > 0)
                {
                    APProjectsDO projectDO = APProjectManager.GetProjectByID(msgDO.ProjectID);
                    sb.Append("<p style=\"margin: 10px;\">项目名称：" + projectDO.Name + "</p>");
                }
                if (string.IsNullOrEmpty(relatedUrl) == false)
                {
                    sb.Append("<p style=\"margin: 10px;\">点击链接进入：<a href=\"" + relatedUrl + "\">此处</a></p>");
                }
                sb.Append("</div>");
                message.Body = sb.ToString();
                message.BodyEncoding = System.Text.Encoding.UTF8;

                client.Send(message);
            }
            catch { }
        }

        public static DataTable SearchMessages(int acceptUserID, string title, DateTime fromDate, DateTime toDate, int status, int projectID) 
        {
            string spName = "SearchMessages";
            SqlParameter[] pars = new SqlParameter[6];
            pars[0] = new SqlParameter("@AcceptUserID", acceptUserID);
            pars[1] = new SqlParameter("@Title", title);
            pars[2] = new SqlParameter("@FromDate", fromDate);
            pars[3] = new SqlParameter("@ToDate", toDate);
            if (status < 0)
            {
                pars[4] = new SqlParameter("@Status", DBNull.Value);
            }
            else
            {
                pars[4] = new SqlParameter("@Status", status);
            }
            pars[5] = new SqlParameter("@ProjectID", projectID);
            return baseLogic.ExceuteStoredProcedure(spName, pars);
        }

        public static DataTable GetMessageInfo(int msgID) 
        {
            string sql = @"select m.ID,
m.Title,
bcType.ItemValue as TypeName, 
isnull(uu.UserName,'系统') as FromUserName,
m.Content,
isnull(m.RelatedUrl,'') as RelatedUrl,
isnull(m.ProjectID,0) as ProjectID
from dbo.APMessage m
left join BusinessConfiguration bcType on bcType.ItemKey=m.TypeID and bcType.ItemDesc='MessageType'
left join APUsers uu on uu.ID=m.FromUserID
where m.ID=@ID";
            SqlParameter[] paras = new SqlParameter[1];
            paras[0] = new SqlParameter("@ID", msgID);
            return BusinessLogicBase.Default.Select(sql, paras);
        }
    
    }
}
