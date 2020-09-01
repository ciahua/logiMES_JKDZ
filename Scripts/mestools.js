var MesTools = {
    /**
     * 获取隐藏列信息，t为表名，用于读取存储信息，c为hide列数据
     * @param {any} t 表名，用于读取存储信息
     * @param {any} c hide列数据
     * @param {any} $ jquery $
     */
    GetHideCols: function (t, c, $) {
        //获取隐藏列设置信息，并设置隐藏列
        var colState = layui.data(t).cols;
        if (colState != undefined) {
            $.each(colState, function (i, o) {
                c[i].hide = o.value;
            });
        }
        return c;
    },

    /**
     * 保存隐藏列信息，t为存储关键字，用于存储隐藏列信息，i为表Id
     * @param {any} i 表Id
     * @param {any} t 存储信息关键字，用于存储隐藏列信息
     * @param {any} table layui.table
     */
    SetHideCols: function (i, t, table) {
        var colHide = [];
        table.eachCols(i, function (index, item) {
            //console.log(index, item);
            var o = new Object();
            o.key = item.field;
            o.value = item.hide;
            colHide.push(o);
        });
        //console.log(colHide);
        layui.data(t, { //保存隐藏列信息
            key: 'cols',
            value: colHide
        });
    },

    /**
     * 2维数组，获取隐藏列信息，t为表名，用于读取存储信息，c为hide列数据
     * @param {any} t 表名，用于读取存储信息
     * @param {any} c hide列数据
     * @param {any} $ jquery $
     */
    GetHideCols2: function (t, c, $) {
        //获取隐藏列设置信息，并设置隐藏列
        var colState = layui.data(t).cols;
        //$.each(colState, function (i, o) {
        //    $.each(o, function (m, n) {
        //        c[i,m].hide = n.value;
        //    })
        //});

        //c = colState;
        var b = c.length;
        for (var i = 0; i < c.length; i++) {
            var l = c[i].length;
            for (var j = 0; j < l; j++) {
                if ('field' in c[i][j]) {
                    $.each(colState, function (a, b) {
                        if (b.key == c[i][j].field) {
                            var s = b.value;
                            c[i][j].hide = s;
                        }
                    })
                }
            }
        }

        return c;
    },

    /**
     * 2维数组，保存隐藏列信息，t为存储关键字，用于存储隐藏列信息，i为表Id
     * @param {any} i 表Id
     * @param {any} t 存储信息关键字，用于存储隐藏列信息
     * @param {any} table layui.table
     */
    SetHideCols2: function (i, t, table) {
        var colHide = [];
        table.eachCols(i, function (index, item) {
            console.log(index, item);
            var o = new Object();
            o.key = item.field;
            o.value = item.hide;
            colHide.push(o);
        });
        //console.log(colHide);
        layui.data(t, { //保存隐藏列信息
            key: 'cols',
            value: colHide
        });
    }
}
