using Uno;
using Uno.Graphics;
using OpenGL;
using Fuse.Elements;
using Fuse.Common;
using Fuse.Controls;
using Fuse.Controls.Graphics;
using Fuse.Resources;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Android
{
	using Fuse.Controls;
	using Fuse.Controls.Native.Android;

	extern (Android) class TextControlLayout
	{
		public StaticLayout Layout { get; private set; }
		public Uno.Recti PixelBounds { get; private set; }

		public void Dispose()
		{
			Layout = null;
		}

		float _cacheWrapWidthPoints;
		bool _cacheMin;
		bool _cacheValid;

		public void Invalidate()
		{
			_cacheValid = false;
		}

		public bool Measure(Fuse.Controls.TextControl Control, TextPaint Paint, float wrapWidthPoints, bool useMin)
		{
			if (Layout != null &&
				_cacheValid &&
				_cacheWrapWidthPoints == wrapWidthPoints &&
				_cacheMin == useMin)
				return false;


			if (wrapWidthPoints < 0)
				throw new ArgumentOutOfRangeException("wrapWidth");


			var wrapWidthPixels = wrapWidthPoints * Control.Viewport.PixelsPerPoint;
			var align = TextAlignmentToAndroidLayoutAlignment(Control.TextAlignment);
			var text = Control.RenderValue ?? "";
			var lineSpacing = Control.LineSpacing * Control.Viewport.PixelsPerPoint;

			float desiredWidth = StaticLayout.GetDesiredWidth(text, Paint);
			if (useMin)
				wrapWidthPixels = Math.Min(wrapWidthPixels, desiredWidth);

			var width = (int)Math.Min(Math.Ceil(wrapWidthPixels), int.MaxValue);
			if (Control.TextWrapping == TextWrapping.NoWrap)
			{
				var layoutWidth = (int)Math.Ceil(Math.Max(wrapWidthPixels, desiredWidth));
				Layout = (Control.TextTruncation == Fuse.Controls.TextTruncation.Standard)
					? new StaticLayout(text, 0, text.Length, Paint, layoutWidth, align, 1.0f, lineSpacing, false, TextUtils.TruncateAt.End, width)
					: new StaticLayout(text, Paint, layoutWidth, align, 1.0f, lineSpacing, false);
			}
			else
			{
				Layout = new StaticLayout(text, Paint, width, align, 1.0f, lineSpacing, false);
			}

			var bounds = new Uno.Rect(0, 0, 0, 0);
			for (int i = 0; i < Layout.LineCount; ++i)
			{
				var rLineBounds = Paint.GetTextBounds(text, Layout.GetLineStart(i), Layout.GetLineEnd(i));
				var lineBounds = Uno.Rect.Translate(rLineBounds, float2(Layout.GetLineLeft(i), Layout.GetLineBaseline(i)));

				bounds = (i == 0)
					? lineBounds
					: Uno.Rect.Union(bounds, lineBounds);
			}


			var min = (int2)Math.Floor(bounds.Minimum);
			var max = (int2)Math.Ceil(bounds.Maximum);
			var pixelBounds = new Recti(min.X, min.Y, max.X, max.Y);
			pixelBounds.Right = pixelBounds.Left + Math.Min(pixelBounds.Size.X, Layout.EllipsizedWidth);
			PixelBounds = Recti.Inflate(pixelBounds, 1);

			_cacheValid = true;
			_cacheWrapWidthPoints = wrapWidthPoints;
			_cacheMin = useMin;
			return true;
		}

		StaticLayout.Alignment TextAlignmentToAndroidLayoutAlignment(TextAlignment textAlignment)
		{
			switch (textAlignment)
			{
			case TextAlignment.Left: return StaticLayout.Alignment.Normal;
			case TextAlignment.Center: return StaticLayout.Alignment.Center;
			case TextAlignment.Right: return StaticLayout.Alignment.Opposite;
			}

			return StaticLayout.Alignment.Normal; // SHUT UP, COMPILER!
		}

		public void UpdatePaint(Fuse.Controls.TextControl Control, TextPaint paint)
		{
			paint.AntiAlias = true;
			// TODO: fix to use Font.PlatformDefault - and platformdefault should return Helvetic for iOS and roboto for Android
			paint.Typeface = (Control.Font != Fuse.Font.PlatformDefault)
				? TypefaceCache.GetTypeface(Control.Font)
				: Typeface.Default;
			paint.TextSize = Control.FontSizeScaled * Control.Viewport.PixelsPerPoint;
			paint.Color = Control.TextColor;
		}
	}

	extern (Android) class TextRenderer: ITextRenderer
	{
		public static ITextRenderer Create( Fuse.Controls.TextControl control )
		{
			return new TextRenderer(control);
		}

		Fuse.Controls.TextControl _control;
		TextRenderer( Fuse.Controls.TextControl Control )
		{
			_control = Control;
		}

		TextPaint _paint;
		void UpdatePaint()
		{
			if (_paint == null)
				_paint = new TextPaint();
			_textLayout.UpdatePaint(_control, _paint);
		}

		TextControlLayout _textLayout = new TextControlLayout();
		TextControlLayout _measureLayout;
		bool _renderThreaded;

		float2 _arrangePosition;
		float2 _arrangeSize;
		public void Arrange(float2 position, float2 size)
		{
			_arrangePosition = position;
			_arrangeSize = size;
			UpdateLayout();
		}

		void UpdateLayout()
		{
			UpdatePaint();

			if(_textLayout.Measure(_control, _paint, _arrangeSize.X, false))
				_emitNewTexture = true;

			var textLength = (_control.RenderValue != null) ? _control.RenderValue.Length : 0;

			_renderThreaded = textLength > 50;
		}

		public void Invalidate()
		{
			_textLayout.Invalidate();
			if (_measureLayout != null)
				_measureLayout.Invalidate();
		}

		public void SoftDispose()
		{
			DisposeTexture();
			_paint = null;
		}

		public float2 GetContentSize(LayoutParams lp)
		{
			if (_measureLayout == null)
				_measureLayout = new TextControlLayout();

			if (_paint == null)
				_paint = new TextPaint();

			var wrapWidth = lp.HasX ? lp.X : float.PositiveInfinity;
			if (lp.HasMaxX)
				wrapWidth = Math.Min(wrapWidth, lp.MaxX);

			UpdatePaint();
			_measureLayout.Measure(_control, _paint, wrapWidth, true);
			var q =float2(_measureLayout.Layout.EllipsizedWidth, _measureLayout.Layout.Height) /
				_control.Viewport.PixelsPerPoint;

			return q;
		}

		public Uno.Rect GetRenderBounds()
		{
			UpdateLayout();
			return Uno.Rect.Translate( new Uno.Rect(
				(float2)_textLayout.PixelBounds.Position / _control.Viewport.PixelsPerPoint,
				(float2)_textLayout.PixelBounds.Size / _control.Viewport.PixelsPerPoint),
				_arrangePosition);
		}

		bool _emitNewTexture = true;
		ulong _wantedVersion, _textureVersion;

		texture2D _texture;

		void SetTexture(texture2D newTexture)
		{
			if (_texture != null)
				_texture.Dispose();

			_texture = newTexture;
			_control.InvalidateVisual();
		}

		void DisposeTexture()
		{
			SetTexture(null);
			_textureVersion = 0;
			_wantedVersion = 0;
			_emitNewTexture = true;
		}

		void PrepareDraw()
		{
			UpdateLayout();
			if (!_emitNewTexture)
				return;

			_wantedVersion++;

			if defined(FUSELIBS_PROFILING)
				Profiling.LogEvent("Rendering text '" + _control.RenderValue + "'", 0);

			var pixelBounds = _textLayout.PixelBounds;
			if (pixelBounds.Size.X <= 0 || pixelBounds.Size.Y <= 0)
			{
				SetTexture(null);
				if defined(FUSELIBS_PROFILING)
					Profiling.LogEvent("Bitmap invalid: size = 0", 0);
				return;
			}

			if (_renderThreaded)
			{
				var backgroundRender = new BackgroundRender(this, _wantedVersion, _textLayout.Layout, pixelBounds);
				GraphicsWorker.Dispatch(backgroundRender.UpdateTextureAsync);
			}
			else
			{
				SetTexture(UpdateTexture(_textLayout.Layout, pixelBounds));
				_textureVersion = _wantedVersion;
			}

			_emitNewTexture = false;
		}

		texture2D UpdateTexture(StaticLayout layout, Recti pixelBounds)
		{
			var bitmap = Bitmap.CreateBitmapARGB8888(pixelBounds.Size.X, pixelBounds.Size.Y);
			var canvas = new Canvas(bitmap);

			canvas.Translate(-pixelBounds.Position.X, -pixelBounds.Position.Y);
			bitmap.EraseColor(float4(0.0f));

			layout.Draw(canvas);

			var texture = new Texture2D(pixelBounds.Size, Format.RGBA8888, false);

			GL.BindTexture(GLTextureTarget.Texture2D, texture.GLTextureHandle);
			GLUtils.TexImage2D(GLTextureTarget.Texture2D, 0, bitmap, 0);
			GL.BindTexture(GLTextureTarget.Texture2D, GLTextureHandle.Zero);

			bitmap.Recycle();
			return texture;
		}

		class BackgroundRender
		{
			TextRenderer _textRenderer;
			ulong _textureVersion;
			StaticLayout _layout;
			Recti _pixelBounds;
			texture2D _result;

			public BackgroundRender(TextRenderer textRenderer, ulong textureVersion, StaticLayout layout, Recti pixelBounds)
			{
				_textRenderer = textRenderer;
				_textureVersion = textureVersion;
				_layout = layout;
				_pixelBounds = pixelBounds;
			}

			public void UpdateTextureAsync()
			{
				_result = _textRenderer.UpdateTexture(_layout, _pixelBounds);

				if defined(OpenGL)
					OpenGL.GL.Finish();

				UpdateManager.PostAction(DoneCallback);
			}

			void DoneCallback()
			{
				if (_textureVersion == _textRenderer._wantedVersion)
				{
					_textRenderer.SetTexture(_result);
					_textRenderer._textureVersion = _textureVersion;
				}
				else
					_result.Dispose();
			}
		}

		void OnBitmapDraw(DrawContext dc, Visual where, float2 dposition, float2 size)
		{
			if (_textureVersion != _wantedVersion || _texture == null)
				return;

			var pixelSize = _textLayout.PixelBounds.Size;
			var pointSize = (float2)pixelSize / _control.Viewport.PixelsPerPoint;

			var position = (float2)_textLayout.PixelBounds.Position / _control.Viewport.PixelsPerPoint
				+ dposition;
			//align oversize correctly in container
			//TODO: https://github.com/fusetools/fuselibs-private/issues/780
			//there is simply no point unless that issue is fixed
			/*if (pointSize.X > size.X)
			{
				if (_control.TextAlignment == TextAlignment.Right)
					position -= (pointSize.X - size.X);
				else if (_control.TextAlignment == TextAlignment.Center)
					position -= (pointSize.Y - size.Y)/2;
			}*/

			var m = dc.GetLocalToClipTransform(where);
			Blitter.Singleton.Blit(_texture, new Rect(position, pointSize), m);
		}

		public void Draw(DrawContext dc, Visual where)
		{
			PrepareDraw();
			OnBitmapDraw(dc,where,_arrangePosition,_arrangeSize);
		}
	}
}
