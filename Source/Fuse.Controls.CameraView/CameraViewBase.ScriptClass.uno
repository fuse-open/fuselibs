using Uno;
using Uno.UX;
using Uno.Time;
using Uno.Compiler.ExportTargetInterop;
using Uno.Threading;
using Uno.Collections;

using Fuse;
using Fuse.Controls;
using Fuse.Controls.Native;
using Fuse.Scripting;

namespace Fuse.Controls
{
	/**
		@include Docs/README.md
	*/
	public partial class CameraViewBase
	{
		const string InfoPhotoResolutions = "photoResolutions";

		static CameraViewBase()
		{
			ScriptClass.Register(typeof(CameraViewBase),
				new ScriptPromise<CameraViewBase,Photo,object>("capturePhoto", ExecutionThread.MainThread, capturePhoto, ConvertPhoto),
				new ScriptPromise<CameraViewBase,RecordingSession,object>("startRecording", ExecutionThread.MainThread, startRecording, ConvertRecordingSession),
				new ScriptPromise<CameraViewBase,CaptureMode,object>("setCaptureMode", ExecutionThread.MainThread, setCaptureMode, ConvertCaptureMode),
				new ScriptPromise<CameraViewBase,CameraFacing,object>("setCameraFacing", ExecutionThread.MainThread, setCameraFacing, ConvertCameraFacing),
				new ScriptPromise<CameraViewBase,Nothing,object>("setCameraFocusPoint", ExecutionThread.MainThread, setCameraFocusPoint),
				new ScriptPromise<CameraViewBase,FlashMode,object>("setFlashMode", ExecutionThread.MainThread, setFlashMode, ConvertFlashMode),
				new ScriptPromise<CameraViewBase,CameraInfo,object>("getCameraInfo", ExecutionThread.MainThread, getCameraInfo, ConvertCameraInfo),
				new ScriptPromise<CameraViewBase,PhotoOption[],object>("setPhotoOptions", ExecutionThread.JavaScript, setPhotoOptions, ConvertPhotoOptions),
				new ScriptReadonlyProperty("CAPTURE_MODE_PHOTO", EnumHelpers.AsString(CaptureMode.Photo)),
				new ScriptReadonlyProperty("CAPTURE_MODE_VIDEO", EnumHelpers.AsString(CaptureMode.Video)),
				new ScriptReadonlyProperty("CAMERA_FACING_FRONT", EnumHelpers.AsString(CameraFacing.Front)),
				new ScriptReadonlyProperty("CAMERA_FACING_BACK", EnumHelpers.AsString(CameraFacing.Back)),
				new ScriptReadonlyProperty("FLASH_MODE_AUTO", EnumHelpers.AsString(FlashMode.Auto)),
				new ScriptReadonlyProperty("FLASH_MODE_ON", EnumHelpers.AsString(FlashMode.On)),
				new ScriptReadonlyProperty("FLASH_MODE_OFF", EnumHelpers.AsString(FlashMode.Off)),
				new ScriptReadonlyProperty("OPTION_PHOTO_RESOLUTION", PhotoResolution.Name),
				new ScriptReadonlyProperty("INFO_FLASH_MODE", CameraInfo.FlashModeName),
				new ScriptReadonlyProperty("INFO_CAMERA_FACING", CameraInfo.CameraFacingName),
				new ScriptReadonlyProperty("INFO_CAPTURE_MODE", CameraInfo.CaptureModeName),
				new ScriptReadonlyProperty("INFO_PHOTO_RESOLUTIONS", CameraInfo.PhotoResolutionsName),
				new ScriptReadonlyProperty("INFO_SUPPORTED_FLASH_MODES", CameraInfo.SupportedFlashModesName));
		}

		/**
			Capture photo

			@scriptmethod capturePhoto()

			Returns a Promise that resolves to a @Fuse.Controls.Photo. The `CaptureMode` must be set to `CAPTURE_MODE_PHOTO`.
			`photo` holds onto the resrouces representing the captured photo, when you are done using it you must
			call `release()`. This will free up the resources. Its considered bad practice to keep more than one
			photo around, this might cause memory usage problems on weaker devices.

				<CameraView ux:Name="Camera" />
				<JavaScript>
					Camera.capturePhoto()
						.then(function(photo) {
							photo.release();
						})
						.catch(function(error) { });
				</JavaScript>
		*/
		static Future<Photo> capturePhoto(Context context, CameraViewBase self, object[] args)
		{
			return self.CapturePhoto();
		}

		/**
			Start video recording

			@scriptmethod startRecording()

			Returns a promise that resolves to a @Fuse.Controls.RecordingSession. The `CaptureMode` must be set to `CAPTURE_MODE_VIDEO`

				<CameraView ux:Name="Camera" />
				<JavaScript>
					Camera.capturePhoto()
						.then(function(recordingSession) { })
						.catch(function(error) { });
				</JavaScript>
		*/
		static Future<RecordingSession> startRecording(Context context, CameraViewBase self, object[] args)
		{
			return self.StartRecording();
		}

