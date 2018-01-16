using Uno;
using Uno.Graphics;

using Fuse.Common;
using Fuse.Drawing;
using Fuse.Internal;
using Fuse.Elements;
using Fuse.Nodes;
using Fuse.Resources;
using Fuse.Resources.Exif;

namespace Fuse.Controls
{
	public partial class Image
	{

		float2 GetSize()
		{
			if (Source == null)
				return float2(0);

			var size = Source.Size;
			var pixelSize = Source.PixelSize;
			if (Source.Orientation.HasFlag(ImageOrientation.Rotate90))
			{
				size = float2(Source.Size.Y, Source.Size.X);
				pixelSize = int2(Source.PixelSize.Y, Source.PixelSize.X);
			}
			return Container.Sizing.CalcContentSize( size, pixelSize );
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

		internal static float3x3 TransformFromImageOrientation(ImageOrientation orientation)
		{
			var transform = float3x3.Identity;

			if (orientation.HasFlag(ImageOrientation.FlipVertical))
			{
				transform.M22 = -1;
				transform.M32 =  1;
			}

			if (orientation.HasFlag(ImageOrientation.Rotate180))
			{
				transform.M11 = -1;
				transform.M22 = -transform.M22;
				transform.M31 =  1;
				transform.M32 =  1 - transform.M32;
			}

			if (orientation.HasFlag(ImageOrientation.Rotate90))
			{
				transform.M12 = -transform.M11;
				transform.M11 = 0;

				transform.M21 = transform.M22;
				transform.M22 = 0;

				var tmp = transform.M31;
				transform.M31 = transform.M32;
				transform.M32 = 1 - tmp;
			}

			return transform;
		}
		
		void DrawVisualColor(DrawContext dc, float4 color)
		{
			var tex = Container.GetTexture();
			if (tex == null)
				return;

			if (Container.StretchMode == StretchMode.Scale9)
			{
				Fuse.Elements.Internal.Scale9Rectangle.Impl.Draw(dc, this, ActualSize, GetSize(), tex, color, Scale9Margin);
			}
			else
			{
				var imageTransform = TransformFromImageOrientation(Source.Orientation);

				ImageElementDraw.Impl.
					Draw(dc, this, _drawOrigin, _drawSize,
						_uvClip.XY, _uvClip.ZW - _uvClip.XY,
						 imageTransform,
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
			float3x3 imageTransform,
			Texture2D tex, ResampleMode resampleMode,
			float4 Color )
		{
			Blitter.Singleton.Blit(tex, GetSamplerState(resampleMode), false,
			                       new Rect(uvPosition, uvSize), imageTransform,
			                       new Rect(offset, size), dc.GetLocalToClipTransform(element),
			                       Color);

			if defined(FUSELIBS_DEBUG_DRAW_RECTS)
				DrawRectVisualizer.Capture(offset, size, element.WorldTransform, dc);
		}
	}
}
