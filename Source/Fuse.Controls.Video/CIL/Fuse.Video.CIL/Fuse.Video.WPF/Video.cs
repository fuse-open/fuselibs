using System;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using Fuse.Video.CILInterface;
using System.Runtime.InteropServices;
using System.Windows;
using PixelFormat = Fuse.Video.CILInterface.PixelFormat;

namespace Fuse.Video.WPF
{

	public static class VideoImpl
	{
		static IGL _gl;

		public static void SetOpenGL(IGL gl)
		{
			_gl = gl;
		}

		public static IVideo FromUrl(string url, Action loaded, Action<string> error)
		{
			var video = new Video(_gl);
			video.LoadUrl(url, loaded, error);
			return video;
		}

		public static IVideo FromFile(string fileName, Action loaded, Action<string> error)
		{
			var video = new Video(_gl);
			video.LoadFile(fileName, loaded, error);
			return video;
		}
	}

	class Video : CILInterface.IVideo, IDisposable
	{
		readonly IGL _gl;
		readonly MediaPlayer _mediaPlayer;
		readonly DrawingVisual _drawingVisual;

		public Video(IGL gl)
		{
			_gl = gl;
			_mediaPlayer = new MediaPlayer();
			_mediaPlayer.MediaOpened += OnMediaOpened;
			_mediaPlayer.MediaFailed += OnMediaFailed;
			_drawingVisual = new DrawingVisual();
		}

		void OnMediaFailed(object sender, ExceptionEventArgs e)
		{
			
		}

		void OnMediaOpened(object sender, EventArgs e)
		{
			
		}

		public void LoadUrl(string url, Action loaded, Action<string> error)
		{
			_mediaPlayer.MediaOpened += (s, e) => { if (!_isDisposed) loaded(); };
			_mediaPlayer.MediaFailed += (s, e) => { if (!_isDisposed) error(e.ErrorException.Message); };
			try
			{
				_mediaPlayer.Open(new Uri(url));
			}
			catch (Exception e)
			{
				error(e.Message);
			}
		}

		public void LoadFile(string filePath, Action loaded, Action<string> error)
		{
			LoadUrl(filePath, loaded, error);
		}

		public void Play()
		{
			_mediaPlayer.Play();
		}

		public void Stop()
		{
			_mediaPlayer.Stop();
		}

		public void Pause()
		{
			if (_mediaPlayer.CanPause)
				_mediaPlayer.Pause();
		}

		public int Width
		{
			get { return _mediaPlayer.NaturalVideoWidth; }
		}

		public int Height
		{
			get { return _mediaPlayer.NaturalVideoHeight; }
		}

		public double Duration
		{
			get { return _mediaPlayer.NaturalDuration.TimeSpan.TotalSeconds; }
		}

		public double Position
		{
			get { return _mediaPlayer.Position.TotalSeconds; }
			set { _mediaPlayer.Position = TimeSpan.FromSeconds(value); }
		}

		public float Volume
		{
			get { return (float)_mediaPlayer.Volume; }
			set { _mediaPlayer.Volume = (double)value; }
		}

		TimeSpan _prevPosition = TimeSpan.Zero;
		public bool IsFrameAvaiable
		{
			get
			{
				if (!(_prevPosition == _mediaPlayer.Position))
				{
					_prevPosition = _mediaPlayer.Position;	
					return true;
				}
				return false;
			}
		}

		public int RotationDegrees
		{
			get { return 0; }
		}

		bool _isDisposed;
		public void Dispose()
		{
			_isDisposed = true;
			_mediaPlayer.MediaOpened -= OnMediaOpened;
			_mediaPlayer.MediaFailed -= OnMediaFailed;
			_mediaPlayer.Close();
			_renderTargetBitmap = null;
			_pixelBuffer = null;
		}


		byte[] _pixelBuffer = null;
		RenderTargetBitmap _renderTargetBitmap = null;

		int _widthCache = -1;
		int _heightCache = -1;
		int _lastTextureHandle = -1;

		public void UpdateTexture(int textureHandle)
		{
			if (Width > 0 && Height > 0)
			{
				using (var dc = _drawingVisual.RenderOpen())
					dc.DrawVideo(_mediaPlayer, new System.Windows.Rect(0, 0, Width, Height));

				if (_renderTargetBitmap == null || (_widthCache != Width || _heightCache != Height))
					_renderTargetBitmap = new RenderTargetBitmap(Width, Height, 100, 100, PixelFormats.Pbgra32);

				_renderTargetBitmap.Render(_drawingVisual);

				var stride = _renderTargetBitmap.PixelWidth * 4;
				var size = _renderTargetBitmap.PixelHeight * stride;
				
				if (_pixelBuffer == null || _pixelBuffer.Length != size)
					_pixelBuffer = new byte[size];
				
				var pinnedBuffer = GCHandle.Alloc(_pixelBuffer, GCHandleType.Pinned);
				
				try
				{
					var pixelBufferPtr = pinnedBuffer.AddrOfPinnedObject();
					
					_renderTargetBitmap.CopyPixels(Int32Rect.Empty, pixelBufferPtr, size, stride);


					_gl.BindTexture((int)TextureTarget.Texture2D, (int)textureHandle);

					if (_widthCache != Width || _heightCache != Height || _lastTextureHandle != textureHandle)
					{
						_widthCache = Width;
						_heightCache = Height;
						_lastTextureHandle = textureHandle;

						_gl.TexImage2D(
							(int)TextureTarget.Texture2D,
							0,
							(int)PixelFormat.Bgra,
							Width,
							Height,
							0,
							(int)PixelFormat.Bgra,
							(int)PixelType.UnsignedByte,
							pixelBufferPtr);
					}
					else
					{
						_gl.TexSubImage2D(
							(int)TextureTarget.Texture2D,
							0,
							0,
							0,
							Width,
							Height,
							(int)PixelFormat.Bgra,
							(int)PixelType.UnsignedByte,
							pixelBufferPtr);
					}
				}
				finally
				{
					pinnedBuffer.Free();
				}
			}
		}

		public void CopyPixels(byte[] destination)
		{
			throw new NotImplementedException();
		}
	}
}
