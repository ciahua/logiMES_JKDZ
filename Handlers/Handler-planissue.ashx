<%@ WebHandler Language="C#" Class="Handler_planissue" %>

using System;
using System.Web;
using System.Configuration;
using Newtonsoft.Json;

public class Handler_planissue : IHttpHandler {

    static string connStr = ConfigurationManager.ConnectionStrings["ConnectionString"].ToString();
    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "text/plain";
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
        string complete = context.Request["complete"];
        string reelType = context.Request["reeltype"];
        string reelSize = context.Request["reelsize"];
        string memo = context.Request["memo"];

        string sql = "insert into ProductionPlan values ('" +
            fileName+"','"+
            planTime+"', '"+
            publisher+"', '"+sheetName+"', '"+machineId+"', '"+machineName+"', '"+planner+"', '"+approver+"', '"+orderTime+"', '"+orderId+"', '"+orderNo+"', '"+orderPeriod+
            "', '"+contract+"', '"+modelVoltage+"', '"+size+"', '"+length+"', '"+requirement+"', '"+type+"', '"+dayShift+"', '"+dayShiftSignature+"', '"+nightShift+"', '"+nightShiftSignature+
            "', '"+ complete + "', '', '" + reelType+"', '"+reelSize+"', '"+memo+"')";

        DbHelperSQL.Execute(sql, connStr);

        context.Response.Write(JsonConvert.SerializeObject("Hello World"));
    }

    public bool IsReusable
    {
        get
        {
            return false;
        }
    }

}