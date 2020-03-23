
using System;
using System.Collections;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Linq.Expressions;
using System.Net;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Xml;
using System.Xml.Linq;
using System.Globalization;

namespace APLibrary
{
    /// <summary>
    /// 扩展
    /// </summary>

    public static class NameValueCollectionExtension
    {
        /// <summary>
        /// 将NameValueCollection转换成为字符串（key=value&key=value）
        /// </summary>
        /// <param name="collection">键值集合</param>
        /// <param name="excludes">需排除键</param>
        /// <param name="splitter">连接字符</param>
        /// <returns></returns>
        public static string ToStringSorted(this NameValueCollection collection, string[] excludekeys, string splitter = "&")
        {
            if (excludekeys != null && excludekeys.Length > 0)
            {
                excludekeys.AsQueryable().ToList().ForEach(e => collection.Remove(e));
            }
            Array.Sort(collection.AllKeys);
            return collection.ToStringJoin(splitter);
        }
        /// <summary>
        /// 将NameValueCollection转换成为字符串（key=value&key=value）
        /// </summary>
        /// <param name="collection">NameValueCollection</param>
        /// <returns></returns>
        public static string ToStringJoin(this NameValueCollection collection, string splitter = "&")
        {
            if (collection == null) return null;
            return string.Join(splitter, collection.ToStringArray());
        }
        /// <summary>
        /// 将键值集合转换成为字符串数组，格式为key=value
        /// </summary>
        /// <param name="collection"></param>
        /// <returns></returns>
        public static string[] ToStringArray(this NameValueCollection collection)
        {
            if (collection == null) return null;
            string[] arr = new string[collection.Count];
            for (int i = 0; i < arr.Length; i++)
            {
                arr[i] = collection.AllKeys[i] + "=" + collection.Get(i);
            }
            return arr;
        }
    }



    public static class StringExtension
    {
        /// <summary>
        /// 将标准的xml字符串反序列化为对象
        /// </summary>
        /// <typeparam name="TObject">对象类型</typeparam>
        /// <param name="xmlstr">xml字符串</param>
        /// <returns></returns>
        public static TObject ToObject<TObject>(this string xmlstr) where TObject : class
        {
            //var xmlReader = XmlReader.Create(new StringReader(xmlstr), new XmlReaderSettings { });
            //return (TObject)new XmlSerializer(typeof(TObject)).Deserialize(xmlReader);

            byte[] byteArray = Encoding.UTF8.GetBytes(xmlstr);
            MemoryStream stream = new MemoryStream(byteArray);
            System.Xml.Serialization.XmlSerializer xs = new System.Xml.Serialization.XmlSerializer(typeof(TObject));
            return xs.Deserialize(stream) as TObject;
        }
        public static string ToXmlFormatString(this string str, string nodeName)
        {
            if (string.IsNullOrEmpty(str)) return null;
            if (str.Contains("xmlns:xsi=") && str.Contains("xmlns:xsd=")) return str;
            int start = str.IndexOf(nodeName);
            StringBuilder sb = new StringBuilder();
            sb.AppendFormat("{0} xmlns=\"http://tempuri.org/{1}.xsd\"{2}", str.Substring(0, start + nodeName.Length), nodeName, str.Substring(start + nodeName.Length));
            return sb.ToString();
        }
        public static string GetValueByName(this string str, string name, char splitterChar = '&', char splitterAdapter = '=')
        {
            int start = str.IndexOf(name);
            if (start > 0)
            {
                string tmp = "";
                int end = str.LastIndexOf(splitterChar, start);
                if (end <= start)
                    tmp = str.Substring(start);
                else tmp = str.Substring(start, end - start);
                return tmp.Substring(tmp.IndexOf(splitterAdapter) + 1);
            }
            return null;
        }

        public static TEnum ToEnum<TEnum>(this string data)
        {
            EnumConverter convert = new EnumConverter(typeof(TEnum));
            if (convert == null)
                throw new ApplicationException("找不到枚举转换器");

            return (TEnum)convert.ConvertFromString(data);
        }

        public static int[] ToIntArray(this string data, char c = ',')
        {
            if (string.IsNullOrEmpty(data)) return new int[0];
            string[] datas = data.Split(new char[] { c }, StringSplitOptions.RemoveEmptyEntries);
            return datas.Select(d => d.ToInt(0)).ToArray();
        }

