using Uno.Threading;
using Uno;
using Uno.IO;
using Uno.Compiler.ExportTargetInterop;
using System;

namespace DotNetNative
{
	[Require("Assembly", "System.Drawing.dll")]
	[DotNetType("System.Drawing.Image")]
	extern(DOTNET) internal class DotNetImage
	{
		public extern static DotNetImage FromFile(string path);
		public extern static DotNetImage FromStream(Stream stream);
		public extern void Save(string filename);
		public extern void Save(string filename, ImageFormat format);
		public extern void Save(Stream stream, ImageFormat format);
		public extern int Width { get; }
		public extern int Height { get; }
		public extern int PixelFormat { get; }
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
		public extern static ImageFormat Png { get; }
	}

	[DotNetType("System.IO.Path")]
	extern(DOTNET) internal class Path
	{
		public extern static string GetTempPath();
		public extern static string GetRandomFileName();
		public extern static string ChangeExtension(string path, string extension);
	}

	[DotNetType("System.Drawing.Bitmap")]
	extern(DOTNET) internal class Bitmap : DotNetImage
	{
		public extern Bitmap(int destWidth, int destHeight);
		public extern Bitmap(DotNetImage img);
		public extern Bitmap Clone(Rectangle rect, PixelFormat format);
	}

	[DotNetType("System.Drawing.Graphics")]
	extern(DOTNET) internal class Graphics : IDisposable
	{
		public extern static Graphics FromImage(DotNetImage image);
		public extern InterpolationMode InterpolationMode { get; set; }
		public extern void DrawImage(DotNetImage image, Rectangle destRect);
		public extern void DrawImage(DotNetImage image, Rectangle destRect, Rectangle srcRect, GraphicsUnit srcUnit);
		public extern void DrawImage(DotNetImage image, int x, int y, Rectangle srcRect, GraphicsUnit srcUnit);
		public extern void Dispose();
	}

	[DotNetType("System.Drawing.Drawing2D.InterpolationMode")]
	extern(DOTNET) internal enum InterpolationMode
	{
		Bicubic, Bilinear, Default, High, HighQualityBicubic, HighQualityBilinear,
		Invalid, Low, NearestNeighbor
	}

	[DotNetType("System.Drawing.GraphicsUnit")]
	extern(DOTNET) internal enum GraphicsUnit
	{
		Display, Document, Inch, Millimeter, Pixel, Point, World
	}

	[DotNetType("System.Drawing.Imaging.PixelFormat")]
	extern(DOTNET) internal enum PixelFormat
	{
			DontCare
	}

	[DotNetType("System.Drawing.Rectangle")]
	extern(DOTNET) internal struct Rectangle
	{
		public extern Rectangle(int x, int y, int width, int height);
		public extern int Width { get; set; }
		public extern int Height { get; set; }
		public extern int X { get; set; }
		public extern int Y { get; set; }
	}
}
