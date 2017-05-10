// Storage polyfill based on Remy Sharp https://gist.github.com/350433
if (typeof window.localStorage == 'undefined' || typeof window.sessionStorage == 'undefined') (function (window, fuseStorage) {

    'use strict';

    var sessionData = '';

    var Storage = function(type) {

        function setData(data) {
            data = JSON.stringify(data);
            if (type == 'session') {
                sessionData = data;
            } else {
                fuseStorage.writeSync('FuseLocalStorage', data);
            }
        }

        function clearData() {
            if (type == 'session') {
                sessionData = '';
            } else {
                fuseStorage.deleteSync('FuseLocalStorage');
            }
        }

        function getData() {
            if(type == 'session') {
                return JSON.parse(sessionData);
            } else {
                try {
                    return JSON.parse(fuseStorage.readSync('FuseLocalStorage'));
                } catch (e) {
                    return {};
                }
            }
        }

        var data = getData();
        var length = 0;

        function numKeys() {
            var n = 0;
            for (var k in data) {
                if (data.hasOwnProperty(k)) {
                    n += 1;
                }
            }
            return n;
        }

        return {
            clear: function() {
                data = {};
                clearData();
                length = numKeys();
            },
            getItem: function(key) {
                key = encodeURIComponent(key);
                return data[key] === undefined ? null : data[key];
            },
            key: function(index) {
                // not perfect, but works
                var ctr = 0;
                for (var k in data) {
                    if (ctr == index) return decodeURIComponent(k);
                    else ctr++;
                }
                return null;
            },
            removeItem: function(key) {
                key = encodeURIComponent(key);
                delete data[key];
                setData(data);
                length = numKeys();
            },
            setItem: function(key, value) {
                key = encodeURIComponent(key);
                data[key] = String(value);
                setData(data);
                length = numKeys();
            },
            get length() {
                return length;
            },
        };
    };

    Storage.prototype.constructor = Storage;
    window.Storage = Storage;
    window.localStorage = new Storage('local');
    //window.sessionStorage = new Storage('session');

})(window, require('FuseJS/Storage'));

localStorage = window.localStorage;