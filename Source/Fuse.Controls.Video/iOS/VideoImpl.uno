using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.Threading;
using Uno.Graphics;

using OpenGL;

namespace Fuse.Controls.VideoImpl.iOS
{

	extern(iOS) internal class VideoPlayer : IVideoPlayer
	{
		VideoTexture _currentTexture;
		public VideoTexture VideoTexture
		{
			get { return _currentTexture; }
		}

		GLTextureHandle TextureHandle
		{
			get { return VideoPlayerImpl.UpdateTexture(_handle); }
		}

		public int2 Size
		{
			get { return int2(VideoPlayerImpl.GetWidth(_handle), VideoPlayerImpl.GetHeight(_handle)); }
		}

		public int RotationDegrees
		{
			get { return VideoPlayerImpl.GetRotation(_handle); }
		}

		public float Volume
		{
			get { return VideoPlayerImpl.GetVolume(_handle); }
			set { VideoPlayerImpl.SetVolume(_handle, value); }
		}

		public double Duration
		{
			get { return VideoPlayerImpl.GetDuration(_handle); }
		}

		public double Position
		{
			get { return VideoPlayerImpl.GetPosition(_handle); }
			set { VideoPlayerImpl.SetPosition(_handle, value); }
		}

		public void Play()
		{
			VideoPlayerImpl.Play(_handle);
		}

		public void Pause()
		{
			VideoPlayerImpl.Pause(_handle);
		}

		GLTextureHandle _currentTextureHandle;
		public void Update()
		{
			var textureHandle = TextureHandle;
			if (textureHandle != _currentTextureHandle)
			{
				_currentTextureHandle = textureHandle;
				_currentTexture = new VideoTexture(_currentTextureHandle);
				OnFrameAvailable();
			}
		}

		public event EventHandler FrameAvailable;
		public event EventHandler<Exception> ErrorOccurred;

		IntPtr _handle = IntPtr.Zero;

		public VideoPlayer(string uri, Action onLoaded, Action onLoadError)
		{
			_handle = VideoPlayerImpl.AllocateVideoState();
			VideoPlayerImpl.Initialize(_handle, uri, onLoaded, onLoadError);
			VideoPlayerImpl.SetErrorHandler(_handle, PlayerErrorHandler);
		}

		void OnFrameAvailable()
		{
			var handler = FrameAvailable;
			if (handler != null)
				handler(this, EventArgs.Empty);
		}

		void PlayerErrorHandler()
		{
			var handler = ErrorOccurred;
			if (handler != null)
				handler(this, new Exception("Unknown playback error"));
		}

		public void Dispose()
		{
			if (_handle != IntPtr.Zero)
			{
				VideoPlayerImpl.FreeVideoState(_handle);
				_handle = IntPtr.Zero;
			}
		}

	}

	[Require("Source.Include", "uObjC.Foreign.h")]
	[Require("Source.Include", "iOS/VideoImpl.h")]
	[Require("Xcode.Framework", "CoreVideo")]
	[Require("Xcode.Framework", "CoreMedia")]
	[Set("FileExtension", "mm")]
	extern(IOS) static class VideoPlayerImpl
	{
		public static Uno.IntPtr AllocateVideoState()
		@{
			return ::FuseVideoImpl::allocateVideoState();
		@}

		public static void FreeVideoState(Uno.IntPtr videoState)
		@{
			::FuseVideoImpl::freeVideoState($0);
		@}

		public static void Initialize(Uno.IntPtr videoState, string uri, Uno.Action loadedCallback, Uno.Action errorCallback)
		@{
			::FuseVideoImpl::initialize($0, uObjC::NativeString($1), $2, $3);
		@}

		public static int GetRotation(Uno.IntPtr videoState)
		@{
			return ::FuseVideoImpl::getRotation($0);
		@}

		public static double GetDuration(Uno.IntPtr videoState)
		@{
			return ::FuseVideoImpl::getDuration($0);
		@}

		public static double GetPosition(Uno.IntPtr videoState)
		@{
			return ::FuseVideoImpl::getPosition($0);
		@}

		public static void SetPosition(Uno.IntPtr videoState, double position)
		@{
			return ::FuseVideoImpl::setPosition($0, $1);
		@}

		public static float GetVolume(Uno.IntPtr videoState)
		@{
			return ::FuseVideoImpl::getVolume($0);
		@}

		public static void SetVolume(Uno.IntPtr videoState, float volume)
		@{
			::FuseVideoImpl::setVolume($0, $1);
		@}

		public static int GetWidth(Uno.IntPtr videoState)
		@{
			return ::FuseVideoImpl::getWidth($0);
		@}

		public static int GetHeight(Uno.IntPtr videoState)
		@{
			return ::FuseVideoImpl::getHeight($0);
		@}

		public static void Play(Uno.IntPtr videoState)
		@{
			::FuseVideoImpl::play($0);
		@}

		public static void Pause(Uno.IntPtr videoState)
		@{
			::FuseVideoImpl::pause($0);
		@}

		public static GLTextureHandle UpdateTexture(Uno.IntPtr videoState)
		@{
			return ::FuseVideoImpl::updateTexture($0);
		@}

		public static void SetErrorHandler(Uno.IntPtr videoState, Uno.Action errorHandler)
		@{
			::FuseVideoImpl::setErrorHandler($0, $1);
		@}
	}
}
