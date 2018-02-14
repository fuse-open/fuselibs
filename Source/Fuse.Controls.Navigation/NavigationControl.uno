using Uno;
using Uno.UX;
using Fuse.Scripting;
using Fuse.Animations;
using Fuse.Elements;
using Fuse.Layouts;
using Fuse.Motion;
using Fuse.Navigation;
using Fuse.Triggers;
using Fuse.Triggers.Actions;

namespace Fuse.Controls
{
	/**
		Specifies what happens to pages which are not currently active.
	*/
	public enum NavigationControlInactiveState
	{
		/** `Visibility` is set to `Collapsed` */
		Collapsed,
		/** `IsEnabled` is set to `false` */
		Disabled,
		/** nothing is done */
		Unchanged,
	}
	
	/**
		Specifies what user interaction is provided.
	*/
	public enum NavigationControlInteraction
	{
		/** No user interaction, the user will be unable to interact unless other gestures are added */
		None,
		/** A swiping gesture is used to move between pages. */
		Swipe,
	}
	
	/**
		Specifies what transition is used to move between pages.
	*/
	public enum NavigationControlTransition
	{
		/** For pages: Use the control/navigation default */
		Default,
		/** No transition is provided. It is expected that you provide your own transition on the pages.*/
		None,
		/** A default transition suitable for the theme/app is used. Typically this is a sliding. */
		Standard,
	}
	
	/**
		A standard page navigation system. This provides standard transitions, user interaction and 
		appropriate page handling for a basic linear navigation.
	*/
	public abstract partial class NavigationControl : Panel, INavigation, Fuse.Reactive.IObserver, Node.ISubtreeDataProvider
	{
		internal NavigationControl()
		{
			//to support embedding of navigation and avoid having translated children still visible
			ClipToBounds = true;
		}
		
		internal void SetNavigation(Fuse.Navigation.VisualNavigation nav)
		{
			_navigation = nav;
			Children.Add(_navigation);
		}
		
		internal NavigationControlTransition _transition = NavigationControlTransition.Standard;
		/**
			Specifies what transitions should be used for page navigation. If you wish to create your own
			transitions set to `None` and add your own to the pages.
			
			When using custom transitions be sure to add a @ReleasePage action. This instructs the `Navigator` on when it can reuse, discard, or add the page to its cache.
		*/
		public NavigationControlTransition Transition
		{
			get { return _transition; }
			set
			{
				if (_transition == value)
					return;
				_transition = value;
				//only update on rooting
			}
		}
		
		Fuse.Navigation.VisualNavigation _navigation;
		internal Fuse.Navigation.VisualNavigation Navigation
		{
			get { return _navigation; }
		}
		
		/**
			The currently active visual of the navigation.
		*/
		public Visual Active
		{
			get { return _navigation.Active; }
			set { _navigation.Active = value; }
		}

		protected override void OnChildAdded(Node n)
		{
			if (IsRootingStarted)
			{
				var v = n as Element;
				if (v != null) UpdateChild(v);
			}
			
			base.OnChildAdded(n);
		}
		
		//the outlet page on which this control resides.
		protected Visual AncestorPage { private set; get; }

		internal RouterPage AncestorRouterPage { private set; get; }

		/* 
			This affects the structure of navigation, in particular by associating PageData.RouterPage's
			with each child, thus needs to happen prior to rooting the children.
		*/
		protected override void OnRootedPreChildren()
		{
			base.OnRootedPreChildren();
			
			if (IsRouterOutlet)
			{
				AncestorPage = Router.FindRouterOutletPage(this);
				if (AncestorPage != null)
				{
					var pd = PageData.GetOrCreate(AncestorPage);
					pd.RouterPageChanged += OnRouterPageChanged;
					this.AncestorRouterPage = pd.RouterPage;
				}
				else
				{
					//for simplicity always have a root, this isn't part of the path however
					var router = Router.TryFindRouter(this);
					if (router != null)
						this.AncestorRouterPage = router.RootPage;
					else
						this.AncestorRouterPage = RouterPage.CreateDefault();
				}
			} 
			else
			{
				this.AncestorRouterPage = RouterPage.CreateDefault();
			}
			
		}
		
