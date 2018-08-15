using Uno.Threading;
using Uno;
using Uno.UX;
using Fuse.Scripting;
using Fuse.ImageTools;
namespace Fuse.Camera
{
	/**
		@scriptmodule FuseJS/Camera

		Allows the capture of still images from the system camera.

		Images are returned as frozen JavaScript Image objects, consisting of a path, a filename, a width and a height.
		Once created or acquired, Images can be passed around to other APIs to use, fetch or alter their underlying data.
		All images are temporary "scratch images" until storage has been specified either through publishing to the CameraRoll or other.

		You need to add a reference to `"Fuse.Camera"` in your project file to use this feature.

		On Android using this API will request the CAMERA and WRITE_EXTERNAL_STORAGE permissions.

		## Example

			var camera = require('FuseJS/Camera');
			camera.takePicture(640,480).then(function(image)
			{
			    //Do things with image here
			}).catch(function(error) {
			    //Something went wrong, see error for details
			});
	*/
	[UXGlobalModule]
	public sealed class Camera : NativeModule
	{
		static readonly Camera _instance;
		public Camera()
		{
			if(_instance != null)return;
			Resource.SetGlobalKey(_instance = this, "FuseJS/Camera");
			AddMember(new NativePromise<Image, Scripting.Object>("takePicture", TakePictureInterface, Image.Converter));
			AddMember(new NativePromise<string, string>("checkPermissions", CheckUserPermissions, null));
			AddMember(new NativePromise<string, string>("requestPermissions", RequestUserPermissions, null));
		}

		/**
			@scriptmethod takePicture([desiredWidth, desiredHeight])

			Starts an OS-specific image capture view and returns a Promise of the resulting Image.

			If the desiredWidth and height parameters are set, returns an Image scaled as close to the specified
			width/height as possible while maintaining aspect ratio. 

			If no size parameters are given, the taken image will be full-sized as determined by the device camera.

			The image capture view is user-configurable on Android.

			@param desiredWidth (int) the desired image width in pixels.
			@param desiredHeight (int) the desired image height in pixels. Defaults to the value of desiredWidth if that value is set.

			@return (Promise) a Promise of a device-orientation-corrected read/writable Image.
		*/
		static Future<Image> TakePictureInterface(object[] args)
		{
			if(args.Length==0) return TakePicture();
			var width = args.ValueOrDefault<int>(0);
			var height = args.ValueOrDefault<int>(1, width);
			var p = new Promise<Image>();
			if(width <= 0 || height <= 0) {
				p.Reject(new Exception("Negative image size values are not supported"));
				return p;
			}
			var cb = new ResizeImageCallback(p, width, height);
			TakePicture(cb.ImagePromise);
			return p;
		}

		internal static Future<Image> TakePicture()
		{
			return TakePicture(new Promise<Image>());
		}

		internal static Future<Image> TakePicture(Promise<Image> p)
		{
			if defined(Android)
				AndroidCamera.TakePicture(p);
			else if defined(iOS)
				iOSCamera.TakePicture(p);
			else
				p.Reject(new Exception("Camera unsupported on current platform"));

			return p;
		}

		/**
			@scriptmethod checkPermissions()

			Checks if device has permissions to access the camera.

			@return (Promise) a Promise that resolves if the user has permission
		*/
		static Future<string> CheckUserPermissions(object[] args)
		{
			var p = new Promise<string>();
			if defined(Android)
				AndroidCamera.CheckPermissions(p);
			else if defined(iOS)
				iOSCamera.CheckPermissions(p);
			return p;
		}

		/**
			@scriptmethod requestPermissions()

			Requests acccess to the camera

			@return (Promise) a Promise that resolves after the user has granted permissions
		*/
		static Future<string> RequestUserPermissions(object[] args) 
		{
			var p = new Promise<string>();
			if defined(Android)
				AndroidCamera.RequestPermissions(p);
			else if defined(iOS)
				iOSCamera.RequestPermissions(p);
			return p;
		}
	}

	class ResizeImageCallback
	{
		public Promise<Image> ImagePromise { get; private set; }
		Promise<Image> _promise;
		int _width;
		int _height;
		public ResizeImageCallback(Promise<Image> p, int width, int height)
		{
			_width = width;
			_height = height;
			_promise = p;
			ImagePromise = new Promise<Image>();
			ImagePromise.Then(ResolveTaken, _promise.Reject);
		}

		void ResolveTaken(Image img){
			ImagePromise = (Promise<Image>) ImageTools.ImageTools.Resize(img, _width, _height, ResizeMode.KeepAspect);
			ImagePromise.Then(ResolveResized, _promise.Reject);
		}

		void ResolveResized(Image img){
			_promise.Resolve(img);
		}
	}
}
