using Uno;
using Uno.UX;
using Uno.IO;
using Fuse;
using Uno.Compiler.ExportTargetInterop;

using OpenGL;
using Uno.Graphics;
using Uno.Threading;

namespace Fuse.Controls.VideoImpl.iOS
{
	extern(iOS) internal class VideoLoader
	{

		class VideoPromise : Promise<IVideoPlayer>
		{
			IVideoPlayer _player;

			public VideoPromise(string url)
			{
				_player = new VideoPlayer(url, OnLoaded, OnLoadError);
			}

			void OnLoaded()
			{
				_readyToDispose = true;
				if (!_isCancelled)
					Resolve(_player);
			}

			void OnLoadError()
			{
				_readyToDispose = true;
				if (!_isCancelled)
					Reject(new Exception("Failed to load"));
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
					_player.Dispose();
					UpdateManager.RemoveAction(DoDispose);
				}
			}

			public override void Dispose()
			{
				base.Dispose();
				ScheduleDispose();
			}
		}

		public static Future<IVideoPlayer> Load(string url)
		{
			return new VideoPromise(url);
		}

		public static Future<IVideoPlayer> Load(FileSource fileSource)
		{
			if (fileSource is BundleFileSource)
				return Load(((BundleFileSource)fileSource).BundleFile);
			else
				return Load("file://" + VideoDiskCache.GetFilePath(fileSource));
		}

		static Future<IVideoPlayer> Load(BundleFile file)
		{
			return Load(GetBundleAbsolutePath("data/" + file.BundlePath));
		}

		[Foreign(Language.ObjC)]
		static string GetBundleAbsolutePath(string bundlePath)
		@{
			return [[[NSBundle bundleForClass:[StrongUnoObject class]] URLForResource:bundlePath withExtension:@""] absoluteString];
		@}
	}

}