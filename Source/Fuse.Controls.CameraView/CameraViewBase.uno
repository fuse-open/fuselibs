using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.Threading;

using Fuse;
using Fuse.Controls.Native;
using Fuse.Scripting;

namespace Fuse.Controls
{
	public enum PreviewStretchMode
	{
		Uniform,
		UniformToFill,
	}

	public enum FlashMode
	{
		Auto,
		On,
		Off,
	}

	public enum CaptureMode
	{
		Photo,
		Video,
	}

	public enum CameraFacing
	{
		Back,
		Front,
	}

	public abstract partial class CameraViewBase : LayoutControl, ICameraViewHost
	{
		PreviewStretchMode _previewStretchMode;
		public PreviewStretchMode PreviewStretchMode
		{
			get { return _previewStretchMode; }
			set
			{
				if (_previewStretchMode != value)
				{
					_previewStretchMode = value;
					CameraView.PreviewStretchMode = value;
				}
			}
		}

		ICamera _camera;
		ICamera Camera
		{
			get { return _camera ?? DummyCameraView.Instance; }
		}

		ICameraView CameraView
		{
			get { return ViewHandle as ICameraView ?? DummyCameraView.Instance; }
		}

		protected override void OnUnrooted()
		{
			base.OnUnrooted();
			_camera = null;
			_cameraPromise = null;
		}

		extern(ANDROID || iOS)
		protected override void PushPropertiesToNativeView()
		{
			CameraView.PreviewStretchMode = PreviewStretchMode;
		}

		GetCameraInfoPromise _cameraPromise;
		GetCameraInfoPromise CameraPromise
		{
			get { return _cameraPromise ?? (_cameraPromise = new GetCameraInfoPromise()); }
		}

		void ICameraViewHost.OnError(Exception e)
		{
			Fuse.Diagnostics.InternalError(e.Message, this);
			CameraPromise.Reject(e);
		}

		void ICameraViewHost.OnCameraLoaded(ICamera camera)
		{
			_camera = camera;
			CameraPromise.OnCameraLoaded(camera);
		}

		public Future<Photo> CapturePhoto()
		{
			if (!IsRootingCompleted)
				return RejectNotRooted<Photo>();

			OnPhotoCaptureStarted();

			var f = Camera.CapturePhoto();
			f.Then(OnPhotoCaptured);
			return f;
		}

		public Future<RecordingSession> StartRecording()
		{
			if (!IsRootingCompleted)
				return RejectNotRooted<RecordingSession>();

			return Camera.StartRecording();
		}

		public Future<CaptureMode> SetCaptureMode(CaptureMode mode)
		{
			if (!IsRootingCompleted)
				return RejectNotRooted<CaptureMode>();

			return Camera.SetCaptureMode(mode);
		}

		public Future<CameraFacing> SetCameraFacing(CameraFacing facing)
		{
			if (!IsRootingCompleted)
				return RejectNotRooted<CameraFacing>();

			return Camera.SetCameraFacing(facing);
		}

		public Future<Nothing> SetCameraFocusPoint(double x, double y, int cameraWidth, int cameraHeight, int isFocusLocked) 
		{
			if (!IsRootingCompleted)
				return RejectNotRooted<Nothing>();
			return Camera.SetCameraFocusPoint(x, y, cameraWidth, cameraHeight, isFocusLocked);
		}

		public Future<FlashMode> SetFlashMode(FlashMode mode)
		{
			if (!IsRootingCompleted)
				return RejectNotRooted<FlashMode>();

			return Camera.SetFlashMode(mode);
		}

		class GetCameraInfoPromise : CameraPromise<CameraInfo>
		{
			public void OnCameraLoaded(ICamera camera) { camera.GetCameraInfo().Then(Resolve, Reject); }
		}

		public Future<CameraInfo> GetCameraInfo()
		{
			if (!IsRootingCompleted)
				return RejectNotRooted<CameraInfo>();

			if (_camera == null)
				return CameraPromise;
			else
				return _camera.GetCameraInfo();
		}

		public Future<PhotoOption[]> SetPhotoOptions(PhotoOption[] options)
		{
			if (!IsRootingCompleted)
				return RejectNotRooted<PhotoOption[]>();

			return Camera.SetPhotoOptions(options);
		}

		Future<T> RejectNotRooted<T>()
		{
			var p = new Promise<T>();
			p.Reject(new Exception(ToString() + " not rooted"));
			return p;
		}

		void OnPhotoCaptured(Photo photo)
		{
			if (IsRootingCompleted)
			{
				var handler = PhotoCaptured;
				if (handler != null)
					handler(photo);
			}
		}

		void OnPhotoCaptureStarted()
		{
			var pcs = PhotoCaptureStarted;
			if (pcs != null)
				pcs(this, EventArgs.Empty);
		}

		internal delegate void PhotoCapturedHandler(Photo photo);

		internal event PhotoCapturedHandler PhotoCaptured;

		internal event EventHandler PhotoCaptureStarted;
	}

	internal interface ICameraViewHost
	{
		void OnCameraLoaded(ICamera camera);
		void OnError(Exception e);
	}

	internal interface ICameraView
	{
		PreviewStretchMode PreviewStretchMode { set; }
	}

	internal interface ICamera
	{
		Future<Photo> CapturePhoto();
		Future<RecordingSession> StartRecording();
		Future<CaptureMode> SetCaptureMode(CaptureMode mode);
		Future<CameraFacing> SetCameraFacing(CameraFacing facing);
		Future<Nothing> SetCameraFocusPoint(double x, double y, int cameraWidth, int cameraHeight, int isFocusLocked);
		Future<FlashMode> SetFlashMode(FlashMode mode);
		Future<PhotoOption[]> SetPhotoOptions(PhotoOption[] options);
		Future<CameraInfo> GetCameraInfo();
	}

	class DummyCameraView : ICameraView, ICamera
	{
		public static readonly DummyCameraView Instance = new DummyCameraView();
		public PreviewStretchMode PreviewStretchMode { set { } }
		public Future<Photo> CapturePhoto() { return Reject<Photo>(); }
		public Future<RecordingSession> StartRecording() { return Reject<RecordingSession>(); }
		public Future<CaptureMode> SetCaptureMode(CaptureMode mode) { return Reject<CaptureMode>(); }
		public Future<CameraFacing> SetCameraFacing(CameraFacing facing) { return Reject<CameraFacing>(); }
		public Future<Nothing> SetCameraFocusPoint(double x, double y, int cameraWidth, int cameraHeight, int isFocusLocked) { return Reject<Nothing>(); }
		public Future<FlashMode> SetFlashMode(FlashMode mode) { return Reject<FlashMode>(); }
		public Future<CameraInfo> GetCameraInfo() { return Reject<CameraInfo>(); }
		public Future<PhotoOption[]> SetPhotoOptions(PhotoOption[] options) { return Reject<PhotoOption[]>(); }
		Future<T> Reject<T>()
		{
			if defined(Android || iOS)
				return new Promise<T>().RejectWithMessage("Camera not loaded");
			else
				return new Promise<T>().RejectWithMessage("Platform not supported");
		}
	}
}
