using Uno.Permissions;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Vibration
{
	[ForeignInclude(Language.Java,
					"android.os.Vibrator",
					"android.app.Activity",
					"android.content.Context")]
	class AndroidVibrator
	{
		double _seconds;

		public AndroidVibrator(double seconds)
		{
			_seconds = seconds;
		}

		[Foreign(Language.Java)]
		public extern(Android) void Done(PlatformPermission permission)
		@{
			Activity a = com.fuse.Activity.getRootActivity();
			Vibrator v = (Vibrator)a.getSystemService(Context.VIBRATOR_SERVICE);
			v.vibrate((long)(@{AndroidVibrator:Of(_this)._seconds} * 1000));
		@}
	}

	[Require("Xcode.Framework", "AudioToolbox")]
	[ForeignInclude(Language.ObjC, "AudioToolbox/AudioToolbox.h")]
	public static class Vibration
	{
		public static extern(Android) void Vibrate(double seconds)
		{
			Permissions.Request(Permissions.Android.VIBRATE).Then(new AndroidVibrator(seconds).Done);
		}

		[Foreign(Language.ObjC)]
		public static extern(iOS) void Vibrate(double seconds)
		@{
			AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
		@}

		public static extern(!MOBILE) void Vibrate(double seconds) { }
	}
}
