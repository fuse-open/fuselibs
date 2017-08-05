
/** Adapts the injected 'this' variable into <JavaScript> to a Fuse Model */
function ViewModelAdapter(viewModule, view) {

	var adapter = this;

	// Dummy function to call to invoke change detection
	// Will be replaced by the Model system	
	adapter.__dirty = function() {}

	var props = Object.getOwnPropertyDescriptors(view);
	for (var p in props) {
		if (props[p].enumerable) { continue; }
		wrapProp(p);
	}

	function wrapProp(p) {
		var obs = view[p];
		var privateProp = "__" + p;

		obs.addSubscriber(propChanged);

		viewModule.disposed.push(function() {
			obs.removeSubscriber(propChanged);
		})

		function propChanged() {
			adapter[privateProp] = obs.value;
			adapter.__dirty();
		}

		Object.defineProperty(adapter, p, {
			get: function() {
				return adapter[privateProp];
			},
			set: function(value) {
				adapter[privateProp] = value;
				adapter.__dirty();
				obs.setValueExclusive(value, propChanged);
			}
		})
	}
}

module.exports = ViewModelAdapter;