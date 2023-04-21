using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.UX;
using Uno.Threading;
using Uno.Collections;
using Fuse.Resources.Exif;
using Fuse.Input;
using Fuse.Scripting;
using Fuse.Controls.Internal;
using Fuse.Controls.Native.iOS;
using Fuse.Controls.Native.Android;

namespace Fuse.Controls
{
	[UXGlobalModule]
	public class DrawingCompositor : NativeModule
	{
		static readonly DrawingCompositor _instance;

		public DrawingCompositor()
		{
			if (_instance != null)
				return;
			Resource.SetGlobalKey(_instance = this, "FuseJS/DrawingCompositor");
			AddMember(new NativePromise<string, string>("composite", Composite));
		}

		public Future<string> Composite(object[] args)
		{
			var p = new Promise<string>();

			if (args.Length != 2)
			{
				p.Reject(new Exception("Expected 2 arguments, got: " + args.Length));
				return p;
			}

			object arg1;
			if (!TryGetExternalObject(args[0], out arg1))
			{
				p.Reject(new Exception("First argument not an object"));
				return p;
			}

			DrawingInfo drawingInfo = arg1 as DrawingInfo;
			if (drawingInfo == null)
			{
				p.Reject(new Exception("First argument must be a DrawingInfo object"));
				return p;
			}

			var filePath = args[1] as string;
			if (filePath == null || !Uno.IO.File.Exists(filePath))
			{
				p.Reject(new Exception("Second argument must be a filePath"));
				return p;
			}
			if defined(iOS)
			{
				var bytes = Uno.IO.File.ReadAllBytes(filePath);
				return new iOSCompositor(drawingInfo, bytes);
			}
			else if defined(ANDROID)
			{
				var bytes = Uno.IO.File.ReadAllBytes(filePath);
				return new AndroidCompositor(drawingInfo, bytes);
			}
			else
			{
				var unsupported = new Promise<string>();
				unsupported.Reject(new Exception("Platform not supported"));
				return unsupported;
			}
		}

		static bool TryGetExternalObject(object obj, out object externalObject)
		{
			var sobj = obj as Scripting.Object;
			if (sobj != null && sobj.ContainsKey("external_object"))
			{
				var ext = sobj["external_object"] as Scripting.External;
				if (ext != null)
				{
					externalObject = ext.Object;
					return true;
				}
			}
			externalObject = null;
			return false;
		}
	}

	extern(ANDROID) internal class AndroidCompositor : Promise<string>
	{
		DrawingInfo _drawingInfo;
		byte[] _jpegBytes;

		public AndroidCompositor(DrawingInfo drawingInfo, byte[] jpegBytes) : base(UpdateManager.Dispatcher)
		{
			_drawingInfo = drawingInfo;
			_jpegBytes = jpegBytes;
			RunAsync(Composite);
		}

		[Foreign(Language.Java)]
		static void RunAsync(Action callback)
		@{
			new java.lang.Thread(callback).start();
		@}

		void Composite()
		{
			var bytes = _jpegBytes;
			var drawingInfo = _drawingInfo;
			using (var image = Bitmap.FromJpegBytes(bytes))
			{
				var orientation = Fuse.Resources.Exif.ExifData.FromByteArray(bytes).Orientation;
				var flipSize = ImageOrientationHelpers.FlipSize(orientation);
				var imageSize = (float2)(flipSize ? image.PixelSize.YX : image.PixelSize);

				var it = ImageOrientationHelpers.TransformFromImageOrientation(orientation);
				it.M31 = it.M31 * image.PixelSize.X;
				it.M32 = it.M32 * image.PixelSize.Y;

				var t = float4x4.Identity;
				t.M11 = it.M11;
				t.M12 = it.M12;
				t.M13 = it.M13;

				t.M21 = it.M21;
				t.M22 = it.M22;
				t.M23 = it.M23;

				t.M41 = it.M31;
				t.M42 = it.M32;

				float3 scale;
				float4 quaternion;
				float3 translation;
				Matrix.Decompose(t, out scale, out quaternion, out translation);

				var rotation = 360 - Quaternion.ToEulerAngleDegrees(quaternion).Z;
				translation = -translation;

				var drawingSize = drawingInfo.Size;
				var drawingScale = Math.Min(imageSize.X / drawingSize.X, imageSize.Y / drawingSize.Y);
				var drawingSizeScaled = drawingSize * drawingScale;
				var drawingTranslation = (imageSize - drawingSizeScaled) / 2.0f;

				using (var nativeCanvas = new NativeCanvas((int2)imageSize))
				{
					nativeCanvas.PushRotation(rotation);
					nativeCanvas.PushTranslation(translation.XY);
					nativeCanvas.Draw(image);
					nativeCanvas.PopTranslation();
					nativeCanvas.PopRotation();

					nativeCanvas.PushTranslation(drawingTranslation);
					foreach (var stroke in drawingInfo.Strokes)
						nativeCanvas.Draw(stroke.Scale(drawingScale));
					nativeCanvas.PopTranslation();

					using (var drawingBitmap = nativeCanvas.AsBitmap())
					{
						drawingBitmap
							.SaveJpeg()
							.Then(Resolve, Reject);
					}
				}
			}
		}
	}

