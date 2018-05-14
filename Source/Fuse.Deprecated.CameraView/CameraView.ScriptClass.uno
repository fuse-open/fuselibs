using Uno;
using Uno.Text;
using Uno.UX;
using Uno.Time;
using Uno.Threading;

using Fuse;
using Fuse.Controls;
using Fuse.Controls.Native;
using Fuse.Scripting;
using Fuse.ImageTools;

namespace Fuse.Deprecated
{
	public partial class CameraViewBase
	{
		class CurrentCameraDirectionProperty : Property<string>
		{
			readonly CameraViewBase _cvb;
			public override PropertyObject Object { get { return _cvb; } }
			public override bool SupportsOriginSetter { get { return false; } }
			public override string Get(PropertyObject obj)
			{
				if defined(iOS || Android)
				{
					var direction = "Back";
					lock(_cvb)
						direction = CameraDirectionToString(_cvb._out);
					return direction;
				}

				return string.Empty;
			}
			public override void Set(PropertyObject obj, string value, IPropertyListener origin)
			{
				if defined(iOS || Android)
				{
					var direction = CameraDirectionFromString(value);
					lock(_cvb)
						_cvb._in = direction;
					UpdateManager.PostAction(_cvb.UpdateCameraDirection);
					
				}
			}
			public CurrentCameraDirectionProperty(CameraViewBase cameraView) : base(CameraViewBase._cameraDirectionName) 
			{ 
				_cvb = cameraView; 
			}
		}

		class IsCurrentlyRecordingProperty : Property<string>
		{
			readonly CameraViewBase _cvb;
			public override PropertyObject Object { get { return _cvb; } }
			public override bool SupportsOriginSetter { get { return false; } }
			public override string Get(PropertyObject obj)
			{
				if defined(iOS || Android)
				{
					var isCurrentlyRecording = false;
					lock(_cvb)
						isCurrentlyRecording = _cvb._isCurrentlyRecording;

					return isCurrentlyRecording ? "Recording" : "NotRecording";
				}

				return string.Empty;
			}
			public override void Set(PropertyObject obj, string value, IPropertyListener origin) { return; }
			public IsCurrentlyRecordingProperty(CameraViewBase cameraView) : base(CameraViewBase._cameraIsRecordingName) 
			{ 
				_cvb = cameraView; 
			}
		}

		static CameraViewBase()
		{
			ScriptClass.Register(typeof(CameraViewBase),
				new ScriptProperty<CameraViewBase, string>("IsCurrentlyRecording", getIsCurrentlyRecordingProperty, ".notNull()"),
				new ScriptProperty<CameraViewBase, string>("CurrentCameraDirection", getCurrentCameraDirectionProperty, ".notNull()"),
				new ScriptMethod<CameraViewBase>("swapCamera", swapCamera, ExecutionThread.MainThread),
				new ScriptMethod<CameraViewBase>("startVideo", startVideo, ExecutionThread.MainThread),
				new ScriptMethod<CameraViewBase>("endVideo", endVideo, ExecutionThread.MainThread),
				new ScriptMethod<CameraViewBase>("takePicture", takePicture, ExecutionThread.MainThread),
				new ScriptMethod<CameraViewBase>("enableFlash", enableFlash, ExecutionThread.MainThread),
				new ScriptMethod<CameraViewBase>("disableFlash", disableFlash, ExecutionThread.MainThread)
				);
		}

		CurrentCameraDirectionProperty _currentDateProperty;
		/**
			@scriptproperty CurrentCameraDirection

			Observable string `Back` or `Front` representing the currently selected camera
		*/
		static Property<string> getCurrentCameraDirectionProperty(CameraViewBase cameraView)
		{
			if (cameraView._currentDateProperty == null)
				cameraView._currentDateProperty = new CurrentCameraDirectionProperty(cameraView);

			return cameraView._currentDateProperty;
		}

		IsCurrentlyRecordingProperty _currentlyRecordingProperty;
		/**
			@scriptproperty IsCurrentlyRecording

			Observable string `Recording` while video is being recorded, otherwise `NotRecording`
		*/
		static Property<string> getIsCurrentlyRecordingProperty(CameraViewBase cameraView)
		{
			if (cameraView._currentlyRecordingProperty == null)
				cameraView._currentlyRecordingProperty = new IsCurrentlyRecordingProperty(cameraView);

			return cameraView._currentlyRecordingProperty;
		}
		
