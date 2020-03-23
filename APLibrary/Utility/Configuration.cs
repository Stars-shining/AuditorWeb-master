using System;
using System.Data;
using System.Xml;
using System.Data.SqlClient;
using System.Collections;
using System.Configuration;
using System.Collections.Generic;


namespace APLibrary
{
	/// <summary>
	/// The SqlHelper class is intended to encapsulate high performance, scalable best practices for 
	/// common uses of SqlClient
	/// </summary>
	public sealed class BusinessConfigurationManager
	{
        private BusinessConfigurationManager() { }
        
        #region Configuration Item
        public static DataTable GetAllConfiguations()
        {
            string sql = "select itemkey as [ID],itemvalue as [Name],itemdesc,ItemOrder from BusinessConfiguration with(nolock)";
            BusinessLogicBase manager = new BusinessLogicBase();
            return manager.Select(sql);            
        }
        /// <summary>
        /// including all provinces, cities, districts
        /// </summary>
        /// <returns></returns>
        public static DataTable GetAllDistricts()
        {
            string sql = "select ID,Code,Name,Level,AreaID,bDirectCity from APCity with(nolock) order by Code";
            BusinessLogicBase manager = new BusinessLogicBase();
            return manager.Select(sql);
        }

        public static DataTable GetProvinces(int areaID)
        {
            DataTable dt = AppCache.dtCity;
            DataView dv = dt.DefaultView;
            string rowfilter = "level = 1";
            dv.RowFilter = rowfilter;
            dt = dv.ToTable();
            if (areaID > 0)
            {
                dv = dt.DefaultView;
                rowfilter = "areaID = " + areaID;
                dv.RowFilter = rowfilter;
                dt = dv.ToTable();
            }
            return dt;
        }

        public static DataTable GetCities(string provinceCode)
        {
            string code = provinceCode.Substring(0, 2);
            DataTable dt = AppCache.dtCity;
            DataView dv = dt.DefaultView;
            string rowfilter = "level = 2 and Code like '" + code + "%'";
            dv.RowFilter = rowfilter;
            dt = dv.ToTable();
            return dt;
        }

        public static DataTable GetDistricts(string cityCode)
        {
            string code = cityCode.Substring(0, 4);
            DataTable dt = AppCache.dtCity;
            DataView dv = dt.DefaultView;
            string rowfilter = "level = 3 and Code like '" + code + "%'";
            dv.RowFilter = rowfilter;
            dt = dv.ToTable();
            return dt;
        }

        public static DataTable GetDictListByDesc(string desc)
        {           
            DataTable dt = AppCache.dtConfiguration;
            DataView dv = dt.DefaultView;
            string rowfilter = "itemdesc = '{0}'";
            rowfilter  =string.Format(rowfilter,desc);
            dv.RowFilter = rowfilter;
            return dv.ToTable();
        }

        public static int GetItemKeyByItemValue(string value, string desc)
        {
            int key = 0;
            DataTable dt = AppCache.dtConfiguration;
            DataView dv = dt.DefaultView;
            string rowfilter = "itemdesc='{0}' and Name='{1}'";
            rowfilter = string.Format(rowfilter, desc, value);
            dv.RowFilter = rowfilter;
            DataTable dtTemp = dv.ToTable();
            if (dtTemp != null && dtTemp.Rows.Count > 0)
            {
                int.TryParse(dtTemp.Rows[0]["ID"].ToString(), out key);
            }
            return key;
        }
        public static string GetItemValueByItemKey(int key, string desc)
        {
            string value = "";
            DataTable dt = AppCache.dtConfiguration;
            DataView dv = dt.DefaultView;
            string rowfilter = "itemdesc='{0}' and ID={1}";
            rowfilter = string.Format(rowfilter, desc, key);
            dv.RowFilter = rowfilter;
            DataTable dtTemp = dv.ToTable();
            if (dtTemp != null && dtTemp.Rows.Count > 0)
            {
                value = dtTemp.Rows[0]["Name"].ToString();
            }
            return value;
        }
        /// <summary>
        /// Get configuration item as integer value
        /// </summary>
        /// <param name="name"></param>
        /// <returns></returns>
        public static int GetConfigurationItemInt(string name)
        {
            string value = GetConfigurationItemString(name);
            int intvalue = int.MinValue;

            int.TryParse(value, out intvalue);

            if (intvalue == int.MinValue) 
            {
                throw new Exception("Value not defined Exception");
            }

            return intvalue;
        }

