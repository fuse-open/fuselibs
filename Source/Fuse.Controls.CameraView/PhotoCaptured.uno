using Uno;
using Fuse.Triggers;

namespace Fuse.Controls
{
	public class PhotoCaptured : Trigger
	{
		CameraViewBase _cameraView;
		public CameraViewBase CameraView
		{
			get { return _cameraView; }
			set
			{
				if (_cameraView != null && IsRootingCompleted)
					_cameraView.PhotoCaptured -= OnPhotoCaptured;

				_cameraView = value;

				if (_cameraView != null && IsRootingCompleted)
					_cameraView.PhotoCaptured += OnPhotoCaptured;
			}
		}

		void OnPhotoCaptured(Photo photo)
		{
			Pulse();
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			if (CameraView != null)
				CameraView.PhotoCaptured += OnPhotoCaptured;
		}

		protected override void OnUnrooted()
		{
			base.OnUnrooted();
			if (CameraView != null)
				CameraView.PhotoCaptured -= OnPhotoCaptured;
		}
	}
}
