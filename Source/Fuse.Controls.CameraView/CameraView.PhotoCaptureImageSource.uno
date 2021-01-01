using Uno;
using Fuse.Resources;
using Fuse.Resources.Exif;

namespace Fuse.Controls
{
	public partial class CameraView
	{
		public class PhotoCaptureImageSource : ImageSource
		{
			CameraViewBase _cameraView;
			public CameraViewBase CameraView
			{
				get { return _cameraView; }
				set
				{
					if (_cameraView != null)
					{
						_cameraView.PhotoCaptured -= OnPhotoCaptured;
						_cameraView.PhotoCaptureStarted -= OnPhotoCaptureStarted;
					}

					_cameraView = value;

					if (_cameraView != null)
					{
						_cameraView.PhotoCaptured += OnPhotoCaptured;
						_cameraView.PhotoCaptureStarted += OnPhotoCaptureStarted;
					}
				}
			}

			void OnPhotoCaptureStarted(object sender, EventArgs args)
			{
				PhotoTexture = null;
				OnChanged();
			}

			void OnPhotoCaptured(Photo photo)
			{
				photo.GetTexture().Then(OnGotTexture, OnRejected);
			}

			PhotoTexture _photoTexture;
			PhotoTexture PhotoTexture
			{
				get { return _photoTexture; }
				set
				{
					if (_photoTexture != null)
						_photoTexture.Dispose();

					_photoTexture = value;
				}
			}

			texture2D Texture
			{
				get { return _photoTexture != null ? _photoTexture.Texture : null; }
			}

			internal EventHandler PhotoTextureLoaded;

			void OnPhotoTextureLoaded()
			{
				var ptl = PhotoTextureLoaded;
				if (ptl != null)
					ptl(this, EventArgs.Empty);
			}

			void OnGotTexture(PhotoTexture photoTexture)
			{
				PhotoTexture = photoTexture;
				OnChanged();
				OnPhotoTextureLoaded();
			}

			void OnRejected(Exception e)
			{
				Diagnostics.InternalError("Failed to get OpenGL texture from photo", e);
			}

			public override float2 Size
			{
				get
				{
					return Texture != null
						? (float2)Texture.Size
						: float2(0);
				}
			}

			public override int2 PixelSize
			{
				get
				{
					return Texture != null
						? Texture.Size
						: int2(0);
				}
			}

			public override ImageSourceState State
			{
				get
				{
					return Texture != null
						? ImageSourceState.Ready
						: ImageSourceState.Pending;
				}
			}

			public override ImageOrientation Orientation
			{
				get
				{
					return PhotoTexture != null
						? PhotoTexture.Orientation
						: ImageOrientation.Identity;

				}
			}

			public override texture2D GetTexture()
			{
				return Texture;
			}

			public override byte[] GetBytes()
			{
				return null;
			}

			public override float SizeDensity
			{
				get { return 1.0f; }
			}
		}
	}
}
