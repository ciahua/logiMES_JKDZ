<%@ WebHandler Language="C#" Class="Handler_planreport" %>

using Newtonsoft.Json;
using System;
using System.Configuration;
using System.Data;
using System.Text.RegularExpressions;
using System.Web;
using Newtonsoft.Json.Linq;

public class Handler_planreport : IHttpHandler
{

    static string connStr = ConfigurationManager.ConnectionStrings["ConnectionString"].ToString();
    int startIndex, endIndex;

    private class DevInfo
    {
        public int id { get; set; }
        public string devno { get; set; }
        public string devname { get; set; }
        public string devtype { get; set; }
        public string devdept { get; set; }
        public string quantity { get; set; }
        public string vender { get; set; }
        public string buydate { get; set; }
        public string lifetime { get; set; }
        public string devclass { get; set; }
        public string special { get; set; }
        public string capacity { get; set; }
        public string devstate { get; set; }
        public string importance { get; set; }
        public string value { get; set; }
        public string changedate { get; set; }
        public string desc { get; set; }
    }
    private class CheckInfo
    {
        public int Id { get; set; }
        public string DeviceId { get; set; }
        public string DeviceName { get; set; }
        public string Unit { get; set; }
        public string Category { get; set; }
        public string Location { get; set; }
        public string Cycle { get; set; }
        public string Result { get; set; }
    }

    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "text/plain";
        string searchKey = string.Empty;
        string resJson = string.Empty;
        string actId = context.Request["actid"];
        string devData = context.Request["data"];
        string devFailData = context.Request["faildata"];
        string repairmanId = context.Request["workid"];
        string repairmanName = context.Request["workname"];
        string issueId = context.Request["issueid"];

        if (context.Request["searchkey"] != null)
        {
            searchKey = context.Request["searchkey"].Trim(); //获取搜索关键字
        }
        string page = context.Request["page"];
        string limit = context.Request["limit"];
        startIndex = (Convert.ToInt32(page) - 1) * Convert.ToInt32(limit) + 1;
        endIndex = Convert.ToInt32(page) * Convert.ToInt32(limit);

