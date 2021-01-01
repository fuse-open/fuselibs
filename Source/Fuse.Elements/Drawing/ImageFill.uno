using Uno;
using Uno.UX;
using Uno.Graphics;

using Fuse.Internal;
using Fuse.Elements;
using Fuse.Resources;

namespace Fuse.Drawing
{
	/**
		A @Brush that fills a @Shape with an image.

		It works almost identically to @Image, but is a @Brush and can therefore not be used as a standalone element.

		## Example

		The following example will fill a `Circle` with an image loaded from the file `Portrait.png`:

		```
		<Circle Width="160" Height="160">
			<ImageFill File="Portrait.png" />
		</Circle>
		```
	*/
	public class ImageFill : DynamicBrush, ILoading, IImageContainerOwner, IMemoryResource
	{
		public ImageFill()
		{
			_container = new ImageContainer(this);
		}

		protected override void OnPinned()
		{
			base.OnPinned();
			_container.IsRooted = true;
			LoadNow();
		}

		void LoadNow()
		{
			//trigger loading now, rather than waiting for Draw. This ensures the Busy status gets
			//set correctly, and resolves. Something might be waiting for it to be ready before
			//attempting to draw
			if (_container.IsRooted)
				_container.GetTexture();
		}

		protected override void OnUnpinned()
		{
			CleanTempTexture();
			_container.IsRooted = false;
			base.OnUnpinned();
		}

		internal bool TestIsClean
		{
			get { return _tempTexture == null && _container.TestIsClean; }
		}

		static Selector _sourceName = "Source";
		void IImageContainerOwner.OnSourceChanged()
		{
			CleanTempTexture();
			OnPropertyChanged(_sourceName);
			OnPropertyChanged(ILoadingStatic.IsLoadingName);
			LoadNow();
		}

		bool ILoading.IsLoading
		{
			get
			{
				var src = _container.Source;
				if (src == null)
					return false;
				return src.State == ImageSourceState.Loading || src.State == ImageSourceState.Pending;
			}
		}

		static Selector _colorName = "Color";
		float4 _color = float4(1);
		/**
			A color used to adjust the color of the image.

		 	For more information on what notations Color supports, check out [this subpage](articles:ux-markup/literals#colors).
		*/
		public float4 Color
		{
			get { return _color; }
			set
			{
				if (_color != value)
				{
					_color = value;
					OnPropertyChanged(_colorName);
				}
			}
		}

		float2 GetSize()
		{
			if (Source != null)
				return _container.Sizing.CalcContentSize( Source.Size, Source.PixelSize );
			return float2(0);
		}

		public struct DrawParams
		{
			public float2 Origin, Size;
			public float4 UVClip;
			public Texture2D Texture;
			public float2 TexCoordBias1, TexCoordBias2, TexCoordScale1, TexCoordScale2;
			public SamplerState SamplerState;
			public bool NeedFract;
		}
		DrawParams _drawParams;

		public framebuffer _tempTexture;

		void CleanTempTexture()
		{
			if (_tempTexture != null)
			{
				DisposalManager.Remove(this);
				FramebufferPool.Release(_tempTexture);
				_tempTexture = null;
			}
		}

		protected override void OnPrepare(DrawContext dc, float2 canvasSize)
		{
			//?? _container.Sizing.snapToPixels = SnapToPixels;
			_container.Sizing.absoluteZoom = dc == null ? 1f : dc.ViewportPixelsPerPoint;

			var contentDesiredSize = GetSize();
			var scale = _container.Sizing.CalcScale( canvasSize, contentDesiredSize );
			var origin = _container.Sizing.CalcOrigin( canvasSize, contentDesiredSize * scale );

			var dp = new DrawParams();
			dp.Origin = origin;
			dp.Size = contentDesiredSize * scale;
			dp.UVClip = _container.Sizing.CalcClip( canvasSize, ref dp.Origin, ref dp.Size );
			dp.Texture = _container.GetTexture();

			if (dp.Texture != null && !dp.Texture.IsPow2 && WrapMode == WrapMode.Repeat && !Texture2D.HaveNonPow2Support)
			{
				/* Unfortunately, OpenGL ES 2.0 doesn't mandate support for repeating
					non-power-of-two textures, so we need to do a little bit of magic
					by ourselves; as a pre-pass, we repeat the first row/column of texels
					at the end of the texture, so we can manually wrap and offset/bias
					the texture coordinates to still get bilinear interpolation of the
					texels. */
				if (_tempTexture == null)
				{
					var size = int2(dp.Texture.Size.X + 1, dp.Texture.Size.Y + 1);
					_tempTexture = FramebufferPool.Lock(size, Format.RGBA8888, false);
					DisposalManager.Add(this);
					RepeatBaker.Singleton.FillBuffer(dc, dp.Texture, _tempTexture);
				}

				dp.TexCoordBias1 = -float2(0.5f) / dp.Texture.Size;
				dp.TexCoordScale1 = float2(1.0f); // float2(2.0f, 4.0f); // repeating amount
				dp.TexCoordBias2 = float2(0.5f) / _tempTexture.ColorBuffer.Size;
				dp.TexCoordScale2 = (float2)(dp.Texture.Size) / _tempTexture.ColorBuffer.Size;

				dp.Texture = _tempTexture.ColorBuffer;
				dp.SamplerState = SamplerState.LinearClamp;
				dp.NeedFract = true;
			}
			else
			{
				CleanTempTexture();

				dp.TexCoordBias1 = float2(0.0f);
				dp.TexCoordScale1 = float2(1.0f);
				dp.TexCoordBias2 = float2(0.0f);
				dp.TexCoordScale2 = float2(1.0f);

				dp.SamplerState = (WrapMode == WrapMode.Repeat) ? SamplerState.LinearWrap : SamplerState.LinearClamp;
				dp.NeedFract = false;
			}

			_drawParams = dp;
			_lastUsed = Time.FrameTime;
		}

