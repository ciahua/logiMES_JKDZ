<%@ WebHandler Language="C#" Class="Handler_planreport" %>

using Newtonsoft.Json;
using System;
using System.Configuration;
using System.Data;
using System.Text.RegularExpressions;
using System.Web;
using System.Linq.Expressions;

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
        public string buydate { get; set; }
        public string devdept { get; set; }
        public string mon1 { get; set; }
        public string mon2 { get; set; }
        public string mon3 { get; set; }
        public string mon4 { get; set; }
        public string mon5 { get; set; }
        public string mon6 { get; set; }
        public string mon7 { get; set; }
        public string mon8 { get; set; }
        public string mon9 { get; set; }
        public string mon10 { get; set; }
        public string mon11 { get; set; }
        public string mon12 { get; set; }
        public string year { get; set; }
        public string desc { get; set; }
        public string sender { get; set; }
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
        string devYearMonth = context.Request["yearmonth"];
        string devYearData = context.Request["yeardata"];
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
            case "getTable":
                resJson = GetTable2Json();
                break;
            case "insTable": //申报故障
                DevInfo devYearInfo = JsonConvert.DeserializeObject<DevInfo>(devYearData);
                string sendTime = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                string sqlYearMaintain = string.Format("insert into YearMaintain (DeviceId, DeviceName, DeviceType, BuyDate, Unit, Mon1,Mon2,Mon3,Mon4,Mon5,Mon6,Mon7,Mon8,Mon9,Mon10,Mon11,Mon12,Year,Sender,SendTime) values ('{0}','{1}','{2}','{3}','{4}','{5}','{6}','{7}','{8}','{9}','{10}','{11}','{12}','{13}','{14}','{15}', '{16}','{17}','{18}','{19}')", devYearInfo.devno, devYearInfo.devname, devYearInfo.devtype, devYearInfo.buydate, devYearInfo.devdept, devYearInfo.mon1, devYearInfo.mon2, devYearInfo.mon3, devYearInfo.mon4, devYearInfo.mon5, devYearInfo.mon6, devYearInfo.mon7, devYearInfo.mon8, devYearInfo.mon9, devYearInfo.mon10, devYearInfo.mon11, devYearInfo.mon12, devYearInfo.year, devYearInfo.sender, sendTime);
                bool sqlYearResult = DbHelperSQL.Execute(sqlYearMaintain, connStr);
                if (sqlYearResult)
                {
                    resJson = "success";
                }
                else
                {
                    resJson = "failure";
                }
                break;
            case "getFailCount":
                resJson = GetFailCountJson(devYearMonth);
                break;
            case "getDailyReport":
                resJson = GetDailyReport2Json(devYearMonth);
                break;
            case "getPerformTable":
                resJson = GetPerformTable(devYearMonth);
                break;
        }

        context.Response.Write(resJson);
    }

    /// <summary>
    /// 获取维修人员列表
    /// </summary>
    /// <returns></returns>
    private string GetFailCountJson(string ym)
    {
        string startTm = Convert.ToDateTime(ym).ToString(), endTm = Convert.ToDateTime(ym).AddMonths(1).ToString();
        string sqlFailDevice = "select DevNo, DevName, IssueDesc, ReportTime, ConfirmTime from DeviceState where (CAST(ReportTime AS DATETIME)>='" + startTm + "' AND CAST(ReportTime AS DATETIME)<='" + endTm + "') AND (CAST(ConfirmTime AS DATETIME)<='" + endTm + "' OR ConfirmTime IS NULL)";
        DataTable dt = DbHelperSQL.ExcuteDataTable(sqlFailDevice, connStr);

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

    private string GetPerformTable(string ym)
    {
        ////获取所有设备列表
        //string sqlDevList = "select Id, DevNo, DevName, DevType, DevDept from DeviceList";
        //DataTable dtDevList = DbHelperSQL.ExcuteDataTable(sqlDevList, connStr);
        //dtDevList.Columns.Add("FailDays", Type.GetType("System.String"));//故障天数
        //dtDevList.Columns.Add("WorkHours", Type.GetType("System.String"));//运转工时
        //dtDevList.Columns.Add("FailHours", Type.GetType("System.String"));//故障时间
        //dtDevList.Columns.Add("RegularHours", Type.GetType("System.String"));//额定工时
        //dtDevList.Columns.Add("FailRate", Type.GetType("System.String"));//故障率
        //dtDevList.Columns.Add("GoodRate", Type.GetType("System.String"));//完好率
        //dtDevList.Columns.Add("WorkRate", Type.GetType("System.String"));//运转率        

        ////获取当月的故障列表
        //string startTm = Convert.ToDateTime(ym).ToString("yyyy-MM-dd HH:mm:ss"), endTm = Convert.ToDateTime(ym).AddMonths(1).ToString("yyyy-MM-dd HH:mm:ss");
        //string sqlFail = "select DevNo, ReportTime, ConfirmTime from DeviceState where (CAST(ReportTime AS DATETIME)>='" + startTm + "' AND CAST(ReportTime AS DATETIME)<='" + endTm + "') OR (CAST(ConfirmTime AS DATETIME)>='"+startTm+"' AND CAST(ConfirmTime AS DATETIME)<='" + endTm + "') OR (CAST(ReportTime AS DATETIME)<'"+endTm+"' AND ConfirmTime IS NULL)";

        //DataTable dtDevFail = DbHelperSQL.ExcuteDataTable(sqlFail, connStr);
        //DateTime dtStartTime = Convert.ToDateTime(startTm);//本月开始时间
        //DateTime dtEndTime = Convert.ToDateTime(endTm);//本月的结束时间
        //double monthDays = (dtEndTime - dtStartTime).TotalDays;//本月总天数
        //for (int i=0; i<dtDevList.Rows.Count; i++)
        //{
        //    TimeSpan timeSpan = new TimeSpan();
        //    string devNo = dtDevList.Rows[i]["DevNo"].ToString();
        //    var failTimes = dtDevFail.Select("DevNo='" + devNo + "'"); //当月该设备发生的故障列表
        //    int ftimes = failTimes.Length;//当月该设备的故障次数

        //    foreach(DataRow dr in failTimes)
        //    {
        //        DateTime sd = Convert.ToDateTime(dr["ReportTime"]);//起始时间，报修时间
        //        DateTime ed = dr["ConfirmTime"] == DBNull.Value ? DateTime.MinValue:Convert.ToDateTime(dr["ConfirmTime"]);//结束时间，


        //        if(sd>=dtStartTime && sd<=dtEndTime && (ed>sd && ed <= dtEndTime))//起止时间在当月内
        //        {
        //            TimeSpan ts = ed - sd;
        //            timeSpan += ts;
        //        }else if(sd>=dtStartTime && sd<=dtEndTime && ed > dtEndTime)//起在当月，止不在当月
        //        {
        //            TimeSpan ts = dtEndTime - sd;
        //            timeSpan += ts;
        //        }else if(ed>=dtStartTime && ed<=dtEndTime && sd > dtStartTime)//止在当月，起不在当月
        //        {
        //            TimeSpan ts = ed - dtStartTime;
        //            timeSpan += ts;
        //        }else if(sd>=dtStartTime && sd<=dtEndTime && ed == DateTime.MinValue)//起在本月，但未结束
        //        {
        //            TimeSpan ts = dtEndTime - sd;
        //            timeSpan += ts;
        //        }else if(sd<dtStartTime && ed == DateTime.MinValue)//起在前月，且未结束
        //        {
        //            TimeSpan ts = dtEndTime - dtStartTime;//当月的时间
        //            timeSpan += ts;
        //        }
        //    }
        //    //获得了本月某设备的故障时间汇总     
        //    //int days = DateTime.DaysInMonth(2020, 3);//获得某个月的天数
        //    double monthFailDays = Math.Round(timeSpan.TotalDays, 2);
        //    dtDevList.Rows[i]["FailDays"] = monthFailDays;//当月故障天数
        //    dtDevList.Rows[i]["FailHours"] = Math.Round(timeSpan.TotalHours, 2);//当月故障时间，小时数
        //    dtDevList.Rows[i]["GoodRate"] = ((monthDays-monthFailDays)/monthDays).ToString("P");//完好率
        //}
        string month=Convert.ToDateTime(ym).ToString("yyyy-MM");//格式转换
        DateTime dtNow = Convert.ToDateTime(month);
        int days = DateTime.DaysInMonth(dtNow.Year, dtNow.Month);
        int regHours = 24 * days;
        string sqlDevList = $"SELECT a.DevNo, a.DevName, convert(varchar(100), case when b.TotalWorkTime is null then 0 else b.TotalWorkTime end)  as WorkHours, convert(varchar(100), case when c.TotalFaultTime is null then 0 else c.TotalFaultTime end) as FailHours, convert(varchar(100),case WHEN d.FaultCount is null then 0 else d.FaultCount end) as FaultCount,'{month}' AS Month, CONVERT(DECIMAL(18,2),(CASE WHEN c.TotalFaultTime IS NULL THEN 0 ELSE c.TotalFaultTime END)/24) AS FailDays,CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2 ), (31-(CASE WHEN c.TotalFaultTime IS NULL THEN 0 ELSE c.TotalFaultTime END)/24)/31)*100)+'%' AS GoodRate, {regHours} as RegularHours FROM dbo.DeviceList a  LEFT JOIN (SELECT DeviceId, DeviceName, CONVERT(DECIMAL(18,2), SUM(WorkTime)) AS TotalWorkTime, SUBSTRING(date,1,7) AS Month FROM OPENDATASOURCE('SQLOLEDB','Data Source=GCD-20200509BFW;User ID=admin;Password=admin').[JINBEI_SCADA].[dbo].[worktime] WHERE SUBSTRING(date,1,7)='{month}' GROUP BY DeviceId, DeviceName, SUBSTRING(date,1,7)) b  ON a.DevNo=b.DeviceId  LEFT JOIN (SELECT DeviceId, CONVERT(DECIMAL(18,2), SUM(WorkTime)) AS TotalFaultTime FROM OPENDATASOURCE('SQLOLEDB','Data Source=GCD-20200509BFW;User ID=admin;Password=admin').[JINBEI_SCADA].[dbo].[downtime] WHERE SUBSTRING(date,1,7)='{month}' GROUP BY DeviceId, DeviceName) c  ON a.DevNo=c.DeviceId  LEFT JOIN downreport d ON a.DevNo=d.DevNo AND d.date='{month}'  ORDER BY a.DevNo  ";
        DataTable dtDevList = DbHelperSQL.ExcuteDataTable(sqlDevList, connStr);
        //dtDevList.Columns.Add("FailDays", Type.GetType("System.String"));//故障天数
        //dtDevList.Columns.Add("WorkHours", Type.GetType("System.String"));//运转工时
        //dtDevList.Columns.Add("FailHours", Type.GetType("System.String"));//故障时间
        //dtDevList.Columns.Add("RegularHours", Type.GetType("System.String"));//额定工时
        dtDevList.Columns.Add("FailRate", Type.GetType("System.String"));//故障率
        //dtDevList.Columns.Add("GoodRate", Type.GetType("System.String"));//完好率
        dtDevList.Columns.Add("WorkRate", Type.GetType("System.String"));//运转率     

        for (int i = 0; i < dtDevList.Rows.Count; i++)
        {
            for (int j = 0; j < dtDevList.Columns.Count; j++)
            {
                string temp = dtDevList.Rows[i][j].ToString().Trim();
                dtDevList.Rows[i][j] = temp;
            }
        }

        //新建json对象，序列化为json字符串
        var json = new
        {
            code = 0,
            msg = "",
            count = dtDevList.Rows.Count,
            data = dtDevList
        };
        return JsonConvert.SerializeObject(json);
    }

    /// <summary>
    /// 获取设备完好日报表
    /// </summary>
    /// <returns></returns>
    private string GetDailyReport2Json(string ym)
    {
        //获取所有设备列表
        string sqlDevList = "select Id, DevNo, DevName, DevDept from DeviceList";
        DataTable dtDevList = DbHelperSQL.ExcuteDataTable(sqlDevList, connStr);
        for (int i = 1; i <= 31; i++)
        {
            dtDevList.Columns.Add("Day" + i, Type.GetType("System.String"));
            dtDevList.Columns.Add("Detial" + i, Type.GetType("System.String"));
        }
        dtDevList.Columns.Add("FailTime", Type.GetType("System.String"));
        dtDevList.Columns.Add("WorkTime", Type.GetType("System.String"));
        dtDevList.Columns.Add("RegularTime", Type.GetType("System.String"));
        dtDevList.Columns.Add("FaultRate", Type.GetType("System.String"));
        dtDevList.Columns.Add("Availability", Type.GetType("System.String"));
        dtDevList.Columns.Add("UseRatio", Type.GetType("System.String"));

        int colOffset = 4; //每日记录的偏移量

        foreach (DataRow dr in dtDevList.Rows)
        {
            for (int i = 0; i < 31; i++)
            {
                dr[i * 2 + colOffset] = "正常";
            }
        }

        //获取某个时间段的故障设备

        //string startTm = Convert.ToDateTime(ym).ToString().Replace('/', '-'), endTm = Convert.ToDateTime(ym).AddMonths(1).ToString().Replace('/', '-');
        string startTm = Convert.ToDateTime(ym).ToString(), endTm = Convert.ToDateTime(ym).AddMonths(1).ToString();
        string sqlFailDevice = "select DevNo, DevName, IssueDesc, ReportTime, ConfirmTime from DeviceState where (CAST(ReportTime AS DATETIME)>='" + startTm + "' AND CAST(ReportTime AS DATETIME)<='" + endTm + "') AND (CAST(ConfirmTime AS DATETIME)<='" + endTm + "' OR ConfirmTime IS NULL)";
        //string sqlFailDevice = "select DevNo, DevName, IssueDesc, ReportTime, ConfirmTime from DeviceState";
        DataTable dtFailDevice = DbHelperSQL.ExcuteDataTable(sqlFailDevice, connStr);
        foreach (DataRow dr in dtFailDevice.Rows)
        {
            object ojb1 = dr["DevNo"];
            object obj2 = dr["ReportTime"];
            object objCfDate = dr["ConfirmTime"];

            if (dr["DevNo"] != null && dr["ReportTime"] != null)
            {
                string devNo = dr["DevNo"].ToString().Trim(); //设备号
                string rpDate = dr["ReportTime"].ToString().Trim(); //上报时间
                string cfDate = dr["ConfirmTime"].ToString().Trim(); //确认时间

                if (objCfDate != null && !string.IsNullOrEmpty(objCfDate.ToString().Trim()))
                {
                    //本月内完成确认
                    //DateTime cfd = Convert.ToDateTime("2020-4-13 18:0:0").Date;//确认日期
                    DateTime cfd = Convert.ToDateTime(cfDate).Date;//确认日期
                    DateTime rpd = Convert.ToDateTime(rpDate).Date;
                    if (cfd == rpd)
                    {
                        //同一天
                        double hoursDiff = Math.Round((Convert.ToDateTime(cfDate) - Convert.ToDateTime(rpDate)).TotalHours, 2); //当天的故障工时
                        if (!string.IsNullOrEmpty(devNo) && !string.IsNullOrEmpty(rpDate))
                        {
                            int rpDay = Convert.ToDateTime(rpDate).Day; //获取上报时间，转换为第几日
                            string detail = dr["IssueDesc"].ToString().Trim(); //问题描述
                            foreach (DataRow drow in dtDevList.Rows)
                            {
                                if (drow["DevNo"].ToString().Trim() == devNo)
                                {
                                    //drow[(rpDay - 1)*2 + colOffset] = hoursDiff; //上报当天故障时间
                                    //drow[(rpDay - 1)*2 + colOffset + 1] = detail; //上报当天故障描述   
                                    if (drow[(rpDay - 1) * 2 + colOffset].ToString().Trim() != "正常")
                                    {
                                        drow[(rpDay - 1) * 2 + colOffset] = Convert.ToDouble(drow[(rpDay - 1) * 2 + colOffset]) + hoursDiff; //上报当天故障时间
                                        drow[(rpDay - 1) * 2 + colOffset + 1] += detail + Environment.NewLine; //上报当天故障描述
                                    }
                                    else
                                    {
                                        drow[(rpDay - 1) * 2 + colOffset] = hoursDiff; //上报当天故障时间
                                        drow[(rpDay - 1) * 2 + colOffset + 1] = detail; //上报当天故障描述
                                    }
                                    int s1 = 0;
                                }
                            }
                        }

                    }
                    else
                    {
                        //不同一天
                        //计算第一天故障时间，确认日故障时间，中间故障时间每天24小时
                        DateTime _date = rpd.AddDays(1);
                        double rpHoursDiff = Math.Round((_date - Convert.ToDateTime(rpDate)).TotalHours, 2); //当天的故障工时
                        double cfHoursDiff = Math.Round((Convert.ToDateTime(cfDate) - cfd).TotalHours, 2); //确认日的故障工时
                        double daysDiff = (cfd - rpd).TotalDays - 1; //中间相差的天数

                        if (!string.IsNullOrEmpty(devNo) && !string.IsNullOrEmpty(rpDate))
                        {
                            int rpDay = Convert.ToDateTime(rpDate).Day; //获取上报时间，转换为第几日
                            int cfDay = Convert.ToDateTime(cfDate).Day; //获取确认时间，转换为第几日
                            string detail = dr["IssueDesc"].ToString().Trim(); //问题描述
                            foreach (DataRow drow in dtDevList.Rows)
                            {
                                if (drow["DevNo"].ToString().Trim() == devNo)
                                {
                                    if (drow[(rpDay - 1) * 2 + colOffset].ToString().Trim() != "正常")
                                    {
                                        drow[(rpDay - 1) * 2 + colOffset] = Convert.ToDouble(drow[(rpDay - 1) * 2 + colOffset]) + rpHoursDiff; //上报当天故障时间
                                        drow[(rpDay - 1) * 2 + colOffset + 1] += detail + Environment.NewLine; //上报当天故障描述
                                    }
                                    else
                                    {
                                        drow[(rpDay - 1) * 2 + colOffset] = rpHoursDiff; //上报当天故障时间
                                        drow[(rpDay - 1) * 2 + colOffset + 1] = detail; //上报当天故障描述
                                    }
                                    if (drow[(cfDay - 1) * 2 + colOffset].ToString().Trim() != "正常")
                                    {
                                        drow[(cfDay - 1) * 2 + colOffset] = Convert.ToDouble(drow[(cfDay - 1) * 2 + colOffset]) + cfHoursDiff; //确认当天故障时间
                                        drow[(cfDay - 1) * 2 + colOffset + 1] += detail + Environment.NewLine; //确认当天故障描述
                                    }
                                    else
                                    {
                                        drow[(cfDay - 1) * 2 + colOffset] = cfHoursDiff; //确认当天故障时间
                                        drow[(cfDay - 1) * 2 + colOffset + 1] = detail; //确认当天故障描述
                                    }

                                    //中间故障时间
                                    for (int i = 0; i < daysDiff; i++)
                                    {
                                        drow[rpDay * 2 + colOffset + i * 2] = 24;
                                    }
                                    string s = "";
                                }
                            }
                        }

                    }
                }
                else
                {
                    //本月内未完成
                    string mon = "4";
                    objCfDate = Convert.ToDateTime("2020-" + mon + "-30 23:59:59"); //本月最后一天
                                                                                    //计算故障申报日的时间，当月有多少天，其余每天记为24小时
                    DateTime rpd = Convert.ToDateTime(rpDate).Date;
                    int rpDay = Convert.ToDateTime(rpDate).Day; //获取上报时间，转换为第几日
                    string detail = dr["IssueDesc"].ToString().Trim(); //问题描述
                    DateTime _date = rpd.AddDays(1);
                    double rpHoursDiff = Math.Round((_date - Convert.ToDateTime(rpDate)).TotalHours, 2); //当天的故障工时
                    foreach (DataRow drow in dtDevList.Rows)
                    {
                        if (drow["DevNo"].ToString().Trim() == devNo)
                        {
                            if (drow[(rpDay - 1) * 2 + colOffset].ToString().Trim() != "正常")
                            {
                                drow[(rpDay - 1) * 2 + colOffset] = Convert.ToDouble(drow[(rpDay - 1) * 2 + colOffset]) + rpHoursDiff; //上报当天故障时间
                                drow[(rpDay - 1) * 2 + colOffset + 1] += detail + Environment.NewLine; //上报当天故障描述
                            }
                            else
                            {
                                drow[(rpDay - 1) * 2 + colOffset] = rpHoursDiff; //上报当天故障时间
                                drow[(rpDay - 1) * 2 + colOffset + 1] = detail; //上报当天故障描述
                            }

                            //中间故障时间
                            int days = DateTime.DaysInMonth(2020, 4);
                            for (int i = 0; i < (days - rpDay); i++)
                            {
                                drow[rpDay * 2 + colOffset + i * 2] = 24;
                            }

                            //统计总的故障时间
                            string s = "";
                        }
                    }
                }
            }
        }

        //统计一行的故障时间        
        foreach (DataRow dr in dtDevList.Rows)
        {
            double failTime = 0, ft;
            for (int i = 0; i < 31; i++)
            {
                string cell = dr[i * 2 + colOffset].ToString();
                if (isNumberic(cell, out ft))
                {
                    failTime += Convert.ToDouble(cell);
                }
            }
            dr["FailTime"] = failTime;
        }

        for (int i = 0; i < dtDevList.Rows.Count; i++)
        {
            for (int j = 0; j < dtDevList.Columns.Count; j++)
            {
                string temp = dtDevList.Rows[i][j].ToString().Trim();
                dtDevList.Rows[i][j] = temp;
            }
        }

        //新建json对象，序列化为json字符串
        var json = new
        {
            code = 0,
            msg = "",
            count = dtDevList.Rows.Count,
            data = dtDevList
        };
        return JsonConvert.SerializeObject(json);
    }

    /// <summary>
    /// 获取当天的计划表格
    /// </summary>
    /// <returns></returns>
    private string GetTable2Json()
    {
        string sql = "SELECT * FROM [jinbeimes].[dbo].[YearMaintain] order by id";
        DataTable dtCount = DbHelperSQL.ExcuteDataTable(sql, connStr); //用于计总数                   

        sql = "SELECT * from (SELECT *, ROW_NUMBER() OVER(ORDER BY id ASC) AS Num FROM YearMaintain)AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex;

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


    /// <summary>
    /// 判断字符串是否为数
    /// </summary>
    /// <param name="message"></param>
    /// <param name="result"></param>
    /// <returns></returns>
    protected bool isNumberic(string message, out double result)
    {
        //判断是否为整数字符串
        //是的话则将其转换为数字并将其设为out类型的输出值、返回true, 否则为false
        result = -1;   //result 定义为out 用来输出值
        try
        {
            //当数字字符串的为是少于4时，以下三种都可以转换，任选一种
            //如果位数超过4的话，请选用Convert.ToInt32() 和int.Parse()

            //result = int.Parse(message);
            //result = Convert.ToInt16(message);
            result = Convert.ToDouble(message);
            return true;
        }
        catch
        {
            return false;
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