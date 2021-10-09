using Uno.Threading;
using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;
using Fuse;
using Fuse.Scripting;

namespace Fuse.MediaPicker
{
	/**
		@scriptmodule FuseJS/MediaPicker

		Allows for picking images or video from the image library, and taking new pictures or record video with the camera.
		To use these features, you can invoke the provided `pickImage` or `pickVideo` methods. You have to pass an object javascript as a method's argument to setup on how you want to get the media from the device. Take a look at the example to see the detail.
		You can also pick multiple images, but only works with iOS 14 later, and Android starts from 4.4 later.

		You need to add a reference to `"Fuse.MediaPicker"` in your project file to use this feature.
		On Android using this API will request the CAMERA and WRITE_EXTERNAL_STORAGE permissions.

		## Example

			var mediaPicker = require('FuseJS/MediaPicker');
			var options = {
				source: mediaPicker.SOURCE_GALLERY, // pick image from gallery, use mediaPicker.SOURCE_CAMERA for taking picture or record video from the device camera
				maxWidth: 1024, // resize image width
				maxHeight: 1024, // resize image height
				quality: 100, // the image quality: 0 - 100
				maxDuration: 120, // filter the duration of the video file to pick or record (in seconds) note: on Android it might not be work 100% or even completely ignored. it depends on the device manufacturer to implement the video picker
				maxImages: 5 // allow for maximum 5 image to pick
			}
			mediaPicker.pickImage(options).then(function(imagePath)
			{
				//imagePath is string array of path image
			}).catch(function(error) {
				//Something went wrong, see error for details
			});

			mediaPicker.pickVideo(options).then(function(videoPath)
			{
				//videoPath is a string array of path video
			}).catch(function(error) {
				//Something went wrong, see error for details
			});

		> **Note**: This package is considered as the advanced version of the `Fuse.CameraRoll` `getImage` method, where in this package we have options to pick media (images & video) from the gallery or by taking from the device camera.
	*/
	[UXGlobalModule]
	public sealed class MediaPicker : NativeModule
	{
		static readonly MediaPicker _instance;
		public MediaPicker()
		{
			if(_instance != null) return;

			Resource.SetGlobalKey(_instance = this, "FuseJS/MediaPicker");

			AddMember(new NativePromise<string, Scripting.Array>("pickImage", PickImageInterface, Converter));
			AddMember(new NativePromise<string, string>("pickVideo", PickVideoInterface));
			AddMember(new NativeProperty<int, int>("SOURCE_CAMERA", SourceCamera));
			AddMember(new NativeProperty<int, int>("SOURCE_GALLERY", SourceGallery));
		}

		/**
			@scriptmethod pickImage(options)

			Starts an OS-specific image picker view.

			@return (Promise) a Promise of images path array.
		*/
		static Future<string> PickImageInterface(object[] args)
		{
			var arguments = args[0] as Scripting.Object;
			var p = new Promise<string>();
			PickImage(p, arguments);
			return p;
		}

		internal static Future<string> PickImage(Promise<string> p, Scripting.Object args)
		{
			if defined(iOS)
				iOSMediaPicker.PickImage(p, ConstructArguments(args));
			else if defined(Android)
				AndroidMediaPicker.PickImage(p, ConstructArguments(args));
			else
				p.Reject(new Exception("Unsupported on current platform"));

			return p;
		}

		static int SourceCamera() {
			return 0;
		}

		static int SourceGallery() {
			return 1;
		}

		/**
			@scriptmethod pickVideo(options)

			Starts an OS-specific video picker view.

			@return (Promise) a Promise of a video path.
		*/
		static Future<string> PickVideoInterface(object[] args)
		{
			var arguments = args[0] as Scripting.Object;

			var p = new Promise<string>();
			PickVideo(p, arguments);
			return p;
		}

		internal static Future<string> PickVideo(Promise<string> p, Scripting.Object args)
		{
			if defined(iOS)
				iOSMediaPicker.PickVideo(p, ConstructArguments(args));
			else if defined(Android)
				AndroidMediaPicker.PickVideo(p, ConstructArguments(args));
			else
				p.Reject(new Exception("Unsupported on current platform"));

			return p;
		}

