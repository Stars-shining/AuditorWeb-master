using System;
using System.Data;
using System.Collections;
using System.Text;
using System.Collections.Generic;
using Aspose.Cells;
using System.Drawing;
using DocumentFormat.OpenXml.Packaging;
using System.Text.RegularExpressions;
using System.IO;
using System.Data.OleDb;

namespace APLibrary
{
    public class ParseExcel
    {
        private class FormatHelper
        {
            private static readonly string[] FormatKeys = { CellStyle.A_AFNP, CellStyle.A_RA, CellStyle.A_LA, CellStyle.A_TA, CellStyle.A_BA, CellStyle.A_CA };

            private static Dictionary<string, string> formatString = null;
            private static Dictionary<string, string> FormatString
            {
                get
                {
                    if (formatString == null || formatString.Count == 0)
                    {
                        formatString = new Dictionary<string, string>();
                        formatString.Add("N", "###,###,###,##0{0}");
                        formatString.Add("C", "$###,###,###,##0{0}");
                        formatString.Add("$", "$###,###,###,##0{0}");
                        formatString.Add("P", "###,###,###,##0{0}%");
                        formatString.Add("%", "###,###,###,##0{0}%");
                    }
                    return formatString;
                }
            }
            public static string ReplaceFormatKey(string columnName)
            {
                string rtn = columnName;
                foreach (string key in FormatKeys)
                {
                    if (rtn.Contains(key))
                    {
                        rtn = rtn.Replace(key, "");
                    }
                }
                return rtn;
            }
            public static Cell AutoFormatValue(Cell cell, object val, string format)
            {
                if (AutoFormatValueByKey(ref cell, val, format))
                {
                    return cell;
                }

                // following code will auto formate data like units, amount, percentage
                string strFormat = GetFormatString(format);
                if (string.IsNullOrEmpty(strFormat))
                {
                    strFormat = ConvertFormatString(val.ToString());
                }


                if (string.IsNullOrEmpty(strFormat) == false)
                {
                    strFormat = GetFormatString(strFormat);
                    decimal d = ConvertValue(val);
                    Aspose.Cells.Style style = cell.GetStyle();
                    style.Custom = strFormat;
                    cell.PutValue(d);
                    cell.SetStyle(style);
                }
                else
                {
                    cell.PutValue(val);
                }
                return cell;
            }

            /// <summary>
            /// AutoFormatValueByKey
            /// format cell display by "CellStyle.A_..."
            /// if CellStyle.A_AFNP exists return true, next auto format(AutoFormatValue) will not execute, otherwise execute
            /// alignment setting will return false, to execute AutoFormatValue
            /// </summary>
            /// <param name="cell">taget cell</param>
            /// <param name="val">cell value</param>
            /// <param name="format">CellStyle.A_... setting, which contain in column name</param>
            /// <returns></returns>
            public static bool AutoFormatValueByKey(ref Cell cell, object val, string format)
            {
                bool rtn = false;
                if (string.IsNullOrEmpty(format))
                {
                    return rtn;
                }

                if (format.Contains(CellStyle.A_AFNP))
                {
                    string tempvalue = val.ToString();
                    DateTime date = Constants.Date_Null;
                    if ((tempvalue.Length == 10 || tempvalue.Length == 8 || tempvalue.Length == DateTime.Now.ToString().Length)
                        && DateTime.TryParse(tempvalue, out date))
                    {
                        Aspose.Cells.Style style = cell.GetStyle();
                        //check if the string is like 'hh:mm:ss'
                        if (Regex.IsMatch(tempvalue, @"\d{1,2}:\d{1,2}:\d{1,2}", RegexOptions.IgnoreCase))
                        {
                            style.Custom = "HH:mm:ss";
                            //treat it as string, avoid it auto add date to the value
                            cell.PutValue(tempvalue);
                        }
                        else
                        {
                            if (tempvalue.Length == 10)
                            {
                                style.Custom = "dd/MM/yyyy";
                            }
                            else
                            {
                                style.Custom = "dd/MM/yy";
                            }
                            cell.PutValue(date);
                        }
                        cell.SetStyle(style);
                    }
                    //add to treate decimal value when has no auto format
                    else if (Regex.IsMatch(tempvalue.Trim(), @"^[-]?[$][-]?[\d,.]*\d+$", RegexOptions.IgnoreCase)
                        || Regex.IsMatch(tempvalue.Trim(), @"^[-]?[\d,.]*\d+[%]$", RegexOptions.IgnoreCase))
                    {
                        Aspose.Cells.Style style = cell.GetStyle();
                        string strFormat = ConvertFormatString(tempvalue);
                        strFormat = GetFormatString(strFormat);
                        style.Custom = strFormat;
                        decimal cellvalue = CommonFunction.GetDeciamlFromCurrency(tempvalue, true);
                        cell.PutValue(cellvalue);
                        cell.SetStyle(style);
                    }
                    else
                    {
                        //cell.PutValue(tempvalue, true);
                        if (tempvalue.Contains("@@@@"))
                        {
                            string text = tempvalue.Substring(0, tempvalue.IndexOf("@@@@"));
                            cell.PutValue(text);

                            string url = tempvalue.Substring(tempvalue.IndexOf("@@@@") + 4);
                            cell.Worksheet.Hyperlinks.Add(cell.Row, cell.Column, 1, 1, url);
                            Aspose.Cells.Style style = cell.GetStyle();
                            style.Font.Underline = FontUnderlineType.Accounting;
                            cell.SetStyle(style);
                        }
                        else
                        {
                            cell.PutValue(tempvalue);
                        }
                    }
                    rtn = true;
                }

                // alignment only, will return false
                #region
                if (format.Contains(CellStyle.A_RA))
                {
                    Aspose.Cells.Style style = cell.GetStyle();
                    style.HorizontalAlignment = TextAlignmentType.Right;
                    cell.SetStyle(style);
                    // alignment only, will return false
                    rtn = rtn || false;
                }
                else if (format.Contains(CellStyle.A_LA))
                {
                    Aspose.Cells.Style style = cell.GetStyle();
                    style.HorizontalAlignment = TextAlignmentType.Left;
                    cell.SetStyle(style);
                    // alignment only, will return false
                    rtn = rtn || false;
                }
                else if (format.Contains(CellStyle.A_BA))
                {
                    Aspose.Cells.Style style = cell.GetStyle();
                    style.HorizontalAlignment = TextAlignmentType.Bottom;
                    cell.SetStyle(style);
                    // alignment only, will return false
                    rtn = rtn || false;
                }
                else if (format.Contains(CellStyle.A_TA))
                {
                    Aspose.Cells.Style style = cell.GetStyle();
                    style.HorizontalAlignment = TextAlignmentType.Top;
                    cell.SetStyle(style);
                    // alignment only, will return false
                    rtn = rtn || false;
                }
                else if (format.Contains(CellStyle.A_CA))
                {
                    Aspose.Cells.Style style = cell.GetStyle();
                    style.HorizontalAlignment = TextAlignmentType.Center;
                    cell.SetStyle(style);
                    // alignment only, will return false
                    rtn = rtn || false;
                }
                #endregion

                return rtn;
            }

