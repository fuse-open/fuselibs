/*
	Refer to <fuse-docs/articles/fusejs/observable-api.md> for documentation of end-user APIs.
*/

/* ----- Observable ------

	Message API:
	
		The format of all messages is:
		
			[object, operation, origin, args...]
		
		The arguments to individual messages:
		
			add [value]
			clear []
			insertAll [index, valuesArray]
			insertAt [index, value]
			newAll [valuesArray]
			newAt [index, value, oldValue]
			removeAt [index, value]
			removeRange [index, count, removeValuesArray]
			set [value]
			failed [message]
				- this implies a "clear" as well. 
				- any other message following clears the failed state
*/

var Diagnostics
try {
	Diagnostics = require("FuseJS/Diagnostics")
} catch(e) {
	//to support the nodeJS based tests
	Diagnostics = {
		deprecated: function() { }
	}
}
var deprecatedMsg = {}

/*
	Creates a new observable.
		Observable([initial value(s)])
		Observable(function() { ... })
*/
var Observable = function()
{
	if ((arguments.length === 1) && (arguments[0] instanceof Function)) {
		return new FunctionObservable(arguments[0])
	} else {
		return new ValueObservable(arguments)
	}
}

function ObservableCtor() {
	this._origin = Observable._createOrigin()
	this._subscribers = [];
	this._isProxy = false
	this._values = []
	this._failed = undefined //stores last failed message if failed
}

Observable.prototype._isOrigin = function(origin) {
	return origin === this._origin
}

//needed to ensure messages are generated again for a test
Observable._testResetDeprecated = function() {
	deprecatedMsg = {}
}

//each new observable needs an origin. Negatives are used here as a positive count is used
//in Scripting/Observable.uno -- it's not clear on how else these can be unified
var originCounter = -2;
Observable._createOrigin = function() {
	return --originCounter
}

/*
	A dervied class handling the "value" observables
*/
function ValueObservable(values) {
	ObservableCtor.call(this)
	this._values = Array.prototype.slice.call(values)
	if (!this._values) { 
		this._values = []
	}
}
ValueObservable.prototype = Object.create(Observable.prototype)
ValueObservable.prototype.constructor = ValueObservable

/*
	A derived class used to deal with proxying Observable values.
*/
function ProxyObservable() {
	ObservableCtor.apply(this, arguments)
	this._isProxy = true;
};
ProxyObservable.prototype = Object.create(Observable.prototype)
ProxyObservable.prototype.constructor = ProxyObservable

Observable.prototype._watchSource = function(source, callback, suppressCallback) {
	var self = this
	//TODO: remove need for this wrapper, this doesn't seem safe anyway (why would the callback
	//have the "this" of the object on which _watchSource is called?
	var callbackProxy = function() {
		callback.apply(self, arguments)
	}
	
	return this._addSubscriptionWatcher( function() {
		source.addSubscriber(callbackProxy, suppressCallback)
	}, function() {
		source.removeSubscriber(callbackProxy)
	})
}

Observable.prototype._unwatchSource = function(watchSourceId) {
	this._removeSubscriptionWatcher(watchSourceId)
}

/*
	@param sigType
		1 = (value)
		2 = (value, index)
		3 = (value, replaceValue)
		4 = (value, index, replaceValue)
		
*/
Observable.prototype._proxyFrom = function(source, mapFunc, clearMap, sigType, suppressInitial) {
	var needsIndex = sigType == 2 || sigType == 4
	
	if (sigType <1 || sigType >4) {
		throw new Error( "Invalid sigType to _proxyFrom")
	}
	
	function mapValue(value, index, replaceValue) {
		if (sigType == 1) {
			return mapFunc(value)
		} else if (sigType == 2) {
			return mapFunc(value, index)
		} else if (sigType == 3) {
			return mapFunc(value, replaceValue)
		} else {
			return mapFunc(value, index, replaceValue)
		}
	}
	
	var self = this
	function clearMapAll() {
		if (clearMap) { 
			for (var i = 0; i < self.length; i++) { 
				clearMap(self._values[i]); 
			}
		}
	}

	var res = {}
	res.watchSourceId = self._watchSource(source, function(src, op, origin, p1, p2) {
		if (self._isOrigin(origin))
		{
			return
		}
		
		if (op === "add")
		{
			self.add(mapValue(p1, this.length, undefined), source._origin);
		}
		else if (op === "clear")
		{
			clearMapAll();
			self.clear(source._origin);
		}
		else if (op === "failed")
		{
			self.failed(p1, source._origin);
		}
		else if (!needsIndex && op === "insertAll")
		{
			var index = p1;
			var values = p2;

			var res = new Array(values.length);
			for (var i = 0; i < values.length; i++)
			{
				res[i] = mapValue(values[i], index + i, undefined);
			}
			self.insertAll(index, res, source._origin);
		}
		else if (!needsIndex && op === "insertAt")
		{
			self.insertAt(p1, mapValue(p2, p1, undefined), source._origin);
		}
		else if(!needsIndex && op === "newAll")
		{
			clearMapAll()
			var values = p1
			
			var res = new Array(values.length)
			for (var i=0; i < values.length; ++i)
			{
				res[i] = mapValue(values[i], i, undefined)
			}
			self.replaceAll(res, source._origin)
		}
		else if (op === "newAt")
		{
			if (clearMap) { clearMap(self._values[p1]); }
			self.replaceAt(p1, mapValue(p2, p1, undefined), source._origin);
		}
		else if (!needsIndex && op === "removeAt")
		{
			if (clearMap) { clearMap(self._values[p1]); }
			self.removeAt(p1, source._origin);
		}
		else if (!needsIndex && op === "removeRange")
		{
			if (clearMap) { for (var i = p1; i < p1+p2; i++) { clearMap(self._values[i]);} }
			self.removeRange(p1, p2, source._origin)
		}
		else if (op === "set")
		{
			if (clearMap && self._values.length > 0) { clearMap(self.value); }
			self.setValueWithOrigin(mapValue(p1, 0, self.value), source._origin);
		}
		else
		{
			// Fallback - assume all is dirty (for "newAll" and also several for needsIndex)
			// The insert/remove and refresh cases are handled here when indices are needed
			clearMapAll();

			var r = [];
			for (var i = 0; i < src.length; ++i)
			{
				r.push(mapFunc(src.getAt(i), i, undefined));
			}
			self.replaceAll(r, source._origin);
		}
	}, suppressInitial)
	
	if (clearMap) {
		res.watchCleanupId = self._addSubscriptionWatcher( function() {}, clearMapAll );
	}
	
	return res
}

