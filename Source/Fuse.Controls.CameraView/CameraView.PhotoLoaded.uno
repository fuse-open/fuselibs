using Uno;
using Fuse.Triggers;

namespace Fuse.Controls
{
	public partial class CameraView
	{
		public class PhotoLoaded : Trigger
		{
			PhotoCaptureImageSource _photoCaptureImageSource;
			public PhotoCaptureImageSource PhotoCaptureImageSource
			{
				get { return _photoCaptureImageSource; }
				set
				{
					if (_photoCaptureImageSource != null && IsRootingCompleted)
						_photoCaptureImageSource.PhotoTextureLoaded -= OnPhotoTextureLoaded;

					_photoCaptureImageSource = value;

					if (_photoCaptureImageSource != null && IsRootingCompleted)
						_photoCaptureImageSource.PhotoTextureLoaded += OnPhotoTextureLoaded;
				}
			}

			PhotoPreview _photoPreview;
			public PhotoPreview PhotoPreview
			{
				get { return _photoPreview; }
				set
				{
					if (_photoPreview != null && IsRootingCompleted)
						_photoPreview.PhotoLoaded -= OnPhotoLoaded;

					_photoPreview = value;

					if (_photoPreview != null && IsRootingCompleted)
						_photoPreview.PhotoLoaded += OnPhotoLoaded;
				}
			}

			void OnPhotoTextureLoaded(object sender, EventArgs args)
			{
				Pulse();
			}

			void OnPhotoLoaded(object sender, EventArgs args)
			{
				Pulse();
			}

			protected override void OnRooted()
			{
				base.OnRooted();
				if (PhotoCaptureImageSource != null)
					PhotoCaptureImageSource.PhotoTextureLoaded += OnPhotoTextureLoaded;

				if (PhotoPreview != null)
					PhotoPreview.PhotoLoaded += OnPhotoLoaded;
			}

			protected override void OnUnrooted()
			{
				base.OnUnrooted();
				if (PhotoCaptureImageSource != null)
					PhotoCaptureImageSource.PhotoTextureLoaded -= OnPhotoTextureLoaded;

				if (PhotoPreview != null)
					PhotoPreview.PhotoLoaded -= OnPhotoLoaded;
			}
		}
	}
}
