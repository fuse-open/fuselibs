using Uno.Threading;
using Fuse.Scripting;
using Uno.UX;
using Fuse.ImageTools;
namespace Fuse.CameraRoll
{
	[UXGlobalModule]
	/**
		@scriptmodule FuseJS/CameraRoll

		Allows adding images to- and fetching images from the system image gallery.

		Fuse represents images as frozen JavaScript Image objects, consisting of a path, a filename, a width and a height.
		Once created or acquired, Images can be passed around to other APIs to use, fetch or alter their underlying data.
		All images are temporary "scratch images" until storage has been specified either through publishing to the CameraRoll or other.

		Using this API on Android will request the `WRITE_EXTERNAL_STORAGE` and `READ_EXTERNAL_STORAGE` permissions.
		
		> **Note:** You need to add a package reference to `Fuse.CameraRoll` to use this API.
		
		## Examples
		
		Requesting an image from the camera roll:
		
			var cameraRoll = require("FuseJS/CameraRoll");
			
			cameraRoll.getImage()
			    .then(function(image) {
			        // Will be called if the user successfully selected an image.
			    }, function(error) {
			        // Will be called if the user aborted the selection or if an error occurred.
			    });
		
		Taking a picture with the camera and adding it to the camera roll:
		
			var cameraRoll = require("FuseJS/CameraRoll");
			var camera = require("FuseJS/Camera");
			
			camera.takePicture(640, 480)
			    .then(function(image) {
			        return cameraRoll.publishImage(image);
			    })
			    .then(function() {
			        // Will be called if the image was successfully added to the camera roll.
			    }, function(error) {
			        // Will called if an error occurred.
			    });
		
		> **Note**: You also need to add a package reference to `Fuse.Camera` for the above example to work.
	*/
	public sealed class CameraRoll : NativeModule
	{
		static readonly CameraRoll _instance;
		public CameraRoll()
		{
			if(_instance != null)return;
			Resource.SetGlobalKey(_instance = this, "FuseJS/CameraRoll");
			AddMember(new NativePromise<Image, Scripting.Object>("getImage", SelectPictureInterface, Image.Converter));
			AddMember(new NativePromise<bool, Scripting.Object>("publishImage", AddToCameraRollInterface, null));
			AddMember(new NativePromise<string, string>("checkPermissions", CheckUserPermissions, null));
			AddMember(new NativePromise<string, string>("requestPermissions", RequestUserPermissions, null));
		}

		/**
			@scriptmethod getImage()

			Starts an OS-specific image picker view (user-configurable on Android).

			@return (Promise) a Promise of a local read/writable Image copied from the camera roll.
		*/
		static Future<Image> SelectPictureInterface(object[] args)
		{
			return SelectPicture();
		}

		/**
			@scriptmethod publishImage(image)

			Adds a copy of the Image instance to the system camera roll.

			On Android this is done by copying the image to the application's public image
			storage directory and notifying the media scanner.

			On iOS this is done by uploading a copy of the image to an asset collection
			named after the application within the system photo library.

			@param image (Object) The image to publish

			@return (Promise) a Promise that resolves to `true` when/if the publish completed
		*/
		static Future<bool> AddToCameraRollInterface(object[] args)
		{
			var Image = Image.FromObject(args[0]);
			return AddToCameraRoll(Image);
		}
		
		/**
			@scriptmethod checkPermissions()

			Checks if device has permissions to access the camera roll.

			@return (Promise) a Promise that resolves if the user has permission
		*/
		static Future<string> CheckUserPermissions(object[] args)
		{
			var p = new Promise<string>();
			if defined(Android)
				AndroidCameraRoll.CheckPermissions(p);
			else if defined(iOS)
				iOSCameraRoll.CheckPermissions(p);
			return p;
		}
		
		/**
			@scriptmethod requestPermissions()

			Requests acccess to photo gallery

			@return (Promise) a Promise that resolves after the user has granted permissions
		*/
		static Future<string> RequestUserPermissions(object[] args) 
		{
			var p = new Promise<string>();
			if defined(Android)
				AndroidCameraRoll.RequestPermissions(p);
			else if defined(iOS)
				iOSCameraRoll.RequestPermissions(p);
			return p;
		}

		internal static Future<Image> SelectPicture()
		{
			var p = new Promise<Image>();
			if defined(Android)
				AndroidCameraRoll.SelectPicture(p);
			else if defined(iOS)
				iOSCameraRoll.SelectPicture(p);
			return p;
		}

		internal static Future<bool> AddToCameraRoll(Image photo)
		{
			if defined(Android)
				return AndroidCameraRoll.AddToCameraRoll(photo);
			else if defined(iOS)
				return iOSCameraRoll.AddToCameraRoll(photo);
			else
				return new Promise<bool>();
		}
	}
}
