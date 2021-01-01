using Uno.Threading;
using Uno;
using Uno.Compiler.ExportTargetInterop;
using Android;
namespace Fuse.ImageTools
{
	[ForeignInclude(Language.Java, "java.lang.Thread", "java.lang.Runnable", "android.util.Log", "android.provider.MediaStore", "com.fuse.Activity", "com.fuse.camera.Image", "com.fuse.camera.ImageUtils", "android.content.Intent")]
	extern (Android) static internal class AndroidImageUtils
	{

		public static int2 GetSize(Image inImage)
		{
			var size = new int[2] {0, 0};
			GetSizeInternal(inImage.Path, size);
			return int2(size[0], size[1]);
		}

		[Foreign(Language.Java)]
		static void GetSizeInternal(string path, int[] values)
		@{
			try{
				Image inImage = Image.fromPath(path);
				values.set(0, inImage.getWidth());
				values.set(1, inImage.getHeight());
			}catch(Exception e){
			}
		@}

		[Foreign(Language.Java)]
		public static void Resize(string path, int width, int height, int mode, Action<string> onSuccess, Action<string> onFail, bool performInPlace = true)
		@{
			final Image inImage = Image.fromPath(path);
			Thread t = new Thread(new Runnable() { public void run() {
					try{
						Image outImage = ImageUtils.resize(inImage, width, height, ImageUtils.ResizeMode.values()[mode], 100, performInPlace);
						onSuccess.run(outImage.getFilePath());
					}catch(Exception e){
						onFail.run(e.getMessage());
						e.printStackTrace();
					}
			}});
			t.start();
		@}

		[Foreign(Language.Java)]
		public static void GetImageFromBuffer(sbyte[] bytes, Action<string> onSuccess, Action<string> onFail)
		@{
			Thread t = new Thread(new Runnable() { public void run() {
				try{
					byte[] bitmapdata = bytes.copyArray();
					Image outImage = Image.fromBytes(bitmapdata);
					onSuccess.run(outImage.getFilePath());
				}catch(Exception e){
					onFail.run(e.getMessage());
				}
			}});
			t.start();
		@}

		[Foreign(Language.Java)]
		public static string GetImageFromBufferSync(sbyte[] bytes)
		@{
			try{
				byte[] bitmapdata = bytes.copyArray();
				Image outImage = Image.fromBytes(bitmapdata);
				return outImage.getFilePath();
			}catch(Exception e){
				e.printStackTrace();
				return null;
			}
		@}

		[Foreign(Language.Java)]
		public static void Crop(string path, int width, int height, int x, int y, Action<string> onSuccess, Action<string> onFail, bool performInPlace = true)
		@{
			final Image inImage = Image.fromPath(path);
			Thread t = new Thread(new Runnable() { public void run() {
				try{
					Image outImage = ImageUtils.crop(inImage, width, height, x, y, 100, performInPlace);
					onSuccess.run(outImage.getFilePath());
				}catch(Exception e){
					onFail.run(e.getMessage());
					e.printStackTrace();
				}
			}});
			t.start();
		@}

		[Foreign(Language.Java)]
		public static void GetImageFromBase64(string b64, Action<string> onSuccess, Action<string> onFail)
		@{
			Thread t = new Thread(new Runnable() { public void run() {
				try
				{
					Image outImage = Image.fromBase64(b64);
					onSuccess.run(outImage.getFilePath());
				}catch(Exception e)
				{
					onFail.run(e.getMessage());
				}
			}});
			t.start();
		@}

		[Foreign(Language.Java)]
		public static void GetBase64FromImage(string path, Action<string> onSuccess, Action<string> onFail)
		@{
			Thread t = new Thread(new Runnable() { public void run() {
				try
				{
					String encoded = ImageUtils.getBase64FromImage(Image.fromPath(path));
					onSuccess.run(encoded);
				}catch(Exception e)
				{
					onFail.run(e.getMessage());
				}
			}});
			t.start();
		@}
	}
}
