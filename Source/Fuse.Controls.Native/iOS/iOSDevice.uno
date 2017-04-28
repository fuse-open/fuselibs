using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Controls.Native.iOS
{
	extern(iOS) public class OSVersion
	{
		public readonly int Major;
		public readonly int Minor;
		public readonly int Patch;
		public OSVersion(int major, int minor, int patch)
		{
			Major = major;
			Minor = minor;
			Patch = patch;
		}
		public override string ToString()
		{
			return Major + "." + Minor + "." + Patch;
		}
	}

	[TargetSpecificImplementation]
	extern(iOS) public static class iOSDevice
	{
		public enum ScreenOrientation
		{
			Portrait,
			Landscape
		}

		static OSVersion _osVersion;
		public static OSVersion OperatingSystemVersion
		{
			get{
				if(_osVersion!=null) return _osVersion;

				int major = extern<int>()"(int)[[NSProcessInfo processInfo] operatingSystemVersion].majorVersion";
				int minor = extern<int>()"(int)[[NSProcessInfo processInfo] operatingSystemVersion].minorVersion";
				int patch = extern<int>()"(int)[[NSProcessInfo processInfo] operatingSystemVersion].patchVersion";

				return _osVersion = new OSVersion(major, minor, patch);
			}
		}

		public static ScreenOrientation Orientation
		{
			get { return IsLandscapeOrientation() ? ScreenOrientation.Landscape : ScreenOrientation.Portrait; }
		}

		public static float2 CompensateForOrientation(float2 size)
		{
			return (OperatingSystemVersion.Major < 8 && Orientation == ScreenOrientation.Landscape /* || IsRootView?? */)
				? float2(size.Y, size.X)
				: size;
		}

		public static Rect CompensateForOrientation(Rect rect)
		{
			return (OperatingSystemVersion.Major < 8 && Orientation == ScreenOrientation.Landscape /* || IsRootView?? */)
				? new Rect(rect.Position.YX, rect.Size.YX)
				: rect;
		}

		[Foreign(Language.ObjC)]
		[Require("Source.Include", "UIKit/UIKit.h")]
		static bool IsLandscapeOrientation()
		@{
			UIInterfaceOrientation o = [[UIApplication sharedApplication] statusBarOrientation];
			return (o == UIInterfaceOrientationLandscapeLeft || o == UIInterfaceOrientationLandscapeRight);
		@}
	}
}
