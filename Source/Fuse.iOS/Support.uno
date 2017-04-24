using Uno;
using Uno.Platform;
using Uno.Collections;
using Uno.Platform.iOS;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Platform;
using Uno.Graphics;

namespace Fuse.iOS
{
	[Require("Source.Include", "@{Uno.Platform.iOS.Application:Include}")]
	[Require("Source.Include", "Foundation/Foundation.h")]
	[Require("Source.Include", "CoreGraphics/CoreGraphics.h")]
	[Require("Source.Include", "UIKit/UIKit.h")]
	[Set("FileExtension", "mm")]
	public extern(IOS) static class Support
	{
		public static Texture2D CreateTextureFromImage(UIImage image)
		{
			int2 bitmapSize = UIImageGetSize(image);
			byte[] bitmap = UIImageToRGBA8888(image);

			Texture2D texture = new Texture2D(bitmapSize, Format.RGBA8888, false);
			texture.Update(extern<IntPtr>(bitmap) "$0->Ptr()");

			return texture;
		}

		static int2 UIImageGetSize(UIImage image)
		@{
			CGSize imageSize = image.size;

			int width = (int) imageSize.width;
			int height = (int) imageSize.height;

			return @{Uno.Int2(int,int):New(width, height)};
		@}

		static byte[] UIImageToRGBA8888(UIImage _image)
		@{
			CGImageRef image = [((UIImage*)_image) CGImage];
			if (image == NULL)
				return NULL;

			UIImageOrientation orientation = _image.imageOrientation;

			CGRect imageRect = CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image));

			int bitmapWidth = imageRect.size.width;
			int bitmapHeight = imageRect.size.height;

			if (int(orientation) & 0x2)
			{
				// Transpose for Left* and Right* orientations
				bitmapWidth = imageRect.size.height;
				bitmapHeight = imageRect.size.width;
			}

			uArray *bitmap = @{byte[]:New(bitmapWidth * bitmapHeight * 4)};

			CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
			CGContextRef context = CGBitmapContextCreate(bitmap->Ptr(),
				bitmapWidth, bitmapHeight, 8, 4 * bitmapWidth, colorSpace,
				kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);

			switch (orientation)
			{
				// Right side up
				case UIImageOrientationUp:
					break;
				case UIImageOrientationUpMirrored:
					CGContextTranslateCTM(context, imageRect.size.width, 0);
					CGContextScaleCTM(context, -1., 1.);
					break;

				// Upside down
				case UIImageOrientationDown:
					CGContextRotateCTM(context, M_PI);
					CGContextTranslateCTM(
						context, -imageRect.size.width, -imageRect.size.height);
					break;
				case UIImageOrientationDownMirrored:
					CGContextRotateCTM(context, M_PI);
					CGContextTranslateCTM(context, 0, -imageRect.size.height);
					CGContextScaleCTM(context, -1., 1.);
					break;

				// Left
				case UIImageOrientationLeft:
					CGContextRotateCTM(context, M_PI_2);
					CGContextTranslateCTM(context, 0, -imageRect.size.height);
					break;
				case UIImageOrientationLeftMirrored:
					CGContextRotateCTM(context, M_PI_2);
					CGContextTranslateCTM(
						context, imageRect.size.width, -imageRect.size.height);
					CGContextScaleCTM(context, -1., 1.);
					break;

				// Right
				case UIImageOrientationRight:
					CGContextRotateCTM(context, -M_PI_2);
					CGContextTranslateCTM(context, -imageRect.size.width, 0);
					break;
				case UIImageOrientationRightMirrored:
					CGContextRotateCTM(context, -M_PI_2);
					CGContextScaleCTM(context, -1., 1.);
					break;
			}

			CGContextDrawImage(context, imageRect, image);

			CGContextRelease(context);
			CGColorSpaceRelease(colorSpace);

			return bitmap;
		@}

		public static extern int2 CGPointToUnoInt2(uCGPoint point, float scale)
		@{
			@{Uno.Int2} unoPoint;
			unoPoint.X = $0.x * $1;
			unoPoint.Y = $0.y * $1;
			return unoPoint;
		@}

		public static extern uCGPoint CGPointFromUnoInt2(int2 unoPoint, float scale)
		@{
			CGPoint point;
			point.x = $0.X / $1;
			point.y = $0.Y / $1;
			return point;
		@}

		public static extern uCGPoint CGPointFromUnoFloat2(float2 unoPoint, float scale)
		@{
			CGPoint point;
			point.x = $0.X / $1;
			point.y = $0.Y / $1;
			return point;
		@}

		public static extern uCGRect CGRectFromUnoRect(Rect unoRect, float scale)
		@{
			CGRect rect;
			rect.origin.x = $0.Left / $1;
			rect.origin.y = $0.Top / $1;
			rect.size.width = ($0.Right - $0.Left) / $1;
			rect.size.height = ($0.Bottom - $0.Top) / $1;
			return rect;
		@}

		public static extern uCGRect CGRectFromUnoRecti(Recti unoRect, float scale)
		@{
			CGRect rect;
			rect.origin.x = $0.Left / $1;
			rect.origin.y = $0.Top / $1;
			rect.size.width = ($0.Right - $0.Left) / $1;
			rect.size.height = ($0.Bottom - $0.Top) / $1;
			return rect;

		@}

		public static extern Recti CGRectToUnoRecti(uCGRect rect, float scale)
		{
			var origin = CGPointToUnoInt2(extern<uCGPoint>(rect)"$0.origin", scale);
			var size = CGSizeToUnoInt2(extern<uCGSize>(rect)"$0.size", scale);
			return new Uno.Recti(origin, size);
		}

		public static extern int2 CGSizeToUnoInt2(uCGSize size, float scale)
		@{
			@{Uno.Int2} unoSize;
			unoSize.X = $0.width * $1;
			unoSize.Y = $0.height * $1;
			return unoSize;
		@}


		public static extern uCGSize CGSizeFromUnoInt2(int2 unoSize, float scale)
		@{
			CGSize size;
			size.width = $0.X / $1;
			size.height = $0.Y / $1;
			return size;
		@}

		public static extern uCGSize CGSizeFromUnoFloat2(float2 unoSize, float scale)
		@{
			CGSize size;
			size.width = $0.X / $1;
			size.height = $0.Y / $1;
			return size;
		@}
	}
}
