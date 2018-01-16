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
			if (ImageSource != null && ImageSource is MultiDensityImageSource)
			{
				((MultiDensityImageSource)ImageSource).ActiveChanged -= OnMultiDensityImageSourceActiveChanged;
			}
			base.Dispose();
		}

		public void UpdateImageTransform(float density, float2 origin, float2 scale, float2 drawSize)
		{
			var imagePos = (int2)Math.Ceil(origin * density);
			var imageScale = scale * density;
			UpdateImageTransform(
				_imageView,
				imagePos.X,
				imagePos.Y,
				imageScale.X,
				imageScale.Y);
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

		void OnImageLoaded(ImageHandle handle)
		{
			ImageHandle = handle;
		}

		void OnImageLoadFailed(Exception e)
		{
			ImageHandle = null;
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

		[Foreign(Language.Java)]
		static void UpdateImageTransform(Java.Object handle, float x, float y, float scaleX, float scaleY)
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
			android.widget.FrameLayout frameLayout = (android.widget.FrameLayout)container;
			android.widget.ImageView imageView = new android.widget.ImageView(com.fuse.Activity.getRootActivity());
			imageView.setScaleType(android.widget.ImageView.ScaleType.MATRIX);
			imageView.setLayoutParams(new android.widget.FrameLayout.LayoutParams(android.view.ViewGroup.LayoutParams.MATCH_PARENT, android.view.ViewGroup.LayoutParams.MATCH_PARENT));
			frameLayout.addView(imageView);
			return imageView;
		@}

		[Foreign(Language.Java)]
		static Java.Object CreateContainer()
		@{
			android.widget.FrameLayout frameLayout = new android.widget.FrameLayout(com.fuse.Activity.getRootActivity());
			frameLayout.setFocusable(true);
			frameLayout.setFocusableInTouchMode(true);
			frameLayout.setClipToPadding(true);
			frameLayout.setClipChildren(true);
			frameLayout.setLayoutParams(new android.widget.FrameLayout.LayoutParams(android.view.ViewGroup.LayoutParams.MATCH_PARENT, android.view.ViewGroup.LayoutParams.MATCH_PARENT));
			return frameLayout;
		@}

	}
}
