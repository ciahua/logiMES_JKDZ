<%@ WebHandler Language="C#" Class="Handler_index" %>

using System;
using System.Web;
using System.Data;
using System.Configuration;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Collections.Generic;
using System.Threading;

public class Handler_index : IHttpHandler {
    static string connStr = ConfigurationManager.ConnectionStrings["ConnectionString"].ToString();
    static string connScadaStr = ConfigurationManager.ConnectionStrings["ConnectionSCADAString"].ToString();
    int startIndex, endIndex;
    public string json = string.Empty;
    public static Dictionary<string,DataTable> viewMap = new Dictionary<string,DataTable>();
    public static Dictionary<string,DataTable> headMap = new Dictionary<string,DataTable>();
    public static Dictionary<string,long> timeMap = new Dictionary<string,long>();
    //public static Dictionary<string,String> tmpMap1 = new Dictionary<string,String>();
    public static Dictionary<string,long> tmpMap = new Dictionary<string,long>();
    public static Dictionary<string,String> dugMap= new Dictionary<string,String>();
    public void ProcessRequest (HttpContext context) {
        context.Response.ContentType = "text/plain";
        string actId = context.Request["actid"];
        string menuName = context.Request["menuname"];
        string userId = context.Request["userid"];
        string ym = context.Request["month"];
        string page = context.Request["page"];
        string limit = context.Request["limit"];
        string viewstr = context.Request["viewstr"];
        startIndex = (Convert.ToInt32(page) - 1) * Convert.ToInt32(limit) + 1;
        endIndex = Convert.ToInt32(page) * Convert.ToInt32(limit);

        switch (actId)
        {
            case "debug":
                json = test();
                break;
            case "view":
                json = GetView(viewstr);
                break;
            case "checkPermission":
                json = CheckPermission(menuName, userId);
                break;
            case "getPermission":
                json = getPermission(userId);
                break;
            case "getSysLog":
                json = GetSysLog();
                break;
            case "getChartData":
                json = GetChartData();
                break;
            case "getChartData1":
                json = GetChartData1();
                break;
            case "getDevStatistics":
                json = GetDevStatistics(ym);
                break;
        }
        context.Response.Write(json);
    }
    public static int isrun = 0;
    public static string test()
    {
        String st="";
        //dugMap
        long times =new DateTimeOffset(DateTime.UtcNow).ToUnixTimeSeconds();
        long tmp = 0;

        foreach(string k in timeMap.Keys)
        {
            tmp = timeMap[k];
            st += k + ":" +(times - tmp) + " \n";
        }

        foreach(string k in dugMap.Keys)
        {
            st += k + ":" + dugMap[k] + " \n";
        }
        if (isrun == 1) st += "占用 \n";
        else st += "空闲 \n";
        return st;
    }

    public void loadData(String obj)
    {
        long times =new DateTimeOffset(DateTime.UtcNow).ToUnixTimeSeconds();
        long tmp = 0;
        if (timeMap.ContainsKey(obj + "")) tmp = timeMap[obj+""];
        if(times - tmp < 1 || isrun == 1) return;
        isrun = 1;
        string sql = "SELECT * FROM "+obj;
        string sql2 = "select name AS [key],name AS [text] from sys.syscolumns where id=object_id('"+obj+"') ORDER BY colorder";
        try
        {
            DataTable dt  = DbHelperSQL.ExcuteDataTable1(sql, connScadaStr);
            DataTable dt2 = DbHelperSQL.ExcuteDataTable1(sql2, connScadaStr);
            for (int i = 0; i < dt.Rows.Count; i++)
            {
                for (int j = 0; j < dt.Columns.Count; j++)
                {
                    object t = dt.Rows[i][j];
                    string temp = dt.Rows[i][j].ToString().Trim();
                    Type dtype = dt.Columns[j].DataType;
                    if( temp == "" && dtype == typeof(double))
                    {
                        dt.Rows[i][j] = DBNull.Value;
                    }
                    else
                    {
                        dt.Rows[i][j] = temp;
                    }
                }
            }
            for (int i = 0; i < dt2.Rows.Count; i++)
            {
                for (int j = 0; j < dt2.Columns.Count; j++)
                {
                    object t = dt2.Rows[i][j];
                    string temp = dt2.Rows[i][j].ToString().Trim();
                    Type dtype = dt2.Columns[j].DataType;
                    if( temp == "" && dtype == typeof(double))
                    {
                        dt2.Rows[i][j] = DBNull.Value;
                    }
                    else
                    {
                        dt2.Rows[i][j] = temp;
                    }
                }
            }
            //新建json对象，序列化为json字符串
            //var json = dt;
            //viewMap.Add(obj+"", dt);
            viewMap[obj + ""] = dt;
            headMap[obj + ""] = dt2;
            //timeMap.Add(obj + "", times);
            times =new DateTimeOffset(DateTime.UtcNow).ToUnixTimeSeconds();
            timeMap[obj + ""] = times;
            isrun = 0;
        }
        catch (Exception ex)
        {

            isrun = 0;
            return;
        }
    }


