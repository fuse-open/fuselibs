using Uno.Threading;
using Uno;
using Uno.UX;
using Fuse.Scripting;
using Uno.Permissions;
using Fuse.Scripting.JSObjectUtils;
namespace Fuse.ImageTools
{

	public enum ResizeMode
	{
		IgnoreAspect = 0,
		KeepAspect = 1,
		ScaleAndCrop = 2
	}

	/**
		@scriptmodule FuseJS/ImageTools

		Utility methods for common Image manipulation.
		
		> To use this module, add `Fuse.ImageTools` to your package references in your `.unoproj`.

		Fuse represents images as frozen JavaScript Image objects, consisting of a path, a filename, a width and a height.
		Once created or acquired, Images can be passed around to other APIs to use, fetch or alter their underlying data.
		All images are temporary "scratch images" until storage has been specified either through publishing to the CameraRoll or other.

		On Android using this API will request the WRITE_EXTERNAL_STORAGE and READ_EXTERNAL_STORAGE permissions.

		## Example

			<JavaScript>
				var ImageTools = require("FuseJS/ImageTools");
				var Observable = require("FuseJS/Observable");

				var imagePath = Observable();
				var base64Image =	"iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPAQMAAAABGAcJAAAABlBMVEX9//wAAQATpOzaAAAAH0l" +
									"EQVQI12MAAoMHIFLAAYSEwIiJgYGZASrI38AAAwBamgM5VF7xgwAAAABJRU5ErkJggg==";
				ImageTools.getImageFromBase64(base64Image)
				.then(function(image) {
					imagePath.value = image.path;
				});

				module.exports = { test: new Date().toString(), image: imagePath };
			</JavaScript>
			<Image File="{image}" />
	*/
	[UXGlobalModule]
	public class ImageTools : NativeModule
	{

		static readonly ImageTools _instance;

		public ImageTools()
		{
			if(_instance != null) return;
			Resource.SetGlobalKey(_instance = this, "FuseJS/ImageTools");
			AddMember(new NativePromise<Image, Scripting.Object>("resize", ResizeImageInterface, Image.Converter));
			AddMember(new NativePromise<Image, Scripting.Object>("crop", CropImageInterface, Image.Converter));
			AddMember(new NativePromise<Image, Scripting.Object>("getImageFromBase64", ImageFromBase64Interface, Image.Converter));
			AddMember(new NativePromise<string, Scripting.Object>("getBase64FromImage", Base64FromImageInterface, null));
			AddMember(new NativePromise<Image, Scripting.Object>("getImageFromBuffer", ImageFromBufferInterface, Image.Converter));
			AddMember(new NativePromise<byte[], Scripting.Object>("getBufferFromImage", BufferFromImageInterface, null));
			AddMember(new NativeProperty<object, int>("IGNORE_ASPECT", ResizeMode.IgnoreAspect));
			AddMember(new NativeProperty<object, int>("KEEP_ASPECT", ResizeMode.KeepAspect));
			AddMember(new NativeProperty<object, int>("SCALE_AND_CROP", ResizeMode.ScaleAndCrop));
		}
		
		public static Image ImageFromByteArray(byte[] bytes)
		{
			if defined(Android)
			{
				sbyte[] sbytes = new sbyte[bytes.Length];
				for(var i = 0; i<bytes.Length; i++)
					sbytes[i] = (sbyte) bytes[i];
				return new Image(AndroidImageUtils.GetImageFromBufferSync(sbytes));
			}
			else if defined(iOS)
			{
				return new Image(iOSImageUtils.GetImageFromBufferSync(bytes));
			}
			else
			{
				debug_log("ImageFromByteArray not supported on current platform.");
				return null;
			}
		}

		/**
			@scriptmethod getImageFromBuffer(imageData)
			@param imageData (ArrayBuffer) The image data
			@return (Promise) a Promise of an Image

			Creates a new temporary image file from an ArrayBuffer of image data.

			## Example

				var ImageTools = require("FuseJS/ImageTools");
				ImageTools.getImageFromBuffer(imageData).
					then(function (image) { console.log("Scratch image path is: " + image.path); });
		*/
		Future<Image> ImageFromBufferInterface(object[] args)
		{
			var p = new Promise<Image>();
			var cb = new ImagePromiseCallback(p);
			if(args.Length == 1){
				var bytes = args[0] as byte[];
				if(bytes!=null)
				{
					if defined(Android)
					{
						sbyte[] sbytes = new sbyte[bytes.Length];
						for(var i = 0; i<bytes.Length; i++)
							sbytes[i] = (sbyte) bytes[i];
						AndroidImageUtils.GetImageFromBuffer(sbytes, cb.Resolve, cb.Reject);
					}
					else if defined(iOS)
					{
						iOSImageUtils.GetImageFromBuffer(bytes, cb.Resolve, cb.Reject);
					}
					else
					{
						cb.Reject("Not supported on current platform.");
					}
				}else{
						cb.Reject("getImageFromBuffer requires an arraybuffer argument");
				}
			}else{
					cb.Reject("getImageFromBuffer requires an arraybuffer argument");
			}

			return p;
		}

