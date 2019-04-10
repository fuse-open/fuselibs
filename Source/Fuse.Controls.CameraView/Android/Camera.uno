using Uno;
using OpenGL;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Uno.Threading;
using Uno.Graphics;

using Fuse;
using Fuse.Controls;
using Fuse.Controls.Native;

namespace Fuse.Controls.Android
{
	extern(ANDROID) class AndroidRecording : Recording
	{
		public AndroidRecording(string outputFilePath) : base(outputFilePath)
		{
		}
	}

	[ForeignInclude(Language.Java,
		"com.fuse.controls.cameraview.RecordingSession",
		"com.fuse.controls.cameraview.IStopRecordingSession")]
	extern(ANDROID) class AndroidRecordingSession : RecordingSession, IDisposable
	{
		Java.Object _session;
		Action _doneCallback;

		public AndroidRecordingSession(Java.Object session, Action doneCallback)
		{
			_session = session;
			_doneCallback = doneCallback;
		}

		bool _stopped = false;
		public override Future<Recording> Stop()
		{
			return InternalStop().Intercept(_doneCallback);
		}

		Future<Recording> InternalStop()
		{
			if (!_stopped)
			{
				_stopped = true;
				var p = new RecordingPromise();
				Stop(_session, p.OnResolve, p.OnReject);
				return p;
			}
			else
			{
				var p = new Promise<Recording>();
				p.Reject(new Exception("Recording already stopped!"));
				return p;
			}
		}

		void IDisposable.Dispose()
		{
			InternalStop();
		}

		class RecordingPromise : CameraPromise<Recording>
		{
			public void OnResolve(string outputFilePath) { Resolve(new AndroidRecording(outputFilePath)); }
			public void OnReject(string exceptionMessage) { Reject(new Exception(exceptionMessage)); }
		}

		[Foreign(Language.Java)]
		static void Stop(Java.Object session, Action<string> resolve, Action<string> reject)
		@{
			((RecordingSession)session).stop(new IStopRecordingSession() {
				public void onSuccess(String outputFilePath) {
					resolve.run(outputFilePath);
				}
				public void onException(String message) {
					reject.run(message);
				}
			});
		@}
	}

