using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;
using Uno.Permissions;

using Fuse;
using Fuse.Controls;
using Fuse.Controls.Native;
using Fuse.Deprecated.CameraView;

namespace Fuse.Deprecated.Android
{
	extern(!Android) class CameraView
	{
		[UXConstructor]
		public CameraView([UXParameter("Host")]ICameraViewHost host) { }
	}

	[ForeignInclude(Language.Java, "android.view.TextureView", "com.fuse.cameraview.AndroidCameraView", "com.fuse.cameraview.AndroidOrientationHelpers")]
	extern(Android) class CameraView : Fuse.Controls.Native.Android.View, ICameraView
	{
		ICameraViewHost _host;
		bool _hasPermission = false;

		[UXConstructor]
		public CameraView([UXParameter("Host")]ICameraViewHost host) : base(Create())
		{
			_host = host;
			var requiredPermissions = new PlatformPermission[]{
				Permissions.Android.CAMERA,
				Permissions.Android.RECORD_AUDIO,
				Permissions.Android.WRITE_EXTERNAL_STORAGE
			};

			var permissionPromise = Permissions.Request(requiredPermissions);
			permissionPromise.Then(OnPermitted, OnRejected);
		}

		void OnPermitted(PlatformPermission[] permission)
		{
			Init(Handle);
			_hasPermission = true;
		}

		void OnRejected(Exception e)
		{
			Fuse.Diagnostics.InternalError("Camera Permission rejected, unable to start camera ", e);
			_hasPermission = false;
		}

		public override void Dispose()
		{
			base.Dispose();
			_host = null;
		}
		
		[Foreign(Language.Java)]
		static Java.Object Create()
		@{	
			com.fuse.cameraview.AndroidCameraView camera = new com.fuse.cameraview.AndroidCameraView();
			return camera;
		@}

		[Foreign(Language.Java)]
		void Init(Java.Object cameraViewHandle)
		@{
			com.fuse.cameraview.AndroidCameraView view = (com.fuse.cameraview.AndroidCameraView) cameraViewHandle;
			view.createAndAddTextureView();
		@}

		public void SavePicture(ImagePromiseCallback callback, PictureResolution res)
		{
			if (!_hasPermission) 
			{
				callback.Reject("Unable to take picture: no provided camera permission!");
				return;
			}

			SavePicture(Handle, callback.Resolve, callback.Reject, res == PictureResolution.Full, texture2D.MaxSize);
		}

		[Foreign(Language.Java)]
		void SavePicture(Java.Object cameraViewHandle, Action<string> onComplete, Action<string> onFail, bool isFullRes, int maxTextureSize)
		@{
			com.fuse.cameraview.AndroidCameraView view = (com.fuse.cameraview.AndroidCameraView) cameraViewHandle;
			view.takePicture(onComplete, onFail, isFullRes, maxTextureSize);
		@}

		public void SwapCamera()
		{
			if (!_hasPermission) return;
			UpdateCamera();
		}

		public void StartRecording()
		{
			if (!_hasPermission) return;
			StartRecording(Handle);
		}

		public CameraDirection[] SupportedDirections
		{
			get 
			{
				return CameraDevice.SupportedDirections;
			}
		}

		[Foreign(Language.Java)]
		void StartRecording(Java.Object cameraViewHandle)
		@{
			com.fuse.cameraview.AndroidCameraView view = (com.fuse.cameraview.AndroidCameraView) cameraViewHandle;
			view.startRecording();
		@}

		public void StopRecording(VideoPromiseCallback callback)
		{
			if (!_hasPermission) 
			{
				callback.Reject("Unable to record: no provided camera permission!");
				return;
			}

			StopRecording(Handle, callback.Resolve, callback.Reject);
		}

		[Foreign(Language.Java)]
		void StopRecording(Java.Object cameraViewHandle, Action<string> onComplete, Action<string> onFail)
		@{
			com.fuse.cameraview.AndroidCameraView view = (com.fuse.cameraview.AndroidCameraView) cameraViewHandle;
			view.stopRecording(onComplete, onFail);
		@}

		CameraDirection _direction = CameraDirection.Back;
		public CameraDirection Direction
		{
			get { return _direction; }

			set { _direction = value; }
		}

		bool _useFlash = false;
		public bool UseFlash
		{
			get { return _useFlash; }

			set 
			{ 
				_useFlash = SetFlash(Handle, value);
			}
		}

		public void UpdateCamera()
		{
			if (!_hasPermission) return;

			UpdateCamera(Handle, _direction == CameraDirection.Back);
		}

		[Foreign(Language.Java)]
		void UpdateCamera(Java.Object cameraViewHandle, bool isFacingBack)
		@{
			com.fuse.cameraview.AndroidCameraView view = (com.fuse.cameraview.AndroidCameraView) cameraViewHandle;
			view.updateCamera(isFacingBack);
		@}

		[Foreign(Language.Java)]
		bool SetFlash(Java.Object cameraViewHandle, bool enableFlash)
		@{
			com.fuse.cameraview.AndroidCameraView view = (com.fuse.cameraview.AndroidCameraView) cameraViewHandle;
			return view.setFlash(enableFlash);
		@}
	}
}