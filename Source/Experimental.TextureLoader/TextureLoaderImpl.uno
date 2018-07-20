using Uno;
using Uno.Compiler.ExportTargetInterop;

namespace Experimental.TextureLoader
{
	[TargetSpecificImplementation]
	static class TextureLoaderImpl
	{
		[TargetSpecificImplementation]
		public static void JpegByteArrayToTexture2D(byte[] arr, Callback callback)
		{
			if defined(DOTNET)
			{
				CilTextureLoader.LoadTexture(arr, callback.Action, "fake.jpeg");
			}
		}

		[TargetSpecificImplementation]
		public static void PngByteArrayToTexture2D(byte[] arr, Callback callback)
		{
			if defined(DOTNET)
			{
				CilTextureLoader.LoadTexture(arr, callback.Action, "fake.png");
			}
		}
	}
}