        /// <summary>
        /// Get Configuration Item as DateTime value
        /// </summary>
        /// <param name="name"></param>
        /// <returns></returns>
        public static DateTime GetConfigurationItemDateTime(string name)
        {
            string value = GetConfigurationItemString(name);
            DateTime datevalue = DateTime.MinValue;

            DateTime.TryParse(value, out datevalue);

            if (datevalue == DateTime.MinValue)
            {
                throw new Exception("Value not defined Exception");
            }

            return datevalue;
        }

        /// <summary>
        /// Get Configuration Item as String value
        /// </summary>
        /// <param name="name"></param>
        /// <returns></returns>
        public static string GetConfigurationItemString(string name) 
        {
            DataTable dt = AppCache.dtConfiguration;
            string rowfilter = "name = '{0}'";
            rowfilter  =string.Format(rowfilter,name);
            DataRow[] drs = dt.Select(rowfilter);

            if (drs != null && drs.Length > 0)
            {
                return drs[0][1].ToString();
            }
            else 
            {
                return string.Empty;
            }
        }

        /// <summary>
        /// Get Configuration Item as Decimal Value
        /// </summary>
        /// <param name="name"></param>
        /// <returns></returns>
        public static decimal GetConfigurationItemDecimal(string name) 
        {
            string value = GetConfigurationItemString(name);
            decimal decimalvalue = decimal.MinValue;

            decimal.TryParse(value, out decimalvalue);

            if (decimalvalue == decimal.MinValue)
            {
                throw new Exception("Value not defined Exception");
            }

            return decimalvalue;
        }

        public static Dictionary<string, string> GetAllDataColumnMappings(string tableName) 
        {
            Dictionary<string, string> mappings = new Dictionary<string, string>();
            DataTable dt = BusinessLogicBase.Default.Select("select * from DataColumnMappings where tableName='" + tableName + "'");
            if (dt != null && dt.Rows.Count > 0) 
            {
                foreach (DataRow row in dt.Rows) 
                {
                    string dataName = row["DataName"].ToString();
                    string columnName = row["ColumnName"].ToString();
                    mappings.Add(columnName, dataName);
                }
            }
            
            return mappings;
        }
        #endregion

        #region AppSettings

        public static string GetAppSettings(string key)
        {
            string value = ConfigurationManager.AppSettings[key];
            return value;
        }

        //Integer
        public static int GetAppSettingInt(string key)
        {
            int value = 0;
            string str = GetAppSettings(key);
            int.TryParse(str,out value);
            return value;
        }

        //Datetime
        public static DateTime GetAppSettingDatetime(string key)
        {
            DateTime value = Constants.Date_Min;
            string str = GetAppSettings(key);
            DateTime.TryParse(str, out value);
            return value;
        }

        //String
        public static string GetAppSettingString(string key)
        {
            string str = GetAppSettings(key);
            return str;
        }

        //Decimal
        public static decimal GetAppSettingDecimal(string key)
        {
            decimal value = 0;
            string str = GetAppSettings(key);
            decimal.TryParse(str, out value);
            return value;
        }
        #endregion

        #region Private Configuration method

        #region GetBoolValueByItemDesc
        private static bool GetBoolValueByItemDesc(string desc)
        {
            bool rtn = false;

            DataTable dt = BusinessConfigurationManager.GetDictListByDesc(desc);
            if (dt == null || dt.Rows.Count == 0)
            {
                rtn = false;
            }
            else
            {
                int itemvalue = int.Parse(dt.Rows[0]["id"].ToString());
                rtn = itemvalue == 1 ? true : false;

            }
            return rtn;
        }
        #endregion

        #endregion
    }
}
