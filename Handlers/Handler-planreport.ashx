<%@ WebHandler Language="C#" Class="Handler_planreport" %>

using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Web;
using Newtonsoft.Json;
using System.Data;
using System.Data.SqlClient;
using System.Text.RegularExpressions;

public class Handler_planreport : IHttpHandler
{

    static string connStr = ConfigurationManager.ConnectionStrings["ConnectionString"].ToString();
    int startIndex, endIndex;
    string devId;
    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "text/plain";

        string actId = context.Request["actid"];
        devId = context.Request["deviceid"]; //设备号
        string page = context.Request["page"];
        string limit = context.Request["limit"];
        startIndex = (Convert.ToInt32(page) - 1) * Convert.ToInt32(limit) + 1;
        endIndex = Convert.ToInt32(page) * Convert.ToInt32(limit);

        string sql = string.Empty;
        string resJson = string.Empty;
        switch (actId)
        {
            case "getTable":
                resJson = GetTable2Json();
                break;
            case "insTable":
                string fileName = context.Request["filename"];
                string planTime = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                string publisher = context.Request["publisher"];
                string sheetName = context.Request["sheetname"];
                string machineId = context.Request["machineid"];
                string machineName = context.Request["machinename"];
                string planner = context.Request["planner"];
                string approver = context.Request["approver"];
                string orderTime = context.Request["ordertime"];
                string orderId = context.Request["orderid"];
                string orderNo = context.Request["orderno"];
                string orderPeriod = context.Request["orderperiod"];
                string contract = context.Request["contract"];
                string modelVoltage = context.Request["modelvoltage"];
                string size = context.Request["size"];
                string length = context.Request["length"];
                string requirement = context.Request["requirement"];
                string type = context.Request["type"];
                string dayShift = context.Request["dayshift"];
                string dayShiftSignature = context.Request["dayshiftsignature"];
                string nightShift = context.Request["nightshift"];
                string nightShiftSignature = context.Request["nightshiftsignature"];
                string reelType = context.Request["reeltype"];
                string reelSize = context.Request["reelsize"];
                string memo = context.Request["memo"];

                //sql = $"insert into ProductionPlan values ('{fileName}','{planTime}', '{publisher}', '{sheetName}', '{machineName}', '{planner}', '{approver}', '{orderTime}', '{orderId}', '{orderNo}', '{orderPeriod}', '{contract}', '{modelVoltage}', '{size}', '{length}', '{requirement}', '{type}', '{dayShift}', '{dayShiftSignature}', '{nightShift}', '{nightShiftSignature}', '{reelType}', '{reelSize}', '{memo}')";
                sql = "insert into ProductionPlan values ('" +
            fileName + "','" +
            planTime + "', '" +
            publisher + "', '" + sheetName + "', '" + machineId + "', '" + machineName + "', '" + planner + "', '" + approver + "', '" + orderTime + "', '" + orderId + "', '" + orderNo + "', '" + orderPeriod +
            "', '" + contract + "', '" + modelVoltage + "', '" + size + "', '" + length + "', '" + requirement + "', '" + type + "', '" + dayShift + "', '" + dayShiftSignature + "', '" + nightShift + "', '" + nightShiftSignature +
            "', '" + reelType + "', '" + reelSize + "', '" + memo + "')";

                DbHelperSQL.Execute(sql, connStr);

                //重新读取表格
                //SELECT * FROM (SELECT *,ROW_NUMBER() OVER(ORDER BY id ASC) AS Num FROM ProductionPlan )AS TempTable WHERE Num BETWEEN 21 AND 30
                sql = "select id as id, publisher as username, sheetname as sex, machinename as city, ordertime as sign, orderno as experience, contract as score, modelvoltage as classify, size as wealth from ProductionPlan order by id";
                DataTable dtCount1 = DbHelperSQL.ExcuteDataTable(sql, connStr); //用于计总数                   

                sql = "select id as id, publisher as username, sheetname as sex, machinename as city, ordertime as sign, orderno as experience, contract as score, modelvoltage as classify, size as wealth from (SELECT *, ROW_NUMBER() OVER(ORDER BY id ASC) AS Num FROM ProductionPlan)AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex; //有问题？

                DataTable dt1 = DbHelperSQL.ExcuteDataTable(sql, connStr);
                //新建json对象，序列化为json字符串
                var json1 = new
                {
                    code = 0,
                    msg = "",
                    count = dtCount1.Rows.Count,
                    data = dt1
                };
                resJson = JsonConvert.SerializeObject(json1);

                break;
            case "updateTable":
                string newValue = context.Request["newvalue"];
                string id = context.Request["id"];
                string field = context.Request["field"];
                string currTime = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                sql = "update ProductionPlan set " + field + " = '" + newValue + "', reporttime = '"+currTime+"' where id=" + id;
                DbHelperSQL.Execute(sql, connStr);
                resJson = GetTable2Json();

                break;
        }

        context.Response.Write(resJson);
    }

    private string GetTable2Json()
    {
        //重新读取表格
        string today = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss").Split(' ')[0];
        string sql = "select id, machineid, machinename, orderid, orderno, orderperiod, contract, modelvoltage, size, length, requirement, type, dayshift, nightshift, complete, reeltype, reelsize from ProductionPlan where machineid='" + devId + "' AND plantime like '"+today+"%' order by plantime desc, reporttime desc, id asc";
        DataTable dtCount = DbHelperSQL.ExcuteDataTable(sql, connStr); //用于计总数                   

        sql = "select id, machineid, machinename, orderid, orderno, orderperiod, contract, modelvoltage, size, length, requirement, type, dayshift, nightshift, complete, reeltype, reelsize from (SELECT *, ROW_NUMBER() OVER(ORDER BY plantime desc, reporttime desc, id asc) AS Num FROM ProductionPlan where machineid='"+devId+ "' AND plantime like '"+today+"%')AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex;

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