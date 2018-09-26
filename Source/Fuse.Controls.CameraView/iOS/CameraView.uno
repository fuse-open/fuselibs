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
	extern(!iOS) class CameraView
	{
		[UXConstructor]
		public CameraView([UXParameter("Host")]ICameraViewHost host) { }
	}

	extern(iOS) class NativeRecording : Recording
	{
		public NativeRecording(string filePath) : base(filePath)
		{
		}
	}

	[Require("Source.Include", "iOS/RecordingSession.h")]
	extern(iOS) class NativeRecordingSession : RecordingSession, IDisposable
	{

		ObjC.Object _handle;

		public NativeRecordingSession(ObjC.Object handle)
		{
			_handle = handle;
		}

		class StopClosure : CameraPromise<Recording>
		{
			public void OnResolve(string filePath) { Resolve(new NativeRecording(filePath)); }
			public void OnReject(string msg) { Reject(new Exception(msg)); }
		}

		public override Future<Recording> Stop()
		{
			var p = new StopClosure();
			Stop(_handle, p.OnResolve, p.OnReject);
			return p;
		}

		void IDisposable.Dispose()
		{
			Stop();
		}

		[Foreign(Language.ObjC)]
		static void Stop(ObjC.Object handle, Action<string> resolve, Action<string> reject)
		@{
			[((::RecordingSession*)handle) stopRecording:resolve onReject:reject];
		@}

		public static RecordingSession New(ObjC.Object handle)
		{
			return new NativeRecordingSession(handle);
		}
	}

	[Require("Source.Include", "iOS/CameraPreview.h")]
	[Require("Source.Include", "iOS/CameraViewImpl.h")]
	extern(iOS) class NativeCamera : ICamera
	{
		static readonly int CaptureModePhoto = extern<int>"fcv::CAPTURE_MODE_PHOTO";
		static readonly int CaptureModeVideo = extern<int>"fcv::CAPTURE_MODE_VIDEO";

		static readonly int CameraFacingFront = extern<int>"fcv::CAMERA_FACING_FRONT";
		static readonly int CameraFacingBack = extern<int>"fcv::CAMERA_FACING_BACK";

		static readonly int FlashModeAuto = extern<int>"fcv::FLASH_MODE_AUTO";
		static readonly int FlashModeOn = extern<int>"fcv::FLASH_MODE_ON";
		static readonly int FlashModeOff = extern<int>"fcv::FLASH_MODE_OFF";

		IntPtr _handle;

		NativeCamera(IntPtr handle)
		{
			_handle = handle;
		}

		class LoadClosure : CameraPromise<NativeCamera>
		{
			public IntPtr DisposeHandle;

			public void OnResolve(IntPtr handle)
			{
				if (!_cancelled)
					Resolve(new NativeCamera(handle));
			}

			public void OnReject(string msg)
			{
				if (!_cancelled)
					Reject(new Exception(msg));
			}

			bool _cancelled = false;
			public override void Cancel(bool shutdownGracefully = false)
			{
				if (!_cancelled)
				{
					NativeCamera.Dispose(DisposeHandle);
					DisposeHandle = IntPtr.Zero;
					_cancelled = true;
				}
			}
		}

		public static Future<NativeCamera> Load(ObjC.Object cameraPreview)
		{
			var p = new LoadClosure();
			p.DisposeHandle = LoadCameraView(cameraPreview, p.OnResolve, p.OnReject);
			return p;
		}

		class CapturePhotoClosure : CameraPromise<Photo>
		{
			public void OnResolve(IntPtr sampleBuffer, int orientation) { Resolve(new NativePhoto(sampleBuffer, orientation)); }
			public void OnReject(string msg) { Reject(new Exception(msg)); }
		}

		public Future<Photo> CapturePhoto()
		{
			var p = new CapturePhotoClosure();
			CapturePhoto(_handle, p.OnResolve, p.OnReject);
			return p;
		}

		class StartRecordingClosure : CameraPromise<RecordingSession>
		{
			Action<IDisposable> _setRecordingSession;

			public StartRecordingClosure(Action<IDisposable> setRecordingSession)
			{
				_setRecordingSession = setRecordingSession;
			}

			public void OnResolve(ObjC.Object recordingSession)
			{
				var s = new NativeRecordingSession(recordingSession);
				_setRecordingSession(s);
				Resolve(s);
			}

			public void OnReject(string msg) { Reject(new Exception(msg)); }
		}

		IDisposable _recordingSession = null;
		void SetRecordingSession(IDisposable recordingSession)
		{
			_recordingSession = recordingSession;
		}

		public Future<RecordingSession> StartRecording()
		{
			var p = new StartRecordingClosure(SetRecordingSession);
			StartRecording(_handle, p.OnResolve, p.OnReject);
			return p;
		}

		class SetCaptureModeClosure : CameraPromise<CaptureMode>
		{
			public void OnResolve(int captureMode) { Resolve(IntToCaptureMode(captureMode)); }
			public void OnReject(string msg) { Reject(new Exception(msg)); }
		}

		public Future<CaptureMode> SetCaptureMode(CaptureMode mode)
		{
			var p = new SetCaptureModeClosure();
			SetCaptureMode(_handle, CaptureModeToInt(mode), p.OnResolve, p.OnReject);
			return p;
		}

		class SetCameraFacingClosure : CameraPromise<CameraFacing>
		{
			public void OnResolve(int cameraFacing) { Resolve(IntToCameraFacing(cameraFacing)); }
			public void OnReject(string msg) { Reject(new Exception(msg)); }
		}

		public Future<CameraFacing> SetCameraFacing(CameraFacing facing)
		{
			var p = new SetCameraFacingClosure();
			SetCameraFacing(_handle, CameraFacingToInt(facing), p.OnResolve, p.OnReject);
			return p;
		}

		class SetCameraFocusPointClosure : CameraPromise<Nothing> 
		{
			public void OnResolve(Nothing nothing) { Resolve(default(Nothing)); }
			public void OnReject(string msg) { Reject(new Exception(msg)); }
		}

		public Future<Nothing> SetCameraFocusPoint(double x, double y, int cameraWidth, int cameraHeight, int isFocusLocked) 
		{
			var p = new SetCameraFocusPointClosure();
			SetCameraFocusPoint(_handle, x, y, cameraWidth, cameraHeight, isFocusLocked, p.OnResolve, p.OnReject);
			return p;
		}

		class SetFlashModeClosure : CameraPromise<FlashMode>
		{
			public void OnResolve(int flashMode) { Resolve(IntToFlashMode(flashMode)); }
			public void OnReject(string msg) { Reject(new Exception(msg)); }
		}

		public Future<FlashMode> SetFlashMode(FlashMode flashMode)
		{
			var p = new SetFlashModeClosure();
			SetFlashMode(_handle, FlashModeToInt(flashMode), p.OnResolve, p.OnReject);
			return p;
		}

		class GetCameraInfoClosure : CameraPromise<CameraInfo>
		{
			public void OnResolve(int captureMode, int flashMode, int cameraFacing, ObjC.Object supportedFlashModes)
			{
				Resolve(new CameraInfo(
					IntToFlashMode(flashMode),
					IntToCameraFacing(cameraFacing),
					IntToCaptureMode(captureMode),
					new int2[0],
					GetFlashModes(supportedFlashModes)));
			}

			static FlashMode[] GetFlashModes(ObjC.Object array)
			{
				var len = NSArrayLength(array);
				var result = new FlashMode[len];
				for (var i = 0; i < len; i++)
					result[i] = (FlashMode)NSArrayGetElement(array, i);
				return result;
			}

			[Foreign(Language.ObjC)]
			static int NSArrayLength(ObjC.Object array)
			@{
				return (int)((NSArray*)array).count;
			@}

			[Require("Source.Include", "iOS/CameraViewImpl.h")]
			[Foreign(Language.ObjC)]
			static int NSArrayGetElement(ObjC.Object array, int index)
			@{
				return [(NSArray<NSNumber*>*)array objectAtIndex:index].intValue;
			@}
		}

		public Future<CameraInfo> GetCameraInfo()
		{
			var p = new GetCameraInfoClosure();
			GetCameraInfo(_handle, p.OnResolve);
			return p;
		}

		class iOSPhotoOptionPromise : PhotoOptionPromise
		{
			protected override void Visit(PhotoResolution photoResolution)
			{
				throw new Exception("PhotoResolution option not supported on iOS");
			}
		}

		public Future<PhotoOption[]> SetPhotoOptions(PhotoOption[] options)
		{
			return new iOSPhotoOptionPromise().Visit(options);
		}

		public void Dispose()
		{
			if (_recordingSession != null)
			{
				_recordingSession.Dispose();
				_recordingSession = null;
			}

			if (_handle != IntPtr.Zero)
			{
				Dispose(_handle);
				_handle = IntPtr.Zero;
			}
		}

		[Foreign(Language.ObjC)]
		static void CapturePhoto(IntPtr handle, Action<IntPtr,int> onResolve, Action<string> onReject)
		@{
			fcv::capturePhoto((fcv::CameraView*)handle, onResolve, onReject);
		@}

		[Foreign(Language.ObjC)]
		static void StartRecording(IntPtr handle, Action<ObjC.Object> onResolve, Action<string> onReject)
		@{
			fcv::startRecording((fcv::CameraView*)handle, onResolve, onReject);
		@}

		[Foreign(Language.ObjC)]
		static void SetCaptureMode(IntPtr handle, int captureMode, Action<int> onResolve, Action<string> onReject)
		@{
			fcv::setCaptureMode((fcv::CameraView*)handle, captureMode, onResolve, onReject);
		@}

		[Foreign(Language.ObjC)]
		static void SetCameraFacing(IntPtr handle, int cameraFacing, Action<int> onResolve, Action<string> onReject)
		@{
			fcv::setCameraFacing((fcv::CameraView*)handle, cameraFacing, onResolve, onReject);
		@}

		[Foreign(Language.ObjC)]
		static void SetCameraFocusPoint(IntPtr handle, double x, double y, int cameraWidth, int cameraHeight, int isFocusLocked, Action<Nothing> onResolve, Action<string> onReject) 
		@{
			fcv::setCameraFocusPoint((fcv::CameraView*)handle, x, y, cameraWidth, cameraHeight, isFocusLocked, onResolve, onReject);
		@}

		[Foreign(Language.ObjC)]
		static void SetFlashMode(IntPtr handle, int flashMode, Action<int> onResolve, Action<string> onReject)
		@{
			fcv::setFlashMode((fcv::CameraView*)handle, flashMode, onResolve, onReject);
		@}

		[Foreign(Language.ObjC)]
		static IntPtr LoadCameraView(ObjC.Object cameraPreview, Action<IntPtr> onResolve, Action<string> onReject)
		@{
			return fcv::loadCameraView((CameraPreview*)cameraPreview, onResolve, onReject);
		@}

		[Foreign(Language.ObjC)]
		static void GetCameraInfo(IntPtr handle, Action<int,int,int,ObjC.Object> callback)
		@{
			fcv::getCameraInfo((fcv::CameraView*)handle, ^(fcv::CameraInfo cameraInfo) {
				callback(cameraInfo.captureMode, cameraInfo.flashMode, cameraInfo.cameraFacing, cameraInfo.supportedFlashModes);
			});
		@}

		[Foreign(Language.ObjC)]
		static void Dispose(IntPtr handle)
		@{
			fcv::dispose((fcv::disposable_t)handle);
		@}

		static CaptureMode IntToCaptureMode(int captureMode)
		{
			if (captureMode == CaptureModePhoto)
				return CaptureMode.Photo;
			else if (captureMode == CaptureModeVideo)
				return CaptureMode.Video;
			else
				throw new Exception("Invalid CaptureMode: " + captureMode);
		}

		static int CaptureModeToInt(CaptureMode captureMode)
		{
			switch (captureMode)
			{
				case CaptureMode.Photo:
					return CaptureModePhoto;
				case CaptureMode.Video:
					return CaptureModeVideo;
				default:
					throw new Exception("Unexpected CaptureMode: " + captureMode);
			}
		}

		static CameraFacing IntToCameraFacing(int cameraFacing)
		{
			if (cameraFacing == CameraFacingFront)
				return CameraFacing.Front;
			else if (cameraFacing == CameraFacingBack)
				return CameraFacing.Back;
			else
				throw new Exception("Invalid CameraFacing: " + cameraFacing);
		}

		static int CameraFacingToInt(CameraFacing cameraFacing)
		{
			switch(cameraFacing)
			{
				case CameraFacing.Front:
					return CameraFacingFront;
				case CameraFacing.Back:
					return CameraFacingBack;
				default:
					throw new Exception("Unexpected CameraFacing: " + cameraFacing);
			}
		}

		static int FlashModeToInt(FlashMode flashMode)
		{
			switch (flashMode)
			{
				case FlashMode.Auto:
					return FlashModeAuto;
				case FlashMode.On:
					return FlashModeOn;
				case FlashMode.Off:
					return FlashModeOff;
				default:
					throw new Exception("Unexpected FlashMode: " + flashMode);
			}
		}

		static FlashMode IntToFlashMode(int flashMode)
		{
			if (flashMode == FlashModeAuto)
				return FlashMode.Auto;
			else if (flashMode == FlashModeOn)
				return FlashMode.On;
			else if (flashMode == FlashModeOff)
				return FlashMode.Off;
			else
				throw new Exception("Unexpected FlashMode: " + flashMode);
		}
	}

	[Require("Source.Include", "iOS/CameraPreview.h")]
	extern(iOS) class CameraView : Fuse.Controls.Native.iOS.View, ICameraView
	{
		ICameraViewHost _host;
		ObjC.Object _cameraPreview;

		[UXConstructor]
		public CameraView([UXParameter("Host")]ICameraViewHost host)
			: this(host, CreateCameraPreview()) { }

		CameraView(ICameraViewHost host, ObjC.Object cameraPreview)
			: base(cameraPreview)
		{
			_host = host;
			_cameraPreview = cameraPreview;
			_cameraFuture = NativeCamera.Load(_cameraPreview);
			_cameraFuture.Then(OnCameraResolved, OnCameraRejected);
		}

		Future<NativeCamera> _cameraFuture;

		NativeCamera _impl;

		void OnCameraResolved(NativeCamera impl)
		{
			if (_isDisposed)
			{
				impl.Dispose();
				return;
			}
			_impl = impl;
			_host.OnCameraLoaded(impl);
		}

		void OnCameraRejected(Exception e)
		{
			if (_isDisposed)
				return;
			_host.OnError(e);
		}

		bool _isDisposed = false;
		public override void Dispose()
		{
			if (_isDisposed)
				return;
			if (_impl == null)
				_cameraFuture.Cancel();
			base.Dispose();
			_host = null;
			if (_impl != null)
			{
				_impl.Dispose();
				_impl = null;
			}
			_isDisposed = true;
		}

		PreviewStretchMode ICameraView.PreviewStretchMode { set { SetFillView(_cameraPreview, value == PreviewStretchMode.UniformToFill); } }

		[Foreign(Language.ObjC)]
		static ObjC.Object CreateCameraPreview()
		@{
			CameraPreview* preview = [[CameraPreview alloc] init];
			[preview setClipsToBounds:true];
			return preview;
		@}

		[Foreign(Language.ObjC)]
		static void SetFillView(ObjC.Object handle, bool fillView)
		@{
			((CameraPreview*)handle).fillView = fillView;
		@}
	}
}
