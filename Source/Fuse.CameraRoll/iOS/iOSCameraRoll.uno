using Uno.Threading;
using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Android;
using Fuse.ImageTools;
namespace Fuse.CameraRoll
{
	[Require("Source.Include", "iOS/CameraRollHelper.h")]
	public extern(iOS) class iOSCameraRoll
	{
		internal static void SelectPicture(Promise<Image> p)
		{
			var cb = new ImagePromiseCallback(p);
			SelectPictureInternal(cb.Resolve, cb.Reject);
		}

		internal static Future<bool> AddToCameraRoll(Image photo)
		{
			var p = new Promise<bool>();
			var cb = new BoolPromiseCallback(p);
			AddToCameraRollInternal(photo.Path, cb.Resolve, cb.Reject);
			return p;
		}

		internal static List<Image> ListTempImages()
		{
			return null;
		}
		internal static List<Image> ListApplicationImages()
		{
			return null;
		}

		[Foreign(Language.ObjC)]
		static void AddToCameraRollInternal(string path, Action success, Action<string> fail)
		@{
			[CameraRollHelper addNewAssetWithImagePath:path onSuccess:success onFail:fail];
		@}

		[Foreign(Language.ObjC)]
		static void SelectPictureInternal(Action<string> onComplete, Action<string> onFail)
		@{
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				[[CameraRollHelper instance] selectPictureWithCompletionHandler:onComplete onFail:onFail];
			});
		@}


	}
}