	[ForeignInclude(Language.Java,
		"com.fuse.controls.cameraview.CameraImpl",
		"com.fuse.controls.cameraview.IPictureCallback",
		"com.fuse.controls.cameraview.RecordingSession",
		"com.fuse.controls.cameraview.IStartRecordingSession")]
	extern(ANDROID) class Camera : ViewHandle
	{
		public Java.Object CameraHandle { get; private set; }
		public CameraFacing Facing { get; private set; }

		FlashMode _flashMode = FlashMode.Off;
		public FlashMode FlashMode
		{
			get { return _flashMode; }
			set
			{
				if (value.IsSupported(this))
				{
					SetFlashMode(CameraHandle, value.AsString());
					_flashMode = value;
				}
			}
		}

		class PicturePromise : CameraPromise<Photo>
		{
			public void OnResolve(Java.Object bytesArray)
			{
				if (State == FutureState.Pending)
					Resolve(new NativePhoto(bytesArray));
			}

			public void OnReject(string exceptionMessage)
			{
				if (State == FutureState.Pending)
					Reject(new Exception(exceptionMessage));
			}
		}

		public Future<Photo> CapturePhoto()
		{
			var picturePromise = new PicturePromise();
			TakePicture(picturePromise.OnResolve, picturePromise.OnReject);
			return picturePromise;
		}

		class AndroidPhotoOptionPromise : PhotoOptionPromise
		{
			Camera _camera;
			string _parameters;

			public AndroidPhotoOptionPromise(Camera camera)
			{
				_camera = camera;
				_parameters = _camera.SaveParameters();
			}

			protected override void Visit(PhotoResolution photoResolution)
			{
				var size = int2(photoResolution.Width, photoResolution.Height);
				if (_camera.SupportsSize(size))
					_camera.SetPictureSize(size.X, size.Y);
				else
				{
					_camera.RestoreParameters(_parameters);
					throw new Exception("Resolution not supported: " + size);
				}
			}
		}

		public Future<PhotoOption[]> SetPhotoOptions(PhotoOption[] options)
		{
			return new AndroidPhotoOptionPromise(this).Visit(options);
		}

		class AndroidCameraFocusPointPromise : Promise<Nothing> 
		{
			Camera _camera;
			string _parameters;

			public AndroidCameraFocusPointPromise(Camera camera) 
			{
				_camera = camera;
				_parameters = _camera.SaveParameters();
			}
				
			public Future<Nothing> doFocus(double x, double y, int cameraWidth, int cameraHeight, int isFocusLocked) 
			{
				try 
				{
					_camera.SetCameraFocusPointNow(x,y, cameraWidth, cameraHeight, isFocusLocked);
					
					Resolve(default(Nothing));
					return this;
				} 
				catch (Exception e) 
				{
					Reject(e);
					return this;
				}
			}
		}

		public Future<Nothing> SetCameraFocusPoint(double x, double y, int cameraWidth, int cameraHeight, int isFocusLocked) 
		{
			return new AndroidCameraFocusPointPromise(this).doFocus(x, y, cameraWidth, cameraHeight, isFocusLocked);
		}

		class RecordingSessionPromise : Promise<RecordingSession>
		{
			Action _doneCallback;
			Action<IDisposable> _setRecordingSession;

			public RecordingSessionPromise(Action doneCallback, Action<IDisposable> setRecordingSession)
			{
				_doneCallback = doneCallback;
				_setRecordingSession = setRecordingSession;
			}

			public void OnResolve(Java.Object session)
			{
				if (State == FutureState.Pending)
				{
					var s = new AndroidRecordingSession(session, _doneCallback);
					_setRecordingSession(s);
					Resolve(s);
				}
			}

			public void OnReject(string exceptionMessage)
			{
				if (State == FutureState.Pending)
					Reject(new Exception(exceptionMessage));
			}
		}

		IDisposable _recordingSession = null;

		void SetRecordingSession(IDisposable recordingSession)
		{
			_recordingSession = recordingSession;
		}

		public Future<RecordingSession> StartRecording(Action doneCallback)
		{
			var recordingPromise = new RecordingSessionPromise(doneCallback, SetRecordingSession);
			StartRecording(recordingPromise.OnResolve, recordingPromise.OnReject);
			return recordingPromise;
		}

		public PreviewStretchMode PreviewStretchMode
		{
			set { UpdatePreviewStretchMode(value == Fuse.Controls.PreviewStretchMode.UniformToFill); }
		}

		public Camera(Java.Object cameraHandle, int cameraId, CameraFacing facing) : base(Create(cameraHandle, cameraId, Texture2D.MaxSize, Texture2D.MaxSize))
		{
			CameraHandle = cameraHandle;
			Facing = facing;
			var supportedFlashModes = SupportedFlashModes;
			if (supportedFlashModes.Length > 0)
				FlashMode = supportedFlashModes[0];
		}

		public override void Dispose()
		{
			if (_recordingSession != null)
			{
				_recordingSession.Dispose();
				_recordingSession = null;
			}
			Dispose(NativeHandle);
			Release(CameraHandle);
			base.Dispose();
		}

		// picturesizes does not change for an instance of Camera
		int2[] _pictureSizes = null;
		public int2[] PictureSizes
		{
			get
			{
				if (_pictureSizes != null)
					return _pictureSizes;

				var count = GetSupportedPictureSizesCount(CameraHandle);
				var sizes = new int[count * 2];
				GetSupportedPictureSizes(CameraHandle, sizes);
				var result = new int2[count];
				for (var i = 0; i < result.Length; i++)
					result[i] = int2(sizes[(i * 2) + 0], sizes[(i * 2) + 1]);
				return _pictureSizes = result;
			}
		}

		public FlashMode[] SupportedFlashModes
		{
			get
			{
				var m = new List<FlashMode>();

				if (Fuse.Controls.FlashMode.Auto.IsSupported(this))
					m.Add(Fuse.Controls.FlashMode.Auto);

				if (Fuse.Controls.FlashMode.On.IsSupported(this))
					m.Add(Fuse.Controls.FlashMode.On);

				if (Fuse.Controls.FlashMode.Off.IsSupported(this))
					m.Add(Fuse.Controls.FlashMode.Off);

				return m.ToArray();
			}
		}

		bool SupportsSize(int2 size)
		{
			foreach (var s in PictureSizes)
				if (s == size)
					return true;
			return false;
		}

		[Foreign(Language.Java)]
		void GetSupportedPictureSizes(Java.Object camera, int[] output)
		@{
			java.util.List<android.hardware.Camera.Size> sizes = ((android.hardware.Camera)camera).getParameters().getSupportedPictureSizes();
			for (int i = 0; i < sizes.size(); i++) {
				output.set((i * 2) + 0, sizes.get(i).width);
				output.set((i * 2) + 1, sizes.get(i).height);
			}
		@}

		[Foreign(Language.Java)]
		int GetSupportedPictureSizesCount(Java.Object camera)
		@{
			return ((android.hardware.Camera)camera).getParameters().getSupportedPictureSizes().size();
		@}

		[Foreign(Language.Java)]
		void UpdatePreviewStretchMode(bool shouldFill)
		@{
			((CameraImpl)@{Fuse.Controls.Native.ViewHandle:Of(_this).NativeHandle:Get()}).updateStretchMode(shouldFill);
		@}

		[Foreign(Language.Java)]
		void SetFlashMode(Java.Object handle, string flashMode)
		@{
			((CameraImpl)@{Fuse.Controls.Native.ViewHandle:Of(_this).NativeHandle:Get()}).setFlashMode(flashMode);
		@}

		[Foreign(Language.Java)]
		void SetCameraFocusPointNow(double x, double y, int cameraWidth, int cameraHeight, int isFocusLocked) 
		@{
			((CameraImpl)@{Fuse.Controls.Native.ViewHandle:Of(_this).NativeHandle:Get()}).setCameraFocusPoint(x,y,cameraWidth,cameraHeight, isFocusLocked);
		@}

		[Foreign(Language.Java)]
		void TakePicture(Action<Java.Object> resolve, Action<string> reject)
		@{
			((CameraImpl)@{Fuse.Controls.Native.ViewHandle:Of(_this).NativeHandle:Get()}).takePicture(new IPictureCallback() {
				public void onPictureTaken(byte[] data) {
					resolve.run(data);
				}
				public void onError(Exception e) {
					reject.run(e.getMessage());
				}
			});
		@}

		[Foreign(Language.Java)]
		void StartRecording(Action<Java.Object> resolve, Action<string> reject)
		@{
			((CameraImpl)@{Fuse.Controls.Native.ViewHandle:Of(_this).NativeHandle:Get()}).startRecording(new IStartRecordingSession() {
				public void onSuccess(RecordingSession recordingSession) {
					resolve.run(recordingSession);
				}
				public void onException(String message) {
					reject.run(message);
				}
			});
		@}

		[Foreign(Language.Java)]
		string SaveParameters()
		@{
			return ((CameraImpl)@{Fuse.Controls.Native.ViewHandle:Of(_this).NativeHandle:Get()}).saveParameters();
		@}

		[Foreign(Language.Java)]
		void RestoreParameters(string parameters)
		@{
			((CameraImpl)@{Fuse.Controls.Native.ViewHandle:Of(_this).NativeHandle:Get()}).restoreParameters(parameters);
		@}

		[Foreign(Language.Java)]
		void SetPictureSize(int width, int height)
		@{
			((CameraImpl)@{Fuse.Controls.Native.ViewHandle:Of(_this).NativeHandle:Get()}).setPictureSize(width, height);
		@}

		[Foreign(Language.Java)]
		static void Release(Java.Object handle)
		@{
			((android.hardware.Camera)handle).release();
		@}

		[Foreign(Language.Java)]
		static void Dispose(Java.Object handle)
		@{
			((CameraImpl)handle).dispose();
		@}

		[Foreign(Language.Java)]
		static Java.Object Create(Java.Object camera, int cameraId, int maxWidth, int maxHeight)
		@{
			CameraImpl view = new CameraImpl(com.fuse.Activity.getRootActivity(), (android.hardware.Camera)camera, cameraId, maxWidth, maxHeight);
			view.setLayoutParams(new android.widget.FrameLayout.LayoutParams(android.view.ViewGroup.LayoutParams.MATCH_PARENT, android.view.ViewGroup.LayoutParams.MATCH_PARENT));
			return view;
		@}
	}

	extern(ANDROID) internal static class FlashModeExtensions
	{
		public static bool IsSupported(this FlashMode flashMode, Camera camera)
		{
			return IsSupported(flashMode.AsString(), camera.CameraHandle);
		}

		[Foreign(Language.Java)]
		static bool IsSupported(string flashMode, Java.Object cameraHandle)
		@{
			java.util.List<String> flashModes = ((android.hardware.Camera)cameraHandle).getParameters().getSupportedFlashModes();
			if (flashModes == null)
				return false;

			for (String mode : flashModes) {
				if (mode.equals(flashMode))
					return true;
			}

			return false;
		@}

		public static string AsString(this FlashMode flashMode)
		{
			switch (flashMode)
			{
				case FlashMode.Auto:
					return "auto";
				case FlashMode.On:
					return "on";
				case FlashMode.Off:
					return "off";
				default:
					throw new Exception("Unexpected FlashMode: " + flashMode);
			}
		}
	}
}
