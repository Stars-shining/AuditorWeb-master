using System;
using System.Collections.Generic;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using System.Reflection;

namespace CopyFiles
{
    public class BusinessLogicBase
    {
        public static BusinessLogicBase Default;
        static BusinessLogicBase()
        {
            Default = new BusinessLogicBase();
        }

        public int Insert(DataObjectBase BO)
        {
            string sql = GetInsertSQL(BO);
            using (SqlConnection conn = new SqlConnection(SqlHelper.ConnectionString))
            {
                conn.Open();
                SqlTransaction trans = conn.BeginTransaction(IsolationLevel.ReadCommitted);
                try
                {
                    object o = SqlHelper.ExecuteScalar(trans, CommandType.Text, sql);
                    int insertid = 0;
                    if (o != null)
                    {
                        int.TryParse(o.ToString(), out insertid);
                    }
                    trans.Commit();
                    return insertid;
                }
                catch (Exception ex)
                {
                    trans.Rollback();
                    throw ex;
                }
                finally
                {
                    conn.Close();
                }
            }
        }

        public int Insert(DataObjectBase BO, int ID)
        {
            //GetInsertSQLWithID
            string sql = GetInsertSQLWithID(BO);
            using (SqlConnection conn = new SqlConnection(SqlHelper.ConnectionString))
            {
                conn.Open();
                SqlTransaction trans = conn.BeginTransaction(IsolationLevel.ReadCommitted);
                try
                {
                    object o = SqlHelper.ExecuteScalar(trans, CommandType.Text, sql);
                    int insertid = 0;
                    if (o != null)
                    {
                        int.TryParse(o.ToString(), out insertid);
                    }
                    //int insertid = Convert.ToInt32((SqlHelper.ExecuteScalar(trans, CommandType.Text, sql)));
                    trans.Commit();
                    return insertid;
                }
                catch (Exception ex)
                {
                    trans.Rollback();
                    throw ex;
                }
                finally
                {
                    conn.Close();
                }
            }
        }

        public bool Insert(List<DataObjectBase> list)
        {
            string sql = string.Empty;
            sql = sql + "Begin Transaction;\r\n";
            foreach (DataObjectBase bo in list)
            {
                sql += GetInsertSQL(bo)+ " \r\n";
            }
            sql = sql + "Commit; \r\n";

            using (SqlConnection conn = new SqlConnection(SqlHelper.ConnectionString))
            {
                conn.Open();
                SqlTransaction trans = conn.BeginTransaction(IsolationLevel.ReadCommitted);
                try
                {
                    object o = SqlHelper.ExecuteScalar(trans, CommandType.Text, sql);
                    int insertid = 0;
                    if (o != null)
                    {
                        int.TryParse(o.ToString(), out insertid);
                    }
                    //int insertid = Convert.ToInt32((SqlHelper.ExecuteScalar(trans, CommandType.Text, sql)));
                    trans.Commit();
                    return true;
                }
                catch (Exception ex)
                {
                    trans.Rollback();
                    throw ex;
                }
                finally
                {
                    conn.Close();
                }
            }
        }

        public int Insert(DataObjectBase BO, SqlCommand cmd)
        {
            string sql = string.Empty;
            sql =GetInsertSQL(BO);

            cmd.CommandType = CommandType.Text;
            cmd.CommandText = sql;
            object o = cmd.ExecuteScalar();
            int insertid = 0;
            if (o != null)
            {
                int.TryParse(o.ToString(), out insertid);
            }            
            return insertid;
        }

        public bool Update(DataObjectBase BO, SqlCommand cmd, string Filter)
        {
            //string sql = GetUpdateSQL(BO);
            string sql = GetUpdateAllPropertySQL(BO);
            int Index = sql.ToUpper().IndexOf("WHERE");
            if (Index > 0)
            {
                sql = sql.Remove(Index);
            }
            sql = sql + " WHERE " + Filter;
            try
            {
                this.Execute(sql);
                //cmd.CommandText = sql;
                //cmd.ExecuteNonQuery();
                return true;
            }
            catch (Exception ex)
            {
                throw ex;
                //return false;
            }
        }

