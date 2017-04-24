if (typeof window == 'undefined') (function (g){

    'use strict';

    g.Window = (function () {
        function Window() {
            this.self = this;
            this.window = this;
        }
        return Window;
    })();
    g.window = new g.Window();
    g.self = window;
    g.window = g;

})(this);

require("js/WindowTimers.js");
require("js/EventTarget.js");
require("js/WindowBase64.js");
require("js/File.js");
require("js/XMLHttpRequest.js");
require("js/fetch.js");
require("js/localStorage.js");
require("js/WebSocketAPI.js");

module.exports = window;