        /// <summary>
        /// 对传入的字符串进行哈希运算
        /// </summary>
        /// <param name="chars_set">输入字符串编码，gbk,utf-8等</param>
        /// <param name="sign_type">哈希算法名称md5,sha-1</param>
        public static byte[] GetHashCode(this string data, string chars_set, string sign_type)
        {
            Encoding encoding = Encoding.GetEncoding(chars_set);
            byte[] data2sign = encoding.GetBytes(data);
            byte[] datasigned = data2sign.GetHashCode(sign_type);
            return datasigned;
        }
        /// <summary>
        /// 获取MD5哈希值
        /// </summary>
        /// <param name="chars_set">输入字符串编码，gbk,utf-8等</param>
        public static byte[] GetMD5HashCode(this string data, string chars_set)
        {
            return GetHashCode(data, chars_set, "MD5");
        }
        public static byte[] GetMD5HashCode(this string data)
        {
            return GetHashCode(data, "utf-8", "MD5");
        }
        /// <summary>
        /// 使用MD5加密字符串
        /// </summary>
        /// <param name="data">字符串</param>
        /// <param name="salt">盐(如果不为空，则使用data+salt规则加密)</param>
        /// <returns></returns>
        public static string ToMD5String(this string data, string salt)
        {
            //if (string.IsNullOrEmpty(data))
            if (string.IsNullOrEmpty(salt))
                return data.GetMD5HashCode().ToHexString();
            return (data + salt).GetMD5HashCode().ToHexString();

        }
        public static byte[] GetMD5HashCodeWithSalt(this string data, string salt)
        {
            return GetHashCode(data + salt, "utf-8", "MD5");
        }
        /// <summary>
        /// 获取SHA1哈希值
        /// </summary>
        /// <param name="chars_set">输入字符串编码，gbk,utf-8等</param>
        public static byte[] GetSHA1HashCode(this string data, string chars_set)
        {
            return GetHashCode(data, chars_set, "SHA1");
        }

        public static byte[] GetSHA1HashCode(this string data)
        {
            return GetHashCode(data, "utf-8", "SHA1");
        }

        /// <summary>
        /// 使用指定字符集，将字符串转换为byte[]
        ///  Encoding.GetEncoding(chars_set).GetBytes(data);
        /// </summary>
        /// <param name="data">字符串</param>
        /// <param name="chars_set">字符集gbk,utf-8等</param>
        /// <returns>byte[]</returns>
        public static byte[] ToByteArray(this string data, string chars_set)
        {
            return Encoding.GetEncoding(chars_set).GetBytes(data);
        }
        /// <summary>
        /// 16进制字符串转换成byte[]
        /// </summary>
        /// <param name="hexstr">16进制字符串无分隔符</param>
        /// <returns>byte[]</returns>
        public static byte[] ToByteArray(this string hexstr)
        {
            if (hexstr.Length / 2.0 != hexstr.Length / 2) return null; //字符串长度不对

            byte[] result = new byte[hexstr.Length / 2];
            int i = 0; int j = 0;
            while (i < hexstr.Length)
            {
                string s = hexstr.Substring(i, 2);
                result[j] = (byte)Convert.ToInt32(s, 16);
                j++;
                i = i + 2;
            }
            return result;
        }
        /// <summary>
        /// 带分隔符的16进制字符串转换成byte[]
        /// </summary>
        /// <param name="hexstr">带分隔符的16进制字符串</param>
        /// <param name="split">分隔符</param>
        /// <returns>byte[]</returns>
        public static byte[] ToByteArray(this string hexstr, string[] splits)
        {
            string[] strs = hexstr.Split(splits, StringSplitOptions.RemoveEmptyEntries);
            byte[] result = new byte[strs.Length];
            for (int i = 0; i < strs.Length; i++)
            {
                result[i] = (byte)Convert.ToInt32(strs[i], 16);
            }
            return result;
        }
        /// <summary>
        /// 将目标字符串Base64加密（默认utf-8）
        /// </summary>
        /// <param name="data"></param>
        /// <param name="encoding">字符集</param>
        /// <returns></returns>
        public static string ToBase64String(this string data, Encoding encoding)
        {
            if (string.IsNullOrEmpty(data)) return string.Empty;
            return Convert.ToBase64String(encoding.GetBytes(data));
        }
        /// <summary>
        /// 将目标字符串Base64加密
        /// </summary>
        /// <param name="data"></param>
        /// <returns></returns>
        public static string ToBase64String(this string data)
        {
            return data.ToBase64String(Encoding.UTF8);
        }

