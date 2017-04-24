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
	public abstract partial class NavigationControl : Panel, INavigation
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
			var v = n as Element;
			if (v != null) UpdateChild(v);
			
			base.OnChildAdded(n);
		}
		
		protected override void OnRooted()
		{
			base.OnRooted();
			
			//defer first update to rooted, to avoid creating/deleting unused Swipe behavior if None
			UpdateInteraction();
			
			for (int i=0; i < Children.Count; ++i)
			{
				var c = Children[i] as Element;
				if (c != null) UpdateChild(c);
			}
			
			Navigation.PageProgressChanged += OnPageProgressChanged;
		}
		
		/**
			Called when the interaction for the control should be setup.
		*/
		protected virtual void UpdateInteraction() {}
		
		void UpdateChild(Element c)
		{
			if (!Fuse.Navigation.Navigation.IsPage(c))
				return;
				
			var pd = GetPageData(c);
			UpdateProgress(c, Navigation.GetPageState(c), pd);

			if ( (pd.Enter == null || pd.Exit == null || pd.Inactive == null || pd.Removing == null) )
			{
				CleanupTriggers(c, pd); //in case partially null
				
				CreateTriggers(c, pd);
				
				if (pd.Enter != null)
					c.Children.Add(pd.Enter);
				if (pd.Exit != null)
					c.Children.Add(pd.Exit);
				if (pd.Inactive != null)
					c.Children.Add(pd.Inactive);
				if (pd.Removing != null)
					c.Children.Add(pd.Removing);
			}
		}

		/**
			How the stnadard triggers are implemented will differ depending on the navigation type
			being used.
			
			@param c the element targeted by the trigger (don't add them here, just create them)
			@param pd where to store the created triggers
		*/
		protected abstract void CreateTriggers(Element c, PageData pd);
		
		protected override void OnUnrooted()
		{
			base.OnUnrooted();
			
			Navigation.PageProgressChanged -= OnPageProgressChanged;
			
			for (int i=0; i < Children.Count; ++i)
			{
				var c = Children[i] as Element;
				if (c == null) continue;

				var pd = GetPageData(c,false);
				if (pd == null)
					continue;
				CleanupTriggers(c, pd);
			}
		}
		
		void CleanupTriggers(Element page, PageData data)
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
				var pd = GetPageData(pc, false);
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
				
				UpdateProgress(n, Navigation.GetPageState(n), GetPageData(n));
			}
		}
		
		protected virtual void UpdateProgress(Element page, NavigationPageState state, PageData pd) { }

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
		protected OutletType RouterOutletType
		{
			get
			{
				if (!IsRouterOutlet)
					return OutletType.None;
				return OutletType.Outlet;
			}
		}
		
		static readonly PropertyHandle _pageDataProperty = Fuse.Properties.CreateHandle();
	
		//UNO: should be protected but the compiler says it isn't accessible for protected functions then
		public class PageData
		{
			public Trigger Enter, Exit, Inactive, Removing;
			public bool Active;
			
			public bool HasTriggers
			{
				get { return Enter != null || Exit != null || Inactive != null || Removing != null; }
			}
			
			//this page came from a template (as opposed to a child instance added by the user)
			public bool FromTemplate;
		}
		
		internal static PageData GetPageData(Visual elm, bool create = true)
		{
			object v;
			if (elm.Properties.TryGet(_pageDataProperty, out v))
				return (PageData)v;
				
			if (!create)
				return null;
				
			var sd = new PageData();
			elm.Properties.Set(_pageDataProperty, sd);
			return sd;
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

		/** See @Navigation.PageCountChanged */
		public event NavigationPageCountHandler PageCountChanged
		{
			add { Navigation.PageCountChanged += value; }
			remove { Navigation.PageCountChanged -= value; }
		}
		/** See @Navigation.PageProgressChanged */
		public event NavigationHandler PageProgressChanged
		{
			add { Navigation.PageProgressChanged += value; }
			remove { Navigation.PageProgressChanged -= value; }
		}
		/** See @Navigation.StateChanged */
		public event ValueChangedHandler<NavigationState> StateChanged
		{
			add { Navigation.StateChanged += value; }
			remove { Navigation.StateChanged -= value; }
		}

		/** See @Navigation.Navigated */
		public event NavigatedHandler Navigated
		{
			add { Navigation.Navigated += value; }
			remove { Navigation.Navigated -= value; }
		}
		/** See @Navigation.HistoryChanged */
		public event HistoryChangedHandler HistoryChanged
		{
			add { Navigation.HistoryChanged += value; }
			remove { Navigation.HistoryChanged -= value; }
		}
		/** See @Navigation.ActivePageChanged */
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
		
	}
}
