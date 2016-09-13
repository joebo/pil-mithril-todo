var todo = function() {
    var vm = new function() {
        this.list =  m.prop([]);
        this.row = {
            desc: m.prop("")
        };
        this.validate = function() { return true; }
        this.clear = function() { this.row.desc(""); }
    };

    this.controller = function() {
        new CrudController("todo", vm).call(this);
    }
    
    this.vm = vm;
    
    this.view = function(c) {
        return [
            m("input", {onchange: m.withAttr("value", vm.row.desc), value: vm.row.desc()}),
            m("button", {onclick: c.add}, "Add"),
            m("table", [
                vm.list().map(function(task, index) {
                    return m("tr", [
                        m("td", [
                            m("input[type=checkbox]", {onclick: m.withAttr("checked", task.done), checked: task.done()})
                        ]),
                        m("td", {style: {textDecoration: task.done() ? "line-through" : "none"}}, task.desc()),
                        m("td", m("button", {onclick: c.del.bind(task, task)}, "delete")),
                    ]);
                })
            ]),
            m("br"),
            m("br"),
            m("a", { href: "/scaffold", text: "scaffold", config: m.route })
        ];
    };
}

var login = function() {
    var msg = m.prop("Welcome, please log in below.");

    var vm = {
        username : m.prop(""),
        password : m.prop("")
    };

    this.vm = vm;
    this.msg = msg;

    this.controller = function() {
        this.login = function() {
            return xhr.post("!user-auth",vm).then(function(json) {
                if (json.session) {
                    session.setKey(json.session);
                    m.route("/todo");
                }
                else {
                    msg("invalid username / password");
                    //console.log(msg());
                }
            });
        };
    };

    this.view = function(c) {
        return [
            m("div", msg()),
            m("label", "username"),
            m("input", { onchange: m.withAttr("value", vm.username) }),
            m("label", "password"),
            m("input[type='password']", { onchange: m.withAttr("value", vm.password) }),
            m("button", { onclick: c.login }, "Log In")
        ];
    };
}



routeBuilders.push(function(routes) { routes["/todo"] = new todo(); })
