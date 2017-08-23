using Uno;
using Uno.UX;
using Uno.Graphics;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using OpenGL;
using Uno.Threading;

namespace Fuse.Controls.VideoImpl.CIL
{

	extern(CIL) internal class VideoLoader
	{
		class VideoPromise : Promise<IVideoPlayer>
		{
			Fuse.Video.Graphics.CIL.VideoHandle _handle;
			public VideoPromise(string url)
			{
				_handle = Fuse.Video.Graphics.CIL.VideoImpl.CreateFromUrl(url, OnLoaded, OnError);
				UpdateManager.AddAction(PollStatus);
			}

			public VideoPromise(string name, byte[] data)
			{
				_handle = Fuse.Video.Graphics.CIL.VideoImpl.CreateFromBytes(name, data, OnLoaded, OnError);
				UpdateManager.AddAction(PollStatus);
			}

			public override void Cancel(bool shutdownGracefully = false)
			{
				_isCancelled = true;
			}

			bool _isCancelled = false;
			bool _loaded = false;
			bool _failed = false;
			string _errorMessage;
			void OnLoaded()
			{
				_loaded = true;
			}

			void OnError(string errorMessage)
			{
				_errorMessage = errorMessage;
				_failed = true;
			}

			void PollStatus()
			{
				if (_isCancelled && (_loaded || _failed))
				{
					Fuse.Video.Graphics.CIL.VideoImpl.Dispose(_handle);
					Done();
					return;
				}

				if (_loaded) Resolve(new VideoPlayer(_handle));
				if (_failed) Reject(new Exception(_errorMessage));
				if (_loaded || _failed) Done();
			}

			void Done()
			{
				UpdateManager.RemoveAction(PollStatus);
			}

			public override void Dispose()
			{
				base.Dispose();
				_isCancelled = true;
			}

		}

		public static Future<IVideoPlayer> Load(string url)
		{
			return new VideoPromise(url);
		}

		static int _tempFileCount = 0;
		public static Future<IVideoPlayer> Load(FileSource fileSource)
		{
			var extension = VideoDiskCache.GetFileExtension(fileSource.Name);
			var name = "tempVideo" + _tempFileCount.ToString() + "." + extension;
			_tempFileCount++;
			var data = fileSource.ReadAllBytes();
			return new VideoPromise(name, data);
		}

	}

	extern(CIL) internal class VideoPlayer : IVideoPlayer
	{
		VideoTexture _videoTexture;
		public VideoTexture VideoTexture
		{
			get { return _videoTexture; }
		}

		public int2 Size
		{
			get { return int2(Fuse.Video.Graphics.CIL.VideoImpl.GetWidth(_handle), Fuse.Video.Graphics.CIL.VideoImpl.GetHeight(_handle)); }
		}

		public int RotationDegrees
		{
			get { return Fuse.Video.Graphics.CIL.VideoImpl.GetRotationDegrees(_handle); }
		}

		public float Volume
		{
			get { return Fuse.Video.Graphics.CIL.VideoImpl.GetVolume(_handle); }
			set { Fuse.Video.Graphics.CIL.VideoImpl.SetVolume(_handle, value); }
		}

		public double Duration
		{
			get { return Fuse.Video.Graphics.CIL.VideoImpl.GetDuration(_handle); }
		}

		public double Position
		{
			get { return Fuse.Video.Graphics.CIL.VideoImpl.GetPosition(_handle); }
			set { Fuse.Video.Graphics.CIL.VideoImpl.SetPosition(_handle, value); }
		}

		readonly Fuse.Video.Graphics.CIL.VideoHandle _handle;

		public VideoPlayer(Fuse.Video.Graphics.CIL.VideoHandle handle)
		{
			_handle = handle;
		}

		public void Play()
		{
			Fuse.Video.Graphics.CIL.VideoImpl.Play(_handle);
		}

		public void Pause()
		{
			Fuse.Video.Graphics.CIL.VideoImpl.Pause(_handle);
		}

		texture2D _texture;
		int2 _sizeCache = int2(-1, -1);

		public void Update()
		{
			if (Size == int2(0,0))
				return;

			if (_sizeCache != Size)
			{
				_sizeCache = Size;
				if (_texture != null)
				{
					_texture.Dispose();
					_texture = null;
				}
				_texture = new texture2D(Size, Format.RGBA8888, false);
			}

			if (Fuse.Video.Graphics.CIL.VideoImpl.IsFrameAvailable(_handle))
			{
				GL.PixelStore(GLPixelStoreParameter.UnpackAlignment, 1);
				Fuse.Video.Graphics.CIL.VideoImpl.UpdateTexture(_handle, _texture.GLTextureHandle);
				_videoTexture = new VideoTexture(_texture.GLTextureHandle);
				OnFrameAvailable();
			}
		}

		public void Dispose()
		{
			if (_texture != null)
				_texture.Dispose();

			Fuse.Video.Graphics.CIL.VideoImpl.Dispose(_handle);
		}

		public event EventHandler FrameAvailable;
		public event EventHandler<Exception> ErrorOccurred;

		void OnFrameAvailable()
		{
			var handler = FrameAvailable;
			if (handler != null)
				handler(this, EventArgs.Empty);
		}

	}
}

namespace Fuse.Video.Graphics.CIL
{

	[TargetSpecificImplementation, DotNetType]
	extern(CIL) internal class VideoHandle { }

	[TargetSpecificImplementation, DotNetType]
	extern(CIL) internal static class VideoImpl
	{

		[TargetSpecificImplementation]
		public static extern VideoHandle CreateFromBytes(string name, byte[] data, Action loaded, Action<string> error);

		[TargetSpecificImplementation]
		public static extern VideoHandle CreateFromFile(string fileName, Action loaded, Action<string> error);

		[TargetSpecificImplementation]
		public static extern VideoHandle CreateFromUrl(string url, Action loaded, Action<string> error);

		[TargetSpecificImplementation]
		public static extern int GetRotationDegrees(VideoHandle handle);

		[TargetSpecificImplementation]
		public static extern double GetPosition(VideoHandle handle);

		[TargetSpecificImplementation]
		public static extern void SetPosition(VideoHandle handle, double position);

		[TargetSpecificImplementation]
		public static extern float GetVolume(VideoHandle handle);

		[TargetSpecificImplementation]
		public static extern void SetVolume(VideoHandle handle, float volume);

		[TargetSpecificImplementation]
		public static extern double GetDuration(VideoHandle handle);

		[TargetSpecificImplementation]
		public static extern int GetWidth(VideoHandle handle);

		[TargetSpecificImplementation]
		public static extern int GetHeight(VideoHandle handle);

		[TargetSpecificImplementation]
		public static extern bool IsFrameAvailable(VideoHandle handle);

		[TargetSpecificImplementation]
		public static extern int GetTextureName(VideoHandle handle);

		[TargetSpecificImplementation]
		public static extern void Play(VideoHandle handle);

		[TargetSpecificImplementation]
		public static extern void Pause(VideoHandle handle);

		[TargetSpecificImplementation]
		public static extern void UpdateTexture(VideoHandle handle, GLTextureHandle textureHandle);

		[TargetSpecificImplementation]
		public static extern void Dispose(VideoHandle handle);

	}

}
