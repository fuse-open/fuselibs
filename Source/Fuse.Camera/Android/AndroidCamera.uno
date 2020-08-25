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

		internal static void CheckPermissions(Promise<string> p)
		{
			new CheckPermissionsCommand(p);
		}

		internal static void RequestPermissions(Promise<string> p)
		{
			new requestAndroidPermissions(p).Execute();
		}
	}

	[ForeignInclude(Language.Java, 
		"android.provider.MediaStore", 
		"com.fuse.Activity", 
		"com.fuse.camera.Image", 
		"android.os.Build",
		"androidx.core.content.FileProvider", 
		"java.io.File",
		"android.net.Uri", 
		"android.util.Log", 
		"android.content.Intent")]
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

				//FileProvider way for Marshmallow+ (API 23)
				if (Build.VERSION.SDK_INT > Build.VERSION_CODES.LOLLIPOP) {

					File photoFile = p.getFile();
					if (photoFile != null) {
						Uri photoURI = FileProvider.getUriForFile(
							com.fuse.Activity.getRootActivity(),
							"@(Activity.Package).camera_file_provider",
							photoFile);
						intent.putExtra(MediaStore.EXTRA_OUTPUT, photoURI);
					} else {
						return null;
					}
				} else {
					intent.putExtra(MediaStore.EXTRA_OUTPUT, p.getFileUri());
				}

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

	[ForeignInclude(Language.Java, "com.fuse.Activity", "com.fuse.camera.Image", "android.content.Intent", "com.fuse.camera.ImageStorageTools")]
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
					p.correctOrientationFromExif();
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
	
	[ForeignInclude(Language.Java, "android.provider.MediaStore", "com.fuse.Activity", "android.content.Intent", "com.fuse.camera.Image", "com.fuse.camera.ImageStorageTools", "androidx.core.content.ContextCompat")]
	extern (Android) class CheckPermissionsCommand
	{
		public CheckPermissionsCommand(Promise<string> p)
		{
			var cb = new PromiseCallback<string>(p);
			CheckPermissionsInternal(cb.Resolve, cb.Reject);
		}
		
		[Foreign(Language.Java)]
		internal static void CheckPermissionsInternal(Action<string> onComplete, Action<string> onFail)
		@{
			if (ContextCompat.checkSelfPermission(com.fuse.Activity.getRootActivity(), android.Manifest.permission.READ_EXTERNAL_STORAGE) != com.fuse.Activity.getRootActivity().getPackageManager().PERMISSION_GRANTED)
			{
				onFail.run("User does not have permission to read");
			}
			else if (ContextCompat.checkSelfPermission(com.fuse.Activity.getRootActivity(), android.Manifest.permission.WRITE_EXTERNAL_STORAGE) != com.fuse.Activity.getRootActivity().getPackageManager().PERMISSION_GRANTED)
			{
				onFail.run("User does not have permission to write");
			}
			else if (ContextCompat.checkSelfPermission(com.fuse.Activity.getRootActivity(), android.Manifest.permission.CAMERA) != com.fuse.Activity.getRootActivity().getPackageManager().PERMISSION_GRANTED)
			{
				onFail.run("User does not have permission access the camera");
			}
			else
			{
				onComplete.run("User has permission to read, write and access camera");
			}
		@}
	}
	
	[ForeignInclude(Language.Java, "android.provider.MediaStore", "com.fuse.Activity", "android.content.Intent", "com.fuse.camera.Image", "com.fuse.camera.ImageStorageTools")]
	extern (Android) class requestAndroidPermissions
	{
		PromiseCallback<string> _callback;
		public requestAndroidPermissions(Promise<string> p)
		{
			_callback = new PromiseCallback<string>(p);
		}
		
		public void Execute()
		{
			Permissions.Request(new PlatformPermission[] { Permissions.Android.WRITE_EXTERNAL_STORAGE, Permissions.Android.READ_EXTERNAL_STORAGE, Permissions.Android.CAMERA }).Then(OnPermissions, OnRejected);
		}

		void OnPermissions(PlatformPermission[] grantedPermissions)
		{
			if(grantedPermissions.Length == 3)
			{
				_callback.Resolve("Success");
			}
			else
			{
				_callback.Reject("Required permission was not granted.");
			}
		}

		void OnRejected(Exception e)
		{
			_callback.Reject(e.Message);
		}
	}
}