Observable.prototype._unproxyFrom = function( proxyId ) {
	this._unwatchSource(proxyId.watchSourceId)
	if (proxyId.watchCleanupId) {
		this._unwatchSource(proxyId.watchCleanupId)
	}
}

function Identity(x)
{
	return x;
}

/*
	A wrapper to ProxyObserveList
	
		ProxyObseve( sources..., callback )
		=>
		ProxyObserveList( sources, callback, undefined )
*/
function ProxyObserve()
{
	var callback = arguments[arguments.length-1];
	if (!(callback instanceof Function)) {
		throw new Error("Last argument to ProxyObserve() must be a function");
	}

	var sources = Array.prototype.slice.call(arguments, 0, arguments.length-1);

	for (var i = 0; i < sources.length; i++) {
		if (!(sources[i] instanceof Observable)) {
			throw new Error("All (except the last) arguments to ProxyObserve() must be of type Observable");
		}
	}

	return ProxyObserveList(sources, callback);
}

/**
	Creates a proxy observable to several source observables.
	
	@param sources the list of source observables to observe
	@param callback called with each change message from the sources
	@param endSubscriptionCallback called when the subscription to the source has ended
*/
function ProxyObserveList(sources, callback, endSubscriptionCallback)
{
	var res = new ProxyObservable();

	for (var i=0; i < sources.length; ++i) {
		res._watchSource(sources[i], callback)
	}
	if (endSubscriptionCallback) {
		res._addSubscriptionWatcher( function() {}, endSubscriptionCallback)
	}

	return res;
}


/*
	A derived class that handles function() observables.
*/
function FunctionObservable(func) {
	ObservableCtor.call(this)
	this._isProxy = true;
	
	var obs = this;
	obs._values = [];
	obs._func = arguments[0];
	obs._dependencies = [];

	var obsFunc = arguments[0];

	var evaluating = false;

	var depChanged = function()
	{
		if (!evaluating)
		{
			obs.value = evaluate();
		}
	};

	var evaluate = function()
	{
		evaluating = true;
		var oldDependencies = obs._dependencies;
		var newDependencies = [];
		obs._dependencies = newDependencies;

		_dependencyStack.push(obs);

		var res;
		try
		{
			res = obsFunc.apply(obs);
		}
		finally
		{
			_dependencyStack.pop(obs);
		}

		oldDependencies.forEach(function(x) {
			var i = newDependencies.indexOf(x);
			if (i === -1) {
				x.removeSubscriber(depChanged);
			}
		});

		newDependencies.forEach(function(x) {
			var i = oldDependencies.indexOf(x);
			if (i === -1) {
				x.addSubscriber(depChanged);
			}
		});

		// Call again to get clean values
		res = obsFunc.apply(obs);

		evaluating = false;

		return res;
	};


	obs._addSubscriptionWatcher( function() {
		depChanged();
	}, function() {
		obs._dependencies.forEach(function (x) {
			x.removeSubscriber(depChanged);
		});
	})
};
FunctionObservable.prototype = Object.create(Observable.prototype)
FunctionObservable.prototype.constructor = FunctionObservable

//tracks observable dependencies during FunctionObservable evaluation
var _dependencyStack = [];

Observable.prototype.depend = function()
{
	if (_dependencyStack.length === 0) return;
	var current = _dependencyStack[_dependencyStack.length-1];
	if (current === this) return;

	var i = current._dependencies.indexOf(this);
	if (i === -1)
	{
		current._dependencies.push(this);
	}
};

