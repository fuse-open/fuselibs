using Uno;
using Uno.UX;
using Fuse.Platform;

namespace Fuse.Controls
{
	internal interface ITextRenderer
	{
		float2 GetContentSize(LayoutParams lp);
		void Draw(DrawContext dc, Fuse.Visual where);
		void Arrange(float2 position, float2 size);
		void Invalidate();
		Rect GetRenderBounds();
		void SoftDispose();
	}

	public partial class TextControl
	{

		extern(iOS || Android)
		internal static Func<TextControl, ITextRenderer> TextRendererFactory { get; set; }

		internal virtual string RenderValue
		{
			get { return Value ?? ""; }
		}

		internal virtual float4 RenderColor
		{
			get { return Color; }
		}

		internal ITextRenderer _textRenderer;

		protected override void OnRooted()
		{
			base.OnRooted();

			if defined(!IGNORE_FONT_SCALING)
				SystemUI.TextScaleFactorChanged += TextScaleFactorChanged;

			if (VisualContext == VisualContext.Graphics)
			{
				if defined(USE_HARFBUZZ)
				{
					_textRenderer = new FuseTextRenderer.TextRenderer(this, InternalLoadAsync);
				}
				else
				{
					if defined(Android || iOS)
					{
						if (TextRendererFactory != null)
							_textRenderer = TextRendererFactory(this);
						else
							_textRenderer = new FallbackTextRenderer.TextRenderer(this);
					}
					else
						_textRenderer = new FallbackTextRenderer.TextRenderer(this);
					AddDrawCost(2.0);
				}
			}
		}

		protected override void OnUnrooted()
		{
			if (VisualContext == VisualContext.Graphics)
			{
				if defined(!USE_HARFBUZZ)
					RemoveDrawCost(2.0);

				if (_textRenderer != null)
					_textRenderer.SoftDispose();
				_textRenderer = null;
			}

			if defined(!IGNORE_FONT_SCALING)
				SystemUI.TextScaleFactorChanged -= TextScaleFactorChanged;

			base.OnUnrooted();
		}

		protected virtual void InvalidateRenderer()
		{
			InvalidateTextRenderer();
		}

		void InvalidateTextRenderer()
		{
			if (_textRenderer != null)
			{
				_textRenderer.Invalidate();
			}
			InvalidateRenderBounds();
		}

		protected override float2 GetContentSize( LayoutParams lp )
		{
			var b = base.GetContentSize(lp);
			if (_textRenderer != null)
			{
				var t = _textRenderer.GetContentSize(lp);
				b = Math.Max(t,b);
			}
			return b;
		}

		protected override void ArrangePaddingBox( LayoutParams lp )
		{
			base.ArrangePaddingBox(lp);

			if (_textRenderer != null)
			{
				//Refer https://github.com/fusetools/fuselibs-private/issues/1766
				//local visuals do not include padding
				_textRenderer.Arrange(float2(0), lp.Size);
			}
		}

		protected override bool FastTrackDrawWithOpacity(DrawContext dc)
		{
			return false;
		}

		protected override void DrawVisual(DrawContext dc)
		{
			var str = RenderValue;

			if (_textRenderer != null && !string.IsNullOrEmpty(str))
			{
				_textRenderer.Draw(dc, this);
			}
		}

		protected override void OnHitTestLocalVisual(HitTestContext htc)
		{
			if (IsPointInside(htc.LocalPoint))
				htc.Hit(this);
			base.OnHitTestLocalVisual(htc);
		}

		protected override VisualBounds HitTestLocalVisualBounds
		{
			get
			{
				var b = base.HitTestLocalVisualBounds;
				b = b.AddRect( float2(0), ActualSize );
				return b;
			}
		}

		protected override VisualBounds CalcRenderBounds()
		{
			var b = base.CalcRenderBounds(); //for backgrounds
			if (_textRenderer != null)
				b = b.AddRect(_textRenderer.GetRenderBounds());
			return b;
		}

		protected override void SoftDispose()
		{
			base.SoftDispose();
			if (_textRenderer != null)
				_textRenderer.SoftDispose();
		}

		private void TextScaleFactorChanged(float textScaleFactor)
		{
			OnFontSizeChanged();
			InvalidateVisual();
		}
	}
}
