using Uno;
using Uno.UX;
using Uno.Platform;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using Fuse;
using Fuse.Drawing;

namespace Fuse.iOS.Bindings
{
	[Require("Source.Include", "@{Uno.Platform.CoreApp:Include}")]
	internal extern(iOS) static class iOSDeviceInterop
	{
		public static bool IsRootView(ObjC.Object uiView)
		{
			return uiView == Uno.Platform.iOS.Application.GetRootView();
		}

		[Foreign(Language.ObjC)]
		public static bool IsOrientationLandscape()
		@{
			UIInterfaceOrientation o = [UIApplication sharedApplication].statusBarOrientation;
			return o == UIInterfaceOrientationLandscapeLeft ||
				o == UIInterfaceOrientationLandscapeRight;
		@}

		public static float2 Pre_iOS8_HandleDeviceOrientation(float2 size, ObjC.Object uiView)
		{
			if (PreV8 && IsOrientationLandscape() && (uiView == null || IsRootView(uiView)))
				return float2(size.Y, size.X);

			return size;
		}

		public static Rect Pre_iOS8_HandleDeviceOrientation(Rect rect, ObjC.Object uiView)
		{
			if (PreV8 && IsOrientationLandscape() && (uiView == null || IsRootView(uiView)))
			{
				var pos = rect.Position;
				var size = rect.Size;
				return new Rect(float2(pos.Y, pos.X), float2(size.Y, size.X));
			}
			return rect;
		}

		public static bool PreV8
		{
			get @{ return NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1; @}
		}

		[Foreign(Language.ObjC)]
		public static extern(iOS) void LaunchUriiOS(string uri)
		@{
			dispatch_sync(dispatch_get_main_queue(), ^{
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:uri]];
			});
		@}

		[Foreign(Language.ObjC)]
		public static extern(iOS) void LaunchApp(string uri, string appStoreUri)
		@{
			dispatch_sync(dispatch_get_main_queue(), ^{
				if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:uri]]) 
				{
					[[UIApplication sharedApplication] openURL:[NSURL URLWithString:uri]];
				} 
				else if (appStoreUri != (id)[NSNull null] && appStoreUri.length > 0) 
				{
					[[UIApplication sharedApplication] openURL:[NSURL URLWithString:appStoreUri]];
				}
			});
		@}
	}
}
