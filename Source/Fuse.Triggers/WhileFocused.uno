using Uno;
using Fuse.Input;

namespace Fuse.Triggers
{
	/**
		Active whenever its containing element is in focus. 
	*/
	public class WhileFocused : WhileTrigger
	{
		protected override void OnRooted()
		{
			base.OnRooted();
			Focus.Gained.AddHandler(Parent, OnGotFocus);
			Focus.Lost.AddHandler(Parent, OnLostFocus);
			SetActive(Focus.FocusedVisual == Parent);
		}

		protected override void OnUnrooted()
		{
			Focus.Gained.RemoveHandler(Parent, OnGotFocus);
			Focus.Lost.RemoveHandler(Parent, OnLostFocus);
			base.OnUnrooted();
		}

		void OnGotFocus(object sender, EventArgs args)
		{
			SetActive(true);
		}

		void OnLostFocus(object sender, EventArgs args)
		{
			SetActive(false);
		}
	}

	/**
		Active whenever its containing element is not in focus.
	
		The inverse of @WhileFocused.
	*/
	public class WhileNotFocused : WhileTrigger
	{
		protected override void OnRooted()
		{
			base.OnRooted();
			Focus.Gained.AddHandler(Parent, OnGotFocus);
			Focus.Lost.AddHandler(Parent, OnLostFocus);
			SetActive(Focus.FocusedVisual != Parent);
		}

		protected override void OnUnrooted()
		{
			Focus.Gained.RemoveHandler(Parent, OnGotFocus);
			Focus.Lost.RemoveHandler(Parent, OnLostFocus);
			base.OnUnrooted();
		}

		void OnGotFocus(object sender, EventArgs args)
		{
			SetActive(false);
		}

		void OnLostFocus(object sender, EventArgs args)
		{
			SetActive(true);
		}
	}

}
