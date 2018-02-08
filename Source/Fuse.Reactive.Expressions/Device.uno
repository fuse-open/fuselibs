using Uno;
using Uno.Collections;
using Uno.UX;

namespace Fuse.Reactive
{
	public class CapsObject : PropertyObject, IObservableObject, IPropertyListener
	{
		Dictionary<string,object> _props = new Dictionary<string,object>();
		protected Dictionary<string,object> Props { get { return _props; } }
		
		internal CapsObject() { }
		
		public bool ContainsKey(string key)
		{
			return _props.ContainsKey(key);
		}
		
		public object this[string key]
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
		
		public string[] Keys
		{
			get { return _props.Keys.ToArray<string>(); }
		}
		
		IPropertySubscription IObservableObject.Subscribe(IPropertyObserver observer)
		{
			var sub = new PropertySubscription(this, observer);
			AddPropertyListener(sub);
			return sub;
		}
		
		protected void ChangeProperty(Selector name, object value)
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
			CapsObject _caps;
			IPropertyObserver _observer;
			
			public PropertySubscription( CapsObject dc, IPropertyObserver observer )
			{
				_caps = dc;
				_observer = observer;
			}
			
			public void Dispose()
			{
				if (_caps != null)
				{
					_caps.RemovePropertyListener(this);
					_caps = null;
					_observer = null;
				}
			}
			
			public void OnPropertyChanged(PropertyObject ignore, Selector name)
			{
				if (_observer != null)
				{
					var str = name.ToString();
					var value = _caps.GetValue(str);
					_observer.OnPropertyChanged(this, str, value);
				}
			}
			
			public bool TrySetExclusive(string propertyName, object newValue)
			{
				return false;
			}
		}
	}

	/**
		Provides information about the device.
		
		Use the global `Device` variable to access these reactive variables. For example, to include something only on Android:
		
			<Instance IsEnabled="Device.isAndroid">
				<CameraView/>
			</Instance>
			
		The properties are:
			- `isAndroid` (bool): True if running on Android OS, false otherwise
			- `isIOS` (bool): True if running on iOS OS, false otherwise
			- `isMac` (bool): True if running on Mac OS, false otherwise
			- `isWindows` (bool): True if running on Windows OS, false otherwise
			- `isPreview` (bool): True if running inside Preview
			
		On iOS and Android the following are also available:
			- `osVersion` (int3): (major, minor, revision) Version of the operating system. (Android: This is for information, stats, and/or debug purposes only. As it doesn't reliably reflect any system features it should not be used for any conditionals.)
			
		On Android:
			- `apiLevel` (int): API Level supported by the device
	*/
	public class DeviceCaps : CapsObject
	{
		static public Selector NameIsAndroid = "isAndroid";
		static public Selector NameIsIOS = "isIOS";
		
		static public Selector NameIsMac = "isMac";
		static public Selector NameIsWindows = "isWindows";
		
		static public Selector NameIsPreview = "isPreview";
		
		static public Selector NameOSVersion = "osVersion";
		static public Selector NameAPILevel = "apiLevel";

		DeviceCaps()
		{
			Props[NameIsAndroid] = defined(Android);
			Props[NameIsIOS] = defined(iOS);
			
			Props[NameIsMac] = defined(OSX);
			Props[NameIsWindows] = defined(Win32);
			
			Props[NameIsPreview] = defined(Preview);
			
			if defined(iOS||Android)
				Props[NameOSVersion] = Fuse.Platform.SystemUI.OSVersion;
			if defined(Android)
				Props[NameAPILevel] = Fuse.Platform.SystemUI.APILevel;
		}
		
		[UXGlobalResource] public static readonly DeviceCaps Device = new DeviceCaps();
	}
}
