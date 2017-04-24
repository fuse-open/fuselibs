using Uno.Threading;
using Uno;
using Uno.Compiler.ExportTargetInterop;
using Android;
using Fuse.ImageTools;
namespace Fuse.Camera
{
	[Require("Source.Include", "iOS/CameraHelper.h")]
	public extern(iOS) class iOSCamera
	{
		internal static void TakePicture(Promise<Image> p)
		{
			var cb = new ImagePromiseCallback(p);
			TakePictureInternal(cb.Resolve, cb.Reject);
		}

		[Foreign(Language.ObjC)]
		static void TakePictureInternal(Action<string> onComplete, Action<string> onFail)
		@{
			[[CameraHelper instance] takePictureWithCompletionHandler:onComplete onFail:onFail];
		@}
	}
}
