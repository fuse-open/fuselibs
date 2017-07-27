

var TreeObservable = require("FuseJS/TreeObservable")

function ComponentStore(source) 
{
    instrument(this, null, this, [], source)

    var subscribers = []

    this.subscribe = function(callback) {
        subscribers.push(callback);
    }

    function instrument(store, parentNode, node, path, state)
    {
        for (var k in state) {
            var v = state[k];
            if (v instanceof Function) {
                node[k] = wrapFunction(k, v);
                state[k] = node[k];
            }
            else if (v instanceof Array) {
                node[k] = instrument(store, node, [], path.concat(k), v);
            }
            else if (v instanceof Object) { 
                node[k] = instrument(store, node, {}, path.concat(k), v);
            }
            else
            {
                node[k] = v; 
            }
        }

        var propGetters = {}

        if (!(state instanceof Array)) {
            registerProps(state);
        }

        function registerProps(obj) {

            var descs = Object.getOwnPropertyDescriptors(obj);
            for (var p in descs) {
                if (p === "constructor") { continue; }
                var value = state[p];
                if (value instanceof Function) {
                    console.log("registering method " + p)
                    node[p] = wrapFunction(p, value);
                }
                else if (descs[p].get instanceof Function)
                {
                    console.log("registering property " + p)
                    node[p] = value;
                    propGetters[p] = function() { return state[p]; }
                }
            }

            // Include members from object's prototype chain (to allow ES6 classes)
            var proto = Object.getPrototypeOf(obj);
            if (proto && proto !== Object.prototype) { registerProps(proto); }
        }

        node.evaluateDerivedProps = function()
        {
            for (var p in propGetters) {
                set(p, propGetters[p].call());
            }
            if (parentNode !== null) parentNode.evaluateDerivedProps();
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
            node.evaluateDerivedProps();
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
                else { set(key, instrument(store, node, [], path.concat(key), value)); }
            }
            else if (value instanceof Object) {
                if ('diff' in node[key]) { node[key].diff(); }
                else { set(key, instrument(store, node, {}, path.concat(key), value));  }
            }
            else if (value !== node[key])
            {
                set(key, value);
            }
        }

        function set(key, value) 
        {
            if (node[key] === value) { return; }
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