        public int Update(DataObjectBase BO,  string Filter)
        { 
            //string sql = GetUpdateSQL(BO);
            string sql = GetUpdateAllPropertySQL(BO);
            int Index = sql.ToUpper().IndexOf("WHERE");
            if (Index > 0)
            {
                sql = sql.Remove(Index);
            }
            sql = sql + " WHERE " + Filter;
            using (SqlConnection conn = new SqlConnection(SqlHelper.ConnectionString))
            {
                conn.Open();
                SqlTransaction trans = conn.BeginTransaction(IsolationLevel.ReadCommitted);
                try
                {
                    int count = SqlHelper.ExecuteNonQuery(SqlHelper.ConnectionString, CommandType.Text, sql);
                    trans.Commit();
                    return count;
                }
                catch (Exception)
                {
                    trans.Rollback();
                    throw;
                }
                finally
                {
                    conn.Close();
                }
            }
        }

        public void Update(List<DataObjectBase> bos) 
        {
            foreach (DataObjectBase bo in bos) 
            {
                Update(bo);
            }
        }

        public int Update(DataObjectBase BO)
        {
            string sql = GetUpdateAllPropertySQL(BO); //GetUpdateSQL(BO);
            using (SqlConnection conn = new SqlConnection(SqlHelper.ConnectionString))
            {
                conn.Open();
                SqlTransaction trans = conn.BeginTransaction(IsolationLevel.ReadCommitted);
                try
                {
                    int count = SqlHelper.ExecuteNonQuery(SqlHelper.ConnectionString, CommandType.Text, sql);
                    trans.Commit();
                    return count;
                }
                catch (Exception)
                {
                    trans.Rollback();
                    throw;
                }
                finally
                {
                    conn.Close();
                }
            }
        }

        public int UpdateSpecificProperty(DataObjectBase BO)
        {
            string sql = GetUpdateSQLWithSpecific(BO);
            using (SqlConnection conn = new SqlConnection(SqlHelper.ConnectionString))
            {
                conn.Open();
                SqlTransaction trans = conn.BeginTransaction(IsolationLevel.ReadCommitted);
                try
                {
                    int count = SqlHelper.ExecuteNonQuery(SqlHelper.ConnectionString, CommandType.Text, sql);
                    trans.Commit();
                    return count;
                }
                catch (Exception)
                {
                    trans.Rollback();
                    throw;
                }
                finally
                {
                    conn.Close();
                }
            }
        }

        public int UpdateAllProperty(DataObjectBase BO)
        {
            return Update(BO);
            //string sql = GetUpdateAllPropertySQL(BO);
            //using (SqlConnection conn = new SqlConnection(SqlHelper.ConnectionString))
            //{
            //    conn.Open();
            //    SqlTransaction trans = conn.BeginTransaction(IsolationLevel.ReadCommitted);
            //    try
            //    {
            //        int count = SqlHelper.ExecuteNonQuery(SqlHelper.ConnectionString, CommandType.Text, sql);
            //        trans.Commit();
            //        return count;
            //    }
            //    catch (Exception)
            //    {
            //        trans.Rollback();
            //        throw;
            //    }
            //    finally
            //    {
            //        conn.Close();
            //    }
            //}
        }

        public bool Update(DataObjectBase BO, SqlCommand cmd)
        {
            //string sql = GetUpdateSQL(BO);
            string sql = GetUpdateAllPropertySQL(BO);
            try
            {
                cmd.CommandType = CommandType.Text;
                cmd.CommandText = sql;
                cmd.ExecuteNonQuery();
                return true;
            }
            catch(Exception ex)
            {
                throw ex;
                //return false;
            }
        }

        public bool UpdateSpecificProperty(DataObjectBase BO, SqlCommand cmd)
        {
            string sql = GetUpdateSQLWithSpecific(BO);
            try
            {
                cmd.CommandType = CommandType.Text;
                cmd.CommandText = sql;
                cmd.ExecuteNonQuery();
                return true;
            }
            catch (Exception ex)
            {
                throw ex;
                //return false;
            }
        }

        public int Delete(DataObjectBase BO)
        {
            string sql = GetDeleteSQL(BO);
            using (SqlConnection conn = new SqlConnection(SqlHelper.ConnectionString))
            {
                conn.Open();
                SqlTransaction trans = conn.BeginTransaction(IsolationLevel.ReadCommitted);
                try
                {
                    int count = SqlHelper.ExecuteNonQuery(SqlHelper.ConnectionString, CommandType.Text, sql);
                    trans.Commit();
                    return count;
                }
                catch (Exception)
                {
                    trans.Rollback();
                    throw;
                }
                finally
                {
                    conn.Close();
                }
            }
        }

