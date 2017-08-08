using Uno.Collections;
using Uno;

namespace Fuse.Reactive
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
				public void Perform()
				{
					if (_obj.ContainsKey("$requestChange")) {
						((Scripting.Function)_obj["$requestChange"]).Call(_key, _value);
					}
					else
					{
						_obj[_key] = _value;
					}
				}
			}

			bool IPropertySubscription.TrySetExclusive(string key, object newValue)
			{
				var t = SubscriptionSubject as TreeObject;

				// Must be done first - to ensure the operations happen in the right order on the JS thread
				JavaScript.Worker.Invoke(new JSThreadSet((Scripting.Object)t.Raw, key, JavaScript.Worker.Unwrap(newValue)).Perform);
				
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

		const string _rawHandle = "$raw";
		object _rawOverride;
		public override object ReflectedRaw 
		{ 
			get 
			{ 
				return _rawOverride ?? base.ReflectedRaw; 
			} 
		}

		internal override void Set(IMirror mirror, Scripting.Object obj)
		{
			_props.Clear();
			var k = obj.Keys;
			for (int i = 0; i < k.Length; i++)
			{
				var s = k[i];
				if (s == _rawHandle)
				{
					_rawOverride = obj[s];
					continue;
				}
				_props.Add(s, mirror.Reflect(obj[s]));
			}

			var sub = Subscribers as PropertySubscription;
			if (sub != null) 
				foreach (var p in _props)
					sub.OnPropertyChanged(p.Key, p.Value, null);
		}

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