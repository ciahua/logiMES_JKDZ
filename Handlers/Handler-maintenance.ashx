<%@ WebHandler Language="C#" Class="Handler_planreport" %>

using Newtonsoft.Json;
using System;
using System.Configuration;
using System.Data;
using System.Text.RegularExpressions;
using System.Web;
using System.Linq.Expressions;
using Newtonsoft.Json.Linq;

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
                string sqlYearMaintain =string.Format("insert into YearMaintain (DeviceId, DeviceName, DeviceType, BuyDate, Unit, Mon1,Mon2,Mon3,Mon4,Mon5,Mon6,Mon7,Mon8,Mon9,Mon10,Mon11,Mon12,Year,Sender,SendTime) values ('{0}','{1}','{2}','{3}','{4}','{5}','{6}','{7}','{8}','{9}','{10}','{11}','{12}','{13}','{14}','{15}', '{16}','{17}','{18}','{19}')", devYearInfo.devno, devYearInfo.devname, devYearInfo.devtype, devYearInfo.buydate, devYearInfo.devdept, devYearInfo.mon1, devYearInfo.mon2, devYearInfo.mon3, devYearInfo.mon4,devYearInfo.mon5,devYearInfo.mon6,devYearInfo.mon7,devYearInfo.mon8,devYearInfo.mon9,devYearInfo.mon10,devYearInfo.mon11,devYearInfo.mon12, devYearInfo.year, devYearInfo.sender, sendTime);
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
            case "submit":
                resJson = SubmitDailyReport2Json(devYearMonth, repairmanName, devData);
                break;
            case "singleSubmit":
                resJson = SingleSubmitDailyReport2Json(devYearMonth, repairmanName, devData);
                break;
            case "getDailyReportView":
                resJson = GetDailyReportView(devYearMonth);
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

    /// <summary>
    /// 指派维修人员
    /// </summary>
    /// <returns></returns>
    private string GetDailyReport2Json(string ym)
    {
        string month=Convert.ToDateTime(ym).ToString("yyyy-MM");//格式转换
        string sqlDevList = $"SELECT a.DevNo, a.DevName, convert(varchar(100), case when b.TotalWorkTime is null then 0 else b.TotalWorkTime end)  as WorkTime, convert(varchar(100), case when c.TotalFaultTime is null then 0 else c.TotalFaultTime end) as FailTime, convert(varchar(100),case WHEN d.FaultCount is null then 0 else d.FaultCount end) as FaultCount,'{month}' AS Month ,d.Day1,d.Day2,d.Day3,d.Day4,d.Day5,d.Day6,d.Day7,d.Day8,d.Day9,d.Day10,d.Day11,d.Day12,d.Day13,d.Day14,d.Day15,d.Day16,d.Day17,d.Day18,d.Day19,d.Day20,d.Day21,d.Day22,d.Day23,d.Day24,d.Day25,d.Day26,d.Day27,d.Day28,d.Day29,d.Day30,d.Day31,d.Detail1,d.Detail2,d.Detail3,d.Detail4,d.Detail5,d.Detail6,d.Detail7,d.Detail8,d.Detail9,d.Detail10,d.Detail11,d.Detail12,d.Detail13,d.Detail14,d.Detail15,d.Detail16,d.Detail17,d.Detail18,d.Detail19,d.Detail20,d.Detail21,d.Detail22,d.Detail23,d.Detail24,d.Detail25,d.Detail26,d.Detail27,d.Detail28,d.Detail29,d.Detail30,d.Detail31 FROM dbo.DeviceList a  LEFT JOIN (SELECT DeviceId, DeviceName, CONVERT(DECIMAL(18,2), SUM(WorkTime)) AS TotalWorkTime, SUBSTRING(date,1,7) AS Month FROM OPENDATASOURCE('SQLOLEDB','Data Source=GCD-20200509BFW;User ID=admin;Password=admin').[JINBEI_SCADA].[dbo].[worktime] WHERE SUBSTRING(date,1,7)='{month}' GROUP BY DeviceId, DeviceName, SUBSTRING(date,1,7)) b  ON a.DevNo=b.DeviceId  LEFT JOIN (SELECT DeviceId, CONVERT(DECIMAL(18,2), SUM(WorkTime)) AS TotalFaultTime FROM OPENDATASOURCE('SQLOLEDB','Data Source=GCD-20200509BFW;User ID=admin;Password=admin').[JINBEI_SCADA].[dbo].[downtime] WHERE SUBSTRING(date,1,7)='{month}' GROUP BY DeviceId, DeviceName) c  ON a.DevNo=c.DeviceId  LEFT JOIN downreport d ON a.DevNo=d.DevNo AND d.date='{month}'  ORDER BY a.DevNo ";

        DataTable dtDevList = DbHelperSQL.ExcuteDataTable(sqlDevList, connStr);
        dtDevList.Columns.Add("RegularTime", Type.GetType("System.String")); //制度工时
        dtDevList.Columns.Add("FaultRate", Type.GetType("System.String")); //故障率
        dtDevList.Columns.Add("Availability", Type.GetType("System.String")); //可利用率
        dtDevList.Columns.Add("UseRatio", Type.GetType("System.String")); //利用率

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

        #region old codes
        ////获取所有设备列表
        //string sqlDevList = "select Id, DevNo, DevName, DevDept from DeviceList";
        //DataTable dtDevList = DbHelperSQL.ExcuteDataTable(sqlDevList, connStr);
        //for (int i = 1; i <= 31; i++)
        //{
        //    dtDevList.Columns.Add("Day"+i, Type.GetType("System.String"));
        //    dtDevList.Columns.Add("Detail"+i, Type.GetType("System.String"));
        //}
        //dtDevList.Columns.Add("FailTime", Type.GetType("System.String")); //故障时间
        //dtDevList.Columns.Add("WorkTime", Type.GetType("System.String")); //设备工时
        //dtDevList.Columns.Add("RegularTime", Type.GetType("System.String")); //制度工时
        //dtDevList.Columns.Add("FaultRate", Type.GetType("System.String")); //故障率
        //dtDevList.Columns.Add("Availability", Type.GetType("System.String")); //可利用率
        //dtDevList.Columns.Add("UseRatio", Type.GetType("System.String")); //利用率

        //int colOffset = 4; //每日记录的偏移量

        //foreach(DataRow dr in dtDevList.Rows)
        //{
        //    for(int i=0; i<31; i++)
        //    {
        //        dr[i*2 + colOffset] = "正常";
        //    }
        //}

        ////获取某个时间段的故障设备

        //string startTm = Convert.ToDateTime(ym).ToString(), endTm = Convert.ToDateTime(ym).AddMonths(1).ToString();
        //string sqlFailDevice = "select DevNo, DevName, IssueDesc, ReportTime, ConfirmTime from DeviceState where (CAST(ReportTime AS DATETIME)>='" + startTm + "' AND CAST(ReportTime AS DATETIME)<='" + endTm + "') AND (CAST(ConfirmTime AS DATETIME)<='" + endTm + "' OR ConfirmTime IS NULL)";
        ////string sqlFailDevice = "select DevNo, DevName, IssueDesc, ReportTime, ConfirmTime from DeviceState";
        //DataTable dtFailDevice = DbHelperSQL.ExcuteDataTable(sqlFailDevice, connStr);
        //foreach (DataRow dr in dtFailDevice.Rows)
        //{
        //    object ojb1 = dr["DevNo"];
        //    object obj2 = dr["ReportTime"];
        //    object objCfDate = dr["ConfirmTime"];

        //    if (dr["DevNo"] != null && dr["ReportTime"] != null)
        //    {
        //        string devNo = dr["DevNo"].ToString().Trim(); //设备号
        //        string rpDate = dr["ReportTime"].ToString().Trim(); //上报时间
        //        string cfDate = dr["ConfirmTime"].ToString().Trim(); //确认时间

        //        if(objCfDate != null && !string.IsNullOrEmpty(objCfDate.ToString().Trim()))
        //        {
        //            //本月内完成确认
        //            //DateTime cfd = Convert.ToDateTime("2020-4-13 18:0:0").Date;//确认日期
        //            DateTime cfd = Convert.ToDateTime(cfDate).Date;//确认日期
        //            DateTime rpd = Convert.ToDateTime(rpDate).Date;
        //            if(cfd == rpd)
        //            {
        //                //同一天
        //                double hoursDiff =Math.Round((Convert.ToDateTime(cfDate) - Convert.ToDateTime(rpDate)).TotalHours, 2); //当天的故障工时
        //                if (!string.IsNullOrEmpty(devNo) && !string.IsNullOrEmpty(rpDate))
        //                {
        //                    int rpDay = Convert.ToDateTime(rpDate).Day; //获取上报时间，转换为第几日
        //                    string detail = dr["IssueDesc"].ToString().Trim(); //问题描述
        //                    foreach (DataRow drow in dtDevList.Rows)
        //                    {
        //                        if (drow["DevNo"].ToString().Trim() == devNo)
        //                        {
        //                            //drow[(rpDay - 1)*2 + colOffset] = hoursDiff; //上报当天故障时间
        //                            //drow[(rpDay - 1)*2 + colOffset + 1] = detail; //上报当天故障描述   
        //                            if (drow[(rpDay - 1) * 2 + colOffset].ToString().Trim() != "正常")
        //                            {
        //                                drow[(rpDay - 1) * 2 + colOffset] = Convert.ToDouble(drow[(rpDay - 1) * 2 + colOffset]) + hoursDiff; //上报当天故障时间
        //                                drow[(rpDay - 1) * 2 + colOffset + 1] += detail + Environment.NewLine; //上报当天故障描述
        //                            }
        //                            else
        //                            {
        //                                drow[(rpDay - 1) * 2 + colOffset] = hoursDiff; //上报当天故障时间
        //                                drow[(rpDay - 1) * 2 + colOffset + 1] = detail; //上报当天故障描述
        //                            }
        //                            int s1 = 0;
        //                        }
        //                    }
        //                }

        //            }
        //            else
        //            {
        //                //不同一天
        //                //计算第一天故障时间，确认日故障时间，中间故障时间每天24小时
        //                DateTime _date = rpd.AddDays(1);
        //                double rpHoursDiff =Math.Round((_date - Convert.ToDateTime(rpDate)).TotalHours, 2); //当天的故障工时
        //                double cfHoursDiff = Math.Round((Convert.ToDateTime(cfDate)-cfd).TotalHours, 2); //确认日的故障工时
        //                double daysDiff = (cfd - rpd).TotalDays - 1; //中间相差的天数

        //                if (!string.IsNullOrEmpty(devNo) && !string.IsNullOrEmpty(rpDate))
        //                {
        //                    int rpDay = Convert.ToDateTime(rpDate).Day; //获取上报时间，转换为第几日
        //                    int cfDay = Convert.ToDateTime(cfDate).Day; //获取确认时间，转换为第几日
        //                    string detail = dr["IssueDesc"].ToString().Trim(); //问题描述
        //                    foreach (DataRow drow in dtDevList.Rows)
        //                    {
        //                        if (drow["DevNo"].ToString().Trim() == devNo)
        //                        {
        //                            if (drow[(rpDay - 1) * 2 + colOffset].ToString().Trim() != "正常")
        //                            {
        //                                drow[(rpDay - 1) * 2 + colOffset] = Convert.ToDouble(drow[(rpDay - 1) * 2 + colOffset]) + rpHoursDiff; //上报当天故障时间
        //                                drow[(rpDay - 1) * 2 + colOffset + 1] += detail + Environment.NewLine; //上报当天故障描述
        //                            }
        //                            else
        //                            {
        //                                drow[(rpDay - 1) * 2 + colOffset] = rpHoursDiff; //上报当天故障时间
        //                                drow[(rpDay - 1) * 2 + colOffset + 1] = detail; //上报当天故障描述
        //                            }
        //                            if (drow[(cfDay - 1) * 2 + colOffset].ToString().Trim() != "正常")
        //                            {
        //                                drow[(cfDay - 1) * 2 + colOffset] = Convert.ToDouble(drow[(cfDay - 1) * 2 + colOffset]) + cfHoursDiff; //确认当天故障时间
        //                                drow[(cfDay - 1) * 2 + colOffset + 1] += detail + Environment.NewLine; //确认当天故障描述
        //                            }
        //                            else
        //                            {
        //                                drow[(cfDay - 1) * 2 + colOffset] = cfHoursDiff; //确认当天故障时间
        //                                drow[(cfDay - 1) * 2 + colOffset + 1] = detail; //确认当天故障描述
        //                            }

        //                            //中间故障时间
        //                            for (int i = 0; i < daysDiff; i++)
        //                            {
        //                                drow[rpDay * 2 + colOffset + i * 2] = 24;
        //                            }
        //                            string s = "";
        //                        }
        //                    }
        //                }

        //            }
        //        }
        //        else
        //        {
        //            //本月内未完成
        //            string mon = "4";
        //            objCfDate = Convert.ToDateTime("2020-" + mon + "-30 23:59:59"); //本月最后一天
        //            //计算故障申报日的时间，当月有多少天，其余每天记为24小时
        //            DateTime rpd = Convert.ToDateTime(rpDate).Date;
        //            int rpDay = Convert.ToDateTime(rpDate).Day; //获取上报时间，转换为第几日
        //            string detail = dr["IssueDesc"].ToString().Trim(); //问题描述
        //            DateTime _date = rpd.AddDays(1);
        //            double rpHoursDiff = Math.Round((_date - Convert.ToDateTime(rpDate)).TotalHours, 2); //当天的故障工时
        //            foreach (DataRow drow in dtDevList.Rows)
        //            {
        //                if (drow["DevNo"].ToString().Trim() == devNo)
        //                {
        //                    if (drow[(rpDay - 1) * 2 + colOffset].ToString().Trim() != "正常")
        //                    {
        //                        drow[(rpDay - 1) * 2 + colOffset] = Convert.ToDouble(drow[(rpDay - 1) * 2 + colOffset]) + rpHoursDiff; //上报当天故障时间
        //                        drow[(rpDay - 1) * 2 + colOffset + 1] += detail + Environment.NewLine; //上报当天故障描述
        //                    }
        //                    else
        //                    {
        //                        drow[(rpDay - 1) * 2 + colOffset] = rpHoursDiff; //上报当天故障时间
        //                        drow[(rpDay - 1) * 2 + colOffset + 1] = detail; //上报当天故障描述
        //                    }

        //                    //中间故障时间
        //                    int days = DateTime.DaysInMonth(2020, 4);
        //                    for (int i = 0; i < (days - rpDay); i++)
        //                    {
        //                        drow[rpDay * 2 + colOffset + i * 2] = 24;
        //                    }

        //                    //统计总的故障时间
        //                    string s = "";
        //                }
        //            }
        //        }
        //    }
        //}

        ////统计一行的故障时间        
        //DateTime sDate = Convert.ToDateTime(ym);//当月起始日期
        //DateTime eDate = Convert.ToDateTime(ym).AddMonths(1); //下个月的第一天
        //TimeSpan _daysInMonth = eDate - sDate;
        //double daysInMonth = _daysInMonth.TotalDays;//当月多少天

        //foreach(DataRow dr in dtDevList.Rows)
        //{
        //    //统计一行的故障时间
        //    double failTime = 0, ft;
        //    for(int i=0; i<daysInMonth; i++)
        //    {
        //        string cell = dr[i * 2 + colOffset].ToString();
        //        if(isNumberic(cell, out ft))
        //        {
        //            failTime += Convert.ToDouble(cell);
        //        }
        //    }
        //    dr["FailTime"] = failTime;

        //    //统计一行的设备工时
        //    double workTime = 0, wt;
        //    for(int i=0; i<daysInMonth; i++)
        //    {
        //        string currDate = sDate.AddDays(i).ToString("yyyy-MM-dd");//当前日期
        //        string sqlWorkTime = string.Format("select WorkTime from OPENDATASOURCE('SQLOLEDB','Data Source=GCD-20200509BFW;User ID=admin;Password=admin').[JINBEI_SCADA].[dbo].[worktime] where DeviceId = '{0}' and Date = '{1}'", dr["DevNo"].ToString().Trim(), currDate);

        //        string cell = (string)DbHelperSQL.ExecuteScalar(sqlWorkTime, connStr);
        //        if(isNumberic(cell, out wt))
        //        {
        //            workTime += Convert.ToDouble(cell);
        //        }
        //    }
        //    dr["WorkTime"] = workTime;
        //} 
        #endregion

        //for (int i = 0; i < dtDevList.Rows.Count; i++)
        //{
        //    for (int j = 0; j < dtDevList.Columns.Count; j++)
        //    {
        //        string temp = dtDevList.Rows[i][j].ToString().Trim();
        //        dtDevList.Rows[i][j] = temp;
        //    }
        //}

        ////新建json对象，序列化为json字符串
        //var json = new
        //{
        //    code = 0,
        //    msg = "",
        //    count = dtDevList.Rows.Count,
        //    data = dtDevList
        //};
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

    private string SubmitDailyReport2Json(string ym, string user, string dataStr)
    {
        JArray ja = (JArray)JsonConvert.DeserializeObject(dataStr);
        string sendTime = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
        ym = Convert.ToDateTime(ym).ToString("yyyy-MM");
        foreach (var jo in ja)
        {
            string sqlIns = $"if not exists (select 1 from DailyReport where Date='{ym}' and DevNo='{jo["DevNo"]}') " +
                $"insert into DailyReport values('{ym}', '{jo["DevNo"]}', '{jo["DevName"]}', '{jo["DevDept"]}', '{user}', '{sendTime}', '{jo["Day1"]}', '{jo["Detail1"]}', '{jo["Day2"]}', '{jo["Detail2"]}','{jo["Day3"]}', '{jo["Detail3"]}', '{jo["Day4"]}', '{jo["Detail4"]}','{jo["Day5"]}', '{jo["Detail5"]}', '{jo["Day6"]}', '{jo["Detail6"]}','{jo["Day7"]}', '{jo["Detail7"]}', '{jo["Day8"]}', '{jo["Detail8"]}', '{jo["Day9"]}', '{jo["Detail9"]}', '{jo["Day10"]}', '{jo["Detail10"]}','{jo["Day11"]}', '{jo["Detail11"]}', '{jo["Day12"]}', '{jo["Detail12"]}','{jo["Day13"]}', '{jo["Detail13"]}', '{jo["Day14"]}', '{jo["Detail14"]}','{jo["Day15"]}', '{jo["Detail15"]}', '{jo["Day16"]}', '{jo["Detail16"]}', '{jo["Day17"]}', '{jo["Detail17"]}', '{jo["Day18"]}', '{jo["Detail18"]}','{jo["Day19"]}', '{jo["Detail19"]}', '{jo["Day20"]}', '{jo["Detail20"]}','{jo["Day21"]}', '{jo["Detail21"]}', '{jo["Day22"]}', '{jo["Detail22"]}','{jo["Day23"]}', '{jo["Detail23"]}', '{jo["Day24"]}', '{jo["Detail24"]}', '{jo["Day25"]}', '{jo["Detail25"]}','{jo["Day26"]}', '{jo["Detail26"]}', '{jo["Day27"]}', '{jo["Detail27"]}','{jo["Day28"]}', '{jo["Detail28"]}', '{jo["Day29"]}', '{jo["Detail29"]}','{jo["Day30"]}', '{jo["Detail130"]}', '{jo["Day31"]}', '{jo["Detail31"]}', '{jo["FailTime"]}', '{jo["WorkTime"]}','{jo["RegularTime"]}','{jo["FaultRate"]}','{jo["Availability"]}','{jo["UseRatio"]}') " +
                $"else " +
                $"update DailyReport set DevName = '{jo["DevName"]}', DevDept = '{jo["DevDept"]}', Sender = '{user}', SendTime = '{sendTime}', Day1 = '{jo["Day1"]}', Detail1 = '{jo["Detail1"]}', Day2 = '{jo["Day2"]}', Detail2 = '{jo["Detail2"]}', Day3='{jo["Day3"]}', Detail3 = '{jo["Detail3"]}', Day4 = '{jo["Day4"]}', Detail4 = '{jo["Detail4"]}', Day5 = '{jo["Day5"]}', Detail5 = '{jo["Detail5"]}', Day6 = '{jo["Day6"]}', Detail6 = '{jo["Detail6"]}', Day7 = '{jo["Day7"]}', Detail7 = '{jo["Detail7"]}', Day8 = '{jo["Day8"]}',Detail8 = '{jo["Detail8"]}', Day9 = '{jo["Day9"]}', Detail9 = '{jo["Detail9"]}', Day10 = '{jo["Day10"]}', Detail10 = '{jo["Detail10"]}',Day11 = '{jo["Day11"]}', Detail11 = '{jo["Detail11"]}', Day12 = '{jo["Day12"]}', Detail12 = '{jo["Detail12"]}', Day13 = '{jo["Day13"]}', Detail13 = '{jo["Detail13"]}', Day14 = '{jo["Day14"]}', Detail14 = '{jo["Detail14"]}', Day15 = '{jo["Day15"]}', Detail15 = '{jo["Detail15"]}', Day16 = '{jo["Day16"]}', Detail16 = '{jo["Detail16"]}', Day17 = '{jo["Day17"]}', Detail17 = '{jo["Detail17"]}', Day18 = '{jo["Day18"]}', Detail18 = '{jo["Detail18"]}',Day19 = '{jo["Day19"]}', Detail19 = '{jo["Detail19"]}', Day20 = '{jo["Day20"]}', Detail20 = '{jo["Detail20"]}',Day21 = '{jo["Day21"]}', Detail21 = '{jo["Detail21"]}', Day22 = '{jo["Day22"]}', Detail22 = '{jo["Detail22"]}',Day23 = '{jo["Day23"]}', Detail23 = '{jo["Detail23"]}', Day24 = '{jo["Day24"]}', Detail24 = '{jo["Detail24"]}', Day25 = '{jo["Day25"]}', Detail25 = '{jo["Detail25"]}', Day26 = '{jo["Day26"]}',Detail26 = '{jo["Detail26"]}', Day27 = '{jo["Day27"]}', Detail27 = '{jo["Detail27"]}', Day28 = '{jo["Day28"]}', Detail28 = '{jo["Detail28"]}', Day29 = '{jo["Day29"]}', Detail29 = '{jo["Detail29"]}', Day30 = '{jo["Day30"]}', Detail30 = '{jo["Detail130"]}', Day31 = '{jo["Day31"]}', Detail31 = '{jo["Detail31"]}', FailTime = '{jo["FailTime"]}', WorkTime = '{jo["WorkTime"]}', RegularTime = '{jo["RegularTime"]}',FaultRate = '{jo["FaultRate"]}',Availability = '{jo["Availability"]}',UseRatio = '{jo["UseRatio"]}'  " +
                $"where Date='{ym}' and DevNo='{jo["DevNo"]}' ";
            DbHelperSQL.Execute(sqlIns, connStr);
        }
        string json = "success";
        return JsonConvert.SerializeObject(json);
    }

    //更新单行
    private string SingleSubmitDailyReport2Json(string ym, string user, string dataStr)
    {
        //JArray ja = (JArray)JsonConvert.DeserializeObject(dataStr);
        JObject jo = (JObject)JsonConvert.DeserializeObject(dataStr);
        string sendTime = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
        ym = Convert.ToDateTime(ym).ToString("yyyy-MM");
        var dept = jo["DevDept"];

        string sqlIns = $"if not exists (select 1 from DailyReport where Date='{ym}' and DevNo='{jo["DevNo"]}') " +
            $"insert into DailyReport values('{ym}', '{jo["DevNo"]}', '{jo["DevName"]}', '{jo["DevDept"]}', '{user}', '{sendTime}', '{jo["Day1"]}', '{jo["Detail1"]}', '{jo["Day2"]}', '{jo["Detail2"]}','{jo["Day3"]}', '{jo["Detail3"]}', '{jo["Day4"]}', '{jo["Detail4"]}','{jo["Day5"]}', '{jo["Detail5"]}', '{jo["Day6"]}', '{jo["Detail6"]}','{jo["Day7"]}', '{jo["Detail7"]}', '{jo["Day8"]}', '{jo["Detail8"]}', '{jo["Day9"]}', '{jo["Detail9"]}', '{jo["Day10"]}', '{jo["Detail10"]}','{jo["Day11"]}', '{jo["Detail11"]}', '{jo["Day12"]}', '{jo["Detail12"]}','{jo["Day13"]}', '{jo["Detail13"]}', '{jo["Day14"]}', '{jo["Detail14"]}','{jo["Day15"]}', '{jo["Detail15"]}', '{jo["Day16"]}', '{jo["Detail16"]}', '{jo["Day17"]}', '{jo["Detail17"]}', '{jo["Day18"]}', '{jo["Detail18"]}','{jo["Day19"]}', '{jo["Detail19"]}', '{jo["Day20"]}', '{jo["Detail20"]}','{jo["Day21"]}', '{jo["Detail21"]}', '{jo["Day22"]}', '{jo["Detail22"]}','{jo["Day23"]}', '{jo["Detail23"]}', '{jo["Day24"]}', '{jo["Detail24"]}', '{jo["Day25"]}', '{jo["Detail25"]}','{jo["Day26"]}', '{jo["Detail26"]}', '{jo["Day27"]}', '{jo["Detail27"]}','{jo["Day28"]}', '{jo["Detail28"]}', '{jo["Day29"]}', '{jo["Detail29"]}','{jo["Day30"]}', '{jo["Detail130"]}', '{jo["Day31"]}', '{jo["Detail31"]}', '{jo["FailTime"]}', '{jo["WorkTime"]}','{jo["RegularTime"]}','{jo["FaultRate"]}','{jo["Availability"]}','{jo["UseRatio"]}') " +
            $"else " +
            $"update DailyReport set DevName = '{jo["DevName"]}', DevDept = '{jo["DevDept"]}', Sender = '{user}', SendTime = '{sendTime}', Day1 = '{jo["Day1"]}', Detail1 = '{jo["Detail1"]}', Day2 = '{jo["Day2"]}', Detail2 = '{jo["Detail2"]}', Day3='{jo["Day3"]}', Detail3 = '{jo["Detail3"]}', Day4 = '{jo["Day4"]}', Detail4 = '{jo["Detail4"]}', Day5 = '{jo["Day5"]}', Detail5 = '{jo["Detail5"]}', Day6 = '{jo["Day6"]}', Detail6 = '{jo["Detail6"]}', Day7 = '{jo["Day7"]}', Detail7 = '{jo["Detail7"]}', Day8 = '{jo["Day8"]}',Detail8 = '{jo["Detail8"]}', Day9 = '{jo["Day9"]}', Detail9 = '{jo["Detail9"]}', Day10 = '{jo["Day10"]}', Detail10 = '{jo["Detail10"]}',Day11 = '{jo["Day11"]}', Detail11 = '{jo["Detail11"]}', Day12 = '{jo["Day12"]}', Detail12 = '{jo["Detail12"]}', Day13 = '{jo["Day13"]}', Detail13 = '{jo["Detail13"]}', Day14 = '{jo["Day14"]}', Detail14 = '{jo["Detail14"]}', Day15 = '{jo["Day15"]}', Detail15 = '{jo["Detail15"]}', Day16 = '{jo["Day16"]}', Detail16 = '{jo["Detail16"]}', Day17 = '{jo["Day17"]}', Detail17 = '{jo["Detail17"]}', Day18 = '{jo["Day18"]}', Detail18 = '{jo["Detail18"]}',Day19 = '{jo["Day19"]}', Detail19 = '{jo["Detail19"]}', Day20 = '{jo["Day20"]}', Detail20 = '{jo["Detail20"]}',Day21 = '{jo["Day21"]}', Detail21 = '{jo["Detail21"]}', Day22 = '{jo["Day22"]}', Detail22 = '{jo["Detail22"]}',Day23 = '{jo["Day23"]}', Detail23 = '{jo["Detail23"]}', Day24 = '{jo["Day24"]}', Detail24 = '{jo["Detail24"]}', Day25 = '{jo["Day25"]}', Detail25 = '{jo["Detail25"]}', Day26 = '{jo["Day26"]}',Detail26 = '{jo["Detail26"]}', Day27 = '{jo["Day27"]}', Detail27 = '{jo["Detail27"]}', Day28 = '{jo["Day28"]}', Detail28 = '{jo["Detail28"]}', Day29 = '{jo["Day29"]}', Detail29 = '{jo["Detail29"]}', Day30 = '{jo["Day30"]}', Detail30 = '{jo["Detail130"]}', Day31 = '{jo["Day31"]}', Detail31 = '{jo["Detail31"]}', FailTime = '{jo["FailTime"]}', WorkTime = '{jo["WorkTime"]}', RegularTime = '{jo["RegularTime"]}',FaultRate = '{jo["FaultRate"]}',Availability = '{jo["Availability"]}',UseRatio = '{jo["UseRatio"]}'  " +
            $"where Date='{ym}' and DevNo='{jo["DevNo"]}' ";
        DbHelperSQL.Execute(sqlIns, connStr);

        string json = "success";
        return JsonConvert.SerializeObject(json);
    }

    private string GetDailyReportView(string ym)
    {
        ym = Convert.ToDateTime(ym).ToString("yyyy-MM");
        string sql = $"SELECT * FROM [jinbeimes].[dbo].[DailyReport] where Date='{ym}' order by id";

        //string sql = $"SELECT * FROM [jinbeimes].[dbo].[DailyReport] where Date='{ym}' " +
        //    $"union all " +
        //    $"select null, null, '合计：', null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null," +
        //    $"cast(cast(sum(cast(failtime as numeric(18,2))) as numeric(18,2)) as varchar)," +
        //    $"cast(cast(avg(cast(worktime as numeric(18,2))) as numeric(18,2)) as varchar)," +
        //    $"null," +
        //    $"cast(cast(avg(cast(FaultRate as numeric(18,2))) as numeric(18,2)) as varchar)+%," +
        //    $"cast(cast(avg(cast(Availability as numeric(18,2))) as numeric(18,2)) as varchar)+%," +
        //    $"cast(cast(avg(cast(UseRatio as numeric(18,2))) as numeric(18,2)) as varchar)+% " +
        //    $"FROM dailyreport where Date='{ym}'";
        DataTable dt = DbHelperSQL.ExcuteDataTable(sql, connStr); //用于计总数 
        double sumFailTime = 0, sumWorkTime = 0, sumRegularTime = 0, avgFaultRate = 0, avgAvailability = 0, avgUseRatio = 0, valFailTime=0, valWorkTime=0, valRegularTime=0, valFaultRate =0, valAvailability=0, valUseRatio=0;
        foreach(DataRow dr in dt.Rows)
        {
            double.TryParse(dr["FailTime"].ToString(), out valFailTime);
            sumFailTime += valFailTime;
            double.TryParse(dr["WorkTime"].ToString(), out valWorkTime);
            sumWorkTime += valWorkTime;
            double.TryParse(dr["RegularTime"].ToString(), out valRegularTime);
            sumRegularTime += valRegularTime;
            double.TryParse(dr["FaultRate"].ToString().TrimEnd('%'), out valFaultRate);
            avgFaultRate += valFaultRate;
            double.TryParse(dr["Availability"].ToString().TrimEnd('%'), out valAvailability);
            avgAvailability += valAvailability;
            double.TryParse(dr["UseRatio"].ToString().TrimEnd('%'), out valUseRatio);
            avgUseRatio += valUseRatio;
        }
        if (dt.Rows.Count > 0)
        {
            //如大于0行，增加统计行
            sumFailTime = Math.Round(sumFailTime, 2);
            sumWorkTime = Math.Round(sumWorkTime, 2);
            sumRegularTime = Math.Round(sumRegularTime, 2);
            avgFaultRate = Math.Round(avgFaultRate / dt.Rows.Count, 2);
            avgAvailability = Math.Round(avgAvailability / dt.Rows.Count, 2);
            avgUseRatio = Math.Round(avgUseRatio / dt.Rows.Count, 2);
            DataRow newRow = dt.NewRow();
            newRow["DevNo"] = "合计：";
            newRow["FailTime"] = sumFailTime;
            newRow["WorkTime"] = sumWorkTime;
            newRow["RegularTime"] = sumRegularTime;
            newRow["FaultRate"] = avgFaultRate+"%";
            newRow["Availability"] = avgAvailability + "%";
            newRow["UseRatio"] = avgUseRatio + "%";
            dt.Rows.Add(newRow);
        }

        for (int i = 0; i < dt.Rows.Count; i++)
        {
            for (int j = 0; j < dt.Columns.Count; j++)
            {
                string temp = dt.Rows[i][j].ToString().Trim();
                if (j == 0 && temp == "")
                {
                    dt.Rows[i][j] = 0;
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