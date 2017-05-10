using Uno.Threading;
using Uno;
using Uno.Compiler.ExportTargetInterop;
using Android;
namespace Fuse.ImageTools
{
	[Require("Source.Include", "iOS/ImageHelper.h")]
	extern (iOS) static internal class iOSImageUtils
	{
		public static int2 GetSize(Image p)
		{
			var size = new int[2] {0, 0};
			GetSizeInternal(p.Path, size);
			return int2(size[0], size[1]);
		}

		[Foreign(Language.ObjC)]
		static void GetSizeInternal(string path, int[] values)
		@{
			NSArray* dims = [ImageHelper getImageSize:path];
			values[0] = dims[0];
			values[1] = dims[1];
		@}

		[Foreign(Language.ObjC)]
		public static void Resize(string path, int width, int height, int mode, Action<string> onSuccess, Action<string> onFail, bool inPlace)
		@{
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				[ImageHelper resizeImage:path width:width height:height mode:mode onComplete:onSuccess onFail:onFail performInPlace:inPlace];
			});
		@}

		[Foreign(Language.ObjC)]
		public static void Crop(string path, int x, int y, int width, int height, Action<string> onSuccess, Action<string> onFail, bool inPlace)
		@{
			CGRect rect = CGRectMake((float)x, (float)y, (float)width, (float)height);
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				[ImageHelper cropImage:path desiredRect:rect onComplete:onSuccess onFail:onFail performInPlace:inPlace];
			});
		@}

		[Foreign(Language.ObjC)]
		public static void GetImageFromBase64(string b64, Action<string> onSuccess, Action<string> onFail)
		@{
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				[ImageHelper imageFromBase64String:b64 onComplete:onSuccess onFail:onFail];
			});
		@}

		[Foreign(Language.ObjC)]
		public static void GetBase64FromImage(string path, Action<string> onSuccess, Action<string> onFail)
		@{
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				[ImageHelper base64FromImageAtPath:path onComplete:onSuccess onFail:onFail];
			});
		@}

		[Foreign(Language.ObjC)]
		public static void GetImageFromBuffer(byte[] byteArray, Action<string> onSuccess, Action<string> onFail)
		@{
			uArray* arr = [byteArray unoArray];
			NSData* data = [NSData dataWithBytes:arr->Ptr() length:[byteArray count]];
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				[ImageHelper imageFromData:data onComplete:onSuccess onFail:onFail];
			});
		@}
		
		[Foreign(Language.ObjC)]
		public static string GetImageFromBufferSync(byte[] byteArray)
		@{
			uArray* arr = [byteArray unoArray];
			NSData* data = [NSData dataWithBytes:arr->Ptr() length:[byteArray count]];
			return [ImageHelper imageFromDataSync:data];
		@}
	}
}
