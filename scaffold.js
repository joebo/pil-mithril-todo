/*global m CrudController xhr routeBuilders */
//converts +Todo to todo

var ScaffoldOptions = {
    buildTableCellHook : null,
    buildInputHook : null
};

var scaffoldEntityToShort = function(entity) {
    if (entity[0] == '+') {
        entity = entity.slice(1);
    }
    return entity.toLowerCase();
}

var ScaffoldList = function() {
     var vm = new function() {
         this.list =  m.prop([]);
     };

    this.controller = function() {
        new CrudController("scaffold-entities", vm).call(this);
    };

    this.view = function(c) {
        return c.mount([
            m("h1", "Entities"),
            m("ol",[
                vm.list().map(function(entity) {
                    return m("li", [
                        m("a", { href: "/scaffold/" + entity, text: entity, config: m.route })
                    ]);
                })
             ])
        ]);
    };
};

//base controller for scaffolding a table
var ScaffoldTableController = function(entity, resource, vm, options, id) {
    return function() {
        var self = this;
        
        vm.list =  m.deferred();
        vm.cols = m.prop([]);
        vm.table = m.prop(entity);
        vm.rows = m.prop([]);
        vm.definition = m.prop([]);
        vm.links = {};
        
        this.beforeRefresh = function() {
            vm.row = null; //clear out the current row
            vm.list = m.deferred();
            vm.list.promise.then(function(resp) {
                var table = m.route.param("table");
                var rawCols = resp.json.definition.map(function(x) { return x.split(/[\s\+]/).splice(1); });
                var tableCols = rawCols.filter(function(x) { return ('+' + x[0]) == table; });
                vm.cols(["nr"].concat(tableCols.map(function(x) { return x[1]; })));
                vm.definition([["nr", "Disabled"]].concat(tableCols.map(function(x) { return x.splice(1); })));
                vm.rows(resp.list);
                //editing/adding and no row found, create vm
                if (resp.list.length == 0) {
                    var row = {};
                    vm.cols().forEach(function(x) {
                        row[x] = m.prop("");
                    });
                    vm.row = row;
                }

                //picklists
                vm.links = resp.json.links;
            });

        };
        new CrudController(resource, vm, options).call(this);
    };
};

var ScaffoldTableList = function() {
    var vm = { };
    this.controller = function(args) {
        var self = this;

        var table = (args && args.table) ? args.table : m.route.param("table");
        var options = {
            postParams: { "*Entity" : table }
        };

        new ScaffoldTableController(table, "scaffold-entity", vm, options).call(this);
        

        this.addRow = function() {
            m.route('/scaffold/' + vm.table() + '/add');
        };
        this.editRow = function(row) {
            m.route('/scaffold/' + vm.table() + '/edit/' + row.nr());
        };
       
        this.deleteRow = function(row) {
            if (!confirm('are you sure you wish to delete this row?')) { return null; }
            return xhr.post("!" + scaffoldEntityToShort(vm.table()) +"-del-json", row).then(function() {
                self.refresh();
            });
        };
        this.buildTableCell = function(row, col) {
            var val = row[col] ? row[col]() : '';
            if (row[col+'-gui']) {
                val = row[col+'-gui']();
            }
            var cell = m("span", val);
            if (ScaffoldOptions.buildTableCellHook) {
                cell = ScaffoldOptions.buildTableCellHook(cell, {table:table,row:row,col:col});
            }
            return m("td", cell);
        };
    };
    
    this.view = function(ctrl) {
        return ctrl.mount([
                m("h1", vm.table()),
                m("input[type='button'][class='button']", { value: 'add', onclick: ctrl.addRow}),
                m("table", [
                    m("tr", [
                        vm.cols().map(function(col) {
                            return m("td", col);
                        }),
                        m("td", "action")
                    ]),
                    vm.rows().map(function(row) {
                        return m("tr", [
                            vm.cols().map(function(col) { return ctrl.buildTableCell(row, col); }),
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
                        ]);
                    })
                ])
        ]);
    };
};

// componentOptions.
var ScaffoldTableForm = function(componentOptions) {
    var vm = {
        id: m.prop("")
    };
    componentOptions = componentOptions || {};
    
    this.controller = function(args) {
        var self = this;

        
        var table = (args && args.table) ? args.table : m.route.param("table");
        var id = (args && args.id) ? args.id : m.route.param("id");

        var options = {
            postParams: { "*Entity" : table, "*Nr": id }
        };

        new ScaffoldTableController(table, "scaffold-entity-row", vm, options, id).call(this);

        this.buildInput = function(def) {
            var rows = vm.rows();
            if (vm.row == undefined && rows.length > 0) {
                vm.row = rows[0];
            }
            var isDisabled = def.indexOf('Disabled') >= 0;
            var isText = def.indexOf('Text') >= 0;
            var isNumber = def.indexOf('Number') >= 0;
            var isRequired = def.indexOf('Need') >= 0;
            var isLink = def.indexOf('Link') >= 0;
            
            var config = { };
            if (isDisabled) {
                config.disabled = "disabled";
            }
            var col = def[0];
            var vmcol = vm.row[col] ? vm.row[col] : '';

            if (vmcol) {
                config.onchange = m.withAttr("value", vmcol);
                config.value = vmcol();
            }
            if (isLink) {
                var linkTable = def[def.indexOf('Link') +1];
                var options = vm.links['+' + linkTable];
                if (!options) {
                    console.log('no options found for '+ linkTable);
                } else {
                    var optionNodes = options.map(function(option) {
                        var optionConfig =  { value: option.key, text: option.text };
                        if (option.key == config.value) {
                            optionConfig.selected = "selected";
                        }
                        return m("option", optionConfig);
                    });
                }
                var el = m("select", config, [
                    m("option"),
                    optionNodes
                ]);
            } else {
                var el = m("input[type='text']", config);
            }
            if (componentOptions.buildInputHook) {
                el = componentOptions.buildInputHook(el, {table: table, col: col, row: vm.row, id: id});
            }
            if (ScaffoldOptions.buildInputHook) {
                el = ScaffoldOptions.buildInputHook(el, {table: table, col: col, row: vm.row, id: id});
            }

            return el;
        };

        this.save = function() {
            console.log(JSON.stringify(vm.row));
            var method = vm.row.nr() ? 'update' : 'add';
            return xhr.post("!" + scaffoldEntityToShort(vm.table()) +"-" + method +"-json", vm.row).then(function() {
                self.afterSave();
            });
        };

        this.afterSave = function() {
            m.route("/scaffold/" + vm.table());
        };
    };

    this.view = function(ctrl) {
        return ctrl.mount([
            m("h1", vm.table()),
            m("form[class='scaffold-form']", {id:vm.table()},
              m("fieldset", 
                vm.definition().map(function(col) {
                    return [
                        m("label", col[0]),
                        ctrl.buildInput(col)
                    ];
                })
               )
             ),
            m("input[type='button'][class='button']", { value: "Save", onclick: ctrl.save })
        ]);
    };
}
routeBuilders.push(function(routes) {
    routes["/scaffold"] = new ScaffoldList();
    routes["/scaffold/:table/add"] = new ScaffoldTableForm();
    routes["/scaffold/:table/edit/:id"] = new ScaffoldTableForm();
    routes["/scaffold/:table"] = new ScaffoldTableList();
});

