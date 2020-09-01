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
    int startIndex, endIndex;

    private class DevInfo
    {
        public int id { get; set; }
        public string sender { get; set; }
        public string department { get; set; }
        public string startdate { get; set; }
        public string enddate { get; set; }
        public string expert { get; set; }
        public string devno { get; set; }
        public string devname { get; set; }
        public string devdept { get; set; }
        public string part { get; set; }
        public string item { get; set; }
        public string requirement { get; set; }
        public string maintainer { get; set; }
        public string duedate { get; set; }
        public string memo { get; set; }
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


        string DeviceNameval = string.Empty;
        string GruopDeviceIdval = string.Empty;
        string GruopMaintainerval = string.Empty;
        string GruopExpertval = string.Empty;
        
        if (context.Request["searchkey"] != null)
        {
            searchKey = context.Request["searchkey"].Trim(); //获取搜索关键字
        }
        if (context.Request["DeviceNameval"] != null)
        {
            DeviceNameval = context.Request["DeviceNameval"].Trim(); //获取搜索关键字
        }
        if (context.Request["GruopDeviceIdval"] != null)
        {
            GruopDeviceIdval = context.Request["GruopDeviceIdval"].Trim(); //获取搜索关键字
        }
        if (context.Request["GruopExpertval"] != null)
        {
            GruopExpertval = context.Request["GruopExpertval"].Trim(); //获取搜索关键字
        }
        if (context.Request["GruopMaintainerval"] != null)
        {
            GruopMaintainerval = context.Request["GruopMaintainerval"].Trim(); //获取搜索关键字
        }





        string page = context.Request["page"];
        string limit = context.Request["limit"];
        startIndex = (Convert.ToInt32(page) - 1) * Convert.ToInt32(limit) + 1;
        endIndex = Convert.ToInt32(page) * Convert.ToInt32(limit);

        switch (actId)
        {
            case "getExpertCheck":
                resJson = GetTable2Json();
                break;
            case "insTable":
                DevInfo devInfo = JsonConvert.DeserializeObject<DevInfo>(devData);
                string time = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                string sqlAddNew = string.Format("insert into ExpertCheck values('{0}','{1}','{2}','{3}','{4}','{5}','{6}','{7}','{8}','{9}','{10}','{11}','{12}','{13}','{14}','{15}')", devInfo.sender.Trim(), devInfo.department.Trim(), time, devInfo.startdate.Trim(), devInfo.enddate.Trim(), devInfo.expert.Trim(), devInfo.devno.Trim(), devInfo.devname.Trim(), devInfo.devdept.Trim(), devInfo.part.Trim(), devInfo.item.Trim(), devInfo.requirement.Trim(), devInfo.maintainer.Trim(), devInfo.duedate.Trim(), devInfo.memo.Trim(), "");
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
                //resJson = SearchTable(searchKey);
                resJson = SearchTable(searchKey,GruopDeviceIdval,DeviceNameval,GruopExpertval,GruopMaintainerval);
                break;
            case "updateTable":
                DevInfo devUpdateInfo = JsonConvert.DeserializeObject<DevInfo>(devData);
                string uptime = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                string sqlEditRow = string.Format("update ExpertCheck set Sender='{0}', Department = '{1}', DateTime='{2}', StartDate='{3}', EndDate='{4}', Expert='{5}', DeviceId='{6}', DeviceName='{7}', Unit='{8}', Part='{9}', Item='{10}', Requirement='{11}', Maintainer='{12}', DueDate='{13}', Memo='{14}' where Id=" + devUpdateInfo.id, devUpdateInfo.sender.Trim(), devUpdateInfo.department.Trim(), uptime, devUpdateInfo.startdate.Trim(), devUpdateInfo.enddate.Trim(), devUpdateInfo.expert.Trim(), devUpdateInfo.devno.Trim(), devUpdateInfo.devname.Trim(), devUpdateInfo.devdept.Trim(), devUpdateInfo.part.Trim(), devUpdateInfo.item.Trim(), devUpdateInfo.requirement.Trim(), devUpdateInfo.maintainer.Trim(), devUpdateInfo.duedate.Trim(), devUpdateInfo.memo.Trim());
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
                string sqlDelRow = string.Format("delete from ExpertCheck where Id=" + devDelInfo.id);
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
            case "getDeviceInfo":
                resJson = GetDevice2Json();
                break;
            case "assignRepairman":
                resJson = AssignRepair2Json(repairmanName, issueId);
                break;
            case "GroupDeviceName":
                resJson =GroupDeviceName();
                break;
            case "GruopDeviceId":
                resJson =GruopDeviceId();
                break;
            case "GruopMaintainer":
                resJson =GruopMaintainer();
                break;
            case "GruopExpert":
                resJson =GruopExpert();
                break;
        }

        context.Response.Write(resJson);
    }
    /// <summary>
    /// 获取设备号
    /// </summary>
    /// <returns></returns>
    private string GroupDeviceName()
    {
        string sqlRepairman = "SELECT DeviceName FROM [jinbeimes].[dbo].[ExpertCheck] group by DeviceName";
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
    /// 获取设备号
    /// </summary>
    /// <returns></returns>
    private string GruopDeviceId()
    {
        string sqlRepairman = "SELECT DeviceId FROM [jinbeimes].[dbo].[ExpertCheck] group by DeviceId";
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
    /// 获取Maintainer定修责任人
    /// </summary>
    /// <returns></returns>
    private string GruopMaintainer()
    {
        string sqlRepairman = "SELECT Maintainer FROM [jinbeimes].[dbo].[ExpertCheck] group by Maintainer";
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
    /// 获取Expert专业点检员
    /// </summary>
    /// <returns></returns>
    private string GruopExpert()
    {
        string sqlRepairman = "SELECT Expert FROM [jinbeimes].[dbo].[ExpertCheck] group by Expert";
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
    /// 获取设备编号列表
    /// </summary>
    /// <returns></returns>
    private string GetDevice2Json()
    {
        string sqlRepairman = "select distinct DevNo, DevName, DevDept from DeviceList";
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
        string sql = "SELECT * FROM [jinbeimes].[dbo].[ExpertCheck] order by id";
        DataTable dtCount = DbHelperSQL.ExcuteDataTable(sql, connStr); //用于计总数                   

        sql = "SELECT * from (SELECT *, ROW_NUMBER() OVER(ORDER BY id ASC) AS Num FROM ExpertCheck)AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex;

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
    private string SearchTable(string key,string id,string name,string expert,string maintainer)
    {
        string tmpstr = " and DeviceId like '%" + id + "%' and DeviceName like '%" + name + "%' and Expert like '%" + expert + "%' and maintainer like '%" + maintainer + "%' ";
        //重新读取表格
        string sql = "select * from ExpertCheck where CAST(Id AS VARCHAR) + Sender + Department + StartDate + EndDate + Expert + DeviceId + DeviceName + Unit + Part + Item + Requirement + Maintainer + DueDate + Memo like '%" + key + "%' ";
        sql += tmpstr;
        DataTable dtCount = DbHelperSQL.ExcuteDataTable(sql, connStr); //用于计总数                   

        sql = "select * from (SELECT *, ROW_NUMBER() OVER(ORDER BY id ASC) AS Num FROM ExpertCheck where CAST(Id AS VARCHAR) + Sender + Department + StartDate + EndDate + Expert + DeviceId + DeviceName + Unit + Part + Item + Requirement + Maintainer + DueDate + Memo like '%" + key + "%')AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex;
        
        sql += tmpstr;
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
        string sql = "select * from ExpertCheck where CAST(Id AS VARCHAR) + Sender + Department + StartDate + EndDate + Expert + DeviceId + DeviceName + Unit + Part + Item + Requirement + Maintainer + DueDate + Memo like '%" + key + "%' order by id";
        DataTable dtCount = DbHelperSQL.ExcuteDataTable(sql, connStr); //用于计总数                   

        sql = "select * from (SELECT *, ROW_NUMBER() OVER(ORDER BY id ASC) AS Num FROM ExpertCheck where CAST(Id AS VARCHAR) + Sender + Department + StartDate + EndDate + Expert + DeviceId + DeviceName + Unit + Part + Item + Requirement + Maintainer + DueDate + Memo like '%" + key + "%')AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex;

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