        /// <summary>
        /// 将目标字符串Base64解密
        /// </summary>
        /// <param name="data"></param>
        /// <param name="encoding">字符集</param>
        /// <returns></returns>
        public static string FromBase64String(this string data, Encoding encoding)
        {
            if (string.IsNullOrEmpty(data)) return string.Empty;
            return encoding.GetString(Convert.FromBase64String(data));
        }
        /// <summary>
        /// 将目标字符串Base64解密（默认utf-8）
        /// </summary>
        /// <param name="str"></param>
        /// <returns></returns>
        public static string FromBase64String(this string str)
        {
            return str.FromBase64String(Encoding.UTF8);
        }
        /// <summary>
        /// 字符串转换为Int，如果格式不正确返回默认值
        /// </summary>
        /// <param name="data"></param>
        /// <param name="default_value">默认值</param>
        /// <returns></returns>
        public static int ToInt(this string data, int default_value)
        {
            int ret = default_value;
            if (int.TryParse(data, out ret)) return ret;
            else return default_value;
        }
        /// <summary>
        /// 字符串转换为byte，如果格式不正确返回默认值
        /// </summary>
        /// <param name="data"></param>
        /// <param name="default_value">默认值</param>
        /// <returns></returns>
        public static byte ToByte(this string data, byte default_value)
        {
            byte ret = default_value;
            if (byte.TryParse(data, out ret)) return ret;
            else return default_value;
        }
        /// <summary>
        /// 字符串转换为Int，如果格式不正确返回默认值
        /// </summary>
        /// <param name="data"></param>
        /// <param name="default_value">默认值</param>
        /// <returns></returns>
        public static short ToShort(this string data, short default_value)
        {
            short ret = default_value;
            if (short.TryParse(data, out ret)) return ret;
            else return default_value;
        }
        public static float ToFloat(this string data, float default_value)
        {
            float ret = default_value;
            if (float.TryParse(data, out ret)) return ret;
            else return default_value;
        }
        public static double ToDouble(this string data, double default_value)
        {
            double ret = default_value;
            if (double.TryParse(data, out ret)) return ret;
            else return default_value;
        }
        public static Decimal ToDecimal(this string data, decimal default_value)
        {
            Decimal ret = default_value;
            if (Decimal.TryParse(data, out ret)) return ret;
            else return default_value;
        }
        public static Boolean ToBoolean(this string data, Boolean default_value)
        {
            Boolean ret = default_value;
            if (Boolean.TryParse(data, out ret)) return ret;
            else return default_value;
        }

        public static Int64 ToInt64(this string data, Int64 default_value)
        {
            Int64 ret = default_value;
            if (Int64.TryParse(data, out ret)) return ret;
            else return default_value;
        }

        /// <summary>
        /// 字符串转换为Int，如果格式不正确返回默认值
        /// </summary>
        /// <param name="data"></param>
        /// <param name="default_value">如果转换失败的默认值</param>
        /// <param name="default_value">如超出范围返回最大值</param>
        /// <returns></returns>
        public static int ToInt(this string data, int default_value, int max_value)
        {
            int ret = default_value;
            if (int.TryParse(data, out ret))
                return ret > max_value ? max_value : ret;
            else return default_value;
        }
        public static uint ToUInt(this string data, uint default_value, uint max_value)
        {
            uint ret = default_value;
            if (uint.TryParse(data, out ret))
                return ret > max_value ? max_value : ret;
            else return default_value;
        }
        public static uint ToUInt(this string data, uint default_value)
        {
            uint ret = default_value;
            if (uint.TryParse(data, out ret))
                return ret;
            else return default_value;
        }

        /// <summary>
        /// 转换为时间格式（非法字符串返回最小值）
        /// </summary>
        /// <param name="data"></param>
        /// <returns></returns>
        public static DateTime ToDateTime(this string data)
        {
            if (string.IsNullOrEmpty(data)) return Constants.Date_Min;
            DateTime time = Constants.Date_Min;
            if (DateTime.TryParse(data, out time))
                return time;
            else return Constants.Date_Min;
        }
        /// <summary>
        /// 转换为时间格式（非法字符串返defaultValue）
        /// </summary>
        /// <param name="data"></param>
        /// <param name="defaultValue"></param>
        /// <returns></returns>
        public static DateTime ToDateTime(this string data, DateTime defaultValue)
        {
            if (string.IsNullOrEmpty(data)) return defaultValue;
            DateTime time = defaultValue;
            if (DateTime.TryParse(data, out time))
                return time;
            else return defaultValue;
        }
        /// <summary>
        /// 生成NameValueCollection对象
        /// 字符串格式如下：p1=v1&p2=v2&p3=v3&p4=v4
        /// </summary>
        /// <param name="data"></param>
        /// <returns>NameValueCollection</returns>
        public static NameValueCollection ToNameValueCollection(this string data)
        {
            return data.ToNameValueCollection('&', '=');
        }

