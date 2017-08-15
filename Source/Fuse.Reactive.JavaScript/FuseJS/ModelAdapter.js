
function ModelAdapter(mod) {
    for (var k in mod) {
        if (mod[k] instanceof Function) {
            mod[k] = wrap(mod[k]);
        }
    }
    return mod;
}

function wrap(func) {
    var argNames = getArgNames(func);
    var wfunc = function() {
        if (arguments.length !== argNames.length) {
            var model = module.exports.GlobalModel;
            var args = Array.prototype.slice.call(arguments);
            for (var i = arguments.length; i < argNames.length; i++) {
                var dependency = argNames[i];
                if (dependency in model) {
                    args.push(model[dependency]);
                }
                else {
                    args.push(undefined);
                    console.log("Unable to satisfy dependency '" + argNames[i] + "' on '" + func.name + "'");
                }
            }
            return func.apply(Object.create(func.prototype), args);
        }
        else {
            return func.apply(this, arguments);
        }
    }
    wfunc.prototype = func.prototype;
    return wfunc;
}

function getArgNames(func) {  
    return (func + '')
      .replace(/[/][/].*$/mg,'') // strip single-line comments
      .replace(/\s+/g, '') // strip white space
      .replace(/[/][*][^/*]*[*][/]/g, '') // strip multi-line comments  
      .split('){', 1)[0].replace(/^[^(]*[(]/, '') // extract the parameters  
      .replace(/=[^,]+/g, '') // strip any ES6 defaults  
      .split(',').filter(Boolean); // split & filter [""]
}  

module.exports = {
    ModelAdapter: ModelAdapter
};