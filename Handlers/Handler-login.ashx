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
    private class DevFailInfo
    {
        public int id { get; set; }
        public string devno { get; set; }
        public string devname { get; set; }
        public string devtype { get; set; }
        public string devdept { get; set; }
        public string desc { get; set; }
        public string reporter { get; set; }
        public string failtime { get; set; }
    }

    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "text/plain";
        string searchKey = string.Empty;
        string resJson = string.Empty;
        string actId = context.Request["actid"];
        string loginData = context.Request["data"];
        string devId = context.Request["devid"];
        string devFailData = context.Request["faildata"];
        string repairmanId = context.Request["workid"];
        string repairmanName = context.Request["workname"];
        string issueId = context.Request["issueid"];
        string mac = context.Request["mac"];

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
            case "getByMac": 
                resJson = getDevice2Json(mac);
                break;
            case "setMacById":
                resJson = setDeviceMAC(devId, mac);
                break;
            case "checkDevId":
                resJson = CheckDevice2Json(devId);
                break;
            case "login":
                JObject joUser = (JObject)JsonConvert.DeserializeObject(loginData);
                string user = joUser["username"].ToString().Trim();
                string pass = joUser["password"].ToString().Trim();
                resJson = CheckLogin2Json(user, pass);
                break;

            case "getTable":
                resJson = GetTable2Json();
                break;
            case "getFailTable":
                resJson = GetFailTable2Json();
                break;
            case "devFail": //申报故障
                DevFailInfo devFailInfo = JsonConvert.DeserializeObject<DevFailInfo>(devFailData);
                string sqlFailReport =string.Format("insert into DeviceState (DevNo, DevName, DevType, DevDept, IssueDesc, Reporter, ReportTime, IssueState) values ('{0}','{1}','{2}','{3}','{4}','{5}','{6}','{7}')", devFailInfo.devno, devFailInfo.devname, devFailInfo.devtype, devFailInfo.devdept, devFailInfo.desc, devFailInfo.reporter, devFailInfo.failtime, "待维修");
                bool sqlFailResult = DbHelperSQL.Execute(sqlFailReport, connStr);
                if (sqlFailResult)
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
            case "getFailMsg":
                resJson = GetFailMsg2Json();
                break;
            case "logOut":
                resJson = LogOut(repairmanId, repairmanName);
                break;
        }

        context.Response.Write(resJson);
    }

    /// <summary>
    /// 检查是否存在指定的设备
    /// </summary>
    /// <param name="id">设备号</param>
    /// <returns></returns>
    private string setDeviceMAC(string id,string mac)
    {
        string dsql = "UPDATE [dbo].[DeviceList]  SET [mac] = '' WHERE [mac]='"+mac+"'"; 
        string sql = "UPDATE [dbo].[DeviceList]  SET [mac] = '"+mac+"' WHERE DevNo='"+id+"'"; 
        DbHelperSQL.Execute(dsql, connStr); 

        DbHelperSQL.Execute(sql, connStr); 
        
        //新建json对象，序列化为json字符串
        var json = new
        {
            code = 0,
            msg = "",
            count = 1,
            data = ""
        };
        return JsonConvert.SerializeObject(json);

    }
    private string getDevice2Json(string mac)
    {
        string sql = "SELECT DevNo,DevName FROM [jinbeimes].[dbo].[DeviceList] WHERE mac='"+mac+"'";

        DataTable dt = DbHelperSQL.ExcuteDataTable(sql, connStr);

        //新建json对象，序列化为json字符串
        var json = new
        {
            code = 0,
            msg = "",
            count = 1,
            data = dt
        };
        return JsonConvert.SerializeObject(json);

    }
    
    /// <summary>
    /// 检查是否存在指定的设备
    /// </summary>
    /// <param name="id">设备号</param>
    /// <returns></returns>
    private string CheckDevice2Json(string id)
    {
        string sql = "SELECT DevName FROM [jinbeimes].[dbo].[DeviceList] WHERE DevNo='"+id+"'";

        string dt =(string)DbHelperSQL.ExecuteScalar(sql, connStr);

        //新建json对象，序列化为json字符串
        var json = new
        {
            code = 0,
            msg = "",
            count = 1,
            data = dt
        };
        return JsonConvert.SerializeObject(json);

    }
    /// <summary>
    /// 登录信息检查
    /// </summary>
    /// <param name="usr">用户名</param>
    /// <param name="pas">密码</param>
    /// <returns></returns>
    private string CheckLogin2Json(string usr, string pas)
    {
        string sqlLogin = string.Format("select userid, realname from userlist where userid='{0}' and userpassword = '{1}'", usr, pas);
        DataTable dt = DbHelperSQL.ExcuteDataTable(sqlLogin, connStr);
        if (dt.Rows.Count > 0)
        {
            string t = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
            string sqlLog = string.Format("insert into SysLog values('{0}', '{1}', '{2}', '{3}')", t, usr, dt.Rows[0]["realname"].ToString(), "登录系统");
            DbHelperSQL.Execute(sqlLog, connStr);
        }

        //新建json对象，序列化为json字符串
        var json = new
        {
            code = 0,
            msg = "",
            count = 1,
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
        string sqlRepairman = "update DeviceState set AnswerTime='"+astime+"', Repairman='"+r_name+"', IssueState = '已派单' where Id = "+ r_id;
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
    /// 获取设备故障维修信息
    /// </summary>
    /// <returns></returns>
    private string GetFailMsg2Json()
    {
        string sql = "SELECT [Id],[DevNo],[DevName],[DevDept],[IssueDesc],[Reporter],[ReportTime],[IssueState], [Repairman], [Confirmor], [ConfirmTime] FROM [jinbeimes].[dbo].[DeviceState] order by ReportTime desc";
        DataTable dt = DbHelperSQL.ExcuteDataTable(sql, connStr); //用于计总数                   

        //sql = "SELECT [Id],[DevNo],[DevName],[DevType],[DevDept],[IssueDesc],[Reporter],[ReportTime],[IssueState], [Repairman], [Confirmor], [ConfirmTime] from (SELECT *, ROW_NUMBER() OVER(ORDER BY ReportTime DESC) AS Num FROM DeviceState)AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex;

        //DataTable dt = DbHelperSQL.ExcuteDataTable(sql, connStr);

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
    /// 按照关键字搜索当天的表格
    /// </summary>
    /// <returns></returns>
    private string SearchTable(string key)
    {
        //重新读取表格
        string today = "2020/4/4"; //DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss").Split(' ')[0];
        string sql = "select id, sheetname, machineid, machinename, orderid, orderno, orderperiod, contract, modelvoltage, size, length, requirement, type, dayshift, nightshift, reeltype, reelsize from ProductionPlan where plantime like '" + today + "%' AND sheetname+machineid+ machinename+orderid+orderno+ orderperiod+ contract+ modelvoltage+ size+ length+ requirement+ type+ dayshift+ nightshift+ reeltype+ reelsize like '%" + key + "%' order by id";
        DataTable dtCount = DbHelperSQL.ExcuteDataTable(sql, connStr); //用于计总数                   

        sql = "select id, sheetname, machineid, machinename, orderid, orderno, orderperiod, contract, modelvoltage, size, length, requirement, type, dayshift, nightshift, reeltype, reelsize from (SELECT *, ROW_NUMBER() OVER(ORDER BY id ASC) AS Num FROM ProductionPlan where plantime like '" + today + "%' AND sheetname+machineid+ machinename+orderid+orderno+ orderperiod+ contract+ modelvoltage+ size+ length+ requirement+ type+ dayshift+ nightshift+ reeltype+ reelsize like '%" + key + "%')AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex;

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

    private string LogOut(string uid, string un)
    {
        string t = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
        string sqlLog = string.Format("insert into SysLog values('{0}', '{1}', '{2}', '{3}')", t, uid, un, "退出系统");
        bool isOk = DbHelperSQL.Execute(sqlLog, connStr);
        if (isOk)
        {
            return "success";
        }
        else
        {
            return "failure";
        }
    }

    public bool IsReusable
    {
        get
        {
            return false;
        }
    }

}