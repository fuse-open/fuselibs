/* An internal module for now to provide diagnostics reporting to the standard Fuse.Diagnostics */

var impl = require("FuseJS/DiagnosticsImpl")

exports.deprecated = function(msg) {
	//FEATURE: the source line number or stack might be nice here (It's hard to figure out where the
	//user code starts though)
	impl.report( "Deprecated", msg )
}
