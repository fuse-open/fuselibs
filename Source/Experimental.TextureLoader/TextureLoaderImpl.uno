using Uno;
using Uno.Compiler.ExportTargetInterop;

namespace Experimental.TextureLoader
{
	[TargetSpecificImplementation]
	static class TextureLoaderImpl
	{
		[TargetSpecificImplementation]
		public static void JpegByteArrayToTexture2D(Buffer arr, Callback callback)
		{
			if defined(CIL)
			{
				CilTextureLoader.LoadTexture(arr, callback.Action, "fake.jpeg");
			}
		}

		[TargetSpecificImplementation]
		public static void PngByteArrayToTexture2D(Buffer arr, Callback callback)
		{
			if defined(CIL)
			{
				CilTextureLoader.LoadTexture(arr, callback.Action, "fake.png");
			}
		}
	}
}
