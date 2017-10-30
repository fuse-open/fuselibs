using Uno;
using Uno.UX;
using Uno.Graphics;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Uno.Threading;

using Fuse;

namespace Fuse.Controls.VideoImpl
{
	internal static class VideoLoader
	{
		public static Future<IVideoPlayer> Load(string url)
		{
			if defined(iOS) return Fuse.Controls.VideoImpl.iOS.VideoLoader.Load(url);
			else if defined(Android) return Fuse.Controls.VideoImpl.Android.VideoLoader.Load(url);
			else if defined(DOTNET) return Fuse.Controls.VideoImpl.CIL.VideoLoader.Load(url);

			throw new Exception("Video not supported on this platform");
		}

		public static Future<IVideoPlayer> Load(FileSource file)
		{
			if defined(iOS) return Fuse.Controls.VideoImpl.iOS.VideoLoader.Load(file);
			else if defined(Android) return Fuse.Controls.VideoImpl.Android.VideoLoader.Load(file);
			else if defined(DOTNET) return Fuse.Controls.VideoImpl.CIL.VideoLoader.Load(file);

			throw new Exception("Video not supported on this platform");
		}
	}

}