Observable.prototype._assertNoDependence = function(x)
{
	if (_dependencyStack.length === 0) return;

	throw new Error("Observable(): cannot create new observables while evaluating dependency function :" + x);
};

Observable.prototype.onValueChanged = function(module, callback) {
	// Support old syntax where module is not provided (no cleanup can be done!)
	if (!callback) {
		//DEPRECATED: 2016-07-20
		Diagnostics.deprecated( "onValueChanged now expects a `module` as the first parameter. " + 
			"Without it there will be a leak." )
		callback = module
		module = null
	}
	
	var subscriber = function(obs, cmd, origin, value) { 
		//for simplicity just update the value always, see https://github.com/fusetools/fuselibs/issues/3556
		callback(obs.value);
	};
	
	if (!module) {	
		this.addSubscriber( subscriber );
	} else {
		this._addDisposableSubscriber( module, subscriber )
	}
};

Observable.prototype.subscribe = function(module) {
	this._addDisposableSubscriber( module, function() {} )
};

Observable.prototype._addDisposableSubscriber = function(module, subscriber) {
	if ((!module) || (!("disposed" in module))) { 
		throw new Error("must provide a module argument"); 
	}

	var self = this;
	
	self.addSubscriber(subscriber);
	
	module.disposed.push(function() {
		self.removeSubscriber(subscriber);
	});
}

Observable.prototype.toArray = function()
{
	this.depend();
	return this._values.slice();
};


function combineGetSources(self, args)
{
	if (args.length < 1) {
		throw new Error("Observable.combine*() must have at least one argument");
	}
	var src = (args[0] instanceof Array) ? args[0] : Array.prototype.slice.call(args, 0, args.length-1);
	src.unshift(self);
	return src;
}

Observable.prototype.combine = function() 
{
	var sources = combineGetSources(this, arguments);
	var mapFunc = arguments[arguments.length-1];

	var res = ProxyObserveList(sources, function() {
		var values = [];
		for (var i = 0; i < sources.length; i++) {
			var src = sources[i]
			
			var f = src.getFailure()
			if (f) {
				this.failed(f)
				return
			}	
			
			values.push(src.value);
		}
		var res = mapFunc.apply(res, values);
		if (typeof res != 'undefined') this.value = res;
	});
	return res;
};

Observable.prototype.combineLatest = function() 
{
	var sources = combineGetSources(this, arguments);
	var mapFunc = arguments[arguments.length-1];

	var combined = ProxyObserveList(sources, function() {
		var values = [];
		for (var i = 0; i < sources.length; i++) {
			var src = sources[i]
			
			var f = src.getFailure()
			if (f) {
				combined.failed(f)
				return;
			}
			
			if (src.length === 0) { 
				combined.clear()
				return; 
			}
			values.push(src.value);
		}
		var res = mapFunc.apply(res, values);
		if (typeof res != 'undefined') combined.value = res;
	});
	return combined;
};

Observable.prototype.combineArrays = function(sources, mapFunc) 
{
	var sources = combineGetSources(this, arguments);
	var mapFunc = arguments[arguments.length-1];
	
	var res = ProxyObserveList(sources, function() {
		var values = [];
		for (var i = 0; i < sources.length; i++) {
			var src = sources[i]
			
			var f = src.getFailure()
			if (f) {
				this.failed(f)
				return
			}	
			
			values.push(src._values);
		}

		var arr = mapFunc.apply(res, values);
		if (arr instanceof Array) {
			this.replaceAll(arr);
		}
	});
	return res;
};

var Subscriber = function(version, callback)
{
	this.version = version
	this.callback = callback
	this.active = true
}

Subscriber.prototype.post = function(args)
{
	this.callback.apply(null, args)
}

Observable.prototype.addSubscriber = function(s, suppressInitialCallback)
{
	this._addSubscriber( new Subscriber(2, s), suppressInitialCallback)
}

Observable.prototype._addSubscriber = function(sub, suppressInitialCallback)
{
	var self = this;

	this._beginSubscriptions();

	if (!suppressInitialCallback)
	{
		if (this._failed)
		{
			messageQueue.push(function() { sub.post([self, "failed", self._origin, self._failed]); });
		}
		else if (this._values.length === 1)
		{
			messageQueue.push(function() { sub.post([self, "set", self._origin, self._values[0]]); });
		}
		else if (this._values.length === 0)
		{
			messageQueue.push(function() { sub.post([self, "clear", self._origin]); });
		}
		else
		{
			messageQueue.push(function() { sub.post([self, "newAll", self._origin, self._values.slice(0)]); });
		}
		PumpMessages();
	}
	
	this._subscribers.push(sub);
};

Observable.prototype._getSubscriberIndex = function(s)
{
	for (var i=0; i < this._subscribers.length; ++i)
	{
		if (this._subscribers[i].callback === s)
			return i;
	}
	return -1;
}