            private static string ConvertValueText(object obj)
            {
                string rtn = string.Empty;
                if (obj != null)
                {
                    string val = obj.ToString();
                    bool isPercentage = false;
                    if (val.IndexOf("%") == val.Length - 1)
                    {
                        isPercentage = true;
                    }
                    val = val.Replace("$", "");
                    val = val.Replace("%", "");
                    rtn = val.Trim();
                }
                return rtn;
            }
            private static decimal ConvertValue(object obj)
            {
                decimal rtn = decimal.Zero;
                if (obj != null)
                {
                    string val = obj.ToString();
                    bool isPercentage = false;
                    if (val.IndexOf("%") == val.Length - 1)
                    {
                        isPercentage = true;
                    }
                    val = val.Replace("$", "");
                    val = val.Replace("%", "");
                    val = val.Trim();
                    if (decimal.TryParse(val, out rtn) && isPercentage)
                    {
                        rtn = rtn / 100;
                    }
                }
                return rtn;
            }

            private static string ConvertFormatString(string val)
            {
                string head = "";
                val = val.Trim();
                if (val == "")
                {
                    return "";
                }
                if (val.IndexOf("$") == 0 || val.IndexOf("$") == 1)
                {
                    head = "C";
                }
                else if (val.IndexOf("%") == val.Length - 1)
                {
                    head = "P";
                }
                else
                {
                    decimal d = decimal.Zero;
                    if (decimal.TryParse(val, out d) == true)
                    {
                        head = "N";
                    }
                }

                if (string.IsNullOrEmpty(head))
                {
                    return "";
                }

                string tmp = ConvertValueText(val);
                tmp = tmp.Trim();
                if (tmp.IndexOf(".") >= 0)
                {
                    tmp = tmp.Substring(tmp.IndexOf(".")).Replace(".", "");
                }
                else
                {
                    tmp = "";
                }
                head = head + (tmp.Length).ToString();
                return head;
            }
            private static string GetFormatString(string format)
            {
                if (string.IsNullOrEmpty(format))
                    return "";
                if (format.Length != 2)
                    return "";

                string head = format.Substring(0, 1);
                if (FormatString.ContainsKey(head) == false)
                {
                    return "";
                }

                string rtn = formatString[head];

                int len = int.Parse(format.Substring(1, 1));
                string padding = ".";
                for (int i = len; i > 0; i--)
                {
                    padding = padding + "0";
                }

                padding = padding == "." ? "" : padding;

                rtn = string.Format(rtn, padding);
                return rtn;
            }
        }
        public class TableName
        {
            public const string Style = "Style";
            public const string Data = "Data";
            public const string Info = "Info";
            public const string Desc = "Description";
            //extend the function to enable set row style
            public const string RowStyle = "RowStyle";
        }
        public class RowType
        {
            public const string DataRows = "0";
            public const string HeaderRows = "1";
            public const string FooterRows = "2";
            public const string ColumnName = "3";
            public const string Alignment = "4";
        }

        public class CellStyle
        {
            public const string FONTBOLD = "bold";
            public const string FONTSIZE = "fontsize";
            public const string ALIGN_RIGHT = "right";
            public const string ALIGN_LEFT = "left";
            public const string ALIGN_CENTER = "center";
            public const string BG_YELLOW = "bg_yellow";
            public const string A_AFNP = "_AutoFormatNotApply";
            public const string A_RA = "_RightAlign";
            public const string A_LA = "_LeftAlign";
            public const string A_TA = "_TopAlign";
            public const string A_BA = "_ButtomAlign";
            public const string A_CA = "_CenterAlign";
            public const string TEXTWRAPPED = "TextWrapped";
        }

        public const string C_CustomStyle = "CustomStyle";
        public const string C_RowType = "RowType";
        public const string C_ColumnIndex = "ColumnIndex";
        public const string C_StyleIndex = "StyleIndex";


        private static readonly string[] alphabet = { "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z" };
        private static readonly string W_DataRows = C_RowType + "=" + RowType.DataRows;
        private static readonly string W_HeaderRows = C_RowType + "=" + RowType.HeaderRows;
        private static readonly string W_FooterRows = C_RowType + "=" + RowType.FooterRows;
        private static readonly string W_ColumnName = C_RowType + "=" + RowType.ColumnName;
        private static readonly string W_Alignment = C_RowType + "=" + RowType.Alignment;
        //private static readonly string W_ColumnWidth = C_RowType + "=" + RowType.ColumnWidth;

