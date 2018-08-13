using Uno.Threading;
using Uno;
using Uno.Compiler.ExportTargetInterop;
using Android;
using Fuse.ImageTools;
using Uno.Permissions;
namespace Fuse.CameraRoll
{
	[ForeignInclude(Language.Java, "com.fuse.Activity", "com.fusetools.camera.Image", "android.content.Intent", "com.fusetools.camera.ImageStorageTools")]
	extern (Android) internal class SelectPictureClosure
	{
		Promise<Image> _p;
		public SelectPictureClosure(Promise<Image> p)
		{
			_p = p;
		}


		public void OnActivityResult(int resultCode, Java.Object intent, object info)
		{
			HandleIntent(resultCode, intent, OnComplete, OnFail);
		}

		[Foreign(Language.Java)]
		void HandleIntent(int resultCode, Java.Object intent, Action<string> onComplete, Action<string> onFail)
		@{
			Intent i = (Intent)intent;
			switch (resultCode)
			{
				case android.app.Activity.RESULT_OK:
					try{
						Image scratch = ImageStorageTools.createScratchFromUri(i.getData());
						String ext = scratch.getExtension().toLowerCase();
						if(ext.equals("jpg") || ext.equals("jpeg") || ext.equals("raw"))
							scratch.correctOrientationFromExif();

						onComplete.run(scratch.getFilePath());
					}catch(Exception e){
						e.printStackTrace();
						onFail.run(e.getMessage());
					}
					return;
				case android.app.Activity.RESULT_CANCELED:
					onFail.run("User aborted select");
					return;
				default:
					onFail.run("Picture could not be selected");
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

	[ForeignInclude(Language.Java, "android.provider.MediaStore", "com.fuse.Activity", "android.content.Intent", "com.fusetools.camera.Image", "com.fusetools.camera.ImageStorageTools")]
	extern (Android) class SelectPicturePermissionCheckCommand
	{
		SelectPictureClosure _closure;
		public SelectPicturePermissionCheckCommand(Promise<Image> p)
		{
			_closure = new SelectPictureClosure(p);
		}


		[Foreign(Language.Java)]
		static Java.Object CreateIntent()
		@{
			Intent intent = new Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
			intent.setType("image/*");
			return intent;
		@}

		public void Execute()
		{
			Permissions.Request(new PlatformPermission[] { Permissions.Android.WRITE_EXTERNAL_STORAGE, Permissions.Android.READ_EXTERNAL_STORAGE }).Then(OnPermissions, OnRejected);
		}

		void OnPermissions(PlatformPermission[] grantedPermissions)
		{
			if(grantedPermissions.Length == 2)
			{
				var intent = CreateIntent();
				if(intent==null){
					throw new Exception("Couldn't create valid intent");
				}
				ActivityUtils.StartActivity(intent, _closure.OnActivityResult);
			}else{
				_closure.OnFail("Required permission was not granted.");
			}

		}

		void OnRejected(Exception e)
		{
			_closure.OnFail(e.Message);
		}
	}

	[ForeignInclude(Language.Java, "android.provider.MediaStore", "com.fuse.Activity", "android.content.Intent", "com.fusetools.camera.Image", "com.fusetools.camera.ImageStorageTools")]
	extern (Android) class AddPicturePermissionCheckCommand
	{
		BoolPromiseCallback _callback;
		string _path;
		public AddPicturePermissionCheckCommand(Promise<bool> p, string path)
		{
			_path = path;
			_callback = new BoolPromiseCallback(p);
		}

		public void Execute()
		{
			Permissions.Request(new PlatformPermission[] { Permissions.Android.WRITE_EXTERNAL_STORAGE, Permissions.Android.READ_EXTERNAL_STORAGE }).Then(OnPermissions, OnRejected);
		}

		void OnPermissions(PlatformPermission[] grantedPermissions)
		{
			if(grantedPermissions.Length == 2)
			{
				AddToCameraRollInternal(_path, _callback.Resolve, _callback.Reject);
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

		[Foreign(Language.Java)]
		internal static void AddToCameraRollInternal(string path, Action success, Action<string> reject)
		@{
			try{
				Image p = Image.fromPath(path);
				Image newImage = ImageStorageTools.copyImage(p.getFile(), ImageStorageTools.getOutputMediaFile(false, p.getFileName()), false);
				Intent mediaScanIntent = new Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE);
				mediaScanIntent.setData(newImage.getFileUri());
				com.fuse.Activity.getRootActivity().sendBroadcast(mediaScanIntent);
				success.run();
			}catch(Exception e){
				reject.run(e.getMessage());
			}
		@}

	}
	
	[ForeignInclude(Language.Java, "android.provider.MediaStore", "com.fuse.Activity", "android.content.Intent", "com.fusetools.camera.Image", "com.fusetools.camera.ImageStorageTools", "android.support.v4.content.ContextCompat")]
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
			else
			{
				onComplete.run("User has permission to read and write");
			}
		@}
	}
	
	[ForeignInclude(Language.Java, "android.provider.MediaStore", "com.fuse.Activity", "android.content.Intent", "com.fusetools.camera.Image", "com.fusetools.camera.ImageStorageTools")]
	extern (Android) class requestAndroidPermissions
	{
		PromiseCallback<string> _callback;
		public requestAndroidPermissions(Promise<string> p)
		{
			_callback = new PromiseCallback<string>(p);
		}
		
		public void Execute()
		{
			Permissions.Request(new PlatformPermission[] { Permissions.Android.WRITE_EXTERNAL_STORAGE, Permissions.Android.READ_EXTERNAL_STORAGE }).Then(OnPermissions, OnRejected);
		}

		void OnPermissions(PlatformPermission[] grantedPermissions)
		{
			if(grantedPermissions.Length == 2)
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
	
	[ForeignInclude(Language.Java, "android.provider.MediaStore", "com.fuse.Activity", "android.content.Intent", "com.fusetools.camera.Image", "com.fusetools.camera.ImageStorageTools")]
	extern (Android) static internal class AndroidCameraRoll
	{
		internal static void SelectPicture(Promise<Image> p)
		{
			new SelectPicturePermissionCheckCommand(p).Execute();
		}

		internal static Future<bool> AddToCameraRoll(Image photo)
		{
			var p = new Promise<bool>();
			new AddPicturePermissionCheckCommand(p, photo.Path).Execute();
			return p;
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
}
