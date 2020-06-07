using Uno;
using Uno.UX;

using Fuse.Platform;

namespace Fuse.Reactive
{
	/**
		Provides details about the device and view needed for layout.

		The `window()` function returns an object with reactive properties. "Window" is a common term that refers to the entire area the application is using on the device, which is not always the entire screen.
			- `width` (float):  the width of the window
			- `height` (float): the height of the window
			-  `size` (float2): the combined width and height of the window
			- `safeMargins` (float4): Margins needed on the content of the window to exclude it from all device UI and reserved areas.
			- `staticMargins` (float4): Like `safeMargins` but does not adjust for popup controls like the soft keyboard.
			- `deviceMargins` (float4): (Experimental) The margins the device reports as not being complete safe for drawing as something may obstruct the view (such as the rounded corners of an iPhone X)

		Drawing anythng but a background (image or brush fill) in the gradient areas is not recommended as it may be obscured by the system UI or the hardware.


		Refer to @SafeEdgePanel and [Safe Layout](articles:layout/safe-layout.md) for more information about safe layouts and device margins.
	*/
	[UXFunction("window")]
	public class WindowFunction : Fuse.Reactive.Expression
	{
		[UXConstructor]
		public WindowFunction() { }

		public override string ToString()
		{
			return "window()";
		}

		public override IDisposable Subscribe(IContext context, IListener listener)
		{
			var rv = context.Node.GetNearestAncestorOfType<RootViewport>();
			var sub = new Subscription(this, rv, listener);
			sub.Init();
			return sub;
		}

		class Subscription : IDisposable
		{
			WindowFunction _func;
			IListener _listener;
			RootViewport _rootViewport;
			WindowCaps _windowCaps;

			public Subscription(WindowFunction func, RootViewport rv, IListener listener)
			{
				_func = func;
				_listener = listener;
				_rootViewport = rv;

				if (rv == null)
					Fuse.Diagnostics.UserError( "No RootViewport found in this context", this );
			}

			public void Init()
			{
				if (_rootViewport == null)
					return;

				_windowCaps = WindowCaps.Attach(_rootViewport);
				_listener.OnNewData(_func, _windowCaps );
			}

			public void Dispose()
			{
				if (_windowCaps != null)
				{
					_windowCaps.Detach();
					_windowCaps = null;
				}
				_rootViewport = null;
				_func = null;
				_listener = null;
			}
		}
	}

	class WindowCaps : Fuse.Reactive.CapsObject
	{
		RootViewport _rootViewport;
		int _attachCount;

		static WindowCaps _singleton;

		public static WindowCaps Attach(RootViewport target)
		{
			var rv = _singleton;
			if (rv == null)
			{
				rv = new WindowCaps(target);
				_singleton = rv;
			}

			rv._attachCount++;
			return rv;
		}

		public static WindowCaps AttachFrom(Node node)
		{
			var rv = node.GetNearestAncestorOfType<RootViewport>();
			if (rv == null)
				throw new Exception( "No RootViewport found" );

			return Attach(rv);
		}

		public void Detach()
		{
			if (--_attachCount == 0)
			{
				Unroot();
				_singleton = null;
			}
		}

		static public Selector NameWidth = "width";
		static public Selector NameHeight = "height";
		static public Selector NameSize = "size";

		static public Selector NamePixelsPerPoint = "pixelsPerPoint";
		static public Selector NamePixelsPerOSPoint = "pixelsPerOSPoint";

		static public Selector NameSafeMargins = "safeMargins";
		static public Selector NameDeviceMargins = "deviceMargins";
		static public Selector NameStaticMargins = "staticMargins";

		WindowCaps( RootViewport rv )
		{
			_rootViewport = rv;
			_rootViewport.Resized += OnResizedRV;
			OnResized();

			SystemUI.MarginsChanged += OnMarginsChanged;
			UpdateMargins();

			ChangeProperty(NamePixelsPerPoint, _rootViewport.PixelsPerPoint);
			ChangeProperty(NamePixelsPerOSPoint, _rootViewport.PixelsPerOSPoint);
		}

		void Unroot()
		{
			SystemUI.MarginsChanged -= OnMarginsChanged;
		}

		void OnResizedRV(float2 ignore) { OnResized(); }
		void OnResized()
		{
			ChangeProperty(NameWidth, _rootViewport.Size.X);
			ChangeProperty(NameHeight, _rootViewport.Size.Y);
			ChangeProperty(NameSize, _rootViewport.Size);
			UpdateManager.AddDeferredAction( UpdateMargins );
		}

		void OnMarginsChanged()
		{
			UpdateManager.AddDeferredAction( UpdateMargins );
		}

		void UpdateMargins()
		{
			var osToFuse = _rootViewport.PixelsPerOSPoint / _rootViewport.PixelsPerPoint;
			ChangeProperty(NameDeviceMargins, SystemUI.DeviceMargins * osToFuse);
			ChangeProperty(NameSafeMargins, SystemUI.SafeMargins * osToFuse);
			ChangeProperty(NameStaticMargins, SystemUI.StaticMargins * osToFuse);
		}
	}
}