        /// <summary>
        /// 将字符串转成键值集合，字符串格式：name1=value2&name2=value2&...
        /// </summary>
        /// <param name="data">字符串</param>
        /// <param name="splitterChar">键值间连接字符（默认 &）</param>
        /// <param name="splitterAdapter">键值连接字符（默认 =）</param>
        /// <returns></returns>
        public static NameValueCollection ToNameValueCollection(this string data, char splitterChar = '&', char splitterAdapter = '=')
        {
            NameValueCollection result = new NameValueCollection();

            if (!string.IsNullOrEmpty(data))
            {
                string[] p = data.Split(new char[] { splitterChar }, StringSplitOptions.RemoveEmptyEntries);
                foreach (string s in p)
                    if (s.IndexOf(splitterAdapter) > -1)
                    {
                        if (s.Count(c => c == splitterAdapter) == 1)
                        {
                            string[] temp = s.Split(new char[] { splitterAdapter }, StringSplitOptions.RemoveEmptyEntries);
                            if (temp.Length == 2)
                                result.Add(temp[0].Trim(), temp[1].Trim());
                            else result.Add(temp[0].Trim(), string.Empty);
                        }
                        else
                        {
                            result.Add(s.Substring(0, s.IndexOf(splitterAdapter)), s.Substring(s.IndexOf(splitterAdapter) + 1));
                        }
                    }
                    else result.Add(s.Trim(), string.Empty);
            }
            return result;
        }
        /// <summary>
        /// 将数值转换成IP地址字符串
        /// </summary>
        /// <param name="ipValue">ip数值</param>
        /// <returns></returns>
        public static string LongIP2Str(this long ipValue)
        {
            try
            {
                return IPAddress.Parse(ipValue.ToString()).ToString();
            }
            catch
            { }
            return "127.0.0.1";
        }
        /// <summary>
        /// 将IP地址转换成数值
        /// </summary>
        /// <param name="ip">ip地址</param>
        /// <returns>不合法的ip地址返回值为0</returns>
        public static long StrIP2Long(this string ip)
        {
            if (!ip.IsIpAddress()) return 0;
            string[] ips = ip.Split(new char[] { '.' }, StringSplitOptions.RemoveEmptyEntries);
            return ips[0].ToInt(0) * 256 * 256 * 256 + ips[1].ToInt(0) * 256 * 256 + ips[2].ToInt(0) * 256 + ips[3].ToInt(0);
        }

        //=================================================================================================
        //匹配ip地址
        private static string patterns_ip = @"^(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])(\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])){3}$";

        //匹配邮件地址
        //private static string patterns_email = @"^[a-zA-Z0-9_-]+@[a-zA-Z0-9_-]+(\.[a-zA-Z0-9_-]+)+$";
        private static string patterns_email = @"^[\.\w-]+(\.[\.\w-]+)*@[\w-]+(\.[\w-]+)+$";

        //匹配日期格式2008-01-31，但不匹配2008-13-00
        private static string patterns_date = @"^\d{4}-(0?[1-9]|1[0-2])-(0?[1-9]|[1-2]\d|3[0-1])$";

        /*
        匹配时间格式00:15:39，但不匹配24:60:00，下面使用RegExp对象的构造方法
             来创建RegExp对象实例，注意正则表达式模式文本中的“\”要写成“\\”
         */
        private static string patterns_time = @"^([0-1]\\d|2[0-3]):[0-5]\\d:[0-5]\\d$";

        /// <summary>
        /// 判断是否为email格式(*@*.*)字符串
        /// </summary>
        /// <param name="data"></param>
        /// <returns></returns>
        public static bool IsEmailAddress(this string data)
        {
            return IsMatch(data, patterns_email);
        }
        /// <summary>
        /// 判断是否为ip地址格式(xxx.xxx.xxx.xxx)字符串
        /// </summary>
        /// <param name="data"></param>
        /// <returns></returns>
        public static bool IsIpAddress(this string data)
        {
            return IsMatch(data, patterns_ip);
        }
        /// <summary>
        /// 判断是否为日期格式(yyyy-MM-dd)字符串
        /// </summary>
        /// <param name="data"></param>
        /// <returns></returns>
        public static bool IsDate(this string data)
        {
            return IsMatch(data, patterns_date);
        }
        /// <summary>
        /// 判断是否为时间格式(HH:mm:ss)字符串
        /// </summary>
        /// <param name="data"></param>
        /// <returns></returns>
        public static bool IsTime(this string data)
        {
            return IsMatch(data, patterns_time);
        }
        /// <summary>
        /// 匹配正则表达式
        /// </summary>
        /// <param name="str">字符串</param>
        /// <param name="regex">正则表达式</param>
        /// <returns></returns>
        private static bool IsMatch(this string str, string regex)
        {
            Regex re = new Regex(regex);
            return re.IsMatch(str);
        }

