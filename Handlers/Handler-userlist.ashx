<%@ WebHandler Language="C#" Class="Handler_userlist" %>

using System;
using System.Web;
using System.Data;
using System.Configuration;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
 
using System.Runtime.InteropServices;

public class Handler_userlist : IHttpHandler {
    static string connStr = ConfigurationManager.ConnectionStrings["ConnectionString"].ToString();
    int startIndex, endIndex;
    public string json = string.Empty;


    [DllImport("Iphlpapi.dll")]
    private static extern int SendARP(Int32 dest, Int32 host, ref   Int64 mac, ref   Int32 length);
    [DllImport("Ws2_32.dll")]
    private static extern Int32 inet_addr(string ip);

    public class UserInfo
    {
        public string id { get; set; }
        public string userId { get; set; }
        public string userName { get; set; }
        public string userPassword { get; set; }
        public string realName { get; set; }
        public string phone { get; set; }
        public string email { get; set; }
        public string sex { get; set; }
        public string dept { get; set; }
        public string deptId { get; set; }
    }

    public void ProcessRequest (HttpContext context) {
        context.Response.ContentType = "text/plain";
        string actId = context.Request["actid"];
        string data = context.Request["data"];
        string page = context.Request["page"];
        string limit = context.Request["limit"];
        string endMacAddr = "";
        startIndex = (Convert.ToInt32(page) - 1) * Convert.ToInt32(limit) + 1;
        endIndex = Convert.ToInt32(page) * Convert.ToInt32(limit);

        //======
        string result = HttpContext.Current.Request.ServerVariables["HTTP_X_FORWARDED_FOR"];
        if (null == result || result == String.Empty)
        {
            result = HttpContext.Current.Request.ServerVariables["REMOTE_ADDR"];
        }
        if (null == result || result == String.Empty)
        {
            result = HttpContext.Current.Request.UserHostAddress;
        }
        Int64 macid = getremotemac(result);
        if (macid != 0)
        {
            string beforeMacAddr = Convert.ToString(macid, 16);

            string[] macArray = new string[6];
            for (int i = 0; i * 2 + 2 <= beforeMacAddr.Length && i < 6 ; i++)
            {
                macArray[i] = beforeMacAddr.Substring(i * 2, 2);
            }
            for (int i = 0; i < 6; i++)
            {
                endMacAddr += macArray[5 - i] + "-";
            }
            endMacAddr = endMacAddr.Substring(0, endMacAddr.Length - 1);
            endMacAddr = endMacAddr.ToUpper();
        }



        switch (actId)
        {
            case "getTable":
                json = GetTable2Json();
                break;
            case "getDeptRoles":
                json = GetDeptRoles2Json();
                break;
            case "insTable":
                json = InsTable2Json(data);
                break;
            case "updateTable":
                json = UpdateTable2Json(data);
                break;
            case "delTable":
                json = DelTable2Json(data);
                break;
            case "mac":
                json = endMacAddr;
                break;
        }

        context.Response.Write(json);
    }


    static private Int64 getremotemac(string remoteip)
    {
        Int32 ldest = inet_addr(remoteip);
        try
        {
            Int64 macinfo = new Int64();
            Int32 len = 6;
            int res = SendARP(ldest, 0, ref   macinfo, ref   len);
            return macinfo;
        }
        catch (Exception err)
        {
            Console.WriteLine("error:{0}", err.Message);
        }
        return 0;
    }

    /// <summary>
    /// 获取表格
    /// </summary>
    /// <returns></returns>
    private string GetTable2Json()
    {
        string sql = "SELECT * FROM [jinbeimes].[dbo].[UserList] order by Id";
        DataTable dtCount = DbHelperSQL.ExcuteDataTable(sql, connStr); //用于计总数                   

        sql = "SELECT * from (SELECT *, ROW_NUMBER() OVER(ORDER BY Id ASC) AS Num FROM UserList)AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex;

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

    private string GetDeptRoles2Json()
    {
        string sql = "select * from deptroles";
        DataTable dt = DbHelperSQL.ExcuteDataTable(sql, connStr);

        //ok. 将权限表转为tree json格式
        JArray array = GetJsonArray("0", dt);

        var jsonObj = new
        {
            code = 0,
            msg = "",
            count = dt.Rows.Count,
            data = array
        };
        string jstr=JsonConvert.SerializeObject(jsonObj);
        return jstr;
    }

    private JArray GetJsonArray(string parentId, DataTable table)
    {
        DataRow[] rows = table.Select("pId=" + parentId);
        JArray ja = new JArray();
        if (rows.Length > 0)
        {
            for (int i = 0; i < rows.Length; i++)
            {
                JObject jo = new JObject();
                jo["name"] = rows[i]["name"].ToString().Trim();
                //jo["value"] =Convert.ToInt32(rows[i]["did"].ToString().Trim());
                jo["value"] =Convert.ToInt32(rows[i]["id"].ToString().Trim());
                jo["children"] = GetJsonArray(rows[i]["id"].ToString().Trim(), table);
                ja.Add(jo);
            }
        }
        return ja;
    }

    private string InsTable2Json(string udata)
    {
        UserInfo ui = JsonConvert.DeserializeObject<UserInfo>(udata);
        string now = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
        string jstr = string.Empty;
        string sqlIns = string.Format("insert into userlist values('{0}','{1}','{2}','{3}','{4}','{5}','{6}','{7}','{8}','{9}','{10}','{11}','{12}','{13}','{14}','{15}')", ui.userId, ui.userName, ui.userPassword, ui.realName, null, ui.phone, ui.email, ui.sex, ui.dept, ui.deptId, now, null, null, null, null, null);
        bool isOK = DbHelperSQL.Execute(sqlIns, connStr);
        if (isOK)
        {
            jstr = "success";
        }
        else
        {
            jstr = "error";
        }
        return jstr;
    }

    private string UpdateTable2Json(string user)
    {
        UserInfo jo = JsonConvert.DeserializeObject<UserInfo>(user);
        string sqlDel = string.Format("update UserList set userid='{0}', username='{1}', userpassword='{2}', realname='{3}', phone='{4}', email='{5}', sex='{6}', dept='{7}', deptid='{8}' where id='{9}'", jo.userId, jo.userName, jo.userPassword, jo.realName, jo.phone, jo.email, jo.sex, jo.dept, jo.deptId, jo.id);
        bool isOk = DbHelperSQL.Execute(sqlDel, connStr);
        string s = string.Empty;
        if (isOk)
        {
            s = "success";
        }
        else
        {
            s = "failure";
        }
        return JsonConvert.SerializeObject(s);
    }

    private string DelTable2Json(string u)
    {
        UserInfo jo = JsonConvert.DeserializeObject<UserInfo>(u);
        string sqlDel = string.Format("delete from UserList where id='{0}'", jo.id);
        bool isOk = DbHelperSQL.Execute(sqlDel, connStr);
        string s = string.Empty;
        if (isOk)
        {
            s = "success";
        }
        else
        {
            s = "failure";
        }
        return JsonConvert.SerializeObject(s);

    }


    public bool IsReusable {
        get {
            return false;
        }
    }

}