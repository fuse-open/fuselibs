using Uno;
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
	class ObservableProperty: Fuse.Reactive.IObserver, IPropertyListener
	{
		protected readonly ThreadWorker _worker;
		readonly Uno.UX.Property _property;
		readonly Scripting.Object _obj;

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
			if(!Marshal.TryConvertTo(_property.PropertyType, value, out marshalledValue))
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
			readonly Action<object> _pushValueOnJSThread;

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
				// HACK: This should really check if the property has ever been set.
				// However, this requires some bigger changes to the UX compiler,
				// so we check for the default value of the UX Property's type instead.
				// Note that this will fail when the initial value is explicitly set to the default value of the type.
				if(IsDefaultValueForType(_property.GetAsObject(), _property.PropertyType))
				{
					_property.SetAsObject(_value, null);
					_pushValueOnJSThread(_value);
				}
			}

			static bool IsDefaultValueForType(object value, Type t)
			{
				return (!t.IsValueType && value == null)
					|| IsDefault<bool>(value, t)
					|| IsDefault<byte>(value, t)
					|| IsDefault<sbyte>(value, t)
					|| IsDefault<char>(value, t)
					|| IsDefault<short>(value, t)
					|| IsDefault<ushort>(value, t)
					|| IsDefault<int>(value, t)
					|| IsDefault<uint>(value, t)
					|| IsDefault<long>(value, t)
					|| IsDefault<ulong>(value, t)
					|| IsDefault<float>(value, t)
					|| IsDefault<double>(value, t)
					|| IsDefault<int2>(value, t)
					|| IsDefault<int3>(value, t)
					|| IsDefault<int4>(value, t)
					|| IsDefault<byte2>(value, t)
					|| IsDefault<byte4>(value, t)
					|| IsDefault<float2>(value, t)
					|| IsDefault<float3>(value, t)
					|| IsDefault<float4>(value, t)
					|| IsDefault<Size>(value, t)
					|| IsDefault<Size2>(value, t);
			}

			static bool IsDefault<T>(object value, Type t)
			{
				if(typeof(T) != t) return false;
				return value.Equals(default(T));
			}
		}

		ISubscription _subscription;
		void Subscribe(Scripting.Context context)
		{
			_subscription = _observable.Subscribe(this);
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

		void Fuse.Reactive.IObserver.OnClear()
		{
			if (_property.PropertyType.IsClass)
				_property.SetAsObject(null, this);
		}

		void Fuse.Reactive.IObserver.OnNewAll(IArray values)
		{
			if (values.Length == 1) Set(values[0]);
		}
		void Fuse.Reactive.IObserver.OnNewAt(int index, object newValue)
		{
			if (index == 0) Set(newValue);
		}
		void Fuse.Reactive.IObserver.OnSet(object newValue)
		{
			Set(newValue);
		}
		void Fuse.Reactive.IObserver.OnAdd(object addedValue)
		{
			// Not supported
		}
		void Fuse.Reactive.IObserver.OnRemoveAt(int index)
		{
			// Not supported
		}
		void Fuse.Reactive.IObserver.OnInsertAt(int index, object value)
		{
			if (index == 0) Set(value);
		}
		void Fuse.Reactive.IObserver.OnFailed(string message)
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
			if(_subscription == null) return;

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
