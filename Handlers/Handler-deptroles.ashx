<%@ WebHandler Language="C#" Class="Handler_planreport" %>

using Newtonsoft.Json;
using System;
using System.Configuration;
using System.Data;
using System.Text.RegularExpressions;
using System.Web;
using Newtonsoft.Json.Linq;
using System.Collections.Generic;

public class Handler_planreport : IHttpHandler
{

    static string connStr = ConfigurationManager.ConnectionStrings["ConnectionString"].ToString();
    int startIndex, endIndex;
    public string json = string.Empty;

    public class Children
    {
        /// <summary>
        /// 
        /// </summary>
        public string id { get; set; }
        /// <summary>
        /// 
        /// </summary>
        public string pid { get; set; }
        /// <summary>
        /// 请设置部门名称4
        /// </summary>
        public string name { get; set; }
        /// <summary>
        /// 
        /// </summary>
        public List<Children> children { get; set; }
        /// <summary>
        /// 
        /// </summary>
        public string LAY_INDEX { get; set; }
    }   
    

    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "text/plain";
        string actId = context.Request["actid"];
        string data = context.Request["data"];
        string newValue = context.Request["newvalue"];
        switch (actId)
        {
            case "getTable":
                json = GetTable2Json();
                break;
            case "addNewLine":
                json = AddNewLine2Json(data);
                break;
            case "addSubLine":
                json = AddSubLine2Json(data);
                break;
            case "delTable":
                json = DelLine2Json(data);
                break;
            case "updateTable":
                json = Update2Json(data, newValue);
                break;
        }
        context.Response.Write(json);
    }

    /// <summary>
    /// 获取表格
    /// </summary>
    /// <returns></returns>
    private string GetTable2Json()
    {
        string sql = "select id, pId as pid, name from DeptRoles";
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

    private string AddSubLine2Json(string da)
    {
        Children jo = JsonConvert.DeserializeObject<Children>(da);
        //获取最大的id值
        string sqlMaxId = string.Format("SELECT MAX(id) FROM dbo.DeptRoles");
        object maxIdObj = DbHelperSQL.ExecuteScalar(sqlMaxId, connStr);
        int maxId = 0;
        if (maxIdObj != null)
        {
            maxId = Convert.ToInt32(maxIdObj);
        }
        string sql = string.Format("insert into DeptRoles values('{0}','{1}','{2}')", ++maxId, jo.id, "请输入新的部门/角色名称");
        bool isOk = DbHelperSQL.Execute(sql, connStr);
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
    /// <summary>
    /// 添加新行
    /// </summary>
    /// <param name="da"></param>
    /// <returns></returns>
    private string AddNewLine2Json(string da)
    {
        //Children jo = JsonConvert.DeserializeObject<Children>(da);
        //获取最大的id值
        string sqlMaxId = string.Format("SELECT MAX(id) FROM dbo.DeptRoles");
        object maxIdObj = DbHelperSQL.ExecuteScalar(sqlMaxId, connStr);
        int maxId = 0;
        if (maxIdObj != null)
        {
            maxId = Convert.ToInt32(maxIdObj);
        }
        string sql = string.Format("insert into DeptRoles values('{0}','{1}','{2}')", ++maxId, "0", "请输入新的部门/角色名称");
        bool isOk = DbHelperSQL.Execute(sql, connStr);
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

    /// <summary>
    /// 删除菜单
    /// </summary>
    /// <param name="da"></param>
    /// <returns></returns>
    private string DelLine2Json(string da)
    {
        Children jo = JsonConvert.DeserializeObject<Children>(da);
        string sqlDel = string.Format("delete from deptroles where id='{0}' and pid='{1}'", jo.id, jo.pid);
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

    private string Update2Json(string da, string nv)
    {
        Children jo = JsonConvert.DeserializeObject<Children>(da);
        string sqlDel = string.Format("update deptroles set name='{0}' where id='{1}' and pid='{2}'", nv, jo.id, jo.pid);
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


    public bool IsReusable
    {
        get
        {
            return false;
        }
    }

}