        public static string CreateExcel(string path, DataSet ds, float[] columnWidths)
        {
            return CreateExcel(path, ds, columnWidths, 0, 0);
        }
        public static string CreateExcel(string path, System.Data.DataSet ds, float[] columnWidths, int offset_row, int offset_col)
        {
            try
            {
                Workbook workbook1 = new Workbook();
                Worksheet worksheet1 = (Worksheet)workbook1.Worksheets["sheet1"];

                int added = 0;

                DataTable dt = ds.Tables[TableName.Data];
                DataTable dtInfo = new DataTable();
                DataTable dtStyle = GetStyleTable();
                if (ds.Tables.Contains(TableName.Style))
                {
                    dtStyle = ds.Tables[TableName.Style];
                }

                DataTable dtRowStyle = GetRowStyleTable();
                if (ds.Tables.Contains(TableName.RowStyle))
                {
                    dtRowStyle = ds.Tables[TableName.RowStyle];
                }

                for (int c = 0; c < columnWidths.Length; c++)
                {
                    worksheet1.Cells.SetColumnWidth(c, columnWidths[c]);
                }

                // [1] header rows
                if (ds.Tables.Contains(TableName.Info))
                {
                    dtInfo = ds.Tables[TableName.Info];
                    added = FillWorksheet(dtInfo, dtStyle, null, W_HeaderRows, ref worksheet1, offset_row, offset_col);
                    offset_row += added;
                }

                // [2] column name row
                DataRow[] drsStyle = dtStyle.Select(W_ColumnName);
                DataRow[] drsAlignment = dtStyle.Select(W_Alignment);

                //in trial balance case , the last two columns is customstyle and rowtype, will remove the column when overlook the all data to compose cell
                //now the case support to row style, may not have the two columns
                //not to ignore the last two column by index, change to igonre then by columnname
                for (int c = 0; c < dt.Columns.Count; c++)
                {
                    //if current column is rowstyle.rowuniqureid, ignore it,just used to find mapping row style
                    string colname = dt.Columns[c].ColumnName;
                    bool btempcolumn = CheckIsTempColumn(colname);
                    if (btempcolumn)
                    {
                        continue;
                    }

                    int rowIndex = offset_row;
                    int colIndex = offset_col + c;
                    string cellName = GetCell(rowIndex, colIndex);

                    Cell cell = worksheet1.Cells[rowIndex, colIndex];
                    cell.Value = colname;
                    cell = SetStyle(cell, ParseExcel.CellStyle.FONTBOLD);

                    foreach (DataRow dr in drsStyle)
                    {
                        if (dr[ParseExcel.C_ColumnIndex].ToString() == c.ToString())
                        {
                            cell = SetStyle(cell, dr[ParseExcel.C_CustomStyle].ToString());
                        }
                    }

                    foreach (DataRow dr in drsAlignment)
                    {
                        if (dr[ParseExcel.C_ColumnIndex].ToString() == c.ToString())
                        {
                            cell = SetStyle(cell, dr[ParseExcel.C_CustomStyle].ToString());
                        }
                    }

                }
                offset_row += 1;

                // [3] data rows
                added = FillWorksheet(dt, dtStyle, dtRowStyle, drsAlignment, W_DataRows, ref worksheet1, offset_row, offset_col);
                offset_row += added;


                // [4] footer rows
                if (ds.Tables.Contains(TableName.Info))
                {
                    added = FillWorksheet(dtInfo, dtStyle, null, W_FooterRows, ref worksheet1, offset_row, offset_col);
                    offset_row += added;
                }

                // save and close objects
                workbook1.Save(path);
                DeleteSheet(path, 1);

            }
            catch (Exception e)
            {
                return "65002";
            }
            return null;
        }

