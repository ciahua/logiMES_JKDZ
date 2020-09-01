<%@ WebHandler Language="C#" Class="Handler" %>

using System;
using System.Web;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.IO;
using System.Text;

public class Handler : IHttpHandler {

    public void ProcessRequest (HttpContext context) {
        context.Response.ContentType = "text/plain";
        string json = context.Request["act"];
        JArray jo = (JArray)JsonConvert.DeserializeObject(json);
        for (int i = 0; i < jo.Count; i++)
        {
            JObject studentitem = (JObject)jo[i];
            String studentname = (String)studentitem["name"];
            JArray studentage = (JArray)studentitem["children"];
            //insert_into_db(studentname, studentage);
        }

        string fileurl = @"E:\write_in.json";
        StreamWriter write_in = new StreamWriter(fileurl,false,Encoding.UTF8);//创建写入文件的对象,文件位置，是否可以追加内容，什么编码。
        write_in.WriteLine(jo);
        //write_in.WriteLine(txtcontent);
        write_in.Close();


        context.Response.Write("Hello World");
    }

    public bool IsReusable {
        get {
            return false;
        }
    }

}