        public bool Delete(DataObjectBase BO, SqlCommand cmd)
        {
            string sql = GetDeleteSQL(BO);
            try
            {
                cmd.CommandType = CommandType.Text;
                cmd.CommandText = sql;
                cmd.ExecuteNonQuery();
                return true;
            }
            catch(Exception ex)
            {
                throw ex;
                //return false;
            }
        }

        public DataObjectBase Select(DataObjectBase BO, int id)
        {
            Type botype = BO.GetType();

            string tablename = BO.BO_Name;
            string pkname = BO.PK_Name;
            string parmname = "@" + pkname;

            string sql = "select * from {0} WITH(nolock) where {1} = {2}";
            sql = string.Format(sql,tablename,pkname,parmname);            
            SqlParameter parm = new SqlParameter(parmname, id);

            using (SqlDataReader rdr = SqlHelper.ExecuteReader(SqlHelper.ConnectionString, CommandType.Text, sql, parm))
            {
                while (rdr.Read())
                {
                    for (int i = 0; i < rdr.FieldCount; i++)
                    {
                        string colname = rdr.GetName(i);
                        //PropertyInfo proinfo = botype.GetProperty(colname);
                        PropertyInfo proinfo = botype.GetProperty(colname, BindingFlags.IgnoreCase | BindingFlags.Public | BindingFlags.Instance);

                        object o = rdr[i];
                        if (!rdr.IsDBNull(i))
                        {
                            if (proinfo != null)
                            {
                                proinfo.SetValue(BO, o, null);
                            }
                        }
                    }
                }
            }
            return BO;
        }

        public DataObjectBase Select(DataObjectBase businessObject, string sql)
        {
            Type boType = businessObject.GetType();
            //
            using (SqlDataReader rdr = SqlHelper.ExecuteReader(SqlHelper.ConnectionString, CommandType.Text, sql))
            {
                if (!rdr.HasRows)
                {
                    return null;
                }

                while (rdr.Read())
                {
                    for (int i = 0; i < rdr.FieldCount; i++)
                    {
                        string colname = rdr.GetName(i);
                        PropertyInfo proinfo = boType.GetProperty(colname, BindingFlags.IgnoreCase | BindingFlags.Public | BindingFlags.Instance);

                        object o = rdr[i];
                        if (!rdr.IsDBNull(i))
                        {
                            if (proinfo != null)
                            {
                                proinfo.SetValue(businessObject, o, null);
                            }
                        }
                    }
                }
            }
            return businessObject;
        }

        public DataObjectBase Select(DataObjectBase businessObject, string sql, SqlParameter[] pars)
        {
            Type boType = businessObject.GetType();
            //
            using (SqlDataReader rdr = SqlHelper.ExecuteReader(SqlHelper.ConnectionString, CommandType.Text, sql, pars))
            {
                if (!rdr.HasRows)
                {
                    return null;
                }

                while (rdr.Read())
                {
                    for (int i = 0; i < rdr.FieldCount; i++)
                    {
                        string colname = rdr.GetName(i);
                        PropertyInfo proinfo = boType.GetProperty(colname, BindingFlags.IgnoreCase | BindingFlags.Public | BindingFlags.Instance);

                        object o = rdr[i];
                        if (!rdr.IsDBNull(i))
                        {
                            if (proinfo != null)
                            {
                                proinfo.SetValue(businessObject, o, null);
                            }
                        }
                    }
                }
            }
            return businessObject;
        }

        public DataObjectBase Select(DataObjectBase businessObject, int id,SqlCommand cmd)
        {
            Type boType = businessObject.GetType();            
            string tablename = businessObject.BO_Name;
            string pkname = businessObject.PK_Name;

            string sql = "select * from [{0}] with(nolock) where {1} = {2}";
            sql = string.Format(sql, tablename, pkname, id);

            cmd.CommandType = CommandType.Text;
            cmd.CommandText = sql;
            using (SqlDataReader rdr = cmd.ExecuteReader())
            {
                if (!rdr.HasRows)
                {
                    return null;
                }

                while (rdr.Read())
                {
                    for (int i = 0; i < rdr.FieldCount; i++)
                    {
                        string colname = rdr.GetName(i);
                        PropertyInfo proinfo = boType.GetProperty(colname, BindingFlags.IgnoreCase | BindingFlags.Public | BindingFlags.Instance);

                        object o = rdr[i];
                        if (!rdr.IsDBNull(i))
                        {
                            if (proinfo != null)
                            {
                                proinfo.SetValue(businessObject, o, null);
                            }
                        }
                    }
                }
            }
            return businessObject;
        }

