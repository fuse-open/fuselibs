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
			PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
			if (status == PHAuthorizationStatusNotDetermined)
				[PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status){
					if (status == PHAuthorizationStatusAuthorized)
						dispatch_async(dispatch_get_main_queue(), ^{
							[[CameraRollHelper instance] selectPictureWithCompletionHandler:onComplete onFail:onFail];
						});
					else
						onFail(@"PHAuthorizationStatusDenied");
				}];
			else if (status == PHAuthorizationStatusAuthorized)
				dispatch_async(dispatch_get_main_queue(), ^{
					[[CameraRollHelper instance] selectPictureWithCompletionHandler:onComplete onFail:onFail];
				});
			else if (status == PHAuthorizationStatusRestricted)
				onFail(@"PHAuthorizationStatusRestricted");
			else if (status == PHAuthorizationStatusDenied)
				onFail(@"PHAuthorizationStatusDenied");
		@}
		
		[Foreign(Language.ObjC)]
		static void CheckPermissionsInternal(Action<string> onComplete, Action<string> onFail)
		@{
			PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
			if (status == PHAuthorizationStatusAuthorized)
				onComplete(@"PHAuthorizationStatusAuthorized");
			else if (status == PHAuthorizationStatusNotDetermined)
				onFail(@"PHAuthorizationStatusNotDetermined");
			else if (status == PHAuthorizationStatusDenied)
				onFail(@"PHAuthorizationStatusDenied");
			else if (status == PHAuthorizationStatusRestricted)
				onFail(@"PHAuthorizationStatusRestricted");
		@}
		
		[Foreign(Language.ObjC)]
		static void RequestPermissionsInternal(Action<string> onComplete, Action<string> onFail)
		@{
			PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
			if (status == PHAuthorizationStatusNotDetermined)
				[PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status){
					if (status == PHAuthorizationStatusAuthorized)
						onComplete(@"PHAuthorizationStatusAuthorized");
					else
						onFail(@"PHAuthorizationStatusDenied");
				}];
			else if (status == PHAuthorizationStatusAuthorized)
				onComplete(@"PHAuthorizationStatusAuthorized");
			else
				dispatch_async(dispatch_get_main_queue(), ^{
					[[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
				});
		@}
	}
}
