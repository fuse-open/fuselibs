using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;
using Uno.Permissions;
using Uno.Threading;
using Uno.Collections;

using Fuse;
using Fuse.Controls;
using Fuse.Controls.Native;
using Fuse.Controls.CameraView;

namespace Fuse.Controls.Android
{
	extern(!ANDROID) class PhotoPreview
	{
		[UXConstructor]
		public PhotoPreview([UXParameter("Host")]IPhotoPreviewHost host, [UXParameter("CameraView")]Fuse.Controls.CameraView cameraView) {}
	}

	extern(ANDROID) class PhotoPreview : Fuse.Controls.Native.Android.View, IPhotoPreview
	{
		[UXConstructor]
		public PhotoPreview(
			[UXParameter("Host")]IPhotoPreviewHost host,
			[UXParameter("CameraView")]Fuse.Controls.CameraView cameraView) : this(NewImageView(), host, cameraView) {}

		Java.Object _view;
		IPhotoPreviewHost _host;
		Fuse.Controls.CameraView _cameraView;

		PhotoPreview(Java.Object view, IPhotoPreviewHost host, Fuse.Controls.CameraView cameraView) : base(view)
		{
			_view = view;
			_host = host;
			_cameraView = cameraView;
			_cameraView.PhotoCaptured += OnPhotoCaptured;
		}

		void OnPhotoCaptured(Photo photo)
		{
			photo.GetPhotoHandle().Then(OnGotPhotoHandle, OnRejected);
		}

		NativePhotoHandle _photoHandle;

		void OnGotPhotoHandle(PhotoHandle photoHandle)
		{
			var oldPhotoHandle = _photoHandle;
			_photoHandle = (NativePhotoHandle)photoHandle;
			SetImageBitmap(_view, _photoHandle.Bitmap);

			if (oldPhotoHandle != null)
				oldPhotoHandle.Dispose();

			_host.OnPhotoLoaded();
		}

		void OnRejected(Exception e)
		{
			Fuse.Diagnostics.InternalError("Failed to get photo handle: " + e.Message, this);
		}

		PreviewStretchMode IPhotoPreview.PreviewStretchMode
		{
			set
			{
				switch (value)
				{
					case PreviewStretchMode.Uniform:
						SetCenterInside(_view);
						break;
					case PreviewStretchMode.UniformToFill:
						SetCenterCrop(_view);
						break;
					default:
						throw new Exception("Unexpected PreviewStretchMode: " + value);
				}
			}
		}

		public override void Dispose()
		{
			base.Dispose();
			_view = null;
			_host = null;
			if (_photoHandle != null)
			{
				_photoHandle.Dispose();
				_photoHandle = null;
			}
			_cameraView.PhotoCaptured -= OnPhotoCaptured;
			_cameraView = null;
		}

		[Foreign(Language.Java)]
		static void SetCenterCrop(Java.Object imageView)
		@{
			((android.widget.ImageView)imageView).setScaleType(android.widget.ImageView.ScaleType.CENTER_CROP);
		@}

		[Foreign(Language.Java)]
		static void SetCenterInside(Java.Object imageView)
		@{
			((android.widget.ImageView)imageView).setScaleType(android.widget.ImageView.ScaleType.CENTER_INSIDE);
		@}

		[Foreign(Language.Java)]
		static void SetImageBitmap(Java.Object imageView, Java.Object bitmap)
		@{
			((android.widget.ImageView)imageView).setImageBitmap((android.graphics.Bitmap)bitmap);
		@}

		[Foreign(Language.Java)]
		static Java.Object NewImageView()
		@{
			android.widget.ImageView imageView = new android.widget.ImageView(com.fuse.Activity.getRootActivity());
			imageView.setCropToPadding(true);
			imageView.setScaleType(android.widget.ImageView.ScaleType.CENTER_INSIDE);
			return imageView;
		@}
	}
}
