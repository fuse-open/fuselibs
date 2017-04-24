using Uno;
using Uno.Collections;
using Uno.UX;
using Fuse.Animations;

namespace Fuse.Triggers
{
	/** Active when the parent element is visible. */
	public class WhileVisible : WhileTrigger
	{
		protected override void OnRooted()
		{
			base.OnRooted();
			Parent.IsVisibleChanged += OnIsVisibleChanged;

			SetActive(Parent.IsVisible);
		}

		protected override void OnUnrooted()
		{
			Parent.IsVisibleChanged -= OnIsVisibleChanged;
			base.OnUnrooted();
		}

		void OnIsVisibleChanged(object sender, EventArgs args)
		{
			SetActive(Parent.IsVisible);
		}
	}
}
