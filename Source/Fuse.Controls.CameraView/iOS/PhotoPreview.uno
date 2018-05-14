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

namespace Fuse.Controls.iOS
{
	extern(!iOS) public class PhotoPreview
	{
		[UXConstructor]
		public PhotoPreview([UXParameter("Host")]IPhotoPreviewHost host, [UXParameter("CameraView")]Fuse.Controls.CameraView cameraView) {}
	}

	extern(iOS) public class PhotoPreview : Fuse.Controls.Native.iOS.View, IPhotoPreview
	{
		ObjC.Object _view;
		IPhotoPreviewHost _host;
		Fuse.Controls.CameraView _cameraView;

		[UXConstructor]
		public PhotoPreview(
			[UXParameter("Host")]IPhotoPreviewHost host,
			[UXParameter("CameraView")]Fuse.Controls.CameraView cameraView) : this(NewUIImageView(), host, cameraView) {}

		PhotoPreview(
			ObjC.Object view,
			IPhotoPreviewHost host,
			Fuse.Controls.CameraView cameraView) : base(NewContainer(view))
		{
			_view = view;
			_host = host;
			_cameraView = cameraView;
			_cameraView.PhotoCaptured += OnPhotoCaptured;
		}

		PreviewStretchMode IPhotoPreview.PreviewStretchMode
		{
			set
			{
				switch (value)
				{
					case PreviewStretchMode.Uniform:
						SetUniform(_view);
						break;
					case PreviewStretchMode.UniformToFill:
						SetUniformToFill(_view);
						break;
					default:
						throw new Exception("Unexpected PreviewStretchMode: " + value);
				}
			}
		}

		void OnPhotoCaptured(Photo photo)
		{
			photo.GetPhotoHandle().Then(OnGotPhotoHandle);
		}

		void OnGotPhotoHandle(PhotoHandle photoHandle)
		{
			var uiImage = ((NativePhotoHandle)photoHandle).UIImage;
			SetUIImage(_view, uiImage);
			_host.OnPhotoLoaded();
		}

		public override void Dispose()
		{
			base.Dispose();
			_view = null;
			_host = null;
			_cameraView.PhotoCaptured -= OnPhotoCaptured;
			_cameraView = null;
		}

		[Foreign(Language.ObjC)]
		static ObjC.Object NewUIImageView()
		@{
			UIImageView* view = [[UIImageView alloc] init];
			view.clipsToBounds = true;
			view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			return view;
		@}

		[Foreign(Language.ObjC)]
		static ObjC.Object NewContainer(ObjC.Object uiImageView)
		@{
			UIView* view = [[UIView alloc] init];
			[view addSubview:(UIImageView*)uiImageView];
			return view;
		@}

		[Foreign(Language.ObjC)]
		static void SetUniform(ObjC.Object handle)
		@{
			((UIImageView*)handle).contentMode = UIViewContentModeScaleAspectFit;
		@}

		[Foreign(Language.ObjC)]
		static void SetUniformToFill(ObjC.Object handle)
		@{
			((UIImageView*)handle).contentMode = UIViewContentModeScaleAspectFill;
		@}

		[Foreign(Language.ObjC)]
		static void SetUIImage(ObjC.Object handle, ObjC.Object uiImage)
		@{
			((UIImageView*)handle).image = (UIImage*)uiImage;
		@}
	}
}
