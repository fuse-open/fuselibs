

var TreeObservable = require("FuseJS/TreeObservable")

function ComponentStore(source) 
{
    instrument(this, this, [], source)

    var subscribers = []

    this.subscribe = function(callback) {
        subscribers.push(callback);
    }

    function instrument(store, node, path, state)
    {
        for (var k in state) {
            var v = state[k];
            if (v instanceof Function) {
                node[k] = wrapFunction(k, v);
                state[k] = node[k];
            }
            else if (v instanceof Array) {
                node[k] = instrument(store, [], path.concat(k), v);
            }
            else if (v instanceof Object) { 
                node[k] = instrument(store, {}, path.concat(k), v);
            }
            else
            {
                node[k] = v; 
            }
        }

        function wrapFunction(name, func) {
            
            var f = function() {
                func.apply(state, arguments);
                dirty();
            }
            f.$isWrapped = true;

            return f;
        }

        var isDirty = false;

        function dirty() {
            if (isDirty) { return; }
            isDirty = true;
            setTimeout(node.diff, 0);
        }

        node.diff = function() {
            isDirty = false;
            for (var k in state) {
                var v = state[k];
                update(k, v);
            }
        }

        node.$requestChange = function(key, value) {

            var changeAccepted = true;
            if ('$requestChange' in state) {
                changeAccepted = state.$requestChange(key, value);
            }

            if (changeAccepted) {
                state[key] = value;
                set(key, value);
            }

            node.diff();
        }

        function update(key, value)
        {
            if (value instanceof Function) {
                if (!value.$isWrapped) {
                    state[key] = wrapFunction(k, value)
                    set(key, state[key]); 
                }
            }
            else if (value instanceof Array) {
                if (value.length == node[key].length && 'diff' in node[key]) { node[key].diff(); }
                else { set(key, instrument(store, [], path.concat(key), value)); }
            }
            else if (value instanceof Object) {
                if ('diff' in node[key]) { node[key].diff(); }
                else { set(key, instrument(store, {}, path.concat(key), value));  }
            }
            else if (value !== node[key])
            {
                node[key] = value;
                set(key, value);
            }
        }

        function set(key, value) 
        {
            node[key] = value;

            var argPath = path.concat(key, value instanceof Array ? [value] : value);
            TreeObservable.set.apply(store, argPath);

            var msg = {
                operation: "set",
                path: path,
                key: key,
                value: value
            }

            for (var s of subscribers) s.call(store, msg);
        }

        return node;
    }
}

ComponentStore.prototype = Object.create(TreeObservable.prototype);

module.exports = ComponentStore;