		/**
			@scriptmethod getBufferFromImage(image)
			@param image (Object) The image to fetch data for
			@return (Promise) a Promise of an ArrayBuffer of image data

			Retrieves the underlying image data for an image as an ArrayBuffer.

			## Example

				// Here image is expected to be an `Image` object
				var ImageTools = require("FuseJS/ImageTools");
				ImageTools.getBufferFromImage(image)
					.then(function(buf) { console.log("Image contains " + buf.byteLength + " bytes"); });
		*/
		Future<byte[]> BufferFromImageInterface(object[] args)
		{
			var p = new Promise<byte[]>();
			if(args.Length == 1){
				var img = Image.FromObject(args[0]);
				if(img != null)
				{
					try
					{
						byte[] bytes = Uno.IO.File.ReadAllBytes(img.Path);
						p.Resolve(bytes);
					}catch(Exception e)
					{
						p.Reject(e);
					}
				}else{
					p.Reject(new Exception("Invalid image reference"));
				}
			}else{
				p.Reject(new Exception("Invalid arguments"));
			}
			return p;
		}

		/**
			@scriptmethod resize(image, options)
			@param image (Object) The image to resize
			@param options (Object) The resize options
			@return (Promise) a Promise of an Image

			Resizes an image using the options provided, and returns a Promise of the transformed Image.

			The `options` parameter must be an object with one or more of the following properties defined:

			* `desiredWidth` - The new width in pixels
			* `desiredHeight` - The new height in pixels
			* `mode` - The resizing mode, which can be:
			  - `ImageTools.IGNORE_ASPECT` - The image is resized exactly to the desired width and height. This is the default.
			  - `ImageTools.KEEP_ASPECT`- The image is resized to within the closest size possible to the desired size while still maintaining the original aspect ratio.
			  - `ImageTools.SCALE_AND_CROP` - The image is first scaled and centered while maintaining aspect to the closest edge of the desired bounds, then cropped according to the Crop rule. This allows you to make an aspect correct square portrait out of a landscape shot, for instance.
			* `performInPlace` - Boolean value determining whether the existing image will replaced

			## Example

				// Here we assume that we have an existing image variable `originalImage`
				var ImageTools = require("FuseJS/ImageTools");

				var options = {
					mode: ImageTools.IGNORE_ASPECT,
					desiredWidth: 320, //The desired width in pixels
					desiredHeight: 240 //The desired height in pixels
				};

				ImageTools.resize(originalImage, options)
					.then(function(newImage) { console.log("Path of resized image is " + newImage.path); });
		*/
		Future<Image> ResizeImageInterface(object[] args)
		{
			if(args.Length!=2)
				throw new Exception("resize takes 2 arguments: An Image and an Object of options");

			var image = Image.FromObject(args[0]);
			var opts = args[1] as Scripting.Object;
			var w = opts.ValueOrDefault<int>("desiredWidth", -1);
			if(w==-1)
				throw new Exception("desiredWidth must be defined");
			var h = opts.ValueOrDefault<int>("desiredHeight", w);
			var m = (ResizeMode)opts.ValueOrDefault<int>("mode", 3);
			var inPlace = opts.ValueOrDefault<bool>("performInPlace", true);

			return Resize(image, w, h, m, inPlace);
		}

		/**
			@scriptmethod crop(image, options)
			@param image (Object) The image to crop
			@param options (Object) The crop options
			@return (Promise) a Promise of an Image

			Crops the supplied `image`, and returns a Promise of the transformed Image.

			The `options` parameter must be an object with one or more of the following properties defined:

			* `x` - X offset for cropped image, from left
			* `y` - Y offset for cropped image, from top
			* `width` - Width of cropped image
			* `height` - Height of cropped image
			* `performInPlace` - Boolean value determining whether the existing image will replaced

			## Example

				// Here we assume that we have an existing image variable `originalImage`
				var ImageTools = require("FuseJS/ImageTools");

				var options = {
					width: 10, // Width of cropped image
					height: 10 // Height of cropped image
				};

				ImageTools.crop(originalImage, options)
					.then(function(newImage) { console.log("Path of cropped image is " + newImage.path); });
		*/
		Future<Image> CropImageInterface(object[] args)
		{
			if(args.Length!=2)
				throw new Exception("crop takes 2 arguments: An Image and an options object");

			var image = Image.FromObject(args[0]);

			var opts = args[1] as Scripting.Object;
			var width = 0;
			var height = 0;
			var x = 0;
			var y = 0;
			var inPlace = true;
			if(opts!=null)
			{
				x = opts.ValueOrDefault<int>("x", 0);
				y = opts.ValueOrDefault<int>("y", 0);
				width = opts.ValueOrDefault<int>("width", 0);
				height = opts.ValueOrDefault<int>("height", width);
				inPlace = opts.ValueOrDefault<bool>("performInPlace", true);
			}

			if(width==0||height==0)
				throw new Exception("Width and height must be larger than 0");

			return Crop(image, width, height, x, y, inPlace);
		}

