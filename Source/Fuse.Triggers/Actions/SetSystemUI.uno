using Uno;
using Fuse.Platform;

namespace Fuse.Triggers.Actions
{
	/**
		Set Screen Orientation

		## Example

			<Page>
				<Activated>
					<SetWindowOrientation To="LandscapeLeft" />
				</Activated>
			</Page>
	*/
	public class SetWindowOrientation : TriggerAction
	{
		/* Target Orientation */
		public ScreenOrientation To
		{
			get; set;
		}

		protected override void Perform(Node n)
		{
			SystemUI.DeviceOrientation = To;
		}
	}

	/**
		Set Status Bar UI

		## Example

			<Page>
				<Activated>
					<SetStatusBarUI Style="Dark" Color="#FFF" IsVisible="true" />
				</Activated>
			</Page>
	*/
	public class SetStatusBarUI : TriggerAction
	{
		public SetStatusBarUI()
		{
			if defined(Android)
				_color = Uno.Color.FromArgb((uint)SystemUI.GetStatusBarColor());
			if defined(MOBILE)
				_isVisible = SystemUI.IsTopFrameVisible;
		}

		/** Set status bar style. */
		public StatusBarStyle Style
		{
			get; set;
		}

		float4 _color = Float4.Identity;
		/** Set status bar color. */
		public float4 Color
		{
			get
			{
				return _color;
			}
			set
			{
				_color = value;
			}
		}

		bool _isVisible = true;
		/** Whether or not the status bar should be visible. */
		public bool IsVisible
		{
			get
			{
				return _isVisible;
			}
			set
			{
				_isVisible = value;
			}
		}

		protected override void Perform(Node n)
		{
			if defined(iOS)
				SystemUI.uStatusBarStyle = Style;
			if defined(Android)
			{
				switch (Style)
				{
					case StatusBarStyle.Dark:
					{
						SystemUI.SetDarkStatusBarStyle();
						break;
					}
					case StatusBarStyle.Light:
					{
						SystemUI.SetLightStatusBarStyle();
						break;
					}
				}
				if (_color != Uno.Color.FromArgb((uint)SystemUI.GetStatusBarColor()))
					SystemUI.SetStatusBarColor((int)Uno.Color.ToArgb(_color));
			}
			if defined(MOBILE)
				if (_isVisible != SystemUI.IsTopFrameVisible)
					SystemUI.IsTopFrameVisible = _isVisible;
		}
	}
}
