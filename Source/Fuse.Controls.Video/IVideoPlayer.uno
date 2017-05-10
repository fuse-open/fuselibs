using Uno;
using Uno.UX;
using Uno.Graphics;
using Uno.Collections;

using Fuse;

namespace Fuse.Controls.VideoImpl
{

	internal interface IVideoPlayer : IDisposable
	{
		VideoTexture VideoTexture { get; }
		int2 Size { get; }
		int RotationDegrees { get; }

		float Volume { get; set; }

		double Duration { get; }
		double Position { get; set; }

		void Play();
		void Pause();
		void Update();

		event EventHandler FrameAvailable;
		event EventHandler<Exception> ErrorOccurred;
	}

	internal class EmptyVideo : IVideoPlayer
	{
		double IVideoPlayer.Duration { get { return 0.0; } }
		double IVideoPlayer.Position { get { return 0.0; } set { } }
		event EventHandler IVideoPlayer.FrameAvailable { add { } remove { } }
		event EventHandler<Exception> IVideoPlayer.ErrorOccurred { add { } remove { } }
		float IVideoPlayer.Volume { get { return 0.0f; } set { } }
		int2 IVideoPlayer.Size { get { return int2(0); } }
		int IVideoPlayer.RotationDegrees { get { return 0; } }
		VideoTexture IVideoPlayer.VideoTexture { get { return null; } }
		void IDisposable.Dispose() { }
		void IVideoPlayer.Pause() { }
		void IVideoPlayer.Play() { }
		void IVideoPlayer.Update() { }
	}
	
}