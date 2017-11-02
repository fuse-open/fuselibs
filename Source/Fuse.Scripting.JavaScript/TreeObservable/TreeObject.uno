using Uno.Collections;
using Uno;
using Fuse.Scripting;
using Fuse.Reactive;

namespace Fuse.Scripting.JavaScript
{
	class TreeObject : ObjectMirror, IObservableObject
	{
		/** Does not poulate the _props. Must call Set() later */
		protected TreeObject(Scripting.Object obj) : base(obj) {}

		public IPropertySubscription Subscribe(IPropertyObserver observer)
		{
			return new PropertySubscription(this, observer);
		}

		internal class PropertySubscription : Subscription, IPropertySubscription
		{
			readonly IPropertyObserver _observer;

			public PropertySubscription(TreeObject om, IPropertyObserver observer): base(om)
			{
				_observer = observer;
			}

			class JSThreadSet
			{
				Scripting.Object _obj;
				string _key;
				object _value;
				public JSThreadSet(Scripting.Object obj, string key, object value)
				{
					_obj = obj;
					_key = key;
					_value = value;
				}
				public void Perform(Scripting.Context context)
				{
					var val = context.Unwrap(_value);
					if (_obj.ContainsKey("__fuse_requestChange")) {
						((Scripting.Function)_obj["__fuse_requestChange"]).Call(context, _key, val);
					}
					else
					{
						_obj[_key] = val;
					}
				}
			}

			bool IPropertySubscription.TrySetExclusive(string key, object newValue)
			{
				var t = (TreeObject)SubscriptionSubject;

				// Must be done first - to ensure the operations happen in the right order on the JS thread
				Fuse.Reactive.JavaScript.Worker.Invoke(new JSThreadSet((Scripting.Object)t.Raw, key, newValue).Perform);

				// then notify the UI (which in turn can trigger re-evaluation of scripts)
				t.Set(key, newValue, this);
				return true;
			}

			public void OnPropertyChanged(string key, object newValue, PropertySubscription exclude)
			{
				if (exclude != this) _observer.OnPropertyChanged(this, key, newValue);
				var next = Next as PropertySubscription;
				if (next != null) next.OnPropertyChanged(key, newValue, exclude);
			}
		}

		const string _rawHandle = "__fuse_raw";
		object _rawOverride;
		public override object ReflectedRaw
		{
			get
			{
				return _rawOverride ?? base.ReflectedRaw;
			}
		}

		class SetClosure
		{
			readonly TreeObject _treeObject;
			readonly Dictionary<string, object> _newProps;
			readonly object _rawOverride;
			readonly bool _hasRawOverride;

			public SetClosure(TreeObject treeObject, Dictionary<string, object> newProps, object rawOverride, bool hasRawOverride)
			{
				_treeObject = treeObject;
				_newProps = newProps;
				_rawOverride = rawOverride;
				_hasRawOverride = hasRawOverride;
			}

			// UI Thread
			public void Perform()
			{
				_treeObject._props = _newProps;

				if(_hasRawOverride)
					_treeObject._rawOverride = _rawOverride;

				var sub = _treeObject.Subscribers as PropertySubscription;
				if(sub != null)
				{
					foreach(var prop in _newProps)
					{
						sub.OnPropertyChanged(prop.Key, prop.Value, null);
					}
				}
			}
		}

		// JS Thread
		internal override void Set(Scripting.Context context, IMirror mirror, Scripting.Object obj)
		{
			object rawOverride = null;
			bool hasRawOverride = false;
			var newProps = new Dictionary<string, object>();

			var keys = obj.Keys;
			for (int i = 0; i < keys.Length; i++)
			{
				var key = keys[i];
				if (key == _rawHandle)
				{
					rawOverride = obj[key];
					hasRawOverride = true;
					continue;
				}
				newProps.Add(key, mirror.Reflect(context, obj[key]));
			}

			UpdateManager.PostAction(new SetClosure(this, newProps, rawOverride, hasRawOverride).Perform);
		}

		// UI Thread
		internal void Set(string key, object newValue, PropertySubscription exclude)
		{
			if (_props.ContainsKey(key))
				ValueMirror.Unsubscribe(_props[key]);

			_props[key] = newValue;

			var sub = Subscribers as PropertySubscription;
			if (sub != null)
				sub.OnPropertyChanged(key, newValue, exclude);
		}
	}
}
