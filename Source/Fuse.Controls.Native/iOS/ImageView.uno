using Uno;
using Uno.IO;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;
using Uno.Collections;
using Uno.Graphics;
using OpenGL;
using Fuse.Resources;
using Fuse.Elements;

namespace Fuse.Controls.Native.iOS
{

	extern(iOS) internal class ImageView : LeafView, IImageView
	{

		ImageSource _imageSource;
		public ImageSource ImageSource
		{
			set
			{
				if (ImageSource is MultiDensityImageSource)
					((MultiDensityImageSource)ImageSource).ActiveChanged -= OnMultiDensityImageSourceActiveChanged;

				_imageSource = value;
				if (value == null)
					return;

				if (value is FileImageSource)
					UpdateImage((FileImageSource)value);
				else if (value is HttpImageSource)
					UpdateImage((HttpImageSource)value);
				else if (value is MultiDensityImageSource)
				{
					((MultiDensityImageSource)ImageSource).ActiveChanged += OnMultiDensityImageSourceActiveChanged;
					UpdateImage((MultiDensityImageSource)value);
				}
				else
				{
					throw new Exception(value + " not supported in native context");
				}
			}
			private get
			{
				return _imageSource;
			}
		}

		void OnMultiDensityImageSourceActiveChanged()
		{
			if (ImageSource is MultiDensityImageSource)
			{
				UpdateImage((MultiDensityImageSource)ImageSource);
			}
		}

		float4 _tintColor = float4(1.0f);
		public float4 TintColor
		{
			set
			{
				_tintColor = value;
				UpdateImage();
			}
		}

		void UpdateImage()
		{
			var c = _tintColor;
			var imageHandle = _uiImageHandle != null
				? TintImage(_uiImageHandle, c.X, c.Y, c.Z, c.W)
				: null;
			SetImage(_uiImageView, imageHandle);
		}

		ObjC.Object _uiImageView;
		public ImageView() : base(Create())
		{
			_uiImageView = CreateImageView(Handle);
			SetAnchorPoint(_uiImageView);
		}

		[Foreign(Language.ObjC)]
		static void SetAnchorPoint(ObjC.Object handle)
		@{
			::UIView* view = (::UIView*)handle;
			[[view layer] setAnchorPoint: { 0.0f, 0.0f }];
		@}

		public override void Dispose()
		{
			ImageHandle = null;
			if (ImageSource != null && ImageSource is MultiDensityImageSource)
			{
				((MultiDensityImageSource)ImageSource).ActiveChanged -= OnMultiDensityImageSourceActiveChanged;
			}
			base.Dispose();
		}

		ObjC.Object _uiImageHandle;
		IDisposable _imageHandle;
		ImageHandle ImageHandle
		{
			set
			{
				if (_imageHandle != null)
				{
					ClearImage(_uiImageView);
					_imageHandle.Dispose();
					_imageHandle = null;
				}

				_imageHandle = value;

				if (_imageHandle != null)
				{
					_uiImageHandle = (ObjC.Object)value.Handle;
					UpdateImage();
				}
			}
		}

		void UpdateImage(FileImageSource fileImageSource)
		{
			ImageHandle = ImageLoader.Load(fileImageSource.File);
		}

		void UpdateImage(HttpImageSource http)
		{
			ImageLoader.Load(http).Then(OnImageLoaded, OnImageLoadFailed);
		}

		void OnImageLoaded(ImageHandle handle)
		{
			ImageHandle = handle;
		}

		void UpdateImage(MultiDensityImageSource multi)
		{
			var active = multi.Active;
			if (active != null)
			{
				if (active is FileImageSource)
					UpdateImage((FileImageSource)active);
				else if (active is HttpImageSource)
					UpdateImage((HttpImageSource)active);
				else
					throw new Exception(active + " not supported in native context");
			}
		}

		void OnImageLoadFailed(Exception e)
		{
			ImageHandle = null;
		}

		public void UpdateImageTransform(float density, float2 origin, float2 scale, float2 drawSize)
		{
			// Set UIImageVIew size from drawSize param and avoid the use of Matrix Transformation
			SetBounds(_uiImageView, 0.0f, 0.0f, drawSize.X, drawSize.Y);
		}

		static void SetTransform(ObjC.Object handle, float4x4 t)
		{
			SetTransform(handle,
				t.M11, t.M12, t.M13, t.M14,
				t.M21, t.M22, t.M23, t.M24,
				t.M31, t.M32, t.M33, t.M34,
				t.M41, t.M42, t.M43, t.M44);
		}

		[Foreign(Language.ObjC)]
		static void SetTransform(ObjC.Object handle,
			float m11, float m12, float m13, float m14,
			float m21, float m22, float m23, float m24,
			float m31, float m32, float m33, float m34,
			float m41, float m42, float m43, float m44)
		@{
			CATransform3D transform = {
				m11, m12, m13, m14,
				m21, m22, m23, m24,
				m31, m32, m33, m34,
				m41, m42, m43, m44
			};
			::UIView* view = (::UIView*)handle;
			[[view layer] setTransform:transform];
		@}

		[Foreign(Language.ObjC)]
		static void SetBounds(ObjC.Object handle, float x, float y, float w, float h)
		@{
			::UIView* view = (::UIView*)handle;
			[view setBounds: { { x, y }, { w, h } }];
		@}

		float2 GetImageSize()
		{
			return float2(
				GetImageWidth(_uiImageView),
				GetImageHeight(_uiImageView));
		}

		[Foreign(Language.ObjC)]
		static float GetImageWidth(ObjC.Object handle)
		@{
			UIImageView* imageView = (UIImageView*)handle;
			return (imageView.image)
				? (float)imageView.image.size.width
				: 0.0f;
		@}

		[Foreign(Language.ObjC)]
		static float GetImageHeight(ObjC.Object handle)
		@{
			UIImageView* imageView = (UIImageView*)handle;
			return (imageView.image)
				? (float)imageView.image.size.height
				: 0.0f;
		@}

		[Foreign(Language.ObjC)]
		static void SetImage(ObjC.Object imageViewHandle, ObjC.Object uiImageHandle)
		@{
			UIImageView* imageView = (UIImageView*)imageViewHandle;
			UIImage* image = (UIImage*)uiImageHandle;
			[imageView setImage:image];
		@}

		[Foreign(Language.ObjC)]
		static ObjC.Object TintImage(ObjC.Object handle, float r, float g, float b, float a)
		@{
			UIImage* image = (UIImage*)handle;
			UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
			CGRect imageRect = CGRectMake(0.0f, 0.0f, image.size.width, image.size.height);
			CGContextRef ctx = UIGraphicsGetCurrentContext();
			[[UIColor colorWithRed:r green:g blue:b alpha:a] setFill];
			CGContextTranslateCTM(ctx, 0, image.size.height);
			CGContextScaleCTM(ctx, 1.0, -1.0);
			CGContextSetBlendMode(ctx, kCGBlendModeMultiply);
			CGContextDrawImage(ctx, imageRect, image.CGImage);
			CGContextClipToMask(ctx, imageRect, image.CGImage);
			CGContextAddRect(ctx, imageRect);
			CGContextDrawPath(ctx, kCGPathFill);
			UIImage* result = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();
			return result;
		@}

		[Foreign(Language.ObjC)]
		static void ClearImage(ObjC.Object imageViewHandle)
		@{
			UIImageView* imageView = (UIImageView*)imageViewHandle;
			[imageView setImage:nil];
		@}

		[Foreign(Language.ObjC)]
		static ObjC.Object Create()
		@{
			UIControl* uicontrol = [[UIControl alloc] init];
			[uicontrol setMultipleTouchEnabled:true];
			[uicontrol setAutoresizesSubviews:false];
			[uicontrol setTranslatesAutoresizingMaskIntoConstraints:false];
			[uicontrol setClipsToBounds:true];
			return uicontrol;
		@}

		[Foreign(Language.ObjC)]
		static ObjC.Object CreateImageView(ObjC.Object container)
		@{
			UIImageView* imageView = [[UIImageView alloc] init];
			[container addSubview:imageView];
			return imageView;
		@}

	}
}