        switch (actId)
        {
            case "getDownByMonth":
                resJson = getDownByMonth(devData);
                break;
            case "GetSumByState1":
                resJson = GetSumByState("已验收");
                break;
            case "GetSumByState2":
                resJson = GetSumByState("待验收");
                break;
            case "GetSumByState3":
                resJson = GetSumByState("维修中");
                break;
            case "GetSumByState4":
                resJson = GetSumByState("待维修");
                break;
            case "GetSumByState":
                resJson = GetSumByState();
                break;
            case "getTable":
                resJson = GetTable2Json();
                break;
            case "getFailTable":
                resJson = GetFailTable2Json();
                break;
            case "getCheckTable":
                resJson = GetCheckTable2Json();
                break;
            case "getCheckResult":
                resJson = GetCheckResult2Json();
                break;
            case "getCheckSummary":
                resJson = GetCheckSummary2Json();
                break;
            case "insTable":
                //CheckInfo checkInfo = JsonConvert.DeserializeObject<CheckInfo>(devData);
                JObject checkInfo = (JObject)JsonConvert.DeserializeObject(devData);
                string checkDate = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                string currentDate = checkDate.Substring(0,10);
                int currentHour = DateTime.Now.Hour;//当前时间（小时）
                string checker = repairmanName;
                string sqlAddNew = "";
                if (currentHour >= 8 && currentHour < 20)
                {
                    //白班
                    sqlAddNew = $"if not exists (select 1 from DeviceCheck where left(CheckDate,10) = '{currentDate}' and DevNo='{checkInfo["DevNo"]}' and CheckItem='{checkInfo["CheckItem"]}') " +
                        $"insert into DeviceCheck values('{checkDate}', '{checker}','{checkInfo["DevNo"]}','{checkInfo["DevName"]}','{checkInfo["DevDept"]}','{checkInfo["CheckItem"]}','{checkInfo["CheckCriteria"]}','{checkInfo["Means"]}','{checkInfo["DayShift"]["value"]}','{checkInfo["DayRecord"]}','{""}','{""}' ) " +
                        "else " +
                        $"update DeviceCheck set CheckDate='{checkDate}', Checker='{checker}', DayShift = '{checkInfo["DayShift"]["value"]}', DayRecord='{checkInfo["DayRecord"]}' where left(CheckDate,10) = '{currentDate}' and DevNo='{checkInfo["DevNo"]}' and CheckItem='{checkInfo["CheckItem"]}' ";

                }
                else if ((currentHour >= 20 && currentHour < 24) || (currentHour >= 0 && currentHour < 8))
                {
                    //夜班
                    sqlAddNew = $"if not exists (select 1 from DeviceCheck where left(CheckDate,10) = '{currentDate}' and DevNo='{checkInfo["DevNo"]}' and CheckItem='{checkInfo["CheckItem"]}') " +
                        $"insert into DeviceCheck values('{checkDate}', '{checker}', '{checkInfo["DevNo"]}','{checkInfo["DevName"]}', '{checkInfo["DevDept"]}', '{checkInfo["CheckItem"]}', '{checkInfo["CheckCriteria"]}', '{checkInfo["Means"]}', '{""}','{""}', '{checkInfo["NightShift"]["value"]}', '{checkInfo["NightRecord"]}' ) " +
                        "else " +
                        $"update DeviceCheck set CheckDate='{checkDate}', Checker='{checker}', NightShift = '{checkInfo["NightShift"]["value"]}', NightRecord='{checkInfo["NightRecord"]}' where left(CheckDate,10) = '{currentDate}' and DevNo='{checkInfo["DevNo"]}' and CheckItem='{checkInfo["CheckItem"]}' ";
                }

                bool sqlResult = DbHelperSQL.Execute(sqlAddNew, connStr);
                if (sqlResult)
                {
                    resJson = "success";
                }
                else
                {
                    resJson = "failure";
                }

                break;
            case "searchTable":
                resJson = SearchTable(searchKey);
                break;
            case "searchResult":
                resJson = SearchResult(searchKey);
                break;
            case "updateTable":
                DevInfo devUpdateInfo = JsonConvert.DeserializeObject<DevInfo>(devData);
                string sqlEditRow = string.Format("update DeviceList set DevNo='{0}', DevName = '{1}', DevType='{2}', DevDept='{3}', Quantity='{4}', Vender='{5}', BuyDate='{6}', LifeTime='{7}', DevClass='{8}', Special='{9}', Capacity='{10}', DevState='{11}', Importance='{12}', Value='{13}', ChangeDate='{14}', ChangeDesc='{15}' where Id=" + devUpdateInfo.id, devUpdateInfo.devno.Trim(), devUpdateInfo.devname.Trim(), devUpdateInfo.devtype.Trim(), devUpdateInfo.devdept.Trim(), devUpdateInfo.quantity.Trim(), devUpdateInfo.vender.Trim(), devUpdateInfo.buydate.Trim(), devUpdateInfo.lifetime.Trim(), devUpdateInfo.devclass.Trim(), devUpdateInfo.special.Trim(), devUpdateInfo.capacity.Trim(), devUpdateInfo.devstate.Trim(), devUpdateInfo.importance.Trim(), devUpdateInfo.value.Trim(), devUpdateInfo.changedate.Trim(), devUpdateInfo.desc.Trim());
                bool sqlUpdateResult = DbHelperSQL.Execute(sqlEditRow, connStr);
                if (sqlUpdateResult)
                {
                    resJson = "success";
                }
                else
                {
                    resJson = "failure";
                }
                break;
            case "delTable":
                DevInfo devDelInfo = JsonConvert.DeserializeObject<DevInfo>(devData);
                string sqlDelRow = string.Format("delete from DeviceList where Id=" + devDelInfo.id);
                bool sqlDelResult = DbHelperSQL.Execute(sqlDelRow, connStr);
                if (sqlDelResult)
                {
                    resJson = "success";
                }
                else
                {
                    resJson = "failure";
                }
                break;
            case "getRepairman":
                resJson = GetRepair2Json();
                break;
            case "assignRepairman":
                resJson = AssignRepair2Json(repairmanName, issueId);
                break;
        }

