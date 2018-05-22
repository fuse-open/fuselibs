function debounce(thisArg, func, graceMS, immediate){
    if(graceMS==undefined) graceMS = 16
    if(immediate==undefined) immediate = false
    var timeout = -1
    return function(){
        var args = arguments
        var c = function(){
            timeout = -1
            if(!immediate)
                func.apply(thisArg, args)
        }
        var callNow = immediate && timeout == -1
        clearTimeout(timeout)
        timeout = setTimeout(c, graceMS)
        if(callNow) func.apply(thisArg, args)
    }
}

module.exports = {
    debounce: debounce
}