using Fuse.Scripting;

namespace Fuse.Controls
{
	public class CameraInfo
	{
		public const string FlashModeName = "flashMode";
		public const string CameraFacingName = "cameraFacing";
		public const string CaptureModeName = "captureMode";
		public const string PhotoResolutionsName = "photoResolutions";
		public const string SupportedFlashModesName = "supportedFlashModes";

		public readonly FlashMode FlashMode;
		public readonly CameraFacing CameraFacing;
		public readonly CaptureMode CaptureMode;
		public readonly int2[] PhotoResolutions;
		public readonly FlashMode[] SupportedFlashModes;

		public CameraInfo(
			FlashMode flashMode,
			CameraFacing cameraFacing,
			CaptureMode captureMode,
			int2[] photoResolutions,
			FlashMode[] supportedFlashModes)
		{
			FlashMode = flashMode;
			CameraFacing = cameraFacing;
			CaptureMode = captureMode;
			PhotoResolutions = photoResolutions;
			SupportedFlashModes = supportedFlashModes;
		}
	}
}
