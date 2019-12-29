using Uno.UX;
using Fuse.Scripting;

namespace Fuse.Vibration
{
	/**
		@scriptmodule FuseJS/Vibration

		Allows you to use the device's vibration functionality.

		You need to add a reference to `"Fuse.Vibration"` in your project file to use this feature.

		## Example

		The following code vibrates the device for 0.8 seconds.

			var vibration = require('FuseJS/Vibration');
			vibration.vibrate(0.8);
			// works on iOS using TapticEngine
			vibration.vibrate('medium')
	*/
	[UXGlobalModule]
	public sealed class VibrationModule : NativeModule
	{
		static readonly VibrationModule _instance;

		public VibrationModule()
		{
			if(_instance != null) return;
			Resource.SetGlobalKey(_instance = this, "FuseJS/Vibration");
			AddMember(new NativeFunction("vibrate", Vibrate));
		}

		/**
			@scriptmethod vibrate(seconds)
			@param seconds (double) seconds the vibration should last. 1 = 10 seconds, 0.5 = 5 seconds or
			vibrationType (string) the type of vibration (works only on iOS using TapticEngine). Available vibrationType are : `soft`, `rigid`, `light`, `medium`, `heavy`, `success`, `warning`, `error`, `selection`
		*/
		static object[] Vibrate(Scripting.Context context, object[] args)
		{
			if (args.Length > 0)
			{
				var vibrationType = args[0] as string;
				if (vibrationType != null)
				{
					if (vibrationType == "soft")
						Fuse.Vibration.Vibration.Feedback(VibrationType.Soft);
					else if (vibrationType == "rigid")
						Fuse.Vibration.Vibration.Feedback(VibrationType.Rigid);
					else if (vibrationType == "light")
						Fuse.Vibration.Vibration.Feedback(VibrationType.Light);
					else if (vibrationType == "medium")
						Fuse.Vibration.Vibration.Feedback(VibrationType.Medium);
					else if (vibrationType == "heavy")
						Fuse.Vibration.Vibration.Feedback(VibrationType.Heavy);
					else if (vibrationType == "success")
						Fuse.Vibration.Vibration.Feedback(VibrationType.Success);
					else if (vibrationType == "warning")
						Fuse.Vibration.Vibration.Feedback(VibrationType.Warning);
					else if (vibrationType == "error")
						Fuse.Vibration.Vibration.Feedback(VibrationType.Error);
					else if (vibrationType == "selection")
						Fuse.Vibration.Vibration.Feedback(VibrationType.Selection);
					else
						Fuse.Vibration.Vibration.Feedback(VibrationType.Soft);
				}
				else
				{
					var seconds = Marshal.ToDouble(args[0]);
					Fuse.Vibration.Vibration.Vibrate(seconds);
				}
			}
			else
				Fuse.Vibration.Vibration.Vibrate(0.4);
			return null;
		}
	}
}
