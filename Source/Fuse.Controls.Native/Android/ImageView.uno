using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;
using Uno.Collections;
using Uno.Graphics;
using OpenGL;
using Fuse.Resources;
using Fuse.Elements;

namespace Fuse.Controls.Native.Android
{
	[ForeignInclude(Language.Java,
		"java.lang.Runnable",
		"android.graphics.*",
		"android.app.Activity",
		"java.net.*",
		"java.io.*",
		"java.lang.*")]
	extern(Android) internal class HttpImageLoader : Uno.Threading.Promise<Java.Object>
	{

		public HttpImageLoader(string url) : base(UpdateManager.Dispatcher)
		{
			LoadAsync(url, Success, Error);
		}

		void Success(Java.Object bitmap)
		{
			if (!_isDisposed)
				Resolve(bitmap);
		}

		void Error(string errorMsg)
		{
			if (!_isDisposed)
				Reject(new Exception(errorMsg));
		}

		[Foreign(Language.Java)]
		static void LoadAsync(string urlString, Action<Java.Object> success, Action<string> error)
		@{
			Thread thread = new Thread() {
				public void run() {
					try
					{
						URL url = new URL(urlString);
						HttpURLConnection connection = (HttpURLConnection)url.openConnection();
						connection.setDoInput(true);
						connection.connect();
						InputStream input = connection.getInputStream();
						Bitmap bitmap = BitmapFactory.decodeStream(input);
						success.run(bitmap);
					}
					catch (IOException e)
					{
						error.run(e.getMessage());
					}
				}
			};
			thread.start();
		@}

		bool _isDisposed = false;
		public override void Dispose()
		{
			_isDisposed = true;
			base.Dispose();
		}

	}

	extern(Android) internal class ImageView : View, IImageView
	{

		public ImageSource ImageSource
		{
			set
			{
				if (value == null)
					ImageHandle = null;
				else if (value is FileImageSource)
					UpdateImage((FileImageSource)value);
				else if (value is HttpImageSource)
					UpdateImage((HttpImageSource)value);
				else if (value is MultiDensityImageSource)
					UpdateImage((MultiDensityImageSource)value);
				else
				{
					throw new Exception(value + " not supported in native context");
				}
			}
		}

		float4 _tintColor = float4(1.0f);
		public float4 TintColor
		{
			set
			{
				_tintColor = value;
				SetTint(_imageView, (int)Color.ToArgb(_tintColor));
			}
		}

		Java.Object _imageView;

		public ImageView() : base(CreateContainer())
		{
			_imageView = Create(Handle);
		}

		public override void Dispose()
		{
			ImageHandle = null;
			base.Dispose();
		}

		public void UpdateImageTransform(float density, float2 origin, float2 scale, float2 drawSize)
		{
			SetImageSize(drawSize * density);
			SetImageMatrix(
				_imageView,
				origin.X * density,
				origin.Y * density,
				scale.X * density,
				scale.Y * density);
		}

		IDisposable _imageHandle;
		ImageHandle ImageHandle
		{
			set
			{
				if (_imageHandle != null)
				{
					_imageHandle.Dispose();
					_imageHandle = null;
					ClearBitmap(_imageView);
				}

				_imageHandle = value;

				if (_imageHandle != null)
				{
					SetBitmap(_imageView, (Java.Object)value.Handle);
					SetTint(_imageView, (int)Color.ToArgb(_tintColor));
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

		void OnImageLoadFailed(Exception e)
		{
			ImageHandle = null;
		}

		void UpdateImage(MultiDensityImageSource multi)
		{
			Fuse.Diagnostics.Unsupported("MultiDensityImageSource in a native context not supported", this);
		}

		float2 MeasureImage()
		{
			var wh = new int[2];
			GetImageSize(_imageView, wh);
			return float2((float)wh[0], (float)wh[1]);
		}

		[Foreign(Language.Java)]
		static void GetImageSize(Java.Object handle, int[] wh)
		@{
			android.widget.ImageView imageView = (android.widget.ImageView)handle;
			imageView.measure(
				android.view.View.MeasureSpec.UNSPECIFIED,
				android.view.View.MeasureSpec.UNSPECIFIED);
			wh.set(0, imageView.getMeasuredWidth());
			wh.set(1, imageView.getMeasuredHeight());
		@}

		void SetImageSize(float2 size)
		{
			var wh = new int[]{ (int)size.X, (int)size.Y };
			SetImageSize(_imageView, wh);
		}

		[Foreign(Language.Java)]
		static void SetImageSize(Java.Object handle, int[] wh)
		@{
			android.widget.ImageView imageView = (android.widget.ImageView)handle;
			imageView.setLayoutParams(new android.widget.RelativeLayout.LayoutParams(wh.get(0), wh.get(1)));
		@}

		[Foreign(Language.Java)]
		static void SetImageMatrix(Java.Object handle, float x, float y, float scaleX, float scaleY)
		@{
			android.widget.ImageView imageView = (android.widget.ImageView)handle;
			float[] m = new float[]
			{
				scaleX, 0.0f, 	x,
				0.0f,	scaleY, y,
				0.0f,	0.0f,	1.0f
			};
			android.graphics.Matrix matrix = new android.graphics.Matrix();
			matrix.setValues(m);
			imageView.setImageMatrix(matrix);
		@}

		[Foreign(Language.Java)]
		static void SetBitmap(Java.Object handle, Java.Object bitmapHandle)
		@{
			((android.widget.ImageView)handle).setImageBitmap( (android.graphics.Bitmap)bitmapHandle );
			((android.widget.ImageView)handle).invalidate();
		@}

		[Foreign(Language.Java)]
		static void SetTint(Java.Object handle, int rgba)
		@{
			android.graphics.drawable.Drawable drawable = ((android.widget.ImageView)handle).getDrawable();
			if (drawable != null) {
				drawable.setColorFilter(rgba, android.graphics.PorterDuff.Mode.MULTIPLY);
			}
		@}

		[Foreign(Language.Java)]
		static void ClearBitmap(Java.Object handle)
		@{
			((android.widget.ImageView)handle).setImageResource(0);
			((android.widget.ImageView)handle).invalidate();
		@}

		[Foreign(Language.Java)]
		static Java.Object Create(Java.Object container)
		@{
			android.widget.RelativeLayout relativeLayout = (android.widget.RelativeLayout)container;
			android.widget.ImageView imageView = new android.widget.ImageView(com.fuse.Activity.getRootActivity());
			imageView.setScaleType(android.widget.ImageView.ScaleType.MATRIX);
			imageView.setLayoutParams(new android.widget.RelativeLayout.LayoutParams(android.view.ViewGroup.LayoutParams.MATCH_PARENT, android.view.ViewGroup.LayoutParams.MATCH_PARENT));
			relativeLayout.addView(imageView);
			return imageView;
		@}

		[Foreign(Language.Java)]
		static Java.Object CreateContainer()
		@{
			android.widget.RelativeLayout relativeLayout = new android.widget.RelativeLayout(com.fuse.Activity.getRootActivity());
			relativeLayout.setFocusable(true);
			relativeLayout.setFocusableInTouchMode(true);
			relativeLayout.setClipToPadding(true);
			relativeLayout.setClipChildren(true);
			relativeLayout.setLayoutParams(new android.widget.RelativeLayout.LayoutParams(android.view.ViewGroup.LayoutParams.MATCH_PARENT, android.view.ViewGroup.LayoutParams.MATCH_PARENT));
			return relativeLayout;
		@}

	}
}