        /// <summary>
        /// 字符长度(以字符为单位的长度，其中汉子占2个字符)
        /// </summary>
        /// <param name="str">字符串</param>
        /// <returns></returns>
        public static int LengthInChar(this string str)
        {
            int _length = str.Length;
            foreach (char s in str)
            {
                if (s.IsChinese())
                    _length++;
            }
            return _length;
        }
        private static Regex _regex = new Regex("[^x00-xff]", RegexOptions.Compiled);
        public static bool IsChinese(this string data)
        {
            return _regex.IsMatch(data);
        }
        public static bool IsChinese(this char data)
        {
            return _regex.IsMatch(data.ToString());
        }

        /// <summary>
        /// 是否包含中文
        /// </summary>
        /// <param name="data"></param>
        /// <returns></returns>
        public static bool IsContainChinese(this string data)
        {
            Regex regex = new Regex("[\u4e00-\u9fa5]");
            Match m = regex.Match(data);
            bool ret = m.Success;
            return ret;

        }

        //
        /// <summary>
        /// 贴换不能用在xml中的特殊字符
        /// &  = (&amp;)   <  =  (&lt;) >  =  (&gt;)   ‘  =  (&apos;)   “ =  (&quot;)
        /// </summary>
        /// <param name="obj"></param>
        /// <returns></returns>
        public static string ReplaceXMLString(this string obj)
        {
            return obj.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;").Replace("'", "&apos;").Replace("\"", "&quot;");
        }

        /// <summary>
        /// 清楚字符串中的特殊字符(默认的特殊字符为导致页面中显示的连接地址错误而设；如做他用，请注意修改！)
        /// </summary>
        /// <param name="str"></param>
        /// <param name="chars">默认的特殊字符为：~!@#$%^&()+{}`[];',.()</param>
        /// <returns></returns>
        public static string ClearSpecialChars(this string str, string chars = "~!@#$%^&()+{}`[];',.()")
        {
            if (string.IsNullOrEmpty(str)) return null;
            StringBuilder sb = new StringBuilder();
            foreach (char c in str)
            {
                if (!chars.Contains(c)) sb.Append(c);
            }
            return sb.ToString();
        }

        /// <summary>
        /// 前台显示字符串长度
        /// </summary>
        /// <param name="str">原始字符串</param>
        /// <param name="count">字符长度</param>
        /// <param name="display">缩略显示字符串</param>
        /// <returns></returns>
        public static string ToDisplay(this string str, int count = 10, string display = "…")
        {
            if (string.IsNullOrEmpty(str)) return string.Empty;
            if (str.LengthInChar() <= count) return str;
            int length = 0;
            foreach (char c in str)
            {
                if (c.IsChinese()) count--;
                length++;
                if (length >= count) break;
            }
            return str.Substring(0, length) + display;
        }

        /// <summary>
        /// 截取字符串
        /// </summary>
        /// <param name="str">源字符串</param>
        /// <param name="isPre">true:取前，false:取后</param>
        /// <param name="splitter">截取字符</param>
        /// <returns></returns>
        public static string GetSubString(this string str, bool isPre = true, char splitter = '.')
        {
            if (isPre) return str.Substring(0, str.IndexOf(splitter));
            return str.Substring(str.LastIndexOf(splitter));
        }

        /// <summary>
        /// 反转字符串
        /// </summary>
        /// <param name="str"></param>
        /// <returns></returns>
        public static string ToReverse(this string str)
        {
            string revStr = "";
            if (!string.IsNullOrEmpty(str))
            {
                int pos = str.Length - 1;
                for (int i = 0; i <= pos; i++)
                {
                    revStr += str.Substring(pos - i, 1);
                }
            }
            return revStr;
        }

        public static string ToFirstUpperString(this string str)
        {
            if (!string.IsNullOrEmpty(str))
            {
                return str.Substring(0, 1).ToUpper() + str.Substring(1);
            }
            return "";
        }
    }


    public static class BytesExtension
    {