Observable.prototype.removeSubscriber = function(s)
{
	var i = this._getSubscriberIndex(s);
	if (i == -1)
		return;
	//prevent late messages from being sent
	this._subscribers[i].active = false
	this._subscribers.splice(i, 1);

	if (this._subscribers.length === 0)
	{
		this._endSubscriptions();
	}
};

var _watcherId = 0
/*
	This creates a callback that is called when the subscriptions to this Observable start/end.
	This is when a proxy should subscribe to the observed sources.
*/
Observable.prototype._addSubscriptionWatcher = function(begin, end) {
	if (!this._subscriptionWatchers) {
		this._subscriptionWatchers = []
	}

	var watcherId = ++_watcherId
	this._subscriptionWatchers.push( { begin: begin, end: end, watcherId: watcherId } )
	if (this._beganSubscriptions) {
		begin()
	}
	
	return watcherId
}

Observable.prototype._removeSubscriptionWatcher = function(watcherId) {
	var sw = this._subscriptionWatchers
	if (!sw) {
		return
	}
	for (var i=0; i < sw.length; ++i ) {
		var tsw = sw[i]
		if (tsw.watcherId === watcherId) {
			sw.splice(i,1)
			if (this._beganSubscriptions) {
				tsw.end()
			}
			return
		}
	}
}

Observable.prototype._beginSubscriptions = function() {
	if (this._beganSubscriptions) {
		return
	}
	this._beganSubscriptions = true
	
	if (this.beginSubscriptions != Observable.prototype.beginSubscriptions) {
		if (!deprecatedMsg.beginSubscriptions) {
			Diagnostics.deprecated( "`.beginSubscriptions` is deprecated. There is currently no replacement, please contact Fuse for how to migrate your code.")
			deprecatedMsg.beginSubscriptions = true
		}
		this.beginSubscriptions()
	}
	
	var sw = this._subscriptionWatchers
	if (sw) {
		var copy = sw.slice()
		for (var i=0; i < copy.length; ++i ) {
			copy[i].begin()
		}
	}
}

Observable.prototype._endSubscriptions = function() {
	this._beganSubscriptions = false
	
	if (this.endSubscriptions != Observable.prototype.endSubscriptions) {
		if (!deprecatedMsg.endSubscriptions) {
			Diagnostics.deprecated( "`.endSubscriptions` is deprecated. There is currently no replacement, please contact Fuse for how to migrate your code.")
			deprecatedMsg.endSubscriptions = true
		}
		this.endSubscriptions()
	}
	
	var sw = this._subscriptionWatchers
	if (!sw) {
		return
	}
	for (var i=0; i < sw.length; ++i ) {
		sw[i].end()
	}
}

/*
	Protected.
	When overridden in a derived observer type, this creates subscriptions with
	all observed sources.
	DEPRECATED: 2016-12-28 there is no public API for this now, it should not be required
*/
Observable.prototype.beginSubscriptions = function() { }

/*
	Protected.
	When overridden in a derived observer type, this removes subscriptions with
	all observed sources.
	DEPRECATED: 2016-12-28 there is no public API for this now, it should not be required
*/
Observable.prototype.endSubscriptions = function() { }

/*
	Gets the value at a specific index.
	Syntax: observable.getAt(index)
*/
Observable.prototype.getAt = function(index)
{
	this.depend();
	return this._values[index];
};

/*
	Replaces the value at a specific index.
	Syntax: observable.replaceAt(index, value);
*/
Observable.prototype.replaceAt = function(index, value, _origin)
{
	if (index < 0 || index >= this._values.length)
		throw new Error("replaceAt(" + index + ") index out-of-bounds: length=" + this._values.length);
	var oldValue = this._values[index];
	this._values[index] = value;
	this._queueMessage(this, "newAt", _origin, index, value, oldValue);
};

/*
	Inserts a value at a specific index.
	Syntax: observable.insertAt(index, value);
*/
Observable.prototype.insertAt = function(index, value, _origin)
{
	if (index == this._values.length)
	{
		this.add(value, _origin);
	}
	else
	{
		this._values.splice(index, 0, value);
		this._queueMessage(this, "insertAt", _origin, index, value);
	}
};

/**
	Marks a failure on the Observable. This clears any values and propagates the failures to 
	any listeners and/or maps.
*/
Observable.prototype.failed = function(message, _origin) {
	this._values = []
	this._failed = message
	this._queueMessage(this, "failed", _origin, message);
};

Observable.prototype._clearFailed = function(_origin) {
	if (!this._failed) {
		return
	}
	
	this._failed = undefined
}

/**
	@return the current failure message, or undefined if not failed
*/
Observable.prototype.getFailure = function() {
	return this._failed
}

Observable.prototype.onFailed = function(module, onFailedCallback, onFailedResolvedCallback ) {
	this._addDisposableSubscriber( module, function(obs, cmd, origin, value) {
		if (cmd === "failed") {
			onFailedCallback(value)
		} else {
			if (onFailedResolvedCallback) {
				onFailedResolvedCallback()
			}
		}
	})
}

