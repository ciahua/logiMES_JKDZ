var SiteScriptHelper = {
    IsString: function (object) {
        return typeof (object) === "string";
    },
    /**
       格式化数字 四舍五入
       s 要格式化的数字
       n 保留位数
     */
    Fmoney: function (s, n) {
        n = n > 0 && n <= 20 ? n : 2;
        s = parseFloat((s + "").replace(/[^\d\.-]/g, "")).toFixed(n) + "";
        var l = s.split(".")[0].split("").reverse(), r = s.split(".")[1];
        t = "";
        for (i = 0; i < l.length; i++) {
            t += l[i] + ((i + 1) % 3 == 0 && (i + 1) != l.length ? "," : "");
        }
        return t.split("").reverse().join("") + "." + r;
    },
    IsArray: function (object) {
        return object && typeof object === 'object' &&
            typeof object.length === 'number' &&
            typeof object.splice === 'function' &&
            //判断length属性是否是可枚举的 对于数组 将得到false  
            !(object.propertyIsEnumerable('length'));
    },
    /* 加载脚本
       jspath: 脚本路径 (支持单个路径 和 多个路径) ['*****.js','**.js']
       callback: 加载完成后执行
    */
    LoadScript: function (jspath, callback, verifyJs) {
        var loadCompleteScripts = [];
        var loadScripts = [];
        if (this.IsArray(jspath)) {
            loadScripts = jspath;
        } else if (this.IsString(jspath)) {
            loadScripts.push(jspath);
        } else {
            return;
        }
        if (typeof (verifyJs) == "undefined")
            verifyJs = true;
        var group = document.getElementsByTagName("script");
        var isAppendSrcript = true;
        for (var i = 0; i < loadScripts.length; i++) {
            // 验证是否脚本
            if (verifyJs && !/\.js(\?)?/ig.test(loadScripts[i])) {
                continue;
            }
            isAppendSrcript = true;
            // 判断脚本页面是否已经加载
            if (group.length > 0) {
                for (var x = 0; x < group.length; x++) {
                    if (group[x].getAttribute("src") === null)
                        continue;
                    if (group[x].getAttribute("src").toString().toLowerCase().indexOf(loadScripts[i].toLowerCase()) >= 0) {
                        loadCompleteScripts.push(loadScripts[i]);
                        if (loadCompleteScripts.length === loadScripts.length
                            && typeof (callback) === "function") {
                            callback();
                        }
                        isAppendSrcript = false;
                        break;
                    }
                }
            }
            if (isAppendSrcript) {
                var script = document.createElement("script");
                script.setAttribute("id", "site_dynaload_" + Math.ceil(Math.random() * 100000));
                script.setAttribute("type", "text/javascript");
                script.setAttribute("src", loadScripts[i] + "?var=" + new Date().getTime());
                if (script.addEventListener) {
                    script.addEventListener('load', function () {
                        loadCompleteScripts.push(this.src);
                        if (loadCompleteScripts.length === loadScripts.length && typeof (callback) === "function")
                            callback();
                    }, false);
                } else if (script.attachEvent) {
                    script.attachEvent('onreadystatechange', function () {
                        var target = window.event.srcElement;
                        if (target.readyState == 'loaded') {
                            loadCompleteScripts.push(target.src);
                            if (loadCompleteScripts.length === loadScripts.length && typeof (callback) === "function")
                                callback();
                        }
                    });
                }
                var head = document.getElementsByTagName('head').item(0);
                head.appendChild(script);
            }
        }
    },
    /* 加载样式
       jspath: 脚本路径 (支持单个路径 和 多个路径) ['*****.css','**.css']
       callback: 加载完成后执行
    */
    LoadCSS: function (filepath, callback) {
        var loadCompleteFile = [];
        var loadFile = [];
        if (this.IsArray(filepath)) {
            loadFile = filepath;
        } else if (this.IsString(filepath)) {
            loadFile.push(filepath);
        } else {
            return;
        }

        var group = document.getElementsByTagName("link");
        var isAppendFile = true;
        for (var i = 0; i < loadFile.length; i++) {
            // 验证是否脚本
            if (!/\.css(\?)?/ig.test(loadFile[i])) {
                continue;
            }
            isAppendFile = true;
            // 判断脚本页面是否已经加载
            if (group.length > 0) {
                for (var x = 0; x < group.length; x++) {
                    if (group[x].getAttribute("href") === null)
                        continue;
                    if (group[x].getAttribute("href").toString().toLowerCase().indexOf(loadFile[i].toLowerCase()) >= 0) {
                        loadCompleteFile.push(loadFile[i]);
                        if (loadCompleteFile.length === loadFile.length
                            && typeof (callback) === "function") {
                            callback();
                        }
                        isAppendFile = false;
                        break;
                    }
                }
            }
            if (isAppendFile) {
                var csslink = document.createElement("link");
                csslink.setAttribute("id", "site_dynaload_" + Math.ceil(Math.random() * 100000));
                csslink.setAttribute("rel", "stylesheet");
                csslink.setAttribute("type", "text/css");
                csslink.setAttribute("href", loadFile[i] + "?var=" + new Date().getTime());
                csslink.onload = csslink.onreadystatechange = function () {
                    if (csslink.readyState && csslink.readyState !== 'loaded' && csslink.readyState !== 'complete') {
                        return;
                    }
                    csslink.onreadystatechange = csslink.onload = null;
                    loadCompleteFile.push(loadFile[i]);
                    if (loadCompleteFile.length === loadFile.length
                        && typeof (callback) === "function") {
                        callback();
                    }
                };
                var head = document.getElementsByTagName('head').item(0);
                head.appendChild(csslink);
            }
        }
    },
    /* 
       给出页面请求的参数
       name ： 不包含参数名
       GetRequestParms()["要获取的参数"]
    */
    GetRequestParms: function (name) {
        var url = location.search; //获取url中"?"符后的字串
        var theRequest = new Object();
        if (url.indexOf("?") !== -1) {
            var str = url.substr(1);
            strs = str.split("&");
            for (var i = 0; i < strs.length; i++) {
                if (strs[i].split("=")[0].toLowerCase() === name) {
                    continue;
                }
                theRequest[strs[i].split("=")[0].toLowerCase()] = unescape(strs[i].split("=")[1]);
            }
        }
        return theRequest;
    },
    /* 
       追加或者更改Url参数
       ChangeURLPar(test, 'haha', 33); // http://www.huistd.com/?id=99&ttt=3&haha=33
    */
    ChangeURLPar: function (url, name, value) {
        var str = "";
        if (url.indexOf('?') != -1)
            str = url.substr(url.indexOf('?') + 1);
        else
            return url + "?" + ref + "=" + value;
        var returnurl = "";
        var setparam = "";
        var arr;
        var modify = "0";
        if (str.indexOf('&') != -1) {
            arr = str.split('&');
            for (i in arr) {
                if (arr[i].split('=')[0] == ref) {
                    setparam = value;
                    modify = "1";
                }
                else {
                    setparam = arr[i].split('=')[1];
                }
                returnurl = returnurl + arr[i].split('=')[0] + "=" + setparam + "&";
            }
            returnurl = returnurl.substr(0, returnurl.length - 1);
            if (modify == "0")
                if (returnurl == str)
                    returnurl = returnurl + "&" + ref + "=" + value;
        }
        else {
            if (str.indexOf('=') != -1) {
                arr = str.split('=');
                if (arr[0] == ref) {
                    setparam = value;
                    modify = "1";
                }
                else {
                    setparam = arr[1];
                }
                returnurl = arr[0] + "=" + setparam;
                if (modify == "0")
                    if (returnurl == str)
                        returnurl = returnurl + "&" + ref + "=" + value;
            }
            else
                returnurl = ref + "=" + value;
        }
        return url.substr(0, url.indexOf('?')) + "?" + returnurl;
    },
    IsMobile: function () {
        var sUserAgent = navigator.userAgent.toLowerCase();
        var bIsIpad = sUserAgent.match(/ipad/i) === "ipad";
        var bIsIphoneOs = sUserAgent.match(/iphone os/i) === "iphone os";
        var bIsMidp = sUserAgent.match(/midp/i) === "midp";
        var bIsUc7 = sUserAgent.match(/rv:1.2.3.4/i) === "rv:1.2.3.4";
        var bIsUc = sUserAgent.match(/ucweb/i) === "ucweb";
        var bIsAndroid = sUserAgent.match(/android/i) === "android";
        var bIsCE = sUserAgent.match(/windows ce/i) === "windows ce";
        var bIsWM = sUserAgent.match(/windows mobile/i) === "windows mobile";
        var bIsWeixinWap = sUserAgent.match(/micromessenger/i) === "micromessenger";
        if (bIsIphoneOs || bIsMidp || bIsUc7 || bIsUc || bIsAndroid || bIsCE || bIsWM || bIsWeixinWap)
            return true;
        else
            return false;
    },
    ScrollTop: function () {
        if (typeof ($(window).scrollTo) !== "undefined") {
            $(window).scrollTo({
                toT: 0
            });
        } else if (typeof ($('html,body').animate) !== "undefined") {
            $('html,body').animate({
                scrollTop: 0
            }, 1000);
        }
    },
    /* 
       时间格式化2018-06-02T11:30:27
    */
    ToTime: function (time) {
        if (time.indexOf("T") < 0)
            return time;
        //部分早期的谷歌浏览器带T的时间字符串进行new Date() 会直接减少8小时 所以这边直接移除掉T
        var dateee = new Date(time.replace("T", " ")).toJSON();
        var date = new Date(+new Date(dateee) + 8 * 3600 * 1000).toISOString()
            .replace(/T/g, ' ')
            .replace(/\.[\d]{3}Z/, '');
        return date;
    },
    /* 
      可格式化 
      2018-06-02T11:30:27
      /Date(2367828670431)
      为标准格式
   */
    FormatTime: function (time, format) {
        var me = this;
        var data = time || "";
        if (time === "")
            data = Date();
        if (typeof (time) === "string") {
            time = time.replace(/-/g, "/");
            if (time.indexOf("T") >= 0)
                data = new Date(me.ToTime(time));
            if (time.indexOf("/Date") >= 0)
                data = new Date(parseInt(time.slice(6, 19)));
        }
        if (typeof (format) === "undefined" || format === "")
            format = "yyyy-MM-dd HH:mm:ss";
        if (!(data instanceof Date))
            data = new Date(time.replace(/-/g, "/"));
        if (format.indexOf("yyyy") >= 0)
            format = format.replace("yyyy", data.getFullYear());
        if (format.indexOf("MM") >= 0)
            format = format.replace("MM", (data.getMonth() + 1) <= 9 ? "0" + (data.getMonth() + 1) : (data.getMonth() + 1));
        if (format.indexOf("dd") >= 0)
            format = format.replace("dd", data.getDate() <= 9 ? "0" + data.getDate() : data.getDate());
        if (format.indexOf("HH") >= 0 || format.indexOf("hh") >= 0)
            format = format.replace(/hh/i, data.getHours() <= 9 ? "0" + data.getHours() : data.getHours());
        if (format.indexOf("mm") >= 0)
            format = format.replace("mm", data.getMinutes() <= 9 ? "0" + data.getMinutes() : data.getMinutes());
        if (format.indexOf("ss") >= 0)
            format = format.replace("ss", data.getSeconds() <= 9 ? "0" + data.getSeconds() : data.getSeconds());
        return format;
    },
    /*
     * 是否是今天
     */
    IsToDay: function (time) {
        var me = this;
        if (typeof (time) === "undefined")
            return false;
        time = me.FormatTime(time);
        var date = new Date(time.replace(/-/g, "/"));
        var curData = new Date();
        if (date.getDate() === curData.getDate())
            return true;
        return false;
    },
    /**
     * 将列表数据转成树形结构和符合table展示的列表
     * var jsonData =[
           {"id":"4","pid":"1","name":"大家电"},
           {"id":"5","pid":"1","name":"生活电器"},
           {"id":"1","pid":"0","name":"家用电器"},
           {"id":"2","pid":"0","name":"服饰"},
           {"id":"3","pid":"0","name":"化妆"},
           {"id":"7","pid":"4","name":"空调"},
           {"id":"8","pid":"4","name":"冰箱"},
           {"id":"9","pid":"4","name":"洗衣机"},
           {"id":"10","pid":"4","name":"热水器"},
           {"id":"11","pid":"3","name":"面部护理"},
           {"id":"12","pid":"3","name":"口腔护理"},
           {"id":"13","pid":"2","name":"男装"},
           {"id":"14","pid":"2","name":"女装"},
           {"id":"15","pid":"7","name":"海尔空调"},
           {"id":"16","pid":"7","name":"美的空调"},
           {"id":"19","pid":"5","name":"加湿器"},
           {"id":"20","pid":"5","name":"电熨斗"}
           ]; 
       ErpScriptHelper.TreeGridArry(jsonData,"id","pid");
     * @param data          列表数据
     * @param field_Id      树形结构主键字段
     * @param field_upId    树形结构上级字段
     * @param specifiedParentId  起始父类Id
     * @returns {Array}     [0]表格列表  [1]树形结构
     */
    TreeGridArry: function (data, field_Id, field_upId, startParentId) {
        var list = [];
        var treeList = [];
        var tableList = [];
        var firstData = [];//顶级父类
        //处理树结构
        var fa = function (upId) {
            var array = [];
            for (var i = 0; i < data.length; i++) {
                var n = data[i];
                if (parseInt(n[field_upId]) === parseInt(upId)) {
                    n.children = fa(n[field_Id]);
                    array.push(n);
                }
            }
            return array;
        }
        if (typeof (startParentId) === "undefined" || !(/^-?\d+$/.test(startParentId))) {
            var isExist = function (id) {
                for (var i = 0; i < data.length; i++) {
                    var n = data[i];
                    if (n[field_Id] === id) {
                        return true;
                    }
                }
            }
            for (var i = 0; i < data.length; i++) {
                if (!isExist(data[i][field_upId])) {
                    firstData.push(data[i]); //得到顶级父类
                }
            }
            for (var i = 0; i < firstData.length; i++) {
                var n = firstData[i];
                n.children = fa(firstData[i][field_Id]);
                treeList.push(n); //递归 data[0][field_upId]
            }
        } else {
            treeList = fa(startParentId);
        }
        //处理表格结构
        var fa2 = function (l, level, upids) {
            for (var i = 0; i < l.length; i++) {
                var n = l[i];
                n.level = level;//设置当前层级
                n.upIds = upids;
                tableList.push(n);
                if (n.children && n.children.length > 0) {
                    fa2(n.children, 1 + level, upids + "_" + n[field_Id] + "_");
                }
            }
            return;
        }
        fa2(treeList, 1, "");

        list.push(tableList);//table结构
        list.push(treeList)//tree树结构
        return list;
    },
    /**
     * 导出文件
     * ErpScriptHelper.ExportFile("file",[{Key:"name",Title:'名字'}], [{name:'张三'}], 'csv'); //默认导出 csv，也可以为：xls
     * ErpScriptHelper.ExportFile("file",['名字','性别','年龄'],[['张三','男','20'],['李四','女','18']], 'csv'); //默认导出 csv，也可以为：xls
     * ErpScriptHelper.ExportFile("file",表格ID,null, 'csv'); //默认导出 csv，也可以为：xls
     * @param {} fileName 
     * @param {} id 
     * @param {} data 
     * @param {} type csv/xls
     * @returns {} 
     */
    ExportFile: function (fileName, id, data, type) {
        if (!+[1,]) {
            console.log("IE不支持导出");
            return;
        }
        data = data || {};
        type = type || 'csv';
        var textType = ({
            csv: 'text/csv',
            xls: 'application/vnd.ms-excel'
        })[type];
        var alink = document.createElement("a");
        var tableHeader = [], dateList = [];
        if (typeof id === 'object') {
            if (typeof id[0] === 'object') {
                var tableHeaderKey = [];
                $.each(id, function (i, item) {
                    tableHeaderKey.push(item.Key);
                    tableHeader.push(item.Title);
                });
                $.each(data, function (i) {
                    var info = [];
                    $.each(tableHeaderKey, function (q, key) {
                        info.push(data[i][key]);
                    });
                    dateList.push(info);
                });
            } else {
                tableHeader = id;
                dateList = data;
            }
        } else {
            if ($("#" + id).length <= 0) {
                console.log("找不到对应Id的table");
                return;
            }
            $("#" + id + " thead tr").eq(0).children().each(function (i, item) {
                tableHeader.push($(item).text());
            });
            $("#" + id + " tbody tr").each(function (i, item) {
                var info = [];
                $.each($(item).find("td"), function (j, item1) {
                    info.push($(item1).text());
                });
                dateList.push(info);
            });
        }
        alink.href = 'data:' + textType + ';charset=utf-8,\ufeff' + encodeURIComponent(function () {
            var dataTitle = [], dataMain = [];
            $.each(dateList, function (i1, item1) {
                var vals = [];
                if (typeof tableHeader === 'object') { //ID直接为表头数据
                    $.each(tableHeader, function (i, item) {
                        i1 === 0 && dataTitle.push(item || '');
                    });
                    $.each(item1, function (i2, item2) {
                        vals.push(item2);
                    });
                }
                dataMain.push(vals.join(','));
            });
            return dataTitle.join(',') + '\r\n' + dataMain.join('\r\n');
        }());
        alink.download = fileName + '.' + type;
        document.body.appendChild(alink);
        alink.click();
        document.body.removeChild(alink);
    },
    /* 
      设置表单值
   */
    SetFormValue: function (formObject, data) {
        formObject.find("[name]").each(function () {
            var type = $(this)[0].nodeName.toLowerCase();
            var name = $(this).attr('name');
            var value = data[name];
            if (typeof (value) === "boolean")
                value = value ? "true" : "false";
            formObject.find(type + "[name='" + name + "']").val(value);
        });
        formObject.find("input[type='checkbox']").each(function () {
            var val = $(this).val();
            $(this).prop('checked', val === "true");
        });
    },
    /* 
      获取表单值
   */
    GetFormValue: function (formObject) {
        var parms = {};
        formObject.find("[name]").each(function () {
            var name = $(this).attr('name');
            var val = $(this).val();
            var typeValue = $(this).attr("type") || "";
            var isCheckbox = typeValue.toLowerCase() === "checkbox";
            if (isCheckbox)
                val = $(this).is(":checked");
            parms[name] = val;
        });
        return parms;
    },
    /**
     * 根据指定字段分组
     */
    GroupByArray: function (arr, groupName) {
        var map = {},
            dest = [];
        for (var i = 0; i < arr.length; i++) {
            var ai = arr[i];
            if (!map[ai[groupName]]) {
                var info = {};
                info[groupName] = ai[groupName];
                info.data = [ai];
                dest.push(info);
                map[ai[groupName]] = ai;
            } else {
                for (var j = 0; j < dest.length; j++) {
                    var dj = dest[j];
                    if (dj[groupName] == ai[groupName]) {
                        dj.data.push(ai);
                        break;
                    }
                }
            }
        }
        return dest;
    },
};