		static extern(Android) Java.Object ConstructArguments(Scripting.Object args)
		{
			int source = 1;
			int maxImages = 1;
			int maxDuration = 0;
			double maxWidth = 1024;
			double maxHeight = 1024;
			int quality = 100;
			if (args != null)
			{
				if (args.ContainsKey("source"))
				{
					source = Marshal.ToInt(args["source"]);
					source = source > 1 ? 1 : source;
				}
				if (args.ContainsKey("maxWidth"))
					maxWidth = Marshal.ToDouble(args["maxWidth"]);
				if (args.ContainsKey("maxHeight"))
					maxHeight = Marshal.ToDouble(args["maxHeight"]);
				if (args.ContainsKey("quality"))
					quality = Marshal.ToInt(args["quality"]);
				if (args.ContainsKey("maxImages"))
					maxImages = Marshal.ToInt(args["maxImages"]);
				if (args.ContainsKey("maxDuration"))
					maxDuration = Marshal.ToInt(args["maxDuration"]);
			}
			return ConstructArgumentsAndroid(source, maxWidth, maxHeight, quality, maxImages, maxDuration);
		}

		[Foreign(Language.Java)]
		static extern(Android) Java.Object ConstructArgumentsAndroid(int source, double maxWidth, double maxHeight, int quality, int maxImages, int maxDuration)
		@{
			java.util.Map<String, Object> args = new java.util.HashMap<String, Object>();
			args.put("source", source);
			args.put("maxWidth", new Double(maxWidth));
			args.put("maxHeight", new Double(maxHeight));
			args.put("imageQuality", quality);
			args.put("maxImages", maxImages);
			args.put("maxDuration", maxDuration);
			return args;
		@}

		static extern(iOS) ObjC.Object ConstructArguments(Scripting.Object args)
		{
			int source = 1;
			int maxImages = 1;
			int maxDuration = 0;
			int maxWidth = 1024;
			int maxHeight = 1024;
			int quality = 100;
			if (args != null)
			{
				if (args.ContainsKey("source"))
				{
					source = Marshal.ToInt(args["source"]);
					source = source > 1 ? 1 : source;
				}
				if (args.ContainsKey("maxWidth"))
					maxWidth = Marshal.ToInt(args["maxWidth"]);
				if (args.ContainsKey("maxHeight"))
					maxHeight = Marshal.ToInt(args["maxHeight"]);
				if (args.ContainsKey("quality"))
					quality = Marshal.ToInt(args["quality"]);
				if (args.ContainsKey("maxImages"))
					maxImages = Marshal.ToInt(args["maxImages"]);
				if (args.ContainsKey("maxDuration"))
					maxDuration = Marshal.ToInt(args["maxDuration"]);
			}
			return ConstructArgumentsIOS(source, maxWidth, maxHeight, quality, maxImages, maxDuration);
		}

		[Foreign(Language.ObjC)]
		static extern(iOS) ObjC.Object ConstructArgumentsIOS(int source, int maxWidth, int maxHeight, int quality, int maxImages, int maxDuration)
		@{
			NSMutableDictionary* args = [NSMutableDictionary dictionary];
			[args setObject:[[NSNumber alloc] initWithInt:source] forKey:@"source"];
			[args setObject:[[NSNumber alloc] initWithInt:maxWidth] forKey:@"maxWidth"];
			[args setObject:[[NSNumber alloc] initWithInt:maxHeight] forKey:@"maxHeight"];
			[args setObject:[[NSNumber alloc] initWithInt:quality] forKey:@"imageQuality"];
			[args setObject:[[NSNumber alloc] initWithInt:maxImages] forKey:@"maxImages"];
			[args setObject:[[NSNumber alloc] initWithInt:maxDuration] forKey:@"maxDuration"];
			return args;
		@}

		public static Scripting.Array Converter(Context context, string result)
		{
			if (result != null)
			{
				var output = context.NewArray();
				var i = 0;
				var list = result.Split(",".ToCharArray());
				foreach(var path in list)
					output[i++] = path;
				return output;
			}
			return null;
		}

	}

	internal sealed class StringPromiseCallback
	{
		Promise<string> _p;
		public StringPromiseCallback(Promise<string> p)
		{
			_p = p;
		}

		public void Resolve(string v)
		{
			_p.Resolve(v);
		}

		public void Reject(string reason)
		{
			_p.Reject(new Exception(reason));
		}
	}
}