Observable.prototype.replaceAll = function(newValues, _origin)
{
	if (newValues instanceof Observable)
	{
		newValues = newValues._values;
	}

	if (!(newValues instanceof Array))
	{
		throw new Error("replaceAll(): argument must be an array");
	}

	if (!newValues)
	{
		newValues = [];
	}

	this._values = newValues.slice();

	if (this._values.length === 1)
	{
		this._queueMessage(this, "set", _origin, this._values[0]);
	}
	else if (this._values.length === 0)
	{
		this._queueMessage(this, "clear", _origin);
	}
	else
	{
		this._queueMessage(this, "newAll", _origin, this._values.slice(0));
	}
};

Observable.prototype.refreshAll = function(newValues, comparefunc, updateFunc, mapFunc)
{
	if (newValues instanceof Observable)
	{
		newValues = newValues._values;
	}

	if (!(newValues instanceof Array))
	{
		throw new Error("refreshAll(): argument must be an array or observable");
	}

	if (!newValues)
	{
		newValues = [];
	}

	if (comparefunc === undefined)
		comparefunc = function(x, y) { return x === y; };

	for (var i = 0; i < Math.min(newValues.length, this._values.length); i++)
	{
		var a = this._values[i];
		var b = newValues[i];

		if (!comparefunc(a, b))
		{
			if (mapFunc !== undefined)
				this.replaceAt(i, mapFunc(b));
			else
				this.replaceAt(i, b);
		}
		else
		{
			if (updateFunc !== undefined)
				updateFunc(a, b);
		}
	}

	for (var i = this._values.length; i < newValues.length; i++)
	{
		if (mapFunc !== undefined)
			this.add(mapFunc(newValues[i]));
		else
			this.add(newValues[i]);
	}

	if (newValues.length < this._values.length)
		this.removeRange(newValues.length, this._values.length - newValues.length);
};

Observable.prototype.add = function(x, _origin)
{
	this._values.push(x);
	this._queueMessage(this, "add", _origin, x);
};

Observable.prototype.insertAll = function(index, array, _origin)
{
	this._values = 
		this._values.slice(0, index)
		.concat(array)
		.concat(this._values.slice(index));
	this._queueMessage(this, "insertAll", _origin, index, array);
};

Observable.prototype.addAll = function(array)
{
	this.insertAll(this._values.length, array);
}

Observable.prototype.remove = function(x)
{
	if (!this.tryRemove(x))
		throw new Error("Observable.remove(): item not found");
};

Observable.prototype.tryRemove = function(x)
{
	var i = this._values.indexOf(x);
	if (i != -1)
	{
		var item = this._values[i];
		this._values.splice(i, 1);
		this._queueMessage(this, "removeAt", this._origin, i, item);
		return true;
	}
	else
	{
		return false;
	}
};

Observable.prototype.removeWhere = function(f)
{
	var count = 0;
	for (var i = 0; i < this._values.length; i++)
	{
		var x = this.getAt(i);
		if (f(x))
		{
			this.removeAt(i--);
			count++;
		}
	}
	return count;
};

Observable.prototype.removeAt = function(index, _origin)
{
	if (index < 0 || index >= this._values.length)
	{
		throw new Error("removeAt(" + index + ") index out-of-bounds: length=" + this._values.length)
	}
	var obj = this._values[index];
	this._values.splice(index, 1);
	this._queueMessage(this, "removeAt", _origin, index, obj);
};

Observable.prototype.removeRange = function(index, count, _origin)
{
	var removed = this._values.slice(index, index+count);
	this._values.splice(index, count);
	this._queueMessage(this, "removeRange", _origin, index, count, removed);
};

Observable.prototype.clear = function( _origin)
{
	this._values = [];
	this._queueMessage(this, "clear", _origin);
};

/*
	Executes a function on all the current values.
*/
Observable.prototype.forEach = function(f)
{
	this.depend();
	for (var i = 0; i < this._values.length; i++)
	{
		f(this._values[i], i);
	}
};

Observable.prototype.indexOf = function(x)
{
	this.depend();
	return this._values.indexOf(x);
};

Observable.prototype.contains = function(x)
{
	this.depend();
	return this._values.indexOf(x) !== -1;
};


/*
	Returns the number of values in the observable.
*/
Object.defineProperty(Observable.prototype, "length",
{
	get: function()
	{
		this.depend();
		return this._values.length;
	}
});

Observable.prototype.setValueExclusive = function(value, exclude, origin) {
	this._values = [value];
	this._queueMessageExclusive([this, "set", origin, value], exclude);	
};

Observable.prototype.setValueWithOrigin = function(value, origin)
{
	this._values = [value];
	this._queueMessage(this, "set", origin, value);
};

Observable.prototype.replaceAllWithOrigin = function(values, origin)
{
	this._values = values;
	this._queueMessage(this, "newAll", origin, values);
}