        /// <summary>
        /// 获取16进制字符串
        /// </summary>
        public static string ToHexString(this byte[] data)
        {
            StringBuilder sb = new StringBuilder();
            foreach (byte d in data)
            {
                sb.Append(d.ToString("X2"));
            }
            return sb.ToString();
        }

        /// <summary>
        /// 获取16进制字符串
        /// </summary>
        /// <param name="data">byte[]数组</param>
        /// <param name="split">分隔符</param>
        /// <returns></returns>
        public static string ToHexString(this byte[] data, string split)
        {
            StringBuilder sb = new StringBuilder();
            int i = 0;
            foreach (byte d in data)
            {
                if (i == 0)
                {
                    sb.Append(d.ToString("X2"));
                }
                else
                {
                    sb.Append(split + d.ToString("X2"));
                }
                i++;

            }
            return sb.ToString();
        }


        /// <summary>
        /// 获取Base64字符串
        /// </summary>
        public static string ToBase64String(this byte[] data)
        {
            return Convert.ToBase64String(data);
        }
        /// <summary>
        /// 获取指定字符集的字符串
        /// </summary>
        public static string ToString(this byte[] data, string chars_set)
        {
            return Encoding.GetEncoding(chars_set).GetString(data);
        }

        /// <summary>
        /// 获取数组的MD5哈希值
        /// </summary>
        public static byte[] GetMD5HashCode(this byte[] data)
        {
            return data.GetHashCode("MD5");
        }
        /// <summary>
        /// 获取数组的SHA1哈希值
        /// </summary>
        /// <param name="data"></param>
        /// <returns></returns>
        public static byte[] GetSHA1HashCode(this byte[] data)
        {
            return data.GetHashCode("SHA1");
        }

        /// <summary>
        /// 获取哈希值
        /// </summary>
        /// <param name="sign_type"> 可选参数 SHA1 MD5 SHA
        /// 更多内容参加MSDN
        /// source-help://MS.VSCC.v90/MS.MSDNQTR.v90.en/fxref_mscorlib/html/6a89632d-5da5-dee7-3521-a5d20d28c725.htm
        /// </param>
        /// <returns></returns>
        public static byte[] GetHashCode(this byte[] data, string sign_type)
        {
            HashAlgorithm hash = System.Security.Cryptography.HashAlgorithm.Create(sign_type);


            return hash.ComputeHash(data);
        }

        /// <summary>
        /// 判断数组元素是否相等
        /// </summary>
        /// <param name="b1"></param>
        /// <param name="b2"></param>
        /// <returns></returns>
        public static bool ValueEquals(this byte[] b1, byte[] b2)
        {
            if (b1 == null && b2 == null) return true;
            if (b1 == null || b2 == null) return false;
            if (b1.Length != b2.Length) return false;
            for (int i = 0; i < b1.Length; i++)
                if (b1[i] != b2[i])
                    return false;
            return true;
        }

    }



    public static class TimeExtension
    {
        public static string ET_TIME_ID = "Eastern Standard Time";
        public static string BEIJING_TIME_ID = "China Standard Time";
        public static string UTC_TIME_ID = "UTC";
        public static string GMT_TIME_ID = "GMT Standard Time";
        public static DateTime SEER_TIME_MIN = new DateTime(2015, 09, 14,0,0,0);
        public static DateTime SEER_TIME_MAX = SEER_TIME_MIN.AddYears(102);
        public static int ONLINE_STAT_LENGTH = 30; 
        public static int LIMIT_SHIFT = 2; 
        public static int LIMIT_LEAVE = 8; 
        public static int SEARCH_PAGESIZE = 30;
        public static int MAX_DOWNLOAD_PUBLIC_ID = 100;
        public static DateTime WEEK_SEQUENCE_START = new DateTime(2015, 09, 14); //第一周周一(must be monday), sequence is 1.

        public static DateTime StartPromotionTime = new DateTime(2017, 07, 31);
        /// <summary>
        /// 是否是最小时间
        /// </summary>
        /// <param name="dt"></param>
        /// <returns></returns>
        public static bool IsMinValue(DateTime dt)
        {
            return dt == DateTime.MinValue;
        }

        /// <summary>  
        /// 将DateTime时间格式转换为Unix时间戳格式  
        /// </summary>  
        /// <param name="time">时间</param>  
        /// <returns>long</returns>  
        public static long ConvertDateTimeToInt(DateTime time)
        {
            DateTime startTime = TimeZone.CurrentTimeZone.ToLocalTime(new DateTime(1970, 1, 1, 0, 0, 0, 0));
            long t = (time.Ticks - startTime.Ticks) / 10000;   //除10000调整为13位      
            return t;
        }

