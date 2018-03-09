using Uno;
using Uno.UX;
using Uno.Graphics;

using Fuse;
using Fuse.Triggers;
using Fuse.Elements;
using Fuse.Controls;
using Fuse.Controls.Graphics;
using Fuse.Internal;
using Fuse.Nodes;

namespace Fuse.Controls.VideoImpl
{

	internal extern (!iOS && !Android && !DOTNET) class VideoVisual : ControlVisual<global::Fuse.Controls.Video>
	{
	
		readonly Panel _placeholder;
		
		public VideoVisual()
		{
			_placeholder = new Panel();
			_placeholder.Children.Add(new Text()
			{
				Value = "Coming soon!",
				TextColor = float4(0f, 0f, 0f, 1f),
				FontSize = 30f,
				TextAlignment = TextAlignment.Center,
				Alignment = Alignment.Center
			});
			var image = new Image();
			image.File = Fuse.Controls.VideoImpl.Placeholder.File;
			image.StretchMode = StretchMode.UniformToFill;

			_placeholder.Children.Add(image);
		}
		
		protected override void Attach()
		{
			Control.Children.Add(_placeholder);
		}

		protected override void Detach()
		{
			Control.Children.Remove(_placeholder);
		}	

		public override void Draw(DrawContext dc) { }
	}