    private static void B(object obj)
    {
        //Console.WriteLine("Method {0}!",obj.ToString ()); 
        long times =new DateTimeOffset(DateTime.UtcNow).ToUnixTimeSeconds();
        long tmp = 0;
        if (timeMap.ContainsKey(obj + "")) tmp = timeMap[obj+""];

        if(times - tmp < 20  || isrun == 1)   return;

        isrun = 1;
        //select name from sys.syscolumns where id=object_id('sum_day');
        string sql = "SELECT * FROM "+obj;
        string sql2 = "select name AS [key],name AS [text] from sys.syscolumns where id=object_id('"+obj+"') ORDER BY colorder";
        try
        {
            DataTable dt  = DbHelperSQL.ExcuteDataTable1(sql, connScadaStr);
            DataTable dt2 = DbHelperSQL.ExcuteDataTable1(sql2, connScadaStr);
            for (int i = 0; i < dt.Rows.Count; i++)
            {
                for (int j = 0; j < dt.Columns.Count; j++)
                {
                    object t = dt.Rows[i][j];
                    string temp = dt.Rows[i][j].ToString().Trim();
                    Type dtype = dt.Columns[j].DataType;
                    if( temp == "" && dtype == typeof(double))
                    {
                        dt.Rows[i][j] = DBNull.Value;
                    }
                    else
                    {
                        dt.Rows[i][j] = temp;
                    }
                }
            }
            for (int i = 0; i < dt2.Rows.Count; i++)
            {
                for (int j = 0; j < dt2.Columns.Count; j++)
                {
                    object t = dt2.Rows[i][j];
                    string temp = dt2.Rows[i][j].ToString().Trim();
                    Type dtype = dt2.Columns[j].DataType;
                    if( temp == "" && dtype == typeof(double))
                    {
                        dt2.Rows[i][j] = DBNull.Value;
                    }
                    else
                    {
                        dt2.Rows[i][j] = temp;
                    }
                }
            }
            //新建json对象，序列化为json字符串
            //var json = dt;
            //viewMap.Add(obj+"", dt);
            viewMap[obj + ""] = dt;
            headMap[obj + ""] = dt2;
            //timeMap.Add(obj + "", times);
            times =new DateTimeOffset(DateTime.UtcNow).ToUnixTimeSeconds();
            timeMap[obj + ""] = times;
            isrun = 0;
        }
        catch (Exception ex)
        {

            isrun = 0;
            return;
        }
    }
    private string GetView(String view)
    {
        Thread childThread = new Thread(new ParameterizedThreadStart(B));
        childThread.Start(view);
        if (viewMap.ContainsKey(view)) {
            var json = new
            {
                data = viewMap[view],
                head = headMap[view]
            }; /**/
            //var json = viewMap[view];
            return JsonConvert.SerializeObject(json);
        }else
            return "";
    }
    /// <summary>
    /// 
    /// </summary>
    /// <param name="mname">菜单名称</param>
    /// <param name="uid">用户id，工号</param>
    /// <returns></returns>
    private string getPermission(string uid)
    {
        string result = string.Empty;
        string sql = string.Format("select [name] from Permission WHERE users LIKE '%{0}%'", uid);
        object obj = DbHelperSQL.ExecuteScalar(sql, connStr);
        string users = obj == null ? "" : obj.ToString();
        DataTable dt = DbHelperSQL.ExcuteDataTable(sql, connStr);

        for (int i = 0; i < dt.Rows.Count; i++)
        {
            for (int j = 0; j < dt.Columns.Count; j++)
            {
                object t = dt.Rows[i][j];
                string temp = dt.Rows[i][j].ToString().Trim();
                Type dtype = dt.Columns[j].DataType;
                if( temp == "" && dtype == typeof(double))
                {
                    dt.Rows[i][j] = DBNull.Value;
                }
                else
                {
                    dt.Rows[i][j] = temp;
                }
            }
        }

        //新建json对象，序列化为json字符串
        var json = new
        {
            code = 0,
            msg = "",
            data = dt
        };
        return JsonConvert.SerializeObject(json);
    }
    /// <summary>
    /// 
    /// </summary>
    /// <param name="mname">菜单名称</param>
    /// <param name="uid">用户id，工号</param>
    /// <returns></returns>
    private string CheckPermission(string mname, string uid)
    {
        string result = string.Empty;
        string sql = string.Format("select users from Permission where name = '{0}'", mname);
        object obj = DbHelperSQL.ExecuteScalar(sql, connStr);
        string users = obj == null ? "" : obj.ToString();
        if (users != "")
        {
            if (users.Contains(uid))
            {
                result = "success";
            }
            else
            {
                result = "failure";
            }
        }
        else
        {
            result = "failure";
        }
        //admin为超级管理员

        if(uid.ToUpper() == "ADMIN")
        {
            result = "success";
        }
        return result;
    }

