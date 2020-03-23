using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web;

namespace APLibrary.Utility
{
    [Serializable]
    public sealed class WebSiteContext
    {
        #region Private Fields
        private const string SessionPredefineEntryStatus = "Session:PredefineEntryStatus";
        private const string SessionCurrentUser = "Session:SessionCurrentUser";
        private const string SessionCurrentProject = "Session:SessionCurrentProject";
        private const string SessionCurrentQuestionnaire = "Session:SessionCurrentQuestionnaire";
        private const string SessionCurrentQuestionList = "Session:SessionCurrentQuestionList";
        private const string SessionCurrentClientID = "Session:SessionCurrentClientID";

        private static WebSiteContext webSiteContext;
        private WebSiteContext()
        {
            //
            // TODO: Add constructor logic here
            //
        }
        static WebSiteContext()
        {
            webSiteContext = new WebSiteContext();
        }
        #endregion

        #region Public Satatic Fields
        public static WebSiteContext Current
        {
            get { return webSiteContext; }
        }

        public static int CurrentUserID
        {
            get
            {
                if (webSiteContext == null)
                    return int.MinValue;
                if (webSiteContext.CurrentUser == null)
                    return int.MinValue;

                return webSiteContext.CurrentUser.ID;
            }
        }

        public static int CurrentProjectID
        {
            get
            {
                if (webSiteContext == null)
                    return int.MinValue;
                if (webSiteContext.CurrentProject == null)
                    return int.MinValue;

                return webSiteContext.CurrentProject.ID;
            }
        }

        public static int CurrentClientID
        {
            get
            {
                if (HttpContext.Current != null && HttpContext.Current.Session != null && HttpContext.Current.Session[SessionCurrentClientID] != null)
                {
                    int _clientID = 0;
                    int.TryParse(HttpContext.Current.Session[SessionCurrentClientID].ToString(), out _clientID);
                    return _clientID;
                }
                else
                {
                    return 0;
                }
            }
            set
            {
                HttpContext.Current.Session[SessionCurrentClientID] = value;
            }
        }

        public static string CurrentUserName
        {
            get
            {
                if (webSiteContext == null)
                    return string.Empty;
                if (webSiteContext.CurrentUser == null)
                    return string.Empty;
                return webSiteContext.CurrentUser.UserName;
            }
        }

        #endregion

        #region Private Method
        private void RedirectToLogin()
        {
            
        }
        #endregion

        #region Public APIs
        public bool ExistSystem()
        {
            if (Current.CurrentUser != null && Current.CurrentUser.ID > 0)
            {
                Current.CurrentUser = null;
                return true;
            }
            return false;
        }

        public void ClearSession()
        {
            HttpContext.Current.Session.Clear();
        }
        #endregion

        public APLibrary.DataObject.APUsersDO CurrentUser
        {
            get
            {
                if (HttpContext.Current != null && HttpContext.Current.Session != null)
                {
                    return HttpContext.Current.Session[SessionCurrentUser] as APLibrary.DataObject.APUsersDO;
                }
                else
                {
                    return null;
                }
            }
            set
            {
                HttpContext.Current.Session[SessionCurrentUser] = value;
            }
        }

        public APLibrary.DataObject.APProjectsDO CurrentProject
        {
            get
            {
                if (HttpContext.Current != null && HttpContext.Current.Session != null)
                {
                    return HttpContext.Current.Session[SessionCurrentProject] as APLibrary.DataObject.APProjectsDO;
                }
                else
                {
                    return null;
                }
            }
            set
            {
                HttpContext.Current.Session[SessionCurrentProject] = value;
            }
        }

        public APLibrary.DataObject.APQuestionnairesDO CurrentQuestionnaire
        {
            get
            {
                if (HttpContext.Current != null && HttpContext.Current.Session != null)
                {
                    return HttpContext.Current.Session[SessionCurrentQuestionnaire] as APLibrary.DataObject.APQuestionnairesDO;
                }
                else
                {
                    return null;
                }
            }
            set
            {
                HttpContext.Current.Session[SessionCurrentQuestionnaire] = value;
            }
        }

        public List<APLibrary.DataObject.APQuestionsDO> CurrentQuestionList
        {
            get
            {
                if (HttpContext.Current != null && HttpContext.Current.Session != null)
                {
                    return HttpContext.Current.Session[SessionCurrentQuestionList] as List<APLibrary.DataObject.APQuestionsDO>;
                }
                else
                {
                    return null;
                }
            }
            set
            {
                HttpContext.Current.Session[SessionCurrentQuestionList] = value;
            }
        }
    }
}
