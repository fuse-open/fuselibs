using Uno;
using Uno.UX;
using Uno.Graphics;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using OpenGL;

using Fuse;
using Fuse.Triggers;
using Uno.Threading;

namespace Fuse.Controls.VideoImpl
{

	internal interface IVideoService : IDisposable
	{
		void Play();
		void Pause();

		float Volume { set; }

		double Position { get; set; }
		double Duration { get;  }

		int2 Size { get; }
		int RotationDegrees { get; }

		bool IsLooping { set; }
		bool AutoPlay { set; }
		bool IsValid { get; }

		VideoTexture VideoTexture { get; }

		void Load(string url);
		void Load(FileSource file);

		void Update();
		void Unload();
	}

	internal interface IVideoCallbacks
	{
		void OnFrameAvailable();
		void OnError(Exception e);
		void OnLoading();
		void OnReady();
		void OnCompleted();
	}

	internal class LoadingClosure : IDisposable
	{
		public static IDisposable Load(string url, Action<IVideoPlayer> loaded, Action<Exception> error)
		{
			return new LoadingClosure(VideoLoader.Load(url), loaded, error);
		}

		public static IDisposable Load(FileSource file, Action<IVideoPlayer> loaded, Action<Exception> error)
		{
			return new LoadingClosure(VideoLoader.Load(file), loaded, error);
		}

		readonly Future<IVideoPlayer> _loaderFuture;
		readonly Future<IVideoPlayer> _thenFuture;
		
		readonly Action<IVideoPlayer> _loaded;
		readonly Action<Exception> _error;

		LoadingClosure(
			Future<IVideoPlayer> loadedFuture,
			Action<IVideoPlayer> loaded,
			Action<Exception> error)
		{
			_loaded = loaded;
			_error = error;
			_loaderFuture = loadedFuture;
			_thenFuture = _loaderFuture.Then(_loaded, _error);
		}

		bool _isDisposed = false;
		void IDisposable.Dispose()
		{
			if (!_isDisposed)
			{
				_loaderFuture.Cancel();
				_loaderFuture.Dispose();
				_thenFuture.Dispose();
				_isDisposed = true;
			}
		}
	}

	internal class GraphicsVideoService : IVideoService
	{

		IVideoPlayer _player;
		IVideoPlayer Player
		{
			get { return _player ?? _empty; }
		}

		IDisposable _loading;

		readonly IVideoPlayer _empty = new EmptyVideo();
		IVideoCallbacks _callbacks;

		public GraphicsVideoService(IVideoCallbacks callbacks)
		{
			_callbacks = callbacks;
		}

		void IVideoService.Play()
		{
			if (IsCompleted)
			{
				Player.Position = 0.0;
			}

			Player.Play();
		}

		void IVideoService.Pause()
		{
			Player.Pause();
		}

		double _durationCache;
		double IVideoService.Duration
		{
			get { return _durationCache; }
		}

		int2 _sizeCache;
		int2 IVideoService.Size
		{
			get { return _sizeCache; }
		}

		VideoTexture IVideoService.VideoTexture
		{
			get { return Player.VideoTexture; }
		}

		float _volume = 1.0f;
		float IVideoService.Volume
		{
			set { Player.Volume = _volume = value; }
		}

		double IVideoService.Position
		{
			get { return Player.Position; }
			set { Player.Position = value; }
		}

		bool _isLooping = false;
		bool IVideoService.IsLooping { set { _isLooping = value; } }

		bool _autoPlay = false;
		bool IVideoService.AutoPlay { set { _autoPlay = value; } }

		bool IVideoService.IsValid { get { return _player != null; } }

		int _rotationCache;
		int IVideoService.RotationDegrees { get { return _rotationCache; } }

		void IVideoService.Load(string url)
		{
			try
			{
				Reset();
				_loading = LoadingClosure.Load(url, OnLoaded, OnLoadingError);
			}
			catch(Exception e)
			{
				_callbacks.OnError(e);
				return;	
			}
			_callbacks.OnLoading();
		}

		void IVideoService.Load(FileSource file)
		{
			try
			{
				Reset();
				_loading = LoadingClosure.Load(file, OnLoaded, OnLoadingError);
			}
			catch(Exception e)
			{
				_callbacks.OnError(e);
				return;
			}
			_callbacks.OnLoading();
		}

		bool IsCompleted
		{
			get
			{
				return Math.Abs(_durationCache - Player.Position) < CompletionTimeThreshold;
			}
		}

		static readonly float CompletionTimeThreshold = 0.05f;
		void IVideoService.Update()
		{
			if (_player != null)
			{
				_player.Update();
				if (IsCompleted)
				{
					if (_isLooping)
					{
						_player.Pause();
						_player.Position = 0.0;
						_player.Play();
					}
					else
					{
						_player.Pause();
						_callbacks.OnCompleted();
					}
				}
			}
		}

		void IVideoService.Unload()
		{
			Reset();
		}

		void IDisposable.Dispose()
		{
			Reset();
			_callbacks = null;
		}

		void Reset()
		{
			if (_player != null)
			{
				_player.FrameAvailable -= OnPlayerFrameAvailable;
				_player.ErrorOccurred -= OnPlayerError;
				_player.Dispose();
				_player = null;
			}
			if (_loading != null)
			{
				_loading.Dispose();
				_loading = null;
			}
		}

		void SetPlayer(IVideoPlayer player)
		{
			_player = player;
			_player.FrameAvailable += OnPlayerFrameAvailable;
			_player.ErrorOccurred += OnPlayerError;
			_player.Volume = _volume;
		}

		void OnLoaded(IVideoPlayer player)
		{
			_durationCache = player.Duration;
			_sizeCache = player.Size;
			_rotationCache = player.RotationDegrees;
			SetPlayer(player);
			_callbacks.OnReady();

			if (_autoPlay)
				Player.Play();
		}

		void OnLoadingError(Exception e)
		{
			_callbacks.OnError(e);
		}

		void OnPlayerError(object sender, Exception e)
		{
			Reset();
			_callbacks.OnError(e);
		}

		void OnPlayerFrameAvailable(object sender, EventArgs args)
		{
			_callbacks.OnFrameAvailable();
		}

	}

}
