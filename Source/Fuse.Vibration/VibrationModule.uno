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
			@param seconds (double) seconds the vibration should last. 1 = 10 seconds, 0.5 = 5 seconds
		*/
		static object[] Vibrate(Scripting.Context context, object[] args)
		{
			var seconds = (args.Length > 0) ? Marshal.ToDouble(args[0]) : 0.4;
			Fuse.Vibration.Vibration.Vibrate(seconds);
			return null;
		}
	}
}
