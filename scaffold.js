var scaffoldList = function() {
     var vm = new function() {
         this.list =  m.prop([]);
     }

    this.controller = function() {
        new CrudController("scaffold-entities", vm).call(this);
    }

    this.view = function(c) {
        return [
            m("h1", "Entities"),
            m("ol",[
                vm.list().map(function(entity) {
                    return m("li", [
                        m("a", { href: "/scaffold/" + entity, text: entity, config: m.route })
                    ])
                })
             ])
        ];
    }
}

var scaffoldTableList = function() {
    var _vm = function() {
        this.list =  m.deferred();
        this.cols = m.prop([]);
        this.table = m.prop("");
        this.rows = m.prop([]);
    }
    var vm = new _vm();
    this.controller = function() {
        vm = new _vm();
        vm.table(m.route.param("table"));
        var options = {
            postParams: { "*Entity" : vm.table() }
        }
        vm.list.promise.then(function(resp) {
            var table = m.route.param("table");
            var rawCols = resp.json.definition.map(function(x) { return x.split(/[\s\+]/).splice(1); });
            var tableCols = rawCols.filter(function(x) { return ('+' + x[0]) == table });
            vm.cols(["nr"].concat(tableCols.map(function(x) { return x[1] })));
            vm.rows(resp.list);
        });
        new CrudController("scaffold-entity", vm, options).call(this);
    }
    
    this.view = function(ctrl) {
        return [
            m("h1", vm.table()),
            m("table", [
                m("tr", [
                    vm.cols().map(function(col) {
                        return m("td", col)
                    })
                ]),
                vm.rows().map(function(row) {
                    return m("tr", [
                        vm.cols().map(function(col) {
                            return m("td", row[col] ? row[col]() : '');
                        })                   
                    ])
                })
            ])
        ];
    }
}

routeBuilders.push(function(routes) {
    routes["/scaffold"] = new scaffoldList();
    routes["/scaffold/:table"] = new scaffoldTableList();
});