		protected override void OnRooted()
		{
			base.OnRooted();
			
			//defer first update to rooted, to avoid creating/deleting unused Swipe behavior if None
			UpdateInteraction();
			
			Navigation.PageProgressChanged += OnPageProgressChanged;
			
			//do after child rooting since it relies on the navigation behaviour to have been rooted
			for (var c = FirstChild<Element>(); c != null; c = c.NextSibling<Element>())
				UpdateChild(c);
			
			if (AncestorRouterPage != null)
				AncestorRouterPage.ChildRouterPagesUpdated += OnChildRouterPagesUpdated;
			OnPageHistoryChanged();
			
			BlockInputRooted();
		}
		
		void OnChildRouterPagesUpdated()
		{
			RouterPage.BubbleHistoryChanged(this);
		}
		
		/**
			Called when the interaction for the control should be setup.
		*/
		protected virtual void UpdateInteraction() {}
		
		void UpdateChild(Element c)
		{
			if (!Fuse.Navigation.Navigation.IsPage(c))
				return;
				
			var cpd = GetControlPageData(c);
			UpdateProgress(c, Navigation.GetPageState(c), cpd);
			
			if ( (cpd.Enter == null || cpd.Exit == null || cpd.Inactive == null || cpd.Removing == null) )
			{
				CleanupTriggers(c, cpd); //in case partially null
				
				CreateTriggers(c, cpd);
				
				if (cpd.Enter != null)
					c.Children.Add(cpd.Enter);
				if (cpd.Exit != null)
					c.Children.Add(cpd.Exit);
				if (cpd.Inactive != null)
					c.Children.Add(cpd.Inactive);
				if (cpd.Removing != null)
					c.Children.Add(cpd.Removing);
			}
			
			//attach a default RouterPage if it doesn't have one
			var pd = PageData.GetOrCreate(c);
			if (pd.RouterPage == null)
				pd.AttachRouterPage( new RouterPage( c.Name, c.Parameter ));
		}

		/**
			How the stnadard triggers are implemented will differ depending on the navigation type
			being used.
			
			@param c the element targeted by the trigger (don't add them here, just create them)
			@param pd where to store the created triggers
		*/
		protected abstract void CreateTriggers(Element c, ControlPageData pd);
		
		protected override void OnUnrooted()
		{
			BlockInputUnrooted();
			OnPageHistoryUnrooted();
			
			if (AncestorPage != null)
			{
				PageData.GetOrCreate(AncestorPage).RouterPageChanged -= OnRouterPageChanged;
				AncestorPage = null;
			}
			
			Navigation.PageProgressChanged -= OnPageProgressChanged;
			
			for (var c = FirstChild<Element>(); c != null; c = c.NextSibling<Element>())
			{
				var pd = GetControlPageData(c,false);
				if (pd == null)
					continue;
				CleanupTriggers(c, pd);
			}
			
			base.OnUnrooted();
		}
		
		virtual void CleanupTriggers(Element page, ControlPageData data)
		{
			if (data.Enter != null)
			{
				page.Children.Remove(data.Enter);
				data.Enter = null;
			}
			if (data.Exit != null)
			{
				page.Children.Remove(data.Exit);
				data.Exit = null;
			}
			if (data.Inactive != null)
			{
				page.Children.Remove(data.Inactive);
				data.Inactive = null;
			}
			if (data.Removing != null)
			{
				page.Children.Remove(data.Removing);
				data.Removing = null;
			}
		}
		
