self = this;
(function(self) {
    'use strict';

    self.Blob = function(blobparts, options = {}) {
        if (typeof blobparts === 'string') {
            const length = blobparts.length;
            this._blobparts  = new Uint8Array(length);
            for (let i = 0; i < length; i++) {
                this._blobparts[i] = blobparts.charCodeAt(i);
            }
        } else {
            this._blobparts = blobparts || new ArrayBuffer();
        }
        this._options = options;

        this.type = this._options.type || '';
        this.size = this._blobparts.byteLength || this._blobparts.length || -1;

        this.arrayBuffer = function() {
            if (ArrayBuffer.prototype.isPrototypeOf(this._blobparts))
                return Promise.resolve(this._blobparts);
            return Promise.resolve(this._blobparts.buffer);
        }

        this.bytes = function() {
            return Promise.resolve(this._blobparts);
        }

        this.slice = function(start, length) {
            if (ArrayBuffer.prototype.isPrototypeOf(this._blobparts))
                return Promise.resolve(this._blobparts.slice(start, length));
            return Promise.resolve(this._blobparts.buffer.slice(start, length));
        }

        this.text = function() {
            var view = new Uint8Array(this.arrayBuffer())
            var chars = new Array(view.length)

            for (var i = 0; i < view.length; i++) {
                chars[i] = String.fromCharCode(view[i])
            }
            return Promise.resolve(chars.join(''));
        }
    }
    self.Blob.polyfill = true

})(typeof self !== 'undefined' ? self : this)