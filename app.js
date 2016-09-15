m.if = function (bool, elem){
  if(bool){
    return elem
  }
}

var navigation = function() {
    this.controller = function() {
        this.logout = function() {
            session.setKey(null);
            session.setName(null);
            m.route("/login")
        }
    }
    this.view = function(ctrl) {
        return [
            m.if(session.key,[
                m("div[class='column column-50'][id='navbar']",[
                    m("a", {href: '/todo',  text:"Todos", config: m.route}),
                    m("a", {href: '/scaffold',  text:"Admin", config: m.route}),
                    m("a", {href: '/logout', onclick: ctrl.logout, text:"Log Out", config: m.route})
                ]),
                m("div[class='column column-50']", m("h6", "Welcome back " + session.name))
            ])
        ];
              
    }
}

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
        this.done = function(val) {
            console.log(val);
        }
    }
    
    this.vm = vm;
    
    this.view = function(c) {
        return [
            m("input[type='text'][placeholder='todo']",{
                onkeypress: function(e) {
                    m.withAttr('value', vm.row.desc)(e);
                    if (e.keyCode == 13) {
                        c.add();
                    }
                },
                value: vm.row.desc()
            }),
            m("button", {onclick: c.add}, "Add"),
            m("table", [
                vm.list().map(function(task, index) {
                    return m("tr", [
                        m("td", [
                            m("input[type=checkbox]", {checked: task.done(), onclick: m.withAttr("checked", function(val) { task.done(val?1:0); c.update(task); }) })
                        ]),
                        m("td", {style: {textDecoration: task.done() ? "line-through" : "none"}}, task.desc()),
                        m("td", m("input[type='button'][class='button button-small button-outline'][value='delete']", {onclick: c.del.bind(task, task)})),
                    ]);
                })
            ])
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
                    session.setName(vm.username());
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
            m("input[type='text']", { onchange: m.withAttr("value", vm.username) }),
            m("label", "password"),
            m("input[type='password']", { onchange: m.withAttr("value", vm.password) }),
            m("button", { onclick: c.login }, "Log In")
        ];
    };
}



routeBuilders.push(function(routes) {
    routes["/todo"] = new todo();
})
