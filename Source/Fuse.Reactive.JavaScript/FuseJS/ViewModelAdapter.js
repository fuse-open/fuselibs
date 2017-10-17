var Observable = require("FuseJS/Observable");

exports.adaptView = function(view, viewModule, model) {

	// Dummy method to trigger change detection
	model.__fuse_dirty = function() {}
	function dirty() {
		model.__fuse_dirty();
	}

	function wrapProperty(key) {
		var observable = view[key];
		
		function propChanged() {
			dirty();
		}
		
		observable.addSubscriber(propChanged);

		viewModule.disposed.push(function() {
			observable.removeSubscriber(propChanged);
		})
		
		var initialValue = model[key];

		Object.defineProperty(model, key, {
			get: function() {
				return observable.value;
			},
			set: function(value) {
				observable.setValueExclusive(value, propChanged);
				dirty();
			}
		});
		
		if('_defaultValueCallback' in observable) {
			observable._defaultValueCallback(initialValue);
		}
	}

	var viewProps = Object.getOwnPropertyDescriptors(view);
	for (var key in viewProps) {
		if(key in model
			&& !viewProps[key].enumerable
			&& view[key] instanceof Observable)
		{
			wrapProperty(key);
		}
	}
}