	internal extern (iOS || Android || DOTNET) class VideoVisual :
		ControlVisual<global::Fuse.Controls.Video>,
		IVideoCallbacks,
		IMediaPlayback
	{

		enum PlaybackTarget
		{
			Undefined,
			Playing,
			Paused,
			Stopped
		}

		PlaybackTarget _playbackTarget = PlaybackTarget.Undefined;

		protected override void Attach()
		{
			Control.RenderParamChanged += OnRenderParamChanged;
			Control.ParamChanged += OnParamChanged;
			Control.SourceChanged += OnSourceChanged;
			UpdateManager.AddAction(OnUpdate);

			Control.SetPlayback(this);

			OnRenderParamChanged(null, null);
			OnParamChanged(null, null);
			OnSourceChanged(null, null);
		}

		protected override void Detach()
		{
			_videoService.Unload();
			Control.SetPlayback(null);
			Control.RenderParamChanged -= OnRenderParamChanged;
			Control.ParamChanged -= OnParamChanged;
			Control.SourceChanged -= OnSourceChanged;
			UpdateManager.RemoveAction(OnUpdate);
		}

		readonly SizingContainer _sizing;
		readonly IVideoService _videoService;

		public VideoVisual()
		{
			_sizing = new SizingContainer();
			_videoService = new GraphicsVideoService(this);
		}

		int2 _sizeCache = int2(0,0);
		void IVideoCallbacks.OnFrameAvailable()
		{
			if (_videoService.Size != _sizeCache)
			{
				_sizeCache = _videoService.Size;
				InvalidateLayout();
			}
			InvalidateVisual();
		}

		void IVideoCallbacks.OnError(Exception e)
		{
			ResetTriggers();
			BusyTask.SetBusy(Control, ref _busyTask, BusyTaskActivity.Failed, e.Message );
			Fuse.Diagnostics.UnknownException("Video error", e, this);
		}

		BusyTask _busyTask;
		void IVideoCallbacks.OnLoading()
		{
			ResetTriggers();
			BusyTask.SetBusy(Control, ref _busyTask, BusyTaskActivity.Loading);
		}

		void IVideoCallbacks.OnReady()
		{
			ResetTriggers();
			BusyTask.SetBusy(Control, ref _busyTask, BusyTaskActivity.None);

			Control.OnDurationChanged();

			var playback = (IPlayback)this;
			switch (_playbackTarget)
			{
				case PlaybackTarget.Playing:
					playback.Resume();
					break;

				case PlaybackTarget.Paused:
					playback.Pause();
					break;

				case PlaybackTarget.Stopped:
					playback.Stop();
					break;
			}

			_playbackTarget = PlaybackTarget.Undefined;
		}

		void IVideoCallbacks.OnCompleted()
		{
			ResetTriggers();
			Fuse.Triggers.WhileCompleted.SetState(Control, true);
		}

		float _volume = 1.0f;
		float IMediaPlayback.Volume
		{
			get { return _volume; }
			set { _videoService.Volume = _volume = value; }
		}

		double IMediaPlayback.Position
		{
			get { return _videoService.Position; }
			set { _videoService.Position = value; }
		}

		double IMediaPlayback.Duration
		{
			get { return _videoService.Duration; }
		}

		void IPlayback.Stop()
		{
			_playbackTarget = PlaybackTarget.Stopped;
			((IPlayback)this).Pause();
			((IMediaPlayback)this).Position = 0.0;
		}

		/** Deprecated **/
		void IPlayback.PlayTo(double progress)
		{
			Fuse.Diagnostics.Unsupported("IPlayback.PlayTo(double) not supported in Fuse.Controls.Video",
				this);
		}
		bool IPlayback.CanPlayTo { get { return false; } }
		/** End-Deprecated **/

		void IPlayback.Pause()
		{
			_playbackTarget = PlaybackTarget.Paused;
			if (_videoService.IsValid)
			{
				_videoService.Pause();
				ResetTriggers();
				Fuse.Triggers.WhilePaused.SetState(Control, true);
			}
		}

		void IPlayback.Resume()
		{
			_playbackTarget = PlaybackTarget.Playing;
			if (_videoService.IsValid)
			{
				ResetTriggers();
				Fuse.Triggers.WhilePlaying.SetState(Control, true);
				_videoService.Play();
			}
		}

		double IProgress.Progress
		{
			get { return (_videoService.Duration > 1e-05) ? _videoService.Position / _videoService.Duration : 0.0; }
		}

		double IPlayback.Progress
		{
			get { return (_videoService.Duration > 1e-05) ? _videoService.Position / _videoService.Duration : 0.0; }
			set { _videoService.Position = _videoService.Duration * value; }
		}

		bool IPlayback.CanStop { get { return true; } }
		bool IPlayback.CanPause { get { return true; } }
		bool IPlayback.CanResume { get { return true; } }

		event ValueChangedHandler<double> IProgress.ProgressChanged
		{
			add { ProgressChanged += value; }
			remove { ProgressChanged -= value; }
		}

		event ValueChangedHandler<double> ProgressChanged;
		void OnProgressChanged()
		{
			if (ProgressChanged != null)
			{
				var progress = ((IPlayback)this).Progress;
				ProgressChanged(this, new ValueChangedArgs<double>(progress));
			}
		}

		void OnUpdate()
		{
			_videoService.Update();
			if (_videoService.IsValid)
				OnProgressChanged();
		}

		void OnRenderParamChanged(object sender, EventArgs args)
		{
			_sizing.SetStretchMode(Control.StretchMode);
			_sizing.SetStretchDirection(Control.StretchDirection);
			_sizing.SetStretchSizing(Control.StretchSizing);
			_sizing.SetAlignment(Control.ContentAlignment);
			InvalidateVisual();
		}

		void OnParamChanged(object sender, EventArgs args)
		{
			_videoService.IsLooping = Control.IsLooping;
			_videoService.AutoPlay = Control.AutoPlay;
			_videoService.Volume = Control.Volume;
		}

		void OnSourceChanged(object sender, EventArgs args)
		{
			if (Control.File != null)
			{
				_videoService.Load(Control.File);
				return;
			}

			if (Control.Url != null)
			{
				_videoService.Load(Control.Url);
				return;
			}
		}

		void ResetTriggers()
		{
			BusyTask.SetBusy(Control, ref _busyTask, BusyTaskActivity.None);
			Fuse.Triggers.WhileCompleted.SetState(Control, false);
			Fuse.Triggers.WhilePlaying.SetState(Control, false);
			Fuse.Triggers.WhilePaused.SetState(Control, false);
		}

		public sealed override float2 GetMarginSize( LayoutParams lp)
		{
			_sizing.snapToPixels = Control.SnapToPixels;
			_sizing.absoluteZoom = Control.AbsoluteZoom;
			return _sizing.ExpandFillSize(GetSize(), lp);
		}


		float2 GetSize()
		{
			return (float2)_videoService.Size;
		}

		float2 _origin;
		float2 _scale;
		float2 _drawOrigin;
		float2 _drawSize;
		float4 _uvClip;
		protected sealed override float2 OnArrangeMarginBox(float2 position, LayoutParams lp)
		{
			var size = base.OnArrangeMarginBox(position, lp);

			_sizing.snapToPixels = Control.SnapToPixels;
			_sizing.absoluteZoom = Control.AbsoluteZoom;

			var contentDesiredSize = GetSize();

			_scale = _sizing.CalcScale( size, contentDesiredSize );
			_origin = _sizing.CalcOrigin( size, contentDesiredSize * _scale );

			_drawOrigin = _origin;
			_drawSize = contentDesiredSize * _scale;
			_uvClip = _sizing.CalcClip( size, ref _drawOrigin, ref _drawSize );

			return size;
		}

		public sealed override void Draw(DrawContext dc)
		{
			var texture = _videoService.VideoTexture;
			if (texture == null)
				return;

			if (Control.StretchMode == StretchMode.Scale9)
			{
				Fuse.Diagnostics.Deprecated("StretchMode.Scale9 is deprecated for video-visual", this);
				Scale9Rectangle.Impl.
					Draw(dc, this, ActualSize, GetSize(), texture, Control.Scale9Margin);
			}
			else
			{
				var rotation = _videoService.RotationDegrees / 90;
				VideoDrawElement.Impl.
					Draw(dc, this, _drawOrigin, _drawSize, _uvClip.XY, _uvClip.ZW - _uvClip.XY, texture, rotation);
			}
		}

		protected override void OnHitTest(HitTestContext htc)
		{
			//must be in the actual video part shown
			var lp = htc.LocalPoint;
			if (lp.X >= _drawOrigin.X && lp.X <= (_drawOrigin.X + _drawSize.X) &&
				lp.Y >= _drawOrigin.Y && lp.Y <= (_drawOrigin.Y + _drawSize.Y) )
				htc.Hit(this);
				
			base.OnHitTest(htc);
		}

	}