        public static string CreateExcel_WidthStyle(string sheetName, string path, System.Data.DataSet ds, float[] columnWidths, int offset_row, int offset_col)
        {
            try
            {
                Workbook workbook1 = new Workbook();
                Worksheet worksheet1 = (Worksheet)workbook1.Worksheets["sheet1"];
                worksheet1.Name = sheetName;

                int added = 0;

                DataTable dt = ds.Tables[TableName.Data];
                DataTable dtInfo = new DataTable();
                DataTable dtStyle = GetStyleTable();
                if (ds.Tables.Contains(TableName.Style))
                {
                    dtStyle = ds.Tables[TableName.Style];
                }

                DataTable dtRowStyle = GetRowStyleTable();
                if (ds.Tables.Contains(TableName.RowStyle))
                {
                    dtRowStyle = ds.Tables[TableName.RowStyle];
                }

                for (int c = 0; c < columnWidths.Length; c++)
                {
                    worksheet1.Cells.SetColumnWidth(c, columnWidths[c]);
                }

                // [1] header rows
                if (ds.Tables.Contains(TableName.Info))
                {
                    dtInfo = ds.Tables[TableName.Info];
                    added = FillWorksheet(dtInfo, dtStyle, null, W_HeaderRows, ref worksheet1, offset_row, offset_col);
                    offset_row += added;
                }

                // [2] column name row
                DataRow[] drsStyle = dtStyle.Select(W_ColumnName);
                DataRow[] drsAlignment = dtStyle.Select(W_Alignment);

                //in trial balance case , the last two columns is customstyle and rowtype, will remove the column when overlook the all data to compose cell
                //now the case support to row style, may not have the two columns
                //not to ignore the last two column by index, change to igonre then by columnname
                for (int c = 0; c < dt.Columns.Count; c++)
                {
                    //if current column is rowstyle.rowuniqureid, ignore it,just used to find mapping row style
                    string colname = dt.Columns[c].ColumnName;
                    bool btempcolumn = CheckIsTempColumn(colname);
                    if (btempcolumn)
                    {
                        continue;
                    }
                    if (colname.Contains("宣传片")) {
                        colname = "节目内容";
                    }

                    int rowIndex = offset_row;
                    int colIndex = offset_col + c;
                    string cellName = GetCell(rowIndex, colIndex);

                    Cell cell = worksheet1.Cells[rowIndex, colIndex];
                    cell.Value = colname;
                    cell = SetStyle(cell, ParseExcel.CellStyle.FONTBOLD);

                    foreach (DataRow dr in drsStyle)
                    {
                        if (dr[ParseExcel.C_ColumnIndex].ToString() == c.ToString())
                        {
                            cell = SetStyle(cell, dr[ParseExcel.C_CustomStyle].ToString());
                        }
                    }

                    foreach (DataRow dr in drsAlignment)
                    {
                        if (dr[ParseExcel.C_ColumnIndex].ToString() == c.ToString())
                        {
                            cell = SetStyle(cell, dr[ParseExcel.C_CustomStyle].ToString());
                        }
                    }
                    Aspose.Cells.Style style = cell.GetStyle();
                    style.VerticalAlignment = TextAlignmentType.Center;
                    style.ForegroundColor = Color.White;
                    style.Borders[BorderType.TopBorder].LineStyle = CellBorderType.Thin;
                    style.Borders[BorderType.TopBorder].Color = Color.Black;
                    style.Borders[BorderType.BottomBorder].LineStyle = CellBorderType.Thin;
                    style.Borders[BorderType.BottomBorder].Color = Color.Black;
                    style.Borders[BorderType.LeftBorder].LineStyle = CellBorderType.Thin;
                    style.Borders[BorderType.LeftBorder].Color = Color.Black;
                    style.Borders[BorderType.RightBorder].LineStyle = CellBorderType.Thin;
                    style.Borders[BorderType.RightBorder].Color = Color.Black;

                    style.Font.Size = 12;

                    cell.SetStyle(style);
                    if (colname == "节目内容")
                    {
                        break;
                    }
                }
                offset_row += 1;

                worksheet1.Cells.Merge(0, 5, 1, 8);
                worksheet1.Cells.SetRowHeight(0, 20);
                for (int i = 5; i <= 12; i++)
                {
                    Cell lastHeaderCell = worksheet1.Cells[0, i];
                    Aspose.Cells.Style headerStyle = lastHeaderCell.GetStyle();
                    headerStyle.Borders[BorderType.TopBorder].LineStyle = CellBorderType.Thin;
                    headerStyle.Borders[BorderType.TopBorder].Color = Color.Black;
                    headerStyle.Borders[BorderType.BottomBorder].LineStyle = CellBorderType.Thin;
                    headerStyle.Borders[BorderType.BottomBorder].Color = Color.Black;
                    headerStyle.Borders[BorderType.LeftBorder].LineStyle = CellBorderType.Thin;
                    headerStyle.Borders[BorderType.LeftBorder].Color = Color.Black;
                    headerStyle.Borders[BorderType.RightBorder].LineStyle = CellBorderType.Thin;
                    headerStyle.Borders[BorderType.RightBorder].Color = Color.Black;

                    headerStyle.Font.Size = 12;

                    lastHeaderCell.SetStyle(headerStyle);
                }

                // [3] data rows
                added = FillWorksheet_New(dt, dtStyle, dtRowStyle, drsAlignment, W_DataRows, ref worksheet1, offset_row, offset_col);
                offset_row += added;

                if (dt != null && dt.Rows.Count > 0)
                {
                    Color backColor = Color.Yellow;
                    Color lightColor = Color.White;
                    int totalColumns = 5 + 8;
                    List<string> channelNameList = new List<string>();
                    int beginRow = 1;
                    int channelCount = 0;
                    for (int i = 0; i < dt.Rows.Count; i++)
                    {

                        worksheet1.Cells.SetRowHeight(i + 1, 60);
                        for (int j = 0; j < totalColumns; j++)
                        {
                            Cell cell = worksheet1.Cells[i + 1, j];
                            if (j == 0) 
                            {
                                string markName = cell.StringValue;
                                if (channelNameList.Contains(markName) == false) 
                                {
                                    channelNameList.Add(markName);
                                    channelCount++;
                                    if (i >= beginRow) 
                                    {
                                        worksheet1.Cells.Merge(beginRow, 0, i + 1 - beginRow, 1);
                                        beginRow = i + 1;
                                    }

                                    if (channelCount % 2 == 0)
                                    {
                                        backColor = Color.Pink;
                                    }
                                    else
                                    {
                                        backColor = Color.Yellow;
                                    }
                                }
                            }
                            Aspose.Cells.Style style = cell.GetStyle();
                            style.IsTextWrapped = true;
                            style.Pattern = BackgroundType.Solid;

                            if ((i + 1 - beginRow) % 2 == 0)
                            {
                                if (string.IsNullOrEmpty(cell.StringValue) == false || j < 4)
                                {
                                    style.ForegroundColor = backColor;
                                }
                            }
                            else if (j > 0)
                            {
                                if (string.IsNullOrEmpty(cell.StringValue) == false || j < 4)
                                {
                                    style.ForegroundColor = lightColor;
                                }
                            }
                            if (j == 0) {
                                style.ForegroundColor = backColor;
                            }
                            style.Borders[BorderType.TopBorder].LineStyle = CellBorderType.Thin;
                            style.Borders[BorderType.TopBorder].Color = Color.Black;
                            style.Borders[BorderType.BottomBorder].LineStyle = CellBorderType.Thin;
                            style.Borders[BorderType.BottomBorder].Color = Color.Black;
                            style.Borders[BorderType.LeftBorder].LineStyle = CellBorderType.Thin;
                            style.Borders[BorderType.LeftBorder].Color = Color.Black;
                            style.Borders[BorderType.RightBorder].LineStyle = CellBorderType.Thin;
                            style.Borders[BorderType.RightBorder].Color = Color.Black;
                            
                            style.Font.Size = 12;

                            if (j == 0)
                            {
                                style.VerticalAlignment = TextAlignmentType.Center;
                            }
                            else
                            {
                                style.VerticalAlignment = TextAlignmentType.Top;
                            }
                            cell.SetStyle(style);
                        }
                    }

                    if (beginRow > 1)
                    {
                        worksheet1.Cells.Merge(beginRow, 0, dt.Rows.Count - beginRow + 1, 1);
                    }
                }
                

                // [4] footer rows
                if (ds.Tables.Contains(TableName.Info))
                {
                    added = FillWorksheet(dtInfo, dtStyle, null, W_FooterRows, ref worksheet1, offset_row, offset_col);
                    offset_row += added;
                }

                //Diego added at 2017-01-03
                if (ds.Tables.Contains(TableName.Desc))
                {
                    DataTable dtDesc = ds.Tables[TableName.Desc];
                    int rowCount = dtDesc.Rows.Count;

                    int inserted = 0;
                    List<string> markNameList = new List<string>();
                    for (int i = 0; i < dt.Rows.Count; i++)
                    {
                        string markName = dt.Rows[i]["频道"].ToString();
                        bool bNeedInsertDesc = false;
                        if (markNameList.Contains(markName) == false && markName == "CCTV-1")
                        {
                            bNeedInsertDesc = true;
                            markNameList.Add(markName);
                        }
                        else if (markNameList.Contains(markName) == false && markName == "CCTV-2")
                        {
                            bNeedInsertDesc = true;
                            markNameList.Add(markName);
                        }
                        else if (markNameList.Contains(markName) == false && markName == "CCTV-3")
                        {
                            bNeedInsertDesc = true;
                            markNameList.Add(markName);
                        }
                        if (bNeedInsertDesc)
                        {
                            int postion = i + inserted;
                            if (postion > 0)
                            {
                                postion++;
                            }
                            worksheet1.Cells.InsertRows(postion, 1);
                            Cell cell = worksheet1.Cells[postion, 0];
                            Style columnStyle = cell.GetStyle();
                            columnStyle.Font.IsBold = true;
                            columnStyle.Font.Size = 12;
                            columnStyle.VerticalAlignment = TextAlignmentType.Center;
                            columnStyle.HorizontalAlignment = TextAlignmentType.Center;
                            columnStyle.ForegroundColor = Color.White;
                            SetBorderStyle(ref columnStyle);
                            cell.SetStyle(columnStyle);
                            cell = AutoFormateValue(cell, dtDesc.Columns[0].ColumnName, dtDesc.Columns[0].DataType);

                            cell = worksheet1.Cells[postion, 1];
                            columnStyle = cell.GetStyle();
                            columnStyle.Font.IsBold = false;
                            columnStyle.Font.Size = 12;
                            columnStyle.VerticalAlignment = TextAlignmentType.Center;
                            columnStyle.HorizontalAlignment = TextAlignmentType.Left;
                            columnStyle.IsTextWrapped = false;
                            columnStyle.ForegroundColor = Color.White;
                            SetBorderStyle(ref columnStyle);
                            cell.SetStyle(columnStyle);
                            cell = AutoFormateValue(cell, dtDesc.Rows[0][0].ToString(), dtDesc.Columns[0].DataType);

                            cell = worksheet1.Cells[postion, 2];
                            columnStyle = cell.GetStyle();
                            columnStyle.Font.IsBold = true;
                            columnStyle.Font.Size = 12;
                            columnStyle.VerticalAlignment = TextAlignmentType.Center;
                            columnStyle.HorizontalAlignment = TextAlignmentType.Center;
                            columnStyle.ForegroundColor = Color.White;
                            SetBorderStyle(ref columnStyle);
                            cell.SetStyle(columnStyle);
                            cell = AutoFormateValue(cell, dtDesc.Columns[1].ColumnName, dtDesc.Columns[1].DataType);

                            cell = worksheet1.Cells[postion, 3];
                            columnStyle = cell.GetStyle();
                            columnStyle.Font.IsBold = false;
                            columnStyle.Font.Size = 12;
                            columnStyle.VerticalAlignment = TextAlignmentType.Center;
                            columnStyle.HorizontalAlignment = TextAlignmentType.Left;
                            columnStyle.ForegroundColor = Color.White;
                            SetBorderStyle(ref columnStyle);
                            cell.SetStyle(columnStyle);
                            cell = AutoFormateValue(cell, dtDesc.Rows[0][1].ToString(), dtDesc.Columns[1].DataType);

                            for (int j = 4; j <= 12; j++)
                            {
                                cell = worksheet1.Cells[postion, j];
                                columnStyle = cell.GetStyle();
                                columnStyle.ForegroundColor = Color.White;
                                SetBorderStyle(ref columnStyle);
                                cell.SetStyle(columnStyle);
                            }

                            worksheet1.Cells.SetRowHeight(postion, 20);

                            inserted++;

                            //Diego added at 2017-02-09
                            if (postion > 0)
                            {
                                worksheet1.Cells.InsertRows(postion + 1, 1);
                                cell = worksheet1.Cells[postion + 1, 0];
                                cell.Copy(worksheet1.Cells[1, 0]);
                                cell = worksheet1.Cells[postion + 1, 1];
                                cell.Copy(worksheet1.Cells[1, 1]);
                                cell = worksheet1.Cells[postion + 1, 2];
                                cell.Copy(worksheet1.Cells[1, 2]);
                                cell = worksheet1.Cells[postion + 1, 3];
                                cell.Copy(worksheet1.Cells[1, 3]);
                                cell = worksheet1.Cells[postion + 1, 4];
                                cell.Copy(worksheet1.Cells[1, 4]);
                                cell = worksheet1.Cells[postion + 1, 5];
                                cell.Copy(worksheet1.Cells[1, 5]);

                                worksheet1.Cells.Merge(postion + 1, 5, 1, 8);
                                worksheet1.Cells.SetRowHeight(postion + 1, 20);
                                inserted++;
                            }
                        }
                    }

                    offset_row += rowCount;
                }

                // save and close objects
                workbook1.Save(path);
                DeleteSheet(path, 1);

            }
            catch (Exception e)
            {
                return "65002";
            }
            return null;
        }

