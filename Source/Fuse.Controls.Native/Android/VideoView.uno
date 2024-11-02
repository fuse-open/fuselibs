using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;
using Uno.Collections;
using Fuse.Resources;
using Fuse.Elements;
using Fuse.Triggers;

namespace Fuse.Controls.Native.Android
{

	extern(Android) internal class VideoView : View, IVideoView, IMediaPlayback
	{

		Fuse.Elements.StretchMode _stretchMode;
		public Fuse.Elements.StretchMode StretchMode
		{
			set
			{
				_stretchMode = value;
				switch (_stretchMode)
				{
					case Fuse.Elements.StretchMode.Fill:
						ScalableType(_videoView, 1);
						break;
					case Fuse.Elements.StretchMode.Uniform:
						ScalableType(_videoView, 2);
						break;
					case Fuse.Elements.StretchMode.UniformToFill:
						ScalableType(_videoView, 3);
						break;
					default:
						ScalableType(_videoView, 1);
						break;
				}
			}
		}

		Fuse.Elements.Alignment _contentAlignment;
		public Fuse.Elements.Alignment ContentAlignment
		{
			set
			{
				_contentAlignment = value;
				switch (_contentAlignment)
				{
					case Fuse.Elements.Alignment.Center:
					case Fuse.Elements.Alignment.HorizontalCenter:
					case Fuse.Elements.Alignment.VerticalCenter:
						ScalableType(_videoView, 10);
						break;
					case Fuse.Elements.Alignment.Left:
						ScalableType(_videoView, 11);
						break;
					case Fuse.Elements.Alignment.Right:
						ScalableType(_videoView, 12);
						break;
					case Fuse.Elements.Alignment.Top:
						ScalableType(_videoView, 13);
						break;
					case Fuse.Elements.Alignment.Bottom:
						ScalableType(_videoView, 14);
						break;
					case Fuse.Elements.Alignment.TopLeft:
						ScalableType(_videoView, 15);
						break;
					case Fuse.Elements.Alignment.TopCenter:
						ScalableType(_videoView, 16);
						break;
					case Fuse.Elements.Alignment.TopRight:
						ScalableType(_videoView, 17);
						break;
					case Fuse.Elements.Alignment.BottomLeft:
						ScalableType(_videoView, 18);
						break;
					case Fuse.Elements.Alignment.BottomCenter:
						ScalableType(_videoView, 19);
						break;
					case Fuse.Elements.Alignment.BottomRight:
						ScalableType(_videoView, 20);
						break;
					default:
						ScalableType(_videoView, 1);
						break;
				}
			}
		}

		FileSource _file;
		public FileSource File
		{
			set
			{
				if (value != _file)
				{
					_file = value;
					if (_file is BundleFileSource)
						SetVideoFromAsset(_videoView, ((BundleFileSource)_file).BundleFile.BundlePath);
					else
					{
						var data = _file.ReadAllBytes();
						var path = Uno.IO.Directory.GetUserDirectory(Uno.IO.UserDirectory.Videos) + "/" + _file.Name;
						Uno.IO.File.WriteAllBytes(path, data);
						SetVideoUri(_videoView, path);
					}
					OnLoading();
					PrepareVideo(_videoView);

				}
			}
		}

		string _url;
		public string Url
		{
			set
			{
				if (value != "" && value != _url)
				{
					_url = value;
					SetVideoUri(_videoView, _url);
					OnLoading();
					PrepareVideo(_videoView);
				}
			}
		}

		bool _isLooping;
		public bool IsLooping
		{
			get
			{
				return _isLooping;
			}
			set
			{
				_isLooping = value;
				SetLooping(_videoView, _isLooping);
			}
		}

		bool _autoPlay;
		public bool AutoPlay
		{
			get
			{
				return _autoPlay;
			}
			set
			{
				_autoPlay = value;
			}
		}

		float _volume;
		public float IMediaPlayback.Volume
		{
			get
			{
				return _volume;
			}
			set
			{
				_volume = value;
				SetVolume(_videoView, _volume);
			}
		}

		public double IMediaPlayback.Duration
		{
			get
			{
				return GetDuration(_videoView);
			}
		}

		public double IMediaPlayback.Position
		{
			get { return GetPosition(_videoView); }
			set { SetPosition(_videoView, value); }
		}

		bool _isReady = false;

		public void IPlayback.Stop()
		{
			if (_isReady)
			{
				((IPlayback)this).Pause();
				((IMediaPlayback)this).Position = 0.0;
			}
		}

		public void IPlayback.Pause()
		{
			if (_isReady)
			{
				PauseVideo(_videoView);
				ResetTriggers();
				Fuse.Triggers.WhilePaused.SetState(_host, true);
			}
		}

		public void IPlayback.Resume()
		{
			if (_isReady)
			{
				ResetTriggers();
				Fuse.Triggers.WhilePlaying.SetState(_host, true);
				ResumeVideo(_videoView);
			}
		}

		public void IVideoView.Release()
		{
			ReleaseVideo(_videoView);
		}

		double IProgress.Progress
		{
			get { return (((IMediaPlayback)this).Duration > 1e-05) ? ((IMediaPlayback)this).Position / ((IMediaPlayback)this).Duration : 0.0; }
		}

		public double IPlayback.Progress
		{
			get
			{
				return (((IMediaPlayback)this).Duration > 1e-05) ? ((IMediaPlayback)this).Position / ((IMediaPlayback)this).Duration : 0.0;
			}
			set
			{
				((IMediaPlayback)this).Position = ((IMediaPlayback)this).Duration * value;
			}
		}

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

		void IVideoView.OnUpdate()
		{
			if (_isReady && IsPlaying(_videoView))
				OnProgressChanged();
		}

		BusyTask _busyTask;
		void ResetTriggers()
		{
			BusyTask.SetBusy(_host, ref _busyTask, BusyTaskActivity.None);
			Fuse.Triggers.WhileCompleted.SetState(_host, false);
			Fuse.Triggers.WhilePlaying.SetState(_host, false);
			Fuse.Triggers.WhilePaused.SetState(_host, false);
		}

		int2 _sizeCache = int2(0,0);
		void OnFrameAvailable()
		{
			ResetTriggers();
			BusyTask.SetBusy(_host, ref _busyTask, BusyTaskActivity.None);
			if (!_isReady && IsPlaying(_videoView))
				Fuse.Triggers.WhilePlaying.SetState(_host, true);
			_isReady = true;
		}

		void OnError(Exception e)
		{
			ResetTriggers();
			BusyTask.SetBusy(_host, ref _busyTask, BusyTaskActivity.Failed, e.Message );
			Fuse.Diagnostics.UnknownException("Video error", e, this);
			_isReady = false;
		}

		void OnLoading()
		{
			ResetTriggers();
			BusyTask.SetBusy(_host, ref _busyTask, BusyTaskActivity.Loading);
			_isReady = false;
		}

		void OnReady()
		{
			ResetTriggers();
			BusyTask.SetBusy(_host, ref _busyTask, BusyTaskActivity.None);
			_isReady = true;
			if (AutoPlay)
				((IPlayback)this).Resume();

		}

		void OnCompleted()
		{
			ResetTriggers();
			Fuse.Triggers.WhileCompleted.SetState(_host, true);
		}

		void OnErrorOccurred(int what, int extra)
		{
			var msg = "what: " + what + " extra: " + extra;
			OnError(new Exception(msg));
		}


		Java.Object _videoView;
		Element _host;

		public VideoView(Element host) : base(Create())
		{
			_videoView = Handle;
			_host = host;
			InstallCallback(_videoView, OnLoading, OnFrameAvailable, OnReady, OnCompleted, OnErrorOccurred);
		}

		public override void Dispose()
		{
			base.Dispose();
			ReleaseVideo(_videoView);
		}

		[Foreign(Language.Java)]
		void InstallCallback(Java.Object handle, Action onLoading , Action onFrameAvailable, Action onReady, Action onComplete, Action<int, int> onError)
		@{
			com.fuse.android.views.VideoView videoView = (com.fuse.android.views.VideoView)handle;
			videoView.setOnPreparedListener(new android.media.MediaPlayer.OnPreparedListener() {
				public void onPrepared(android.media.MediaPlayer mp) {
					onReady.run();
					onFrameAvailable.run();
				}
			});

			videoView.setOnInfoListener(new android.media.MediaPlayer.OnInfoListener() {
				@Override
				public boolean onInfo(android.media.MediaPlayer mp, int what, int extra) {
					if (what == android.media.MediaPlayer.MEDIA_INFO_BUFFERING_START) {
						onLoading.run();
					} else if (what == android.media.MediaPlayer.MEDIA_INFO_BUFFERING_END) {
						onFrameAvailable.run();
					}
					return true;
				}
			});

			videoView.setOnCompletionListener(new android.media.MediaPlayer.OnCompletionListener() {
				@Override
				public void onCompletion(android.media.MediaPlayer mediaPlayer) {
					onComplete.run();
				}
			});

			videoView.setOnErrorListener(new android.media.MediaPlayer.OnErrorListener() {
				public boolean onError(android.media.MediaPlayer mp, int what, int extra) {
					onError.run(what, extra);
					return false;
				}
			});
		@}

		[Foreign(Language.Java)]
		void StopVideo(Java.Object handle)
		@{
			((com.fuse.android.views.VideoView)handle).stop();
			((com.fuse.android.views.VideoView)handle).reset();
		@}

		[Foreign(Language.Java)]
		void PauseVideo(Java.Object handle)
		@{
			((com.fuse.android.views.VideoView)handle).pause();
		@}

		[Foreign(Language.Java)]
		void ResumeVideo(Java.Object handle)
		@{
			com.fuse.android.views.VideoView videoView = (com.fuse.android.views.VideoView)handle;
			videoView.start();
		@}

		[Foreign(Language.Java)]
		void ReleaseVideo(Java.Object handle)
		@{
			((com.fuse.android.views.VideoView)handle).release();
		@}

		[Foreign(Language.Java)]
		double GetPosition(Java.Object handle)
		@{
			return (double)((com.fuse.android.views.VideoView)handle).getCurrentPosition();
		@}

		[Foreign(Language.Java)]
		void SetPosition(Java.Object handle, double position)
		@{
			((com.fuse.android.views.VideoView)handle).seekTo((int)position);
		@}

		[Foreign(Language.Java)]
		double GetDuration(Java.Object handle)
		@{
			return (double)((com.fuse.android.views.VideoView)handle).getDuration();
		@}

		[Foreign(Language.Java)]
		void SetVolume(Java.Object handle, float volume)
		@{
			((com.fuse.android.views.VideoView)handle).setVolume( volume, volume);
		@}

		[Foreign(Language.Java)]
		void SetLooping(Java.Object handle, bool looping)
		@{
			((com.fuse.android.views.VideoView)handle).setLooping(looping);
		@}

		[Foreign(Language.Java)]
		void ScalableType(Java.Object handle, int type)
		@{
			com.fuse.android.views.VideoView videoView = (com.fuse.android.views.VideoView)handle;
			switch (type) {
				case 1:
					videoView.setScalableType(com.fuse.android.views.ScalableType.FIT_XY);
					break;
				case 2:
					videoView.setScalableType(com.fuse.android.views.ScalableType.FIT_CENTER);
					break;
				case 3:
					videoView.setScalableType(com.fuse.android.views.ScalableType.CENTER_CROP);
					break;
				case 10:
					videoView.setScalableType(com.fuse.android.views.ScalableType.CENTER);
					break;
				case 11:
					videoView.setScalableType(com.fuse.android.views.ScalableType.LEFT_CENTER);
					break;
				case 12:
					videoView.setScalableType(com.fuse.android.views.ScalableType.RIGHT_CENTER);
					break;
				case 13:
					videoView.setScalableType(com.fuse.android.views.ScalableType.CENTER_TOP_CROP);
					break;
				case 14:
					videoView.setScalableType(com.fuse.android.views.ScalableType.CENTER_BOTTOM_CROP);
					break;
				case 15:
					videoView.setScalableType(com.fuse.android.views.ScalableType.LEFT_TOP);
					break;
				case 16:
					videoView.setScalableType(com.fuse.android.views.ScalableType.CENTER_TOP);
					break;
				case 17:
					videoView.setScalableType(com.fuse.android.views.ScalableType.RIGHT_TOP);
					break;
				case 18:
					videoView.setScalableType(com.fuse.android.views.ScalableType.LEFT_BOTTOM);
					break;
				case 19:
					videoView.setScalableType(com.fuse.android.views.ScalableType.CENTER_BOTTOM);
					break;
				case 20:
					videoView.setScalableType(com.fuse.android.views.ScalableType.RIGHT_BOTTOM);
					break;
			}
		@}

		[Foreign(Language.Java)]
		void PrepareVideo(Java.Object handle)
		@{
			try {
				((com.fuse.android.views.VideoView)handle).prepareAsync();
			} catch (Exception e) {
				e.printStackTrace();
			}
		@}

		[Foreign(Language.Java)]
		bool IsPlaying(Java.Object handle)
		@{
			return ((com.fuse.android.views.VideoView)handle).isPlaying();
		@}

		[Foreign(Language.Java)]
		void SetVideoUri(Java.Object handle, string uri)
		@{
			com.fuse.android.views.VideoView player = (com.fuse.android.views.VideoView)handle;
			try
			{
				player.setDataSource(com.fuse.Activity.getRootActivity(), android.net.Uri.parse(uri));
			} catch (java.io.IOException e) {
				e.printStackTrace();
			}
		@}

		[Foreign(Language.Java)]
		void SetVideoFromAsset(Java.Object handle, string assetName)
		@{
			com.fuse.android.views.VideoView player = (com.fuse.android.views.VideoView)handle;
			android.content.res.AssetFileDescriptor afd = null;
			try
			{
				afd = com.fuse.Activity.getRootActivity().getAssets().openFd(assetName);
				player.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());
				afd.close();
			}
			catch (Exception e)
			{
				android.util.Log.e("Fuse.Video", e.getMessage());
			}
		@}


		[Foreign(Language.Java)]
		static Java.Object Create()
		@{
			com.fuse.android.views.VideoView videoView = new com.fuse.android.views.VideoView(com.fuse.Activity.getRootActivity());
			videoView.setScalableType(com.fuse.android.views.ScalableType.CENTER_INSIDE);
			videoView.setLayoutParams(new android.widget.FrameLayout.LayoutParams(android.view.ViewGroup.LayoutParams.MATCH_PARENT, android.view.ViewGroup.LayoutParams.MATCH_PARENT));
			return videoView;
		@}

	}
}