        public static string GetFullHourStr(TimeSpan? from, int hours)
        {
            if (from.HasValue && hours > 0)
            {
                return from.Value.ToString(@"hh\:mm") + "-" +
                       from.Value.Add(new TimeSpan(hours, 0, 0)).ToString(@"hh\:mm");
            }
            else return "";
        }

        /// <summary>
        /// 获取当前时间时间戳（从格林威治时间1970年01月01日00时00分00秒(北京时间1970年01月01日08时00分00秒)起至现在的总秒数）
        /// </summary>
        /// <returns></returns>
        public static double GetTimeStamp(DateTime dateTime)
        {
            double t = Math.Round((dateTime - new System.DateTime(1970, 1, 1, 0, 0, 0, 0)).TotalSeconds,0); 
            return t;
        }

        public static DateTime ETNow()
        {
            return DateTime.Now.Beijing2ET();
        }

      
    }

    public static class EnumExtension
    {

        public static string GetDescription(this Enum data)
        {
            string name = data.ToString();
            MemberInfo[] members = data.GetType().GetMember(name);
            foreach (MemberInfo member in members)
            {
                if (member.Name == name)
                {
                    foreach (DescriptionAttribute attr in member.GetCustomAttributes(typeof(DescriptionAttribute), false))
                    {
                        return attr.Description;
                    }
                }
            }
            return name;
        }

        /// <summary>
        /// 得到类型成员的注释
        /// </summary>
        /// <param name="aType">类型定义</param>
        /// <param name="aName">成员名</param>
        /// <returns>注释,如果无注释则返回成员名</returns>
        public static string GetDescription(this Type aType, string aName)
        {
            if (string.IsNullOrEmpty(aName)) return string.Empty;
            MemberInfo[] minfos = aType.GetMember(aName);
            foreach (MemberInfo info in minfos)
            {
                foreach (DescriptionAttribute attr in info.GetCustomAttributes(typeof(DescriptionAttribute), false))
                {
                    return attr.Description;
                }
            }
            return aName;
        }

        /// <summary>
        /// 获取类型中所有属性的Description
        /// </summary>
        /// <param name="type">类型</param>
        /// <returns></returns>
        public static List<string> GetDescriptions(this Type type)
        {
            List<string> comments = new List<string>();
            if (type.IsEnum)
            {
                string[] names = Enum.GetNames(type);
                foreach (string name in names)
                {
                    comments.Add(type.GetDescription(name));
                }
                return comments;
            }
            else if (type.IsClass)
            {
                foreach (FieldInfo fi in type.GetFields())
                {
                    foreach (DescriptionAttribute attr in fi.GetCustomAttributes(typeof(DescriptionAttribute), false))
                    {
                        comments.Add(attr.Description);
                    }
                }
            }
            return comments;
        }

        /// <summary>
        /// 将枚举类型转换成数组
        /// 格式：string[]{Description,Name,Value}
        /// </summary>
        /// <returns></returns>
        public static string[] ToArgments(this Enum data)
        {
            string[] args = new string[3];
            args[0] = data.GetDescription();
            args[1] = data.ToString();
            args[2] = data.GetHashCode().ToString();
            return args;
        }


    }


    public static class DateTimeExtension
    {
        public static DateTime BaseDate = new DateTime(2012, 1, 1, 0, 0, 0);
        public static string ET_TIME_ID = "Eastern Standard Time";
        public static string BEIJING_TIME_ID = "China Standard Time";
        public static string UTC_TIME_ID = "UTC";
        public static string GMT_TIME_ID = "GMT Standard Time";

        public static DateTime SEER_TIME_MIN = new DateTime(2015, 09, 14);
        public static DateTime SEER_TIME_MAX = SEER_TIME_MIN.AddYears(102);//立志百年企业
        /// <summary>
        /// 将时间转换为****-**-** **小时 格式的字符串
        /// </summary>
        /// <param name="date"></param>
        /// <returns></returns>
        public static string ToLocalHourString(this DateTime date)
        {
            return date.ToString("yyyy-MM-dd") + " " + date.Hour.ToString() + "时";
        }

        /// <summary>
        ///转换为只有时和分的字符串 12:30
        /// </summary>
        /// <param name="date"></param>
        /// <returns></returns>
        public static string ToHourMinuteString(this DateTime date)
        {
            if (date == null || date == DateTime.MinValue || date == DateTime.MaxValue) return "";
            return date.ToString("HH:mm");
        }

