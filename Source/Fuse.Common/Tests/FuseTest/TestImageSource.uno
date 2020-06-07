using Uno;

using Fuse;
using Fuse.Resources;
using Fuse.Resources.Exif;

namespace FuseTest
{
	/**
		A manually controlled loading image source
	*/
	public class TestImageSource : ImageSource
	{
		public int2 SourcePixelSize = int2(100,200);

		public float PixelsPerPoint = 1;

		ImageSourceState _state = ImageSourceState.Pending;

		public override float2 Size
		{
			get { return float2(SourcePixelSize.X / PixelsPerPoint, SourcePixelSize.Y / PixelsPerPoint); }
		}
		public override ImageOrientation Orientation { get { return ImageOrientation.Identity; } }
		public override int2 PixelSize { get { return SourcePixelSize; } }
		public override ImageSourceState State { get  { return _state; } }
		public override texture2D GetTexture()
		{
			return null;
		}

		public override byte[] GetBytes()
		{
			return null;
		}

		public override float SizeDensity { get { return PixelsPerPoint; } }

		public void MarkReady()
		{
			_state = ImageSourceState.Ready;
			OnChanged();
		}

		public void MarkLoading()
		{
			_state = ImageSourceState.Loading;
			OnChanged();
		}

		public void Fail( string message )
		{
			_state = ImageSourceState.Failed;
			OnError( message );
		}

		int _reloadCount;
		public int ReloadCount { get { return _reloadCount; } }
		public override void Reload()
		{
			_reloadCount++;
		}
	}
}