		public DrawParams GetDrawParams(DrawContext dc, float2 size)
		{
			return _drawParams;
		}

		//translate to/from element position to get the correct UV coordinates based on _container.Sizing
		float2 ElementPosition: req(TexCoord as float2)
			CanvasSize * TexCoord;
		float2 OurTC:
			(ElementPosition - DP.Origin)/DP.Size *(DP.UVClip.ZW - DP.UVClip.XY) + DP.UVClip.XY;

		DrawContext DrawContext: prev, null;
		DrawParams DP:
			GetDrawParams(DrawContext, CanvasSize);

		float2 AdjustedTexCoord: DP.TexCoordBias1 + OurTC * DP.TexCoordScale1;
		float2 WrappedTexCoord: DP.TexCoordBias2 + Math.Fract(pixel AdjustedTexCoord) * DP.TexCoordScale2;
		float2 FinalTexCoord: DP.NeedFract ? WrappedTexCoord : OurTC;
		float4 TextureColor: DP.Texture == null ? float4(0) : sample(DP.Texture, FinalTexCoord, DP.SamplerState);

		float4 fc : TextureColor * Color;
		FinalColor: float4(fc.XYZ*fc.W, fc.W);

		///////////////////////////////////////////
		// ImageContainer proxying
		ImageContainer _container;
		[UXContent]
		public FileSource File
		{
			get { return _container.File; }
			set { _container.File = value; }
		}

		internal SizingContainer SizingContainer
		{
			get { return _container.Sizing; }
		}

		public string Url
		{
			get { return _container.Url; }
			set { _container.Url = value; }
		}

		public float Density
		{
			get { return _container.Density; }
			set { _container.Density = value; }
		}

		public MemoryPolicy MemoryPolicy
		{
			get { return _container.MemoryPolicy; }
			set { _container.MemoryPolicy = value; }
		}

		[UXContent]
		public Resources.ImageSource Source
		{
			get { return _container.Source; }
			set { _container.Source = value; }
		}

		public ResampleMode ResampleMode
		{
			get { return _container.ResampleMode; }
			set { _container.ResampleMode = value; }
		}

		static Selector _wrapModeName = "WrapMode";
		WrapMode _wrapMode = WrapMode.Repeat;
		public WrapMode WrapMode
		{
			get { return _wrapMode; }
			set
			{
				if (_wrapMode != value)
				{
					_wrapMode = value;
					OnPropertyChanged(_wrapModeName);
				}
			}
		}

		static Selector _paramName = "Param";
		void IImageContainerOwner.OnParamChanged()
		{
			OnPropertyChanged(_paramName);
		}

		public StretchMode StretchMode
		{
			get { return _container.StretchMode; }
			set { _container.StretchMode = value; }
		}

		static Selector _sizingName = "Sizing";
		void IImageContainerOwner.OnSizingChanged()
		{
			OnPropertyChanged(_sizingName);
		}

		public StretchDirection StretchDirection
		{
			get { return _container.StretchDirection; }
			set { _container.StretchDirection = value; }
		}

		public Fuse.Elements.Alignment ContentAlignment
		{
			get { return _container.ContentAlignment; }
			set { _container.ContentAlignment = value; }
		}

		double _lastUsed;
		MemoryPolicy IMemoryResource.MemoryPolicy { get { return _container.MemoryPolicy; } }
		bool IMemoryResource.IsPinned { get { return _container.IsRooted; } }
		double IMemoryResource.LastUsed { get { return _lastUsed; } }
		void IMemoryResource.SoftDispose() { CleanTempTexture(); }
	}

	class RepeatBaker
	{
		static public RepeatBaker Singleton = new RepeatBaker();

		public void FillBuffer(DrawContext dc, texture2D tex, framebuffer fb)
		{
			dc.PushRenderTarget(fb);

			draw
			{
				float2[] Vertices: new []
				{
					float2(0, 0), float2(0, 1), float2(1, 1),
					float2(0, 0), float2(1, 1), float2(1, 0)
				};
				float2 VertexPosition: vertex_attrib(Vertices);
				ClipPosition: float4(VertexPosition * 2 - 1, 0, 1);

				float2 TexelIndex: VertexPosition * fb.Size;
				float2 TexCoord: TexelIndex / tex.Size;

				CullFace: PolygonFace.None;
				DepthTestEnabled: false;
				BlendEnabled: false;

				PixelColor: sample(tex, Math.Fract(pixel TexCoord), SamplerState.NearestClamp);
			};

			dc.PopRenderTarget();
		}
	}
}
