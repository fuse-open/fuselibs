using Uno;
using Uno.Collections;
using Uno.IO;
using Uno.Threading;
using Uno.UX;

using Fuse.Internal;
using Fuse.Resources;
using Fuse.Text;
using Fuse.Triggers;

namespace Fuse.Controls.FuseTextRenderer
{
	sealed class TextRenderer : ITextRenderer
	{
		// --------------------------------------------------------------------------
		// Font caching
		static Cache<List<FontFaceDescriptor>, Fuse.Text.FontFace> _fallbackFontCache
			= new Cache<List<FontFaceDescriptor>, Fuse.Text.FontFace>(GetFallbackFontFace);
		static Cache<FontFaceDescriptor, Fuse.Text.FontFace> _fontCache
			= new Cache<FontFaceDescriptor, Fuse.Text.FontFace>(GetFontFace);

		static Fuse.Text.FontFace GetFallbackFontFace(List<FontFaceDescriptor> descriptors)
		{
			var len = descriptors.Count;
			var fontFaces = new CacheItem<FontFaceDescriptor, Fuse.Text.FontFace>[len];
			for (int i = 0; i < len; ++i)
			{
				fontFaces[i] = _fontCache.Get(descriptors[i]);
			}
			return new FallingBackFontFace(fontFaces);
		}

		static Fuse.Text.FontFace GetFontFace(FontFaceDescriptor descriptor)
		{
			return new LazyFontFace(descriptor);
		}
		// --------------------------------------------------------------------------

		Fuse.Controls.TextControl _control;

		Fuse.Font _fuseFont;

		CacheItem<List<FontFaceDescriptor>, Fuse.Text.FontFace> _fontFace;
		CacheItem<List<FontFaceDescriptor>, Fuse.Text.FontFace> FontFace
		{
			get { return _fontFace; }
			set
			{
				if (_fontFace != value)
				{
					if (_fontFace != default(CacheItem<List<FontFaceDescriptor>, Fuse.Text.FontFace>))
						_fontFace.Dispose();
					_fontFace = value;
				}
			}
		}
		CacheItem<int, Fuse.Text.Font> _font;
		public CacheItem<int, Fuse.Text.Font> Font
		{
			get { return _font; }
			private set
			{
				if (_font != value)
				{
					if (_font != default(CacheItem<int, Fuse.Text.Font>))
						_font.Dispose();
					_font = value;
				}
			}
		}

		int _fontSize;
		float _ascender;

		float2 _arrangePosition;
		float2 _arrangeSize;

		// Null if we're currently loading something asynchronously
		CacheState _cacheState = new NothingCached();

		bool _loadAsync;

		public TextRenderer(TextControl control, bool loadAsync)
		{
			_control = control;
			_loadAsync = loadAsync;
		}

		internal List<List<PositionedRun>> GetPositionedRuns()
		{
			List<List<PositionedRun>> result;
			Renderer renderer;
			_cacheState = _cacheState.GetRenderer(CreateTextControlData(), out renderer, out result);
			return result;
		}

		TextControlData CreateTextControlData()
		{
			return CreateTextControlData(_arrangeSize.X);
		}

		TextControlData CreateTextControlData(float pointWidth)
		{
			return new TextControlData(Font.Value, _control, pointWidth * _control.Viewport.PixelsPerPoint);
		}

		BusyTask _busyTask;
		public float2 GetContentSize(LayoutParams lp)
		{
			if (_cacheState == null)
				return float2(0);

			UpdateFont();

			var pointWidth = Math.Min(
				lp.HasX ? lp.X : float.PositiveInfinity,
				lp.HasMaxX ? lp.MaxX : float.PositiveInfinity);

			var data = CreateTextControlData(pointWidth);

			if (_loadAsync)
			{
				float2 measurements;
				if (_cacheState.TryGetMeasurements(data, out measurements))
				{
					return measurements / _control.Viewport.PixelsPerPoint;
				}
				else
				{
					GraphicsWorker.Dispatch(new AsyncMeasurer(_cacheState, data, AsyncMeasurementsDone).Run);
					_cacheState = null;
					BusyTask.SetBusy(_control, ref _busyTask, BusyTaskActivity.Loading);
					return float2(0);
				}
			}
			else
			{
				float2 measurements;
				_cacheState = _cacheState.GetMeasurements(data, out measurements);
				return measurements / _control.Viewport.PixelsPerPoint;
			}
		}

		void AsyncMeasurementsDone(CacheState state)
		{
			BusyTask.SetBusy(_control, ref _busyTask, BusyTaskActivity.None);
			assert _cacheState == null;
			_cacheState = state;
			_control.InvalidateLayout();
			_control.InvalidateVisual();
		}

		public void Draw(DrawContext dc, Fuse.Visual where)
		{
			if (_cacheState == null)
				return;

			UpdateFont();

			Renderer renderer;
			_cacheState = _cacheState.GetRenderer(CreateTextControlData(), out renderer);

			var ascender = _ascender / _control.Viewport.PixelsPerPoint;

			var pixelToClipSpaceMatrix = Matrix.Mul(
				Matrix.Scaling(1 / _control.Viewport.PixelsPerPoint),
				Matrix.Translation(float3(_arrangePosition + float2(0, ascender), 0)),
				dc.GetLocalToClipTransform(where));

			renderer.Draw(
				_control.RenderColor,
				pixelToClipSpaceMatrix);
		}

		public void Arrange(float2 position, float2 size)
		{
			_arrangePosition = position;
			_arrangeSize = size;
		}

		public void Invalidate()
		{
			if (_cacheState != null)
				UpdateFont();
		}

		void UpdateFont()
		{
			int newFontSize = Math.Clamp(
				(int)Math.Floor( _control.FontSizeScaled * _control.Viewport.PixelsPerPoint + 0.5f),
				4,
				400);
			if (_control.Font != _fuseFont || newFontSize != _fontSize)
			{
				_fuseFont = _control.Font;
				_fontSize = newFontSize;
				FontFace = _fallbackFontCache.Get(_fuseFont.Descriptors);
				Font = FontFace.Value.GetOfPixelSize(newFontSize);
				_ascender = Font.Value.Ascender;
				_cacheState.Dispose();
				_cacheState = new NothingCached();
			}
		}

		public Rect GetRenderBounds()
		{
			if (_cacheState == null)
				return new Rect();

			UpdateFont();
			Rect bounds;
			_cacheState = _cacheState.GetBounds(CreateTextControlData(), out bounds);

			return Rect.Scale(
				Rect.Inflate(bounds, 2 * Font.Value.LineHeight),
				1 / _control.Viewport.PixelsPerPoint);
		}

		public void SoftDispose()
		{
			_fuseFont = null;
			_fontSize = 0;
			Font = default(CacheItem<int, Fuse.Text.Font>);
			FontFace = default(CacheItem<List<FontFaceDescriptor>, Fuse.Text.FontFace>);
			if (_cacheState != null)
			{
				_cacheState.Dispose();
				_cacheState = new NothingCached();
			}
		}
	}
}
