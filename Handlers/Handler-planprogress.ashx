<%@ WebHandler Language="C#" Class="Handler_planreport" %>

using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Web;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Data;
using System.Data.SqlClient;
using System.Text.RegularExpressions;

public class Handler_planreport : IHttpHandler
{

    static string connStr = ConfigurationManager.ConnectionStrings["ConnectionString"].ToString();
    int startIndex, endIndex;

    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "text/plain";
        string searchKey = string.Empty;
        string resJson = string.Empty;
        string actId = context.Request["actid"];
        string planData = context.Request["data"];
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
            case "getSum":
                resJson = GetSum();
                break;
            case "searchTable":
                resJson = SearchTable(searchKey);
                break;
            case "updateTable":
                string newValue = context.Request["newvalue"];
                string id = context.Request["id"];
                string field = context.Request["field"];
                string _sql = "update ProductionPlan set " + field + " = '" + newValue + "' where id=" + id;
                DbHelperSQL.Execute(_sql, connStr);
                resJson = GetTable2Json();
                break;
            case "insTable":
                resJson = InsertTable2Json(planData);
                break;
            case "delTable":
                JObject devDelInfo = (JObject)JsonConvert.DeserializeObject(planData);
                string sqlDelRow = string.Format("delete from ProductionPlan where Id=" + devDelInfo["id"]);
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
            case "eidtTable":
                JObject planUpInfo = (JObject)JsonConvert.DeserializeObject(planData);
                string planTime = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                string orderTime = planTime.Substring(0, 10);
                string sqlEditRow = string.Format("update ProductionPlan set plantime='{0}', publisher = '{1}', sheetname='{2}', machineid='{3}', machinename ='{4}', planner = '{5}', approver = '{6}', ordertime = '{7}', orderid = '{8}', orderno = '{9}', orderperiod = '{10}', contract = '{11}', modelvoltage = '{12}', size = '{13}', length ='{14}', requirement ='{15}', type = '{16}', dayshift = '', dayshiftsignature='', nightshift = '', nightshiftsignature='', complete = '', reporttime='',  reeltype ='{17}', reelsize ='{18}', memo='{19}' where Id=" + planUpInfo["id"], planTime, planUpInfo["approver"], planUpInfo["sheetname"], planUpInfo["machineid"], planUpInfo["machinename"], planUpInfo["approver"], planUpInfo["approver"], orderTime, planUpInfo["orderid"], planUpInfo["orderno"], planUpInfo["orderperiod"], planUpInfo["contract"], planUpInfo["modelvoltage"], planUpInfo["size"], planUpInfo["length"], planUpInfo["requirement"], planUpInfo["type"], planUpInfo["reeltype"], planUpInfo["reelsize"], planUpInfo["memo"]);
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
            case "orderComplete":
                string today = DateTime.Now.ToString("yyyy-MM-dd");
                //today = "2020-08-04";
                //string sqlOrderComplete = "select cast(convert (decimal(18,0),100*cast(count(*) as float)/cast((select count(*) from dbo.ProductionPlan WHERE SUBSTRING(plantime, 1, 10)='"+today+"') as float) ) as varchar)+'%' from dbo.ProductionPlan WHERE SUBSTRING(plantime, 1, 10)='"+today+"' AND complete='是'";
                string sqlOrderComplete = "SELECT COUNT(*) orders, (SELECT COUNT(*) FROM dbo.ProductionPlan WHERE SUBSTRING(plantime, 1, 10)='" + today + "' AND complete<>'') feed, (SELECT COUNT(*) FROM dbo.ProductionPlan WHERE SUBSTRING(plantime, 1, 10)='" + today + "' AND complete='是') completed, (SELECT cast(convert(decimal(18,0),ISNULL(100*cast(count(*) as float)/NULLIF(cast((select count(*) from dbo.ProductionPlan WHERE SUBSTRING(plantime, 1, 10)='" + today + "') as float),0),0) ) as varchar)+'%' from dbo.ProductionPlan WHERE SUBSTRING(plantime, 1, 10)='" + today + "' AND complete='是') AS per FROM dbo.ProductionPlan WHERE SUBSTRING(plantime, 1, 10) = '" + today + "'";
                DataTable dt = DbHelperSQL.ExcuteDataTable(sqlOrderComplete, connStr);
                //新建json对象，序列化为json字符串
                var json = new
                {
                    code = 0,
                    msg = "",
                    count = dt.Rows.Count,
                    data = dt
                };
                resJson = JsonConvert.SerializeObject(json);
                break;
            case "getDevList":
                resJson = GetDevList();
                break;
            case "getProdValue":
                resJson = GetProdValue();
                break;
            case "submitValues":
                resJson = SubmitValues(planData);
                break;

        }

        context.Response.Write(resJson);
    }

    private string GetSum()
    {
        string sqlRepairman = "SELECT  COUNT(*) AS sum FROM [jinbeimes].[dbo].[ProductionPlan] WHERE plantime = (SELECT TOP 1 plantime FROM [jinbeimes].[dbo].[ProductionPlan] ORDER BY id DESC)";
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
    /// 获取当天的计划表格
    /// </summary>
    /// <returns></returns>
    private string GetTable2Json()
    {
        //重新读取表格
        //string today = "2020/4/4"; //DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss").Split(' ')[0];
        string today = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss").Split(' ')[0];
        string sql = "select id, sheetname, machineid, machinename, orderid, orderno, orderperiod, contract, modelvoltage, size, length, requirement, type, dayshift, nightshift, complete, reeltype, reelsize from ProductionPlan where plantime like '" + today + "%' order by plantime desc, reporttime desc, id asc";
        DataTable dtCount = DbHelperSQL.ExcuteDataTable(sql, connStr); //用于计总数                   

        sql = "select id, sheetname, machineid, machinename, orderid, orderno, orderperiod, contract, modelvoltage, size, length, requirement, type, dayshift, nightshift, complete, reeltype, reelsize from (SELECT *, ROW_NUMBER() OVER(ORDER BY plantime desc, reporttime desc, id asc) AS Num FROM ProductionPlan where plantime like '" + today + "%')AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex;

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
        string today = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss").Split(' ')[0];
        string sql = "select id, sheetname, machineid, machinename, orderid, orderno, orderperiod, contract, modelvoltage, size, length, requirement, type, dayshift, nightshift, complete, reeltype, reelsize from ProductionPlan where plantime like '" + today + "%' AND sheetname + machineid + machinename + orderid + orderno + orderperiod + contract + modelvoltage + size + length + requirement + type + dayshift + nightshift + complete + reeltype + reelsize like '%" + key + "%' order by id";
        DataTable dtCount = DbHelperSQL.ExcuteDataTable(sql, connStr); //用于计总数                   

        sql = "select id, sheetname, machineid, machinename, orderid, orderno, orderperiod, contract, modelvoltage, size, length, requirement, type, dayshift, nightshift, complete, reeltype, reelsize from (SELECT *, ROW_NUMBER() OVER(ORDER BY id ASC) AS Num FROM ProductionPlan where plantime like '" + today + "%' AND sheetname + machineid + machinename + orderid + orderno + orderperiod + contract + modelvoltage + size + length + requirement + type + dayshift + nightshift + complete + reeltype + reelsize like '%" + key + "%')AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex;

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

    private string InsertTable2Json(string pdata)
    {
        JObject planInfo = (JObject)JsonConvert.DeserializeObject(pdata);
        string planTime = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
        string orderTime = planTime.Substring(0, 10);
        string sqlAddNew = $"insert into ProductionPlan values(" +
            $"'', '{planTime}', '{planInfo["approver"]}', '{planInfo["sheetname"]}', '{planInfo["machineid"]}', '{planInfo["machinename"]}', '{planInfo["approver"]}', '{planInfo["approver"]}', '{orderTime}', '{planInfo["orderid"]}', '{planInfo["orderno"]}', '{planInfo["orderperiod"]}', '{planInfo["contract"]}', '{planInfo["modelvoltage"]}', '{planInfo["size"]}', '{planInfo["length"]}', '{planInfo["requirement"]}', '{planInfo["type"]}', '', '', '', '', '', '', '{planInfo["reeltype"]}', '{planInfo["reelsize"]}', '{planInfo["memo"]}')";

        bool sqlResult = DbHelperSQL.Execute(sqlAddNew, connStr);
        string reJson = string.Empty;
        if (sqlResult)
        {
            reJson = "success";
        }
        else
        {
            reJson = "failure";
        }
        return reJson;
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

    private string GetDevList()
    {
        string sql = "select DevNo, DevName from [jinbeimes].[dbo].[DeviceList] order by DevNo";
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
            count = dt,
            data = dt
        };
        return JsonConvert.SerializeObject(json);

    }

    private string GetProdValue()
    {
        string sql = "select * from [jinbeimes].[dbo].[ProdValue] order by Id";
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
            count = dt,
            data = dt
        };
        return JsonConvert.SerializeObject(json);

    }

    private string SubmitValues(string values)
    {
        JObject jo = (JObject)JsonConvert.DeserializeObject(values);
        string sql = $"update [jinbeimes].[dbo].[ProdValue] set PoValue='{jo["PoValue"]}', CompletedValue='{jo["CompletedValue"]}', UncompletedValue='{jo["UncompletedValue"]}' where Id='{jo["Id"]}'";
        bool result = DbHelperSQL.Execute(sql, connStr);
        if (result)
        {
            return "success";
        }
        else
        {
            return "failure";
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