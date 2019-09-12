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
		
		internal static void CheckPermissions(Promise<string> p)
		{
			var cb = new PromiseCallback<string>(p);
			CheckPermissionsInternal(cb.Resolve, cb.Reject);
		}
		
		internal static void RequestPermissions(Promise<string> p)
		{
			var cb = new PromiseCallback<string>(p);
			RequestPermissionsInternal(cb.Resolve, cb.Reject);
		}

		[Foreign(Language.ObjC)]
		static void TakePictureInternal(Action<string> onComplete, Action<string> onFail)
		@{
			dispatch_async(dispatch_get_main_queue(), ^{
				[[CameraHelper instance] takePictureWithCompletionHandler:onComplete onFail:onFail];
			});
		@}
		
		[Foreign(Language.ObjC)]
		static void CheckPermissionsInternal(Action<string> onComplete, Action<string> onFail)
		@{
			AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
			if (status == AVAuthorizationStatusAuthorized)
				onComplete(@"AVAuthorizationStatusAuthorized");
			else if (status == AVAuthorizationStatusNotDetermined)
				onFail(@"AVAuthorizationStatusNotDetermined");
			else if (status == AVAuthorizationStatusDenied)
				onFail(@"AVAuthorizationStatusDenied");
			else if (status == AVAuthorizationStatusRestricted)
				onFail(@"AVAuthorizationStatusRestricted");
		@}
		
		[Foreign(Language.ObjC)]
		static void RequestPermissionsInternal(Action<string> onComplete, Action<string> onFail)
		@{
			AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
			if (status == AVAuthorizationStatusNotDetermined)
				[AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
					if(granted)
						onComplete(@"AVAuthorizationStatusAuthorized");
					else
						onFail(@"AVAuthorizationStatusDenied");
				}];
			else if (status == AVAuthorizationStatusAuthorized)
				onComplete(@"AVAuthorizationStatusAuthorized");
			else
				dispatch_async(dispatch_get_main_queue(), ^{
					[[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
				});
		@}
	}
}