	class VideoDrawElement
	{
		static public VideoDrawElement Impl = new VideoDrawElement();

		static readonly float3x3[] Transforms = new float3x3[4];

		static VideoDrawElement()
		{
			var t = float3x3.Identity;
			t.M11 = t.M22 = Math.Cos(Math.PIf / 2.0f);
			t.M21 = Math.Sin(Math.PIf / 2.0f);
			t.M12 = -t.M21;
			t.M32 = 1.0f;

			Transforms[0] = float3x3.Identity;
			Transforms[1] = t;
			Transforms[2] = Matrix.Mul(t, t);
			Transforms[3] = Matrix.Mul(Matrix.Mul(t, t), t);
		}

		public void Draw(DrawContext dc, Visual element, float2 offset, float2 size,
			float2 uvPosition, float2 uvSize, VideoTexture tex, int rotation)
		{
			var transform = Transforms[rotation];
			draw
			{
				apply Fuse.Drawing.Planar.Rectangle;

				DrawContext: dc;
				Visual: element;
				Size: size;
				Position: offset;

				TexCoord: VertexData * uvSize + uvPosition;
				TexCoord: Vector.Transform(float3(prev.XY, 1.0f), transform).XY;

				PixelColor: float4(sample(tex, TexCoord, SamplerState.LinearClamp).XYZ, 1.0f);
			};

			if defined(FUSELIBS_DEBUG_DRAW_RECTS)
				DrawRectVisualizer.Capture(offset, size, element.WorldTransform, dc);
		}
	}

	class Scale9Rectangle
	{
		static public Scale9Rectangle Impl = new Scale9Rectangle();

		public void Draw(DrawContext dc, Visual element, float2 size,  float2 scaleTextureSize,
			VideoTexture tex, float4 margin)
		{
			draw
			{
				float3[] xverts: new []
				{
					float3(0,0,0), float3(1,0,0), float3(0,1,0), float3(0,0,1),
					float3(0,0,0), float3(1,0,0), float3(0,1,0), float3(0,0,1),
					float3(0,0,0), float3(1,0,0), float3(0,1,0), float3(0,0,1),
					float3(0,0,0), float3(1,0,0), float3(0,1,0), float3(0,0,1)
				};

				float3[] yverts: new []
				{
					float3(0,0,0), float3(0,0,0), float3(0,0,0), float3(0,0,0),
					float3(1,0,0), float3(1,0,0), float3(1,0,0), float3(1,0,0),
					float3(0,1,0), float3(0,1,0), float3(0,1,0), float3(0,1,0),
					float3(0,0,1), float3(0,0,1), float3(0,0,1), float3(0,0,1)
				};

				ushort[] indices: new ushort[]
				{
					0,4,5,		0,5,1, 		1,5,6,		1,6,2,		2,6,7, 	 	2,7,3,
					4,8,9, 	  	4,9,5,		5,9,10, 	5,10,6,		6,10,11, 	6,11,7,
					8,12,13, 	8,13,9,		9,13,14,	9,14,10,	10,14,15,	10,15,11
				};

				float3 xv: vertex_attrib(xverts, indices);
				float3 yv: vertex_attrib(yverts, indices);

				CullFace: Uno.Graphics.PolygonFace.None;
				DepthTestEnabled: false;

				apply Fuse.Drawing.AlphaCompositing;

				float Ax: margin.X;
				float Bx: size.X - margin.Z;
				float Cx: size.X;
				float Ay: margin.Y;
				float By: size.Y - margin.W;
				float Cy: size.Y;

				float x: xv.X * Ax + xv.Y * Bx + xv.Z * Cx;
				float y: yv.X * Ay + yv.Y * By + yv.Z * Cy;

				float2 LocalPosition: float2(x, y);

				float4 WorldPosition: Vector.Transform(float4(LocalPosition,0,1), element.WorldTransform);

				public float2 TexCoord : float2(
					xv.X * margin.X + xv.Y * (scaleTextureSize.X-margin.Z) + xv.Z * scaleTextureSize.X,
					yv.X * margin.Y + yv.Y * (scaleTextureSize.Y-margin.W) + yv.Z * scaleTextureSize.Y) / scaleTextureSize;

				ClipPosition: Vector.Transform( WorldPosition, dc.Viewport.ViewProjectionTransform );
				public float4 TextureColor: float4(sample( tex, TexCoord, SamplerState.LinearClamp ).XYZ, 1.0f);
				PixelColor: TextureColor;
			};

			if defined(FUSELIBS_DEBUG_DRAW_RECTS)
				DrawRectVisualizer.Capture(float2(0), size, element.WorldTransform, dc);
		}
	}

}
