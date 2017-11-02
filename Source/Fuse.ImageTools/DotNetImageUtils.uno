using Uno.Threading;
using Uno;
using Uno.IO;
using Uno.Compiler.ExportTargetInterop;
using System;

namespace Fuse.ImageTools
{
	using DotNetNative;

	extern (DOTNET) internal class DotNetImageUtils
	{
		public static void GetImageFromBase64(string b64, Action<string> onSuccess, Action<string> onFail)
		{
			var asBytes = Convert.FromBase64String(b64);
			var stream = new MemoryStream(asBytes);
			DotNetImage outImage = DotNetImage.FromStream(stream);
			
			var path = TemporaryPath("jpg");
			outImage.Save(path);
			onSuccess(path);
		}

		public static void GetBase64FromImage(string path, Action<string> onSuccess, Action<string> onFail)
		{
			var image = DotNetImage.FromFile(path);

			using (MemoryStream ms = new MemoryStream())
			{
				image.Save(ms, ImageFormat.Jpeg);
				byte[] imageBytes = ms.GetBuffer();
				onSuccess(Convert.ToBase64String(imageBytes));
			}
		}
		
		static string TemporaryPath(string extension)
		{
			var dir = DotNetNative.Path.GetTempPath ();
			var path = DotNetNative.Path.ChangeExtension(dir + DotNetNative.Path.GetRandomFileName(), extension);
			return path;
		}
	}

	namespace DotNetNative
	{
		[Require("Assembly", "System.Drawing")]
		[DotNetType("System.Drawing.Image")]
		extern(DOTNET) internal class DotNetImage
		{
			public extern static DotNetImage FromFile(string path);
			public extern static DotNetImage FromStream(Stream stream);
			public extern void Save(string filename);
			public extern void Save(Stream stream, ImageFormat format);
		}

		[DotNetType("System.Convert")]
		extern(DOTNET) internal class Convert
		{
			public extern static byte[] FromBase64String(string s);
			public extern static string ToBase64String(byte[] inArray);
		}

		[DotNetType("System.Drawing.Imaging.ImageFormat")]
		extern(DOTNET) internal class ImageFormat
		{
			public extern static ImageFormat Jpeg { get; }
		}

		[DotNetType("System.IO.Path")]
		extern(DOTNET) internal class Path
		{
			public extern static string GetTempPath();
			public extern static string GetRandomFileName();
			public extern static string ChangeExtension(string path, string extension);
		}
	}
}
