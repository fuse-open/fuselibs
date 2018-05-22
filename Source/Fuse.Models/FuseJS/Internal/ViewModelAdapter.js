var Observable = require("FuseJS/Observable");

exports.adaptView = function(view, viewModule, model) {
	// Dummy method to trigger change detection
	model.__fuse_dirty = function() {}
	function dirty() {
		model.__fuse_dirty();
	}

	var observables = []
	function mapOnProperties(){

		function format(){
			var out = {}
			for(var i=0;i<arguments.length;i++){
				out[observables[i].name] = arguments[i]
			}
			return out
		}

		function handler(result){
			model["onProperties"].call(model, result.value)
		}
		
		var first = observables[0].observable
		var obs = first.combineLatest.apply(first, observables.slice(1).map(ob => ob.observable).concat(format))
		obs.addSubscriber(handler);

		viewModule.disposed.push(function() {
			obs.removeSubscriber(handler);
		})
	}

	// If the view key is already an observable
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

	var viewKeys = Object.getOwnPropertyNames(view);
	for (var i in viewKeys) {
		var key = viewKeys[i];
		var descriptor = Object.getOwnPropertyDescriptor(view, key);
		if(!descriptor.enumerable && view[key] instanceof Observable) {
			observables.push({name:key, observable:view[key]})
			if(!(key in model)) continue;
			wrapProperty(key);
		}
	}
	if("onProperties" in model && observables.length>0)
		mapOnProperties()
}