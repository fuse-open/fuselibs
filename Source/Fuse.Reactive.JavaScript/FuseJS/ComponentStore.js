

var TreeObservable = require("FuseJS/TreeObservable")

function ComponentStore(source) 
{
    instrument(this, this, [], source)

    function instrument(store, node, path, state)
    {
        for (var k in state) {
            var v = state[k];
            if (v instanceof Function) {
                node[k] = wrapFunction(v);
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

        function wrapFunction(func) {
            if (func.$isWrapped) { return func; }

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
                if (v instanceof Function) {
                    node[k] = wrapFunction(v);
                    state[k] = node[k];
                }
                else if (v instanceof Array) {
                    if (v.length == node[k].length && 'diff' in node[k]) { node[k].diff(); }
                    else 
                    {
                        node[k] = instrument(store, [], path.concat(k), v);
                        TreeObservable.set.apply(store, path.concat(k, [node[k]]));
                    }
                }
                else if (v instanceof Object) {
                    if ('diff' in node[k]) { node[k].diff(); }
                    else {
                        node[k] = instrument(store, {}, path.concat(k), v);
                        TreeObservable.set.apply(store, path.concat(k, node[k]));
                    }
                }
                else if (v != node[k])
                {
                    TreeObservable.set.apply(store, path.concat(k, v));
                    node[k] = v;
                }
            }
        }

        return node;
    }
}

ComponentStore.prototype = Object.create(TreeObservable.prototype);

module.exports = ComponentStore;