    private string GetSysLog()
    {
        string sql = "SELECT * FROM [jinbeimes].[dbo].[SysLog] order by id desc";
        DataTable dtCount = DbHelperSQL.ExcuteDataTable(sql, connStr); //用于计总数                   

        sql = "SELECT * from (SELECT *, ROW_NUMBER() OVER(ORDER BY id desc) AS Num FROM SysLog)AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex;

        DataTable dt = DbHelperSQL.ExcuteDataTable(sql, connStr);

        for (int i = 0; i < dt.Rows.Count; i++)
        {
            for (int j = 0; j < dt.Columns.Count; j++)
            {
                object t = dt.Rows[i][j];
                string temp = dt.Rows[i][j].ToString().Trim();
                Type dtype = dt.Columns[j].DataType;
                if( temp == "" && dtype == typeof(double))
                {
                    dt.Rows[i][j] = DBNull.Value;
                }
                else
                {
                    dt.Rows[i][j] = temp;
                }
            }
        }

        //新建json对象，序列化为json字符串
        var json = new
        {
            code = 0,
            msg = "",
            count = dtCount.Rows.Count,
            data = dt
        };
        return JsonConvert.SerializeObject(json);
    }

    private string GetChartData()
    {
        DateTime dtm = DateTime.Now;//当天
        //本月第一天时间      
        DateTime dt_First = dtm.AddDays(1 - (dtm.Day));
        //获得某年某月的天数    
        int year = dtm.Date.Year;
        int month = dtm.Date.Month;
        int dayCount = DateTime.DaysInMonth(year, month);
        //本月最后一天时间    
        DateTime dt_Last = dt_First.AddDays(dayCount - 1);
        string dtmFirst = dt_First.ToString("yyyy-MM-dd");
        string dtmLast = dt_Last.ToString("yyyy-MM-dd");

        //string sql = $"SELECT * FROM dbo.DailyPower WHERE SQLtime>'{dtmFirst}' AND	SQLtime<'{dtmLast}' AND shebeibianhao='SUM_DB'";
        string sql = $"SELECT * FROM [JINBEI_SCADA].[dbo].[dayreport_dianbiao_shuju_shebeibianhao] WHERE SQLtime>'{dtmFirst}' AND	SQLtime<'{dtmLast}' AND shebeibianhao='SUM_DB'";
        //string sql=$"SELECT * FROM [JINBEI_SCADA].[dbo].[View_3] WHERE Expr1>='{dtmFirst}' AND	Expr1<='{dtmLast}'";
        DataTable dt = DbHelperSQL.ExcuteDataTable(sql, connScadaStr); //用于计总数  
        string[] days = new string[dayCount];
        for (int i = 0; i < dayCount; i++)
        {
            days[i] = dt_First.AddDays(i).ToString("yyyy-MM-dd");
            bool isIn = false;
            for (int j = 0; j < dt.Rows.Count; j++)
            {
                string _date = dt.Rows[j]["SQLtime"].ToString().Trim();
                if (_date == days[i])
                {
                    isIn = true;
                }
            }
            if (!isIn)
            {
                DataRow dr = dt.NewRow();
                dr["ID"] = i;
                dr["SQLtime"] = days[i];
                dr["shebeibianhao"] = "SUM_DB";
                dr["shebeimingcheng"] = "电表总累积";
                dr["real_yongdianliang"] = 0;
                dt.Rows.Add(dr);
            }
        }
        DataView dv = new DataView(dt);
        dv.Sort = "SQLtime ASC";
        dt = dv.ToTable();
        //dt.Rows[12]["real_yongdianliang"] = 10000;
        for (int i = 0; i < dt.Rows.Count; i++)
        {
            for (int j = 0; j < dt.Columns.Count; j++)
            {
                object t = dt.Rows[i][j];
                string temp = dt.Rows[i][j].ToString().Trim();
                Type dtype = dt.Columns[j].DataType;
                if( temp == "" && dtype == typeof(double))
                {
                    dt.Rows[i][j] = DBNull.Value;
                }
                else
                {
                    dt.Rows[i][j] = temp;
                }
            }
        }

        //新建json对象，序列化为json字符串
        var json = new
        {
            code = 0,
            msg = "",
            count = dt.Rows.Count,
            data = dt
        };
        return JsonConvert.SerializeObject(json);
    }

