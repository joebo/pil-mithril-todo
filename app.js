/*global m */
var DEBUG = 0;
var session = new (function() {
    this.key = (typeof sessionStorage != 'undefined') ? sessionStorage.getItem('sessionKey') : '';
    this.setKey = function(value) {
        if (typeof sessionStorage != 'undefined') sessionStorage.setItem('sessionKey', value);
        this.key = value;
    };
});

//helper to serialize ajax calls and do some logging
var xhr = new (function() {
    var log = function(value) {
        console.log(value);
        return value;
    }
    var serializer = function(data) {
        var json = JSON.stringify(data);
        if (DEBUG) { console.log({session: session.key, json: json }) }
        var postData = '*Data=' + encodeURIComponent(json);
        if (session.key) {
            postData = postData + '&*Session=' + session.key;
        }
        return postData;
    };
    this.post = function(url, data) {
        var req =  m.request({method: "POST", url: "/" + url, data, serialize: serializer});
        if (DEBUG) { req.then(log); }
        return req;
    }
});


var todo = function() {
     var Todo = function(data) {
         this.desc = m.prop(data.desc);
         this.done = m.prop(false);
         this.nr = m.prop(data.nr);
     };

    var vm = {
        list: m.prop([]),
        description: m.prop("")
    };

    this.vm = vm;
    
    this.controller = function() {
        var self = this;
        this.refresh = function() {
            return xhr.post("!todo-list-json", {}).then(function(json) {
                vm.list(json.todos.map(function(x) { return new Todo(x) }));
            });
        }

        this.add = function() {
            if (vm.description()) {
                return xhr.post("!todo-add-json", {desc: vm.description})
                    .then(function(json) {
                        vm.description("");
                        self.refresh();
                        return json; //return for next in chain
                    });
            }
        };
        this.del = function(task) {
            return xhr.post("!todo-del-json", {nr: task.nr}).then(self.refresh);
        };

        this.refresh();
    };


    this.view = function(c) {
        return [
            m("input", {onchange: m.withAttr("value", vm.description), value: vm.description()}),
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



