using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.Platform2;
using Fuse.Platform;

namespace Fuse.Platform
{
	enum SystemUIResizeReason
	{
		WillShow,
		WillChangeFrame,
		WillHide,
	}

	enum SysUIState // was SystemUI.UIState
	{
		Normal = 0,
		StatusBarHidden = 1,
		Fullscreen = 2,
	}

	/**
		Abstract system details about the UI of the target device.
		
		This desktop version serves as the documentation for what is expected from the platform backends.
	*/
	static extern(!iOS && !Android) class SystemUI
	{
		/**
			Emitted whenever one of the `...Margins` property changes.
		*/
		static public event Action MarginsChanged;
		
		/**
			The margins the device reports as not being complete safe for drawing as something may obstruct the view, such as rounded corners or bevels.
			
			The units are the natural units of the native SDK, such that Viewport.PointsPerOSPoint would translate into Fuse points.
		*/
		static public float4 DeviceMargins
		{
			get { return float4(0); }
		}
		
		/**
			Margins that completely exclude all system controls, device margins, or anything else which makes the area unsafe for drawing.
		*/
		static public float4 SafeMargins
		{
			get { return float4(0); }
		}

		/**
			Like `SafeMargins` but does not include areas which are dynamically allocated for controls, such as a popup keyboard.
		*/
		static public float4 StaticMargins
		{
			get { return float4(0); }
		}
	}
}
