using Uno;
using Uno.Collections;
using Uno.UX;

namespace Fuse.Reactive
{
	public class DeviceCaps : PropertyObject, IObservableObject, IPropertyListener
	{
		Dictionary<string,object> _props = new Dictionary<string,object>();
		
		static public Selector NameIsAndroid = "isAndroid";
		static public Selector NameIsIOS = "isIOS";
		
		static public Selector NameIsMac = "isMac";
		static public Selector NameIsWindows = "isWindows";
		
		static public Selector NameIsPreview = "isPreview";

		DeviceCaps()
		{
			_props[NameIsAndroid] = defined(Android);
			_props[NameIsIOS] = defined(iOS);
			
			_props[NameIsMac] = defined(OSX);
			_props[NameIsWindows] = defined(Win32);
			
			_props[NameIsPreview] = defined(Preview);
		}
		
		[UXGlobalResource] public static readonly DeviceCaps Device = new DeviceCaps();
		
		bool IObject.ContainsKey(string key)
		{
			return _props.ContainsKey(key);
		}
		
		object IObject.this[string key]
		{
			get { return GetValue(key); }
		}
		object GetValue(string key)
		{
			object value;
			if (_props.TryGetValue(key, out value))
				return value;
			return null;
		}
		
		string[] IObject.Keys
		{
			get { return _props.Keys.ToArray<string>(); }
		}
		
		IPropertySubscription IObservableObject.Subscribe(IPropertyObserver observer)
		{
			var sub = new PropertySubscription(this, observer);
			AddPropertyListener(sub);
			return sub;
		}
		
		void ChangeProperty(Selector name, object value)
		{	
			_props[name] = value;
			OnPropertyChanged(name, this);
		}

		void IPropertyListener.OnPropertyChanged(PropertyObject obj, Selector name)
		{
			//needed by interface, but not used
		}
		
		class PropertySubscription : IPropertySubscription, IPropertyListener
		{
			DeviceCaps _deviceCaps;
			IPropertyObserver _observer;
			
			public PropertySubscription( DeviceCaps dc, IPropertyObserver observer )
			{
				_deviceCaps = dc;
				_observer = observer;
			}
			
			public void Dispose()
			{
				if (_deviceCaps != null)
				{
					_deviceCaps.RemovePropertyListener(this);
					_deviceCaps = null;
					_observer = null;
				}
			}
			
			public void OnPropertyChanged(PropertyObject ignore, Selector name)
			{
				if (_observer != null)
				{
					var str = name.ToString();
					var value = _deviceCaps.GetValue(str);
					_observer.OnPropertyChanged(this, str, value);
				}
			}
			
			public bool TrySetExclusive(string propertyName, object newValue)
			{
				return false;
			}
		}
	}
}
