using Uno;
using Uno.Graphics;
using Uno.UX;

using Fuse.Internal;
using Fuse.Nodes;

namespace Fuse.Effects
{
	/** Masks an @Element to an image.
		@examples Docs/Mask/Examples.md
	*/
	public sealed class Mask : BasicEffect, IImageContainerOwner
	{
		ImageContainer _container;

		public Mask() : base(EffectType.Composition)
		{
			_container = new ImageContainer(this);
			//nothing else is supported now (properties are also not exposed via Mask)
			_container.StretchMode = Fuse.Elements.StretchMode.Fill;
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			_container.IsRooted = true;
		}

		protected override void OnUnrooted()
		{
			_container.IsRooted = false;
			base.OnUnrooted();
		}

		void IImageContainerOwner.OnSourceChanged()
		{
			OnRenderingChanged();
		}

		void IImageContainerOwner.OnParamChanged()
		{
			OnRenderingChanged();
		}

		void IImageContainerOwner.OnSizingChanged()
		{
			OnRenderingChanged();
		}

		/** Specifies which channels should be used to determine the opacity of each pixel. */
		public enum MaskMode
		{
			/** Only the alpha channel of the image will be considered. */
			Alpha,
			/** The image is assumed to be grayscale and only the *red* channel will be considered. */
			Grayscale,
			/** Each channel will be masked separately, all channels including alpha will be considered. */
			RGBA,
		}

		MaskMode _mode = MaskMode.RGBA;
		/** Specifies which channels should be used to determine the opacity of each pixel. */
		public MaskMode Mode
		{
			get { return _mode; }
			set
			{
				if( _mode != value )
				{
					_mode = value;
					OnRenderingChanged();
				}
			}
		}

		public override VisualBounds ModifyRenderBounds( VisualBounds inBounds )
		{
			//Mask is relative to the bounds of the object, thus clips anything outside of that
			return VisualBounds.Rect(float2(0),Element.ActualSize);
		}

		protected override void OnRender(DrawContext dc, Rect elementRect)
		{
			elementRect = Rect.Intersect( new Rect(float2(0),Element.ActualSize), elementRect );
			var texture = _container.GetTexture();
			if (texture == null)
				return;

			var original = Element.CaptureRegion(dc, elementRect, float2(0));
			if (original == null)
				return;

			var scale = elementRect.Size / Element.ActualSize;
			var bias = (elementRect.LeftTop / elementRect.Size) * scale;
			switch(_mode)
			{
			case MaskMode.Alpha:
				draw Fuse.Drawing.Planar.Image
				{
					DrawContext: dc;
					Visual: Element;
					Position: elementRect.Minimum;
					Invert: true;
					Size: elementRect.Size;
					Texture: original.ColorBuffer;

					float2 uv2: float2(TexCoord.X, 1 - TexCoord.Y) * scale + bias;
					float4 m: sample(texture, uv2, Uno.Graphics.SamplerState.LinearClamp);
					PixelColor: TextureColor * m.W;

					apply Fuse.Drawing.PreMultipliedAlphaCompositing;
					DepthTestEnabled: false;
				};
				break;
			case MaskMode.Grayscale:
				draw Fuse.Drawing.Planar.Image
				{
					DrawContext: dc;
					Visual: Element;
					Position: elementRect.Minimum;
					Invert: true;
					Size: elementRect.Size;
					Texture: original.ColorBuffer;

					float2 uv2: float2(TexCoord.X, 1 - TexCoord.Y) * scale + bias;
					float4 m: sample(texture, uv2, Uno.Graphics.SamplerState.LinearClamp);
					PixelColor: TextureColor * m.X; //since gray, R==G==B

					apply Fuse.Drawing.PreMultipliedAlphaCompositing;
					DepthTestEnabled: false;
				};
				break;
			case MaskMode.RGBA:
				draw Fuse.Drawing.Planar.Image
				{
					DrawContext: dc;
					Visual: Element;
					Position: elementRect.Minimum;
					Invert: true;
					Size: elementRect.Size;
					Texture: original.ColorBuffer;

					float2 uv2: float2(TexCoord.X, 1 - TexCoord.Y) * scale + bias;
					float4 m: sample(texture, uv2, Uno.Graphics.SamplerState.LinearClamp);
					PixelColor: TextureColor * float4(m.XYZ * m.W, m.W);

					apply Fuse.Drawing.PreMultipliedAlphaCompositing;
					DepthTestEnabled: false;
				};
				break;
			}

			if defined(FUSELIBS_DEBUG_DRAW_RECTS)
				DrawRectVisualizer.Capture(elementRect.Minimum, elementRect.Size, Element.WorldTransform, dc);

			FramebufferPool.Release(original);
		}

		///////////////////////////////////////////
		// ImageContainer proxying
		[UXContent]
		/** Loads the masking image from a file. */
		public FileSource File
		{
			get { return _container.File; }
			set { _container.File = value; }
		}

		[UXContent]
		/** The source of the masking image. */
		public Resources.ImageSource Source
		{
			get { return _container.Source; }
			set { _container.Source = value; }
		}
	}
}
