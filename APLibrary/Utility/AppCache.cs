using System;
using System.Data;
using System.Web.Caching;
using System.Collections.Generic;

namespace APLibrary
{
    /// <summary>
    /// Summary description for AppCache
    /// </summary>
    public class AppCache
    {
        public AppCache()
        {
            //
            // TODO: Add constructor logic here
            //
        }

        public static DataTable dtConfiguration
        {
            get
            {
                string key = "Cache:SRConfiguration";
                return GetConfiguration(key);
            }
        }

        public static DataTable GetConfiguration(string key)
        {
            if (System.Web.HttpContext.Current == null)
            {
                DataTable dt = BusinessConfigurationManager.GetAllConfiguations();
                return dt;
            }
            else if (System.Web.HttpContext.Current.Cache[key] == null)
            {
                DataTable dt = BusinessConfigurationManager.GetAllConfiguations();
                System.Web.HttpContext.Current.Cache.Insert(key, dt, null, DateTime.MaxValue, TimeSpan.FromDays(1), CacheItemPriority.Normal, null);
                return dt;
            }
            return System.Web.HttpContext.Current.Cache[key] as DataTable;
        }

        public static DataTable dtCity
        {
            get
            {
                string key = "Cache:dtCity";
                return GetCity(key);
            }
        }

        public static DataTable GetCity(string key)
        {
            if (System.Web.HttpContext.Current.Cache[key] == null)
            {
                DataTable dt = BusinessConfigurationManager.GetAllDistricts();
                System.Web.HttpContext.Current.Cache.Insert(key, dt, null, DateTime.MaxValue, TimeSpan.FromDays(1), CacheItemPriority.Normal, null);
                return dt;
            }
            return System.Web.HttpContext.Current.Cache[key] as DataTable;
        }
    }
}