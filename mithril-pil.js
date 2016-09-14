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
        var globals = {}
        //move params that start with * to globals
        Object.keys(data).forEach(function(x) {
            if (x[0] == '*') {
                globals[x] = data[x];
                delete data[x];
            }
        });
        var json = JSON.stringify(data);
        if (DEBUG) { console.log({session: session.key, json: json }) }
        var postData = '*Data=' + encodeURIComponent(json);
        if (session.key) {
            postData = postData + '&*Session=' + session.key;
        }
        Object.keys(globals).forEach(function(x) {
            postData = postData + '&' + x + '=' + encodeURIComponent(globals[x]);
        });
        return postData;
    };
    this.post = function(url, data) {
        var req =  m.request({method: "POST", url: "/" + url, data, serialize: serializer});
        if (DEBUG) { req.then(log); }
        return req;
    }

    this.listToProp = function(list,prop) {
        return function(rawJson) {
            if (rawJson.error && rawJson.error == 'timeout') {
                m.route('/login');
            }
            var json=rawJson[prop];
            if (Array.isArray(json) && json[0] && typeof(json[0]) != 'object') {
                list(json);
            } else {
                var newList = json.map(function(x) {
                    var entity = {}
                    Object.keys(x).forEach(function(key) { entity[key] = m.prop(x[key]) });
                    return entity;
                });
                if (list.promise) {
                    list.resolve({list: newList, json: rawJson});
                } else {
                    list(newList);
                }
            }
        }
    }
});

//helper to wrap list/add/del/edit json calls
var CrudController = function(entity, vm, options) {
    return function() {
        var self = this;
        this.refresh = function() {
            var params = options && options.postParams ? options.postParams : {}
            return xhr.post("!" + entity + "-list-json", params).then(xhr.listToProp(vm.list, entity))
        }

        this.add = function() {
            if (vm.validate()) {
                return xhr.post("!" + entity + "-add-json", vm.row)
                    .then(function(json) {
                        vm.clear();
                        self.refresh();
                        return json; //return for next in chain
                    });
            }
        };
        this.del = function(row) {
            return xhr.post("!" + entity +"-del-json", row).then(self.refresh);
        };

        this.refresh();
    };
}

var routeBuilders = [];