/*
	Gets or sets the (first) value of the observable.
	This property is mainly for use with for sigle-valued observables.
	If the observable contains multiple values, this property only
	gets or sets the first value.
*/
Object.defineProperty(Observable.prototype, "value",
{
	get : function()
	{
		this.depend();
		if (this._values.length === 0) { return undefined; }
		else { return this._values[0]; }
	},
	set : function(x)
	{
		this._values = [x];
		this._queueMessage(this, "set", this._origin, x);
	}
});


/*
	Returns an observable that will only propagate values that pass the given
	criteria, otherwise it retains it's previous value.

	This method only considers the first (single) value of an observable.
*/
Observable.prototype.filter = function(f)
{
	this._assertNoDependence("filter");

	if (!f) f = Identity;

	return ProxyObserve(this, function(src)
	{
		if (f(src.value)) this.value = src.value;
	});
};

Observable.prototype.toString = function()
{
	this.depend();
	if (this._values) { return "(observable) " + this._values.toString(); }
	else return "(no value)";
};

// A list of functions to be processed in order
var messageQueue = [];
var pumping = false;
function PumpMessages()
{
	if (pumping) return;
	try
	{
		pumping = true;
		while (messageQueue.length > 0)
		{
			var msg = messageQueue.shift();
			msg();
		}
	}
	finally
	{
		pumping = false;
	}
}

function PostMessage(sub, args)
{
	messageQueue.push(function() {
		var obs = args[0];
		if (sub.active) {
			sub.post(args);
		}
	});
}

/**
	_queueMessage( object, op, origin, args... )
*/
Observable.prototype._queueMessage = function() 
{
	var args = Array.prototype.slice.call(arguments);
	if (args[1] !== "failed") {
		this._clearFailed()
	}
	if (!args[2]/*origin*/) {
		args[2] = this._origin
	}
	this._queueMessageExclusive(args);
};

Observable.prototype._queueMessageExclusive = function(args, exclude) 
{
	for (var i = 0; i < this._subscribers.length; i++) {
		var sub = this._subscribers[i];
		if (sub.callback !== exclude) {
			PostMessage(sub, args);
		}
	}

	PumpMessages();
};



/* --- operators --- */

Observable.prototype.map = function(mapFunc, clearMap)
{
	return this._map(mapFunc, undefined, clearMap)
}

Observable.prototype.mapTwoWay = function( mapFunc, unmapFunc )
{	
	return this._map(mapFunc, unmapFunc, undefined)
}

Observable.prototype._map = function(mapFunc, unmapFunc, clearMap)
{
	this._assertNoDependence("map");

	//is the mapping function expecting an index
	var mapFuncNeedsIndex = mapFunc.length > 1
	
	var source = this
	var target = new ProxyObservable()
	target._proxyFrom(this, mapFunc, clearMap, mapFuncNeedsIndex ? 2 : 1, false)

	if (unmapFunc) {
		source._proxyFrom(target, unmapFunc, undefined, 3, true)
	}
	
	return target
};

function Identity(x) { return x; }

Observable.prototype.identity = function() {
	return this.map(Identity);
};

Observable.prototype.pick = function(field) {
	return this.map(function(x) { return x[field]; });
};

Observable.prototype.pickTwoWay = function(index) {
	return this.mapTwoWay(
		function(v) { return v[index] },
		function(v, ov) {
			ov[index] = v
			return ov
		})
}

Observable.prototype.flatMap = function(mapFunc) {
	return this.map(mapFunc).inner();
}

Observable.prototype.notNull = function() {
	return this.where(function(x) { return x; } );
};

Observable.prototype.parseJson = function()
{
	return this.map(JSON.parse);
};

Observable.prototype.stringifyJson = function() 
{
	return this.map(JSON.stringify);
};

Observable.prototype.expand = function(f)
{
	this._assertNoDependence("expand");

	var self = this;
	return ProxyObserve(self, function () {

		if (self.length > 1)
			throw new Error("expand(): can only be used on a single value");

		var r = self.value;

		if (r === undefined)
			this.replaceAll([]);
		else {
			if (!(r instanceof Array))
				throw new Error("expand(): source value must be an array");

			this.replaceAll(r);
		}
	});
};

/*  Transforms an object to a filter function that checks if the
	given fields are present and match the given value. */
function ObjectToFilter(obj)
{
	return function(x) {
		for (var p in obj) {
			if (!x.hasOwnProperty(p)) { return false; }
			if (x[p] !== obj[p]) { return false;}
		}
		return true;
	}
}

