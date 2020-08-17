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

	public enum ScreenOrientation
	{
		Portrait,
		LandscapeLeft,
		LandscapeRight,
		PortraitUpsideDown,
		Default
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
		static public event Action<ScreenOrientation> DeviceOrientationChanged;
		static public event Action<float> TextScaleFactorChanged;

		static float4 _deviceMargins = float4(0);
		static float4 _safeMargins = float4(0);
		static float4 _staticMargins = float4(0);
		static float _textScaleFactor = 1.0f;

		static public float TextScaleFactor
		{
			get { return _textScaleFactor; }
			private set
			{
				if (_textScaleFactor != value)
				{
					_textScaleFactor = value;
					if (TextScaleFactorChanged != null)
						TextScaleFactorChanged(value);
				}
			}
		}

		/**
			The margins the device reports as not being complete safe for drawing as something may obstruct the view, such as rounded corners or bevels.

			The units are the natural units of the native SDK, such that Viewport.PointsPerOSPoint would translate into Fuse points.
		*/
		static public float4 DeviceMargins
		{
			get { return _deviceMargins; }
		}

		/**
			Margins that completely exclude all system controls, device margins, or anything else which makes the area unsafe for drawing.
		*/
		static public float4 SafeMargins
		{
			get { return _safeMargins; }
		}

		/**
			Like `SafeMargins` but does not include areas which are dynamically allocated for controls, such as a popup keyboard.
		*/
		static public float4 StaticMargins
		{
			get { return _staticMargins; }
		}


		extern(UNO_TEST) static internal void SetMargins( float4 device, float4 safe, float4 static_ )
		{
			_deviceMargins = device;
			_safeMargins = safe;
			_staticMargins = static_;

			if (MarginsChanged != null)
				MarginsChanged();
		}

		public static ScreenOrientation DeviceOrientation
		{
			get { return ScreenOrientation.Portrait; }
			set
			{
				if (DeviceOrientationChanged != null)
					DeviceOrientationChanged(value);
			}
		}
	}
}
