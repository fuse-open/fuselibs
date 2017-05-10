using Uno;

using Fuse;
using Fuse.Triggers;

namespace Fuse.Navigation
{
	/**
		@mount Navigation
	*/
	public abstract class WhileHistoryTrigger : WhileTrigger
	{
		IBaseNavigation _context;
		public IBaseNavigation NavigationContext { set { _context = value; } get { return _context; } }

		protected override void OnRooted()
		{
			base.OnRooted();
			if (NavigationContext == null)
			{
				NavigationContext = Navigation.TryFindBaseNavigation(Parent);
			}
			if (NavigationContext == null)
			{
				Diagnostics.UserError( "WhileHistoryTrigger requires a Navigation context", this );
				return;
			}
			SetActive(IsOn);
			NavigationContext.HistoryChanged += OnHistoryChanged;
		}

		protected override void OnUnrooted()
		{
			if (NavigationContext != null)
			{
				NavigationContext.HistoryChanged -= OnHistoryChanged;
				NavigationContext = null;
			}
			base.OnUnrooted();
		}

		void OnHistoryChanged(object sender)
		{
			SetActive(IsOn);
		}

		protected abstract bool IsOn { get; }
	}

	/**
		Active whenever navigating backward is possible.

		This trigger depends on the navigation context.

		@seealso Navigation

		@examples Docs/WhileHistoryTrigger.md
	*/
	public class WhileCanGoBack : WhileHistoryTrigger
	{
		protected override bool IsOn { get { return NavigationContext.CanGoBack; } }
	}

	/**
		Active whenever navigating forward is possible.

		This trigger depends on the navigation context.

		@seealso Navigation

		@examples Docs/WhileHistoryTrigger.md
	*/
	public class WhileCanGoForward : WhileHistoryTrigger
	{
		protected override bool IsOn { get { return NavigationContext.CanGoForward; } }
	}

}