        private static void SetBorderStyle(ref Style style)
        {
            style.Borders[BorderType.TopBorder].LineStyle = CellBorderType.Thin;
            style.Borders[BorderType.TopBorder].Color = Color.Black;
            style.Borders[BorderType.BottomBorder].LineStyle = CellBorderType.Thin;
            style.Borders[BorderType.BottomBorder].Color = Color.Black;
            style.Borders[BorderType.LeftBorder].LineStyle = CellBorderType.Thin;
            style.Borders[BorderType.LeftBorder].Color = Color.Black;
            style.Borders[BorderType.RightBorder].LineStyle = CellBorderType.Thin;
            style.Borders[BorderType.RightBorder].Color = Color.Black;
        }

        /// <summary>
        /// the function compose the cell
        /// </summary>
        /// <param name="dt"></param>
        /// <param name="dtStyle"></param>
        /// <param name="drsAlign"></param>
        /// <param name="strWhere"></param>
        /// <param name="worksheet1"></param>
        /// <param name="offset_row"></param>
        /// <param name="offset_col"></param>
        /// <returns></returns>
        private static int FillWorksheet(DataTable dt, DataTable dtStyle, DataRow[] drsAlign, string strWhere, ref Worksheet worksheet1,
            int offset_row, int offset_col)
        {
            return FillWorksheet(dt, dtStyle, null, drsAlign, strWhere, ref worksheet1, offset_row, offset_col);
        }

        /// <summary>
        /// create cell by styles
        /// </summary>
        /// <param name="dt"></param>
        /// <param name="dtStyle"></param>
        /// <param name="dtRowStyle">add to enable row style</param>
        /// <param name="drsAlign"></param>
        /// <param name="strWhere"></param>
        /// <param name="worksheet1"></param>
        /// <param name="offset_row"></param>
        /// <param name="offset_col"></param>
        /// <returns></returns>
        private static int FillWorksheet(DataTable dt, DataTable dtStyle, DataTable dtRowStyle, DataRow[] drsAlign, string strWhere, ref Worksheet worksheet1,
            int offset_row, int offset_col)
        {
            DataTable dtdata = dt.Copy();

            //check if table contain 'RowType', if not, the all table will be data to show
            if (dt.Columns.Contains(C_RowType))
            {
                DataView dv = dtdata.DefaultView;
                dv.RowFilter = strWhere;
                dtdata = dv.ToTable();
            }

            //check if has column style 
            bool bhascolumnstyle = false;
            if (dt.Columns.Contains(C_CustomStyle))
            {
                bhascolumnstyle = true;
            }
            //check if has row style]
            bool bhasrowstyle = false;
            if (dt.Columns.Contains(Constants.RowStyle.RowUniqueID) && (dtRowStyle != null && dtRowStyle.Rows.Count > 0))
            {
                bhasrowstyle = true;
            }

            for (int r = 0; r < dtdata.Rows.Count; r++)
            {
                DataRow dr = dtdata.Rows[r];
                //check if has the uniquneid for rowstyle and dtrowstyle has data for the row
                string rowstyle = "";
                if (bhasrowstyle)
                {
                    try
                    {
                        //find the row style by uniqueid
                        string rowuniqureid = dr[Constants.RowStyle.RowUniqueID].ToString().Trim();
                        DataRow[] rowstylerow = dtRowStyle.Select(string.Format("{0}='{1}'", Constants.RowStyle.RowUniqueID, rowuniqureid));
                        if (rowstylerow.Length == 1)
                        {
                            rowstyle = rowstylerow[0][Constants.RowStyle.RowStyleContent].ToString().Trim();
                        }
                    }
                    catch
                    {
                        rowstyle = "";
                    }
                }

                //in trial balance case , the last two columns is customstyle and rowtype, will remove the column when overlook the all data to compose cell
                //now the case support to row style, may not have the two columns
                //not to ignore the last two column by index, change to igonre then by columnname
                for (int c = 0; c < dr.Table.Columns.Count; c++)
                {
                    //if current column is rowstyle.rowuniqureid, ignore it,just used to find mapping row style
                    string colname = dr.Table.Columns[c].ColumnName;
                    bool btempcolumn = CheckIsTempColumn(colname);
                    if (btempcolumn)
                    {
                        continue;
                    }

                    int rowIndex = offset_row + r;
                    int colIndex = offset_col + c;
                    string cellName = GetCell(rowIndex, colIndex);
                    Cell cell = worksheet1.Cells[rowIndex, colIndex];
                    //check if exist column style
                    string columnstyle = "";
                    if (bhascolumnstyle)
                    {
                        columnstyle = dr[C_CustomStyle].ToString();
                    }
                    //update to support row style
                    cell = SetStyle(cell, columnstyle, rowstyle);
                    cell = AutoFormateValue(cell, dr[c], dt.Columns[c].DataType);

                    if (drsAlign != null)
                    {
                        foreach (DataRow drA in drsAlign)
                        {
                            if (drA[ParseExcel.C_ColumnIndex].ToString() == c.ToString())
                            {
                                cell = SetStyle(cell, drA[ParseExcel.C_CustomStyle].ToString());
                            }
                        }
                    }
                    
                }
            }
            return dtdata.Rows.Count;
        }