		protected override void OnChildRemoved(Node n)
		{
			var pc = n as Element;
			if (pc != null)
			{
				var pd = GetControlPageData(pc, false);
				if (pd != null)
				{
					CleanupTriggers(pc, pd);
				}
			}
			
			base.OnChildRemoved(n);
		}
		
		void OnPageProgressChanged(object page, NavigationArgs args)
		{
			for (int i=0; i < Navigation.PageCount; ++i)
			{
				var n = Navigation.GetPage(i) as Element;
				if (n == null)
					return;
				
				UpdateProgress(n, Navigation.GetPageState(n), GetControlPageData(n));
			}
		}
		
		protected virtual void UpdateProgress(Element page, NavigationPageState state, ControlPageData pd) { }

		bool _isRouterOutlet = true;
		/**
			Specifies whether this control participates in routing (is it a router outlet). 
			
			The default is "true".
		*/
		public bool IsRouterOutlet
		{
			get{ return _isRouterOutlet; }
			set { _isRouterOutlet = value; }
		}
		
		/*
			This class does not implemented IRouterOutlet due to a defect in the compiler. I was unable
			to get the derived classes compiling and overriding parts of the interface. So the derived
			classes simply implement the entire interaace and call this function.
		*/
		internal OutletType RouterOutletType
		{
			get
			{
				if (!IsRouterOutlet)
					return OutletType.None;
				return OutletType.Outlet;
			}
		}
		
		public class ControlPageData
		{
			public Trigger Enter, Exit, Inactive, Removing;
			
			public bool HasTriggers
			{
				get { return Enter != null || Exit != null || Inactive != null || Removing != null; }
			}
			
			//this page came from a template (as opposed to a child instance added by the user)
			public bool FromTemplate;
		}
		
		internal static ControlPageData GetControlPageData(Visual elm, bool create = true)
		{
			var pd = PageData.GetOrCreate(elm, create);
			if (pd == null) //could only happen if create == false
				return null;
				
			if (pd.ControlPageData != null || !create)
				return (ControlPageData)pd.ControlPageData;
				
			var cpd = new ControlPageData();
			pd.ControlPageData = cpd;
			return cpd;
		}
		
		static PropertyHandle _propTransition = Properties.CreateHandle();
		[UXAttachedPropertySetter("NavigationControl.Transition")]
		static public void SetTransition(Visual elm, NavigationControlTransition value)
		{
			elm.Properties.Set(_propTransition, value);
		}

		[UXAttachedPropertyGetter("NavigationControl.Transition")]
		static public NavigationControlTransition GetTransition(Visual elm)
		{
			object res;
			if (elm.Properties.TryGet(_propTransition,out res))
				return (NavigationControlTransition)res;
			return NavigationControlTransition.Default;
		}
		
		protected NavigationControlTransition PageTransition(Visual elm)
		{
			var t = GetTransition(elm);
			if (t != NavigationControlTransition.Default)
				return t;
			
			if (elm.FirstChild<Transition>() != null)
				return NavigationControlTransition.None;
				
			return Transition;
		}
		
		//INavigation
		/** See @Navigation.PageCount */
		public int INavigation.PageCount { get { return Navigation.PageCount; } }
		/** See @Navigation.PageProgress */
		public double INavigation.PageProgress { get { return Navigation.PageProgress; } }
		/** See @Navigation.GetPage */
		public Visual INavigation.GetPage(int index) { return Navigation.GetPage(index); }
		/** See @Navigation.ActivePage */
		public Visual INavigation.ActivePage { get { return Navigation.ActivePage; } }
		/** See @INavigation.GetPageState */
		public NavigationPageState INavigation.GetPageState( Visual page ) { return Navigation.GetPageState(page); }
		/** See @INavigation.State */
		public NavigationState INavigation.State { get { return Navigation.State; } }

