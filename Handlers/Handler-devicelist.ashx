﻿<%@ WebHandler Language="C#" Class="Handler_planreport" %>

using Newtonsoft.Json;
using System;
using System.Configuration;
using System.Data;
using System.Text.RegularExpressions;
using System.Web;

public class Handler_planreport : IHttpHandler
{

    static string connStr = ConfigurationManager.ConnectionStrings["ConnectionString"].ToString();
    static string connScadaStr = ConfigurationManager.ConnectionStrings["ConnectionSCADAString"].ToString();
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
        public string reserved2 { get; set; } //xxy 2020-06-30
    }

    public class DevIssue
    {
        /// <summary>
        /// 
        /// </summary>
        public int Id { get; set; }
        /// <summary>
        /// 
        /// </summary>
        public string DevNo { get; set; }
        /// <summary>
        /// 冠标大拉机
        /// </summary>
        public string DevName { get; set; }
        /// <summary>
        /// 
        /// </summary>
        public string DevType { get; set; }
        /// <summary>
        /// 导体车间
        /// </summary>
        public string DevDept { get; set; }
        /// <summary>
        /// 不能开机
        /// </summary>
        public string IssueDesc { get; set; }
        /// <summary>
        /// 
        /// </summary>
        public string Reporter { get; set; }
        /// <summary>
        /// 
        /// </summary>
        public string ReportTime { get; set; }
        /// <summary>
        /// 待维修
        /// </summary>
        public string IssueState { get; set; }
        /// <summary>
        /// 
        /// </summary>
        public string Repairman { get; set; }
    }

    public class RepairForm
    {
        /// <summary>
        /// 
        /// </summary>
        public string id { get; set; }
        /// <summary>
        /// 
        /// </summary>
        public string devno { get; set; }
        /// <summary>
        /// 冠标大拉机
        /// </summary>
        public string devname { get; set; }
        /// <summary>
        /// 
        /// </summary>
        public string devtype { get; set; }
        /// <summary>
        /// 导体车间
        /// </summary>
        public string devdept { get; set; }
        /// <summary>
        /// 测试
        /// </summary>
        public string desc { get; set; }

        public string reserved3 { get; set; }
    }

    public class ConfirmInfo
    {
        /// <summary>
        /// 
        /// </summary>
        public int Id { get; set; }
        /// <summary>
        /// 
        /// </summary>
        public string DevNo { get; set; }
        /// <summary>
        /// 冠标大拉机
        /// </summary>
        public string DevName { get; set; }
        /// <summary>
        /// 
        /// </summary>
        public string DevType { get; set; }
        /// <summary>
        /// 导体车间
        /// </summary>
        public string DevDept { get; set; }
        /// <summary>
        /// 
        /// </summary>
        public string IssueType { get; set; }
        /// <summary>
        /// 不能开机
        /// </summary>
        public string IssueDesc { get; set; }
        /// <summary>
        /// 
        /// </summary>
        public string Reporter { get; set; }
        /// <summary>
        /// 
        /// </summary>
        public string ReportTime { get; set; }
        /// <summary>
        /// 待验收
        /// </summary>
        public string IssueState { get; set; }
        /// <summary>
        /// 
        /// </summary>
        public string AnswerTime { get; set; }
        /// <summary>
        /// 
        /// </summary>
        public string AnswerType { get; set; }
        /// <summary>
        /// 
        /// </summary>
        public string Repairman { get; set; }
        /// <summary>
        /// 
        /// </summary>
        public string RepairLeader { get; set; }
        /// <summary>
        /// 
        /// </summary>
        public string TakeJobTime { get; set; }
        /// <summary>
        /// 修完了，一切正常
        /// </summary>
        public string RepairDesc { get; set; }
        /// <summary>
        /// 
        /// </summary>
        public string RepairTime { get; set; }
        /// <summary>
        /// 
        /// </summary>
        public string Confirmor { get; set; }
        /// <summary>
        /// 
        /// </summary>
        public string ConfirmTime { get; set; }
        /// <summary>
        /// 
        /// </summary>
        public string ConfirmDesc { get; set; }
        /// <summary>
        /// 
        /// </summary>
        public string State { get; set; }
        /// <summary>
        /// 
        /// </summary>
        public string reserved2 { get; set; }
        /// <summary>
        /// 
        /// </summary>
        public string reserved3 { get; set; }
        /// <summary>
        /// 
        /// </summary>
        public string reserved4 { get; set; }
        /// <summary>
        /// 
        /// </summary>
        public string reserved5 { get; set; }
        /// <summary>
        /// 
        /// </summary>
        public int Num { get; set; }
    }




    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "text/plain";
        string searchKey = string.Empty;
        string resJson = string.Empty;
        string actId = context.Request["actid"];
        string devData = context.Request["data"];
        string devYearMonth = context.Request["yearmonth"];
        string devFailData = context.Request["faildata"];
        string repairmanId = context.Request["workid"];
        string repairmanName = context.Request["workname"];
        string issueId = context.Request["issueid"];
        searchKey = context.Request["searchkey"];
        string dateRange = context.Request["daterange"];
        string searchDevName = context.Request["devname"];
        if ( searchKey != null)
        {
            searchKey = context.Request["searchkey"].Trim(); //获取搜索关键字
        }
        string page = context.Request["page"];
        string limit = context.Request["limit"];
        startIndex = (Convert.ToInt32(page) - 1) * Convert.ToInt32(limit) + 1;
        endIndex = Convert.ToInt32(page) * Convert.ToInt32(limit);

        switch (actId)
        {
            case "getTable":
                resJson = GetTable2Json();
                break;
            case "getDeviceLogTable":
                resJson = GetDeviceLogTable2Json();
                break;
            case "getFailTable":
                resJson = GetFailTable2Json();
                break;
            case "getFailTableByactive":
                if (searchDevName == null) searchDevName = "";
                resJson = GetFailTable2JsonByactin(searchDevName); 
                break;
            case "getFailTableByConfol":
                if (searchDevName == null) searchDevName = "";
                resJson = GetFailTable2JsonByactin1(searchDevName); 
                break;
            case "insTable":
                DevInfo devInfo = JsonConvert.DeserializeObject<DevInfo>(devData);
                string sqlAddNew = string.Format("insert into DeviceList values('{0}','{1}','{2}','{3}','{4}','{5}','{6}','{7}','{8}','{9}','{10}','{11}','{12}','{13}','{14}','{15}','{16}','{17}','{18}','{19}','{20}')", devInfo.devno.Trim(), devInfo.devname.Trim(), devInfo.devtype.Trim(), devInfo.devdept.Trim(), devInfo.quantity.Trim(), devInfo.vender.Trim(), devInfo.buydate.Trim(), devInfo.lifetime.Trim(), devInfo.devclass.Trim(), devInfo.special.Trim(), devInfo.capacity.Trim(), devInfo.devstate.Trim(), devInfo.importance.Trim(), devInfo.value.Trim(), devInfo.changedate.Trim(), devInfo.desc.Trim(), "", "", "", "", "");
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
            case "updateTable":
                DevInfo devUpdateInfo = JsonConvert.DeserializeObject<DevInfo>(devData);
                string sqlEditRow = string.Format("update DeviceList set DevNo='{0}', DevName = '{1}', DevType='{2}', DevDept='{3}', Quantity='{4}', Vender='{5}', BuyDate='{6}', LifeTime='{7}', DevClass='{8}', Special='{9}', Capacity='{10}', DevState='{11}', Importance='{12}', Value='{13}', ChangeDate='{14}', ChangeDesc='{15}' where Id="+devUpdateInfo.id, devUpdateInfo.devno.Trim(), devUpdateInfo.devname.Trim(), devUpdateInfo.devtype.Trim(), devUpdateInfo.devdept.Trim(), devUpdateInfo.quantity.Trim(), devUpdateInfo.vender.Trim(), devUpdateInfo.buydate.Trim(), devUpdateInfo.lifetime.Trim(), devUpdateInfo.devclass.Trim(), devUpdateInfo.special.Trim(), devUpdateInfo.capacity.Trim(), devUpdateInfo.devstate.Trim(), devUpdateInfo.importance.Trim(), devUpdateInfo.value.Trim(), devUpdateInfo.changedate.Trim(), devUpdateInfo.desc.Trim());
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
            case "devFail": //申报故障
                DevFailInfo devFailInfo = JsonConvert.DeserializeObject<DevFailInfo>(devFailData);
                //原 string sqlFailReport =string.Format("insert into DeviceState (DevNo, DevName, DevType, DevDept, IssueDesc, Reporter, ReportTime, IssueState) values ('{0}','{1}','{2}','{3}','{4}','{5}','{6}','{7}')", devFailInfo.devno, devFailInfo.devname, devFailInfo.devtype, devFailInfo.devdept, devFailInfo.desc, devFailInfo.reporter, devFailInfo.failtime, "待维修");

                //xxy 2020-06-30    
                string reportTime = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");//格式替换devFailInfo.failtime
                string sqlFailReport =string.Format("insert into DeviceState (DevNo, DevName, DevType, DevDept, IssueDesc, Reporter, ReportTime, IssueState,reserved2) values ('{0}','{1}','{2}','{3}','{4}','{5}','{6}','{7}','{8}')",
                    devFailInfo.devno, devFailInfo.devname, devFailInfo.devtype, devFailInfo.devdept, devFailInfo.desc, devFailInfo.reporter, reportTime, "待维修",devFailInfo.reserved2);

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
            case "getLocalDeviceInfo":
                resJson = GetLocalDeviceInfo2Json(devData);
                break;
            case "takeJob":
                resJson = TakeJob(devData, repairmanName);
                break;
            case "takeJob1":
                resJson = TakeJob1(devData, repairmanName);
                break;
            case "updateRepairTable":
                resJson = UpdateRepairTable(devData, repairmanName);
                break;
            case "confirmRepair":
                resJson = ConfirmRepair(devData, repairmanName);
                break;
            case "searchLog":
                resJson = SearchLog(searchKey);
                break;
            case "searchKey":
                resJson = SearchKey(searchDevName, dateRange);
                break;
            case "getDevLogTable":
                resJson = GetDevLogTable(devYearMonth);
                break;
            case "getDeviceList":
                resJson = GetDeviceTable2Json();
                break;
        }

        context.Response.Write(resJson);
    }

    /// <summary>
    /// 获取维修人员列表
    /// </summary>
    /// <returns></returns>
    private string GetRepair2Json()
    {
        string sqlRepairman = "select * from userlist where dept='维修班'";
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
    /// 获取设备列表
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

    /// <summary>
    /// 获取设备日志的表格
    /// </summary>
    /// <returns></returns>
    private string GetDeviceLogTable2Json()
    {
        //string sql = "SELECT [Id],[DevNo],[DevName],[DevType],[DevDept],[Quantity],[Vender],[BuyDate],[LifeTime],[DevClass],[Special],[Capacity],[DevState],[Importance],[Value],[ChangeDate],[ChangeDesc] FROM [jinbeimes].[dbo].[DeviceList] order by id";
        //string sql = "SELECT a.*, b.DevType, b.DevDept FROM	dbo.tt_WorkTime a LEFT JOIN dbo.DeviceList b ON b.DevNo = a.DeviceId ORDER BY date DESC";
        //string sql = "SELECT a.*, b.DevType, b.DevDept FROM OPENDATASOURCE('SQLOLEDB','Data Source=GCD-20200509BFW;User ID=admin;Password=admin').[JINBEI_SCADA].[dbo].[worktime] a LEFT JOIN dbo.DeviceList b ON b.DevNo = a.DeviceId ORDER BY date DESC";
        string sql = "SELECT a.*, b.DevType, b.DevDept, CONVERT(VARCHAR, c.WorkTime) AS FaultTime FROM OPENDATASOURCE('SQLOLEDB','Data Source=GCD-20200509BFW;User ID=admin;Password=admin').[JINBEI_SCADA].[dbo].[worktime] a LEFT JOIN dbo.DeviceList b ON b.DevNo = a.DeviceId LEFT JOIN dbo.downbydesc c ON a.date=c.date AND a.DeviceId=c.DevNo ORDER BY a.date DESC";
        DataTable dtCount = DbHelperSQL.ExcuteDataTable(sql, connStr); //用于计总数                   

        sql = "SELECT * FROM (SELECT a.*, b.DevType, b.DevDept, CONVERT(VARCHAR, c.WorkTime) AS FaultTime, ROW_NUMBER() OVER(ORDER BY a.date DESC) AS Num FROM OPENDATASOURCE('SQLOLEDB','Data Source=GCD-20200509BFW;User ID=admin;Password=admin').[JINBEI_SCADA].[dbo].[worktime] a LEFT JOIN dbo.DeviceList b ON b.DevNo = a.DeviceId LEFT JOIN dbo.downbydesc c ON a.date=c.date AND a.DeviceId=c.DevNo)AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex;

        DataTable dt = DbHelperSQL.ExcuteDataTable(sql, connStr);
        //dt.Columns.Add("FaultTime");
        //foreach(DataRow dr in dt.Rows)
        //{
        //    dr["FaultTime"] = 0;
        //}

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


    private string GetDevLogTable(string day)
    {
        string sql = $"SELECT a.*, b.DevType, b.DevDept, CONVERT(VARCHAR, c.WorkTime) AS FaultTime FROM OPENDATASOURCE('SQLOLEDB','Data Source=GCD-20200509BFW;User ID=admin;Password=admin').[JINBEI_SCADA].[dbo].[worktime] a LEFT JOIN dbo.DeviceList b ON b.DevNo = a.DeviceId LEFT JOIN dbo.downbydesc c ON a.date=c.date AND a.DeviceId=c.DevNo WHERE a.date='{day}' ORDER BY a.date DESC";
        DataTable dtCount = DbHelperSQL.ExcuteDataTable(sql, connStr); //用于计总数                   

        sql = $"SELECT * FROM (SELECT a.*, b.DevType, b.DevDept, CONVERT(VARCHAR, c.WorkTime) AS FaultTime, ROW_NUMBER() OVER(ORDER BY a.date DESC) AS Num FROM OPENDATASOURCE('SQLOLEDB','Data Source=GCD-20200509BFW;User ID=admin;Password=admin').[JINBEI_SCADA].[dbo].[worktime] a LEFT JOIN dbo.DeviceList b ON b.DevNo = a.DeviceId LEFT JOIN dbo.downbydesc c ON a.date=c.date AND a.DeviceId=c.DevNo WHERE a.date='{day}')AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex;

        DataTable dt = DbHelperSQL.ExcuteDataTable(sql, connStr);
        //dt.Columns.Add("FaultTime");
        //foreach(DataRow dr in dt.Rows)
        //{
        //    dr["FaultTime"] = 0;
        //}

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
    /// <summary>
    /// 获取设备故障维修信息
    /// </summary>
    /// <returns></returns>
    private string GetFailTable2JsonByactin1(String searchDevName)
    {
        //string sql = "SELECT * FROM [jinbeimes].[dbo].[DeviceState] order by ReportTime desc";
        string sql = "SELECT * FROM [jinbeimes].[dbo].[DeviceState] order by Id desc";
        DataTable dtCount = DbHelperSQL.ExcuteDataTable(sql, connStr); //用于计总数                   


        sql = "SELECT * from (SELECT *, ROW_NUMBER() OVER(ORDER BY Id DESC) AS Num FROM DeviceState LEFT JOIN (SELECT realname,userid FROM UserList) a  ON  userid = DeviceState.Reporter )AS TempTable WHERE " +
            " IssueState<>'已验收' AND   " +
            " DevNo like '%"+searchDevName+"%' and " +
            "Num BETWEEN " + startIndex + " AND " + endIndex;


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
    private string GetFailTable2JsonByactin(String searchDevName)
    {
        //string sql = "SELECT * FROM [jinbeimes].[dbo].[DeviceState] order by ReportTime desc";
        string sql = "SELECT * FROM [jinbeimes].[dbo].[DeviceState] order by Id desc";
        DataTable dtCount = DbHelperSQL.ExcuteDataTable(sql, connStr); //用于计总数                   


        sql = "SELECT * from (SELECT *, ROW_NUMBER() OVER(ORDER BY Id DESC) AS Num FROM DeviceState LEFT JOIN (SELECT realname,userid FROM UserList) a  ON  userid = DeviceState.Reporter )AS TempTable WHERE " +
            " IssueState<>'已验收' AND IssueState<>'待验收' and " +
            " DevNo like '%"+searchDevName+"%' and " +
            "Num BETWEEN " + startIndex + " AND " + endIndex;


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
        //string sql = "SELECT * FROM [jinbeimes].[dbo].[DeviceState] order by ReportTime desc";
        string sql = "SELECT * FROM [jinbeimes].[dbo].[DeviceState] order by Id desc";
        DataTable dtCount = DbHelperSQL.ExcuteDataTable(sql, connStr); //用于计总数                   

        sql = "SELECT * from (SELECT *, ROW_NUMBER() OVER(ORDER BY Id DESC) AS Num FROM DeviceState LEFT JOIN (SELECT realname,userid FROM UserList) a  ON  userid = DeviceState.Reporter )AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex;


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

    private string GetLocalDeviceInfo2Json(string devid)
    {
        string sqlDevice = "select * from DeviceList where DevNo='"+devid+"'";
        DataTable dt = DbHelperSQL.ExcuteDataTable(sqlDevice, connStr);

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


    /// <summary>
    /// 维修主管接单
    /// </summary>
    /// <returns></returns>
    private string TakeJob(string d, string r_name)
    {
        DevIssue devIssue = JsonConvert.DeserializeObject<DevIssue>(d);
        string tktime = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");//接单时间
        string sqlRepairman = "update DeviceState set AnswerTime='"+tktime+"', TakeJobTime='"+tktime+"', Repairman='"+r_name+"', IssueState = '维修中', RepairLeader='"+r_name+"' where Id = "+ devIssue.Id;
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
    /// 非维修主管接单
    /// </summary>
    /// <returns></returns>
    private string TakeJob1(string d, string r_name)
    {
        DevIssue devIssue = JsonConvert.DeserializeObject<DevIssue>(d);
        string tktime = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");//接单时间
        string sqlRepairman = "update DeviceState set TakeJobTime='"+tktime+"', Repairman='"+r_name+"', IssueState = '维修中' where Id = "+ devIssue.Id;
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

    private string UpdateRepairTable(string d, string r_name)
    {
        RepairForm devIssue = JsonConvert.DeserializeObject<RepairForm>(d);
        string rptime = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");//维修完成时间
        string sqlRepairman = "update DeviceState set reserved3='"+devIssue.reserved3+"', RepairTime='"+rptime+"', RepairDesc='"+devIssue.desc+"', IssueState = '已验收' where Id = "+ devIssue.id;//待验收
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

    private string ConfirmRepair(string d, string r_name)
    {
        ConfirmInfo devIssue = JsonConvert.DeserializeObject<ConfirmInfo>(d);
        string cftime = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");//维修确认时间
        string sqlRepairman = "update DeviceState set ConfirmTime='"+cftime+"', Confirmor='"+r_name+"', ConfirmDesc='"+devIssue.ConfirmDesc+"', IssueState = '已验收' where Id = "+ devIssue.Id;
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

    private string SearchLog(string key)
    {
        string sql = string.Format("select * from DeviceState where concat(Id,DevNo,DevName,DevDept,reserved2, IssueType,IssueDesc,Reporter,ReportTime,IssueState,AnswerTime,AnswerType,Repairman,RepairLeader,TakeJobTime,RepairDesc,RepairTime,Confirmor,ConfirmTime,ConfirmDesc) LIKE '%"+key+"%'");
        DataTable dtCount = DbHelperSQL.ExcuteDataTable(sql, connStr); //用于计总数  
        sql = "select * from (SELECT *, ROW_NUMBER() OVER(ORDER BY id DESC) AS Num FROM DeviceState where concat(Id,DevNo,DevName,DevDept,reserved2, IssueType,IssueDesc,Reporter,ReportTime,IssueState,AnswerTime,AnswerType,Repairman,RepairLeader,TakeJobTime,RepairDesc,RepairTime,Confirmor,ConfirmTime,ConfirmDesc) LIKE '%"+key+"%')AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex;
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

    private string SearchKey(string key1, string key2)
    {
        string k1 = key1.Trim();
        string[] k2 = null;
        string sql = string.Empty;
        if (string.IsNullOrEmpty(key2))
        {//不限时间
            sql = string.Format("select * from DeviceState where DevName LIKE '%" + k1 + "%'");
        }
        else
        {//时间范围
            k2 = key2.Split('~');
            sql = string.Format("select * from DeviceState where DevName LIKE '%" + k1 + "%' and ReportTime>='" + k2[0].Trim() + "' and ReportTime <= '" + k2[1].Trim() + "'");
        }
        DataTable dtCount = DbHelperSQL.ExcuteDataTable(sql, connStr); //用于计总数  
        if (string.IsNullOrEmpty(key2))
        {
            sql = "select * from (SELECT *, ROW_NUMBER() OVER(ORDER BY id DESC) AS Num FROM DeviceState where  DevName LIKE '%"+k1+"%')AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex;
        }
        else
        {
            sql = "select * from (SELECT *, ROW_NUMBER() OVER(ORDER BY id DESC) AS Num FROM DeviceState where  DevName LIKE '%"+k1+"%' and ReportTime>='"+k2[0].Trim()+"' and ReportTime <= '"+k2[1].Trim()+"')AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex;
        }

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

    /// <summary>
    /// 获取设备名称，编号列表
    /// </summary>
    /// <returns></returns>
    private string GetDeviceTable2Json()
    {
        string sql = "SELECT [Id],[DevNo],[DevName] FROM [jinbeimes].[dbo].[DeviceList] order by id";
        DataTable dt = DbHelperSQL.ExcuteDataTable(sql, connStr); //用于计总数                   

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

    public bool IsReusable
    {
        get
        {
            return false;
        }
    }

}