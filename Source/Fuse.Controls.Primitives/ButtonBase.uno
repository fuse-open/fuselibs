using Uno;
using Uno.UX;
using Fuse.Controls.Native;

namespace Fuse.Controls
{

	/** Baseclass for buttons
	
		ButtonBase is the undecorated baseclass for buttons in fuse. Can be used to make
		ux classes for buttons that has text.

		## Example:

			<ButtonBase ux:Class="GradientButton" Margin="2">
				<Text ux:Name="Button_Text" Value="{ReadProperty this.Text}" Color="#000" Alignment="Center" TextAlignment="Center" Margin="10" />
				<Rectangle CornerRadius="4" Layer="Background">
					<LinearGradient>
						<GradientStop Offset="0" Color="#0fc" />
						<GradientStop Offset="1" Color="#0cf" />
					</LinearGradient>
				</Rectangle>
			</ButtonBase>

	*/
	public class ButtonBase : Panel
	{
		string _text;
		[UXOriginSetter("SetText")]
		public string Text
		{
			get { return _text; }
			set { SetText(value, null); }
		}

		public void SetText(string value, IPropertyListener origin)
		{
			if (value != _text)
			{
				_text = value;
				OnPropertyChanged("Text", origin);
				var l = LabelView;
				if (l != null)
					l.Text = value;
			}
		}

		ILabelView LabelView
		{
			get { return NativeView as ILabelView; }
		}

		protected override void PushPropertiesToNativeView()
		{
			base.PushPropertiesToNativeView();
			var l = LabelView;
			if (l != null)
			{
				l.Text = Text;
			}
		}

	}
}