Observable.prototype.where = function(criteria)
{
	this._assertNoDependence("where");

	if (!criteria) {
		return this.map(function(x) { return x; });
	}

	if ((!(criteria instanceof Function)) && (criteria instanceof Object)) {
		criteria = ObjectToFilter(criteria);
	}

	
	var self = this.map(function(x, index) {
		var cond = criteria(x);
		var item = {
			condition: cond,
			unsubscribe: null,
			value: x
		}

		if (cond instanceof Observable) {
			function condChanged() {
				if (item.condition && !cond.value) {
					res.removeAt(getResultIndex(index));
				}
				if (!item.condition && cond.value) {
					res.insertAt(getResultIndex(index), x);
				}
				item.condition = cond.value;
			}

			cond.addSubscriber(condChanged, true/*suppress initial*/);
			item.unsubscribe = function() {
				cond.removeSubscriber(condChanged);
			}
			item.condition = cond.value;
		}

		return item;
	}, /*unmap: */ function(x) {
		if (x.unsubscribe) { x.unsubscribe(); }
		x.unsubscribe = null;
	});

	function getResultIndex(selfIndex)
	{
		var c = 0;
		for (var i = 0; i < selfIndex; i++)
		{
			if (self.getAt(i).condition) { c++; }
		}
		return c;
	}

	var res = ProxyObserve(self, function(src, op, origin, p1, p2, p3)
	{
		if (op === "set")
		{
			if (p1.condition)
			{
				this.value = p1.value;
			}
			else 
			{
				this.replaceAll([]);
			}
		}
		else if (op === "clear")
		{
			this.clear();
		}
		else if (op === "add")
		{
			if (p1.condition)
			{
				this.add(p1.value);
			}
		}
		else if (op === "removeAt")
		{
			if (p2.condition)
			{
				this.removeAt(getResultIndex(p1));
			}
		}
		else if (op === "insertAt")
		{
			if (p2.condition)
			{
				this.insertAt(getResultIndex(p1), p2.value);
			}
		}
		else if (op === "newAt")
		{
			var index = getResultIndex(p1);
			var newValue = p2;
			var oldValue = p3;
	
			if (oldValue.condition)
			{
				if (newValue.condition)
				{
					this.replaceAt(index, newValue.value);
				}
				else
				{
					this.removeAt(index);
				}
			}
			else
			{
				if (newValue.condition)
				{
					this.insertAt(index, newValue.value);
				}
			}
		}
		else if (op === "insertAll")
		{
			var items = p2;
			var result = [];
			for (var i = 0; i < items.length; i++)
			{
				var item = items[i];
				if (item.condition)
				{
					result.push(item.value);
				}
			}

			if (result.length > 0)
			{
				this.insertAll(getResultIndex(p1), result);
			}
		}
		else if (op === "removeRange")
		{
			var index = getResultIndex(p1);

			var count = 0;
			for (var i = 0; i < p3.length; i++)
			{
				if (p3[i].condition) { count++; }
			}

			if (count > 0)
			{
				this.removeRange(index, count);	
			}
		}
		else if (op === "failed")
		{
			this.failed(p1);
		}
		else if (op === "newAll")
		{
			var r = [];

			self.forEach(function(x) {
				if (x.condition) {
					r.push(x.value);
				}
			});

			this.replaceAll(r);
		}
		else
		{
			throw new Error("Unhandled operation in where(): " + op);
		}
	});

	return res;
};


Observable.prototype.count = function(criteria)
{
	this._assertNoDependence("count");

	if (criteria) {
		return this.where(criteria).count();
	}

	return ProxyObserve(this, function(src) {
		this.value = src.length;
	});
};

Observable.prototype.any = function(f) {
	return this.count(f).map(function(x) { return x > 0; } );
}

Observable.prototype.first = function(f) {
	return this.where(f).slice(0, 1);
}

Observable.prototype.last = function(f) {
	return this.where(f).slice(-1);
}

Observable.prototype.inner = function() {
	return this._inner(false, false)
}

Observable.prototype.innerTwoWay = function() {
	return this._inner(true, false)
}

/**
	These two variants do a variant which map the source Observable as-is should it not
	contain an Observable. It's unknown if this mode will ever be needed. It's being retained
	for the two test-cases that use it, as they are still valuable. But if we really don't need
	this mode then we can drop it (the actual change in `_inner` is minimal)
*/
Observable.prototype._forceInner = function() {
	return this._inner(false, true)
}

Observable.prototype._forceInnerTwoWay = function() {
	return this._inner(true, true)
}

Observable.prototype._inner = function(enableTwoWay, forceSourceObservable) {
	var target = new ProxyObservable()
	var self = this
	var proxied = undefined
	var targetProxyId = undefined
	var sourceProxyId = undefined
	
	function selfChanged(src, op, origin, p1, p2) {
		var source = self.value
		var toProxy = source instanceof Observable ? source : (forceSourceObservable ? self : null)
		if (toProxy !== null && toProxy === proxied) {
			return
		}
			
		if (proxied) {
			target._unproxyFrom(targetProxyId)
			if (enableTwoWay) {
				proxied._unproxyFrom(sourceProxyId)
			}
			
			targetProxyId = undefined
			sourceProxyId = undefined
			proxied = undefined
		}
		
		if (toProxy) {
			targetProxyId = target._proxyFrom(toProxy, function(v) { return v }, undefined, 1, false )
			if (enableTwoWay) {
				sourceProxyId = toProxy._proxyFrom(target, function(v) { return v }, undefined, 1, true )
			}
			proxied = toProxy
		} else if (source instanceof Array) {
			target.replaceAll( source )
		} else if (source === null || source === undefined) {
			target.clear()
		} else {
			target.value = source
		}
	}
	
	target._addSubscriptionWatcher( function() {
		self.addSubscriber(selfChanged)
	}, function() {
		self.removeSubscriber(selfChanged)
	})
	
	//DEPRECATED: 2016-12-27
	target.twoWayMap = function(f,g) {
		if (!deprecatedMsg.twoWayMap) {
			Diagnostics.deprecated( "`.inner().twoWayMap()` is deprecated. Use `.innerTwoWay()`, possibly combined with `.mapTwoWay()` or another two-way function" );
			deprecatedMsg.twoWayMap = true
		}
		return self._innerDeprecated().twoWayMap(f,g)
	}
	
	return target
}

