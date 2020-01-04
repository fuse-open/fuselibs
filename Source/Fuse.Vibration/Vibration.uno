using Uno.Permissions;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Vibration
{
	public enum VibrationType
	{
		Undefined,
		Soft,
		Rigid,
		Light,
		Medium,
		Heavy,
		Success,
		Warning,
		Error,
		Selection
	}

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

	[Require("Source.Include", "UIKit/UIKit.h")]
	[Require("Xcode.Framework", "AudioToolbox")]
	[ForeignInclude(Language.ObjC, "AudioToolbox/AudioToolbox.h")]
	extern(iOS) class IOSTapticFeedback
	{
		public static extern(iOS) void Perform(VibrationType style)
		{
			switch (style)
			{
				case VibrationType.Soft:
					PerformSoft();
					break;
				case VibrationType.Rigid:
					PerformRigid();
					break;
				case VibrationType.Light:
					PerformLight();
					break;
				case VibrationType.Medium:
					PerformMedium();
					break;
				case VibrationType.Heavy:
					PerformHeavy();
					break;
				case VibrationType.Success:
					PerformSuccess();
					break;
				case VibrationType.Warning:
					PerformWarning();
					break;
				case VibrationType.Error:
					PerformError();
					break;
				case VibrationType.Selection:
					PerformSelection();
					break;
				default:
					PerformLight();
					break;

			}
		}

		[Foreign(Language.ObjC)]
		static extern(iOS) void PerformSoft()
		@{
		#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
			dispatch_async(dispatch_get_main_queue(), ^{
				UIImpactFeedbackGenerator * feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleSoft];
				[feedback impactOccurred];
			});
		#else
			AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
		#endif
		@}

		[Foreign(Language.ObjC)]
		static extern(iOS) void PerformRigid()
		@{
		#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
			dispatch_async(dispatch_get_main_queue(), ^{
				UIImpactFeedbackGenerator * feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleRigid];
				[feedback impactOccurred];
			});
		#else
			AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
		#endif
		@}

		[Foreign(Language.ObjC)]
		static extern(iOS) void PerformLight()
		@{
		#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
			dispatch_async(dispatch_get_main_queue(), ^{
				UIImpactFeedbackGenerator * feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
				[feedback impactOccurred];
			});
		#else
			AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
		#endif
		@}

		[Foreign(Language.ObjC)]
		static extern(iOS) void PerformMedium()
		@{
		#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
			dispatch_async(dispatch_get_main_queue(), ^{
				UIImpactFeedbackGenerator * feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
				[feedback impactOccurred];
			});
		#else
			AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
		#endif
		@}

		[Foreign(Language.ObjC)]
		static extern(iOS) void PerformHeavy()
		@{
		#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
			dispatch_async(dispatch_get_main_queue(), ^{
				UIImpactFeedbackGenerator * feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
				[feedback impactOccurred];
			});
		#else
			AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
		#endif
		@}

		[Foreign(Language.ObjC)]
		static extern(iOS) void PerformSuccess()
		@{
		#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
			dispatch_async(dispatch_get_main_queue(), ^{
				UINotificationFeedbackGenerator * feedback = [[UINotificationFeedbackGenerator alloc] init];
				[feedback notificationOccurred:UINotificationFeedbackTypeSuccess];
			});
		#else
			AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
		#endif
		@}

		[Foreign(Language.ObjC)]
		static extern(iOS) void PerformWarning()
		@{
		#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
			dispatch_async(dispatch_get_main_queue(), ^{
				UINotificationFeedbackGenerator * feedback = [[UINotificationFeedbackGenerator alloc] init];
				[feedback notificationOccurred:UINotificationFeedbackTypeWarning];
			});
		#else
			AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
		#endif
		@}

		[Foreign(Language.ObjC)]
		static extern(iOS) void PerformError()
		@{
		#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
			dispatch_async(dispatch_get_main_queue(), ^{
				UINotificationFeedbackGenerator * feedback = [[UINotificationFeedbackGenerator alloc] init];
				[feedback notificationOccurred:UINotificationFeedbackTypeError];
			});
		#else
			AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
		#endif
		@}

		[Foreign(Language.ObjC)]
		static extern(iOS) void PerformSelection()
		@{
		#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
			dispatch_async(dispatch_get_main_queue(), ^{
				UISelectionFeedbackGenerator * feedback = [[UISelectionFeedbackGenerator alloc] init];
				[feedback selectionChanged];
				[feedback prepare];
			});
		#else
			AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
		#endif
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

		public static extern(Android) void Feedback(VibrationType type)
		{
			Permissions.Request(Permissions.Android.VIBRATE).Then(new AndroidVibrator(0.4).Done);
		}

		public static extern(iOS) void Feedback(VibrationType type)
		{
			IOSTapticFeedback.Perform(type);
		}

		public static extern(!MOBILE) void Vibrate(double seconds) { }

		public static extern(!MOBILE) void Feedback(VibrationType type) { }
	}
}
