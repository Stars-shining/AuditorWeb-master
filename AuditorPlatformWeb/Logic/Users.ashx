<%@ WebHandler Language="C#" Class="Users" %>

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
using QRCodeLib;
using System.IO;

public class Users : IHttpHandler, IRequiresSessionState
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
                    SearchUsers();
                    break;
                case 2:
                    QuitSystem();
                    break;
                case 3:
                    LoadLoginUser();
                    break;
                case 4:
                    DoLogin();
                    break;
                case 5:
                    GetAllUsers();
                    break;
                case 6:
                    SubmitAccount();
                    break;
                case 7:
                    GetAccountInfo();
                    break;
                case 8:
                    DeleteUser();
                    break;
                case 9:
                    DownloadAllUsers();
                    break;
                case 10:
                    GetUserRoles();
                    break;
                case 11:
                    GetAllReturnClientUsers();
                    break;
                case 12:
                    ChangePassword();
                    break;
                case 13:
                    ResetPassword();
                    break;
                case 14:
                    SubmitUserInfo();
                    break;
                case 15:
                    CreateUserQRCode();
                    break;
                case 16:
                    GetVisitorCardInfo();
                    break;
                case 17:
                    GetProjectVisitorByIDCardNumber();
                    break;
                case 18:
                    GetAllProjectUsers();
                    break;
                case 19:
                    DownloadAllProjectUsers();
                    break;
                case 20:
                    SubmitProjectUsers();
                    break;
                case 21:
                    DeleteProjectUsers();
                    break;
                case 22:
                    LoginClientUser();
                    break;
                case 23:
                    GetRandCode();
                    break;
                default: 
                    break;
            }
        }
        catch { }
    }

    public void GetRandCode()
    {
        YZMHelper code = new YZMHelper();
        //写入Session，验证的时候再取出来比对
        HttpContext.Current.Session[Constants.LoginRandCode] = code.Text;
        
        MemoryStream ms = new MemoryStream();
        code.Image.Save(ms, System.Drawing.Imaging.ImageFormat.Bmp);
        byte[] bytes = ms.GetBuffer();
        ms.Close();
        HttpContext.Current.Response.ContentType = "image/jpeg";
        HttpContext.Current.Response.BinaryWrite(bytes);
        HttpContext.Current.Response.Flush();
        return;
    }
    
    public void GetProjectVisitorByIDCardNumber()
    {
        string pid = HttpContext.Current.Request.QueryString["pid"];
        string idCardNumber = HttpContext.Current.Request.QueryString["idCardNumber"];
        
        int projectID = 0;
        int.TryParse(pid, out projectID);

        int userID = APUserManager.GetUserIDByIDCardNumber(idCardNumber);
        if (userID <=0 || projectID <= 0)
        {
            string jsonResult = "-1";
            HttpContext.Current.Response.ContentType = "application/json";
            HttpContext.Current.Response.Write(jsonResult);
            return;
        }
        bool involved = false;
        DataTable dt = APProjectManager.GetAllProjects("", Constants.Date_Min, Constants.Date_Max, -999, userID, (int)Enums.UserType.访问员);
        DataView dv = dt.DefaultView;
        dv.RowFilter = "ID=" + projectID;
        dt = dv.ToTable();
        if (dt != null && dt.Rows.Count > 0) 
        {
            involved = true;
        }
        string result = "-1";
        if (involved)
        {
            result = userID.ToString();
        }
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(result);
    }

    public void GetVisitorCardInfo() 
    {
        string uid = HttpContext.Current.Request.QueryString["uid"];
        string pid = HttpContext.Current.Request.QueryString["pid"];

        int userID = 0;
        int projectID = 0;
        int.TryParse(uid, out userID);
        int.TryParse(pid, out projectID);

        APUsersDO userDO = APUserManager.GetUserByID(userID);
        APProjectsDO projectDO = APProjectManager.GetProjectByID(projectID);
        if (userID == null || projectDO == null) 
        {
            string jsonResult = "-1";
            HttpContext.Current.Response.ContentType = "application/json";
            HttpContext.Current.Response.Write(jsonResult);
            return;
        }
        string userName = userDO.UserName;
        string idCardNumber = userDO.IDCardNumber;
        string photoPath = userDO.PhotoPath;
        string projectName = projectDO.Name;
        string period = projectDO.FromDate.ToString("yyyy.MM.dd") + " 至 " + projectDO.ToDate.ToString("yyyy.MM.dd");
        string result = "{\"userName\":\"" + userName + "\",\"idCardNumber\":\"" + idCardNumber + "\",\"photoPath\":\"" + photoPath + "\",\"projectName\":\"" + projectName + "\",\"period\":\"" + period + "\"}";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(result);
    }

    public void CreateUserQRCode() 
    {
        string id = HttpContext.Current.Request.Params["id"];
        string refresh = HttpContext.Current.Request.Params["refresh"];

        if (WebSiteContext.Current.CurrentUser == null)
        {
            //session 超时或丢失，强制重新登录
            HttpContext.Current.Response.ContentType = "text/plain";
            HttpContext.Current.Response.Write("-1");
            return;
        }
        
        int userID = WebSiteContext.CurrentUserID;

        bool bNew = false;
        bool.TryParse(refresh, out bNew);
        
        string photoPath = WebSiteContext.Current.CurrentUser.PhotoPath;
        string diskPath = string.Empty;
        if (string.IsNullOrEmpty(photoPath)) 
        {
            photoPath = Constants.SysLogoWithoutName;
            diskPath = HttpContext.Current.Server.MapPath(photoPath);
        }
        else
        {
            string photoPathVirtual = photoPath.Replace("..", "~");
            diskPath = HttpContext.Current.Server.MapPath(photoPathVirtual);
        }
        DirectoryMappingDO dmDO = DocumentManager.GetCurrentDirMappingDO();
        string physicalPath = dmDO.PhysicalPath;
        string vituralPath = dmDO.VituralPath;

        string folderName = Constants.UserPhotoFolderName;
        string timestamp = DateTime.Now.Year.ToString();
        string originalName = userID + "_code.jpg";
        string diskFolderPath = physicalPath.TrimEnd('\\') + "\\" + folderName + "\\" + timestamp + "\\";
        if (Directory.Exists(diskFolderPath) == false)
        {
            Directory.CreateDirectory(diskFolderPath);
        }
        string diskFilePath = diskFolderPath + originalName;
        if (bNew == false && File.Exists(diskFilePath) && File.GetCreationTime(diskFilePath).AddDays(1) > DateTime.Today)
        {
            //创建时间不超过一天，则不创建新的文件
        }
        else
        {
            string expireTime = DateTime.Now.AddDays(1).ToString("yyyy-MM-dd hh:mm:ss");
            string paras = "?uid=" + CommonFunction.EncodeBase64(userID.ToString(), 2) + "&pid=" + CommonFunction.EncodeBase64(id, 2) + "&et=" + CommonFunction.EncodeBase64(expireTime, 2);
            string url = HttpContext.Current.Request.UrlReferrer.ToString().Replace("list.htm", "visitorCard.htm") + paras;
            ImageUtility util = new ImageUtility();
            System.Drawing.Bitmap img = QRCodeHelper.CreateQRCodeWithLogo(url, diskPath);
            if (System.IO.File.Exists(diskFilePath))
            {
                System.IO.File.Delete(diskFilePath);
            }
            img.Save(diskFilePath);
        }
        string webDirPath = vituralPath.TrimEnd('/') + "/" + folderName + "/" + timestamp + "/" + originalName;
        string jsonResult = webDirPath;
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void SubmitUserInfo() 
    {
        string id = HttpContext.Current.Request.Params["id"];

        string name = HttpContext.Current.Request.Params["name"];
        string sex = HttpContext.Current.Request.Params["sex"];
        string degree = HttpContext.Current.Request.Params["degree"];
        string birthdate = HttpContext.Current.Request.Params["birthdate"];
        string region = HttpContext.Current.Request.Params["region"];
        string household = HttpContext.Current.Request.Params["household"];
        string householdAddress = HttpContext.Current.Request.Params["householdAddress"];
        string address = HttpContext.Current.Request.Params["address"];
        string idcardNumber = HttpContext.Current.Request.Params["idcardNumber"];
        string postcode = HttpContext.Current.Request.Params["postcode"];
        string department = HttpContext.Current.Request.Params["department"];
        string position = HttpContext.Current.Request.Params["position"];
        string telephone = HttpContext.Current.Request.Params["telephone"];
        string mobilephone = HttpContext.Current.Request.Params["mobilephone"];
        string bHasExperience = HttpContext.Current.Request.Params["bHasExperience"];
        string bHasProtocol = HttpContext.Current.Request.Params["bHasProtocol"];
        string protocolType = HttpContext.Current.Request.Params["protocolType"];
        string entryTime = HttpContext.Current.Request.Params["entryTime"];
        string trainingDate = HttpContext.Current.Request.Params["trainingDate"];
        string trainingScore = HttpContext.Current.Request.Params["trainingScore"];
        string trainingComment = HttpContext.Current.Request.Params["trainingComment"];
        string openingBankName = HttpContext.Current.Request.Params["openingBankName"];
        string bankAccount = HttpContext.Current.Request.Params["bankAccount"];
        string photoPath = HttpContext.Current.Request.Params["photoPath"];
        
        int userID = 0;
        int.TryParse(id, out userID);

        int _sex = 0;
        int _degree = 0;
        int _region = 0;
        int _household = 0;
        int _protocolType = 0;
        bool _bHasExperience = false;
        bool _bHasProtocol = false;
        DateTime _birthdate = Constants.Date_Null;
        DateTime _entryTime = Constants.Date_Null;
        DateTime _trainingDate = Constants.Date_Null;
        decimal _trainingScore = 0;
        int.TryParse(sex, out _sex);
        int.TryParse(degree, out _degree);
        int.TryParse(region, out _region);
        int.TryParse(household, out _household);
        int.TryParse(protocolType, out _protocolType);
        bool.TryParse(bHasExperience, out _bHasExperience);
        bool.TryParse(bHasProtocol, out _bHasProtocol);
        DateTime.TryParse(birthdate, out _birthdate);
        DateTime.TryParse(entryTime, out _entryTime);
        DateTime.TryParse(trainingDate, out _trainingDate);
        decimal.TryParse(trainingScore, out _trainingScore);
        
        APUsersDO userDO = APUserManager.GetUserByID(userID);
        userDO.UserName = name;
        userDO.Sex = _sex;
        userDO.Degree = _degree;
        userDO.Region = _region;
        userDO.HouseHoldRegistration = _household;
        userDO.BHasExperience = _bHasExperience;
        userDO.BHasProtocol = _bHasProtocol;
        userDO.DateOfBirth = _birthdate;
        userDO.EntryTime = _entryTime;
        userDO.TrainingTime = _trainingDate;
        userDO.TrainingScore = _trainingScore;
        userDO.TrainingComment = trainingComment;

        userDO.HouseHoldAddress = householdAddress;
        userDO.Address = address;
        userDO.IDCardNumber = idcardNumber;
        userDO.Department = department;
        userDO.Position = position;
        userDO.Postcode = postcode;
        userDO.ProtocolType = _protocolType;
        userDO.Telephone = telephone;
        userDO.MobilePhone = mobilephone;
        userDO.OpeningBankName = openingBankName;
        userDO.BankAccount = bankAccount;
        userDO.PhotoPath = photoPath;
        APUserManager.Default.Update(userDO);
        
        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void ResetPassword()
    {
        string id = HttpContext.Current.Request.Params["id"];
        int userID = 0;
        int.TryParse(id, out userID);
        APUsersDO userDO = APUserManager.GetUserByID(userID);
        if (userDO.RoleID == (int)Enums.UserType.客户) 
        {
            userDO.Password = userDO.LoginName;
        }
        else
        {
            userDO.Password = Constants.InitialPassword;
        }
        APUserManager.Default.Update(userDO);
        string jsonResult = userDO.Password;
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void ChangePassword() 
    {
        string oldPwd = HttpContext.Current.Request.Params["oldPwd"];
        string newPwd = HttpContext.Current.Request.Params["newPwd"];
        string newPwdConfirm = HttpContext.Current.Request.Params["newPwdConfirm"];
        string jsonResult = "0";

        if (WebSiteContext.Current.CurrentUser == null)
        {
            jsonResult = "3";
            HttpContext.Current.Response.ContentType = "application/json";
            HttpContext.Current.Response.Write(jsonResult);
            return;
        }
        string currentPwd = WebSiteContext.Current.CurrentUser.Password;
        if (currentPwd != oldPwd) 
        {
            jsonResult = "2";
            HttpContext.Current.Response.ContentType = "application/json";
            HttpContext.Current.Response.Write(jsonResult);
            return;
        }
        APUsersDO userDO = APUserManager.GetUserByID(WebSiteContext.CurrentUserID);
        userDO.Password = newPwd;
        BusinessLogicBase.Default.Update(userDO);
        jsonResult = "1";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetAllReturnClientUsers() 
    {
        string resultID = HttpContext.Current.Request.QueryString["resultID"];
        int _resultID = 0;
        int.TryParse(resultID, out _resultID);
        
        APQuestionnaireResultsDO resultDO = APQuestionnaireManager.GetQuestionnaireResultDOByID(_resultID);
        
        int currentClientID = WebSiteContext.Current.CurrentUser.ClientID;
        int clientID = resultDO.ClientID;
        DataTable dt = new DataTable();
        dt.Columns.Add("Order", typeof(int));
        dt.Columns.Add("ID", typeof(int));
        dt.Columns.Add("Name", typeof(string));
        int projectID = WebSiteContext.CurrentProjectID;
        int tempClientID = clientID;
        int order = 0;
        while (currentClientID != tempClientID && tempClientID > 0) {
            APUsersDO userDO = APUserManager.GetClientUserDO(tempClientID, projectID);
            dt.Rows.Add(++order, userDO.ID, userDO.UserName);
            
            APClientsDO clientDO = APClientManager.GetClientDOByID(tempClientID);
            tempClientID = clientDO.ParentID;
        }

        DataView dv = dt.DefaultView;
        dv.Sort = "Order desc";
        dt = dv.ToTable();        
        string jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetUserRoles() 
    {
        int userType = WebSiteContext.Current.CurrentUser.RoleID;
    
    }

    public void DeleteUser() 
    {
        string ids = HttpContext.Current.Request.Params["ids"];
        string[] allids = ids.Split(',');
        foreach (string id in allids)
        {
            int _id = 0;
            int.TryParse(id, out _id);
            APUsersDO userDO = APUserManager.GetUserByID(_id);
            userDO.DeleteTime = DateTime.Now;
            userDO.DeleteFlag = true;
            userDO.Status = (int)Enums.UserStatus.删除;
            BusinessLogicBase.Default.Update(userDO);
        }
        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void SubmitProjectUsers()
    {
        int projectID = WebSiteContext.CurrentProjectID;
        if (projectID <= 0) 
        {
            HttpContext.Current.Response.ContentType = "text/plain";
            HttpContext.Current.Response.Write("0");
            return;
        }
        string ids = HttpContext.Current.Request.Params["ids"];
        string roleID = HttpContext.Current.Request.Params["roleID"];
        int _roleID = 0;
        int.TryParse(roleID, out _roleID);
        string[] allids = ids.Split(',');
        foreach (string id in allids)
        {
            int _id = 0;
            int.TryParse(id, out _id);
            APProjectUsersDO userDO = new APProjectUsersDO();
            userDO.UserID = _id;
            userDO.RoleID = _roleID;
            userDO.ProjectID = projectID;
            BusinessLogicBase.Default.Insert(userDO);
        }
        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void DeleteProjectUsers() 
    {
        string ids = HttpContext.Current.Request.Params["ids"];
        int projectID = WebSiteContext.CurrentProjectID;
        if (ids != "" && projectID > 0)
        {
            string sql = string.Format("delete from APProjectUsers where ProjectID={0} and UserID in ({1}) ", projectID, ids);
            BusinessLogicBase.Default.Execute(sql);
        }
        string jsonResult = "1";
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }


    public void GetAccountInfo() 
    {
        string id = HttpContext.Current.Request.QueryString["id"];
        int _id = 0;
        int.TryParse(id, out _id);
        APUsersDO userDO = APUserManager.GetUserByID(_id);
        string jsonResult = JSONHelper.ObjectToJSON(userDO);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void SubmitAccount() 
    {
        string userName = HttpContext.Current.Request.Params["userName"];
        string loginName = HttpContext.Current.Request.Params["loginName"];
        string roleID = HttpContext.Current.Request.Params["roleID"];
        string email = HttpContext.Current.Request.Params["email"];
        string groupID = HttpContext.Current.Request.Params["groupID"];
        string password = HttpContext.Current.Request.Params["password"];
        string statusID = HttpContext.Current.Request.Params["statusID"];

        string areaID = HttpContext.Current.Request.Params["areaID"];
        string province = HttpContext.Current.Request.Params["province"];
        string city = HttpContext.Current.Request.Params["city"];
        string district = HttpContext.Current.Request.Params["district"];
        
        string id = HttpContext.Current.Request.Params["id"];

        int _roleID = 0;
        int.TryParse(roleID, out _roleID);
        int _groupID = 0;
        int.TryParse(groupID, out _groupID);
        int _statusID = 0;
        int.TryParse(statusID, out _statusID);
        int _id = 0;
        int.TryParse(id, out _id);

        int _areaID = 0;
        int.TryParse(areaID, out _areaID);

        APUsersDO userDO = new APUsersDO();
        if (_id > 0)
        {
            userDO = APUserManager.GetUserByID(_id);
            userDO.LastModifiedTime = DateTime.Now;
            userDO.LastModifiedUserID = WebSiteContext.CurrentUserID;
        }
        else 
        {
            userDO.Password = password;
            userDO.CreateTime = DateTime.Now;
            userDO.CreateUserID = WebSiteContext.CurrentUserID;
        }

        bool bExisting = APUserManager.CheckLoginNameExisting(loginName, _id);
        if (bExisting == true) 
        {
            HttpContext.Current.Response.ContentType = "text/plain";
            HttpContext.Current.Response.Write("-1");
            return;
        }

        userDO.RoleID = _roleID;
        userDO.UserName = userName;
        userDO.LoginName = loginName;
        userDO.GroupID = _groupID;
        userDO.Email = email;
        userDO.Status = _statusID;

        if (_roleID == (int)Enums.UserType.区控 ||
            _roleID == (int)Enums.UserType.执行督导 ||
            _roleID == (int)Enums.UserType.访问员) 
        {
            userDO.AreaID = _areaID;
            userDO.Province = province;
            userDO.City = city;
            userDO.District = district;
        }

        if (_id > 0)
        {
            if (_statusID != (int)Enums.UserStatus.删除)
            {
                userDO.DeleteFlag = false;
            }
            BusinessLogicBase.Default.Update(userDO);
        }
        else
        {
            _id = BusinessLogicBase.Default.Insert(userDO);
        }
        string jsonResult = _id.ToString();
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void LoginClientUser()
    {
        string userName = HttpContext.Current.Request.Params["username"];
        string password = HttpContext.Current.Request.Params["pwd"];
        string projectID = HttpContext.Current.Request.Params["projectID"];
        int _projectID = 0;
        int.TryParse(projectID, out _projectID);
        APUsersDO userDO = APUserManager.TryLoginClientUser(userName, password, _projectID);
        
        string jsonResult = "0";
        string firstpage = string.Empty;
        if (userDO != null && userDO.ID > 0)
        {
            int clientID = userDO.ClientID;
            int topClientID = APClientManager.GetTopClientID(_projectID);
            //success
            bool checkInAppealPeriod = true;
            if (clientID != topClientID)
            {
                //非最高级别客户账号才需要验证是否在申诉期内
                checkInAppealPeriod = APUserManager.CheckIsInAppealPeriod(DateTime.Now, _projectID);
            }
            if (checkInAppealPeriod == false)
            {
                jsonResult = "3";
            }
            else if (userDO.Status == (int)Enums.UserStatus.停用)
            {
                jsonResult = "2";
            }
            else
            {
                jsonResult = "1"; 
                userDO.LastLoginIP = CommonFunction.GetHostAddress();
                userDO.LastLoginTime = DateTime.Now;
                BusinessLogicBase.Default.Update(userDO);
                WebSiteContext.Current.CurrentUser = userDO;

                int roleID = userDO.RoleID;
                if (userDO.ProjectID > 0)
                {
                    APProjectsDO projectDO = APProjectManager.GetProjectByID(userDO.ProjectID);
                    WebSiteContext.Current.CurrentProject = projectDO;
                }

                APUserRoleDO roleDO = new APUserRoleDO();
                roleDO = (APUserRoleDO)BusinessLogicBase.Default.Select(roleDO, roleID);
                if (roleDO.ID > 0)
                {
                    firstpage = roleDO.FirstPage;
                }
                //Diego added at 2019-4-3
                APClientsDO clientDO = APClientManager.GetClientDOByID(clientID);
                int minLevelID = APClientManager.GetClientMinLevel(WebSiteContext.CurrentProjectID);
                if (roleID == (int)Enums.UserType.客户 && clientDO.LevelID == minLevelID)
                {
                    //总行账号
                    firstpage = "QuestionnaireCheckListClient3.htm";
                }

                if (HttpContext.Current.Request.Cookies["UserType_C"] == null)
                {
                    HttpCookie cookie = new HttpCookie("UserType_C");
                    cookie.Value = roleID.ToString();
                    cookie.Expires = DateTime.Now.AddDays(1);
                    HttpContext.Current.Response.AppendCookie(cookie);
                }
                else
                {
                    HttpContext.Current.Response.Cookies["UserType_C"].Value = roleID.ToString();
                    HttpContext.Current.Response.Cookies["UserType_C"].Expires = DateTime.Now.AddDays(1);
                }
                
                int groupID = WebSiteContext.Current.CurrentProject.GroupID;
                if (HttpContext.Current.Request.Cookies["GroupID_C"] == null)
                {
                    HttpCookie cookie = new HttpCookie("GroupID_C");
                    cookie.Value = groupID.ToString();
                    cookie.Expires = DateTime.Now.AddDays(1);
                    HttpContext.Current.Response.AppendCookie(cookie);
                }
                else
                {
                    HttpContext.Current.Response.Cookies["GroupID_C"].Value = groupID.ToString();
                    HttpContext.Current.Response.Cookies["GroupID_C"].Expires = DateTime.Now.AddDays(1);
                }
            }
        }
        else
        {
            //failed
            jsonResult = "0";
        }
        string result = "{\"Result\":\"" + jsonResult + "\",\"FirstPage\":\"" + firstpage + "\"}";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(result);
    }
    
    public void DoLogin() 
    {
        string userName = HttpContext.Current.Request.Params["username"];
        string password = HttpContext.Current.Request.Params["pwd"];
        string clientCode = HttpContext.Current.Request.Params["clientCode"];
        string mobile = HttpContext.Current.Request.Params["mobile"];
        
        //string randCode = HttpContext.Current.Request.Params["randCode"];
        //if (string.IsNullOrEmpty(randCode) == false) 
        //{
        //    string codeInServer = HttpContext.Current.Session[Constants.LoginRandCode].ToString();
        //    if (codeInServer.ToLower() != randCode.ToLower())
        //    {
        //        string resultError = "{\"Result\":\"3\",\"FirstPage\":\"\"}";
        //        HttpContext.Current.Response.ContentType = "application/json";
        //        HttpContext.Current.Response.Write(resultError);
        //        return;
        //    }
        //}
        
        APUsersDO userDO = APUserManager.TryLoginUser(userName, password);
        string jsonResult = "0";
        string firstpage = string.Empty;
        if (userDO != null && userDO.ID > 0)
        {
            //success
            jsonResult = "1";
            if (userDO.Status == (int)Enums.UserStatus.停用)
            {
                jsonResult = "2";
            }
            else
            {             
                userDO.LastLoginIP = CommonFunction.GetHostAddress();
                userDO.LastLoginTime = DateTime.Now;
                BusinessLogicBase.Default.Update(userDO);
                WebSiteContext.Current.CurrentUser = userDO;

                int roleID = userDO.RoleID;
                if (userDO.ProjectID > 0)
                {
                    int projectID = userDO.ProjectID;
                    APProjectsDO projectDO = APProjectManager.GetProjectByID(projectID);
                    WebSiteContext.Current.CurrentProject = projectDO;
                }

                APUserRoleDO roleDO = new APUserRoleDO();
                roleDO = (APUserRoleDO)BusinessLogicBase.Default.Select(roleDO, roleID);
                if (roleDO.ID > 0)
                {
                    firstpage = roleDO.FirstPage;
                }

                if (HttpContext.Current.Request.Cookies["UserType_C"] == null)
                {
                    HttpCookie cookie = new HttpCookie("UserType_C");
                    cookie.Value = roleID.ToString();
                    cookie.Expires = DateTime.Now.AddDays(1);
                    HttpContext.Current.Response.AppendCookie(cookie);
                }
                else
                {
                    HttpContext.Current.Response.Cookies["UserType_C"].Value = roleID.ToString();
                    HttpContext.Current.Response.Cookies["UserType_C"].Expires = DateTime.Now.AddDays(1);
                }
            }
        }
        else
        {
            //failed
            jsonResult = "0";
        }
        //only works for mobile
        if (jsonResult == "1" && mobile == "1") {
            if (userDO.RoleID != (int)Enums.UserType.访问员)
            {
                jsonResult = "-1";
            }
        }
        //only works for visitor
        if (jsonResult == "1" && clientCode != null && clientCode != "")
        {
            if (userDO.RoleID != (int)Enums.UserType.访问员)
            {
                jsonResult = "-1";
            }
            else
            {
                string projectID = HttpContext.Current.Request.Params["projectID"];
                int _projectID = 0;
                int.TryParse(projectID, out _projectID);

                int clientID = APClientManager.GetDeliveryClientID(clientCode, _projectID, userDO.ID);
                if (clientID > 0)
                {

                    WebSiteContext.CurrentClientID = clientID;
                    APProjectsDO apDO = APProjectManager.GetProjectByID(_projectID);
                    WebSiteContext.Current.CurrentProject = apDO;
                    firstpage = "QuestionnaireUL.htm";

                    if (HttpContext.Current.Request.Cookies["ClientID_V"] == null)
                    {
                        HttpCookie cookie = new HttpCookie("ClientID_V");
                        cookie.Value = clientID.ToString();
                        cookie.Expires = DateTime.Now.AddDays(1);
                        HttpContext.Current.Response.AppendCookie(cookie);
                    }
                    else
                    {
                        HttpContext.Current.Response.Cookies["ClientID_V"].Value = clientID.ToString();
                        HttpContext.Current.Response.Cookies["ClientID_V"].Expires = DateTime.Now.AddDays(1);
                    }

                    if (HttpContext.Current.Request.Cookies["ProjectID_V"] == null)
                    {
                        HttpCookie cookie = new HttpCookie("ProjectID_V");
                        cookie.Value = _projectID.ToString();
                        cookie.Expires = DateTime.Now.AddDays(1);
                        HttpContext.Current.Response.AppendCookie(cookie);
                    }
                    else
                    {
                        HttpContext.Current.Response.Cookies["ProjectID_V"].Value = _projectID.ToString();
                        HttpContext.Current.Response.Cookies["ProjectID_V"].Expires = DateTime.Now.AddDays(1);
                    }
                }
                else
                {
                    APClientsDO clientDO = APClientManager.GetClientByCode(clientCode, _projectID);
                    if (clientDO != null && clientDO.ID > 0)
                    {
                        //登录失败，未分配该网点给当前用户，请与上级或管理员确认后再尝试。
                        jsonResult = "-2";
                    }
                    else
                    {
                        //登录失败
                        jsonResult = "-1";
                    }
                }
            }
        }
        else 
        {
            if (HttpContext.Current.Request.Cookies["ClientID_V"] != null)
            {
                HttpCookie cookie = HttpContext.Current.Request.Cookies["ClientID_V"];
                cookie.Expires = DateTime.Now.AddDays(-2);
                HttpContext.Current.Response.Cookies.Set(cookie);
            }
            if (HttpContext.Current.Request.Cookies["ProjectID_V"] != null)
            {
                HttpCookie cookie = HttpContext.Current.Request.Cookies["ProjectID_V"];
                cookie.Expires = DateTime.Now.AddDays(-2);
                HttpContext.Current.Response.Cookies.Set(cookie);
            }
        }
        string result = "{\"Result\":\"" + jsonResult + "\",\"FirstPage\":\"" + firstpage + "\"}";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(result);
    }

    public void SearchUsers()
    {
        string jsonResult = string.Empty;
        string name = HttpContext.Current.Request.QueryString["Name"];
        string province = HttpContext.Current.Request.QueryString["Province"];
        string city = HttpContext.Current.Request.QueryString["City"];
        string district = HttpContext.Current.Request.QueryString["District"];
        string roleID = HttpContext.Current.Request.QueryString["RoleID"];
        int _roleID = 0;
        int.TryParse(roleID, out _roleID);
        DataTable dt = APUserManager.SearchUsers(name, province, city,district, _roleID);
       
        jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetAllUsers()
    {
        string jsonResult = string.Empty;
        string name = HttpContext.Current.Request.QueryString["name"];
        string province = HttpContext.Current.Request.QueryString["province"];
        string city = HttpContext.Current.Request.QueryString["city"];
        string district = HttpContext.Current.Request.QueryString["district"];
        string roleID = HttpContext.Current.Request.QueryString["roleID"];
        string statusID = HttpContext.Current.Request.QueryString["statusID"];
        string period = HttpContext.Current.Request.QueryString["period"];
        
        int _roleID = 0;
        int.TryParse(roleID, out _roleID);
        int _statusID = 0;
        int.TryParse(statusID, out _statusID);
        DateTime fromDate = Constants.Date_Min;
        DateTime toDate = Constants.Date_Max;
        if (!string.IsNullOrEmpty(period) && period != "-999")
        {
            string strFrom = period.Split('|')[0];
            string strTo = period.Split('|')[1];
            DateTime.TryParse(strFrom, out fromDate);
            DateTime.TryParse(strTo, out toDate);
            toDate = toDate.AddDays(1);
        }
        int currentUserID = WebSiteContext.CurrentUserID;
        int currentUserType = WebSiteContext.Current.CurrentUser.RoleID;
        DataTable dt = APUserManager.SearchUsers(name, _roleID, fromDate, toDate, province, city, district, _statusID, currentUserID, currentUserType);
        if (dt != null)
        {
            if (_roleID != (int)Enums.UserType.客户 && currentUserType != (int)Enums.UserType.客户)
            {
                DataView dv = dt.DefaultView;
                dv.RowFilter = "RoleID<>9";
                dt = dv.ToTable();
            }

            if (currentUserType == (int)Enums.UserType.执行督导) 
            {

                DataView dv = dt.DefaultView;
                dv.RowFilter = "CreateUserID=" + currentUserID;
                dt = dv.ToTable();
            }
        }
        
        jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void GetAllProjectUsers() 
    {
        string jsonResult = string.Empty;
        string name = HttpContext.Current.Request.QueryString["name"];
        string province = HttpContext.Current.Request.QueryString["Province"];
        string city = HttpContext.Current.Request.QueryString["City"];
        string district = HttpContext.Current.Request.QueryString["District"];
        string roleID = HttpContext.Current.Request.QueryString["RoleID"];

        int _roleID = 0;
        int.TryParse(roleID, out _roleID);
        int currentUserID = WebSiteContext.CurrentUserID;
        int currentUserType = WebSiteContext.Current.CurrentUser.RoleID;
        int projectID = WebSiteContext.CurrentProjectID;
        DataTable dt = APUserManager.SearchProjectUsers(projectID, name, province, city, district, _roleID, currentUserID, currentUserType);
        jsonResult = JSONHelper.DataTableToJSON(dt);
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void DownloadAllProjectUsers()
    {
        string name = HttpContext.Current.Request.QueryString["name"];
        string province = HttpContext.Current.Request.QueryString["province"];
        string city = HttpContext.Current.Request.QueryString["city"];
        string district = HttpContext.Current.Request.QueryString["district"];
        string roleID = HttpContext.Current.Request.QueryString["roleID"];

        int _roleID = 0;
        int.TryParse(roleID, out _roleID);
        int currentUserID = WebSiteContext.CurrentUserID;
        int currentUserType = WebSiteContext.Current.CurrentUser.RoleID;
        int projectID = WebSiteContext.CurrentProjectID;
        DataTable dt = APUserManager.SearchProjectUsers(projectID, name, province, city, district, _roleID, currentUserID, currentUserType);
        //jsonResult = JSONHelper.DataTableToJSON(dt);
        DataTable dtOutput = new DataTable();
        dtOutput.TableName = "人员列表";
        dtOutput.Columns.Add("编号", typeof(string));
        dtOutput.Columns.Add("账号", typeof(string));
        dtOutput.Columns.Add("姓名", typeof(string));
        dtOutput.Columns.Add("角色", typeof(string));
        dtOutput.Columns.Add("创建时间", typeof(string));
        dtOutput.Columns.Add("状态", typeof(string));
        if (dt != null && dt.Rows.Count > 0)
        {
            foreach (DataRow row in dt.Rows)
            {
                DataRow newRow = dtOutput.NewRow();
                newRow["编号"] = row["ID"].ToString();
                newRow["账号"] = row["LoginName"].ToString();
                newRow["姓名"] = row["UserName"].ToString();
                newRow["角色"] = row["RoleName"].ToString();
                newRow["创建时间"] = row["CreateTime"].ToString();
                newRow["状态"] = row["StatusName"].ToString();
                dtOutput.Rows.Add(newRow);
            }
        }

        DataSet ds = new DataSet();
        ds.Tables.Add(dtOutput.Copy());
        string fileName = string.Format("项目人员列表_{0:yyyyMMddHHmmss}.xlsx", DateTime.Now);
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

    public void DownloadAllUsers()
    {
        string name = HttpContext.Current.Request.QueryString["name"];
        string province = HttpContext.Current.Request.QueryString["province"];
        string city = HttpContext.Current.Request.QueryString["city"];
        string district = HttpContext.Current.Request.QueryString["district"];
        string roleID = HttpContext.Current.Request.QueryString["roleID"];
        string statusID = HttpContext.Current.Request.QueryString["statusID"];
        string period = HttpContext.Current.Request.QueryString["period"];
        
        int _roleID = 0;
        int.TryParse(roleID, out _roleID);
        int _statusID = 0;
        int.TryParse(statusID, out _statusID);
        DateTime fromDate = Constants.Date_Min;
        DateTime toDate = Constants.Date_Max;
        if (!string.IsNullOrEmpty(period) && period != "-999")
        {
            string strFrom = period.Split('|')[0];
            string strTo = period.Split('|')[1];
            DateTime.TryParse(strFrom, out fromDate);
            DateTime.TryParse(strTo, out toDate);
            toDate = toDate.AddDays(1);
        }
        int currentUserID = WebSiteContext.CurrentUserID;
        int currentUserType = WebSiteContext.Current.CurrentUser.RoleID;
        DataTable dt = APUserManager.SearchUsers(name, _roleID, fromDate, toDate, province, city, district, _statusID,currentUserID, currentUserType);
        if (_roleID != (int)Enums.UserType.客户 && currentUserType != (int)Enums.UserType.客户)
        {
            DataView dv = dt.DefaultView;
            dv.RowFilter = "RoleID<>9";
            dt = dv.ToTable();
        }

        if (currentUserType == (int)Enums.UserType.执行督导)
        {

            DataView dv = dt.DefaultView;
            dv.RowFilter = "CreateUserID=" + currentUserID;
            dt = dv.ToTable();
        }
        //jsonResult = JSONHelper.DataTableToJSON(dt);
        DataTable dtOutput = new DataTable();
        dtOutput.TableName = "人员列表";
        dtOutput.Columns.Add("编号", typeof(string));
        dtOutput.Columns.Add("账号", typeof(string));
        dtOutput.Columns.Add("姓名", typeof(string));
        if (currentUserType == (int)Enums.UserType.客户)
        {
            dtOutput.Columns.Add("级别", typeof(string));
        }
        else
        {
            dtOutput.Columns.Add("角色", typeof(string));
        }
        dtOutput.Columns.Add("创建时间", typeof(string));
        dtOutput.Columns.Add("状态", typeof(string));
        if (dt != null && dt.Rows.Count > 0)
        {
            foreach (DataRow row in dt.Rows)
            {
                DataRow newRow = dtOutput.NewRow();
                newRow["编号"] = row["ID"].ToString();
                newRow["账号"] = row["LoginName"].ToString();
                newRow["姓名"] = row["UserName"].ToString();
                if (currentUserType == (int)Enums.UserType.客户)
                {
                    newRow["级别"] = row["LevelName"].ToString();
                }
                else
                {
                    newRow["角色"] = row["RoleName"].ToString();
                }
                newRow["创建时间"] = row["CreateTime"].ToString();
                newRow["状态"] = row["StatusName"].ToString();
                dtOutput.Rows.Add(newRow);
            }
            List<string> fixedColumnNames = new List<string>();
            fixedColumnNames.Add("编号");
            fixedColumnNames.Add("账号");
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
        string fileName = string.Format("人员列表_{0:yyyyMMddHHmmss}.xlsx", DateTime.Now);
        string folderRelevantPath = Constants.RelevantTempPath;
        string folderPath = HttpContext.Current.Server.MapPath(folderRelevantPath);
        if (System.IO.Directory.Exists(folderPath) == false)
        {
            System.IO.Directory.CreateDirectory(folderPath);
        }
        //CommonFunction.ClearAllFilesUnderFolder(folderPath);
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

    public void QuitSystem()
    {
        string jsonResult = "1";
        if (WebSiteContext.CurrentClientID > 0)
        {
            if (WebSiteContext.Current.CurrentUser.RoleID == (int)Enums.UserType.访问员)
            {
                APClientsDO clientDO = APClientManager.GetClientDOByID(WebSiteContext.CurrentClientID);
                jsonResult = "VLogin.htm?p=" + clientDO.ProjectID;
            }
        }
        if (WebSiteContext.Current.CurrentUser.RoleID == (int)Enums.UserType.客户)
        {
            if (WebSiteContext.Current.CurrentProject.GroupID > 0)
            {
                jsonResult = "CLogin.htm?g=" + WebSiteContext.Current.CurrentProject.GroupID;
            }
            else
            {
                jsonResult = "CLogin.htm";
            }
        }
        WebSiteContext.Current.ClearSession();
        HttpContext.Current.Response.ContentType = "text/plain";
        HttpContext.Current.Response.Write(jsonResult);
    }

    public void LoadLoginUser() 
    {
        int userType = 0;
        string userName = WebSiteContext.CurrentUserName;
        if (string.IsNullOrEmpty(userName) == false) 
        {
            userType = WebSiteContext.Current.CurrentUser.RoleID;
        }
        string clientID = int.MinValue.ToString();
        if (HttpContext.Current.Request.Cookies["ClientID_V"] != null)
        {
            clientID = HttpContext.Current.Request.Cookies["ClientID_V"].Value;
        }
        string projectID = int.MinValue.ToString();
        if (HttpContext.Current.Request.Cookies["ProjectID_V"] != null)
        {
            projectID = HttpContext.Current.Request.Cookies["ProjectID_V"].Value;
        }
        string oldUserType = int.MinValue.ToString();
        if (HttpContext.Current.Request.Cookies["UserType_C"] != null)
        {
            oldUserType = HttpContext.Current.Request.Cookies["UserType_C"].Value;
        }
        string groupID = "0";
        if (HttpContext.Current.Request.Cookies["GroupID_C"] != null)
        {
            groupID = HttpContext.Current.Request.Cookies["GroupID_C"].Value;
        }
        string result = "{\"ID\":" + WebSiteContext.CurrentUserID + ",\"UserName\":\"" + userName + "\",\"UserType\":" + userType + ",\"ClientID\":" + clientID + ",\"OldUserType\":" + oldUserType + ",\"OldGroupID\":" + groupID + ",\"ProjectID\":" + projectID + "}";
        HttpContext.Current.Response.ContentType = "application/json";
        HttpContext.Current.Response.Write(result);
    }
    
    public bool IsReusable {
        get {
            return false;
        }
    }

}