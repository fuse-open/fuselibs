using Uno;
using Uno.UX;
using Uno.IO;
using Fuse;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Platform;
using OpenGL;
using Uno.Graphics;
using Uno.Threading;

namespace Fuse.Controls.VideoImpl.Android
{

	extern(Android) internal class VideoLoader
	{
		class VideoPromise : Promise<IVideoPlayer>
		{
			readonly MediaPlayer _videoPlayer;

			VideoPromise()
			{
				_videoPlayer = new MediaPlayer();
				HookEvents();
			}

			public VideoPromise(BundleFile file) : this()
			{
				_videoPlayer.LoadAsync(file);
			}

			public VideoPromise(string url) : this()
			{
				_videoPlayer.LoadAsync(url);
			}

			void HookEvents()
			{
				_videoPlayer.Prepared += OnPrepared;
				_videoPlayer.Error += OnError;
			}

			void UnhookEvents()
			{
				_videoPlayer.Prepared -= OnPrepared;
				_videoPlayer.Error -= OnError;
			}

			void OnPrepared(object sender, EventArgs args)
			{
				UnhookEvents();
				_readyToDispose = true;
				if (!_isCancelled)
					Resolve(_videoPlayer);
			}

			void OnError(object sender, string msg)
			{
				UnhookEvents();
				_readyToDispose = true;
				if (!_isCancelled)
					Reject(new Uno.Exception(msg));
			}

			bool _readyToDispose = false;
			bool _isCancelled = false;
			public override void Cancel(bool shutdownGracefully = false)
			{
				ScheduleDispose();
			}

			void ScheduleDispose()
			{
				if (!_isCancelled)
				{
					_isCancelled = true;
					UpdateManager.AddAction(DoDispose);
				}
			}

			void DoDispose()
			{
				if (_readyToDispose)
				{
					_videoPlayer.Dispose();
					UpdateManager.RemoveAction(DoDispose);
				}
			}

			public override void Dispose()
			{
				base.Dispose();
				ScheduleDispose();	
			}
		}

		class NoHardwareAcceleration : Promise<IVideoPlayer>
		{
			public NoHardwareAcceleration()
			{
				Fuse.UpdateManager.AddOnceAction(DoReject);
			}

			void DoReject()
			{
				Reject(new Uno.Exception("Video not supported on this device due to lack of hardware acceleration"));
			}

			public override void Cancel(bool shutdownGracefully = false) { }
		}

		public static Future<IVideoPlayer> Load(FileSource fileSource)
		{
			if (fileSource is BundleFileSource)
			{
				return Load(((BundleFileSource)fileSource).BundleFile);
			}
			else
			{
				return Load(VideoDiskCache.GetFilePath(fileSource));
			}
		}

		public static Future<IVideoPlayer> Load(string url)
		{
			if (MediaPlayer.IsHardwareAccelerated())
			{
				return new VideoPromise(url);
			}
			else
			{
				return new NoHardwareAcceleration();
			}
		}

		static Future<IVideoPlayer> Load(BundleFile file)
		{
			if (MediaPlayer.IsHardwareAccelerated())
			{
				return new VideoPromise(file);
			}
			else
			{
				return new NoHardwareAcceleration();
			}
		}

	}