		/**
			Set CaptureMode

			@scriptmethod setCaptureMode( captureMode )

			Returns a promise that resolves to the new `CaptureMode`. The values for `CaptureMode` can be found
			as constants on the `CameraView`. Valid values are `CAPTURE_MODE_PHOTO` and `CAPTURE_MODE_VIDEO`

				<CameraView ux:Name="Camera" />
				<JavaScript>
					Camera.setCaptureMode(Camera.CAPTURE_MODE_PHOTO)
						.then(function(newCaptureMode) {  })
						.catch(function(error) { });
				</JavaScript>
		*/
		static Future<CaptureMode> setCaptureMode(Context context, CameraViewBase self, object[] args)
		{
			if (args.Length != 1)
				return new Promise<CaptureMode>().RejectWithMessage("An argument for CaptureMode must be provided");

			var arg = args[0] as string;
			if (arg != null)
				return self.SetCaptureMode(EnumHelpers.As<CaptureMode>(arg));
			else
				return new Promise<CaptureMode>().RejectWithMessage("Bad argument");
		}

		/**
			Set CameraFacing

			@scriptmethod setCameraFacing( cameraFacing )

			Returns a promise that resolves to the new `CameraFacing`. The values for `CameraFacing` can be found
			as constants on the `CameraView`. Valid values are `CAMERA_FACING_BACK` and `CAMERA_FACING_BACK`

				<CameraView ux:Name="Camera" />
				<JavaScript>
					Camera.setCameraFacing(Camera.CAMERA_FACING_FRONT)
						.then(function(newCameraFacing) {  })
						.catch(function(error) { });
				</JavaScript>
		*/
		static Future<CameraFacing> setCameraFacing(Context context, CameraViewBase self, object[] args)
		{
			if (args.Length != 1)
				return new Promise<CameraFacing>().RejectWithMessage("An argument for CameraFacing must be provided");

			var arg = args[0] as string;
			if (arg != null)
				return self.SetCameraFacing(EnumHelpers.As<CameraFacing>(arg));
			else
				return new Promise<CameraFacing>().RejectWithMessage("Bad argument");
		}

		/**
			Set CameraFocusPoint

			@scriptmethod setCameraFocusPoint( x, y, cameraWidth, cameraHeight, isFocusLocked )

			Returns a promise of nothing. Valid values are double x, double y, int cameraWidth, int cameraHeight and int isFocusLocked.

				<CameraView ux:Name="Camera" />
				<JavaScript>
					Camera.setCameraFocusPoint(x, y, cameraWidth, cameraHeight, isFocusLocked)
						.then(function(isSet) {  })
						.catch(function(error) { });
				</JavaScript>
		*/
		static Future<Nothing> setCameraFocusPoint(Context context, CameraViewBase self, object[] args) 
		{
			if (args.Length != 5)
				return new Promise<Nothing>().RejectWithMessage("Arguments for CameraFocusPoint must be provided");

			return self.SetCameraFocusPoint( 
				Marshal.ToDouble(args[0]), Marshal.ToDouble(args[1]), 
				Marshal.ToInt(args[2]), Marshal.ToInt(args[3]), Marshal.ToInt(args[4]) 
			);
		}

		/**
			Set FlashMode

			@scriptmethod setFlashMode( flashMode )

			Returns a promise that resolves to the new `FlashMode`. The values for `FlashMode` can be found
			as constants on the `CameraView`. Valid values are `FLASH_MODE_AUTO`, `FLASH_MODE_ON` and `FLASH_MODE_OFF`

				<CameraView ux:Name="Camera" />
				<JavaScript>
					Camera.setFlashMode(Camera.FLASH_MODE_OFF)
						.then(function(newFlashMode) {  })
						.catch(function(error) { });
				</JavaScript>
		*/
		static Future<FlashMode> setFlashMode(Context context, CameraViewBase self, object[] args)
		{
			if (args.Length != 1)
				return new Promise<FlashMode>().RejectWithMessage("An argument for FlashMode must be provided");

			var arg = args[0] as string;
			if (arg != null)
				return self.SetFlashMode(EnumHelpers.As<FlashMode>(arg));
			else
				return new Promise<FlashMode>().RejectWithMessage("Bad argument");
		}

