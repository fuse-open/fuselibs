using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse
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
				if(_osVersion != null) return _osVersion;
				
				int major, minor, patch;
				GetiOSVersion(out major, out minor, out patch);
				
				return _osVersion = new OSVersion(major, minor, patch);
			}
		}

		[Foreign(Language.ObjC)]
		static void GetiOSVersion(out int major, out int minor, out int patch)
		@{
			*major = (int)[[NSProcessInfo processInfo] operatingSystemVersion].majorVersion;
			*minor = (int)[[NSProcessInfo processInfo] operatingSystemVersion].minorVersion;
			*patch = (int)[[NSProcessInfo processInfo] operatingSystemVersion].patchVersion;
		@}

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
