using Uno.Threading;
using Uno;
using Uno.UX;
using Fuse.Scripting;
using Fuse.Scripting.JSObjectUtils;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Controls;

namespace Fuse.Deprecated
{
	internal class CameraDevice
	{
		/** A class of static functions for getting device information related to the Camera
		*/
		public static CameraDirection[] SupportedDirections
		{
			get 
			{
				int lowlevel = 0; 

				if defined(iOS)
					lowlevel = iOSCameraDevice.GetSupportedDirections();
				else if defined (Android)
					lowlevel = AndroidCameraDevice.GetSupportedDirections();

				if (lowlevel == 0)
					return new CameraDirection[] {};
				else if (lowlevel == 1)
					return new CameraDirection[] { CameraDirection.Front };
				else if (lowlevel == 2)
					return new CameraDirection[] { CameraDirection.Back };

				return new CameraDirection[] { CameraDirection.Front, CameraDirection.Back };
				
			}
		}

		extern (iOS) internal class iOSCameraDevice 
		{
			[Require("Xcode.Framework", "AssetsLibrary")]
			[Require("Source.Include", "AVFoundation/AVFoundation.h")]
			[Foreign(Language.ObjC)]
			extern (iOS) public static int GetSupportedDirections()
			@{
				int retVal = 0;
				BOOL hasFront = false;
				BOOL hasBack = false;

				NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
				for (AVCaptureDevice *device in devices) 
				{
					if ([device position] == AVCaptureDevicePositionFront) 
					{
						hasFront = true;
					} 
					else if ([device position] == AVCaptureDevicePositionBack)
					{
						hasBack = true;
					}
				}

				// retVal meanings
				// 0 - Nothing supported
				// 1 - Only Front Supported
				// 2 - Only Back Supported
				// 3 - Both Supported
				if (hasFront) retVal += 1;
				if (hasBack) retVal += 2;

				return retVal;
			@}
		}

		[ForeignInclude(Language.Java, "android.hardware.Camera")]
		extern (Android) internal class AndroidCameraDevice
		{
			[Foreign(Language.Java)]
			extern (Android) public static int GetSupportedDirections()
			@{
				boolean hasFront = false;
				boolean hasBack = false;

				Camera.CameraInfo cameraInfo = new Camera.CameraInfo();

				for (int cameraId = 0; cameraId < Camera.getNumberOfCameras(); cameraId++)
				{
					Camera.getCameraInfo(cameraId, cameraInfo);

					if (cameraInfo.facing == Camera.CameraInfo.CAMERA_FACING_FRONT)
						hasFront = true;
					else if (cameraInfo.facing == Camera.CameraInfo.CAMERA_FACING_BACK)
						hasBack = true;
				}

				// retVal meanings
				// 0 - Nothing supported
				// 1 - Only Front Supported
				// 2 - Only Back Supported
				// 3 - Both Supported
				int retVal = 0;

				if (hasFront) retVal += 1;
				if (hasBack) retVal += 2;
				return retVal;
			@}
		}
	}
}