//DEPRECATED: 2016-12-27
Observable.prototype.innerDeprecated = function()
{
	if (!deprecatedMsg.innerDeprecated) {
		Diagnostics.deprecated( "`.innerDeprecated()` is deprecated, being provided only for odd compatibility reasons. Try using `.inner()` instead. " );
		deprecatedMsg.innerDeprecated = true
	}
	return this._innerDeprecated()
}

Observable.prototype._innerDeprecated = function()
{
	this._assertNoDependence("inner");

	var self = this;
	var res = new ProxyObservable();
	var sub = null;

	var innerChanged = function(src, op, p1, p2)
	{
		res.replaceAll(src);
	};

	var selfChanged = function(src)
	{
		if (sub instanceof Observable)
		{
			sub.removeSubscriber(innerChanged);
		}
		sub = src.value;
		if (sub instanceof Observable)
		{
			sub.addSubscriber(innerChanged);
		}
		else if (sub instanceof Array)
		{
			res.replaceAll(sub);
		}
		else if (sub === null || sub === undefined)
		{
			res.clear();
		}
		else
		{
			res.value = sub;
		}
	};

	res.setInnerValue = function(value) {
		if (self.value instanceof Observable) {
			self.value.setValueExclusive(value, innerChanged);
		}
	}

	res.twoWayMap = function(f, g) {
		var self = this;
		var m = self.map(f);

		var mChanged = function() {
			if (m.length > 0) {
				self.setInnerValue(g(m.value, self.value));
			}
		};

		m._addSubscriptionWatcher( function() {
			m.addSubscriber(mChanged);
		},  function() {
			m.removeSubscriber(mChanged);
		})

		return m;
	}

	res._addSubscriptionWatcher( function() {
		self.addSubscriber(selfChanged);
	}, function() {
		self.removeSubscriber(selfChanged);
		if (sub instanceof Observable) {
			sub.removeSubscriber(innerChanged);
		}
		sub = null;
	})

	return res;
};

Observable.prototype.not = function()
{
	return this.map(function (x) { return !x; });
};

/**
	Returns a new observable of a portion of another observable.
*/
Observable.prototype.slice = function(begin, end)
{
	return ProxyObserve(this, function(src) {
		this.replaceAll(src._values.slice(begin, end));
	})
};

/**
	Maps the error state.
	
	@param failedMapFunc(err) Returns the value to use when there is failure
	@param notFailedMapFunc()  (OPTIONAL) Returns the value to use when there is no failure
*/
Observable.prototype.failedMap = function( failedMapFunc, notFailedMapFunc ) {
	var res = new ProxyObservable()
	
	res._watchSource( this, function(src, op, origin, p1, p2) {
		var value = undefined
		
		if (op === "failed") {
			value = failedMapFunc(p1)
		} else if (notFailedMapFunc) {
			value = notFailedMapFunc()
		}
		
		if (value !== undefined) {
			res.setValueWithOrigin( value, origin )
		} else {
			res.clear( origin )
		}
	})
	
	return res
}

/**
	Returns an observable which has value `true` if this observable failed, or `false` otherwise.
	
	It optionally takes a list of several other observables and the result of them is OR'd together (`true` if any of them is failed, `false` is none of them are failed.
*/
Observable.prototype.isFailed = function() {	
	var sources = Array.prototype.slice.call(arguments)
	sources.unshift(this)
	
	var res = ProxyObserveList(sources, function() {
		var failed = false
		for (var i=0; i < sources.length; ++i) {
			if (sources[i].getFailure() !== undefined) {
				failed = true
			}
		}
		this.value = failed
	})
	return res
}

/* Used by Node to implement _findData */
Observable._getDataObserver = function(node, key)
{
	if (!node._dataObservers) {
		node._dataObservers = {};
	}


	if (!(key in node._dataObservers)) {

		var obs = Observable();	

		var handle;
		
		function changed(data) {
			obs.value = data;
		}

		function begin()
		{
			handle = node._createWatcher(key, changed);
		}

		function end()
		{
			node._destroyWatcher(handle);
		}

		obs._addSubscriptionWatcher(begin, end);
		node._dataObservers[key] = obs;
	}

	var res = node._dataObservers[key];
	return res;
}

module.exports = Observable;
