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
		internal IBaseNavigation _context;
		public IBaseNavigation NavigationContext { set; get; }

		protected override void OnRooted()
		{
			base.OnRooted();
			_context = NavigationContext ?? Navigation.TryFindBaseNavigation(Parent);

			if (_context == null)
			{
				Diagnostics.UserError( "WhileHistoryTrigger requires a Navigation context", this );
				return;
			}
			SetActive(IsOn);
			_context.HistoryChanged += OnHistoryChanged;
		}

		protected override void OnUnrooted()
		{
			if (_context != null)
			{
				_context.HistoryChanged -= OnHistoryChanged;
				_context = null;
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
		protected override bool IsOn { get { return _context.CanGoBack; } }
	}

	/**
		Active whenever navigating forward is possible.

		This trigger depends on the navigation context.

		@seealso Navigation

		@examples Docs/WhileHistoryTrigger.md
	*/
	public class WhileCanGoForward : WhileHistoryTrigger
	{
		protected override bool IsOn { get { return _context.CanGoForward; } }
	}

}