        context.Response.Write(resJson);
    }

    /// <summary>
    /// 获取设备点检信息表
    /// </summary>
    /// <returns></returns>
    private string getDownByMonth(String date)
    {
        string sql = "SELECT * from RegularCheckTable order by DevNo";
        //DataTable dtCount = DbHelperSQL.ExcuteDataTable(sql, connStr); //用于计总数                   

       

        DataTable dt = DbHelperSQL.ExcuteDataTable(sql, connStr);

        for (int i = 0; i < dt.Rows.Count; i++)
        {
            for (int j = 0; j < dt.Columns.Count; j++)
            {
                string temp = dt.Rows[i][j].ToString().Trim();
                dt.Rows[i][j] = temp;
            }
        }

        //新建json对象，序列化为json字符串
        var json = new
        {
            code = 0,
            msg = "",
            count = 100,
            data = dt
        };
        return JsonConvert.SerializeObject(json);
    }

    /// <summary>
    /// 获取设备点检信息表
    /// </summary>
    /// <returns></returns>
    private string GetCheckTable2Json()
    {
        string sql = "SELECT * from RegularCheckTable order by DevNo";
        DataTable dtCount = DbHelperSQL.ExcuteDataTable(sql, connStr); //用于计总数                   

        sql = "SELECT * from (SELECT *, ROW_NUMBER() OVER(ORDER BY DevNo) AS Num FROM RegularCheckTable)AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex;

        DataTable dt = DbHelperSQL.ExcuteDataTable(sql, connStr);

        for (int i = 0; i < dt.Rows.Count; i++)
        {
            for (int j = 0; j < dt.Columns.Count; j++)
            {
                string temp = dt.Rows[i][j].ToString().Trim();
                dt.Rows[i][j] = temp;
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

    /// <summary>
    /// 获取设备点检结果表
    /// </summary>
    /// <returns></returns>
    private string GetCheckResult2Json()
    {
        string sql = "SELECT * from DeviceCheck order by CheckDate Desc";
        DataTable dtCount = DbHelperSQL.ExcuteDataTable(sql, connStr); //用于计总数                   

        sql = "SELECT * from (SELECT *, ROW_NUMBER() OVER(ORDER BY CheckDate Desc) AS Num FROM DeviceCheck)AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex;

        DataTable dt = DbHelperSQL.ExcuteDataTable(sql, connStr);

        for (int i = 0; i < dt.Rows.Count; i++)
        {
            for (int j = 0; j < dt.Columns.Count; j++)
            {
                string temp = dt.Rows[i][j].ToString().Trim();
                dt.Rows[i][j] = temp;
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

    /// <summary>
    /// 获取设备点检月度汇总表
    /// </summary>
    /// <returns></returns>
    private string GetCheckSummary2Json()
    {
        string sql = "SELECT * from DevCheckView";
        DataTable dtCount = DbHelperSQL.ExcuteDataTable(sql, connStr); //用于计总数                   

        sql = "SELECT * from (SELECT *, ROW_NUMBER() OVER(ORDER BY CheckDate Desc) AS Num FROM DevCheckView)AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex;

        DataTable dt = DbHelperSQL.ExcuteDataTable(sql, connStr);

        for (int i = 0; i < dt.Rows.Count; i++)
        {
            for (int j = 0; j < dt.Columns.Count; j++)
            {
                string temp = dt.Rows[i][j].ToString().Trim();
                dt.Rows[i][j] = temp;
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

    private string GetSumByState()
    {
        string sqlRepairman = "SELECT COUNT(*) AS sum FROM deviceState";
        DataTable dt = DbHelperSQL.ExcuteDataTable(sqlRepairman, connStr);

        for (int i = 0; i < dt.Rows.Count; i++)
        {
            for (int j = 0; j < dt.Columns.Count; j++)
            {
                string temp = dt.Rows[i][j].ToString().Trim();
                dt.Rows[i][j] = temp;
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
    /// <summary>
    /// 获取维修人员列表
    /// </summary>
    /// <returns></returns>
    private string GetSumByState(String st)
    {
        string sqlRepairman = "SELECT COUNT(*) AS sum FROM deviceState WHERE IssueState = '" + st + "'";
        DataTable dt = DbHelperSQL.ExcuteDataTable(sqlRepairman, connStr);

        for (int i = 0; i < dt.Rows.Count; i++)
        {
            for (int j = 0; j < dt.Columns.Count; j++)
            {
                string temp = dt.Rows[i][j].ToString().Trim();
                dt.Rows[i][j] = temp;
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


    /// <summary>
    /// 获取维修人员列表
    /// </summary>
    /// <returns></returns>
    private string GetRepair2Json()
    {
        string sqlRepairman = "select * from userlist where dept='设备部'";
        DataTable dt = DbHelperSQL.ExcuteDataTable(sqlRepairman, connStr);

        for (int i = 0; i < dt.Rows.Count; i++)
        {
            for (int j = 0; j < dt.Columns.Count; j++)
            {
                string temp = dt.Rows[i][j].ToString().Trim();
                dt.Rows[i][j] = temp;
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

    /// <summary>
    /// 指派维修人员
    /// </summary>
    /// <returns></returns>
    private string AssignRepair2Json(string r_name, string r_id)
    {
        string astime = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");//指派时间
        string sqlRepairman = "update DeviceState set AnswerTime='" + astime + "', Repairman='" + r_name + "', IssueState = '已派单' where Id = " + r_id;
        bool isAssign = DbHelperSQL.Execute(sqlRepairman, connStr);
        if (isAssign)
        {
            return "success";
        }
        else
        {
            return "failure";
        }
    }

    /// <summary>
    /// 获取当天的计划表格
    /// </summary>
    /// <returns></returns>
    private string GetTable2Json()
    {
        string sql = "SELECT [Id],[DevNo],[DevName],[DevType],[DevDept],[Quantity],[Vender],[BuyDate],[LifeTime],[DevClass],[Special],[Capacity],[DevState],[Importance],[Value],[ChangeDate],[ChangeDesc] FROM [jinbeimes].[dbo].[DeviceList] order by id";
        DataTable dtCount = DbHelperSQL.ExcuteDataTable(sql, connStr); //用于计总数                   

        sql = "SELECT [Id],[DevNo],[DevName],[DevType],[DevDept],[Quantity],[Vender],[BuyDate],[LifeTime],[DevClass],[Special],[Capacity],[DevState],[Importance],[Value],[ChangeDate],[ChangeDesc] from (SELECT *, ROW_NUMBER() OVER(ORDER BY id ASC) AS Num FROM DeviceList)AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex;

        DataTable dt = DbHelperSQL.ExcuteDataTable(sql, connStr);

        for (int i = 0; i < dt.Rows.Count; i++)
        {
            for (int j = 0; j < dt.Columns.Count; j++)
            {
                string temp = dt.Rows[i][j].ToString().Trim();
                dt.Rows[i][j] = temp;
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

    /// <summary>
    /// 获取设备故障维修信息
    /// </summary>
    /// <returns></returns>
    private string GetFailTable2Json()
    {
        string sql = "SELECT [Id],[DevNo],[DevName],[DevType],[DevDept],[IssueDesc],[Reporter],[ReportTime],[IssueState], [Repairman] FROM [jinbeimes].[dbo].[DeviceState] order by ReportTime desc";
        DataTable dtCount = DbHelperSQL.ExcuteDataTable(sql, connStr); //用于计总数                   

        sql = "SELECT [Id],[DevNo],[DevName],[DevType],[DevDept],[IssueDesc],[Reporter],[ReportTime],[IssueState], [Repairman] from (SELECT *, ROW_NUMBER() OVER(ORDER BY ReportTime DESC) AS Num FROM DeviceState)AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex;

        DataTable dt = DbHelperSQL.ExcuteDataTable(sql, connStr);

        for (int i = 0; i < dt.Rows.Count; i++)
        {
            for (int j = 0; j < dt.Columns.Count; j++)
            {
                string temp = dt.Rows[i][j].ToString().Trim();
                dt.Rows[i][j] = temp;
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


    /// <summary>
    /// 按照关键字搜索点检清单的表格
    /// </summary>
    /// <returns></returns>
    private string SearchTable(string key)
    {
        //重新读取表格
        string sql = "select * from RegularCheckTable where [DevNo]+[DevName]+[DevDept]+[CheckItem]+[CheckCriteria]+[Means] like '%" + key + "%' order by DevNo";
        DataTable dtCount = DbHelperSQL.ExcuteDataTable(sql, connStr); //用于计总数                   

        sql = "select * from (SELECT *, ROW_NUMBER() OVER(ORDER BY DevNo ASC) AS Num FROM RegularCheckTable where [DevNo]+[DevName]+[DevDept]+[CheckItem]+[CheckCriteria]+[Means] like '%" + key + "%')AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex;

        DataTable dt = DbHelperSQL.ExcuteDataTable(sql, connStr);

        for (int i = 0; i < dt.Rows.Count; i++)
        {
            for (int j = 0; j < dt.Columns.Count; j++)
            {
                string temp = dt.Rows[i][j].ToString().Trim();
                dt.Rows[i][j] = temp;
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

    /// <summary>
    /// 按照关键字搜索点检结果的表格
    /// </summary>
    /// <returns></returns>
    private string SearchResult(string key)
    {
        //重新读取表格
        string sql = string.Empty, sqlPage=string.Empty;
        if (key.Contains("DayShift+"))
        {
            key = key.Split('+')[1];
            if (!string.IsNullOrEmpty(key))
            {
                sql = "select * from DeviceCheck where DayShift='" + key + "'";
                sqlPage = "select * from (SELECT *, ROW_NUMBER() OVER(ORDER BY CheckDate DESC) AS Num FROM DeviceCheck where DayShift='" + key + "')AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex;
            }
            else
            {
                sql = "select * from DeviceCheck";
                sqlPage = "select * from (SELECT *, ROW_NUMBER() OVER(ORDER BY CheckDate DESC) AS Num FROM DeviceCheck)AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex;
            }

        }else if (key.Contains("NightShift+"))
        {
            key = key.Split('+')[1];
            if (!string.IsNullOrEmpty(key))
            {
                sql = "select * from DeviceCheck where NightShift = '" + key + "'";
                sqlPage = "select * from (SELECT *, ROW_NUMBER() OVER(ORDER BY CheckDate DESC) AS Num FROM DeviceCheck where NightShift= '" + key + "')AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex;
            }
            else
            {
                sql = "select * from DeviceCheck";
                sqlPage = "select * from (SELECT *, ROW_NUMBER() OVER(ORDER BY CheckDate DESC) AS Num FROM DeviceCheck)AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex;
            }
        }
        else
        {
            sql = "select * from DeviceCheck where [DevNo]+[DevName]+[DevDept]+[CheckItem]+[CheckCriteria]+[Means]+[CheckDate]+[Checker]+[DayShift]+[DayRecord]+[NightShift]+[NightRecord] like '%" + key + "%' order by CheckDate DESC";
            sqlPage = "select * from (SELECT *, ROW_NUMBER() OVER(ORDER BY CheckDate DESC) AS Num FROM DeviceCheck where [DevNo]+[DevName]+[DevDept]+[CheckItem]+[CheckCriteria]+[Means]+[CheckDate]+[Checker]+[DayShift]+[DayRecord]+[NightShift]+[NightRecord] like '%" + key + "%')AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex;
        }

        DataTable dtCount = DbHelperSQL.ExcuteDataTable(sql, connStr); //用于计总数    
        DataTable dt = DbHelperSQL.ExcuteDataTable(sql, connStr);

        for (int i = 0; i < dt.Rows.Count; i++)
        {
            for (int j = 0; j < dt.Columns.Count; j++)
            {
                string temp = dt.Rows[i][j].ToString().Trim();
                dt.Rows[i][j] = temp;
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


    #region 取客户端真实IP

    ///  <summary>  
    ///  取得客户端真实IP。如果有代理则取第一个非内网地址  
    ///  </summary>  
    public static string GetIPAddress
    {
        get
        {
            var result = HttpContext.Current.Request.ServerVariables["HTTP_X_FORWARDED_FOR"];
            if (!string.IsNullOrEmpty(result))
            {
                //可能有代理  
                if (result.IndexOf(".") == -1)        //没有“.”肯定是非IPv4格式  
                    result = null;
                else
                {
                    if (result.IndexOf(",") != -1)
                    {
                        //有“,”，估计多个代理。取第一个不是内网的IP。  
                        result = result.Replace("  ", "").Replace("'", "");
                        string[] temparyip = result.Split(",;".ToCharArray());
                        for (int i = 0; i < temparyip.Length; i++)
                        {
                            if (IsIPAddress(temparyip[i])
                                    && temparyip[i].Substring(0, 3) != "10."
                                    && temparyip[i].Substring(0, 7) != "192.168"
                                    && temparyip[i].Substring(0, 7) != "172.16.")
                            {
                                return temparyip[i];        //找到不是内网的地址  
                            }
                        }
                    }
                    else if (IsIPAddress(result))  //代理即是IP格式  
                        return result;
                    else
                        result = null;        //代理中的内容  非IP，取IP  
                }

            }

            string IpAddress = (HttpContext.Current.Request.ServerVariables["HTTP_X_FORWARDED_FOR"] != null && HttpContext.Current.Request.ServerVariables["HTTP_X_FORWARDED_FOR"] != String.Empty) ? HttpContext.Current.Request.ServerVariables["HTTP_X_FORWARDED_FOR"] : HttpContext.Current.Request.ServerVariables["HTTP_X_REAL_IP"];

            if (string.IsNullOrEmpty(result))
                result = HttpContext.Current.Request.ServerVariables["HTTP_X_REAL_IP"];

            if (string.IsNullOrEmpty(result))
                result = HttpContext.Current.Request.UserHostAddress;

            return result;
        }
    }

    #endregion

    #region  判断是否是IP格式

    ///  <summary>
    ///  判断是否是IP地址格式  0.0.0.0
    ///  </summary>
    ///  <param  name="str1">待判断的IP地址</param>
    ///  <returns>true  or  false</returns>
    public static bool IsIPAddress(string str1)
    {
        if (string.IsNullOrEmpty(str1) || str1.Length < 7 || str1.Length > 15) return false;

        const string regFormat = @"^d{1,3}[.]d{1,3}[.]d{1,3}[.]d{1,3}$";

        var regex = new Regex(regFormat, RegexOptions.IgnoreCase);
        return regex.IsMatch(str1);
    }

    #endregion

    //获取客户端IP
    private string GetClientIP()
    {
        string result = HttpContext.Current.Request.ServerVariables["HTTP_X_FORWARDED_FOR"];
        if (null == result || result == String.Empty)
        {
            result = HttpContext.Current.Request.ServerVariables["REMOTE_ADDR"];
        }

        if (null == result || result == String.Empty)
        {
            result = HttpContext.Current.Request.UserHostAddress;
        }
        return result;
    }

    public string GetIP()
    {
        string uip = "";
        if (HttpContext.Current.Request.ServerVariables["HTTP_VIA"] != null)
        {
            uip = HttpContext.Current.Request.ServerVariables["HTTP_X_FORWARDED_FOR"].ToString();
        }
        else
        {
            uip = HttpContext.Current.Request.ServerVariables["REMOTE_ADDR"].ToString();
        }
        return uip;
    }


    public bool IsReusable
    {
        get
        {
            return false;
        }
    }

}