/**

 @Name：layuiAdmin 主页控制台
 @Author：嘉腾
 @Site：http://www.logi-iot.com/admin/
 @License：GPL-2
    
 */


layui.define(function (exports) {

    /*
      下面通过 layui.use 分段加载不同的模块，实现不同区域的同时渲染，从而保证视图的快速呈现
    */

    //区块轮播切换
    layui.use(['admin', 'carousel'], function () {
        var $ = layui.$
            , admin = layui.admin
            , carousel = layui.carousel
            , element = layui.element
            , device = layui.device();

        //轮播切换
        $('.layadmin-carousel').each(function () {
            var othis = $(this);
            carousel.render({
                elem: this
                , width: '100%'
                , arrow: 'none'
                , interval: othis.data('interval')
                , autoplay: othis.data('autoplay') === true
                , trigger: (device.ios || device.android) ? 'click' : 'hover'
                , anim: othis.data('anim')
            });
        });

        element.render('progress');

    });

    //数据概览
    layui.use(['carousel', 'echarts'], function () {
        var $ = layui.$
            , carousel = layui.carousel
            , echarts = layui.echarts;

        Date.prototype.Format = function (fmt) {
            var o = {
                "M+": this.getMonth() + 1, //月份 
                "d+": this.getDate(), //日 
                "H+": this.getHours(), //小时 
                "m+": this.getMinutes(), //分 
                "s+": this.getSeconds(), //秒 
                "q+": Math.floor((this.getMonth() + 3) / 3), //季度 
                "S": this.getMilliseconds() //毫秒 
            };
            if (/(y+)/.test(fmt)) fmt = fmt.replace(RegExp.$1, (this.getFullYear() + "").substr(4 - RegExp.$1.length));
            for (var k in o)
                if (new RegExp("(" + k + ")").test(fmt)) fmt = fmt.replace(RegExp.$1, (RegExp.$1.length == 1) ? (o[k]) : (("00" + o[k]).substr(("" + o[k]).length)));
            return fmt;
        }

        /*
         *   功能:实现VBScript的DateAdd功能.
         *   参数:interval,字符串表达式，表示要添加的时间间隔.
         *   参数:number,数值表达式，表示要添加的时间间隔的个数.
         *   参数:date,时间对象.
         *   返回:新的时间对象.
         *   var now = new Date();
         *   var newDate = DateAdd( "d", 5, now);
         *---------------   DateAdd(interval,number,date)   -----------------
         */
        function DateAdd(interval, number, date) {
            switch (interval) {
                case "y ": {
                    date.setFullYear(date.getFullYear() + number);
                    return date;
                    break;
                }
                case "q ": {
                    date.setMonth(date.getMonth() + number * 3);
                    return date;
                    break;
                }
                case "m ": {
                    date.setMonth(date.getMonth() + number);
                    return date;
                    break;
                }
                case "w ": {
                    date.setDate(date.getDate() + number * 7);
                    return date;
                    break;
                }
                case "d ": {
                    date.setDate(date.getDate() + number);
                    return date;
                    break;
                }
                case "h ": {
                    date.setHours(date.getHours() + number);
                    return date;
                    break;
                }
                case "m ": {
                    date.setMinutes(date.getMinutes() + number);
                    return date;
                    break;
                }
                case "s ": {
                    date.setSeconds(date.getSeconds() + number);
                    return date;
                    break;
                }
                default: {
                    date.setDate(d.getDate() + number);
                    return date;
                    break;
                }
            }
        }

        //var now = new Date();
        //// 加五天.
        //var newDate = DateAdd("d ", 5, now);
        //alert(newDate.toLocaleDateString())
        //// 加两个月.
        //newDate = DateAdd("m ", 2, now);
        //alert(newDate.toLocaleDateString())
        //// 加一年
        //newDate = DateAdd("y ", 1, now);
        //alert(newDate.toLocaleDateString())

        var echartsApp = [], options = [
            //今日流量趋势
            {
                title: {
                    text: '设备日耗电量曲线图',
                    x: 'center',
                    textStyle: {
                        fontSize: 14
                    }
                },
                tooltip: {
                    trigger: 'axis'
                },
                legend: {
                    data: ['', '']
                },
                xAxis: [{
                    type: 'category',
                    boundaryGap: false,
                    data: ['06:00', '06:30', '07:00', '07:30', '08:00', '08:30', '09:00', '09:30', '10:00', '11:30', '12:00', '12:30', '13:00', '13:30', '14:00', '14:30', '15:00', '15:30', '16:00', '16:30', '17:00', '17:30', '18:00', '18:30', '19:00', '19:30', '20:00', '20:30', '21:00', '21:30', '22:00', '22:30', '23:00', '23:30']
                }],
                yAxis: [{
                    type: 'value'
                }],
                series: [{
                    name: '日耗电量',
                    type: 'line',
                    smooth: true,
                    itemStyle: { normal: { areaStyle: { type: 'default' } } },
                    data: [111, 222, 333, 444, 555, 666, 3333, 33333, 55555, 66666, 33333, 3333, 6666, 17777, 9666, 6555, 5555, 3333, 2222, 3111, 6999, 5888, 2777, 1666, 999, 888, 777, 11888, 26666, 38888, 56666, 42222, 39999, 28888]
                }]
            },

            //设备能耗TOP5分布
            {
                title: {
                    text: '设备实时能耗TOP5分布',
                    x: 'center',
                    textStyle: {
                        fontSize: 14
                    }
                },
                tooltip: {
                    trigger: 'item',
                    formatter: "{a} <br/>{b} : {c} ({d}%)"
                },
                legend: {
                    orient: 'vertical',
                    x: 'left',
                    data: ['中车株洲', '南京高立', '中铁工程', '贵州金沙', '河南神火']
                },
                series: [{
                    name: '访问来源',
                    type: 'pie',
                    radius: '55%',
                    center: ['50%', '50%'],
                    data: [
                        { value: 9052, name: '中车株洲' },
                        { value: 1610, name: '南京高立' },
                        { value: 3200, name: '中铁工程' },
                        { value: 535, name: '贵州金沙' },
                        { value: 1700, name: '河南神火' }
                    ]
                }]
            },

            //最近一周生产订单的数量
            {
                title: {
                    text: '最近一周生产计划量',
                    x: 'center',
                    textStyle: {
                        fontSize: 14
                    }
                },
                tooltip: { //提示框
                    trigger: 'axis',
                    formatter: "{b}<br>生产计划量：{c}"
                },
                xAxis: [{ //X轴
                    type: 'category',
                    data: ['11-07', '11-08', '11-09', '11-10', '11-11', '11-12', '11-13']
                }],
                yAxis: [{  //Y轴
                    type: 'value'
                }],
                series: [{ //内容
                    type: 'line',
                    data: [200, 300, 400, 610, 150, 270, 380],
                }]
            }
        ]
            , elemDataView = $('#LAY-index-dataview').children('div')
            , renderDataView = function (index) {
                //echartsApp[index] = echarts.init(elemDataView[index], layui.echartsTheme);
                //echartsApp[index].setOption(options[index]);
                //window.onresize = echartsApp[index].resize;
                if (index == 0) {
                    $.ajax({
                        //url: '../../../Handlers/Handler-index.ashx',
                        url:'../../../Handlers/Handler-index.ashx?actid=view&viewstr=View_3&',
                        //data: { actid: 'getChartData' },
                        async: false,
                        success: function (res) {
                            var p = JSON.parse(res).data;
                            var d = [], pow = [];
                            $.each(p, function (i, n) {
                                d[i] = n.Expr1;
                                pow[i] = n.val;
                                //d[i] = n.SQLtime;
                                //pow[i] = n.real_yongdianliang;
                            });
                            options[index].xAxis[0].data = d;
                            options[index].series[0].data = pow;

                            echartsApp[index] = echarts.init(elemDataView[index], layui.echartsTheme);
                            echartsApp[index].setOption(options[index]);
                            window.onresize = echartsApp[index].resize;
                        },
                        error: function (e) {

                        }
                    });
                }
                else if (index == 1) {
                    $.ajax({
                        url: '../../../Handlers/Handler-index.ashx',
                        data: { actid: 'getChartData1' },
                        async: false,
                        success: function (res) {
                            var p = JSON.parse(res).data;
                            var d = [], pow = [];
                            $.each(p, function (i, n) {
                                d[i] = n.Expr1;
                                pow[i] = n.电度量;
                                options[index].series[0].data[i].name = n.Expr1;
                                options[index].series[0].data[i].value = n.电度量;
                            });
                            options[index].legend.data = d;
                            echartsApp[index] = echarts.init(elemDataView[index], layui.echartsTheme);
                            echartsApp[index].setOption(options[index]);
                            window.onresize = echartsApp[index].resize;
                        },
                        error: function (e) {

                        }
                    });
                } else {
                    var today = new Date();
                    //today = DateAdd("d ", -1, today);
                    var days = [];
                    for (var i = 0; i < 7; i++) {
                        days.push(DateAdd("d ", -1, today).Format("MM-dd"));
                    }                    
                    options[index].xAxis[0].data = days.reverse(); //['11-07', '11-08', '11-09', '11-10', '11-11', '11-12', '11-13'];
                    echartsApp[index] = echarts.init(elemDataView[index], layui.echartsTheme);
                    echartsApp[index].setOption(options[index]);
                    window.onresize = echartsApp[index].resize;
                }                
            };


        //没找到DOM，终止执行
        if (!elemDataView[0]) return;

        renderDataView(0);

        //监听数据概览轮播
        var carouselIndex = 0;
        carousel.on('change(LAY-index-dataview)', function (obj) {
            renderDataView(carouselIndex = obj.index);
        });

        //监听侧边伸缩
        layui.admin.on('side', function () {
            setTimeout(function () {
                renderDataView(carouselIndex);
            }, 300);
        });

        //监听路由
        layui.admin.on('hash(tab)', function () {
            layui.router().path.join('') || renderDataView(carouselIndex);
        });
    });

    //最新订单
    layui.use(['table', 'util'], function () {
        var $ = layui.$
            , table = layui.table
            , util = layui.util;

        //系统消息
        var inst = table.render({
            elem: '#LAY-index-topSearch'
            //,url: layui.setter.base + 'json/console/top-search.js' //模拟接口
            , id: 'testReload'
            , url: '../../../Handlers/Handler-index.ashx'
            , where: { actid: 'getSysLog' }
            , page: true
            , cols: [[
                { type: 'numbers', fixed: 'left' }
                //, { field: 'Time', title: '时间', minWidth: 300, templet: '<div><a href="https://www.baidu.com/s?wd={{ d.Time }}" target="_blank" class="layui-table-link">{{ d.Time }}</div>' }
                , {
                    field: 'Time', title: '时间', minWidth: 300, templet: function (d) {
                        return util.timeAgo(d.Time, true);
                    }
                }
                , { field: 'UserName', title: '用户', minWidth: 120, sort: true }
                , { field: 'Action', title: '事件', sort: true }
            ]]
            , skin: 'line'
        });


        var reload = function () {
            //执行重载
            table.reload('testReload', {
                page: {
                    curr: 1 //重新从第 1 页开始
                }
            }, 'data');
        }

        function getTable() {
            $.ajax({
                url: '../../../Handlers/Handler-index.ashx',
                data: { actid: 'getSysLog' },
                async: false,
                success: function (res) {
                    var djson = JSON.parse(res);
                    var data = djson.data;
                    iniTable(data);
                },
                error: function (data) {
                    console.log(data);
                }
            });
        }

        function iniTable(data) {
            table.render({
                elem: '#LAY-index-topSearch'
                //,url: layui.setter.base + 'json/console/top-search.js' //模拟接口
                , id: 'testReload'
                //, url: '../../../Handlers/Handler-index.ashx'
                //, where: { actid: 'getSysLog' }
                , data: data
                , page: true
                , cols: [[
                    { type: 'numbers', fixed: 'left' }
                    //, { field: 'Time', title: '时间', minWidth: 300, templet: '<div><a href="https://www.baidu.com/s?wd={{ d.Time }}" target="_blank" class="layui-table-link">{{ d.Time }}</div>' }
                    , {
                        field: 'Time', title: '时间', minWidth: 300, templet: function (d) {
                            return util.timeAgo(d.Time, true);
                        }
                    }
                    , { field: 'UserName', title: '用户', minWidth: 120, sort: true }
                    , { field: 'Action', title: '事件', sort: true }
                ]]
                , skin: 'line'
            });
        }

        setInterval(reload, 1000 * 60);

        //今日热贴
        table.render({
            elem: '#LAY-index-topCard'
            , url: layui.setter.base + 'json/console/top-card.js' //模拟接口
            , page: true
            , cellMinWidth: 120
            , cols: [[
                { type: 'numbers', fixed: 'left' }
                , { field: 'title', title: '标题', minWidth: 300, templet: '<div><a href="{{ d.href }}" target="_blank" class="layui-table-link">{{ d.title }}</div>' }
                , { field: 'username', title: '发帖者' }
                , { field: 'channel', title: '类别' }
                , { field: 'crt', title: '点击率', sort: true }
            ]]
            , skin: 'line'
        });
    });
















    exports('console', {})
});