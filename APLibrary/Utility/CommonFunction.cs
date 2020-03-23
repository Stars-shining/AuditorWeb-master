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
using System.Drawing;
using System.Drawing.Imaging;
using System.Diagnostics;


namespace APLibrary
{
    /// <summary>
    /// Summary description for CommonFunction
    /// </summary>
    public class CommonFunction
    {
        public CommonFunction()
        {
            //
            // TODO: Add constructor logic here
            //
        }

        public const string strInternalParameterFormat = @"{{::{0}::{1}}}";
        public const string strregInternalParameterFormat = @"[{]::(?<name>[\w]+)::(?<value>.*)[}]";
        /// <summary>
        /// construct for store parameter value for each message, not use session, just added to message text
        /// </summary>
        /// <param name="parametername"></param>
        /// <param name="parametervalue"></param>
        /// <returns></returns>
        public static string AddInternalParameterToMsg(string parametername, string parametervalue)
        {
            string strnewmsg = "";

            if (parametername != "")
            {
                strnewmsg = string.Format(strInternalParameterFormat, parametername, parametervalue);
            }

            return strnewmsg;
        }

        /// <summary>
        /// get stored parameter value for each message
        /// </summary>
        /// <param name="msg"></param>
        /// <returns></returns>
        public static Dictionary<string, string> GetInternalParameter(ref string msg)
        {
            Dictionary<string, string> msginternalval = new Dictionary<string, string>();
            Regex reginternalval = new Regex(strregInternalParameterFormat, RegexOptions.IgnoreCase);

            MatchCollection mcs = reginternalval.Matches(msg);
            foreach (Match mc in mcs)
            {
                string tmpstr = mc.ToString();
                msg = msg.Replace(tmpstr, "");

                string paraname = mc.Groups["name"].ToString().Trim();
                string paraval = mc.Groups["value"].ToString();

                if (msginternalval.ContainsKey(paraname))
                {
                    msginternalval[paraname] = paraval;
                }
                else
                {
                    msginternalval.Add(paraname, paraval);
                }
            }

            return msginternalval;
        }

        /// <summary>
        /// Get Phone Number
        /// </summary>
        /// <param name="tmpfile"></param>
        public static string GetPhoneNumber(string prefix, string number)
        {
            string phone = string.Empty;
            if (prefix == null)
            {
                prefix = string.Empty;
            }

            if (number == null)
            {
                number = string.Empty;
            }


            if (prefix.Trim() != string.Empty || number.Trim() != string.Empty)
            {
                if (prefix.Trim() != string.Empty)
                {
                    phone += "(" + prefix + ") ";
                }

                if (number.Trim() != string.Empty)
                {
                    if (phone != string.Empty)
                    {
                        phone += number;
                    }
                    else
                    {
                        phone += number;
                    }
                }
            }

            return phone;
        }


        public static DataTable DataTableAdd(DataTable from, DataTable to)
        {
            if (from == null) return null;

            if (to == null || to.Rows.Count == 0)
            {
                to = from.Clone();
            }

            DataTable newdt = new DataTable();
            newdt = to.Clone();

            foreach (DataRow dr in to.Rows)
            {
                DataRow thedr = newdt.NewRow();
                thedr.ItemArray = dr.ItemArray;
                newdt.Rows.Add(thedr);
            }

            foreach (DataRow dr in from.Rows)
            {
                DataRow thedr = newdt.NewRow();
                thedr.ItemArray = dr.ItemArray;
                newdt.Rows.Add(thedr);
            }
            return newdt;
        }


        public static DataTable DataTableAdd(DataTable to, DataRow[] rows)
        {
            if (rows == null) return to;

            foreach (DataRow dr in rows)
            {
                DataRow thedr = to.NewRow();
                thedr.ItemArray = dr.ItemArray;
                to.Rows.Add(thedr);
            }
            return to;
        }