        /// <summary>
        ///转换为日期和有时和分的字符串 2012-11-14 12:30
        /// </summary>
        /// <param name="date"></param>
        /// <returns></returns>
        public static string ToDateAndHourMinuteString(this DateTime date)
        {
            if (date == null || date == DateTime.MinValue || date == DateTime.MaxValue) return "";
            return date.ToString("yyyy-MM-dd HH:mm");
        }

        public static DateTime ToBaseDate(this DateTime date)
        {
            if (date == null || date == DateTime.MinValue || date == DateTime.MaxValue)
                return BaseDate;
            return BaseDate.AddHours(date.Hour).AddMinutes(date.Minute);
        }
        /// <summary>
        /// 转换为****年**月**日 格式的字符串
        /// </summary>
        /// <param name="date"></param>
        /// <returns></returns>
        public static string ToLocalDateString(this DateTime date)
        {
            if (date == null || date == DateTime.MinValue || date == DateTime.MaxValue) return "";
            return date.Year.ToString() + "年" + date.Month.ToString() + "月" + date.Day.ToString() + "日";
        }

        /// <summary>
        /// 转换为yyyy-MM-dd HH:mm:ss的字符串
        /// </summary>
        /// <param name="date"></param>
        /// <returns></returns>
        public static string ToNormalFullString(this DateTime date)
        {
            if (date == null || date == DateTime.MaxValue || date == DateTime.MinValue) return "";
            else return date.ToString("yyyy-MM-dd HH:mm:ss");
        }
        public static string ToFullStringNoSplit(this DateTime date)
        {
            if (date == null || date == DateTime.MaxValue || date == DateTime.MinValue) return "";
            else return date.ToString("yyMMddHHmmss");
        }
        public static string ToDateString(this DateTime date)
        {
            return date.ToString("yyyy-MM-dd");
        }

        public static DateTime ET2Beijing(this DateTime et)
        {
            return TimeZoneInfo.ConvertTimeBySystemTimeZoneId(et, ET_TIME_ID, BEIJING_TIME_ID);
        }

        public static DateTime Beijing2ET(this DateTime bj)
        {
            return TimeZoneInfo.ConvertTimeBySystemTimeZoneId(bj, BEIJING_TIME_ID, ET_TIME_ID);
        }
        /// <summary>
        /// Gmt时间转换为北京时间，美东时间为Gmt+8
        /// </summary>
        /// <param name="gmttime"></param>
        /// <returns></returns>
        public static DateTime Gmt2Beijing(this DateTime gmttime)
        {
            return TimeZoneInfo.ConvertTimeBySystemTimeZoneId(gmttime, UTC_TIME_ID, BEIJING_TIME_ID);
        }

        public static DateTime Beijing2GMT(this DateTime bj)
        {
            return TimeZoneInfo.ConvertTimeBySystemTimeZoneId(bj, BEIJING_TIME_ID, UTC_TIME_ID);
        }

        public static DateTime Beijing2Local(this DateTime et, string localTimezoneId)
        {
            return TimeZoneInfo.ConvertTimeBySystemTimeZoneId(et, BEIJING_TIME_ID, localTimezoneId);
        }

        /// <summary>
        /// 农历日期转换为目标年份公历日期
        /// </summary>
        /// <param name="date">北京农历时间</param>
        /// <param name="year">目标年份</param>
        /// <returns></returns>
        public static DateTime Lunar2Solar(this DateTime date, int year)
        {
            ChineseLunisolarCalendar china = new ChineseLunisolarCalendar();
            //判断目标年是否是闰年，闰年需要月份+1
            return china.ToDateTime(year, china.IsLeapYear(year) ? date.Month + 1 : date.Month, date.Day, date.Hour, date.Minute, date.Second, date.Millisecond);
        }

        public static string GetEtcMsgTipsTime(this DateTime etcTime)
        {
            if (etcTime == TimeExtension.SEER_TIME_MIN || etcTime == TimeExtension.SEER_TIME_MAX) return "";
            DateTime today = DateTime.Now;
            TimeSpan span = DateTime.Now - etcTime;
            if (span.TotalHours < 24 && etcTime.Day == today.Day)
            {//今天，24小时以内的
                return etcTime.Beijing2ET().ToString("HH:mm");
            }
            else if (span.TotalHours < 48 && etcTime.Day == today.Day - 1)
            {
                return "yesterday " + etcTime.Beijing2ET().ToString("HH:mm");
            }
            else
            {
                return etcTime.Beijing2ET().ToString("yy-MM-dd HH:mm:ss");
            }
        }
    }  
}