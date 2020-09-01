/**

 @Name：layuiAdmin 用户管理 管理员管理 角色管理
 @Author：star1029
 @Site：http://www.logi-iot.com/admin/
 @License：LPPL
    
 */

layui.define(['table', 'form', 'util'], function (exports) {
    var $ = layui.$
        , table = layui.table
        , form = layui.form;

    //用户管理
    table.render({
        elem: '#LAY-user-manage'
        , url: '../../../Handlers/Handler-userlist.ashx' //模拟接口
        //, url: layui.setter.base + 'json/useradmin/webuser.js'
        , where: {actid: 'getTable'}
        , cols: [[
            { type: 'checkbox', fixed: 'left' }
            , { field: 'id', width: 100, title: 'ID', sort: true }
            , { field: 'userid', width: 100, title: '工号ID', sort: true }
            , { field: 'username', title: '用户名', minWidth: 100 }
            , { field: 'userpassword', title: '密码', minWidth: 100 }
            , { field: 'realname', title: '真实姓名', minWidth: 100 }
            //, { field: 'avatar', title: '头像', width: 100, templet: '#imgTpl' }
            , { field: 'phone', title: '手机' }
            , { field: 'email', title: '邮箱' }
            , { field: 'sex', width: 80, title: '性别' }
            , { field: 'dept', title: '部门' }
            , { field: 'jointime', title: '加入时间', sort: true }
            , { title: '操作', width: 150, align: 'center', fixed: 'right', toolbar: '#table-useradmin-webuser' }
        ]]
        , id: 'LAY-user-manage'
        , page: true
        , limit: 30
        , height: 'full-220'
        //, text: '对不起，加载出现异常！'
        , text: {
            none: '暂无相关数据' //默认：无数据。注：该属性为 layui 2.2.5 开始新增
        }
    });

    //监听工具条
    table.on('tool(LAY-user-manage)', function (obj) {
        var data = obj.data;
        if (obj.event === 'del') {
            layer.confirm('真的删除行么', function (index) {
                obj.del();
                //提交 Ajax 成功后，静态更新表格中的数据
                $.ajax({
                    url: '../../../Handlers/Handler-userlist.ashx',
                    data: { actid: 'delTable', data: JSON.stringify(data) },
                    success: function (res) {
                        alert('删除成功');
                        layer.close(index); //关闭弹层
                    },
                    error: function (e) {
                        console.log(e);
                    }
                });

                layer.close(index);
            });

            //layer.prompt({
            //    formType: 1
            //    , title: '敏感操作，请验证口令'
            //}, function (value, index) {
            //    layer.close(index);

            //    layer.confirm('真的删除行么', function (index) {
            //        obj.del();
            //        layer.close(index);
            //    });
            //});
        } else if (obj.event === 'edit') {
            var tr = $(obj.tr);
            json = JSON.stringify(data);

            layer.open({
                type: 2
                , title: '编辑用户'
                , content: '../../../views/component/users/userformedit.html'
                , maxmin: true
                , area: ['500px', '600px']
                , btn: ['确定', '取消']
                , yes: function (index, layero) {
                    var iframeWindow = window['layui-layer-iframe' + index]
                        , submitID = 'LAY-user-front-submit'
                        , submit = layero.find('iframe').contents().find('#' + submitID); 
                    var body = layer.getChildFrame('body', index);

                    //监听提交
                    iframeWindow.layui.form.on('submit(' + submitID + ')', function (data) {
                        var field = data.field; //获取提交的字段
                        var result = body.find("#male").is(":checked");                        
                        if (result) {
                            field.sex = '男';
                        } else {
                            field.sex = '女';
                        }
                        
                        //提交 Ajax 成功后，静态更新表格中的数据
                        $.ajax({
                            url: '../../../Handlers/Handler-userlist.ashx',
                            data: { actid: 'updateTable', data: JSON.stringify(field) },
                            success: function (res) {
                                alert('修改成功');
                                table.reload('LAY-user-manage');
                                layer.close(index); //关闭弹层
                            },
                            error: function (e) {
                                console.log(e);
                            }
                        });
                        //table.reload('LAY-user-front-submit'); //数据刷新
                        //layer.close(index); //关闭弹层
                    });

                    submit.trigger('click');
                }
                , success: function (layero, index) {
                    var body = layer.getChildFrame('body', index);
                    var iframeWin = window[layero.find('iframe')[0]['name']];
                    body.find("input[name='id']").val(data.id); 
                    body.find("input[name='userid']").val(data.userid); 
                    body.find("input[name='username']").val(data.username);
                    body.find("input[name='userpassword']").val(data.userpassword);
                    body.find("input[name='realname']").val(data.realname);
                    body.find("input[name='phone']").val(data.phone);
                    body.find("input[name='email']").val(data.email);
                    body.find("input[name='dept']").val(data.email);
                    body.find("input[name='sex']").val(data.sex); 
                    if (data.sex == '男') {
                        body.find("#male").attr("checked", "true");
                        //alert('男');
                        //body.find("input[name='sex'][value='男']").attr("checked", 'true');
                        //body.find("input[name='sex'][value='女']").attr("checked", 'false');
                    } else {
                        body.find("#female").attr("checked", "true");
                        //alert('女');
                        //body.find("input[name='sex'][value='男']").attr("checked", 'true');
                        //body.find("input[name='sex'][value='女']").attr("checked", 'false');
                    }
                }
            });
        }
    });

    //管理员管理
    table.render({
        elem: '#LAY-user-back-manage'
        , url: layui.setter.base + 'json/useradmin/mangadmin.js' //模拟接口
        , cols: [[
            { type: 'checkbox', fixed: 'left' }
            , { field: 'id', width: 80, title: 'ID', sort: true }
            , { field: 'loginname', title: '登录名' }
            , { field: 'telphone', title: '手机' }
            , { field: 'email', title: '邮箱' }
            , { field: 'role', title: '角色' }
            , { field: 'jointime', title: '加入时间', sort: true }
            , { field: 'check', title: '审核状态', templet: '#buttonTpl', minWidth: 80, align: 'center' }
            , { title: '操作', width: 150, align: 'center', fixed: 'right', toolbar: '#table-useradmin-admin' }
        ]]
        , text: '对不起，加载出现异常！'
    });

    //监听工具条
    table.on('tool(LAY-user-back-manage)', function (obj) {
        var data = obj.data;
        if (obj.event === 'del') {
            layer.prompt({
                formType: 1
                , title: '敏感操作，请验证口令'
            }, function (value, index) {
                layer.close(index);
                layer.confirm('确定删除此管理员？', function (index) {
                    console.log(obj)
                    obj.del();
                    layer.close(index);
                });
            });
        } else if (obj.event === 'edit') {
            var tr = $(obj.tr);

            layer.open({
                type: 2
                , title: '编辑管理员'
                , content: '../../../views/user/administrators/adminform.html'
                , area: ['420px', '420px']
                , btn: ['确定', '取消']
                , yes: function (index, layero) {
                    var iframeWindow = window['layui-layer-iframe' + index]
                        , submitID = 'LAY-user-back-submit'
                        , submit = layero.find('iframe').contents().find('#' + submitID);

                    //监听提交
                    iframeWindow.layui.form.on('submit(' + submitID + ')', function (data) {
                        var field = data.field; //获取提交的字段

                        //提交 Ajax 成功后，静态更新表格中的数据
                        //$.ajax({});
                        table.reload('LAY-user-front-submit'); //数据刷新
                        layer.close(index); //关闭弹层
                    });

                    submit.trigger('click');
                }
                , success: function (layero, index) {

                }
            })
        }
    });

    //角色管理
    table.render({
        elem: '#LAY-user-back-role'
        , url: layui.setter.base + 'json/useradmin/role.js' //模拟接口
        , cols: [[
            { type: 'checkbox', fixed: 'left' }
            , { field: 'id', width: 80, title: 'ID', sort: true }
            , { field: 'rolename', title: '角色名' }
            , { field: 'limits', title: '拥有权限' }
            , { field: 'descr', title: '具体描述' }
            , { title: '操作', width: 150, align: 'center', fixed: 'right', toolbar: '#table-useradmin-admin' }
        ]]
        , text: '对不起，加载出现异常！'
    });

    //监听工具条
    table.on('tool(LAY-user-back-role)', function (obj) {
        var data = obj.data;
        if (obj.event === 'del') {
            layer.confirm('确定删除此角色？', function (index) {
                obj.del();
                layer.close(index);
            });
        } else if (obj.event === 'edit') {
            var tr = $(obj.tr);

            layer.open({
                type: 2
                , title: '编辑角色'
                , content: '../../../views/user/administrators/roleform.html'
                , area: ['500px', '480px']
                , btn: ['确定', '取消']
                , yes: function (index, layero) {
                    var iframeWindow = window['layui-layer-iframe' + index]
                        , submit = layero.find('iframe').contents().find("#LAY-user-role-submit");

                    //监听提交
                    iframeWindow.layui.form.on('submit(LAY-user-role-submit)', function (data) {
                        var field = data.field; //获取提交的字段

                        //提交 Ajax 成功后，静态更新表格中的数据
                        //$.ajax({});
                        table.reload('LAY-user-back-role'); //数据刷新
                        layer.close(index); //关闭弹层
                    });

                    submit.trigger('click');
                }
                , success: function (layero, index) {

                }
            })
        }
    });

    exports('useradmin', {})
});