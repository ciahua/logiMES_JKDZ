<%@ WebHandler Language="C#" Class="Handler_info" %>

using Newtonsoft.Json;
using System;
using System.Configuration;
using System.Data;
using System.Text.RegularExpressions;
using System.Web;
using Newtonsoft.Json.Linq;
using System.Collections.Generic;

public class Handler_info : IHttpHandler {
    static string connStr = ConfigurationManager.ConnectionStrings["ConnectionString"].ToString();
    string json = string.Empty;
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
        public string remarks { get; set; }
    }
    public class Pass
    {
        public string username { get; set; }
        public string oldPassword { get; set; }
        public string password { get; set; }
    }

    public void ProcessRequest (HttpContext context) {
        context.Response.ContentType = "text/plain";
        string actid = context.Request["actid"];
        string data = context.Request["data"];
        switch (actid)
        {
            case "getTable":
                json = GetTable2Json(data);
                break;
            case "updateTable":
                json = UpdateTable2Json(data);
                break;
            case "changePassword":
                json = ChangePassword(data);
                break;
        }
        context.Response.Write(json);
    }
    /// <summary>
    /// 获取表格
    /// </summary>
    /// <returns></returns>
    private string GetTable2Json(string uid)
    {
        string sql = "select * from UserList where userid='"+uid+"'";
        DataTable dt = DbHelperSQL.ExcuteDataTable(sql, connStr);

        var json = new
        {
            code = 0,
            msg = "",
            count = dt.Rows.Count,
            data = dt
        };
        return JsonConvert.SerializeObject(json);
    }

    private string UpdateTable2Json(string user)
    {
        UserInfo jo = JsonConvert.DeserializeObject<UserInfo>(user);
        string sqlDel = string.Format("update UserList set phone='{0}', email='{1}', reserved1='{2}' where id='{3}'", jo.phone, jo.email, jo.remarks, jo.id);
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
        var json = new
        {
            code = 0,
            msg = s,
            count = 1,
            data = s
        };
        return JsonConvert.SerializeObject(json);
    }

    private string ChangePassword(string pass)
    {
        string s = string.Empty;
        Pass jo = JsonConvert.DeserializeObject<Pass>(pass);
        string sqlChange = string.Format("select * from userlist where userid='{0}' and userpassword='{1}'", jo.username, jo.oldPassword);
        object result = DbHelperSQL.ExecuteScalar(sqlChange, connStr);
        if (result != null)
        {
            sqlChange = string.Format("update userlist set userpassword='{0}' where userid='{1}'", jo.password, jo.username);
            DbHelperSQL.Execute(sqlChange, connStr);
            s = "success";
        }
        else
        {
            s = "failure";
        }

        var json = new
        {
            code = 0,
            msg = s,
            count = 1,
            data = s
        };
        return JsonConvert.SerializeObject(json);
    }

    public bool IsReusable {
        get {
            return false;
        }
    }

}