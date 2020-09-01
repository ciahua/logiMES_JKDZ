<%@ WebHandler Language="C#" Class="Handler_planreport" %>

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

        string star = context.Request["star"];
        string end = context.Request["end"];
        string type = context.Request["type"];
        string name = context.Request["name"];
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
            case "reportbydevname":
                resJson = GetReport(type,star,end,name);
                break;
            case "reportbydate":
                resJson = GetReport(type,star);
                break;
            case "reportByType":
                resJson = GetReportByType(type, star);
                break;
            case "getReport":
                resJson = GetReport(star,end,type);
                break;
            case "getData":
                resJson = GetData(star,end,type);
                break;
            case "getTable":
                resJson = GetTable2Json();
                break;
            case "getDailyEnergyTable":
                resJson = GetDailyEnergyTable2Json();
                break;
            case "getFailTable":
                resJson = GetFailTable2Json();
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
        }

        context.Response.Write(resJson);
    }
    //GetReport(type,star,end,name); 
    private string GetReport(String type,String star,String end,String name)
    {
        string sql = "";
        sql += "SELECT SUBSTRING(SQLtime,0," + type + ") AS date,devname,ROUND(SUM(val),2) AS val FROM energyByDate ";
        sql += " where SQLtime >= '"+star+"' and SQLtime <= '"+end+"' AND devname='"+name+"'";
        sql += "GROUP BY SUBSTRING(SQLtime,0," + type + "),devname ";
        DataTable dt = DbHelperSQL.ExcuteDataTable(sql, connScadaStr);

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
            // count = dtCount.Rows.Count,
            data = dt
        };
        return JsonConvert.SerializeObject(json);
    }

    private string GetReportByType(String type,String date)
    {
             
        string sql = "SELECT " +
            "SUBSTRING(SQLtime,0," + type + ") AS SQLtime " +
            ",SUBSTRING(devName,0,3) AS devName " +
            ",ROUND(SUM(val),2)  AS val FROM View_24 WHERE " +
            "SUBSTRING(SQLtime,0," + type + ")='"+date+"' " +
            "GROUP BY SUBSTRING(devName,0,3),SUBSTRING(SQLtime,0," + type + ") ";


        DataTable dt = DbHelperSQL.ExcuteDataTable(sql, connScadaStr);

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
            // count = dtCount.Rows.Count,
            data = dt
        };
        return JsonConvert.SerializeObject(json);
    }


    private string GetReport(String type,String date)
    {
        string sql = "";
        sql += "SELECT SUBSTRING(SQLtime,0," + type + ") AS date,devname,ROUND(SUM(val),2) AS val FROM energyByDate ";
        sql += "WHERE SUBSTRING(SQLtime,0," + type + ")='"+date+"' ";
        sql += "GROUP BY SUBSTRING(SQLtime,0," + type + "),devname ";


        DataTable dt = DbHelperSQL.ExcuteDataTable(sql, connScadaStr);

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
            // count = dtCount.Rows.Count,
            data = dt
        };
        return JsonConvert.SerializeObject(json);
    }
    private string GetData(String star,String end,String type)
    {
        string sql = "";

        sql = "SELECT SUBSTRING(SQLtime, 1, "+type+") AS SQLtime, ROUND(SUM(永雄中拉), 2) AS 永雄中拉, ROUND(SUM(欣宏泰细拉), 2) AS 欣宏泰细拉, ROUND(SUM([2# 细丝机]), 2) AS [2# 细丝机], ROUND(SUM([1# 细丝机]), 2) AS [1# 细丝机], ROUND(SUM(欣宏泰中拉), 2) AS 欣宏泰中拉, ROUND(SUM(杰创大拉), 2) AS 杰创大拉, ROUND(SUM(冠标大拉机), 2) AS 冠标大拉机, ROUND(SUM(电解镀锡机), 2) AS 电解镀锡机, ROUND(SUM([60填充挤橡机]), 2) AS [60填充挤橡机], ROUND(SUM(三层共挤挤橡连硫生产线), 2) AS 三层共挤挤橡连硫生产线, ROUND(SUM([150+120挤橡连硫生产线]), 2) AS [150+120挤橡连硫生产线], ROUND(SUM([90+120挤橡连硫生产线]), 2) AS [90+120挤橡连硫生产线], ROUND(SUM([100挤橡连硫生产线B]), 2) AS [100挤橡连硫生产线B], ROUND(SUM([100挤橡连硫生产线A]), 2) AS [100挤橡连硫生产线A], ROUND(SUM([90+70挤橡连硫生产线]), 2) AS [90+70挤橡连硫生产线], ROUND(SUM([70挤橡连硫生产线]), 2) AS [70挤橡连硫生产线], ROUND(SUM([4# 70挤橡连硫生产线]), 2) AS [4# 70挤橡连硫生产线], ROUND(SUM([3# 70挤橡连硫生产线]), 2) AS [3# 70挤橡连硫生产线], ROUND(SUM([2# 70+60挤橡连硫生产线]), 2) AS [2# 70+60挤橡连硫生产线], ROUND(SUM([1# 70+60挤橡连硫生产线]), 2) AS [1# 70+60挤橡连硫生产线], ROUND(SUM(框式绞线机), 2) AS 框式绞线机, ROUND(SUM([8# D631束线机]), 2) AS [8# D631束线机], ROUND(SUM([7# D631束线机]), 2) AS [7# D631束线机], ROUND(SUM([6#D631P束丝机]), 2) AS [6#D631P束丝机], ROUND(SUM([5#D631P束丝机]), 2) AS [5#D631P束丝机], ROUND(SUM([500笼绞机]), 2) AS [500笼绞机], ROUND(SUM([630笼绞机]), 2) AS [630笼绞机], ROUND(SUM([2# 630管绞机]), 2) AS [2# 630管绞机], ROUND(SUM([2# 500管绞机]), 2) AS [2# 500管绞机], ROUND(SUM([500管绞机]), 2) AS [500管绞机], ROUND(SUM([630管绞机]), 2) AS [630管绞机], ROUND(SUM([4# D631束线机]), 2) AS [4# D631束线机], ROUND(SUM([3# D631束线机]), 2) AS [3# D631束线机], ROUND(SUM([2# D631束线机]), 2) AS [2# D631束线机], ROUND(SUM([1# D631束线机]), 2) AS [1# D631束线机], ROUND(SUM([2# D801束线机]), 2) AS [2# D801束线机], ROUND(SUM([1# D801束线机]), 2) AS [1# D801束线机], ROUND(SUM([120挤塑]), 2) AS [120挤塑], ROUND(SUM([2# 70挤塑机（新改）]), 2) AS [2# 70挤塑机（新改）], ROUND(SUM([70+35挤塑机]), 2) AS [70+35挤塑机], ROUND(SUM([90挤塑机]), 2) AS [90挤塑机], ROUND(SUM([2# 单绞机（精铁）]), 2) AS [2# 单绞机（精铁）], ROUND(SUM([1000旋臂单绞机]), 2) AS [1000旋臂单绞机], ROUND(SUM([2500盘绞成缆机]), 2) AS [2500盘绞成缆机], ROUND(SUM([1000摇篮式成缆机]), 2) AS [1000摇篮式成缆机], ROUND(SUM([800摇篮式成缆机]), 2) AS [800摇篮式成缆机], ROUND(SUM([630摇篮式成缆机]), 2) AS [630摇篮式成缆机], ROUND(SUM([2# 630/1+6弓绞机]), 2) AS [2# 630/1+6弓绞机], ROUND(SUM([1# 630/1+3弓绞机]), 2) AS [1# 630/1+3弓绞机], ROUND(SUM([1+1对绞机]), 2) AS [1+1对绞机], ROUND(SUM([1+1弓绞机]), 2) AS [1+1弓绞机], ROUND(SUM([36锭高速编织机]), 2) AS [36锭高速编织机], ROUND(SUM([32锭高速编织机]), 2) AS [32锭高速编织机] FROM dbo.datBytime ";
        sql += " where SQLtime >= '"+star+"' and SQLtime <= '"+end+"'";
        sql += " GROUP BY SUBSTRING(SQLtime, 1, "+type+")  ORDER BY SUBSTRING(SQLtime, 1, "+type+") DESC";
        DataTable dt = DbHelperSQL.ExcuteDataTable(sql, connScadaStr);

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
            // count = dtCount.Rows.Count,
            data = dt
        };
        return JsonConvert.SerializeObject(json);
    }


    private string GetReport(String star,String end,String type)
    {
        string sql = "";

        sql += "SELECT SUBSTRING(dat,0," + type + ") AS dats, ROUND(SUM(val),2) AS val  FROM energyByTime ";
        sql += " where dat >= '"+star+"' and dat <= '"+end+"'";
        sql += "GROUP BY SUBSTRING(dat,0,"+type+") ORDER BY dats";

        DataTable dt = DbHelperSQL.ExcuteDataTable(sql, connScadaStr);

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
            // count = dtCount.Rows.Count,
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
        string sql = "SELECT * FROM [jinbeimes].[dbo].[Energy] order by Id";
        DataTable dtCount = DbHelperSQL.ExcuteDataTable(sql, connStr); //用于计总数                   

        sql = "SELECT * from (SELECT *, ROW_NUMBER() OVER(ORDER BY Id ASC) AS Num FROM Energy)AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex;

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

    private string GetDailyEnergyTable2Json()
    {
        //string sql = "SELECT * FROM [jinbeimes].[dbo].[DailyPower] WHERE shebeibianhao<>'SUM_DB' ORDER BY SQLtime desc";
        string sql = "SELECT * FROM [JINBEI_SCADA].[dbo].[dayreport_dianbiao_shuju_shebeibianhao] WHERE shebeibianhao<>'SUM_DB' ORDER BY SQLtime desc";
        DataTable dtCount = DbHelperSQL.ExcuteDataTable(sql, connScadaStr); //用于计总数                   

        //sql = "SELECT * from (SELECT *, ROW_NUMBER() OVER(ORDER BY SQLtime desc) AS Num FROM DailyPower WHERE shebeibianhao<>'SUM_DB')AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex;
        sql = "SELECT * from (SELECT *, ROW_NUMBER() OVER(ORDER BY SQLtime desc) AS Num FROM [JINBEI_SCADA].[dbo].[dayreport_dianbiao_shuju_shebeibianhao] WHERE shebeibianhao<>'SUM_DB')AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex;

        DataTable dt = DbHelperSQL.ExcuteDataTable(sql, connScadaStr);

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