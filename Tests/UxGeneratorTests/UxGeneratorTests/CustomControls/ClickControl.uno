using Uno;
using Fuse.Elements;
using Fuse.Gestures;

namespace Fuse.Controls
{
	public class ClickControl: Panel
	{
		public ClickControl()
		{ }

		public event ClickedHandler Clicked;

		public void EmulateClick()
		{
			if (Clicked != null)
				Clicked(this, null);
		}
	}
}