	extern(Android) internal class MediaPlayer : IDisposable, IVideoPlayer
	{

		public VideoTexture VideoTexture
		{
			get { return _videoTexture; }
		}

		public event EventHandler Prepared;
		public event EventHandler Completion;
		public event EventHandler<string> Error;
		public event EventHandler<int> Buffering;

		public event EventHandler FrameAvailable;
		public event EventHandler<Exception> ErrorOccurred;

		public double Duration { get { return GetDuration(_handle) / 1000.0; } }
		public int2 Size { get { return int2(GetWidth(_handle), GetHeight(_handle)); } }
		public double Position
		{
			get { return GetCurrentPosition(_handle) / 1000.0; }
			set
			{
				if (GetDuration(_handle) >= 0)
					SeekTo(_handle, (int)(value * 1000));
			}
		}

		int _rotationDegrees = 0;
		public int RotationDegrees
		{
			get { return _rotationDegrees; }
		}

		float _volume = 1.0f;
		public float Volume
		{
			get { return _volume; }
			set
			{
				_volume = Uno.Math.Clamp(value, 0.0f, 1.0f);
				SetVolume(_handle, _volume, _volume);
			}
		}

		readonly Java.Object _handle;
		readonly Java.Object _surfaceTexture;
		readonly Java.Object _surface;

		readonly VideoTexture _videoTexture;

		string _dataSourcePath;

		public MediaPlayer()
		{
			var glHandle = GL.CreateTexture();
			_videoTexture = new VideoTexture(glHandle);
			_surfaceTexture = CreateSurfaceTexture((int)glHandle);
			_surface = CreateSurface(_surfaceTexture);
			_handle = CreateMediaPlayer(_surface);
			_dataSourcePath = null;

			Fuse.Platform.Lifecycle.EnteringBackground += OnEnteringBackground;
		}

		[Foreign(Language.Java)]
		static int GetOrientation(Java.Object handle, string dataSorucePath)
		@{
			/*
				Nasty code to check for rotation metadata on a video

				This code probes for orientation as the soruce might not have it.
			*/
			if (dataSorucePath != null)
			{
				try
				{
					android.media.MediaMetadataRetriever mmr = new android.media.MediaMetadataRetriever();
					mmr.setDataSource(dataSorucePath);
					String rotation = mmr.extractMetadata(android.media.MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION);
					if (rotation != null) {
						return java.lang.Integer.parseInt(rotation);
					}
				}
				catch(Exception e) { /* We do not care if this fails */ }

				try
				{
					android.content.res.AssetFileDescriptor afd = com.fuse.Activity.getRootActivity()
						.getAssets()
						.openFd(dataSorucePath);

					android.media.MediaMetadataRetriever mmr = new android.media.MediaMetadataRetriever();
					mmr.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());
					String rotation = mmr.extractMetadata(android.media.MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION);
					if (rotation != null) {
						return java.lang.Integer.parseInt(rotation);
					}
				}
				catch (Exception e) { /* We do not care if this fails */ }
			}

			if (android.os.Build.VERSION.SDK_INT < 19) // we need API level 19 to call MediaPlayer.TrackInfo.getFormat()
				return 0;

			android.media.MediaPlayer player = (android.media.MediaPlayer)handle;
			android.media.MediaPlayer.TrackInfo[] tracks = player.getTrackInfo();
			for (int i = 0; i < tracks.length; i++)
			{
				android.media.MediaPlayer.TrackInfo track = tracks[i];
				if (track.getTrackType() == android.media.MediaPlayer.TrackInfo.MEDIA_TRACK_TYPE_VIDEO)
				{
					android.media.MediaFormat format = track.getFormat();
					if (format != null)
					{
						if (format.getFeatureEnabled(android.media.MediaFormat.KEY_ROTATION))
						{
							return format.getInteger(android.media.MediaFormat.KEY_ROTATION);
						}
					}
				}
			}
			return 0;
		@}

		[Foreign(Language.Java)]
		[Require("Source.Include", "Uno/Graphics/GLHelper.h")]
		public static bool IsHardwareAccelerated()
		@{
			android.view.Window window = com.fuse.Activity.getRootActivity().getWindow();

			if (window != null) {
				if ((window.getAttributes().flags & android.view.WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED) != 0) {
					return true;
				}
			}

			try
			{
				android.content.pm.ActivityInfo info = com.fuse.Activity.getRootActivity().getPackageManager().getActivityInfo(com.fuse.Activity.getRootActivity().getComponentName(), 0);
				if ((info.flags & android.content.pm.ActivityInfo.FLAG_HARDWARE_ACCELERATED) != 0) {
					return true;
				}
			}
			catch (android.content.pm.PackageManager.NameNotFoundException e)
			{

			}

			return false;
		@}

