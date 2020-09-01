<%@ WebHandler Language="C#" Class="Handler_menuspermission" %>

using System;
using System.Web;
using System.Data;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;


public class Handler_menuspermission : IHttpHandler
{
	string connStr = "Data Source = localhost;Initial Catalog = jinbeimes;User Id = sa;Password = 123456;";
	public string json = string.Empty;
	public void ProcessRequest(HttpContext context)
	{
		context.Response.ContentType = "text/plain";
		string actId = context.Request["actid"];
		string data = context.Request["data"];
		string menuName = context.Request["menuname"];
		string menuValue = context.Request["menuvalue"];

		switch (actId)
		{
			case "getTable":
				json = GetTable();
				break;
			case "getMenus":
				json = GetMenus();
				break;
			case "getUsers":
				json = GetUsers();
				break;
			case "savePermission":
				json = SavePermission(data, menuName, menuValue);
				break;
			case "loadPermission":
				json = LoadPermission(menuValue);
				break;
		}
		context.Response.Write(json);
	}

	private string GetTable()
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
		string jstr = JsonConvert.SerializeObject(jsonObj);
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
				jo["value"] = Convert.ToInt32(rows[i]["did"].ToString().Trim());
				jo["children"] = GetJsonArray(rows[i]["id"].ToString().Trim(), table);
				ja.Add(jo);
			}
		}
		return ja;
	}

	private string GetMenus()
	{
		string sql = "select * from Menus";
		DataTable dt = DbHelperSQL.ExcuteDataTable(sql, connStr);

		//ok. 将权限表转为tree json格式
		JArray array = GetMenusArray("0", dt);

		var jsonObj = new
		{
			code = 0,
			msg = "",
			count = dt.Rows.Count,
			data = array
		};
		string jstr = JsonConvert.SerializeObject(jsonObj);
		return jstr;
	}

	private JArray GetMenusArray(string parentId, DataTable table)
	{
		DataRow[] rows = table.Select("pId=" + parentId);
		JArray ja = new JArray();
		if (rows.Length > 0)
		{
			for (int i = 0; i < rows.Length; i++)
			{
				JObject jo = new JObject();
				jo["name"] = rows[i]["name"].ToString().Trim();
				jo["value"] = Convert.ToInt32(rows[i]["id"].ToString().Trim());
				jo["children"] = GetMenusArray(rows[i]["id"].ToString().Trim(), table);
				ja.Add(jo);
			}
		}
		return ja;
	}

	private string GetUsers()
	{
		string sql = @"
		BEGIN
			IF EXISTS(SELECT* FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[staff]') AND type in (N'U'))
			DROP TABLE[dbo].[staff]
			SELECT* INTO staff FROM dbo.DeptRoles
			INSERT INTO staff SELECT userid AS id, deptid AS pId, realname AS name FROM dbo.UserList
			SELECT * FROM dbo.staff
		END
		";

		DataTable dt = DbHelperSQL.ExcuteDataTable(sql, connStr);

		//ok. 将权限表转为tree json格式
		JArray array = GetUsersArray("0", dt);

		var jsonObj = new
		{
			code = 0,
			msg = "",
			count = dt.Rows.Count,
			data = array
		};
		string jstr = JsonConvert.SerializeObject(jsonObj);
		return jstr;
	}

	private JArray GetUsersArray(string parentId, DataTable table)
	{
		DataRow[] rows = table.Select("pId='" + parentId+"'");
		JArray ja = new JArray();
		if (rows.Length > 0)
		{
			for (int i = 0; i < rows.Length; i++)
			{
				JObject jo = new JObject();
				jo["name"] = rows[i]["name"].ToString().Trim();
				//jo["value"] = Convert.ToInt32(rows[i]["id"].ToString().Trim());
				jo["value"] = rows[i]["id"].ToString().Trim();
				jo["children"] = GetUsersArray(rows[i]["id"].ToString().Trim(), table);
				ja.Add(jo);
			}
		}
		return ja;
	}

	private string SavePermission(string d, string mname, string mvalue)
	{
		//获取菜单的pId
		string sql = string.Format("select pid from menus where id='{0}'", mvalue);
		object obj = DbHelperSQL.ExecuteScalar(sql, connStr);
		string mpid = obj == null ? "" : obj.ToString();

		sql = string.Format("" +
			"IF NOT EXISTS(SELECT * FROM Permission WHERE id='{0}') " +
				"INSERT INTO Permission	VALUES('{1}','{2}', '{3}', '{4}', '{5}') " +
			"ELSE " +
				"UPDATE Permission SET users='{6}' WHERE id='{7}'", mvalue, mvalue, mpid, mname, "", d, d, mvalue);
		bool isOK = DbHelperSQL.Execute(sql, connStr);
		string s = string.Empty;
		if (isOK)
		{
			s = "success";
		}
		else
		{
			s = "failure";
		}
		return s;
	}

	private string LoadPermission(string mvalue)
	{
		string sql = string.Format("select users from permission where id='{0}'", mvalue);
		object obj = DbHelperSQL.ExecuteScalar(sql, connStr);
		string objStr = obj == null ? "" : obj.ToString();
		return objStr;
	}

	public bool IsReusable
	{
		get
		{
			return false;
		}
	}

}