		/**
			@scriptmethod swapCamera()

			Changes the current camera view's camera to the opposite direction. If facing Front, it will now swap
			to the default `Back` camera and vice versa.
		*/
		static void swapCamera(Context context, CameraViewBase cameraView, object[] args)
		{
			if defined(iOS || Android)
				cameraView.SwapCamera();
		}

		/**
			@scriptmethod takePicture(args)

			Take a picture from the current camera view. The picture is stored in a temp folder.
			A callback must be given which will be given two arguments - the first, an error object, 
			the second, the image object. If the camera is already recording, the recording will stop.

			`args` is a plain JavaScript object that holds a mandatory `callback` function that is called with the resulting image object, and an optional `resolution` property that can be set to `"Full"` (default is `"Preview"`)

			```
				cameraView.takePicture({
					callback: function(err, image){
						if (err){
							console.error(err);
							return;
						}

						doThingsWithImage(image);
					}
				});
			```
		*/
		static void takePicture(Context context, CameraViewBase cameraView, object[] args)
		{
			if (args.Length < 1) 
			{
				Diagnostics.UserError("CameraView.takePicture(): must provide exactly 1 argument.", cameraView);
				return;
			}
			var obj = args[0] as Fuse.Scripting.Object;

			if (obj == null)
			{
				Diagnostics.UserError("CameraView.takePicture(): argument must be a object.", cameraView);
				return;
			}

			var resolutionMode = PictureResolution.Preview;
			Fuse.Scripting.Function callback = null;

			if (obj.ContainsKey("resolution"))
			{
				if ((obj["resolution"] as string) == "Full")
				{
					resolutionMode = PictureResolution.Full;
				}
			}

			if (obj.ContainsKey("callback"))
			{
				callback = obj["callback"] as Function;
			}

			if (callback == null)
			{
				Diagnostics.UserError("CameraView.takePicture(): callback must be a function!", cameraView);
				return;
			}

			if defined(iOS || Android)
				cameraView.SavePicture(new ImagePromiseCallback(callback, context), resolutionMode);
			else 
				callback.Call(context, "Not supported on this platform!", null);
		}

		/**
			@scriptmethod startVideo()

			Start recording a video from the current camera. Will stop any recording that is currently
			happening, in order to ensure platform-compatiblity.
		*/
		static void startVideo(Context context, CameraViewBase cameraView, object[] args)
		{
			if defined(iOS || Android)
				cameraView.StartRecording();
		}

		/**
			@scriptmethod endVideo(args)

			Stop recording a video. Stores the video in a temporary path.
			Must take a callback that takes an error and a video path.

			`args` is a plain JavaScript function that is called with the resulting video file path

			```
				var VideoTools = require("FuseJS/VideoTools");
				cameraView.endVideo(function(err, path){
					if (err){
						console.error(err);
						return;
					}

					VideoTools.copyVideoToCameraRoll(path);
				});
			```
		*/
		static void endVideo(Context context, CameraViewBase cameraView, object[] args)
		{
			if (args.Length != 1) 
			{
				Diagnostics.UserError("CameraView.endVideo(): must provide exactly 1 argument.", cameraView);
				return;
			}
			var callback = args[0] as Function;

			if (callback == null)
			{
				Diagnostics.UserError("CameraView.endVideo(): argument must be a function.", cameraView);
				return;
			}

			if defined(iOS || Android)
				cameraView.StopRecording(new VideoPromiseCallback(callback, context));
			else 
				callback.Call(context, "Not supported on this platform", null);
		}

		/**
			@scriptmethod enableFlash()

			Turn on the flash on device.
		*/
		static void enableFlash(Context context, CameraViewBase cameraView, object[] args)
		{
			cameraView.UseFlash = true;
		}

		/**
			@scriptmethod disableFlash()
			
			Turn off the flash on device.
		*/
		static void disableFlash(Context context, CameraViewBase cameraView, object[] args)
		{
			cameraView.UseFlash = false;
		}

		static bool isDirectionSupported(Context context, CameraViewBase cameraView, object[] args)
		{
			var direction = args[0] as string;

			if (direction == null) return false;

			return CameraViewBase.IsDirectionSupported(CameraViewBase.CameraDirectionFromString(direction));
		}
	}
}