		/**
			@scriptmethod getImageFromBase64(base64)
			@param base64 (string) The data to decode
			@return (Promise) a Promise of an Image

			Takes base64 string encoded image data and returns a Promise of an Image.

			## Example

				// Here we assume that someBase64ImageString contains a base-64 encoded image
				var ImageTools = require("FuseJS/ImageTools");
				ImageTools.getImageFromBase64(someBase64ImageString);
					.then(function(image) {
						console.log("Scratch path of image is " + image.path);
					});
		*/
		Future<Image> ImageFromBase64Interface(object[] args)
		{
			if(args.Length!=1)
				throw new Exception("imageFromBase64 needs a base64 string argument");
			var str = args.ValueOrDefault<string>(0);
			return ImageFromBase64(str);
		}

		/**
			@scriptmethod getBase64FromImage(image)
			@param image (Object) The Image to encode
			@return (Promise) a Promise of a string of base64 data

			Encodes the given image as a base64 string.

			## Example

				// Here we assume that we have an existing `image` object
				var ImageTools = require("FuseJS/ImageTools");
				ImageTools.getBase64FromImage(image)
					.then(function(base64Image) { console.log("The base64 encoded image is \"" + base64Image + "\""); });
		*/
		Future<string> Base64FromImageInterface(object[] args)
		{
			if(args.Length!=1)
				throw new Exception("base64FromImage needs a Image argument");

			var image = Image.FromObject(args[0]);
			return ImageToBase64(image);
		}

		public static Future<Image> Resize(Image img, int desiredWidth, int desiredHeight, ResizeMode mode, bool inPlace = true)
		{
			var p = new Promise<Image>();
			var closure = new ImagePromiseCallback(p);
			if defined(Android)
			{
				new ResizeCommand(img.Path, desiredWidth, desiredHeight, (int)mode, closure.Resolve, closure.Reject, inPlace).Execute();
			}
			else if defined(iOS)
			{
				iOSImageUtils.Resize(img.Path, desiredWidth, desiredHeight, (int)mode, closure.Resolve, closure.Reject, inPlace);
			}
			else
			{
				closure.Reject("Unsupported platform");
			}
			return p;
		}

		public static Future<Image> Crop(Image img, int width, int height, int x, int y, bool inPlace = true)
		{
			var p = new Promise<Image>();
			var closure = new ImagePromiseCallback(p);
			if defined(Android)
				new CropCommand(img.Path, x, y, width, height, closure.Resolve, closure.Reject, inPlace).Execute();
			else if defined(iOS)
				iOSImageUtils.Crop(img.Path, x, y, width, height, closure.Resolve, closure.Reject, inPlace);
			else
				closure.Resolve(img.Path);
			return p;
		}

		extern (Android) class GetBase64Command : PCommand {
			string _path;
			Action<string> _resolve;
			Action<string> _reject;
			public GetBase64Command(string path, Action<string> Resolve, Action<string> Reject) : base(new PlatformPermission[] { Permissions.Android.READ_EXTERNAL_STORAGE })
			{
				_path = path;
				_resolve = Resolve;
				_reject = Reject;
			}
			override void OnGranted()
			{
				AndroidImageUtils.GetBase64FromImage(_path, _resolve, _reject);
			}

			override void OnRejected(Exception e)
			{
				_reject(e.Message);
			}
		}

		public static Future<string> ImageToBase64(Image img)
		{
			var p = new Promise<string>();
			var closure = new PromiseCallback<string>(p);
			if defined(Android)
				new GetBase64Command(img.Path,closure.Resolve, closure.Reject).Execute();
			else if defined(iOS)
				iOSImageUtils.GetBase64FromImage(img.Path, closure.Resolve, closure.Reject);
			else if defined(dotnet)
				DotNetImageUtils.GetBase64FromImage(img.Path, closure.Resolve, closure.Reject);
			else
				closure.Reject("Unsupported platform");
			return p;
		}

		extern (Android) class ImageFromBase64Command : PCommand {
			string _base64Image;
			Action<string> _resolve;
			Action<string> _reject;
			public ImageFromBase64Command(string base64Image, Action<string> Resolve, Action<string> Reject) : base(new PlatformPermission[] { Permissions.Android.WRITE_EXTERNAL_STORAGE })
			{
				_base64Image = base64Image;
				_resolve = Resolve;
				_reject = Reject;
			}
			override void OnGranted()
			{
				AndroidImageUtils.GetImageFromBase64(_base64Image, _resolve, _reject);
			}

			override void OnRejected(Exception e)
			{
				_reject(e.Message);
			}
		}

		public static Future<Image> ImageFromBase64(string b64)
		{
			var p = new Promise<Image>();
			var closure = new ImagePromiseCallback(p);
			if defined(Android)
				new ImageFromBase64Command(b64, closure.Resolve, closure.Reject).Execute();
			else if defined(iOS)
				iOSImageUtils.GetImageFromBase64(b64, closure.Resolve, closure.Reject);
			else if defined(dotnet)
				DotNetImageUtils.GetImageFromBase64(b64, closure.Resolve, closure.Reject);
			else
				closure.Reject("Unsupported platform");
			return p;
		}

	}
}