        private static int FillWorksheet_New(DataTable dt, DataTable dtStyle, DataTable dtRowStyle, DataRow[] drsAlign, string strWhere, ref Worksheet worksheet1,
    int offset_row, int offset_col)
        {
            DataTable dtdata = dt.Copy();

            //check if table contain 'RowType', if not, the all table will be data to show
            if (dt.Columns.Contains(C_RowType))
            {
                DataView dv = dtdata.DefaultView;
                dv.RowFilter = strWhere;
                dtdata = dv.ToTable();
            }

            //check if has column style 
            bool bhascolumnstyle = false;
            if (dt.Columns.Contains(C_CustomStyle))
            {
                bhascolumnstyle = true;
            }
            //check if has row style]
            bool bhasrowstyle = false;
            if (dt.Columns.Contains(Constants.RowStyle.RowUniqueID) && (dtRowStyle != null && dtRowStyle.Rows.Count > 0))
            {
                bhasrowstyle = true;
            }

            for (int r = 0; r < dtdata.Rows.Count; r++)
            {
                DataRow dr = dtdata.Rows[r];
                //check if has the uniquneid for rowstyle and dtrowstyle has data for the row
                string rowstyle = "";
                if (bhasrowstyle)
                {
                    try
                    {
                        //find the row style by uniqueid
                        string rowuniqureid = dr[Constants.RowStyle.RowUniqueID].ToString().Trim();
                        DataRow[] rowstylerow = dtRowStyle.Select(string.Format("{0}='{1}'", Constants.RowStyle.RowUniqueID, rowuniqureid));
                        if (rowstylerow.Length == 1)
                        {
                            rowstyle = rowstylerow[0][Constants.RowStyle.RowStyleContent].ToString().Trim();
                        }
                    }
                    catch
                    {
                        rowstyle = "";
                    }
                }

                //in trial balance case , the last two columns is customstyle and rowtype, will remove the column when overlook the all data to compose cell
                //now the case support to row style, may not have the two columns
                //not to ignore the last two column by index, change to igonre then by columnname
                int merge = 0;
                for (int c = 0; c < dr.Table.Columns.Count; c++)
                {
                    //if current column is rowstyle.rowuniqureid, ignore it,just used to find mapping row style
                    string colname = dr.Table.Columns[c].ColumnName;
                    bool btempcolumn = CheckIsTempColumn(colname);
                    if (btempcolumn)
                    {
                        continue;
                    }

                    int rowIndex = offset_row + r;
                    int colIndex = offset_col + c + merge;
                    string cellName = GetCell(rowIndex, colIndex);
                    Cell cell = worksheet1.Cells[rowIndex, colIndex];
                    //check if exist column style
                    string columnstyle = "";
                    if (bhascolumnstyle)
                    {
                        columnstyle = dr[C_CustomStyle].ToString();
                    }
                    //update to support row style
                    cell = SetStyle(cell, columnstyle, rowstyle);
                    cell = AutoFormateValue(cell, dr[c], dt.Columns[c].DataType);

                    if (drsAlign != null)
                    {
                        foreach (DataRow drA in drsAlign)
                        {
                            if (drA[ParseExcel.C_ColumnIndex].ToString() == c.ToString())
                            {
                                cell = SetStyle(cell, drA[ParseExcel.C_CustomStyle].ToString());
                            }
                        }
                    }

                    string cellValue = dr[c].ToString();
                    Regex reg = new Regex(@"[(]\d+s[)]");
                    if (reg.IsMatch(cellValue))
                    {
                        string strTime = reg.Match(cellValue).Value;
                        int number = 1;
                        if (strTime == "(15s)")
                        {
                            number = 1;
                        }
                        else if (strTime == "(30s)")
                        {
                            number = 2;
                        }
                        else if (strTime == "(45s)")
                        {
                            number = 3;
                        }
                        else if (strTime == "(60s)")
                        {
                            number = 4;
                        }
                        if (number > 1)
                        {
                            worksheet1.Cells.Merge(rowIndex, colIndex, 1, number);
                            merge = merge + number - 1;
                        }
                    }
                }
            }
            return dtdata.Rows.Count;
        }