		/**
			Get CameraInfo

			@scriptmethod getCameraInfo()

			Returns a promise that resolves to an object containing information about the camera state. The object will always
			contain the current FlashMode, CaptureMode and CameraFacing.

			This promise does not resolve until the camera is fully loaded. When the camera is loaded this promise resolves immediatley.

				<CameraView ux:Name="Camera" />
				<JavaScript>
					Camera.getCameraInfo()
						.then(function(info) {
							console.log(info[Camera.INFO_FLASH_MODE]);
							console.log(info[Camera.INFO_CAPTURE_MODE]);
							console.log(info[Camera.INFO_CAMERA_FACING]);
							console.log(info[Camera.INFO_SUPPORTED_FLASH_MODES].join());
						})
						.catch(function(error) { });
				</JavaScript>

			On Android the user should set the output resolution for photos, while on iOS you cannot set a specific resolution.
			In this abstraction we try to pick a sensible resolution based on the max width and height of OpenGL textures and
			the aspect of the camera preview. However you might want to configure this yourself. Due to this platform difference
			`getCameraInfo` will return additional information on Android, an array of available photo resolutions:

				<CameraView ux:Name="Camera" />
				<JavaScript>
					Camera.getCameraInfo()
						.then(function(info) {
							// check if INFO_PHOTO_RESOLUTIONS exists. It will not on iOS
							if (Camera.INFO_PHOTO_RESOLUTIONS in info) {
								info[Camera.INFO_PHOTO_RESOLUTIONS].forEach(function(e) {
									console.log(e.width + "x" + e.height);
								});
							}
						})
						.catch(function(error) { });
				</JavaScript>

		*/
		static Future<CameraInfo> getCameraInfo(Context context, CameraViewBase self, object[] args)
		{
			return self.GetCameraInfo();
		}

		class SetPhotoOptionsClosure : Promise<PhotoOption[]>
		{
			CameraViewBase _cameraViewBase;
			PhotoOption[] _options;

			public SetPhotoOptionsClosure(PhotoOption[] options, CameraViewBase cameraViewBase)
			{
				_options = options;
				_cameraViewBase = cameraViewBase;
				UpdateManager.PostAction(Dispatch);
			}

			void Dispatch()
			{
				_cameraViewBase.SetPhotoOptions(_options).Then(Resolve, Reject);
			}
		}

		/**
			Set PhotoOptions

			@scriptmethod setPhotoOptions( photoOptions )

			Returns a promise that resolves when the options are successfully set. Due to platform differences some
			options might not be valid on all platforms.

				<CameraView ux:Name="Camera" />
				<JavaScript>
					Camera.getCameraInfo()
						.then(function(info) {
							if ("photoResolutions" in info) {
								// photoResolutions is an array of supported resolutions, for example: { width: 1920, height: 1080 }
								var resolution = pick_appropriate_resolution(info["photoResolutions"]);
								var options = {};
								options[Camera.OPTION_PHOTO_RESOLUTION] = resolution;

								Camera.setPhotoOptions(options)
									.then(function() { })
									.catch(function(error) { });
							}
						})
				</JavaScript>

			As of now photo resolution is the only available option
		*/
		static Future<PhotoOption[]> setPhotoOptions(Context context, CameraViewBase self, object[] args)
		{
			if (args.Length != 1)
				return new Promise<PhotoOption[]>().RejectWithMessage("An argument with photo options must be provided");

			var obj = args[0] as Fuse.Scripting.Object;
			if (obj == null)
				return new Promise<PhotoOption[]>().RejectWithMessage("Invalid argument");

			PhotoOption[] options = null;

			try
			{
				options = PhotoOption.From(obj);
			}
			catch(Exception e)
			{
				var p = new Promise<PhotoOption[]>();
				p.Reject(e);
				return p;
			}

			return new SetPhotoOptionsClosure(options, self);
		}

		static object ConvertPhoto(Context c, Photo pictureResult)
		{
			return c.Unwrap(pictureResult);
		}

		static object ConvertRecordingSession(Context c, RecordingSession recordingSession)
		{
			return c.Unwrap(recordingSession);
		}

		static object ConvertCaptureMode(Context c, CaptureMode captureMode)
		{
			return EnumHelpers.AsString(captureMode);
		}

		static object ConvertCameraFacing(Context c, CameraFacing cameraFacing)
		{
			return EnumHelpers.AsString(cameraFacing);
		}

		static object ConvertFlashMode(Context c, FlashMode flashMode)
		{
			return EnumHelpers.AsString(flashMode);
		}

		static object ConvertCameraInfo(Context c, CameraInfo cameraInfo)
		{
			var dict = c.NewObject();
			dict[CameraInfo.FlashModeName] = ConvertFlashMode(c, cameraInfo.FlashMode);
			dict[CameraInfo.CaptureModeName] = ConvertCaptureMode(c, cameraInfo.CaptureMode);
			dict[CameraInfo.CameraFacingName] = ConvertCameraFacing(c, cameraInfo.CameraFacing);
			var sizes = cameraInfo.PhotoResolutions;
			if (sizes.Length > 0)
			{
				object[] values = new object[sizes.Length];
				for (var i = 0; i < sizes.Length; i++)
				{
					var obj = c.NewObject();
					obj["width"] = sizes[i].X;
					obj["height"] = sizes[i].Y;
					values[i] = obj;
				}
				dict[InfoPhotoResolutions] = c.NewArray(values);
			}
			var flashModes = cameraInfo.SupportedFlashModes;
			object[] f = new object[flashModes.Length];
			for (var i = 0; i < flashModes.Length; i++)
				f[i] = ConvertFlashMode(c, flashModes[i]);
			dict[CameraInfo.SupportedFlashModesName] = c.NewArray(f);
			return dict;
		}

		static object ConvertPhotoOptions(Context c, PhotoOption[] options)
		{
			return null;
		}
	}
}
