using Uno;
using Uno.UX;

using Fuse;
using Fuse.Triggers;

namespace Fuse.Navigation
{
	/**
		Active while the user is currently navigating between two pages.

		Does not provide progress.
	*/
	public class WhileNavigating : WhileTrigger
	{
		INavigation _context;
		
		protected override void OnRooted()
		{
			base.OnRooted();
			_context = Navigation.TryFind(Parent);
			if (_context == null)
			{
				Diagnostics.UserError( "WhileNavigating requires a Navigation context", this );
				return;
			}
			
			_context.StateChanged += OnStateChanged;
			SetActive( _context.State != NavigationState.Stable );
		}

		protected override void OnUnrooted()
		{
			if (_context != null)
			{
				_context.StateChanged -= OnStateChanged;
				_context = null;
			}
			base.OnUnrooted();
		}

		void OnStateChanged(object s, ValueChangedArgs<NavigationState> args)
		{
			SetActive(args.Value != NavigationState.Stable);
		}

	}
}