        public static string CreateExcel(string path, System.Data.DataSet ds)
        {
            try
            {
                Workbook workbook1 = new Workbook();
                int count = ds.Tables.Count;
                int sheetindex = 0;

                foreach (DataTable dt in ds.Tables)
                {
                    string sheetname = dt.TableName;
                    if (sheetindex >= workbook1.Worksheets.Count)
                    {
                        workbook1.Worksheets.Add(sheetname);
                    }
                    else
                    {
                        workbook1.Worksheets[sheetindex].Name = sheetname;
                    }

                    Worksheet worksheet1 = (Worksheet)workbook1.Worksheets[sheetname];
                    int rowindex = 0;
                    int colindex = 0;
                    foreach (DataColumn col in dt.Columns)
                    {
                        Cell cell = worksheet1.Cells[rowindex, colindex];
                        /*
                         * make column name the same alingment as column value setting,
                         * this only effect for a column that column name contains "CellStyle.A_..."
                         */
                        // get original column name 
                        string colName = FormatHelper.ReplaceFormatKey(col.ColumnName);
                        cell.PutValue(colName);
                        // check if it contains "CellStyle.A_..."
                        if (colName != col.ColumnName)
                        {
                            FormatHelper.AutoFormatValueByKey(ref cell, colName, col.ColumnName);
                        }

                        colindex++;
                    }

                    rowindex = 1;
                    foreach (DataRow row in dt.Rows)
                    {
                        colindex = 0;
                        foreach (DataColumn col in dt.Columns)
                        {
                            string value = "";
                            object o = row[col];
                            if (o != null)
                            {
                                value = o.ToString();
                            }
                            Cell cell = worksheet1.Cells[rowindex, colindex];
                            FormatHelper.AutoFormatValue(cell, o, col.ColumnName);

                            colindex++;
                        }
                        rowindex++;
                    }
                    // -- bug -- 7394 --
                    worksheet1.AutoFitColumns();
                }

                workbook1.Save(path);
                DeleteSheet(path, count);
            }
            catch (Exception e)
            {
                return "65002";
            }
            return null;
        }

        public static string CreateExcel_New(string path, System.Data.DataSet ds, double[] widths)
        {
            try
            {
                Workbook workbook1 = new Workbook();
                int count = ds.Tables.Count;
                int sheetindex = 0;

                foreach (DataTable dt in ds.Tables)
                {
                    string sheetname = dt.TableName;
                    if (sheetindex >= workbook1.Worksheets.Count)
                    {
                        workbook1.Worksheets.Add(sheetname);
                    }
                    else
                    {
                        workbook1.Worksheets[sheetindex].Name = sheetname;
                    }

                    Worksheet worksheet1 = (Worksheet)workbook1.Worksheets[sheetname];
                    int rowindex = 0;
                    int colindex = 0;
                    foreach (DataColumn col in dt.Columns)
                    {
                        Cell cell = worksheet1.Cells[rowindex, colindex];
                        /*
                         * make column name the same alingment as column value setting,
                         * this only effect for a column that column name contains "CellStyle.A_..."
                         */
                        // get original column name 
                        string colName = FormatHelper.ReplaceFormatKey(col.ColumnName);
                        cell.PutValue(colName);
                        // check if it contains "CellStyle.A_..."
                        if (colName != col.ColumnName)
                        {
                            FormatHelper.AutoFormatValueByKey(ref cell, colName, col.ColumnName);
                        }
                        colindex++;
                    }

                    rowindex = 1;
                    foreach (DataRow row in dt.Rows)
                    {
                        colindex = 0;
                        foreach (DataColumn col in dt.Columns)
                        {
                            string value = "";
                            object o = row[col];
                            if (o != null)
                            {
                                value = o.ToString();
                            }
                            Cell cell = worksheet1.Cells[rowindex, colindex];
                            FormatHelper.AutoFormatValue(cell, o, col.ColumnName);
                            Style cellStyle = cell.GetStyle();
                            
                            colindex++;
                        }
                        rowindex++;
                    }

                    for (int i = 0; i < widths.Length; i++)
                    {
                        worksheet1.Cells.SetColumnWidth(i, widths[i]);
                    }
                    // -- bug -- 7394 --
                    worksheet1.AutoFitColumns();
                }

                workbook1.Save(path);
                DeleteSheet(path, count);
            }
            catch (Exception e)
            {
                return "65002";
            }
            return null;
        }

        private static Cell AutoFormateValue(Cell cell, object val, Type t)
        {
            string formatedVal = string.Empty;

            if (t == typeof(string))
            {
                if (!string.IsNullOrEmpty(val.ToString()))
                {
                    cell.PutValue(val.ToString());
                }
            }
            else if (t == typeof(decimal))
            {
                decimal d = 0;
                decimal.TryParse(val.ToString(), out d);
                if (d != 0)
                {
                    Aspose.Cells.Style style = cell.GetStyle();
                    style.Number = 4;
                    cell.PutValue(d);
                    cell.SetStyle(style);
                }

            }
            else if (t == typeof(int))
            {
                int i = 0;
                int.TryParse(val.ToString(), out i);
                cell.PutValue(i);
            }
            //else if (t == typeof(DateTime))
            //{
            //    return CommonFunction.FormatDateTime(val);
            //}
            else
            {
                if (!string.IsNullOrEmpty(val.ToString()))
                {
                    cell.PutValue(val.ToString());
                }
            }
            return cell;
        }

        //extend to have row style
        /// <summary>
        /// set style to the cell
        /// </summary>
        /// <param name="cell"></param>
        /// <param name="strStyle">style for column</param>
        /// <returns></returns>
        private static Cell SetStyle(Cell cell, string strStyle)
        {
            return SetStyle(cell, strStyle, "");
        }

        //extend to have row style
        /// <summary>
        /// set style to the cell
        /// </summary>
        /// <param name="cell"></param>
        /// <param name="strStyle">style for column</param>
        /// <param name="rowStyle">style for row</param>
        /// <returns></returns>
        private static Cell SetStyle(Cell cell, string strStyle, string rowStyle)
        {
            if (string.IsNullOrEmpty(strStyle) && string.IsNullOrEmpty(rowStyle))
            {
                return cell;
            }

            Aspose.Cells.Style style = cell.GetStyle();
            //compose the column style to cell
            if (!string.IsNullOrEmpty(strStyle))
            {
                string[] sytles = strStyle.Split(';');
                foreach (string s in sytles)
                {
                    //check the font if bold
                    if (s.ToLower().Equals(CellStyle.FONTBOLD))
                    {
                        style.Font.IsBold = true;
                    }
                    else if (s.ToLower().Equals(CellStyle.TEXTWRAPPED.ToLower()))
                    {
                        style.IsTextWrapped = true;
                    }
                    //check the font size
                    else if (s.ToLower().IndexOf(CellStyle.FONTSIZE) == 0)
                    {
                        string val = s.Replace(CellStyle.FONTSIZE, "").Replace(":", "");
                        style.Font.Size = int.Parse(val);
                    }
                    //check the background is yellow or not
                    else if (s.ToLower().IndexOf(CellStyle.BG_YELLOW) == 0)
                    {
                        style.BackgroundColor = Color.Yellow;
                    }
                    //check the cell alignment is left
                    else if (s.ToLower().IndexOf(CellStyle.ALIGN_LEFT) == 0)
                    {
                        style.HorizontalAlignment = TextAlignmentType.Left;
                    }
                    //check the cell alignment is right
                    else if (s.ToLower().IndexOf(CellStyle.ALIGN_RIGHT) == 0)
                    {
                        style.HorizontalAlignment = TextAlignmentType.Right;
                    }
                    //check the cell alignment is center
                    else if (s.ToLower().IndexOf(CellStyle.ALIGN_CENTER) == 0)
                    {
                        style.HorizontalAlignment = TextAlignmentType.Center;
                    }
                }
            }

            //compose the row style to cell
            if (!string.IsNullOrEmpty(rowStyle))
            {
                //the row style format like 'FontColor:Red;FontSize:8;'
                //get the values by regularexpression
                Regex regrow = new Regex(@"(?<name>[\w]+)[\s]*[:][\s]*(?<value>[\w]+)[;]", RegexOptions.IgnoreCase);
                MatchCollection mcs = regrow.Matches(rowStyle);

                foreach (Match mc in mcs)
                {
                    string stylename = mc.Groups["name"].Value;
                    string stylevalue = mc.Groups["value"].Value;

                    //just support the font color now
                    if (Regex.IsMatch(stylename, "fontcolor", RegexOptions.IgnoreCase))
                    {
                        style.Font.Color = Color.FromName(stylevalue);
                    }
                    else if (Regex.IsMatch(stylename, "fontbold", RegexOptions.IgnoreCase))
                    {
                        bool isbold = false;
                        bool.TryParse(stylevalue, out isbold);
                        style.Font.IsBold = isbold;
                    }
                }
            }

            cell.SetStyle(style);
            return cell;
        }

