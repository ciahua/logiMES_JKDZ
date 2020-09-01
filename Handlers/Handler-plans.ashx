<%@ WebHandler Language="C#" Class="Handler_plans" %>

using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Configuration;
using System.Data;
using System.Text.RegularExpressions;
using System.Web;

public class Handler_plans : IHttpHandler {
    static string connStr = ConfigurationManager.ConnectionStrings["ConnectionString"].ToString();
    static string connScadaStr = ConfigurationManager.ConnectionStrings["ConnectionSCADAString"].ToString();
    int startIndex, endIndex;

    public void ProcessRequest (HttpContext context) {
        context.Response.ContentType = "text/plain";
        string resJson = string.Empty;
        string actId = context.Request["actid"];

        string page = context.Request["page"];
        string limit = context.Request["limit"];
        startIndex = (Convert.ToInt32(page) - 1) * Convert.ToInt32(limit) + 1;
        endIndex = Convert.ToInt32(page) * Convert.ToInt32(limit);

        switch (actId)
        {
            case "getTable":
                resJson = GetTable2Json();
                break;
        }

        context.Response.Write(resJson);
    }

    /// <summary>
    /// 获取计划列表
    /// </summary>
    /// <returns></returns>
    private string GetTable2Json()
    {
        string sql = "SELECT * FROM Plans order by Id Desc";
        DataTable dtCount = DbHelperSQL.ExcuteDataTable(sql, connStr); //用于计总数                   

        sql = "SELECT * from (SELECT *, ROW_NUMBER() OVER(ORDER BY Id ASC) AS Num FROM Plans)AS TempTable WHERE Num BETWEEN " + startIndex + " AND " + endIndex;

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

    public bool IsReusable {
        get {
            return false;
        }
    }

}