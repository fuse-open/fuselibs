using Uno;
using Uno.UX;
using Uno.Collections;
using Fuse.Scripting;
using Fuse.Triggers;
using Fuse.Animations;
using Fuse.Elements;

namespace Fuse.Navigation
{
	public abstract partial class VisualNavigation : Behavior, INavigation, IParentObserver
	{
		static VisualNavigation()
		{
			ScriptClass.Register(typeof(VisualNavigation),
				new ScriptMethod<VisualNavigation>("goto", gotoNode));
		}

		/**
			Transition to the target node.

			@scriptmethod goto(node)
			@param node The `Visual` target for the transition. For most navigation types this must already be
				 a child of the navigation panel.
		*/
		static void gotoNode(VisualNavigation nav, object[] args)
		{
			var target = args[0] as Visual;
			if (target != null) nav.Goto(target);
			else Fuse.Diagnostics.UserError("Navigation.goto() : Argument must be a node object", nav);
		}

		internal VisualNavigation() { }

		public abstract void Goto(Visual element, NavigationGotoMode mode = NavigationGotoMode.Transition);
		public abstract Visual Active { get; set; }
		public virtual void Toggle(Visual page) { }

		public abstract double PageProgress { get; }
		public virtual NavigationPageState GetPageState(Visual page)
		{
			var pd = GetPageData(page);
			if (pd == null)
				return new NavigationPageState{ Progress = 0, PreviousProgress = 0 };
			return new NavigationPageState{
				Progress = pd.Progress, PreviousProgress = pd.PreviousProgress };
		}

		public event NavigationPageCountHandler PageCountChanged;

		NavigationState _navState = NavigationState.Stable;
		public NavigationState State
		{
			get { return _navState; }
		}
		public event ValueChangedHandler<NavigationState> StateChanged;

		protected void OnStateChanged(NavigationState newState)
		{
			if (newState == _navState)
				return;

			_navState = newState;
			if (StateChanged != null)
				StateChanged( this, new ValueChangedArgs<NavigationState>(newState) );
		}

		protected void OnPageCountChanged()
		{
			if (PageCountChanged != null)
				PageCountChanged(this);
		}

		public event NavigationHandler PageProgressChanged;

		protected void OnPageProgressChanged(NavigationMode mode)
		{
			OnPageProgressChanged(0,0,mode);
		}

		protected void OnPageProgressChanged(double current, double prev, NavigationMode mode)
		{
			if (PageProgressChanged != null)
				PageProgressChanged(this, new NavigationArgs(current, prev, mode) );
		}

		public event NavigatedHandler Navigated;

		/**
			Call when the navigation to the target page is completed.
		*/
		protected void OnNavigated(Visual newElement)
		{
			var handler = Navigated;
			if (handler != null)
			{
				handler(this, new NavigatedArgs(newElement));
			}
		}

		public event ActivePageChangedHandler ActivePageChanged;

		/**
			Call immedaitely when the active page changes (when it is set). This happens prior to animation,
			so strictly prior to `OnNavigated` (though within the same frame, the next calls, is fine).
		*/
		protected void OnActiveChanged(Visual newElement)
		{
			OnPropertyChanged(ActiveIndexName);

			if (ActivePageChanged != null)
				ActivePageChanged(this, newElement);
		}

		public event HistoryChangedHandler HistoryChanged;

		protected void OnHistoryChanged()
		{
			if (HistoryChanged != null)
				HistoryChanged(this);
		}

		public virtual void GoForward() { }
		public virtual void GoBack() { }
		public virtual bool CanGoBack { get { return false; } }
		public virtual bool CanGoForward { get { return false; } }
		public virtual void ClearHistory() { }


		List<PageData> _pages = new List<PageData>();

		internal IList<PageData> Pages { get { return _pages; } }

		internal PageData GetPageData( Visual page )
		{
			if (page == null)
				return null;

			return PageData.Get(page);
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			UpdatePages();
		}

		void UpdatePages()
		{
			_pages.Clear();
			int c = 0;
			for (var x = Parent.FirstChild<Visual>(); x != null; x = x.NextSibling<Visual>())
			{
				//we require Visual (though IsPage tends to check that anyway)
				if (!Navigation.IsPage(x))
					continue;

				var pd = PageData.GetOrCreate(x);
				pd.Index = c;
				_pages.Add( pd );
				c++;
			}

			OnPageCountChanged();
		}

		protected override void OnUnrooted()
		{
			_pages.Clear();
			base.OnUnrooted();
		}

		public virtual void OnChildAddedWhileRooted(Node child)
		{
			var v = child as Visual;
			if (v == null)
				return;

			UpdatePages();
		}

		public virtual void OnChildRemovedWhileRooted(Node child)
		{
			var v = child as Visual;
			if (v == null)
				return;

			UpdatePages();
		}

		public virtual void OnChildMovedWhileRooted(Node child)
		{
			var v = child as Visual;
			if (v == null)
				return;

			UpdatePages();
		}

		protected bool IsPage(Node x) { return Navigation.IsPage(x); }

		public int PageCount
		{
			get { return _pages.Count; }
		}

		public Visual GetPage(int index)
		{
			if (index < 0 || index >= _pages.Count)
				return null;
			return _pages[index].Visual;
		}

		public Visual ActivePage { get { return Active; } }

		protected bool HasPages
		{
			get { return _pages.Count > 0; }
		}

		protected int GetPageIndex(Visual child)
		{
			var pd = GetPageData(child);
			if (pd == null)
				return -1;
			return pd.Index;
		}

		internal static Selector ActiveIndexName = "ActiveIndex";
		[UXOriginSetter("SetActiveIndex")]
		/**
			The child index of the currently active page.

			The value is `-1` if there is currently no active page.

			Setting this value causes the navigation to transition to the desired page. Due to animations there may be a delay between setting and the new value actually becoming the "active" page. If you need to respond at a precise time in the transition you can use a `ActivatingAnimation` or a `WhileActive` trigger with appropriate threshold.
		*/
		public int ActiveIndex
		{
			get
			{
				var pd = GetPageData(Active);
				return pd == null ? -1 : pd.Index;
			}
			set { SetActiveIndex(value, null); }
		}
		public void SetActiveIndex(int value, IPropertyListener origin)
		{
			if (value == ActiveIndex)
				return;
			Active = GetPage(value);
		}
	}
}
