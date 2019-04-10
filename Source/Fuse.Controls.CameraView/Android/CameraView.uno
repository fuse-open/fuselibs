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
	extern(!ANDROID) class CameraView
	{
		[UXConstructor]
		public CameraView([UXParameter("Host")]ICameraViewHost host) { }
	}

	extern(ANDROID) class CameraView : Fuse.Controls.Native.Android.View, ICameraView, ICamera
	{
		enum CaptureState
		{
			Idle,
			CapturingPhoto,
			CapturingVideo,
		}

		ICameraViewHost _host;

		[UXConstructor]
		public CameraView([UXParameter("Host")]ICameraViewHost host) : base(Create())
		{
			Fuse.Platform.Lifecycle.EnteringForeground += OnEnteringForeground;
			Fuse.Platform.Lifecycle.EnteringBackground += OnEnteringBackground;

			_host = host;
			_cameraFuture = new InitialLoadClosure(CameraFacing.Back);
			_cameraFuture.Then(OnCameraLoaded, OnCameraRejected);
		}

		bool _inForeground = true;
		void OnEnteringBackground(Fuse.Platform.ApplicationState s)
		{
			if (!_inForeground)
				return;
			_inForeground = false;
			CleanupCamera();
		}

		void OnEnteringForeground(Fuse.Platform.ApplicationState s)
		{
			if (_inForeground)
				return;
			_inForeground = true;
			if (!_isLoading)
				LoadCamera(_lastCameraFacing);
		}

		class InitialLoadClosure : CameraPromise<Camera>
		{
			CameraFacing _facing;

			public InitialLoadClosure(CameraFacing facing)
			{
				_facing = facing;
				Permissions.Request(new PlatformPermission[] {
					Permissions.Android.CAMERA,
					Permissions.Android.RECORD_AUDIO,
					Permissions.Android.WRITE_EXTERNAL_STORAGE
				}).Then(OnPermissionsPerimtted, Reject);
			}

			void OnPermissionsPerimtted(PlatformPermission[] permission)
			{
				CameraLoader.Load(_facing).Then(Resolve, Reject);
			}
		}

		Future<Camera> _cameraFuture;
		bool _isLoading = true;
		CameraFacing _lastCameraFacing;
		void LoadCamera(CameraFacing facing)
		{
			_isLoading = true;
			try
			{
				if (_camera != null)
					CleanupCamera();

				_cameraFuture.Cancel();
				_lastCameraFacing = facing;
				_cameraFuture = CameraLoader.Load(facing);
				_cameraFuture.Then(OnCameraLoaded, OnCameraRejected);
			}
			catch (Exception e)
			{
				_isLoading = false;
				throw e;
			}
		}

		void OnCameraRejected(Exception e)
		{
			if (_isDisposed)
				return;
			_isLoading = false;
			_host.OnError(e);
		}

		Camera _camera;
		void OnCameraLoaded(Camera camera)
		{
			if (_isDisposed)
			{
				camera.Dispose();
				return;
			}
			_isLoading = false;
			_camera = camera;
			InsertChild(_camera);
			_camera.PreviewStretchMode = _previewStretchMode;
			_host.OnCameraLoaded(this);
		}

		PreviewStretchMode _previewStretchMode;

		PreviewStretchMode ICameraView.PreviewStretchMode
		{
			set
			{
				_previewStretchMode = value;
				if (_camera != null)
					_camera.PreviewStretchMode = _previewStretchMode;
			}
		}

		CaptureState _captureState = CaptureState.Idle;
		CaptureMode _captureMode = CaptureMode.Photo;

		void ResetCaptureState() { _captureState = CaptureState.Idle; }

		Future<Photo> ICamera.CapturePhoto()
		{
			if (_camera == null)
				return Reject<Photo>("Camera busy or misconfigured");

			if (_captureState != CaptureState.Idle)
				return Reject<Photo>("Cannot capture photo while already capturing photo or video");

			if (_captureMode != CaptureMode.Photo)
				return Reject<Photo>("Cannot capture photo, CaptureMode not set to photo");

			_captureState = CaptureState.CapturingPhoto;

			return _camera.CapturePhoto().Intercept(ResetCaptureState);
		}

		Future<RecordingSession> ICamera.StartRecording()
		{
			if (_camera == null)
				return Reject<RecordingSession>("Camera busy or misconfigured");

			if (_captureState != CaptureState.Idle)
				return Reject<RecordingSession>("Cannot start recording while already capturing photo or video");

			if (_captureMode != CaptureMode.Video)
				return Reject<RecordingSession>("Cannot start recording, CaptureMode not set to video");

			_captureState = CaptureState.CapturingVideo;

			return _camera.StartRecording(ResetCaptureState).InvokeOnRejected(ResetCaptureState);
		}

		Future<CaptureMode> ICamera.SetCaptureMode(CaptureMode mode)
		{
			if (_captureState != CaptureState.Idle)
				return Reject<CaptureMode>("Cannot set CaptureMode while capturing photo or video");

			_captureMode = mode;
			return new Promise<CaptureMode>(mode);
		}

		Future<PhotoOption[]> ICamera.SetPhotoOptions(PhotoOption[] options)
		{
			if (_camera == null)
				return Reject<PhotoOption[]>("Camera busy or misconfigured");

			if (_captureState != CaptureState.Idle)
				return Reject<PhotoOption[]>("Cannot set photo options while capturing photo or video");

			return _camera.SetPhotoOptions(options);
		}

		class SetCameraFacingClosure : CameraPromise<CameraFacing>
		{
			CameraFacing _cameraFacing;

			public SetCameraFacingClosure(CameraFacing cameraFacing)
			{
				_cameraFacing = cameraFacing;
			}

			public void OnResolve(Camera camera)
			{
				if (camera.Facing == _cameraFacing)
					Resolve(_cameraFacing);
				else
					Reject(new Exception("Failed to set CameraFacing"));
			}

			public void OnReject(Exception e) { Reject(new Exception("Failed to set CameraFacing: " + e.Message)); }
		}

		Future<CameraFacing> ICamera.SetCameraFacing(CameraFacing facing)
		{
			if (_captureState != CaptureState.Idle)
				return Reject<CameraFacing>("Cannot set CameraFacing while capturing photo or video");

			if (_cameraFuture.State != FutureState.Resolved)
				return Reject<CameraFacing>("Camera busy or misconfigured");

			if (_camera != null && _camera.Facing == facing)
				return new Promise<CameraFacing>(facing);

			var p = new SetCameraFacingClosure(facing);
			LoadCamera(facing);
			_cameraFuture.Then(p.OnResolve, p.OnReject);
			return p;
		}

		Future<Nothing> ICamera.SetCameraFocusPoint(double x, double y, int cameraWidth, int cameraHeight, int isFocusLocked) 
		{
			if (_camera == null)
				return Reject<Nothing>("Camera busy or misconfigured");

			if (_captureState != CaptureState.Idle)
				return Reject<Nothing>("Cannot set photo options while capturing photo or video");

			return _camera.SetCameraFocusPoint(x, y, cameraWidth, cameraHeight, isFocusLocked);
		}

		Future<FlashMode> ICamera.SetFlashMode(FlashMode mode)
		{
			if (_camera == null)
				return Reject<FlashMode>("Camera busy or misconfigured");

			if (_captureState != CaptureState.Idle)
				return Reject<FlashMode>("Cannot set FlashMode while capturing photo or video");

			if (!mode.IsSupported(_camera))
				return Reject<FlashMode>("FlashMode." + mode + " not supported for CameraFacing." + _camera.Facing);

			return new Promise<FlashMode>(_camera.FlashMode = mode);
		}

		class GetCameraInfoClosure : Promise<CameraInfo>
		{
			CameraView _cameraView;

			public GetCameraInfoClosure(CameraView cameraView)
			{
				_cameraView = cameraView;
				_cameraView._cameraFuture.Then(OnResolve, OnReject);
			}

			void OnResolve(Camera camera) { Resolve(new CameraInfo(camera.FlashMode, camera.Facing, _cameraView._captureMode, camera.PictureSizes, camera.SupportedFlashModes)); }
			void OnReject(Exception e) { Reject(new Exception("Failed to get camera info: " + e.Message, e)); }
		}

		Future<CameraInfo> ICamera.GetCameraInfo()
		{
			return new GetCameraInfoClosure(this);
		}

		Future<T> Reject<T>(string message)
		{
			var p = new Promise<T>();
			p.Reject(new Exception(message));
			return p;
		}

		void CleanupCamera()
		{
			if (_camera != null)
			{
				RemoveChild(_camera);
				_camera.Dispose();
				_camera = null;
			}
		}

		bool _isDisposed = false;
		public override void Dispose()
		{
			Fuse.Platform.Lifecycle.EnteringForeground -= OnEnteringForeground;
			Fuse.Platform.Lifecycle.EnteringBackground -= OnEnteringBackground;
			CleanupCamera();
			base.Dispose();
			_host = null;
			_isDisposed = true;
		}

		[Foreign(Language.Java)]
		static Java.Object Create()
		@{
			android.widget.FrameLayout frameLayout = new android.widget.FrameLayout(com.fuse.Activity.getRootActivity());
			frameLayout.setLayoutParams(new android.widget.FrameLayout.LayoutParams(android.view.ViewGroup.LayoutParams.MATCH_PARENT, android.view.ViewGroup.LayoutParams.MATCH_PARENT));
			return frameLayout;
		@}
	}
}