		[Foreign(Language.Java)]
		Java.Object CreateMediaPlayer(Java.Object surfaceHandle)
		@{
			android.media.MediaPlayer player = new android.media.MediaPlayer();
			player.setAudioStreamType(android.media.AudioManager.STREAM_MUSIC);
			player.setOnPreparedListener(new android.media.MediaPlayer.OnPreparedListener() {
				public void onPrepared(android.media.MediaPlayer mp) {
					@{Fuse.Controls.VideoImpl.Android.MediaPlayer:Of(_this).OnPrepared():Call()};
				}
			});
			player.setOnCompletionListener(new android.media.MediaPlayer.OnCompletionListener() {
				public void onCompletion(android.media.MediaPlayer mp) {
					@{Fuse.Controls.VideoImpl.Android.MediaPlayer:Of(_this).OnCompletion():Call()};
				}
			});
			player.setOnErrorListener(new android.media.MediaPlayer.OnErrorListener() {
				public boolean onError(android.media.MediaPlayer mp, int what, int extra) {
					@{Fuse.Controls.VideoImpl.Android.MediaPlayer:Of(_this).OnError(int,int):Call(what, extra)};
					return false;
				}
			});
			player.setOnBufferingUpdateListener(new android.media.MediaPlayer.OnBufferingUpdateListener() {
				public void onBufferingUpdate(android.media.MediaPlayer mp, int percent) {
					@{Fuse.Controls.VideoImpl.Android.MediaPlayer:Of(_this).OnBuffer(int):Call(percent)};
				}
			});
			player.setSurface(((android.view.Surface)surfaceHandle));
			return player;
		@}

		[Foreign(Language.Java)]
		Java.Object CreateSurfaceTexture(int glHandle)
		@{
			android.graphics.SurfaceTexture surfaceTexture = new android.graphics.SurfaceTexture(glHandle);
			surfaceTexture.setOnFrameAvailableListener(new android.graphics.SurfaceTexture.OnFrameAvailableListener() {
				public void onFrameAvailable(android.graphics.SurfaceTexture surfaceTexture) {
					@{Fuse.Controls.VideoImpl.Android.MediaPlayer:Of(_this).OnFrameAvailable():Call()};
				}
			});
			return surfaceTexture;
		@}

		[Foreign(Language.Java)]
		Java.Object CreateSurface(Java.Object surfaceTexture)
		@{
			return new android.view.Surface(((android.graphics.SurfaceTexture)surfaceTexture));
		@}

		void UpdateTexture() { UpdateTexture(_surfaceTexture); }
		[Foreign(Language.Java)]
		static void UpdateTexture(Java.Object surfaceTextureHandle)
		@{
			((android.graphics.SurfaceTexture)surfaceTextureHandle).updateTexImage();
		@}

		bool _frameAvailable = false;
		void OnFrameAvailable()
		{
			_frameAvailable = true;
		}

		public void Update()
		{
			if (_frameAvailable)
			{
				extern "GLHelper::SwapBackToBackgroundSurface()";

				UpdateTexture();
				_frameAvailable = false;
				if (FrameAvailable != null)
					FrameAvailable(this, EventArgs.Empty);
			}
		}

		void OnEnteringBackground(Fuse.Platform.ApplicationState args)
		{
			Pause();
		}

		public void LoadAsync(BundleFile file)
		{
			_dataSourcePath = file.BundlePath;
			LoadAsyncAsset(_handle, file.BundlePath);
		}

		public void LoadAsync(string url)
		{
			_dataSourcePath = url;
			LoadAsyncUrl(_handle, url);
		}

		[Foreign(Language.Java)]
		void LoadAsyncUrl(Java.Object handle, string url)
		@{
			android.media.MediaPlayer player = (android.media.MediaPlayer)handle;
			player.reset();
			try
			{
				player.setDataSource(url);
			}
			catch(Exception e)
			{
				android.util.Log.e("Fuse.Video", e.getMessage());
				@{Fuse.Controls.VideoImpl.Android.MediaPlayer:Of(_this).OnErrorOccurred(string):Call(e.getMessage())};
			}
			player.prepareAsync();
		@}

		// (ﾉಥДಥ)ﾉ︵┻━┻･/
		[Foreign(Language.Java)]
		void LoadAsyncAsset(Java.Object handle, string assetName)
		@{
			android.media.MediaPlayer player = (android.media.MediaPlayer)handle;
			android.content.res.AssetFileDescriptor afd = null;
			try
			{
				afd = com.fuse.Activity.getRootActivity()
					.getAssets()
					.openFd(assetName);
			}
			catch (Exception e)
			{
				// checked exceptions suck (ﾉಥДಥ)ﾉ︵┻━┻･/
				android.util.Log.e("Fuse.Video", e.getMessage());
				@{Fuse.Controls.VideoImpl.Android.MediaPlayer:Of(_this).OnErrorOccurred(string):Call(e.getMessage())};
			}

			/// AAAAAAAAAA JAVA
			if (afd == null)
			{
				// (ﾉಥДಥ)ﾉ︵┻━┻･/
				return;
			}

			player.reset();
			try
			{
				// (ﾉಥДಥ)ﾉ︵┻━┻･/
				player.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());
			}
			// (ﾉಥДಥ)ﾉ︵┻━┻･/
			catch (Exception e)
			{
				// (ﾉಥДಥ)ﾉ︵┻━┻･/
				android.util.Log.e("Fuse.Video", e.getMessage());
				@{Fuse.Controls.VideoImpl.Android.MediaPlayer:Of(_this).OnErrorOccurred(string):Call(e.getMessage())};
			}