        /// <summary>
        /// check if columnname which just for flag, style, rowindex . these columns need to ignore when compose cells in reports
        /// </summary>
        /// <returns></returns>
        public static bool CheckIsTempColumn(string colname)
        {
            bool btemplatecolumn = false;
            //if the column the row uniqure id for mapping row style
            if (Regex.IsMatch(colname, Constants.RowStyle.RowUniqueID, RegexOptions.IgnoreCase))
            {
                btemplatecolumn = true;
            }
            //in trial balance case , the last two columns is customstyle and rowtype, will remove the column when overlook the all data to compose cell
            //now the case support to row style, may not have the two columns
            else if (Regex.IsMatch(colname, C_CustomStyle, RegexOptions.IgnoreCase))
            {
                btemplatecolumn = true;
            }
            else if (Regex.IsMatch(colname, C_RowType, RegexOptions.IgnoreCase))
            {
                btemplatecolumn = true;
            }

            return btemplatecolumn;
        }

        private static string GetCell(int r, int c)
        {
            string rtn = alphabet[c];
            rtn = rtn + (r + 1).ToString();
            return rtn;
        }

        public static DataRow AppendBlankRow(ref System.Data.DataTable dt, string rowType)
        {
            DataRow dr = dt.NewRow();
            dr[C_RowType] = rowType;
            dt.Rows.Add(dr);
            return dr;
        }


        public static DataTable GetStyleTable()
        {
            DataTable dtStyle = new DataTable();
            dtStyle.TableName = ParseExcel.TableName.Style;
            dtStyle.Columns.Add(ParseExcel.C_ColumnIndex);
            dtStyle.Columns.Add(ParseExcel.C_StyleIndex);
            dtStyle.Columns.Add(ParseExcel.C_CustomStyle);
            dtStyle.Columns.Add(ParseExcel.C_RowType);
            return dtStyle;
        }

        //construct the columns for row style
        public static DataTable GetRowStyleTable()
        {
            DataTable dtStyle = new DataTable();
            dtStyle.TableName = ParseExcel.TableName.RowStyle;
            dtStyle.Columns.Add(Constants.RowStyle.RowUniqueID);
            //this column will save the formate like "XX:XXX;XX:XXX;"
            //e.g. "FontColor:Red;FontSize:8;"
            dtStyle.Columns.Add(Constants.RowStyle.RowStyleContent);
            return dtStyle;
        }

        public static DataTable GetInfoTable(DataTable dtData)
        {
            System.Data.DataTable dtInfo = new System.Data.DataTable();
            dtInfo.TableName = ParseExcel.TableName.Info;

            foreach (DataColumn dc in dtData.Columns)
            {
                dtInfo.Columns.Add(dc.ColumnName);
            }

            if (!dtInfo.Columns.Contains(ParseExcel.C_CustomStyle))
            {
                dtInfo.Columns.Add(ParseExcel.C_CustomStyle);
            }

            if (!dtInfo.Columns.Contains(ParseExcel.C_RowType))
            {
                dtInfo.Columns.Add(ParseExcel.C_RowType);
            }
            return dtInfo;
        }

        private static void DeleteSheet(string fName, int i)
        {
            SpreadsheetDocument file = SpreadsheetDocument.Open(fName, true);
            if (file.WorkbookPart.Workbook.Sheets.ChildElements.Count > i)
            {
                file.WorkbookPart.Workbook.Sheets.ChildElements[i].Remove();
                file.WorkbookPart.Workbook.Save();
            }
            file.Close();
        }

        public static DataSet GetDataSetFromExcelFile(string path)
        {
            DataSet ds = new DataSet();
            string strConn = "Provider=Microsoft.ACE.OLEDB.12.0;" + "Data Source=" + @path + ";" + "Extended Properties='Excel 12.0;HDR=YES;IMEX=1';";
            using (OleDbConnection conn = new OleDbConnection(strConn))
            {
                conn.Open();
                DataTable table = conn.GetOleDbSchemaTable(System.Data.OleDb.OleDbSchemaGuid.Tables, null);
                if (table != null && table.Rows.Count > 0)
                {
                    foreach (DataRow row in table.Rows)
                    {
                        string tableName = row["Table_Name"].ToString();
                        if (tableName.Contains("FilterDatabase") || tableName.Contains("Print_Titles")
|| tableName.Contains("_xlnm#Database") || tableName.Contains("Print_Area")
|| tableName.Contains("_xlnm.Database") || tableName.Contains("ExternalData")
|| tableName.Contains("DRUG_IMP_STOCK") || tableName.Contains("Sheet1$zy")
|| tableName.Contains("Sheet1$xy") || tableName.Contains("data_xy_zcy")
|| tableName.Contains("Results"))
                        {
                            continue;
                        }
                        OleDbDataAdapter myCommand = null;
                        string strExcel = string.Format("select * from [{0}]", tableName);
                        myCommand = new OleDbDataAdapter(strExcel, strConn);
                        DataTable dt = new DataTable();
                        dt.TableName = tableName;
                        myCommand.Fill(dt);
                        ds.Tables.Add(dt);
                    }
                }
                conn.Close();
            }
            return ds;
        }
    }
}
