using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Uno.UX;
using Uno;

namespace Fuse.Controls.Native.iOS
{
	[TargetSpecificType]
	extern(IOS) internal struct CGContext : IDisposable
	{
		public void Release()
		{
			extern(this)"CGContextRelease($0)";
		}

		public void Dispose()
		{
			Release();
		}

		public CGImage CreateImage()
		{
			return extern<CGImage>(this)"CGBitmapContextCreateImage($0)";
		}

		public void Draw(CGImage image)
		{
			var width = image.Width;
			var height = image.Height;
			extern(this,image)"CGContextDrawImage($0, CGRectMake(0, 0, width, height), $1)";
		}

		public float4 StrokeColor
		{
			set
			{
				using (var color = CGColor.From(value))
				{
					extern(this,color)"CGContextSetStrokeColorWithColor($0, $1)";
				}
			}
		}

		public float4 FillColor
		{
			set
			{
				using (var color = CGColor.From(value))
				{
					extern(this,color)"CGContextSetFillColorWithColor($0, $1)";
				}
			}
		}

		public void ClearRect(Rect rect)
		{
			var pos = rect.Position;
			var size = rect.Size;
			extern(this,pos.X,pos.Y,size.X,size.Y)"CGContextClearRect($0, { { $1, $2 }, { $3, $4 } })";
		}

		public void FillRect(Rect rect)
		{
			var pos = rect.Position;
			var size = rect.Size;
			extern(this,pos.X,pos.Y,size.X,size.Y)"CGContextFillRect($0, { { $1, $2 }, { $3, $4 } })";
		}

		public void SaveGState()
		{
			extern(this)"CGContextSaveGState($0)";
		}

		public void RestoreGState()
		{
			extern(this)"CGContextRestoreGState($0)";
		}

		public static CGContext Null
		{
			get { return extern<CGContext>"nullptr"; }
		}

		public static CGContext NewBitmapContext(int width, int height)
		@{
			CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
			CGContextRef context = CGBitmapContextCreate(
				NULL,
				width,
				height,
				8,
				4 * width,
				colorSpace,
				kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
			CGColorSpaceRelease(colorSpace);
			CGContextClearRect(context, { { 0.0f, 0.0f, }, { (CGFloat)width, (CGFloat)height } });
			return context;
		@}

		public static bool operator ==(CGContext ctx1, CGContext ctx2)
		{
			return extern<bool>(ctx1,ctx2)"$0 == $1";
		}

		public static bool operator !=(CGContext ctx1, CGContext ctx2)
		{
			return extern<bool>(ctx1,ctx2)"$0 != $1";
		}
	}

	[TargetSpecificType]
	extern(IOS) internal struct CGColor : IDisposable
	{
		public static CGColor From(float4 c)
		{
			return From(c.X, c.Y, c.Z, c.W);
		}

		public void Release()
		{
			extern(this)"CGColorRelease($0)";
		}

		public void Dispose()
		{
			Release();
		}

		public static CGColor Null
		{
			get { return extern<CGColor>"nullptr"; }
		}

		public static bool operator ==(CGColor col1, CGColor col2)
		{
			return extern<bool>(col1,col2)"$0 == $1";
		}

		public static bool operator !=(CGColor col1, CGColor col2)
		{
			return extern<bool>(col1,col2)"$0 != $1";
		}

		static CGColor From(float r, float g, float b, float a)
		@{
			CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
			CGFloat components[] = { r, g, b, a };
			CGColorRef color = CGColorCreate(colorSpace, components);
			CGColorSpaceRelease(colorSpace);
			return color;
		@}
	}

	[TargetSpecificType]
	extern(IOS) internal struct CGImage : IDisposable
	{
		public static CGImage Null
		{
			get { return extern<CGImage>"nullptr"; }
		}

		public int Width
		{
			get { return extern<int>(this)"(int32_t)CGImageGetWidth($0)"; }
		}

		public int Height
		{
			get { return extern<int>(this)"(int32_t)CGImageGetHeight($0)"; }
		}

		public int2 Size
		{
			get { return int2(Width, Height); }
		}

		public void Release()
		{
			extern(this)"CGImageRelease($0)";
		}

		public void Dispose()
		{
			Release();
		}

		public static CGImage FromJpegBytes(byte[] bytes)
		@{
			auto dataProvider = CGDataProviderCreateWithData(
				NULL,
				(const UInt8 *)bytes->Ptr(),
				bytes->Length(),
				NULL);
			auto cgImage = CGImageCreateWithJPEGDataProvider(
				dataProvider,
				NULL,
				true,
				kCGRenderingIntentDefault);
			CGDataProviderRelease(dataProvider);
			return cgImage;
		@}

		public static bool operator ==(CGImage img1, CGImage img2)
		{
			return extern<bool>(img1,img2)"$0 == $1";
		}

		public static bool operator !=(CGImage img1, CGImage img2)
		{
			return extern<bool>(img1,img2)"$0 != $1";
		}
	}
}