        public static DataSet BuildDataset(DataTable dt)
        {
            DataSet ds = new DataSet();
            if (dt != null)
            {
                ds.Tables.Add(dt.Copy());
            }
            return ds;
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="tmpfile"></param>
        public static void DeleteTmpFile(string tmpfile)
        {
            if (string.IsNullOrEmpty(tmpfile))
            {
                return;
            }

            if (File.Exists(tmpfile))
            {
                File.Delete(tmpfile);
            }
        }


        /// <summary>
        /// Delete all files in the specific folders
        /// </summary>
        /// <param name="path"></param>
        /// <returns></returns>
        public static void DeleteAllTmpFile(string path)
        {
            if (Directory.Exists(path))
            {
                string[] fileList = Directory.GetFiles(path);
                foreach (string file in fileList)  // filename include like "XXXX.cs"
                {
                    try
                    {
                        DeleteTmpFile(file);
                    }
                    catch (Exception ex)
                    {

                    }
                }
            }
        }

        public static string FormatDecimal(object value)
        {
            if (value.ToString().Length > 0)
            {
                return FormatDecimal(value, "###,###,###,###.00");
            }
            return value.ToString();
        }
        public static string FormatDecimal(object value, string format)
        {
            decimal decvalue = 0;
            if (value != null)
            {
                decimal.TryParse(value.ToString(), out decvalue);
            }
            try
            {
                return decvalue.ToString(format);
            }
            catch
            {
                return decvalue.ToString();
            }
        }

        public static string FormatDateTime(string datetime)
        {
            DateTime dt = DateTime.MinValue;
            if (DateTime.TryParse(datetime, out dt))
            {
                return string.Format(CommonFunction.GetDateFormat(), dt);//"dd-MMM-yyyy"            
            }
            else
            {
                return "";
            }
        }

        public static string FormatDateTime(DateTime datetime)
        {
            if (datetime == Constants.Date_Min || datetime == Constants.Date_Null)
                return "";
            return string.Format(CommonFunction.GetDateFormat(), datetime);//"dd-MMM-yyyy"         
        }

        public static int? StringToInt(string value)
        {
            try
            {
                return int.Parse(value);
            }
            catch (Exception)
            {
                return null;
            }
        }

        public static bool ShouldApplyCase(string tempstring)
        {
            tempstring = tempstring.Trim();
            int uNo = 0;

            for (int i = 0; i < tempstring.Length; i++)
            {
                if (!Char.IsUpper(tempstring[i]))
                {
                    uNo++;
                }
            }

            if (uNo >= 2)
            {
                return false;
            }
            else
            {
                return true;
            }

        }

        public static string FormatStringAsHeaderForName(string tempstring)
        {
            if (ShouldApplyCase(tempstring))
            {
                tempstring = tempstring.ToLower();
                TextInfo textInfo = CultureInfo.InvariantCulture.TextInfo;
                return textInfo.ToTitleCase(tempstring.Trim());
            }
            else
            {
                return tempstring;
            }
        }

        /// <summary>
        /// Change the first char of letter which in string 'tempstring' to upcase
        /// </summary>
        /// <param name="tempstring"></param>
        /// <returns></returns>
        public static string FormatStringAsHeader(string tempstring)
        {
            TextInfo textInfo = CultureInfo.InvariantCulture.TextInfo;
            return textInfo.ToTitleCase(tempstring.Trim());
        }

        public static string GetDateFormat()
        {
            string rtn = ConfigurationManager.AppSettings["DateFormatString"];
            if (string.IsNullOrEmpty(rtn))
            {
                return "{0:dd/MM/yyyy}";
            }
            else
            {
                return rtn;
            }
        }

        public static decimal GetDeciamlFromCurrency(string currency, bool dividePercentage)
        {
            decimal rtn = GetDeciamlFromCurrency(currency);
            if (currency.Contains("%") == true)
            {
                if (dividePercentage == true)
                {
                    rtn = rtn / 100;
                }
            }
            return rtn;
        }
        public static decimal GetDeciamlFromCurrency(string currency)
        {
            decimal amount = 0;
            string stramount = currency;
            stramount = stramount.Replace("$", "");
            stramount = stramount.Replace("%", "");
            stramount = stramount.Replace(",", "");
            decimal.TryParse(stramount, out amount);
            return amount;
        }

        /// <summary>
        /// Young added function: if one date - another more than one year
        /// </summary>
        /// <param name="dt1"></param>
        /// <param name="dt2"></param>
        /// <returns></returns>
        public static bool OneYearGreater(DateTime dt1, DateTime dt2)
        {
            if (dt1 == null || dt2 == null) return false;

            DateTime dt = dt2.AddYears(1);
            int days = dt1.CompareTo(dt);
            return (days > 0);
        }

        /// <summary>
        /// Refresh ISOCode of label, Only when label not include other "()" can use this mathod
        /// </summary>
        /// <param name="ISOCode"></param>
        /// <param name="oldLabel"></param>
        /// <returns>Return the label text after format</returns>
        public static string FormatCurrencyLabel(string ISOCode, string oldLabel)
        {
            string newLabel = "";
            if (oldLabel.LastIndexOf("(") > 0)
            {
                if (ISOCode == "AUD")
                {
                    newLabel = oldLabel.Split('(')[oldLabel.Split('(').Length - 2];
                }
                else
                    newLabel = oldLabel.Split('(')[oldLabel.Split('(').Length - 2] + "(" + ISOCode + ")";
            }
            else
            {
                if (ISOCode == "AUD")
                {
                    newLabel = oldLabel;
                }
                else
                    newLabel = oldLabel + " (" + ISOCode + ")";
            }
            return newLabel;
        }

        public static DateTime GetFirstDayOfFinancialYearByDate(DateTime datetime)
        {
            int year = datetime.Year;
            int month = datetime.Month;
            DateTime yearStart = new DateTime(year, 7, 1);
            if (month < 7)
            {
                yearStart = yearStart.AddYears(-1);
            }
            return yearStart;
        }

        public static DateTime GetEndDayOfFinancialYearByDate(DateTime datetime)
        {

            int year = datetime.Year;
            int month = datetime.Month;
            DateTime yearEnd = new DateTime(year, 6, 30);
            if (month >= 7)
            {
                yearEnd = yearEnd.AddYears(1);
            }
            return yearEnd;
        }

        /// <summary>
        ///  Encode
        /// </summary>
        /// <param name="o"></param>
        /// <returns></returns>
        public static string Encode(object o)
        {
            return Encode(o.ToString());
        }

        /// <summary>
        ///  Encode
        /// </summary>
        /// <param name="source"></param>
        /// <returns></returns>
        public static string Encode(string source)
        {
            return HttpContext.Current.Server.HtmlEncode(source);
        }

        /// <summary>
        /// Get the days different between DateTime1 and DateTime2, return value is always positive
        /// </summary>
        /// <param name="DateTime1"></param>
        /// <param name="DateTime2"></param>
        /// <returns></returns>
        public static int GetDateDiff(DateTime DateTime1, DateTime DateTime2)
        {
            int dateDiff = 0;
            TimeSpan ts1 = new TimeSpan(DateTime1.Ticks);
            TimeSpan ts2 = new TimeSpan(DateTime2.Ticks);
            TimeSpan ts = ts1.Subtract(ts2).Duration();
            dateDiff = ts.Days;
            return dateDiff;
        }

        /// <summary>
        /// Get the days different between DateTime1 and DateTime2, return value is always positive
        /// </summary>
        /// <param name="DateTime1"></param>
        /// <param name="DateTime2"></param>
        /// <returns></returns>
        public static int GetDateDiff(DateTime DateTime1, DateTime DateTime2, bool inclusive)
        {
            if (inclusive)
            {
                DateTime2 = CommonFunction.DateAdd(DateTime2, 1);
            }
            return GetDateDiff(DateTime1, DateTime2);
        }



        public static DateTime DateAdd(DateTime DateTime1, int day)
        {
            TimeSpan ts1 = new TimeSpan(DateTime1.Ticks);

            TimeSpan ts2 = new TimeSpan(day, 0, 0, 0);

            TimeSpan ts = ts1.Add(ts2);

            return new DateTime(ts.Ticks);
        }



        public static bool IsCharInBag(string o)
        {
            string bag = "0123456789,.-";
            char[] chars = o.ToCharArray();
            foreach (char c in chars)
            {
                if (bag.IndexOf(c) >= 0)
                {
                    continue;
                }
                else
                {
                    return false;
                }
            }
            return true;
        }

        public static string conv(string str)
        {
            return (str.Replace("\\", "\\\\"));

        }


        /// <summary>
        /// get the physical path from the relativepath and pdfreportpath
        /// </summary>
        /// <param name="RelativePath"></param>
        /// <param name="PDFReportPath"></param>
        /// <returns></returns>
        public static string GetPhysicalPath(string RelativePath, string PDFReportPath)
        {
            //relative path like @"~\Reports\Fund7\CGT2007.pdf"
            //pdfreoprtpath like @"D:\SuperMyWay\Web\Reports\Fund7\"
            if (string.IsNullOrEmpty(PDFReportPath) || string.IsNullOrEmpty(RelativePath))
            {
                return null;
            }

            string seperator = @"\Reports\Fund";
            int pdfreportindex = PDFReportPath.IndexOf(seperator);
            int pdfrelativeindex = RelativePath.IndexOf(seperator);
            if (pdfrelativeindex < 0 || pdfreportindex < 0)
            {
                return null;
            }
            else
            {
                string physicalpth = PDFReportPath.Substring(0, pdfreportindex) + RelativePath.Substring(pdfrelativeindex, RelativePath.Length - pdfrelativeindex);
                return physicalpth;
            }
        }


        /// <summary>
        /// Get all classname from specfic folder
        /// </summary>
        /// <param name="path"></param>
        /// <returns></returns>
        public static DataTable GetClassFromPath(string path)
        {
            DataTable dt = new DataTable();
            DataColumn col = new DataColumn("Name", Type.GetType("System.String"));
            dt.Columns.Add(col);

            if (Directory.Exists(path))
            {
                string[] fileList = Directory.GetFiles(path);
                foreach (string file in fileList)  // filename include like "XXXX.cs"
                {
                    if (file.ToLower().Trim().EndsWith(".cs"))
                    {
                        string classname = file.Substring(path.Length, file.Length - path.Length);
                        if (classname.Length > 3)
                        {
                            classname = classname.Substring(0, classname.Length - 3);
                        }

                        DataRow newrow = dt.NewRow();
                        newrow[0] = classname;
                        dt.Rows.Add(newrow);
                    }
                }
            }

            return dt;
        }


        public static List<int> ConvertReaderToList(SqlDataReader reader)
        {
            List<int> list = new List<int>();
            while (reader.Read())
            {
                if (!reader.IsDBNull(0))
                {
                    list.Add(reader.GetInt32(0));
                }
            }
            return list;
        }

        /// <summary>
        /// convert object list to DataTable for display purpose
        /// </summary>
        /// <param name="dboCollection"></param>
        /// <returns></returns>
        public static DataTable ConvertListToTable(IEnumerable<DataObjectBase> collections)
        {
            DataTable dt = new DataTable();
            DataColumn dc;
            DataRow dr;
            Type dboType;
            DataObjectBase dob;

            IEnumerator<DataObjectBase> dboCollection = collections.GetEnumerator();

            if (dboCollection != null && dboCollection.MoveNext())
            {
                dboType = dboCollection.Current.GetType();

                PropertyInfo[] infors = dboType.GetProperties(BindingFlags.IgnoreCase | BindingFlags.Public | BindingFlags.Instance);

                foreach (PropertyInfo info in infors)
                {
                    dc = new DataColumn(info.Name, BusinessLogicBase.GetGenericType(info.PropertyType));
                    dt.Columns.Add(dc);
                }

                do
                {
                    dob = dboCollection.Current;
                    dr = dt.NewRow();

                    foreach (PropertyInfo infor in infors)
                    {
                        dr[infor.Name] = infor.GetValue(dob, null);
                    }
                    dt.Rows.Add(dr);
                }
                while (dboCollection.MoveNext());
            }
            return dt;
        }

        /// <summary>
        /// convert DataTable to object list
        /// </summary>
        /// <param name="dboCollection"></param>
        /// <returns></returns>
        public static List<DataObjectBase> ConvertTableToList(DataTable dt, Type ObjectType)
        {
            List<DataObjectBase> list = new List<DataObjectBase>();

            foreach (DataRow row in dt.Rows)
            {
                object obj = Activator.CreateInstance(ObjectType);

                foreach (DataColumn col in dt.Columns)
                {
                    string colname = col.ColumnName;
                    PropertyInfo info = ObjectType.GetProperty(colname, BindingFlags.IgnoreCase | BindingFlags.Public | BindingFlags.Instance);

                    if (info != null && !row.IsNull(colname))
                    {
                        object setvalue = row[colname];
                        info.SetValue(obj, setvalue, null);
                    }
                }

                if (obj != null)
                {
                    DataObjectBase dob = obj as DataObjectBase;
                    if (dob != null)
                    {
                        list.Add(dob);
                    }
                }
            }

            return list;
        }


        /// <summary>
        /// Get fieldname and fieldtype from specific class
        /// </summary>
        /// <param name="classname"></param>
        /// <returns></returns>
        public static DataTable GetFieldsFromClass(string classname)
        {
            string classnamespace = "SuperMyWay.MyFund.BusinessObject";
            DataTable dt = GetFieldsFromClass(classname, classnamespace);
            return dt;
        }

        public static DataTable GetFieldsFromClass(string classname, string classnamespace)
        {
            DataTable dt = new DataTable();
            DataColumn col = new DataColumn("Name", Type.GetType("System.String"));
            dt.Columns.Add(col);
            col = new DataColumn("Type", Type.GetType("System.String"));
            dt.Columns.Add(col);

            string dllassemblyname = "{0}.{1},MyFundLibrary";
            string typename = string.Format(dllassemblyname, classnamespace, classname);
            Type classtype = Type.GetType(typename);

            if (classtype != null)
            {
                PropertyInfo[] infos = classtype.GetProperties();
                foreach (PropertyInfo info in infos)
                {
                    string infoname = info.Name;
                    Type infotype = info.PropertyType;

                    DataRow newrow = dt.NewRow();
                    newrow["Name"] = infoname;
                    newrow["Type"] = infotype.ToString();
                    dt.Rows.Add(newrow);
                }
            }
            return dt;
        }


        /// <summary>
        /// used to calculate the decimal in pdf. to round the value.
        /// </summary>
        /// <param name="value"></param>
        /// <param name="decimaldigits"></param>
        /// <returns></returns>    
        public static decimal RoundValue2Digits(decimal value)
        {
            return Math.Round(value, 2, MidpointRounding.AwayFromZero);
        }

        public static decimal RoundValue(decimal value, int digits)
        {
            return Math.Round(value, digits, MidpointRounding.AwayFromZero);
        }

        /// <summary>
        /// Reconcile the value to eliminate the 0.01/0.02/0.03 margin
        /// </summary>
        /// <param name="AllValue"></param>
        /// <param name="TotalAmount"></param>
        /// <returns></returns>
        public static Dictionary<string, decimal> Reconcile(Dictionary<string, decimal> AllValue, decimal TotalAmount)
        {
            List<string> SeqList = new List<string>();
            decimal total = 0;
            int index = 0;

            Dictionary<string, decimal> ReconcileDic = new Dictionary<string, decimal>();

            //get the sequence of the value order by descend
            foreach (KeyValuePair<string, decimal> curvalue in AllValue)
            {
                string key = curvalue.Key;
                decimal value = curvalue.Value;
                decimal tmpvalue = CommonFunction.RoundValue2Digits(value);
                ReconcileDic.Add(key, tmpvalue);

                total += tmpvalue;
                if (tmpvalue != 0)
                {
                    if (SeqList.Count == 0)
                    {
                        SeqList.Add(key);
                    }
                    else
                    {
                        int seqindex = 0;
                        foreach (string seq in SeqList)
                        {
                            decimal tmpv = AllValue[seq];
                            if (Math.Abs(value) > Math.Abs(tmpv))
                            {
                                SeqList.Insert(seqindex, key);
                                break;
                            }
                            seqindex++;
                        }
                        if (seqindex == SeqList.Count)
                        {
                            SeqList.Add(key);
                        }
                    }
                }
                index++;
            }

            //compare the original amount to the show amount
            decimal roundtotal = CommonFunction.RoundValue2Digits(total);
            decimal roundmargin = CommonFunction.RoundValue2Digits(TotalAmount) - roundtotal;
            decimal margin = 0.01m;
            if (roundmargin < 0)
            {
                margin = -0.01m;
            }

            //eliminate the margin
            if (SeqList.Count > 0)
            {
                int seqtimes = 0;
                while (roundmargin != 0)
                {
                    foreach (string seqkey in SeqList)
                    {
                        decimal tmpvalue = 0;
                        if (seqtimes == 0)
                        {
                            tmpvalue = CommonFunction.RoundValue2Digits(AllValue[seqkey]);
                        }
                        else
                        {
                            tmpvalue = CommonFunction.RoundValue2Digits(ReconcileDic[seqkey]);
                        }

                        if (seqtimes > 0 && roundmargin == 0)
                        {
                            break;
                        }

                        if (roundmargin != 0)
                        {
                            tmpvalue += margin;
                            roundmargin -= margin;
                        }
                        ReconcileDic[seqkey] = tmpvalue;
                    }
                    seqtimes++;
                }
            }

            return ReconcileDic;
        }


        public static Dictionary<string, decimal> Reconcile(Dictionary<string, decimal> AllValue, decimal TotalAmount, int decimalPoint)
        {
            List<string> SeqList = new List<string>();
            decimal total = 0;
            int index = 0;

            Dictionary<string, decimal> ReconcileDic = new Dictionary<string, decimal>();

            //get the sequence of the value order by descend
            foreach (KeyValuePair<string, decimal> curvalue in AllValue)
            {
                string key = curvalue.Key;
                decimal value = curvalue.Value;
                decimal tmpvalue = CommonFunction.RoundValue(value, decimalPoint);
                ReconcileDic.Add(key, tmpvalue);

                total += tmpvalue;
                if (tmpvalue != 0)
                {
                    if (SeqList.Count == 0)
                    {
                        SeqList.Add(key);
                    }
                    else
                    {
                        int seqindex = 0;
                        foreach (string seq in SeqList)
                        {
                            decimal tmpv = AllValue[seq];
                            if (Math.Abs(value) > Math.Abs(tmpv))
                            {
                                SeqList.Insert(seqindex, key);
                                break;
                            }
                            seqindex++;
                        }
                        if (seqindex == SeqList.Count)
                        {
                            SeqList.Add(key);
                        }
                    }
                }
                index++;
            }

            //compare the original amount to the show amount
            decimal roundtotal = CommonFunction.RoundValue(total, decimalPoint);
            decimal roundmargin = CommonFunction.RoundValue(TotalAmount, decimalPoint) - roundtotal;
            decimal margin = 1m / Decimal.Parse(System.Math.Pow(10, decimalPoint).ToString());
            if (roundmargin < 0)
            {
                margin = -1 * margin;
            }

            //eliminate the margin
            if (SeqList.Count > 0)
            {
                int seqtimes = 0;
                while (roundmargin != 0)
                {
                    foreach (string seqkey in SeqList)
                    {
                        decimal tmpvalue = 0;
                        if (seqtimes == 0)
                        {
                            tmpvalue = CommonFunction.RoundValue(AllValue[seqkey], decimalPoint);
                        }
                        else
                        {
                            tmpvalue = CommonFunction.RoundValue(ReconcileDic[seqkey], decimalPoint);
                        }

                        if (seqtimes > 0 && roundmargin == 0)
                        {
                            break;
                        }

                        if (roundmargin != 0)
                        {
                            tmpvalue += margin;
                            roundmargin -= margin;
                        }
                        ReconcileDic[seqkey] = tmpvalue;
                    }
                    seqtimes++;
                }
            }

            return ReconcileDic;
        }

        /// <summary>
        /// reconcile for DataTable
        /// </summary>
        /// <param name="dt">target DataTable</param>
        /// <param name="keys">columns which can make an unique key for a  data row</param>
        /// <param name="targetColumn">column which need reconcile</param>
        /// <param name="TotalAmount">total amount</param>
        /// <param name="decimalPoint">how many decimal should be</param>
        public static void Reconcile(ref DataTable dt, List<string> keys, string targetColumn, decimal TotalAmount, int decimalPoint)
        {
            if (dt != null && dt.Rows.Count > 0)
            {
                Dictionary<string, decimal> dictAllValue = new Dictionary<string, decimal>();
                // loop to get value dictionay, to invoke CommonFunction.Reconcile
                foreach (DataRow dr in dt.Rows)
                {
                    string key = CreateDataKeyByList(dr, keys);
                    decimal weighting = decimal.Parse(dr[targetColumn].ToString());
                    dictAllValue.Add(key, weighting);
                }
                Dictionary<string, decimal> dictWeighting = CommonFunction.Reconcile(dictAllValue, 1, 4);
                // loop to save reconciled value to DataTable
                foreach (DataRow dr in dt.Rows)
                {
                    string key = CreateDataKeyByList(dr, keys);
                    dr["Weighting"] = dictWeighting[key];
                }
            }
        }

        /// <summary>
        /// CreateDataKeyByList for Reconcile function
        /// 9110M-9111S-9112P
        /// </summary>
        /// <param name="dr">data row which is in process</param>
        /// <param name="keys">columns to make data key</param>
        /// <returns>data key(may have more than one column value joined together</returns>
        private static string CreateDataKeyByList(DataRow dr, List<string> keys)
        {
            string rtn = "";

            foreach (string s in keys)
            {
                if (dr.Table.Columns.Contains(s))
                {
                    // retur formate like "[22][9823][123454]"
                    rtn = rtn + string.Format("[{0}]", dr[s].ToString());
                }
            }

            return rtn;
        }


        public static string GetFullName(string firstName, string middleName, string familyName)
        {
            if (firstName == null) firstName = "";
            if (middleName == null) middleName = "";
            if (familyName == null) familyName = "";
            string restr = firstName.Trim();
            if (restr != "")
            {
                if (middleName != "")
                    restr = restr + " " + middleName;
                if (familyName != "")
                    restr = restr + " " + familyName;
            }
            else if (middleName != "")
            {
                restr = middleName;
                if (familyName != "")
                    restr = restr + " " + familyName;
            }
            else if (familyName != "")
            {
                restr = familyName;
            }
            return FormatStringAsHeader(restr.ToLower());
        }

        public static string GetFullName1(string firstName, string middleName, string familyName)
        {
            if (firstName == null)
                firstName = "";
            else
                firstName = firstName.Trim();

            if (middleName == null)
                middleName = "";
            else
                middleName = middleName.Trim();

            if (familyName == null)
                familyName = "";
            else
                familyName = familyName.Trim();


            string restr = firstName.Trim();
            if (restr != "")
            {
                if (middleName != "")
                {
                    string[] mnames = middleName.Split(' ');
                    middleName = "";
                    foreach (string a in mnames)
                    {
                        if (string.IsNullOrEmpty(a) || a == " ")
                            continue;
                        middleName = middleName + a.Substring(0, 1).ToUpper() + ".";
                    }
                    restr = restr + " " + middleName;
                }
                if (familyName != "")
                    restr = restr + " " + familyName;
            }
            else if (middleName != "")
            {
                string[] mnames = middleName.Split(' ');
                middleName = "";
                foreach (string a in mnames)
                {
                    if (string.IsNullOrEmpty(a) || a == " ")
                        continue;
                    middleName = middleName + a.Substring(0, 1).ToUpper() + ".";
                }
                restr = middleName;
                if (familyName != "")
                    restr = restr + " " + familyName;
            }
            else if (familyName != "")
            {
                restr = familyName;
            }
            return FormatStringAsHeader(restr.ToLower());
        }

        internal static Dictionary<string, decimal> GetSystemConstants(int fundid)
        {
            string strtaxable = "taxable";
            string strnontaxable = "nontaxable";

            decimal nontaxable = 1m / 3m;
            decimal taxable = 2m / 3m;

            Dictionary<string, decimal> mydictionary = new Dictionary<string, decimal>();
            mydictionary.Add(strtaxable, taxable);
            mydictionary.Add(strnontaxable, nontaxable);

            return mydictionary;
        }

        public static DateTime GetDateFromContent(string content, string format)
        {
            IFormatProvider cul = new System.Globalization.CultureInfo("en-US", true);
            return GetDateFromContent(content, format, cul);
        }

        public static DateTime GetDateFromContent(string content, string format, IFormatProvider cul)
        {
            DateTime tmpdate = Constants.Date_Null;
            try
            {
                tmpdate = DateTime.ParseExact(content, format, cul);
            }
            catch
            {
                if (!DateTime.TryParse(content, out tmpdate))
                {
                    tmpdate = Constants.Date_Null;
                }
            }
            return tmpdate;
        }

        /// <summary>
        /// get a decimal value from a column in datarow
        /// </summary>
        /// <param name="row"></param>
        /// <param name="columnname"></param>
        /// <returns></returns>
        public static decimal GetColumnValue(DataRow row, string columnname)
        {
            decimal value = 0;

            if (row != null)
            {
                if (!row.IsNull(columnname))
                {
                    string stramount = row[columnname].ToString();
                    stramount = stramount.Replace("$", "");
                    stramount = stramount.Replace("%", "");
                    stramount = stramount.Replace(",", "");
                    decimal.TryParse(stramount, out value);
                }
            }

            return value;
        }



        /// <summary>
        /// get a decimal value from a column in datarow
        /// </summary>
        /// <param name="row"></param>
        /// <param name="columnname"></param>
        /// <returns></returns>
        public static decimal GetColumnValue(DataRow row, string columnname, out string columnvalue)
        {
            columnvalue = "nullvalue";

            decimal value = 0;

            if (row != null)
            {
                if (!row.IsNull(columnname))
                {
                    string stramount = row[columnname].ToString();

                    stramount = stramount.Replace("$", "");
                    stramount = stramount.Replace("%", "");
                    stramount = stramount.Replace(",", "");

                    if (!decimal.TryParse(stramount, out value))
                    {
                        columnvalue = stramount;
                    }
                }
            }

            return value;
        }


        public static decimal GetComputeValue(DataTable dt, string expression, string filter)
        {
            decimal value = 0;

            try
            {
                object o = dt.Compute(expression, filter);
                decimal.TryParse(o.ToString(), out value);
            }
            catch
            {
            }

            return value;
        }

        public static DataTable SortTable(DataTable dt, string sort, int record)
        {
            DataTable thedt = SortTable(dt, sort);
            DataTable newdt = thedt.Clone();
            DataRow dr;

            int counter = dt.Rows.Count;

            if (counter > record)
            {
                counter = record;
            }


            for (int i = 0; i < counter; i++)
            {
                dr = newdt.NewRow();
                dr.ItemArray = thedt.Rows[i].ItemArray;
                newdt.Rows.Add(dr);
            }

            return newdt;
        }

        public static DataTable SortTable(DataTable dt, string sort)
        {
            DataView dv = dt.DefaultView;
            dv.Sort = sort;
            return dv.ToTable();
        }


        public static void RenameColumnName(ref DataTable dt, string orgname, string newname)
        {
            DataColumn col = dt.Columns[orgname];
            if (col != null)
            {
                col.ColumnName = newname;
            }
        }

        /// <summary>
        /// get the columns in filter
        /// </summary>
        /// <param name="colnames"></param>
        /// <param name="dt"></param>
        /// <returns></returns>
        public static DataTable GetFilterColumnTable(List<string> colnames, DataTable dt)
        {
            if (dt == null)
            {
                return null;
            }

            DataTable newdt = new DataTable();
            for (int i = 0; i < colnames.Count; i++)
            {
                string colname = colnames[i];
                DataColumn col = dt.Columns[colname];
                if (col != null)
                {
                    DataColumn newcol = new DataColumn(col.ColumnName, col.DataType);
                    newdt.Columns.Add(newcol);
                }
            }

            foreach (DataRow row in dt.Rows)
            {
                DataRow newrow = newdt.NewRow();
                foreach (DataColumn newcol in newdt.Columns)
                {
                    newrow[newcol] = row[newcol.ColumnName];
                }
                newdt.Rows.Add(newrow);
            }

            return newdt;
        }

        /// <summary>
        /// get the columns from the key of dictionary, and change the name as the value of dictionary
        /// the key is the original name of column, the value is the name after change 
        /// </summary>
        /// <param name="colnames"></param>
        /// <param name="dt"></param>
        /// <returns></returns>
        public static DataTable GetFilterColumnTable(Dictionary<string, string> colnames, DataTable dt)
        {
            if (dt == null)
            {
                return null;
            }

            DataTable newdt = new DataTable();
            foreach (KeyValuePair<string, string> data in colnames)
            {
                string colname = data.Key;
                DataColumn col = dt.Columns[colname];
                if (col != null)
                {
                    DataColumn newcol = new DataColumn(colname, col.DataType);
                    newdt.Columns.Add(newcol);
                }
            }

            foreach (DataRow row in dt.Rows)
            {
                DataRow newrow = newdt.NewRow();
                foreach (DataColumn newcol in newdt.Columns)
                {
                    newrow[newcol] = row[newcol.ColumnName];
                }
                newdt.Rows.Add(newrow);
            }

            //rename the col to value of the dic
            foreach (KeyValuePair<string, string> data in colnames)
            {
                string oldname = data.Key.ToString();
                string newname = data.Value;
                if (!string.IsNullOrEmpty(newname.Trim()) && oldname.ToLower().Trim() != newname.ToLower().Trim())
                {
                    if (!newdt.Columns.Contains(newname))
                    {
                        RenameColumnName(ref newdt, oldname, newname);
                    }
                }
            }
            return newdt;
        }

        /// <summary>
        /// return two columns in datatable: text,value
        /// </summary>
        /// <param name="time"></param>
        /// <param name="count"></param>
        /// <returns></returns>
        public static DataTable GetQuarterList(DateTime time, int count, bool isAsc)
        {
            DataTable dt = new DataTable();
            dt.Columns.Add("Text");
            dt.Columns.Add("value");
            int month = time.Month;
            int year = time.Year;
            DateTime tempdatestart;
            DateTime tempdateend;
            int flag = 1;
            if (!isAsc)
                flag = -1;

            while (count > 0)
            {
                DataRow dr = dt.NewRow();
                if (month <= 3)
                {
                    tempdatestart = new DateTime(year, 1, 1);
                    tempdateend = new DateTime(year, 4, 1);

                }
                else if (month <= 6)
                {
                    tempdatestart = new DateTime(year, 4, 1);
                    tempdateend = new DateTime(year, 7, 1);
                }
                else if (month <= 9)
                {
                    tempdatestart = new DateTime(year, 7, 1);
                    tempdateend = new DateTime(year, 10, 1);
                }
                else
                {
                    tempdatestart = new DateTime(year, 10, 1);
                    tempdateend = new DateTime(year + 1, 1, 1);
                }
                tempdateend = tempdateend.AddDays(-1);
                dr["text"] = tempdatestart.ToString("MMM yyyy") + " - " + tempdateend.ToString("MMM yyyy");
                dr["value"] = FormatDateTime(tempdateend);
                dt.Rows.Add(dr);
                time = time.AddMonths(3 * flag);
                month = time.Month;
                year = time.Year;
                count--;
            }

            return dt;
        }

        public static DateTime GetQuarterTime(DateTime time)
        {
            int year = time.Year;
            int month = time.Month;
            int day = time.Day;

            int newmonth = 1;

            if (month <= 3)
            {
                newmonth = 1;
            }
            else if (month <= 6)
            {
                newmonth = 4;
            }
            else if (month <= 9)
            {
                newmonth = 7;
            }
            else
            {
                newmonth = 10;
            }
            return new DateTime(year, newmonth, 1);
        }

        public static string GetQuarterDesc(DateTime time, out string desc1, out string shortdesc)
        {
            int year = time.Year;
            int month = time.Month;
            shortdesc = "";
            int quarter = (int)Math.Ceiling((decimal)month / (decimal)3);
            string text = "{0} - {1} {2}";

            switch (quarter)
            {
                case 4:
                    shortdesc = string.Format(text, "Oct", "Dec", year);

                    break;
                case 3:
                    shortdesc = string.Format(text, "Jul", "Sep", year);

                    break;
                case 2:
                    shortdesc = string.Format(text, "Apr", "Jun", year);

                    break;
                case 1:
                    shortdesc = string.Format(text, "Jan", "Mar", year);
                    break;
                default:
                    break;
            }

            string restr = "{0} to {1} {2}";
            DateTime datefrom = new DateTime();
            DateTime dateto = new DateTime();
            string format = "MMMM";
            string format2 = "d MMM yyyy";

            desc1 = "{0} to {1}";

            if (month <= 3)
            {
                datefrom = new DateTime(year, 1, 1);
                dateto = new DateTime(year, 3, 1);
            }
            else if (month <= 6)
            {
                datefrom = new DateTime(year, 4, 1);
                dateto = new DateTime(year, 6, 1);
            }
            else if (month <= 9)
            {
                datefrom = new DateTime(year, 7, 1);
                dateto = new DateTime(year, 9, 1);
            }
            else
            {
                datefrom = new DateTime(year, 10, 1);
                dateto = new DateTime(year, 12, 1);
            }
            restr = string.Format(restr, datefrom.ToString(format), dateto.ToString(format), year);
            desc1 = string.Format(desc1, datefrom.ToString(format2), dateto.AddMonths(1).AddDays(-1).ToString(format2));
            return restr;

        }

        public static string CheckSQLCharacter(string sql)
        {
            StringBuilder content = new StringBuilder("");
            //replace the single "'" with "''"
            int startindex = 0;
            while (sql.IndexOf("'", startindex) >= 0)
            {
                int curindex = sql.IndexOf("'", startindex);
                content.Append(sql.Substring(startindex, curindex - startindex));
                if (curindex + 1 < sql.Length && sql.Substring(curindex, 2) != "''")
                {
                    content.Append("''");
                    startindex = curindex + 1;
                }
                else
                {
                    content.Append("''");
                    startindex = curindex + 2;
                }

                if (startindex >= sql.Length)
                {
                    break;
                }
            }

            if (startindex < sql.Length)
            {
                content.Append(sql.Substring(startindex));
            }

            return content.ToString();
        }

        /// <summary>
        /// Check whether is a pdf file
        /// </summary>
        /// <param name="filename"></param>
        /// <returns></returns>
        public static bool CheckPDFFile(string filename)
        {
            string str = filename.Trim();
            Regex reg = new Regex(".pdf$", RegexOptions.IgnoreCase);
            bool bpdf = reg.IsMatch(str);
            return bpdf;
        }

        /// <summary>
        /// replace ".pdf" in filename
        /// </summary>
        /// <param name="filename"></param>
        /// <param name="replace"></param>
        /// <returns></returns>
        public static string ReplacePDFInFileName(string filename, string replacestr)
        {
            if (Regex.IsMatch(replacestr, "[0-9]{4}[0-1][0-9][0-3][0-9][0-2][0-9]([0-5][0-9]){2}[0-9]{4}[.]pdf"))
            {
                string str = filename.Trim();
                Regex reg = new Regex("([0-9]{4}[0-1][0-9][0-3][0-9][0-2][0-9]([0-5][0-9]){2}[0-9]{4})+[.]pdf$", RegexOptions.IgnoreCase);
                if (reg.IsMatch(str))
                {
                    return reg.Replace(str, replacestr);
                }
                else
                {
                    reg = new Regex(".pdf$", RegexOptions.IgnoreCase);
                    return reg.Replace(str, replacestr);
                }
            }
            else
            {
                string str = filename.Trim();
                Regex reg = new Regex(".pdf$", RegexOptions.IgnoreCase);
                return reg.Replace(str, replacestr);
            }
        }


        public static DataTable ComposeCSVTable(params string[] cols)
        {
            DataTable dt = new DataTable();

            foreach (string colstr in cols)
            {
                string colname = colstr.Trim();
                if (colname == "")
                    continue;
                //trim the unnecessary space in colname
                Regex reg = new Regex("[ ]{2,}");
                if (reg.IsMatch(colname))
                {
                    colname = reg.Replace(colname, " ");
                }

                DataColumn col = new DataColumn(colname);
                dt.Columns.Add(col);
            }

            return dt;
        }

        public static Dictionary<string, string> Merge(Dictionary<string, string> first, Dictionary<string, string> second)
        {
            if (first == null)
            {
                first = new Dictionary<string, string>();
            }
            if (second == null)
            {
                second = new Dictionary<string, string>();
            }
            foreach (var item in second)
                if (!first.ContainsKey(item.Key))
                    first.Add(item.Key, item.Value);
            return first;
        }

        /// <summary>
        /// Validate if the string is an email with correct format
        /// </summary>
        /// <param name="emailAddress"></param>
        /// <returns></returns>
        public static bool CheckEmailAddress(string emailAddress)
        {
            string regexp = @"^\w+([-+.']\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*$";
            return new Regex(regexp).Match(emailAddress).Success;
        }

        //replace the char illegal in file name
        public static string ReplaceBadCharOfFileName(string fileName)
        {
            string str = fileName;
            Regex regchar = new Regex("[\\/:*?<>|]");
            str = regchar.Replace(str, " ");
            return str;
        }

        /// <summary>
        /// Generates a new path for duplicate filenames.
        /// </summary>
        /// <param name="path">The path.</param>
        /// <returns></returns>
        public static string GetNewPathForDuplicates(string path)
        {
            string directory = Path.GetDirectoryName(path);
            string filename = Path.GetFileNameWithoutExtension(path);
            string extension = Path.GetExtension(path);
            int counter = 1;
            string newFullPath = path;
            while (System.IO.File.Exists(newFullPath))
            {
                string newFilename = string.Format("{0}({1}){2}", filename, counter, extension);
                newFullPath = Path.Combine(directory, newFilename);
                counter++;
            }
            return newFullPath;
        }

        public static string GetThumbPathForImageFile(string path)
        {
            string pathWithoutExtension = path.Substring(0, path.LastIndexOf('.'));
            string extension = path.Substring(path.LastIndexOf('.'));
            string thumbPath = string.Format("{0}_{1}{2}", pathWithoutExtension, "thumb", extension);
            return thumbPath;
        }

        public static string GetFixedTime(string ctrTime)
        {
            string result = ctrTime;
            string strHour = ctrTime.Substring(0, 2);
            int hour = 0;
            int.TryParse(strHour, out hour);
            if (hour >= 24)
            {
                hour = hour % 24;
                result = hour + ctrTime.Substring(2);
            }
            return result;
        }

        public static string ResolveUrl(string relativeUrl)
        {
            if (relativeUrl == null) throw new ArgumentNullException("relativeUrl");

            if (relativeUrl.Length == 0 || relativeUrl[0] == '/' ||
                relativeUrl[0] == '\\') return relativeUrl;

            int idxOfScheme =
              relativeUrl.IndexOf(@"://", StringComparison.Ordinal);
            if (idxOfScheme != -1)
            {
                int idxOfQM = relativeUrl.IndexOf('?');
                if (idxOfQM == -1 || idxOfQM > idxOfScheme) return relativeUrl;
            }

            StringBuilder sbUrl = new StringBuilder();
            sbUrl.Append(HttpRuntime.AppDomainAppVirtualPath);
            if (sbUrl.Length == 0 || sbUrl[sbUrl.Length - 1] != '/') sbUrl.Append('/');

            // found question mark already? query string, do not touch!
            bool foundQM = false;
            bool foundSlash; // the latest char was a slash?
            if (relativeUrl.Length > 1
                && relativeUrl[0] == '~'
                && (relativeUrl[1] == '/' || relativeUrl[1] == '\\'))
            {
                relativeUrl = relativeUrl.Substring(2);
                foundSlash = true;
            }
            else foundSlash = false;
            foreach (char c in relativeUrl)
            {
                if (!foundQM)
                {
                    if (c == '?') foundQM = true;
                    else
                    {
                        if (c == '/' || c == '\\')
                        {
                            if (foundSlash) continue;
                            else
                            {
                                sbUrl.Append('/');
                                foundSlash = true;
                                continue;
                            }
                        }
                        else if (foundSlash) foundSlash = false;
                    }
                }
                sbUrl.Append(c);
            }

            return sbUrl.ToString();
        }

        public static void GetAllGroups(int currentIndex, int remain, Dictionary<int, string> currentSelect, Dictionary<int, string> items, ref List<Dictionary<int, string>> result)
        {
            if (remain == 0)
            {
                result.Add(currentSelect);
                return;
            }

            if (items.Count - currentIndex < remain)
                return;
            Dictionary<int, string> tempSelect = new Dictionary<int, string>();
            foreach (KeyValuePair<int, string> pair in currentSelect)
            {
                tempSelect.Add(pair.Key, pair.Value);
            }
            int i = 0;
            foreach (KeyValuePair<int, string> pair in items)
            {
                if (i == currentIndex)
                {
                    tempSelect.Add(pair.Key, pair.Value);
                    break;
                }
                i++;
            }
            GetAllGroups(currentIndex + 1, remain - 1, tempSelect, items, ref result);
            GetAllGroups(currentIndex + 1, remain, currentSelect, items, ref result);
        }

        public static void GetAllGroups(int currentIndex, int remain, string currentSelect, List<string> items, ref List<string> result)
        {
            if (result.Count > 1000)
            {
                return;
            }
            if (remain == 0)
            {
                result.Add(currentSelect.Trim(','));
                return;
            }

            if (items.Count - currentIndex < remain)
                return;
            GetAllGroups(currentIndex + 1, remain - 1, currentSelect + "," + items[currentIndex], items, ref result);
            GetAllGroups(currentIndex + 1, remain, currentSelect, items, ref result);
        }

        public static void ClearAllFilesUnderFolder(string folderPath)
        {
            if (!Directory.Exists(folderPath))
            {
                return;
            }
            try
            {
                System.IO.DirectoryInfo di = new System.IO.DirectoryInfo(folderPath);
                FileInfo[] files = di.GetFiles();
                foreach (FileInfo fi in files)
                {
                    fi.Delete();
                }
            }
            catch { }
        }

        public static string GetWeekDay(DayOfWeek day)
        {
            string[] weekdays = { "星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六" };
            string week = weekdays[Convert.ToInt32(day)];
            return week;
        }

        public static int GetWeekNum(DateTime date)
        {
            return (int)date.DayOfWeek;
        }


        public static int GetFileType(string fileName)
        {
            int extensionIndex = fileName.LastIndexOf('.');
            string extension = fileName.Substring(extensionIndex).ToLower();
            int fileTypeID = 5;
            switch (extension)
            {
                case ".jpg":
                case ".png":
                case ".bmp":
                case ".gif":
                    fileTypeID = 1;
                    break;
                case ".mp3":
                case ".wav":
                case ".wma":
                case ".ogg":
                case ".acc":
                case ".aac":
                case ".ape":
                    fileTypeID = 2;
                    break;
                case ".mp4":
                case ".avi":
                case ".mpg":
                case ".mpeg":
                case ".mov":
                case ".wmv":
                case ".rm":
                case ".rmvb":
                case ".mkv":
                case ".3gp":
                case ".asf":
                case ".flv":
                case ".swf":
                    fileTypeID = 3;
                    break;
                case ".doc":
                case ".docx":
                case ".ppt":
                case ".pptx":
                case ".xls":
                case ".xlsx":
                case ".txt":
                case ".pdf":
                case ".xml":
                case ".csv":
                    fileTypeID = 4;
                    break;
                default:
                    fileTypeID = 5;
                    break;
            }
            return fileTypeID;
        }

        public static string GetFileTypeName(string fileName)
        {
            int fileTypeID = GetFileType(fileName);
            string fileTypeName = BusinessConfigurationManager.GetItemValueByItemKey(fileTypeID, "FileType");
            return fileTypeName;
        }

        public static int GetQuestionTypeByName(string typeName)
        {
            int typeID = 0;
            switch (typeName)
            {
                case "段落":
                    typeID = (int)Enums.QuestionType.段落;
                    break;
                case "单选题":
                    typeID = (int)Enums.QuestionType.单选题;
                    break;
                case "多选题":
                    typeID = (int)Enums.QuestionType.多选题;
                    break;
                case "是非题":
                    typeID = (int)Enums.QuestionType.是非题;
                    break;
                case "填空题":
                    typeID = (int)Enums.QuestionType.填空题;
                    break;
                case "矩阵单选题":
                    typeID = (int)Enums.QuestionType.矩阵单选题;
                    break;
                case "矩阵多选题":
                    typeID = (int)Enums.QuestionType.矩阵多选题;
                    break;
                default:
                    break;
            }
            return typeID;
        }

        public static int GetCountTypeByName(string typeName)
        {
            int typeID = 0;
            switch (typeName)
            {
                case "正确得分":
                    typeID = (int)Enums.QuestionCountType.正确得分;
                    break;
                case "错误扣分":
                    typeID = (int)Enums.QuestionCountType.错误扣分;
                    break;
                case "全部正确得分":
                    typeID = (int)Enums.QuestionCountType.全部正确得分;
                    break;
                case "选项分总和":
                    typeID = (int)Enums.QuestionCountType.选项分总和;
                    break;
                case "不得分不扣分":
                    typeID = (int)Enums.QuestionCountType.不得分不扣分;
                    break;
                default:
                    typeID = (int)Enums.QuestionCountType.不得分不扣分;
                    break;
            }
            return typeID;
        }

        public static int GetQuaterOfMonth(int month)
        {
            int quater = 0;
            if (month >= 1 && month <= 3)
            {
                quater = 1;
            }
            else if (month >= 4 && month <= 6)
            {
                quater = 2;
            }
            else if (month >= 7 && month <= 9)
            {
                quater = 3;
            }
            else if (month >= 10 && month <= 12)
            {
                quater = 4;
            }
            return quater;
        }

        public static int GetQuaterFirstMonth(int quater)
        {
            int month = 0;
            if (quater == 1)
            {
                month = 1;
            }
            else if (quater == 2)
            {
                month = 4;
            }
            else if (quater == 3)
            {
                month = 7;
            }
            else if (quater == 4)
            {
                month = 10;
            }
            return month;
        }

        public static DataTable GetPeriod(int frequency, DateTime fromdate, DateTime todate)
        {
            DataTable dt = new DataTable();
            dt.Columns.Add("Name", typeof(string));
            dt.Columns.Add("Value", typeof(string));
            if (frequency == 1)
            {
                while (fromdate <= todate)
                {
                    DateTime tempDate = fromdate.AddDays(6);
                    if (tempDate > todate)
                    {
                        tempDate = todate;
                    }
                    string name = fromdate.ToString("yyyy.MM.dd") + " - " + tempDate.ToString("yyyy.MM.dd");
                    string value = name;
                    dt.Rows.Add(name, value);

                    fromdate = fromdate.AddDays(7);
                }
            }
            else if (frequency == 2)
            {
                int currentYear = fromdate.Year;
                int currentMonth = fromdate.Month;
                int lastYear = todate.Year;
                int lastMonth = todate.Month;

                while (new DateTime(currentYear, currentMonth, 1) <= new DateTime(lastYear, lastMonth, 1))
                {
                    DateTime tempMonthFirstDate = new DateTime(currentYear, currentMonth, 1);
                    DateTime tempMonthLastDate = tempMonthFirstDate.AddMonths(1).AddDays(-1);
                    if (tempMonthFirstDate < fromdate)
                    {
                        tempMonthFirstDate = fromdate;
                    }
                    if (tempMonthLastDate > todate)
                    {
                        tempMonthLastDate = todate;
                    }
                    string value = tempMonthFirstDate.ToString("yyyy.MM.dd") + " - " + tempMonthLastDate.ToString("yyyy.MM.dd");
                    string name = currentYear + "年" + currentMonth + "月";
                    dt.Rows.Add(name, value);

                    currentMonth++;
                    if (currentMonth > 12)
                    {
                        currentMonth = currentMonth % 12;
                        currentYear++;
                    }
                }
            }
            else if (frequency == 3)
            {
                int currentYear = fromdate.Year;
                int currentMonth = fromdate.Month;
                int lastYear = todate.Year;
                int lastMonth = todate.Month;
                int firstQuater = CommonFunction.GetQuaterOfMonth(currentMonth);
                int firstMonthOfFirstQuater = CommonFunction.GetQuaterFirstMonth(firstQuater);
                while (new DateTime(currentYear, firstMonthOfFirstQuater, 1) <= new DateTime(lastYear, lastMonth, 1))
                {
                    DateTime tempMonthFirstDate = new DateTime(currentYear, firstMonthOfFirstQuater, 1);
                    DateTime tempMonthLastDate = tempMonthFirstDate.AddMonths(3).AddDays(-1);
                    if (tempMonthFirstDate < fromdate)
                    {
                        tempMonthFirstDate = fromdate;
                    }
                    if (tempMonthLastDate > todate)
                    {
                        tempMonthLastDate = todate;
                    }
                    string value = tempMonthFirstDate.ToString("yyyy.MM.dd") + " - " + tempMonthLastDate.ToString("yyyy.MM.dd");
                    string name = currentYear + "年" + currentMonth + "季度";
                    dt.Rows.Add(name, value);

                    firstMonthOfFirstQuater += 3;
                    if (firstMonthOfFirstQuater > 12)
                    {
                        firstMonthOfFirstQuater = firstMonthOfFirstQuater % 12;
                        currentYear++;
                    }
                }
            }
            else if (frequency == 4)
            {
                int currentYear = fromdate.Year;
                int currentMonth = fromdate.Month;
                int lastYear = todate.Year;
                int lastMonth = todate.Month;
                int firstMonthOfHalfYear = currentMonth > 6 ? 7 : 1;
                while (new DateTime(currentYear, firstMonthOfHalfYear, 1) <= new DateTime(lastYear, lastMonth, 31))
                {
                    DateTime tempMonthFirstDate = new DateTime(currentYear, firstMonthOfHalfYear, 1);
                    DateTime tempMonthLastDate = tempMonthFirstDate.AddMonths(3).AddDays(-1);
                    if (tempMonthFirstDate < fromdate)
                    {
                        tempMonthFirstDate = fromdate;
                    }
                    if (tempMonthLastDate > todate)
                    {
                        tempMonthLastDate = todate;
                    }
                    string value = tempMonthFirstDate.ToString("yyyy.MM.dd") + " - " + tempMonthLastDate.ToString("yyyy.MM.dd");
                    string strHalfYear = "上";
                    if (currentMonth > 6)
                    {
                        strHalfYear = "下";
                    }
                    string name = currentYear + "年" + strHalfYear + "半年";
                    dt.Rows.Add(name, value);

                    firstMonthOfHalfYear += 6;
                    if (firstMonthOfHalfYear > 12)
                    {
                        firstMonthOfHalfYear = firstMonthOfHalfYear % 12;
                        currentYear++;
                    }
                }
            }
            else if (frequency == 5)
            {
                int currentYear = fromdate.Year;
                int lastYear = todate.Year;
                while (currentYear <= lastYear)
                {
                    DateTime tempMonthFirstDate = new DateTime(currentYear, 1, 1);
                    DateTime tempMonthLastDate = tempMonthFirstDate.AddYears(1).AddDays(-1);
                    if (tempMonthFirstDate < fromdate)
                    {
                        tempMonthFirstDate = fromdate;
                    }
                    if (tempMonthLastDate > todate)
                    {
                        tempMonthLastDate = todate;
                    }
                    string value = tempMonthFirstDate.ToString("yyyy.MM.dd") + " - " + tempMonthLastDate.ToString("yyyy.MM.dd");
                    string name = currentYear + "年";
                    dt.Rows.Add(name, value);

                    currentYear += 1;
                }
            }
            return dt;
        }

        public static int GetNextStatusByUserType(int userType)
        {
            int status = 0;
            switch (userType)
            {
                case (int)Enums.UserType.访问员:
                    status = (int)Enums.QuestionnaireStageStatus.录入中;
                    break;
                case (int)Enums.UserType.执行督导:
                    status = (int)Enums.QuestionnaireStageStatus.执行督导审核中;
                    break;
                case (int)Enums.UserType.区控:
                    status = (int)Enums.QuestionnaireStageStatus.区控审核中;
                    break;
                case (int)Enums.UserType.质控员:
                    status = (int)Enums.QuestionnaireStageStatus.质控审核中;
                    break;
                case (int)Enums.UserType.质控督导:
                    status = (int)Enums.QuestionnaireStageStatus.质控督导审核中;
                    break;
                default:
                    break;
            }
            return status;
        }

        public static string GetUserActionInfo(int userID, DateTime inputdate)
        {
            string info = string.Empty;
            if (userID > 0)
            {
                string name = APUserManager.GetUserByID(userID).UserName;
                string strDate = inputdate.ToString("yyyy-MM-dd HH:mm");
                info = name + " " + strDate;
            }
            return info;
        }

        public static string FixedSpecialCharsInFileName(string fileName)
        {
            string result = fileName;
            string invalid = new string(Path.GetInvalidFileNameChars()) + new string(Path.GetInvalidPathChars());
            foreach (char c in invalid)
            {
                result = result.Replace(c.ToString(), "");
            }
            return result;
        }

        //提供加密N次  
        public static string EncodeBase64(string mingwen, int times)
        {
            int num = (times <= 0) ? 1 : times;
            string code = "";
            if (string.IsNullOrEmpty(mingwen) == false)
            {
                code = mingwen;
                for (int i = 0; i < num; i++)
                {
                    code = EncodeBase64(code);
                }
            }
            return code;
        }
        //对应提供解密N次  
        public static string DecodeBase64(string mi, int times)
        {
            int num = (times <= 0) ? 1 : times;
            string mingwen = "";
            if (string.IsNullOrEmpty(mi) == false)
            {
                mingwen = mi;
                for (int i = 0; i < num; i++)
                {
                    mingwen = DecodeBase64(mingwen);
                }
            }
            return mingwen;
        }

        public static string EncodeBase64(string mingwen)
        {
            string code = "";
            if (string.IsNullOrEmpty(mingwen) == false)
            {
                byte[] inArray = System.Text.Encoding.UTF8.GetBytes(mingwen);
                code = Convert.ToBase64String(inArray);
            }
            return code;
        }

        public static string DecodeBase64(string mi)
        {
            string mingwen = "";
            if (string.IsNullOrEmpty(mi) == false)
            {
                byte[] inArray = Convert.FromBase64String(mi);
                mingwen = System.Text.Encoding.UTF8.GetString(inArray);
            }
            return mingwen;
        }

        public static String FormatFileSize(Int64 fileSize)
        {
            if (fileSize < 0)
            {
                throw new ArgumentOutOfRangeException("fileSize");
            }
            else if (fileSize >= 1024 * 1024 * 1024)
            {
                return string.Format("{0:########0.00} GB", ((Double)fileSize) / (1024 * 1024 * 1024));
            }
            else if (fileSize >= 1024 * 1024)
            {
                return string.Format("{0:####0.00} MB", ((Double)fileSize) / (1024 * 1024));
            }
            else if (fileSize >= 1024)
            {
                return string.Format("{0:####0.00} KB", ((Double)fileSize) / 1024);
            }
            else
            {
                return string.Format("{0} bytes", fileSize);
            }
        }

        /// <summary>
        /// 获取客户端IP地址（无视代理）
        /// </summary>
        /// <returns>若失败则返回回送地址</returns>
        public static string GetHostAddress()
        {
            string userHostAddress = HttpContext.Current.Request.UserHostAddress;

            if (string.IsNullOrEmpty(userHostAddress))
            {
                userHostAddress = HttpContext.Current.Request.ServerVariables["REMOTE_ADDR"];
            }

            //最后判断获取是否成功，并检查IP地址的格式（检查其格式非常重要）
            if (!string.IsNullOrEmpty(userHostAddress) && IsIP(userHostAddress))
            {
                return userHostAddress;
            }
            return "127.0.0.1";
        }

        /// <summary>
        /// 检查IP地址格式
        /// </summary>
        /// <param name="ip"></param>
        /// <returns></returns>
        public static bool IsIP(string ip)
        {
            return System.Text.RegularExpressions.Regex.IsMatch(ip, @"^((2[0-4]\d|25[0-5]|[01]?\d\d?)\.){3}(2[0-4]\d|25[0-5]|[01]?\d\d?)$");
        }

        public static string StringToJsonString(string s)
        {
            StringBuilder sb = new StringBuilder();
            for (int i = 0; i < s.Length; i++)
            {

                char c = s[i];
                switch (c)
                {
                    case '\"':
                        sb.Append("\\\"");
                        break;
                    case '\\':
                        sb.Append("\\\\");
                        break;
                    case '/':
                        sb.Append("\\/");
                        break;
                    case '\b':
                        sb.Append("\\b");
                        break;
                    case '\f':
                        sb.Append("\\f");
                        break;
                    case '\n':
                        sb.Append("\\n");
                        break;
                    case '\r':
                        sb.Append("\\r");
                        break;
                    case '\t':
                        sb.Append("\\t");
                        break;
                    default:
                        sb.Append(c);
                        break;
                }
            }
            return sb.ToString();
        }

        public static string GetStringValue(object obj)
        {
            if (obj == null)
            {
                return null;
            }
            return obj.ToString();
        }

        public static int GetIntValue(object obj)
        {
            if (obj == null)
            {
                return 0;
            }
            int val = 0;
            int.TryParse(obj.ToString(), out val);
            return val;
        }

        public static decimal GetDecimalValue(object obj)
        {
            if (obj == null)
            {
                return 0;
            }
            decimal val = 0;
            decimal.TryParse(obj.ToString(), out val);
            return val;
        }

        public static bool GetBoolValue(object obj)
        {
            if (obj == null)
            {
                return false;
            }
            bool val = false;
            bool.TryParse(obj.ToString(), out val);
            return val;
        }

        public static TimeSpan GetTimeSpanValue(object obj)
        {
            TimeSpan val = TimeSpan.MinValue;
            if (obj == null)
            {
                return val;
            }
            TimeSpan.TryParse(obj.ToString(), out val);
            return val;
        }

        public static DateTime GetDateTimeValue(object obj)
        {
            if (obj == null)
            {
                return Constants.Date_Null;
            }
            string strValue = obj.ToString();
            DateTime createTime = Constants.Date_Null;
            DateTime.TryParse(strValue, out createTime);
            if (createTime <= Constants.Date_Min)
            {
                double dbValue = 0;
                double.TryParse(strValue, out dbValue);
                try
                {
                    createTime = DateTime.FromOADate(dbValue);
                }
                catch { }
            }
            return createTime;
        }

        public static void DownloadFile(string url, string filePath) 
        {
            int attempt = 5;
            while (File.Exists(filePath) == false && attempt > 0)
            {
                try
                {
                    DownloadFileInstance(url, filePath);
                }
                catch { }
            }
        }

        public static void DownloadFileInstance(string url, string filePath)
        {
            Uri downUri = new Uri(url);
            HttpWebRequest hwr = (HttpWebRequest)WebRequest.Create(downUri);
            using (Stream stream = hwr.GetResponse().GetResponseStream())
            {
                using (FileStream fs = new FileStream(filePath, FileMode.Create))
                {
                    byte[] bytes = new byte[1024];
                    int n = 1;
                    while (n > 0)
                    {
                        n = stream.Read(bytes, 0, 1024);
                        fs.Write(bytes, 0, n);
                    }
                }
            }
        }

        public static string GetFileNameInUrl(string url) 
        {
            string fileName = string.Empty;
            if (url.Contains("?"))
            {
                string realUrl = url.Substring(0, url.LastIndexOf('?'));
                fileName = realUrl.Substring(realUrl.LastIndexOf('/') + 1);
            }
            else 
            {
                fileName = url.Substring(url.LastIndexOf('/') + 1);
            }
            return fileName;
        }

        public static String StringToJson(String s)
        {
            StringBuilder sb = new StringBuilder();
            for (int i = 0; i < s.Length; i++)
            {
                char c = s[i];
                switch (c)
                {
                    case '\"':
                        sb.Append("\\\"");
                        break;
                    case '\\':
                        sb.Append("\\\\");
                        break;
                    case '/':
                        sb.Append("\\/");
                        break;
                    case '\b':
                        sb.Append("\\b");
                        break;
                    case '\f':
                        sb.Append("\\f");
                        break;
                    case '\n':
                        sb.Append("\\n");
                        break;
                    case '\r':
                        sb.Append("\\r");
                        break;
                    case '\t':
                        sb.Append("\\t");
                        break;
                    default:
                        sb.Append(c);
                        break;
                }
            }
            return sb.ToString();
        }


        /// <summary>
        /// 文字水印
        /// </summary>
        /// <param name="imgPath">服务器图片相对路径</param>
        /// <param name="filename">保存文件名</param>
        /// <param name="watermarkText">水印文字</param>
        /// <param name="watermarkStatus">图片水印位置 0=不使用 1=左上 2=中上 3=右上 4=左中  9=右下</param>
        /// <param name="quality">附加水印图片质量,0-100</param>
        /// <param name="fontsize">字体大小</param>
        /// <param name="fontname">字体</param>
        public static void AddImageSignText(string imgPath, string filename, string watermarkText, int watermarkStatus, int quality, int fontsize, string fontname = "微软雅黑")
        {
            try
            {
                byte[] _ImageBytes = File.ReadAllBytes(imgPath);
                Image img = Image.FromStream(new System.IO.MemoryStream(_ImageBytes));

                int sizeTimes = img.Width / 150;
                fontsize = fontsize + sizeTimes * 2;

                Graphics g = Graphics.FromImage(img);
                Font drawFont = new Font(fontname, fontsize, FontStyle.Regular, GraphicsUnit.Pixel);
                SizeF crSize;
                crSize = g.MeasureString(watermarkText, drawFont);

                float xpos = 0;
                float ypos = 0;

                switch (watermarkStatus)
                {
                    case 1:
                        xpos = (float)img.Width * (float).01;
                        ypos = (float)img.Height * (float).01;
                        break;
                    case 2:
                        xpos = ((float)img.Width * (float).50) - (crSize.Width / 2);
                        ypos = (float)img.Height * (float).01;
                        break;
                    case 3:
                        xpos = ((float)img.Width * (float).99) - crSize.Width;
                        ypos = (float)img.Height * (float).01;
                        break;
                    case 4:
                        xpos = (float)img.Width * (float).01;
                        ypos = ((float)img.Height * (float).50) - (crSize.Height / 2);
                        break;
                    case 5:
                        xpos = ((float)img.Width * (float).50) - (crSize.Width / 2);
                        ypos = ((float)img.Height * (float).50) - (crSize.Height / 2);
                        break;
                    case 6:
                        xpos = ((float)img.Width * (float).99) - crSize.Width;
                        ypos = ((float)img.Height * (float).50) - (crSize.Height / 2);
                        break;
                    case 7:
                        xpos = (float)img.Width * (float).01;
                        ypos = ((float)img.Height * (float).99) - crSize.Height;
                        break;
                    case 8:
                        xpos = ((float)img.Width * (float).50) - (crSize.Width / 2);
                        ypos = ((float)img.Height * (float).99) - crSize.Height;
                        break;
                    case 9:
                        xpos = ((float)img.Width * (float).99) - crSize.Width;
                        ypos = ((float)img.Height * (float).99) - crSize.Height;
                        break;
                }

                g.DrawString(watermarkText, drawFont, new SolidBrush(Color.Black), xpos + 1, ypos + 1);
                g.DrawString(watermarkText, drawFont, new SolidBrush(Color.White), xpos, ypos);

                ImageCodecInfo[] codecs = ImageCodecInfo.GetImageEncoders();
                ImageCodecInfo ici = null;
                foreach (ImageCodecInfo codec in codecs)
                {
                    if (codec.MimeType.IndexOf("jpeg") > -1)
                        ici = codec;
                }
                EncoderParameters encoderParams = new EncoderParameters();
                long[] qualityParam = new long[1];
                if (quality < 0 || quality > 100)
                    quality = 80;

                qualityParam[0] = quality;

                EncoderParameter encoderParam = new EncoderParameter(System.Drawing.Imaging.Encoder.Quality, qualityParam);
                encoderParams.Param[0] = encoderParam;

                if (ici != null)
                    img.Save(filename, ici, encoderParams);
                else
                    img.Save(filename);

                g.Dispose();
                img.Dispose();
            }
            catch { }
        }

        /// <summary>
        /// 生成缩略图
        /// </summary>
        /// <param name="originalImagePath">源图路径（物理路径）</param>
        /// <param name="thumbnailPath">缩略图路径（物理路径）</param>
        /// <param name="width">缩略图宽度</param>
        /// <param name="height">缩略图高度</param>
        /// <param name="mode">生成缩略图的方式</param>    
        public static void MakeThumbnail(string originalImagePath, string thumbnailPath, int width, int height, string mode)
        {
            Image originalImage = Image.FromFile(originalImagePath);

            int towidth = width;
            int toheight = height;

            int x = 0;
            int y = 0;
            int ow = originalImage.Width;
            int oh = originalImage.Height;

            if (string.IsNullOrEmpty(mode))
            {
                if (ow > oh)
                {
                    mode = "W";
                }
                else
                {
                    mode = "H";
                }
            }

            switch (mode)
            {
                case "HW"://指定高宽缩放（可能变形）                
                    break;
                case "W"://指定宽，高按比例                    
                    toheight = originalImage.Height * width / originalImage.Width;
                    break;
                case "H"://指定高，宽按比例
                    towidth = originalImage.Width * height / originalImage.Height;
                    break;
                case "Cut"://指定高宽裁减（不变形）                
                    if ((double)originalImage.Width / (double)originalImage.Height > (double)towidth / (double)toheight)
                    {
                        oh = originalImage.Height;
                        ow = originalImage.Height * towidth / toheight;
                        y = 0;
                        x = (originalImage.Width - ow) / 2;
                    }
                    else
                    {
                        ow = originalImage.Width;
                        oh = originalImage.Width * height / towidth;
                        x = 0;
                        y = (originalImage.Height - oh) / 2;
                    }
                    break;
                default:
                    break;
            }

            //新建一个bmp图片
            Image bitmap = new System.Drawing.Bitmap(towidth, toheight);
            //新建一个画板
            Graphics g = System.Drawing.Graphics.FromImage(bitmap);
            try
            {
                //设置高质量插值法
                g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.High;

                //设置高质量,低速度呈现平滑程度
                g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.HighQuality;

                //清空画布并以透明背景色填充
                g.Clear(Color.Transparent);

                //在指定位置并且按指定大小绘制原图片的指定部分
                g.DrawImage(originalImage, new Rectangle(0, 0, towidth, toheight),
                    new Rectangle(x, y, ow, oh),
                    GraphicsUnit.Pixel);

                //以jpg格式保存缩略图
                bitmap.Save(thumbnailPath, System.Drawing.Imaging.ImageFormat.Jpeg);
            }
            catch (System.Exception e)
            {
                throw e;
            }
            finally
            {
                originalImage.Dispose();
                bitmap.Dispose();
                g.Dispose();
            }
        }

        public static Process StartProcessWorker(string tempfilePath,
string physicalPath,
string vituralPath,
int projectID,
int resultID,
int questionID,
int answerID,
string fromDate,
string clientCode,
string formatFileName,
int fileType,
string watermark,
int typeID,
int userID,
string imageUrl)
        {
            string args = string.Format("\"{0}\" \"{1}\" \"{2}\" \"{3}\" \"{}\" \"{4}\" \"{5}\" \"{6}\" \"{7}\" \"{8}\" \"{9}\" \"{10}\" \"{11}\" \"{12}\" \"{13}\" \"{14}\" \"{15}\"", 
tempfilePath,
physicalPath,
vituralPath,
projectID,
resultID,
questionID,
answerID,
fromDate,
clientCode,
formatFileName,
fileType,
watermark,
typeID,
userID,
imageUrl);
            Process p = new Process();
            string proPath = AppDomain.CurrentDomain.SetupInformation.ApplicationBase.TrimEnd('\\') + "\\ReadImageFromICTR.exe";
            p.StartInfo.FileName = proPath;
            p.StartInfo.Arguments = args;
            p.StartInfo.UseShellExecute = false;
            p.StartInfo.CreateNoWindow = true;
            p.Start();

            return p;
        }
    }
}