		/** @hide */
		public event NavigationPageCountHandler PageCountChanged
		{
			add { Navigation.PageCountChanged += value; }
			remove { Navigation.PageCountChanged -= value; }
		}
		/** @hide */
		public event NavigationHandler PageProgressChanged
		{
			add { Navigation.PageProgressChanged += value; }
			remove { Navigation.PageProgressChanged -= value; }
		}
		/** @hide */
		public event ValueChangedHandler<NavigationState> StateChanged
		{
			add { Navigation.StateChanged += value; }
			remove { Navigation.StateChanged -= value; }
		}

		/** @hide */
		public event NavigatedHandler Navigated
		{
			add { Navigation.Navigated += value; }
			remove { Navigation.Navigated -= value; }
		}
		/** @hide */
		public event HistoryChangedHandler HistoryChanged
		{
			add { Navigation.HistoryChanged += value; }
			remove { Navigation.HistoryChanged -= value; }
		}
		/** @hide */
		public event ActivePageChangedHandler ActivePageChanged
		{
			add { Navigation.ActivePageChanged += value; }
			remove { Navigation.ActivePageChanged -= value; }
		}
		/** See @Navigation.GoForward */
		public void GoForward() { Navigation.GoForward(); }
		/** See @Navigation.GoBack */
		public void GoBack() { Navigation.GoBack(); }
		/** See @Navigation.CanGoBack */
		public bool CanGoBack { get { return Navigation.CanGoBack; } }
		/** See @Navigation.CanGoForward */
		public bool CanGoForward { get { return Navigation.CanGoForward; } }
		/** See @Navigation.Goto */
		public void Goto(Visual node, NavigationGotoMode mode) { Navigation.Goto(node, mode); }
		/** See @Navigation.Toggle */
		public void Toggle(Visual node) { Navigation.Toggle(node);}

		internal bool IsEmptyParameter(string a)
		{
			//the last tests are for a JS empty string, empty object, and null. The value is expected to be a JSON
			//serialized string.
			return a == null || a == "" || a == "\"\"" || a == "{}" || a == "null";
		}
		
		internal bool CompatibleParameter( string a, string b )
		{
			if (a == b)
				return true;
				
			return IsEmptyParameter(a) && IsEmptyParameter(b);
		}

		void OnRouterPageChanged(object sender, RouterPage routerPage)
		{
			AncestorRouterPage = routerPage;
			
			if (AncestorRouterPage == null)
				return;
				
			var pages = AncestorRouterPage.ChildRouterPages;
			Visual ignore;
			var current = (this as IRouterOutlet).GetCurrent(out ignore);
			if (pages.Count == 0 && current != null)
				pages.Add(current);
		}

		// common to PageControl and EdgeNavigator (unclear how to merge into Navigator)
		internal void RootActivePage()
		{
			var pages = AncestorRouterPage != null ? AncestorRouterPage.ChildRouterPages : null;
			if (pages != null && pages.Count > 0)
			{ 
				Visual ignore;
				((IRouterOutlet)this).Goto( pages[pages.Count-1], NavigationGotoMode.Bypass, 
					RoutingOperation.Goto, "", out ignore );
			}
			else
			{
				OnActivePageChanged(this, Navigation.Active);
			}

			Navigation.ActivePageChanged += OnActivePageChanged;
		}
		
		internal void UnrootActivePage()
		{
			Navigation.ActivePageChanged -= OnActivePageChanged;
		}
		
		void OnActivePageChanged(object sender, Visual active)
		{
			if (AncestorRouterPage != null)
			{
				Visual ignore;
				var current = (this as IRouterOutlet).GetCurrent(out ignore);
				var pages = AncestorRouterPage.ChildRouterPages;
				var changed = false;
				if (pages.Count == 0)
				{
					pages.Add( current );
					changed = true;
				}
				else if (pages[pages.Count -1] != current) 
				{
					pages[pages.Count-1] = current;
					changed = true;
				}
	
				if (changed)
					RouterPage.BubbleHistoryChanged(this);
			}
		}
	}
}
