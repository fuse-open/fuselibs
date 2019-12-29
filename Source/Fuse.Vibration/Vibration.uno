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
	class IOSTapticEngine
	{
		public static extern(iOS) void perform(VibrationType style)
		{
			switch (style)
			{
				case VibrationType.Soft:
					performSoft();
					break;
				case VibrationType.Rigid:
					performRigid();
					break;
				case VibrationType.Light:
					performLight();
					break;
				case VibrationType.Medium:
					performMedium();
					break;
				case VibrationType.Heavy:
					performHeavy();
					break;
				case VibrationType.Success:
					performSuccess();
					break;
				case VibrationType.Warning:
					performWarning();
					break;
				case VibrationType.Error:
					performError();
					break;
				case VibrationType.Selection:
					performSelection();
					break;
				default:
					performLight();
					break;

			}
		}

		[Foreign(Language.ObjC)]
		static extern(iOS) void performSoft()
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
		static extern(iOS) void performRigid()
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
		static extern(iOS) void performLight()
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
		static extern(iOS) void performMedium()
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
		static extern(iOS) void performHeavy()
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
		static extern(iOS) void performSuccess()
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
		static extern(iOS) void performWarning()
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
		static extern(iOS) void performError()
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
		static extern(iOS) void performSelection()
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
			IOSTapticEngine.perform(type);
		}

		public static extern(!MOBILE) void Vibrate(double seconds) { }

		public static extern(!MOBILE) void Feedback(VibrationType type) { }
	}
}
