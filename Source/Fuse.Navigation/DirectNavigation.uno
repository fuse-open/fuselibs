using Uno;

using Fuse;
using Fuse.Elements;
using Fuse.Triggers;

namespace Fuse.Navigation
{
	/**
		## Navigation Order
		
		Pages in a `DirectNavigation` have a discrete page progress. The active page is `0`, and all others are `-1`. All inactives pages are behind the active one, and no pages are ever in front of the active one.
		
		See [Navigation Order](articles:navigation/navigationorder.md)
	*/
	public class DirectNavigation : VisualNavigation
	{
		protected override void OnRooted()
		{
			base.OnRooted();
			UpdateState( true );
		}

		public override void OnChildAddedWhileRooted(Node child)
		{
			base.OnChildAddedWhileRooted(child);
			UpdateState(true);
		}

		public override void OnChildRemovedWhileRooted(Node child)
		{
			base.OnChildRemovedWhileRooted(child);
			if (_active == child)
				Goto(null, NavigationGotoMode.Transition);
		}

		public override void Goto( Visual visual, NavigationGotoMode mode )
		{
			if (mode == NavigationGotoMode.Bypass ||
				mode == NavigationGotoMode.Transition)
				TransitionTo( visual, mode == NavigationGotoMode.Bypass );
		}

		void TransitionTo( Visual visual, bool bypass )
		{
			var oldActive = _active;
			_active = visual;
			UpdateState( bypass );

			if (oldActive != _active)
			{
				OnActiveChanged(_active);
				OnNavigated(_active);
			}
		}

		void UpdateState( bool bypass )
		{
			for (int t = 0; t < Pages.Count; t++)
			{
				var c = Pages[t].Visual;
				bool active = _active == c;
				var newProgress = active ? 0 : -1;
				SetProgressState(c, newProgress);
			}
			
			OnPageProgressChanged(bypass ? NavigationMode.Bypass : NavigationMode.Switch);
		}

		Visual _active;
		public override Visual Active
		{
			get { return _active; }
			set
			{
				TransitionTo( value, false);
			}
		}

		void SetProgressState(Visual elm, int progress)
		{
			var pd = GetPageData(elm);
			if (pd == null)
			{
				Fuse.Diagnostics.InternalError( "Unexpected null page", elm );
				return;
			}
			
			pd.PreviousProgress = pd.Progress;
			pd.Progress = progress;
		}
		
		public override double PageProgress
		{
			get
			{
				if (_active == null)
					return -1;
				return 0;
			}
		}
	}
}
