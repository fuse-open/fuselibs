using Uno.UX;
using Uno.Collections;
using Fuse.Reactive;

namespace Fuse.Scripting.JavaScript
{
	class LazyObservableProperty: ObservableProperty
	{
		public LazyObservableProperty(ThreadWorker w, Scripting.Object obj, Uno.UX.Property p, Scripting.Context c): base(w, obj, p)
		{
			c.ObjectDefineProperty(obj, p.Name.ToString(), Get);
		}

		object Get(Scripting.Context context, object[] args)
		{
			return context.Unwrap(GetObservable(context));
		}
	}

	/** A wrapper for a weak observable on the JS side.
		The backing observable can be disposed (e.g. when the associated view is unrooted)
		and then re-created on demand on calls to GetObservable().

		This prevents leakage of strong references to observables on the JS side.
	*/
	class ObservableProperty: IObserver, IPropertyListener
	{
		protected readonly ThreadWorker _worker;
		Uno.UX.Property _property;
		Scripting.Object _obj;

		public ObservableProperty(ThreadWorker w, Scripting.Object obj, Uno.UX.Property p)
		{
			_obj = obj;
			_worker = w;
			_property = p;
		}

		public string Name { get { return _property.Name; } }

		Observable _observable;

		// JS thread
		internal Observable GetObservable(Scripting.Context context)
		{
			if (_observable == null)
			{
				_observable = Observable.Create(context, _worker);
				_observable.Object["_defaultValueCallback"] = (Scripting.Callback)DefaultValueCallback;
				Subscribe(context);
			}
			return _observable;
		}

		// JS thread
		object DefaultValueCallback(Scripting.Context context, object[] args)
		{
			var value = args[0];

			object marshalledValue;
			if (!Marshal.TryConvertTo(_property.PropertyType, value, out marshalledValue))
			{
				return null;
			}

			var resolveClosure = new ResolveDefaultValueClosure(this, marshalledValue);
			UpdateManager.PostAction(resolveClosure.Perform);

			return null;
		}

		internal class ResolveDefaultValueClosure
		{
			readonly Uno.UX.Property _property;
			readonly ISubscription _subscription;
			readonly object _value;
			readonly Uno.Action<object> _pushValueOnJSThread;

			public ResolveDefaultValueClosure(ObservableProperty op, object value)
			{
				_property = op._property;
				_subscription = op._subscription;
				_pushValueOnJSThread = op.PushValueOnJSThread;
				_value = value;
			}

			// UI thread
			public void Perform()
			{
				if (IsDefaultValueForType(_property.GetAsObject(), _property.PropertyType))
				{
					_property.SetAsObject(_value, null);
					_pushValueOnJSThread(_value);
				}
			}

			/*
				!! This is a temporary workaround !!

				What we actually want to check here is wether a given ux:Property has been set at all.
				The UX compiler doesn't (yet) produce code that keeps track of this,
				so we compare the value against `default(T)` as a temporary heuristic until that feature has landed.
				Since we may only evaluate `default(T)` at compile time, we would in theory need to compare against
				the default value of every single value type ever (reference types always have a default value of null).

				However, we only perform this check if there is a conflict with a value coming from JavaScript.
				Since the value is coming from JavaScript, it needs to be marshalled to a corresponding Uno type.
				If it cannot be marshalled, the UX value "wins" by default.

				Therefore, we only need to compare against default values
				for value types that are known to be handled by `Marshal.TryConvertTo`.

				https://github.com/fuse-open/fuselibs/issues/541#issuecomment-335101235
			*/
			static bool IsDefaultValueForType(object value, Uno.Type t)
			{
				if (value == null)
					return true;

				if (t.IsEnum)
					return (int)value == 0;

				return IsDefault<bool>(value, t)
					|| IsDefault<int>(value, t)
					|| IsDefault<float>(value, t)
					|| IsDefault<double>(value, t)
					|| IsDefault<float2>(value, t)
					|| IsDefault<float3>(value, t)
					|| IsDefault<float4>(value, t)
					|| IsDefault<Size>(value, t)
					|| IsDefault<Size2>(value, t)
					|| IsDefault<Selector>(value, t);
			}

			static bool IsDefault<T>(object value, Uno.Type t)
			{
				return t == typeof(T) && value.Equals(default(T));
			}
		}

		Observable.Subscription _subscription;
		void Subscribe(Scripting.Context context)
		{
			_subscription = _observable.SubscribeInternal(this);
			PushValue(context, _property.GetAsObject());
			_property.AddListener(this);
		}

		public void Reset()
		{
			if (_subscription != null)
			{
				_subscription.Dispose();
				_subscription = null;
				_property.RemoveListener(this);
			}

			if (_observable != null)
			{
				_observable.Unsubscribe();
				_observable = null;
			}
		}

		void IObserver.OnClear()
		{
			if (_property.PropertyType.IsClass)
				_property.SetAsObject(null, this);
		}

		void IObserver.OnNewAll(IArray values)
		{
			if (values.Length == 1) Set(values[0]);
		}
		void IObserver.OnNewAt(int index, object newValue)
		{
			if (index == 0) Set(newValue);
		}
		void IObserver.OnSet(object newValue)
		{
			Set(newValue);
		}
		void IObserver.OnAdd(object addedValue)
		{
			// Not supported
		}
		void IObserver.OnRemoveAt(int index)
		{
			// Not supported
		}
		void IObserver.OnInsertAt(int index, object value)
		{
			if (index == 0) Set(value);
		}
		void IObserver.OnFailed(string message)
		{
			// Not supported
		}

		void Set(object value)
		{
			object res;
			if (Marshal.TryConvertTo(_property.PropertyType, value, out res, this))
				_property.SetAsObject(res, this);
		}

		void IPropertyListener.OnPropertyChanged(PropertyObject obj, Selector prop)
		{
			if (prop != _property.Name) return;
			if (obj != _property.Object) return;
			if (_subscription == null) return;
			PushValueOnJSThread(_property.GetAsObject());
		}

		void PushValueOnJSThread(object value)
		{
			_worker.Invoke(new PushCapture(PushValue, value).Run);
		}

		class PushCapture
		{
			readonly Uno.Action<Scripting.Context,object> _push;
			readonly object _arg;

			public PushCapture(Uno.Action<Scripting.Context,object> push, object arg)
			{
				_push = push;
				_arg = arg;
			}

			public void Run(Scripting.Context context)
			{
				_push(context, _arg);
			}
		}

		void PushValue(Scripting.Context context, object val)
		{
			if (_subscription == null) return;

			if (val != null)
			{
				_subscription.SetExclusive(context, val);
			}
			else
			{
				_subscription.ClearExclusive(context);
			}
		}
	}
}