			player.prepareAsync();
		@}


		public void Play() { Play(_handle); }
		public void Pause()
		{
			if (GetDuration(_handle) >= 0)
				Pause(_handle);
		}

		[Foreign(Language.Java)]
		static void Play(Java.Object handle)
		@{
			android.media.MediaPlayer player = (android.media.MediaPlayer)handle;
			if (!player.isPlaying())
			{
				android.media.AudioManager am = (android.media.AudioManager)com.fuse.Activity.getRootActivity().getSystemService(android.content.Context.AUDIO_SERVICE);
				am.requestAudioFocus(null, android.media.AudioManager.STREAM_MUSIC, android.media.AudioManager.AUDIOFOCUS_GAIN);
				player.start();
			}
		@}

		[Foreign(Language.Java)]
		static void Pause(Java.Object handle)
		@{
			android.media.MediaPlayer player = (android.media.MediaPlayer)handle;
			if (player.isPlaying())
			{
				android.media.AudioManager am = (android.media.AudioManager)com.fuse.Activity.getRootActivity().getSystemService(android.content.Context.AUDIO_SERVICE);
				am.abandonAudioFocus(null);
				player.pause();
			}
		@}

		bool _isDisposed = false;
		public void Dispose()
		{
			if (!_isDisposed)
			{
				_isDisposed = true;
				Fuse.Platform.Lifecycle.EnteringBackground -= OnEnteringBackground;
				Dispose(_handle, _surface, _surfaceTexture);
				_videoTexture.Dispose();
			}
		}

		[Foreign(Language.Java)]
		static void Dispose(Java.Object mediaplayerHandle, Java.Object surfaceHandle, Java.Object surfaceTextureHandle)
		@{
			android.media.MediaPlayer player = (android.media.MediaPlayer)mediaplayerHandle;
			player.reset();
			player.release();

			android.view.Surface surface = (android.view.Surface)surfaceHandle;
			surface.release();

			android.graphics.SurfaceTexture surfaceTexture = (android.graphics.SurfaceTexture)surfaceTextureHandle;
			surfaceTexture.release();
		@}

		void OnPrepared()
		{
			_rotationDegrees = GetOrientation(_handle, _dataSourcePath);
			if (Prepared != null)
				Prepared(this, EventArgs.Empty);
		}

		void OnCompletion()
		{
			if (Completion != null)
				Completion(this, EventArgs.Empty);
		}

		void OnError(int what, int extra)
		{
			var msg = "what: " + what + " extra: " + extra;
			if (Error != null)
				Error(this, msg);

			OnErrorOccurred(msg);
		}

		void OnErrorOccurred(string msg)
		{
			if (ErrorOccurred != null)
				ErrorOccurred(this, new Exception(msg));
		}

		void OnBuffer(int percent)
		{
			if (Buffering != null)
				Buffering(this, percent);
		}

		[Foreign(Language.Java)]
		static int GetCurrentPosition(Java.Object handle)
		@{
			return ((android.media.MediaPlayer)handle).getCurrentPosition();
		@}

		[Foreign(Language.Java)]
		static void SeekTo(Java.Object handle, int position)
		@{
			((android.media.MediaPlayer)handle).seekTo(position);
		@}

		[Foreign(Language.Java)]
		static int GetWidth(Java.Object handle)
		@{
			return ((android.media.MediaPlayer)handle).getVideoWidth();
		@}

		[Foreign(Language.Java)]
		static int GetHeight(Java.Object handle)
		@{
			return ((android.media.MediaPlayer)handle).getVideoHeight();
		@}

		[Foreign(Language.Java)]
		static void SetVolume(Java.Object handle, float left, float right)
		@{
			((android.media.MediaPlayer)handle).setVolume(left, right);
		@}

		[Foreign(Language.Java)]
		static int GetDuration(Java.Object handle)
		@{
			return ((android.media.MediaPlayer)handle).getDuration();
		@}

	}
}
