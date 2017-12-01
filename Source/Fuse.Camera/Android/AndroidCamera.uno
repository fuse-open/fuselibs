using Uno.Threading;
using Uno;
using Uno.Compiler.ExportTargetInterop;
using Android;
using Fuse.ImageTools;
using Uno.Permissions;
namespace Fuse.Camera
{
	
	extern (Android) static internal class AndroidCamera
	{
		internal static void TakePicture(Promise<Image> p)
		{
			var permissions = new PlatformPermission[] 
			{
				Permissions.Android.CAMERA,
				Permissions.Android.WRITE_EXTERNAL_STORAGE,
				Permissions.Android.READ_EXTERNAL_STORAGE
			};

			Permissions.Request(permissions).Then(new TakePictureCommand(p).Execute, p.Reject);
		}
	}

	[ForeignInclude(Language.Java, "android.provider.MediaStore", "com.fuse.Activity", "com.fusetools.camera.Image", "android.content.Intent")]
	extern (Android) internal class TakePictureCommand
	{
		Promise<Image> _promise;
		public TakePictureCommand(Promise<Image> promise)
		{
			_promise = promise;
		}
		public void Execute(PlatformPermission[] grantedPermissions)
		{
			if(grantedPermissions.Length<3)
			{
				_promise.Reject(new Exception("Required permissions were not granted."));
				return;
			}
			
			var photo = CreateImage();
			if(photo==null)
				throw new Exception("Couldn't create temporary Image");

			var intent = CreateIntent(photo);
			if(intent==null)
				throw new Exception("Couldn't create Image capture intent");

			ActivityUtils.StartActivity(intent, new TakePictureCallback(_promise).OnActivityResult, (object)photo);
		}

		[Foreign(Language.Java)]
		static Java.Object CreateIntent(Java.Object photo)
		@{
			Image p = (Image)photo;
			try {
				Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
				intent.putExtra(MediaStore.EXTRA_OUTPUT, p.getFileUri());
				return intent;
			} catch (Exception e) {
				e.printStackTrace();
				return null;
			}
		@}

		[Foreign(Language.Java)]
		static Java.Object CreateImage()
		@{
			try {
				return Image.create();
			} catch(Exception e) {
				e.printStackTrace();
				return null;
			}
		@}
	}

	[ForeignInclude(Language.Java, "com.fuse.Activity", "com.fusetools.camera.Image", "android.content.Intent", "com.fusetools.camera.ImageStorageTools")]
	extern (Android) internal class TakePictureCallback
	{
		Promise<Image> _p;
		public TakePictureCallback(Promise<Image> p)
		{
			_p = p;
		}

		public void OnActivityResult(int resultCode, Java.Object intent, object info)
		{
			HandleIntent(resultCode, intent, (Java.Object)info, OnComplete, OnFail);
		}

		[Foreign(Language.Java)]
		void HandleIntent(int resultCode, Java.Object intent, Java.Object photo, Action<string> onComplete, Action<string> onFail)
		@{
			switch (resultCode)
			{
				case android.app.Activity.RESULT_OK:
					Image p = (Image)photo;
					try{
						p.correctOrientationFromExif();
					}catch(Exception e){
						// Still allow the picture through: It's been created but possibly with wrong orientation
					}
					onComplete.run(p.getFilePath());
					return;
				case android.app.Activity.RESULT_CANCELED:
					onFail.run("User cancelled");
					return;
				default:
					onFail.run("Picture could not be captured");
			}
		@}

		public void OnComplete(string path)
		{
			_p.Resolve(new Image(path));
		}

		public void OnFail(string reason)
		{
			_p.Reject(new Exception(reason));
		}
	}
}