    private string GetChartData1()
    {
        DateTime dtm = DateTime.Now;//当天
        //本月第一天时间      
        DateTime dt_First = dtm.AddDays(1 - (dtm.Day));
        //获得某年某月的天数    
        int year = dtm.Date.Year;
        int month = dtm.Date.Month;
        int dayCount = DateTime.DaysInMonth(year, month);
        //本月最后一天时间    
        DateTime dt_Last = dt_First.AddDays(dayCount - 1);
        string dtmFirst = dt_First.ToString("yyyy-MM-dd");
        string dtmLast = dt_Last.ToString("yyyy-MM-dd");

        string sql = $"SELECT * FROM [JINBEI_SCADA].[dbo].[ph]";
        DataTable dt = DbHelperSQL.ExcuteDataTable(sql, connScadaStr); //用于计总数  

        for (int i = 0; i < dt.Rows.Count; i++)
        {
            for (int j = 0; j < dt.Columns.Count; j++)
            {
                object t = dt.Rows[i][j];
                string temp = dt.Rows[i][j].ToString().Trim();
                Type dtype = dt.Columns[j].DataType;
                if( temp == "" && dtype == typeof(double))
                {
                    dt.Rows[i][j] = DBNull.Value;
                }
                else
                {
                    dt.Rows[i][j] = temp;
                }
            }
        }

        //新建json对象，序列化为json字符串
        var json = new
        {
            code = 0,
            msg = "",
            count = dt.Rows.Count,
            data = dt
        };
        return JsonConvert.SerializeObject(json);
    }

    private string GetDevStatistics(string month)
    {
        string sql = "SELECT * FROM [jinbeimes].[dbo].[DevStatistics] where Month='"+month+"'";
        DataTable dt = DbHelperSQL.ExcuteDataTable(sql, connStr);

        for (int i = 0; i < dt.Rows.Count; i++)
        {
            for (int j = 0; j < dt.Columns.Count; j++)
            {
                object t = dt.Rows[i][j];
                string temp = dt.Rows[i][j].ToString().Trim();
                Type dtype = dt.Columns[j].DataType;
                if( temp == "" && dtype == typeof(double))
                {
                    dt.Rows[i][j] = DBNull.Value;
                }
                else
                {
                    dt.Rows[i][j] = temp;
                }
            }
        }

        //新建json对象，序列化为json字符串
        var json = new
        {
            code = 0,
            msg = "",
            count = dt.Rows.Count,
            data = dt
        };
        return JsonConvert.SerializeObject(json);
    }

    public bool IsReusable {
        get {
            return false;
        }
    }

}