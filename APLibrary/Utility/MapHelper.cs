using System;
using System.Data;
using System.Data.SqlClient;
using System.Configuration;
using System.Web;
using System.Web.Security;

using System.Globalization;
using System.Collections.Generic;
using System.Reflection;
using System.IO;
using System.Collections;
using System.Text;
using System.Text.RegularExpressions;
using System.Linq;
using System.Net;
using System.Web.Script.Serialization;


namespace APLibrary
{
    public class MapHelper
    {
        public static double pi = 3.1415926535897932384626;
        public static double a = 6378245.0;
        public static double ee = 0.00669342162296594323;
        private static double bd_pi = 3.14159265358979324 * 3000.0 / 180.0;

        public static LocateInfo wgs84_To_Gcj02(double lat, double lon)
        {
            LocateInfo info = new LocateInfo();
            if (outOfChina(lat, lon))
            {
                info.IsChina = false;
                info.Latitude = lat;
                info.Longitude = lon;
            }
            else
            {
                double dLat = transformLat(lon - 105.0, lat - 35.0);
                double dLon = transformLon(lon - 105.0, lat - 35.0);
                double radLat = lat / 180.0 * pi;
                double magic = Math.Sin(radLat);
                magic = 1 - ee * magic * magic;
                double SqrtMagic = Math.Sqrt(magic);
                dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * SqrtMagic) * pi);
                dLon = (dLon * 180.0) / (a / SqrtMagic * Math.Cos(radLat) * pi);
                double mgLat = lat + dLat;
                double mgLon = lon + dLon;
                info.IsChina = true;
                info.Latitude = mgLat;
                info.Longitude = mgLon;
            }
            return info;
        }

        public static LocateInfo gcj02_To_Wgs84(double lat, double lon)
        {
            LocateInfo info = new LocateInfo();
            LocateInfo gps = transform(lat, lon);
            double lontitude = lon * 2 - gps.Longitude;
            double latitude = lat * 2 - gps.Latitude;

            info.IsChina = gps.IsChina;
            info.Latitude = latitude;
            info.Longitude = lontitude;
            return info;
        }

        public static LocateInfo wgs84_To_Bd(double lat, double lon) 
        {
            string path = "http://api.map.baidu.com/ag/coord/convert?from=0&to=4&x=" + lon + "&y=" + lat + "";
            HttpWebRequest webRequest = (HttpWebRequest)WebRequest.Create(path);
            webRequest.Method = "GET";
            HttpWebResponse webResponse = (HttpWebResponse)webRequest.GetResponse();
            StreamReader sr = new StreamReader(webResponse.GetResponseStream(), Encoding.UTF8);
            string strJson = sr.ReadToEnd();
            JavaScriptSerializer js = new JavaScriptSerializer();
            MapConvert mc = js.Deserialize<MapConvert>(strJson);
            LocateInfo info = new LocateInfo();
            if (mc.error == "0")
            {
                //进行Base64解码
                byte[] xBuffer = Convert.FromBase64String(mc.x);
                string strX = Encoding.UTF8.GetString(xBuffer, 0, xBuffer.Length);

                byte[] yBuffer = Convert.FromBase64String(mc.y);
                string strY = Encoding.UTF8.GetString(yBuffer, 0, yBuffer.Length);

                info.Longitude = strX.ToDouble(0);
                info.Latitude = strY.ToDouble(0);
            }
            return info;
        }

        public static LocateInfo gcj02_To_Bd09(double lat, double lon)
        {
            double x = lon, y =lat;
            double z = Math.Sqrt(x * x + y * y) + 0.00002 * Math.Sin(y * bd_pi);
            double theta = Math.Atan2(y, x) + 0.000003 * Math.Cos(x * bd_pi);
            double bd_lon = z * Math.Cos(theta) + 0.0065;
            double bd_lat = z * Math.Sin(theta) + 0.006;
            return new LocateInfo(bd_lon, bd_lat);
        }

        public static LocateInfo bd09_To_Gcj02(double lat, double lon)
        {
            double x = lon - 0.0065, y = lat - 0.006;
            double z = Math.Sqrt(x * x + y * y) - 0.00002 * Math.Sin(y * bd_pi);
            double theta = Math.Atan2(y, x) - 0.000003 * Math.Cos(x * bd_pi);
            double gg_lon = z * Math.Cos(theta);
            double gg_lat = z * Math.Sin(theta);
            return new LocateInfo(gg_lon, gg_lat);
        }

        private static bool outOfChina(double lat, double lon)
        {
            if (lon < 72.004 || lon > 137.8347)
                return true;
            if (lat < 0.8293 || lat > 55.8271)
                return true;
            return false;
        }

        private static double transformLat(double x, double y)
        {
            double ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y
            + 0.2 * Math.Sqrt(Math.Abs(x));
            ret += (20.0 * Math.Sin(6.0 * x * pi) + 20.0 * Math.Sin(2.0 * x * pi)) * 2.0 / 3.0;
            ret += (20.0 * Math.Sin(y * pi) + 40.0 * Math.Sin(y / 3.0 * pi)) * 2.0 / 3.0;
            ret += (160.0 * Math.Sin(y / 12.0 * pi) + 320 * Math.Sin(y * pi / 30.0)) * 2.0 / 3.0;
            return ret;
        }

        private static double transformLon(double x, double y)
        {
            double ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1
            * Math.Sqrt(Math.Abs(x));
            ret += (20.0 * Math.Sin(6.0 * x * pi) + 20.0 * Math.Sin(2.0 * x * pi)) * 2.0 / 3.0;
            ret += (20.0 * Math.Sin(x * pi) + 40.0 * Math.Sin(x / 3.0 * pi)) * 2.0 / 3.0;
            ret += (150.0 * Math.Sin(x / 12.0 * pi) + 300.0 * Math.Sin(x / 30.0 * pi)) * 2.0 / 3.0;
            return ret;
        }

        private static LocateInfo transform(double lat, double lon)
        {
            LocateInfo info = new LocateInfo();
            if (outOfChina(lat, lon))
            {
                info.IsChina = false;
                info.Latitude = lat;
                info.Longitude = lon;
                return info;
            }
            double dLat = transformLat(lon - 105.0, lat - 35.0);
            double dLon = transformLon(lon - 105.0, lat - 35.0);
            double radLat = lat / 180.0 * pi;
            double magic = Math.Sin(radLat);
            magic = 1 - ee * magic * magic;
            double SqrtMagic = Math.Sqrt(magic);
            dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * SqrtMagic) * pi);
            dLon = (dLon * 180.0) / (a / SqrtMagic * Math.Cos(radLat) * pi);
            double mgLat = lat + dLat;
            double mgLon = lon + dLon;
            info.IsChina = true;
            info.Latitude = mgLat;
            info.Longitude = mgLon;
            return info;
        }

        private const double EARTH_RADIUS = 6378137;
        /// <summary>
        /// 计算两点位置的距离，返回两点的距离，单位 米
        /// 该公式为GOOGLE提供，误差小于0.2米
        /// </summary>
        /// <param name="lat1">第一点纬度</param>
        /// <param name="lng1">第一点经度</param>
        /// <param name="lat2">第二点纬度</param>
        /// <param name="lng2">第二点经度</param>
        /// <returns></returns>
        public static double GetDistance(double lat1, double lng1, double lat2, double lng2)
        {
            double radLat1 = Rad(lat1);
            double radLng1 = Rad(lng1);
            double radLat2 = Rad(lat2);
            double radLng2 = Rad(lng2);
            double a = radLat1 - radLat2;
            double b = radLng1 - radLng2;
            double result = 2 * Math.Asin(Math.Sqrt(Math.Pow(Math.Sin(a / 2), 2) + Math.Cos(radLat1) * Math.Cos(radLat2) * Math.Pow(Math.Sin(b / 2), 2))) * EARTH_RADIUS;
            return result;
        }

        /// <summary>
        /// 经纬度转化成弧度
        /// </summary>
        /// <param name="d"></param>
        /// <returns></returns>
        private static double Rad(double d)
        {
            return (double)d * Math.PI / 180d;
        }
    }

    public class MapConvert
    {
        public string error { get; set; }
        public string x { get; set; }
        public string y { get; set; }
    }

    public class LocateInfo
    {
        public double Longitude{ get; set; }
        public double Latitude { get; set; }
        public bool IsChina { get; set; }

        public LocateInfo() { }

        public LocateInfo(double longitude, double latitude)
        {
            this.Longitude = longitude;
            this.Latitude = latitude;
        }
    }

    public class GPSValication 
    {
        public int questionnaireID { get; set; }
        public int resultID { get; set; }
        public int questionID { get; set; }
        public double Longitude { get; set; }
        public double Latitude { get; set; }
    }
}