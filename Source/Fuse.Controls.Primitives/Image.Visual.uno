using Uno;
using Uno.Graphics;

using Fuse.Drawing;
using Fuse.Internal;
using Fuse.Elements;
using Fuse.Nodes;

namespace Fuse.Controls
{
	public partial class Image
	{
		float2 GetSize()
		{
			if (Source != null)
				return Container.Sizing.CalcContentSize( Source.Size, Source.PixelSize );
			return float2(0);
		}

		protected override float2 GetContentSize( LayoutParams lp )
		{
			var b = base.GetContentSize(lp);
			Container.Sizing.snapToPixels = SnapToPixels;
			Container.Sizing.absoluteZoom = AbsoluteZoom;
			var r = Container.Sizing.ExpandFillSize( GetSize(), lp );
			b = Math.Max(r,b);
			return b;
		}

		internal float2 _origin, _scale;
		internal float2 _drawOrigin, _drawSize;
		float4 _uvClip;
		protected override void ArrangePaddingBox( LayoutParams lp)
		{
			base.ArrangePaddingBox(lp);
				
			var size = lp.Size;
			
			Container.Sizing.snapToPixels = SnapToPixels;
			Container.Sizing.absoluteZoom = AbsoluteZoom;

			var contentDesiredSize = GetSize();
			_scale = Container.Sizing.CalcScale( size, contentDesiredSize );
			_origin = Container.Sizing.CalcOrigin( size, contentDesiredSize * _scale );

			_drawOrigin = _origin;
			_drawSize = contentDesiredSize * _scale;
			_uvClip = Container.Sizing.CalcClip( size, ref _drawOrigin, ref _drawSize );
			InvalidateRenderBounds();
			
			SetContentBox(float4(_drawOrigin,_drawOrigin+_drawSize));
			UpdateNativeImageTransform();
		}

		void UpdateNativeImageTransform()
		{
			var imageView = ImageView;
			if (imageView != null)
			{
				imageView.UpdateImageTransform(Viewport.PixelsPerPoint, _origin, _scale, _drawSize);
			}
		}

		protected override bool FastTrackDrawWithOpacity(DrawContext dc)
		{
			if (!base.FastTrackDrawWithOpacity(dc))
				return false;
			
			DrawVisualColor(dc, float4(Color.XYZ, Color.W * Opacity));
			return true;
		}
		
		protected override void DrawVisual(DrawContext dc)
		{
			DrawVisualColor(dc, Color);
		}
		
		void DrawVisualColor(DrawContext dc, float4 color)
		{
			var tex = Container.GetTexture();
			if (tex == null)
				return;

			if (Container.StretchMode == StretchMode.Scale9)
			{
				Fuse.Elements.Internal.Scale9Rectangle.Impl.Draw(dc, this, ActualSize, GetSize(), tex, color, 
					Scale9Margin);
			}
			else
			{
				ImageElementDraw.Impl.
					Draw(dc, this, _drawOrigin, _drawSize,
					     _uvClip.XY, _uvClip.ZW - _uvClip.XY,
					      tex, Container.ResampleMode,
					      color);
			}
		}

		protected override void OnHitTestLocalVisual(HitTestContext htc)
		{
			//must be in the actual image part shown
			var lp = htc.LocalPoint;
			if (lp.X >= _drawOrigin.X && lp.X <= (_drawOrigin.X + _drawSize.X) &&
				lp.Y >= _drawOrigin.Y && lp.Y <= (_drawOrigin.Y + _drawSize.Y) )
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
			var b = base.CalcRenderBounds();
			b = b.AddRect(_drawOrigin, _drawOrigin + _drawSize);
			return b;
		}
	}

	class ImageElementDraw
	{
		static public ImageElementDraw Impl = new ImageElementDraw();
		SamplerState GetSamplerState(ResampleMode resampleMode)
		{
			switch (resampleMode)
			{
				case ResampleMode.Nearest: return SamplerState.NearestClamp;
				case ResampleMode.Linear: return SamplerState.LinearClamp;
				case ResampleMode.Mipmap: return SamplerState.TrilinearClamp;
				default:
					throw new ArgumentException("Invalid enum value", "resampleMode");
			}
		}

		public void Draw(DrawContext dc, Visual element, float2 offset,
		                 float2 size, float2 uvPosition, float2 uvSize,
	                     Texture2D tex, ResampleMode resampleMode,
		                 float4 Color )
		{
			draw
			{
				apply Fuse.Drawing.Planar.Image;
				DrawContext: dc;
				Visual: element;
				Size: size;
				Position: offset;
				Texture: tex;
				SamplerState SamplerState: GetSamplerState(resampleMode);
				TexCoord: VertexData * uvSize + uvPosition;
				TextureColor: prev * Color;
			};

			if (defined(FUSELIBS_DEBUG_DRAW_RECTS) && dc.RenderTarget == DrawRectVisualizer.RenderTarget)
				DrawRectVisualizer.Capture(offset, size, element.WorldTransform, dc);
		}
	}
}
