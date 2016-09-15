//converts +Todo to todo
var scaffoldEntityToShort = function(entity) {
    if (entity[0] == '+') {
        entity = entity.slice(1);
    }
    return entity.toLowerCase();
}
var ScaffoldList = function() {
     var vm = new function() {
         this.list =  m.prop([]);
     }

    this.controller = function() {
        new CrudController("scaffold-entities", vm).call(this);
    }

    this.view = function(c) {
        return c.mount([
            m("h1", "Entities"),
            m("ol",[
                vm.list().map(function(entity) {
                    return m("li", [
                        m("a", { href: "/scaffold/" + entity, text: entity, config: m.route })
                    ])
                })
             ])
        ]);
    }
}

var ScaffoldTableList = function() {
    var _vm = function() {
        this.list =  m.deferred();
        this.cols = m.prop([]);
        this.table = m.prop("");
        this.rows = m.prop([]);
    }
    this.controller = function(args) {
        var self = this;
        var vm = new _vm();
        this.vm = vm;
        vm.table((args && args.table) ? args.table : m.route.param("table"));
        var options = {
            postParams: { "*Entity" : vm.table() }
        }

        this.addRow = function() {
            m.route('/scaffold/' + vm.table() + '/add');
        }
        this.editRow = function(row) {
            m.route('/scaffold/' + vm.table() + '/edit/' + row.nr());
        }
        this._refresh = function() {
            vm.list = m.deferred();
            vm.list.promise.then(function(resp) {
                var table = m.route.param("table");
                var rawCols = resp.json.definition.map(function(x) { return x.split(/[\s\+]/).splice(1); });
                var tableCols = rawCols.filter(function(x) { return ('+' + x[0]) == table });
                vm.cols(["nr"].concat(tableCols.map(function(x) { return x[1] })));
                vm.rows(resp.list);
            });

        }
        this.deleteRow = function(row) {
            if (!confirm('are you sure you wish to delete this row?')) { return; }
            return xhr.post("!" + scaffoldEntityToShort(vm.table()) +"-del-json", row).then(function() {
                self.refresh();
            });
        }
        new CrudController("scaffold-entity", vm, options).call(this);
    }
    
    this.view = function(ctrl) {
        var vm = ctrl.vm;

        return ctrl.mount([
                m("h1", vm.table()),
                m("input[type='button'][class='button']", { value: 'add', onclick: ctrl.addRow}),
                m("table", [
                    m("tr", [
                        vm.cols().map(function(col) {
                            return m("td", col)
                        }),
                        m("td", "action")
                    ]),
                    vm.rows().map(function(row) {
                        return m("tr", [
                            vm.cols().map(function(col) {
                                return m("td", row[col] ? row[col]() : '');
                            }),
                            m("td[class='action']", [
                                m("input[type='button'][class='button button-small]", {
                                    value: 'edit',
                                    onclick: ctrl.editRow.bind(row, row)
                                }),
                                m("input[type='button'][class='button button-small button-outline']", {
                                    value: 'delete',
                                    onclick: ctrl.deleteRow.bind(row, row)
                                })
                            ])
                        ])
                    })
                ])
        ]);
    }
}

var ScaffoldTableForm = function() {
    this.controller = function() {

    }
    this.view = function() {

    }
}
routeBuilders.push(function(routes) {
    routes["/scaffold"] = new ScaffoldList();
    routes["/scaffold/:table/add"] = new ScaffoldTableForm();
    routes["/scaffold/:table/edit/:id"] = new ScaffoldTableForm();
    routes["/scaffold/:table"] = new ScaffoldTableList();
});
