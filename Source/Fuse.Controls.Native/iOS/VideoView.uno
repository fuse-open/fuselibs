using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;
using Uno.Collections;
using Fuse.Resources;
using Fuse.Elements;
using Fuse.Triggers;

namespace Fuse.Controls.Native.iOS
{

	[ForeignInclude(Language.ObjC, "AVFoundation/AVFoundation.h")]
	[Require("source.include", "iOS/VideoPlayerView.h")]
	extern(iOS) internal class VideoView : LeafView, IVideoView, IMediaPlayback
	{
		Fuse.Elements.StretchMode _stretchMode;
		public Fuse.Elements.StretchMode StretchMode
		{
			set
			{
				_stretchMode = value;
				SetStretchMode(_stretchMode);
			}
		}

		Fuse.Elements.Alignment _contentAlignment;
		public Fuse.Elements.Alignment ContentAlignment
		{
			set
			{
				_contentAlignment = value;
				SetContentGravity(_contentAlignment);
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
						SetVideoUri(_videoView, GetBundleAbsolutePath("data/" + ((BundleFileSource)_file).BundleFile.BundlePath));
					else
					{
						var data = _file.ReadAllBytes();
						var path = Uno.IO.Directory.GetUserDirectory(Uno.IO.UserDirectory.Videos) + "/" + _file.Name;
						Uno.IO.File.WriteAllBytes(path, data);
						SetVideoUri(_videoView, path);
					}
					OnLoading();

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
			get { return (((IMediaPlayback)this).Duration > 1e-05) ? ((IMediaPlayback)this).Position / ((IMediaPlayback)this).Duration : 0.0; }
			set { ((IMediaPlayback)this).Position = ((IMediaPlayback)this).Duration * value; }
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

		void SetStretchMode(Fuse.Elements.StretchMode _stretchMode)
		{
			switch (_stretchMode)
			{
				case Fuse.Elements.StretchMode.Fill:
					SetVideoGravity(_videoView, 1);
					break;
				case Fuse.Elements.StretchMode.Uniform:
					SetVideoGravity(_videoView, 2);
					break;
				case Fuse.Elements.StretchMode.UniformToFill:
					SetVideoGravity(_videoView, 3);
					break;
				default:
					SetVideoGravity(_videoView, 2);
					break;
			}
		}

		void SetContentGravity(Fuse.Elements.Alignment _contentAlignment)
		{
			switch (_contentAlignment)
				{
					case Fuse.Elements.Alignment.Center:
						SetContentGravity(_videoView, 9);
						break;
					case Fuse.Elements.Alignment.HorizontalCenter:
					case Fuse.Elements.Alignment.VerticalCenter:
						SetContentGravity(_videoView, 10);
						break;
					case Fuse.Elements.Alignment.Left:
						SetContentGravity(_videoView, 11);
						break;
					case Fuse.Elements.Alignment.Right:
						SetContentGravity(_videoView, 12);
						break;
					case Fuse.Elements.Alignment.TopCenter:
					case Fuse.Elements.Alignment.Top:
						SetContentGravity(_videoView, 13);
						break;
					case Fuse.Elements.Alignment.BottomCenter:
					case Fuse.Elements.Alignment.Bottom:
						SetContentGravity(_videoView, 14);
						break;
					case Fuse.Elements.Alignment.TopLeft:
						SetContentGravity(_videoView, 15);
						break;
					case Fuse.Elements.Alignment.TopRight:
						SetContentGravity(_videoView, 16);
						break;
					case Fuse.Elements.Alignment.BottomLeft:
						SetContentGravity(_videoView, 17);
						break;
					case Fuse.Elements.Alignment.BottomRight:
						SetContentGravity(_videoView, 18);
						break;
					default:
						SetContentGravity(_videoView, 1);
						break;
				}
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
			SetStretchMode(_stretchMode);
			_isReady = true;
			if (AutoPlay)
				((IPlayback)this).Resume();
		}

		void OnCompleted()
		{
			ResetTriggers();
			Fuse.Triggers.WhileCompleted.SetState(_host, true);
			((IPlayback)this).Stop();
			if (IsLooping)
			{
				((IPlayback)this).Resume();
			}
		}

		void OnErrorOccurred(string message)
		{
			var msg = "There is an error when playing Video: " + message;
			OnError(new Exception(msg));
		}

		ObjC.Object _videoView;
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

		[Foreign(Language.ObjC)]
		void StopVideo(ObjC.Object handle)
		@{
			VideoPlayerView* videoPlayerView = (VideoPlayerView*)handle;
			AVPlayer *player = videoPlayerView.player;
			[player pause];
			[player seekToTime: CMTimeMake(0, 1000)];
		@}

		[Foreign(Language.ObjC)]
		void PauseVideo(ObjC.Object handle)
		@{
			VideoPlayerView* videoPlayerView = (VideoPlayerView*)handle;
			AVPlayer *player = videoPlayerView.player;
			[player pause];
		@}

		[Foreign(Language.ObjC)]
		void ResumeVideo(ObjC.Object handle)
		@{
			VideoPlayerView* videoPlayerView = (VideoPlayerView*)handle;
			AVPlayer *player = videoPlayerView.player;
			[player play];
		@}

		[Foreign(Language.ObjC)]
		void ReleaseVideo(ObjC.Object handle)
		@{
			VideoPlayerView* videoPlayerView = (VideoPlayerView*)handle;
			AVPlayer *player = videoPlayerView.player;
			AVPlayerLayer* playerLayer = videoPlayerView.playerLayer;
			[player pause];
			[player removeObserver:videoPlayerView forKeyPath:@"currentItem.status"];
			[player removeObserver:videoPlayerView forKeyPath:@"currentItem.playbackLikelyToKeepUp"];
			[player removeObserver:videoPlayerView forKeyPath:@"currentItem.playbackBufferFull"];
			[player removeObserver:videoPlayerView forKeyPath:@"currentItem.playbackBufferEmpty"];
			[[NSNotificationCenter defaultCenter] removeObserver:videoPlayerView];
			playerLayer = nil;
			player = nil;
			videoPlayerView = nil;
		@}

		[Foreign(Language.ObjC)]
		double GetPosition(ObjC.Object handle)
		@{
			VideoPlayerView* videoPlayerView = (VideoPlayerView*)handle;
			AVPlayer *player = videoPlayerView.player;
			return CMTimeGetSeconds([[player currentItem] currentTime]);
		@}

		[Foreign(Language.ObjC)]
		void SetPosition(ObjC.Object handle, double position)
		@{
			VideoPlayerView* videoPlayerView = (VideoPlayerView*)handle;
			AVPlayer *player = videoPlayerView.player;
			[player seekToTime: CMTimeMake(position * 1000, 1000)];
		@}

		[Foreign(Language.ObjC)]
		double GetDuration(ObjC.Object handle)
		@{
			VideoPlayerView* videoPlayerView = (VideoPlayerView*)handle;
			AVPlayer *player = videoPlayerView.player;
			return CMTimeGetSeconds([[player currentItem] duration]);
		@}

		[Foreign(Language.ObjC)]
		void SetVolume(ObjC.Object handle, float volume)
		@{
			VideoPlayerView* videoPlayerView = (VideoPlayerView*)handle;
			AVPlayer *player = videoPlayerView.player;
			[player setVolume: volume];
		@}

		[Foreign(Language.ObjC)]
		void SetVideoGravity(ObjC.Object handle, int type)
		@{
			VideoPlayerView* videoPlayerView = (VideoPlayerView*)handle;
			AVPlayerLayer* playerLayer = videoPlayerView.playerLayer;
			if (type == 1)
				playerLayer.videoGravity = AVLayerVideoGravityResize;
			else if (type == 2)
				playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
			else
				playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
		@}

		[Foreign(Language.ObjC)]
		void SetContentGravity(ObjC.Object handle, int type)
		@{
			VideoPlayerView* videoPlayerView = (VideoPlayerView*)handle;
			AVPlayerLayer* playerLayer = videoPlayerView.playerLayer;
			if (type == 9)
				playerLayer.contentsGravity = kCAGravityCenter;
			else if (type == 10)
				playerLayer.contentsGravity = kCAGravityResizeAspectFill;
			else if (type == 11)
				playerLayer.contentsGravity = kCAGravityLeft;
			else if (type == 12)
				playerLayer.contentsGravity = kCAGravityRight;
			else if (type == 13)
				playerLayer.contentsGravity = kCAGravityTop;
			else if (type == 14)
				playerLayer.contentsGravity = kCAGravityBottom;
			else if (type == 15)
				playerLayer.contentsGravity = kCAGravityTopLeft;
			else if (type == 16)
				playerLayer.contentsGravity = kCAGravityTopRight;
			else if (type == 17)
				playerLayer.contentsGravity = kCAGravityBottomLeft;
			else if (type == 18)
				playerLayer.contentsGravity = kCAGravityBottomRight;
			else
				playerLayer.contentsGravity = kCAGravityResizeAspect;
		@}

		[Foreign(Language.ObjC)]
		bool IsPlaying(ObjC.Object handle)
		@{
			VideoPlayerView* videoPlayerView = (VideoPlayerView*)handle;
			AVPlayer *player = videoPlayerView.player;
			if (player.timeControlStatus == AVPlayerTimeControlStatusPlaying)
				return true;
			else
				return false;
		@}

		[Foreign(Language.ObjC)]
		void SetVideoUri(ObjC.Object handle, string uri)
		@{
			VideoPlayerView* videoPlayerView = (VideoPlayerView*)handle;
			AVPlayer *player = videoPlayerView.player;
			NSURL *newURL = [NSURL URLWithString:uri];
			AVPlayerItem *newItem = [AVPlayerItem playerItemWithURL:newURL];
			[player replaceCurrentItemWithPlayerItem:newItem];
		@}

		[Foreign(Language.ObjC)]
		static ObjC.Object Create()
		@{
			VideoPlayerView* videoPlayerView = [[VideoPlayerView alloc] init];
			return videoPlayerView;
		@}

		[Foreign(Language.ObjC)]
		static void InstallCallback(ObjC.Object handle, Action onLoading, Action onFrameAvailable, Action onReady, Action onComplete, Action<string> onError)
		@{
			VideoPlayerView* videoPlayerView = (VideoPlayerView*)handle;
			AVPlayer *player = videoPlayerView.player;
			videoPlayerView.onLoadingCallback = onLoading;
			videoPlayerView.onReadyCallback = onReady;
			videoPlayerView.onCompleteCallback = onComplete;
			videoPlayerView.onErrorCallback = onError;
			videoPlayerView.onFrameAvailableCallback = onFrameAvailable;
			[player addObserver:videoPlayerView
									forKeyPath:@"currentItem.status"
									options: (NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial)
									context:nil];
			[player addObserver: videoPlayerView
									forKeyPath: @"currentItem.playbackLikelyToKeepUp"
									options: (NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
									context:nil];
			[player addObserver: videoPlayerView
									forKeyPath: @"currentItem.playbackBufferFull"
									options: (NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
									context:nil];
			[player addObserver: videoPlayerView
									forKeyPath: @"currentItem.playbackBufferEmpty"
									options: (NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
									context:nil];
			[NSNotificationCenter.defaultCenter addObserver:videoPlayerView
									selector:@selector(contentDidFinishPlaying:)
									name:AVPlayerItemDidPlayToEndTimeNotification
									object:[player currentItem]];
		@}

		[Foreign(Language.ObjC)]
		static string GetBundleAbsolutePath(string bundlePath)
		@{
			return [[[NSBundle bundleForClass:[StrongUnoObject class]] URLForResource:bundlePath withExtension:@""] absoluteString];
		@}
	}
}