	extern(iOS) internal class iOSCompositor : Promise<string>
	{
		DrawingInfo _drawingInfo;
		byte[] _jpegBytes;

		public iOSCompositor(DrawingInfo drawingInfo, byte[] jpegBytes) : base(UpdateManager.Dispatcher)
		{
			_drawingInfo = drawingInfo;
			_jpegBytes = jpegBytes;
			RunAsync(Composite);
		}

		[Foreign(Language.ObjC)]
		static void RunAsync(Action callback)
		@{
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				callback();
			});
		@}

		void Composite()
		{
			var bytes = _jpegBytes;
			var drawingInfo = _drawingInfo;
			using (var image = CGImage.FromJpegBytes(bytes))
			{
				var orientation = Fuse.Resources.Exif.ExifData.FromByteArray(bytes).Orientation;
				var flipSize = ImageOrientationHelpers.FlipSize(orientation);
				var imageSize = (float2)(flipSize ? image.Size.YX : image.Size);
				var imageTransform = ImageOrientationHelpers.TransformFromImageOrientation(orientation);

				imageTransform.M31 = imageTransform.M31 * imageSize.X;
				imageTransform.M32 = imageTransform.M32 * imageSize.Y;

				var drawingSize = drawingInfo.Size;
				var drawingScale = Math.Min(imageSize.X / drawingSize.X, imageSize.Y / drawingSize.Y);
				var drawingSizeScaled = drawingSize * drawingScale;

				var translation = (imageSize - drawingSizeScaled) / 2.0f;

				var drawingTransform = float3x3.Identity;
				drawingTransform.M11 = 1.0f;
				drawingTransform.M22 = -1.0f;
				drawingTransform.M31 = translation.X;
				drawingTransform.M32 = translation.Y + drawingSizeScaled.Y;

				using (var nativeCanvas = new NativeCanvas((int2)imageSize))
				{
					nativeCanvas.PushTransform(imageTransform);
					nativeCanvas.Draw(image);
					nativeCanvas.PopTransform();

					nativeCanvas.PushTransform(drawingTransform);
					foreach (var stroke in drawingInfo.Strokes)
						nativeCanvas.Draw(stroke.Scale(drawingScale));
					nativeCanvas.PopTransform();

					using (var cgImage = nativeCanvas.AsCGImage())
					{
						cgImage
							.SaveJpeg()
							.Then(Resolve, Reject);
					}
				}
			}
		}
	}

	extern(iOS) internal static class CGImageExtensions
	{
		public static Future<string> SaveJpeg(this CGImage cgImage)
		{
			var sp = new SavePromise();
			SaveJpeg(cgImage, sp.Resolve, sp.OnRejected);
			return sp;
		}

		class SavePromise : Promise<string>
		{
			public void OnRejected(string msg) { Reject(new Exception(msg)); }
		}

		[Foreign(Language.ObjC)]
		static void SaveJpeg(
			CGImage cgImage,
			Action<string> onResolve,
			Action<string> onReject)
		@{
			UIImage* uiImage = [UIImage imageWithCGImage:cgImage];
			NSData* data = UIImageJPEGRepresentation(uiImage, 1.0f);;
			NSString* ext = @"jpg";
			NSString* uuid = [[NSUUID UUID] UUIDString];
			NSString* dir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
			NSString* path = [NSString stringWithFormat:@"%@/IMG_%@.%@", dir, uuid, ext];

			NSError* error = nil;
			if (![data writeToFile:path options:NSDataWritingWithoutOverwriting error:&error]) {
				onReject([NSString stringWithFormat:@"%@", error]);
			} else {
				onResolve(path);
			}
		@}
	}

	internal static class ImageOrientationHelpers
	{
		public static bool FlipSize(ImageOrientation orientation)
		{
			return orientation.HasFlag(ImageOrientation.Rotate90);
		}

		public static float3x3 TransformFromImageOrientation(ImageOrientation orientation)
		{
			var transform = float3x3.Identity;

			if (orientation.HasFlag(ImageOrientation.FlipVertical))
			{
				transform.M22 = -1;
				transform.M32 =  1;
			}

			if (orientation.HasFlag(ImageOrientation.Rotate180))
			{
				transform.M11 = -1;
				transform.M22 = -transform.M22;
				transform.M31 =  1;
				transform.M32 =  1 - transform.M32;
			}

			if (orientation.HasFlag(ImageOrientation.Rotate90))
			{
				transform.M12 = -transform.M11;
				transform.M11 = 0;

				transform.M21 = transform.M22;
				transform.M22 = 0;

				var tmp = transform.M31;
				transform.M31 = transform.M32;
				transform.M32 = 1 - tmp;
			}

			return transform;
		}
	}
}