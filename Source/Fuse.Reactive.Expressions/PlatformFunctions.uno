using Uno;
using Uno.UX;

namespace Fuse.Reactive
{
	/**	
		A series of functions to check the device platform.
		
		[subclass Fuse.Reactive.PlatformFunction]
	*/
	public abstract class PlatformFunction : Expression
	{
		string _name;
		internal PlatformFunction(string name)
		{
			_name = name;
		}
		
		public override string ToString()
		{
			return "is" + _name + "()";
		}
		
		public override IDisposable Subscribe(IContext context, IListener listener)
		{
			var sub = new Subscription(this, listener);
			sub.Init();
			return sub;
		}

		protected abstract bool GetResult();
		
		class Subscription : IDisposable
		{
			PlatformFunction _func;
			IListener _listener;
			
			public Subscription(PlatformFunction func, IListener listener)
			{
				_func = func;
				_listener = listener;
			}
			
			public void Init()
			{
				_listener.OnNewData(_func, _func.GetResult() );
			}
			
			public void Dispose()
			{
				_func = null;
				_listener = null;
			}
		}
	}
	
	[UXFunction("isIOS")]
	/** `true` if running on an iOS device */
	public class IsIOSFunction : PlatformFunction
	{
		[UXConstructor]
		public IsIOSFunction() : base("IOS") { }
		protected override bool GetResult() { return defined(iOS); }
	}
	
	[UXFunction("isDesktop")]
	/** `true` if running on a desktop */
	public class IsDesktopFunction : PlatformFunction
	{
		[UXConstructor]
		public IsDesktopFunction() : base("Desktop") { }
		protected override bool GetResult() { return !defined(iOS) && !defined(Android); }
	}
	
	[UXFunction("isAndroid")]
	/** `true` if running on an Android device */
	public class IsAndroidFunction : PlatformFunction
	{
		[UXConstructor]
		public IsAndroidFunction() : base("Android") { }
		protected override bool GetResult() { return defined(Android); }
	}
	
	[UXFunction("isMobile")]
	/** `true` if running on an Mobile device */
	public class IsMobileFunction : PlatformFunction
	{
		[UXConstructor]
		public IsMobileFunction() : base("Mobile") { }
		protected override bool GetResult() { return defined(iOS) || defined(Android); }
	}
	
	[UXFunction("isOSX")]
	/** `true` if running on OSX */
	public class IsOSXFunction : PlatformFunction
	{
		[UXConstructor]
		public IsOSXFunction() : base("OSX") { }
		protected override bool GetResult() { return defined(OSX); }
	}
	
	[UXFunction("isWindows")]
	/** `true` if running on Windows */
	public class IsWindowsFunction : PlatformFunction
	{
		[UXConstructor]
		public IsWindowsFunction() : base("Windows") { }
		protected override bool GetResult() { return defined(Win32); }
	}
}
