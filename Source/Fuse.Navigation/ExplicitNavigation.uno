using Uno;

using Fuse;
using Fuse.Elements;
using Fuse.Triggers;

namespace Fuse.Navigation
{
	internal class ExplicitNavigation : VisualNavigation
	{
		public override void Goto( Visual visual, NavigationGotoMode mode )
		{
			if (mode != NavigationGotoMode.Transition &&
				mode != NavigationGotoMode.Bypass)
				return;
				
			SetPageProgress(visual, 0, false);
			Active = visual;
			OnPageProgressChanged( mode == NavigationGotoMode.Bypass ?
				NavigationMode.Bypass : NavigationMode.Switch);
		}

		Visual _active;
		public override Visual Active
		{
			get { return _active; }
			set 
			{ 
				if (_active != value)
				{
					_active = value; 
					OnActiveChanged(_active);
					OnNavigated(_active);
				}
			}
		}

		public override double PageProgress
		{
			get { return 0; }
		}
		
		void SetPageProgress(Visual page, float progress, float previous, bool update, bool havPrev)
		{
			var pd = GetPageData(page);
			if (pd == null)
				return;
			pd.PreviousProgress = havPrev ? previous : pd.Progress;
			pd.Progress = progress;
			if (update)
				OnPageProgressChanged(NavigationMode.Switch);
		}
		
		public void SetPageProgress(Visual page, float progress, float previous, bool update = true)
		{
			SetPageProgress(page, progress, previous, update, true );
		}
		
		public void SetPageProgress(Visual page, float progress, bool update = true)
		{
			SetPageProgress(page, progress, 0, update, false );
		}
		
		public void UpdateProgress(NavigationMode mode)
		{
			OnPageProgressChanged(mode);
		}
		
		public void SetState(NavigationState state)
		{
			OnStateChanged(state);
		}
	}
}
