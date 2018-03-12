using System;
using Fuse.Video.CILInterface;

namespace Fuse.Video.Mono
{
	public class MonoImpl : CILInterface.IVideo
	{
		static IGL _gl;

		readonly VideoHandle _handle;

		MonoImpl(string uri, Action loaded, Action<string> error)
		{
			_handle = VideoImpl.Create(_gl, uri, loaded, error);
		}

		public static void SetOpenGL(IGL gl)
		{
			_gl = gl;
		}

		public static MonoImpl FromFile(string fileName, Action loaded, Action<string> error)
		{
			return new MonoImpl("file://" + fileName, loaded, error);
		}

		public static MonoImpl FromUrl(string url, Action loaded, Action<string> error)
		{
			return new MonoImpl(url, loaded, error);
		}

		public double Duration
		{
			get { return VideoImpl.GetDuration(_handle); }
		}

		public bool IsFrameAvaiable
		{
			get { return VideoImpl.HasNewPixelBuffer(_handle); }
		}

		public int Height
		{
			get { return VideoImpl.GetHeight(_handle); }
		}

		public double Position
		{
			get { return VideoImpl.GetPosition(_handle); }
			set { VideoImpl.SetPosition(_handle, value); }
		}

		public float Volume
		{
			get { return VideoImpl.GetVolume(_handle); }
			set { VideoImpl.SetVolume(_handle, value); }
		}

		public int Width
		{
			get { return VideoImpl.GetWidth(_handle); }
		}

		public int RotationDegrees
		{
			get { return VideoImpl.GetRotation(_handle); }
		}

		public void Dispose()
		{
			VideoImpl.Dispose(_handle);
		}

		public void Pause()
		{
			VideoImpl.Pause(_handle);
		}

		public void Play()
		{
			VideoImpl.Play(_handle);
		}

		public void Stop()
		{
			VideoImpl.Stop(_handle);
		}

		public void UpdateTexture(System.Int32 textureHandle)
		{
			VideoImpl.UpdateTexture(_handle, textureHandle);
		}

		public void CopyPixels(byte[] destination)
		{

		}
	}
}