        public DataTable Select(string sql)
        {
            try
            {
                return SqlHelper.ExecuteDataset(SqlHelper.ConnectionString, sql).Tables[0];
            }
            catch (Exception)
            {
                throw;
            }
        }

        public DataTable Select(string sql,params SqlParameter[] pars)
        {
            try
            {
                return SqlHelper.ExecuteDataset(SqlHelper.ConnectionString,CommandType.Text,sql,pars).Tables[0];
            }
            catch (Exception)
            {
                throw;
            }
        }

        public DataTable Select(string sql, SqlCommand cmd, params SqlParameter[] parameters)
        {
            cmd.CommandText = sql;
            cmd.CommandType = CommandType.Text;
            cmd.CommandTimeout = cmd.CommandTimeout;
            cmd.Parameters.Clear();
            if (parameters != null)
                foreach (SqlParameter parameter in parameters)
                    cmd.Parameters.Add(parameter);

            SqlDataAdapter adapter = new SqlDataAdapter(cmd);
            DataTable result = new DataTable();
            try
            {
                adapter.Fill(result);
            }
            catch (Exception ex)
            {
                throw ex;
            }
            cmd.Parameters.Clear();
            return result;
        }

        public DataTable ExceuteStoredProcedure(string spname,SqlParameter[] pars)
        {
            try
            {
                return SqlHelper.ExecuteDataset(SqlHelper.ConnectionString,spname, pars).Tables[0];
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }


        public void Execute(string sql)
        {
            using (SqlConnection conn = new SqlConnection(SqlHelper.ConnectionString))
            {
                conn.Open();
                SqlTransaction trans = conn.BeginTransaction(IsolationLevel.ReadCommitted);
                try
                {
                    int count = SqlHelper.ExecuteNonQuery(SqlHelper.ConnectionString, CommandType.Text, sql);
                    trans.Commit();
                }
                catch (Exception)
                {
                    trans.Rollback();
                    throw;
                }
                finally
                {
                    conn.Close();
                }
            }
        }

        public void Execute(string sql,SqlParameter[] pars)
        {
            using (SqlConnection conn = new SqlConnection(SqlHelper.ConnectionString))
            {
                conn.Open();
                SqlTransaction trans = conn.BeginTransaction(IsolationLevel.ReadCommitted);
                try
                {
                    int count = SqlHelper.ExecuteNonQuery(SqlHelper.ConnectionString, CommandType.Text, sql,pars);
                    trans.Commit();                    
                }
                catch (Exception)
                {
                    trans.Rollback();
                    throw;
                }
                finally
                {
                    conn.Close();
                }
            }
        }

        public bool Execute(string sql, SqlParameter[] pars, SqlCommand cmd)
        {
            try
            {
                cmd.CommandType = CommandType.Text;
                cmd.CommandText = sql;
                cmd.Parameters.Clear();
                foreach (SqlParameter par in pars)
                {
                    cmd.Parameters.Add(par);
                }
                cmd.ExecuteNonQuery();
                return true;
            }
            catch (Exception ex)
            {
                throw ex;
                //return false;
            }
        }

        public bool Execute(string sql, SqlCommand cmd)
        {
            try
            {
                cmd.CommandType = CommandType.Text;
                cmd.CommandText = sql;
                cmd.Parameters.Clear();
                cmd.ExecuteNonQuery();
                return true;
            }
            catch(Exception ex)
            {
                throw ex;
                //return false;
            }
        }

        public void ExecuteSPNonQuery(string spname, SqlParameter[] pars,SqlCommand cmd)
        {
            try
            {
                //9611M-9612S-9613P-DELETING INITIAL TERM DEPOSITS TRANSACTION QUESTIONNAIRE OR ENTRIES.docx
                //avoid error when cmd is null
                if (cmd == null)
                {
                    ExecuteSPNonQuery(spname, pars);
                    return;
                }
                cmd.CommandText = spname;
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.Clear();
                foreach (SqlParameter par in pars)
                {
                    cmd.Parameters.Add(par);
                }
                cmd.ExecuteNonQuery();
                return;
            }
            catch (Exception ex)
            {
                throw ex;
                //return false;
            }
        }

        public void ExecuteSPNonQuery(string spname,SqlParameter[] pars)
        {
            SqlHelper.ExecuteNonQuery(SqlHelper.ConnectionString, spname, pars);
            return;
        }

        public void ExecuteSPNonQueryAsynchronous(string spname, SqlParameter[] pars)
        {
            SqlConnection conn=new SqlConnection(SqlHelper.ConnectionString);
            SqlHelper.ExecuteNonQueryAsynchronous(conn, spname, pars);
        }

        public DataTable ExecuteSP(string spname, SqlParameter[] pars)
        {
            return SqlHelper.Fill(spname, pars);
        }

        public DataTable ExecuteSP(string spname, SqlParameter[] pars, SqlCommand cmd)
        {
            return SqlHelper.FillCommand(spname, cmd, pars);
        }


        public SqlCommand BeginTransaction()
        {
            SqlConnection con = new SqlConnection(SqlHelper.ConnectionString);
            con.Open();
            SqlTransaction sqltrans = con.BeginTransaction(IsolationLevel.ReadCommitted);
            SqlCommand cmd = new SqlCommand();
            cmd.CommandTimeout = 120;
            cmd.Connection = con;
            cmd.Transaction = sqltrans;
            return cmd;
        }

        public void RollBack(SqlCommand cmd)
        {
            SqlTransaction sqltrans = cmd.Transaction;
            SqlConnection con = cmd.Connection;
            sqltrans.Rollback();
            if (con.State == ConnectionState.Open)
                con.Close();
        }

        public void Commit(SqlCommand cmd)
        {
            SqlTransaction sqltrans = cmd.Transaction;
            SqlConnection con = cmd.Connection;
            sqltrans.Commit();
            if (con.State == ConnectionState.Open)
                con.Close();
        }

        public object SetNullValue(Type valtype)
        {
            if (valtype == Type.GetType("System.String"))
            {
                return "";
            }
            else if (valtype == Type.GetType("System.DateTime"))
            {
                return new DateTime(1900, 1, 1);
            }
            else if (valtype == Type.GetType("System.Decimal") || valtype == Type.GetType("System.Int32"))
            {
                return 0;
            }
            else

                return null;
        }

        public bool CheckValidValue(Type coltype, object o)
        {
            if (coltype == Type.GetType("System.String"))
            {
                if (o == null)
                    return false;
                else
                {
                    return true;
                }
            }
            else if (coltype == Type.GetType("System.DateTime"))
            {
                if (Convert.ToDateTime(o) == Constants.Date_Null || Convert.ToDateTime(o) == Constants.Date_Min || Convert.ToDateTime(o) == DateTime.MinValue)
                    return false;
                else
                {
                    return true;
                }
            }
            else if (coltype == Type.GetType("System.Decimal"))
            {
                if (Convert.ToDecimal(o) == decimal.MinValue)
                    return false;
                else
                {
                    return true;
                }
            }
            else if (coltype == Type.GetType("System.Double"))
            {
                if (Convert.ToDouble(o) == double.MinValue)
                    return false;
                else
                {
                    return true;
                }
            }
            else if (coltype == Type.GetType("System.Int32"))
            {
                if (Convert.ToInt32(o) == int.MinValue)
                    return false;
                else
                {
                    return true;
                }
            }
            else if (coltype == Type.GetType("System.Int64"))
            {
                if (Convert.ToInt64(o) == int.MinValue)
                    return false;
                else
                {
                    return true;
                }
            }
            else if (coltype == Type.GetType("System.Boolean"))
            {
                return true;
            }
            else if (coltype == Type.GetType("System.TimeSpan"))
            {
                return true;
            }
            else
                return false;
        }

        public string GetInsertSQL(DataObjectBase BO)
        {
            string BOName = BO.BO_Name;
            string PKName = BO.PK_Name;
            string sql = @"insert into {0} ({1}) values ({2})
                          SELECT   @@IDENTITY   AS   'NewId'";
            string fields = "";
            string values = "";
            Type botype = BO.GetType();
            PropertyInfo[] infos = botype.GetProperties();
            foreach (PropertyInfo info in infos)
            {
                string ColName = info.Name;
                if (ColName.ToLower().Trim() == PKName.ToLower().Trim())
                    continue;
                Type infotype =  GetGenericType(info.PropertyType);
                object o = info.GetValue(BO, null);
                if (o == null)
                    continue;
                if (!CheckValidValue(infotype, o))
                    continue;
                fields += "[" + ColName + "],";
                if (infotype == Type.GetType("System.DateTime"))
                {
                    DateTime time = Convert.ToDateTime(o.ToString());
                    string t = string.Format("{0:MM-dd-yyyy HH:mm:ss}", time);
                    values += "'" + t + "',";
                }
                else if (infotype == Type.GetType("System.TimeSpan")) 
                {
                    TimeSpan time = TimeSpan.Parse(o.ToString());
                    string t = string.Format("{0}:{1}:{2}", time.Hours, time.Minutes, time.Seconds);
                    values += "'" + t + "',";
                }
                else
                    values += "'" + o.ToString().Replace("'", "''") + "',";
            }

            if (fields.Length > 0)
            {
                fields = fields.Substring(0, fields.Length - 1);
                values = values.Substring(0, values.Length - 1);
            }
            sql = string.Format(sql, BOName, fields, values);
            return sql;
        }

        public string GetInsertSQLWithID(DataObjectBase BO)
        {
            string BOName = BO.BO_Name;
            string PKName = BO.PK_Name;
            string sql = @"insert into {0} ({1}) values ({2})";
                          //SELECT   @@IDENTITY   AS   'NewId'";
            string fields = "";
            string values = "";
            Type botype = BO.GetType();
            PropertyInfo[] infos = botype.GetProperties();
            foreach (PropertyInfo info in infos)
            {
                string ColName = info.Name;
                //if (ColName.ToLower().Trim() == PKName.ToLower().Trim())
                //    continue;
                Type infotype = GetGenericType(info.PropertyType);
                object o = info.GetValue(BO, null);

                if (!CheckValidValue(infotype, o))
                    continue;
                fields += "[" + ColName + "],";
                if (infotype == Type.GetType("System.DateTime"))
                {
                    DateTime time = Convert.ToDateTime(o.ToString());
                    string t = string.Format("{0:MM-dd-yyyy HH:mm:ss}", time);
                    values += "'" + t + "',";
                }
                else
                    values += "'" + o.ToString().Replace("'", "''") + "',";
            }

            if (fields.Length > 0)
            {
                fields = fields.Substring(0, fields.Length - 1);
                values = values.Substring(0, values.Length - 1);
            }
            sql = string.Format(sql, BOName, fields, values);
            return sql;
        }

        /// <summary>
        /// if the update function just want to update some of the property,  only set these property and set the id.
        /// </summary>
        /// <param name="BO"></param>
        /// <returns></returns>
        public string GetUpdateSQLWithSpecific(DataObjectBase BO)
        {
            string BOName = BO.BO_Name;
            string PKName = BO.PK_Name;
            string sql = @"Update {0} set {1} where {2}";

            string fields = "";
            string filter = PKName + "=";
            Type botype = BO.GetType();
            PropertyInfo[] infos = botype.GetProperties();
            foreach (PropertyInfo info in infos)
            {
                string ColName = info.Name;
                if (ColName.ToLower().Trim() == PKName.ToLower().Trim())
                {
                    object pkid = info.GetValue(BO, null);
                    filter += pkid.ToString();
                }
                else
                {
                    Type infotype = GetGenericType(info.PropertyType);
                    object o = info.GetValue(BO, null);

                    //if (infotype == Type.GetType("System.DateTime"))
                    //{
                    //    if (Convert.ToDateTime(o) == DataObjectBase.Date_Min || Convert.ToDateTime(o) == DateTime.MinValue)
                    //    {
                    //        fields += "[" + ColName + "]=null,";
                    //    }
                    //}

                    if (CheckValidValue(infotype, o))
                    {
                        if (infotype == Type.GetType("System.DateTime"))
                        {
                            DateTime time = Convert.ToDateTime(o.ToString());
                            string t = string.Format("{0:MM-dd-yyyy HH:mm:ss}", time);
                            fields += "[" + ColName + "]='" + t + "',";
                        }
                        else
                            fields += "[" + ColName + "]='" + o.ToString().Replace("'", "''") + "',";
                    }
                }
            }

            if (fields.Length > 0)
            {
                fields = fields.Substring(0, fields.Length - 1);
            }

            sql = string.Format(sql, BOName, fields, filter);
            return sql;
        }

        public string GetUpdateAllPropertySQL(DataObjectBase BO)
        {
            string BOName = BO.BO_Name;
            string PKName = BO.PK_Name;
            string sql = @"Update {0} set {1} where {2}";

            string fields = "";
            string filter = PKName + "=";
            Type botype = BO.GetType();
            PropertyInfo[] infos = botype.GetProperties();
            foreach (PropertyInfo info in infos)
            {
                string ColName = info.Name;
                if (ColName.ToLower().Trim() == PKName.ToLower().Trim())
                {
                    object pkid = info.GetValue(BO, null);
                    filter += pkid.ToString();
                }
                else
                {
                    Type infotype = GetGenericType(info.PropertyType);
                    object o = info.GetValue(BO, null);
                    if (CheckValidValue(infotype, o))
                    {
                        if (infotype == Type.GetType("System.DateTime"))
                        {
                            DateTime time = Convert.ToDateTime(o.ToString());
                            string t = string.Format("{0:MM-dd-yyyy HH:mm:ss}", time);
                            fields += "[" + ColName + "]='" + t + "',";
                        }
                        else                        
                            fields += "[" + ColName + "]='" + o.ToString().Replace("'","''") + "',";
                    }
                    else
                    {
                        fields += "[" + ColName + "]=NULL,";
                    }
                }
            }

            if (fields.Length > 0)
            {
                fields = fields.Substring(0, fields.Length - 1);
            }

            sql = string.Format(sql, BOName, fields, filter);
            return sql;
        }

        public string GetDeleteSQL(DataObjectBase BO)
        {
            string BOName = BO.BO_Name;
            string PKName = BO.PK_Name;
            string sql = "Delete from {0} where {1}";

            string filter = PKName + "=";
            Type botype = BO.GetType();
            PropertyInfo[] infos = botype.GetProperties();
            foreach (PropertyInfo info in infos)
            {
                string ColName = info.Name;
                if (ColName.ToLower().Trim() == PKName.ToLower().Trim())
                {
                    object pkid = info.GetValue(BO, null);
                    filter += pkid.ToString();
                    break;
                }
            }

            sql = string.Format(sql, BOName, filter);
            return sql;
        }

        public static double? GetValue(string ob)
        {
            if (ob == "")
            {
                return null;
            }
            else
            {
                return Convert.ToDouble(ob);
            }
        }

        public static Type GetGenericType(Type type)
        {
            if (type.IsGenericType && type.GetGenericTypeDefinition() == typeof(Nullable<>))
            {
                Type generictype = Nullable.GetUnderlyingType(type);
                type = generictype;
            }
            return type;
        }

        public static object CopyValue(Type ToObjType, object FromObject)
        {
            object obj = Activator.CreateInstance(ToObjType);

            PropertyInfo[] infos = ToObjType.GetProperties(BindingFlags.Public | BindingFlags.Instance | BindingFlags.DeclaredOnly);

            Type FromType = FromObject.GetType();

            foreach (PropertyInfo info in infos)
            {
                if (info.CanWrite)
                {
                    string infoname = info.Name;
                    PropertyInfo frominfo = FromType.GetProperty(infoname, BindingFlags.Public | BindingFlags.Instance | BindingFlags.IgnoreCase);
                    if (frominfo != null) //&& info.PropertyType == frominfo.PropertyType
                    {
                        try
                        {
                            object value = frominfo.GetValue(FromObject, null);
                            info.SetValue(obj, value, null);
                        }
                        catch
                        {

                        }
                    }
                }
            }

            return obj;
        }

        public static object CopyValueAll(Type ToObjType, object FromObject)
        {
            object obj = Activator.CreateInstance(ToObjType);

            PropertyInfo[] infos = ToObjType.GetProperties(BindingFlags.Public | BindingFlags.Instance);

            Type FromType = FromObject.GetType();

            foreach (PropertyInfo info in infos)
            {
                if (info.CanWrite)
                {
                    string infoname = info.Name;
                    PropertyInfo frominfo = FromType.GetProperty(infoname, BindingFlags.Public | BindingFlags.Instance | BindingFlags.IgnoreCase);
                    if (frominfo != null) //&& info.PropertyType == frominfo.PropertyType
                    {
                        try
                        {
                            object value = frominfo.GetValue(FromObject, null);
                            info.SetValue(obj, value, null);
                        }
                        catch
                        {

                        }
                    }
                }
            }

            return obj;
        }

        public static object CopyFieldsAll(Type ToObjType, object FromObject)
        {
            object obj = Activator.CreateInstance(ToObjType);

            FieldInfo[] infos = ToObjType.GetFields(BindingFlags.Public | BindingFlags.Instance);

            Type FromType = FromObject.GetType();

            foreach (FieldInfo info in infos)
            {
                if (info.IsPublic)
                {
                    string infoname = info.Name;
                    FieldInfo frominfo = FromType.GetField(infoname, BindingFlags.Public | BindingFlags.Instance | BindingFlags.IgnoreCase);
                    if (frominfo != null) 
                    {
                        try
                        {
                            object value = frominfo.GetValue(FromObject);
                            info.SetValue(obj, value);
                        }
                        catch
                        {

                        }
                    }
                }
            }

            return obj;
        }

        #region 
        /// <summary>
        /// transaction commit or rollback the entire insert. use external transaction of sqlbulkcopy
        /// </summary>
        /// <param name="dt"></param>
        /// <param name="tablename"></param>
        /// <param name="colmapping"></param>
        /// <returns></returns>
        public static bool InsertBulk(DataTable dt, string tablename, params SqlBulkCopyColumnMapping[] colmapping)
        {
            bool bsucess = true;
            try
            {
                using (SqlConnection conn = new SqlConnection(SqlHelper.ConnectionString))
                {
                    conn.Open();

                    SqlTransaction trans = conn.BeginTransaction();
                    using (SqlBulkCopy sbulk = new SqlBulkCopy(conn,SqlBulkCopyOptions.KeepIdentity,trans))
                    {
                        sbulk.BatchSize = 100;
                        sbulk.DestinationTableName = tablename;
                        if (colmapping != null && colmapping.Length > 0)
                        {
                            foreach (SqlBulkCopyColumnMapping map in colmapping)
                            {
                                sbulk.ColumnMappings.Add(map);
                            }
                        }
                        else
                        {
                            foreach (DataColumn col in dt.Columns)
                            {
                                string colname = col.ColumnName;
                                sbulk.ColumnMappings.Add(new SqlBulkCopyColumnMapping(colname, colname));
                            }
                        }

                        try
                        {
                            sbulk.WriteToServer(dt);
                            trans.Commit();
                        }
                        catch (Exception ex)
                        {
                            trans.Rollback();
                            throw ex;                            
                        }

                    }
                }
            }
            catch
            {
                bsucess = false;
            }
            return bsucess;
        }

        /// <summary>
        /// transaction commit or rollback the entire insert. use external transaction of sqlbulkcopy
        /// </summary>
        /// <param name="dt"></param>
        /// <param name="tablename"></param>
        /// <param name="colmapping"></param>
        /// <returns></returns>
        public static bool InsertBulk(DataTable dt, string tablename, SqlCommand cmd, params SqlBulkCopyColumnMapping[] colmapping)
        {
            bool bsucess = true;
            using (cmd)
            {
                try
                {
                    SqlConnection conn = cmd.Connection;
                    SqlTransaction trans = cmd.Transaction; ;
                    using (SqlBulkCopy sbulk = new SqlBulkCopy(conn, SqlBulkCopyOptions.KeepIdentity, trans))
                    {
                        sbulk.BatchSize = 100;
                        sbulk.DestinationTableName = tablename;
                        if (colmapping != null && colmapping.Length > 0)
                        {
                            foreach (SqlBulkCopyColumnMapping map in colmapping)
                            {
                                sbulk.ColumnMappings.Add(map);
                            }
                        }
                        else
                        {
                            foreach (DataColumn col in dt.Columns)
                            {
                                string colname = col.ColumnName;
                                sbulk.ColumnMappings.Add(new SqlBulkCopyColumnMapping(colname, colname));
                            }
                        }
                        try
                        {
                            sbulk.WriteToServer(dt);
                        }
                        catch (Exception ex)
                        {
                            bsucess = false;
                            throw ex;
                        }
                    }
                }
                catch
                {
                    bsucess = false;
                }
            }
            return bsucess;
        }
        #endregion
    }
}
