using Uno;
using Uno.Collections;
using Uno.UX;
using Fuse.Animations;
using Fuse.Input;


namespace Fuse.Triggers
{
	/**
		Active whenever a child of its containing element is in focus. 
	*/
	public class WhileFocusWithin: WhileTrigger
	{
		protected override void OnRooted()
		{
			base.OnRooted();
			Focus.Gained.AddHandler(Parent, OnFocusChange);
			Focus.Lost.AddHandler(Parent, OnFocusChange);

			SetActive(IsOn);
		}

		protected override void OnUnrooted()
		{
			Focus.Gained.RemoveHandler(Parent, OnFocusChange);
			Focus.Lost.RemoveHandler(Parent, OnFocusChange);
			base.OnUnrooted();
		}

		void OnFocusChange(object sender, EventArgs args)
		{
			SetActive(IsOn);
		}

		bool IsOn
		{
			get { return Focus.IsWithin(Parent); }
		}
	}
}
