using System;

namespace Fuse.Video.Graphics.CIL
{
	using System.IO;
	using CILInterface;

	public class VideoHandle
	{
		public IVideo Video { get; private set; }

		public string PathToTempFileOnDisk { get; private set; }

		public VideoHandle(IVideo video) : this(video, null) { }

		public VideoHandle(IVideo video, string pathToTempFileOnDisk)
		{
			Video = video;
			PathToTempFileOnDisk = pathToTempFileOnDisk;
		}
	}

	public static class VideoImpl
	{

		/// Jeeezzz, clean up this mess
		public static VideoHandle CreateFromBytes(string name, byte[] data, Action loaded, Action<string> error)
		{
			var dir = Path.GetTempPath ();
			var path = dir + Path.DirectorySeparatorChar + name;
			File.WriteAllBytes(path, data);

			if (Outracks.Diagnostics.Platform.OperatingSystem == Outracks.Diagnostics.OS.Mac)
				return CreateFromUrl ("file://" + path, loaded, error);
			
			var handle = CreateFromFile(path, loaded, error);

			return new VideoHandle(handle.Video, path);
		}

		public static VideoHandle CreateFromFile(string fileName, Action loaded, Action<string> error)
		{
			switch (Outracks.Diagnostics.Platform.OperatingSystem)
			{
				case Outracks.Diagnostics.OS.Windows: return new VideoHandle(WPF.VideoImpl.FromFile(fileName, loaded, error));
				case Outracks.Diagnostics.OS.Mac: return new VideoHandle(Mono.MonoImpl.FromFile(fileName, loaded, error));
				case Outracks.Diagnostics.OS.X11:
				case Outracks.Diagnostics.OS.Other:
					throw new NotSupportedException("Platform not supported");
			}
			throw new NotSupportedException("Platform not supported");
		}

		public static VideoHandle CreateFromUrl(string url, Action loaded, Action<string> error)
		{
			switch (Outracks.Diagnostics.Platform.OperatingSystem)
			{
				case Outracks.Diagnostics.OS.Windows: return new VideoHandle(WPF.VideoImpl.FromUrl(url, loaded, error));
				case Outracks.Diagnostics.OS.Mac: return new VideoHandle(Mono.MonoImpl.FromUrl(url, loaded, error));
				case Outracks.Diagnostics.OS.X11:
				case Outracks.Diagnostics.OS.Other:
					throw new NotSupportedException("Platform not supported");
			}
			throw new NotSupportedException("Platform not supported");
		}

		public static double GetPosition(VideoHandle handle)
		{
			return handle.Video.Position;
		}

		public static void SetPosition(VideoHandle handle, double position)
		{
			handle.Video.Position = position;
		}

		public static float GetVolume(VideoHandle handle)
		{
			return handle.Video.Volume;
		}

		public static void SetVolume(VideoHandle handle, float volume)
		{
			handle.Video.Volume = volume;
		}

		public static double GetDuration(VideoHandle handle)
		{
			return handle.Video.Duration;
		}
		
		public static int GetWidth(VideoHandle handle)
		{
			return handle.Video.Width;
		}
		
		public static int GetHeight(VideoHandle handle)
		{
			return handle.Video.Height;
		}

		public static bool IsFrameAvailable(VideoHandle handle)
		{
			return handle.Video.IsFrameAvaiable;
		}
		
		public static void Play(VideoHandle handle)
		{
			handle.Video.Play();
		}

		public static int GetRotationDegrees(VideoHandle handle)
		{
			return handle.Video.RotationDegrees;
		}
		
		public static void Pause(VideoHandle handle)
		{
			handle.Video.Pause();
		}

		public static void UpdateTexture(VideoHandle handle, System.Int32 textureHandle)
		{
			handle.Video.UpdateTexture(textureHandle);
		}

		public static void Dispose(VideoHandle handle)
		{
			handle.Video.Dispose();
			if (handle.PathToTempFileOnDisk != null)
				if (File.Exists(handle.PathToTempFileOnDisk))
					File.Delete(handle.PathToTempFileOnDisk);
		}

		public static void CopyPixels(VideoHandle handle, byte[] destination)
		{
			handle.Video.CopyPixels(destination);	
		}

	}
}
