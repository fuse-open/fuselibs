using Uno;
using Uno.UX;

using Fuse.Animations;
using Fuse.Elements;
using Fuse.Layouts;
using Fuse.Motion;
using Fuse.Navigation;
using Fuse.Scripting;
using Fuse.Triggers;
using Fuse.Triggers.Actions;

namespace Fuse.Controls
{
	/**
		Provides standard transitions, user interaction, and page handling for a basic linear navigation.
		
		# Examples
		
		The following example illustrates the default behavior of `PageControl`, which is to slide the pages in response to swipe gestures:
		
			<PageControl>
				<Panel Background="Red"/>
				<Panel Background="Blue"/>
			</PageControl>
		
		`PageControl` is a router outlet, meaning that it can be controlled by a @Router.
		You can disable this behavior by setting the @IsRouterOutlet property to `false`.
		
			<JavaScript>
			    module.exports = {
			        gotoPage1: function() { router.goto("page1"); },
			        gotoPage2: function() { router.goto("page2"); },
			        gotoPage3: function() { router.goto("page3"); }
			    };
			</JavaScript>

			<Router ux:Name="router" />

			<PageControl>
			    <Panel ux:Name="page1" Color="#e74c3c" Clicked="{gotoPage2}" />
			    <Panel ux:Name="page2" Color="#2ecc71" Clicked="{gotoPage3}" />
			    <Panel ux:Name="page3" Color="#3498db" Clicked="{gotoPage1}" />
			</PageControl>

		By using data binding, you can set the currently active page by `Name` using the `Active` property.
		In the following example, We have three pages and a button that returns the user to the first page.

			<DockPanel>
				<JavaScript>
					var Observable = require("FuseJS/Observable");
					var currentPage = Observable("page1");
					function clickHandler() {
						currentPage.value = "page1";
					}
					module.exports = {
						clickHandler: clickHandler,
						currentPage: currentPage
					};
				</JavaScript>
				<PageControl Active="{currentPage}">
					<Panel Name="page1" Background="Red"/>
					<Panel Name="page2" Background="Green"/>
					<Panel Name="page3" Background="Blue"/>
				</PageControl>
				<Button Text="Home" Clicked="{clickHandler}" Dock="Bottom"/>
			</DockPanel>

		Take a look at the [Slides](/examples/page-control) example to see how this can be used in practice.
		
		## Navigation Order
		
		The pages of a `PageControl` are ordered front to back, with the first child being in the front. Going forward means going towards the first child and going backwards means going towards the last child.
		
		`PageControl` uses continous navigation between pages (not discrete changes).
		
		See [Navigation Order](articles:navigation/navigationorder.md)
		
	*/
	public partial class PageControl : NavigationControl, ISeekableNavigation, IRouterOutlet, IPropertyListener
	{
		static PageControl()
		{
			ScriptClass.Register(typeof(PageControl),
				new ScriptMethod<PageControl>("goto", gotoPage));
		}

		/**
			Transition to a page.
			
			@scriptmethod goto(node)
			@param node The @Visual object of target page. Typically a `ux:Name` variable.
		*/
		static void gotoPage(PageControl pc, object[] args)
		{
			var target = args[0] as Visual;
			if (target != null) pc.Active = target;
			else Diagnostics.UserError("PageControl.goto() : Argument must be a node object", pc);
		}

		new internal Fuse.Navigation.DynamicLinearNavigation Navigation
		{
			get { return ((NavigationControl)this).Navigation as Fuse.Navigation.DynamicLinearNavigation; }
		}
		
		public PageControl()
		{
			//https://github.com/fusetools/fuselibs-private/issues/1548
			HitTestMode = HitTestMode.LocalBounds | HitTestMode.Children;
			
			//defaults for NavigationControl
			_interaction = NavigationControlInteraction.Swipe;
			_transition = NavigationControlTransition.Standard;

			var nav = new DynamicLinearNavigation();
			nav.AddPropertyListener(this);
			SetNavigation( nav );
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			_pages.Rooted(this);
			RootActivePage();
		}
		
		protected override void OnUnrooted()
		{
			UnrootActivePage();
			_pages.Unrooted();
			base.OnUnrooted();
		}
		
		void IPropertyListener.OnPropertyChanged(PropertyObject obj, Selector property)
		{
			if (obj == Navigation) 
			{
				//forward index changes
				if (property == VisualNavigation.ActiveIndexName)
					OnPropertyChanged(ActiveIndexName);
			}
		}

		OutletType IRouterOutlet.Type { get { return RouterOutletType; } }
		
		void IRouterOutlet.PartialPrepareGoto(double progress)
		{
		}
		
		void IRouterOutlet.CancelPrepare()
		{
		}
		
		RoutingResult IRouterOutlet.CompareCurrent(RouterPage routerPage, out Visual pageVisual)
		{
			return CommonNavigation.CompareCurrent(this, Active, routerPage, out pageVisual);
		}
		
		RoutingResult IRouterOutlet.Goto(RouterPage routerPage, NavigationGotoMode gotoMode, 
			RoutingOperation operation, string operationStyle, out Visual pageVisual)
		{
			return CommonNavigation.Goto(this, routerPage, gotoMode, operation, operationStyle, out pageVisual);
		}
		
		RouterPage IRouterOutlet.GetCurrent(out Visual pageVisual)
		{
			pageVisual = Active;
			if (Active == null)
				return new RouterPage( "" );
			else
				return PageData.GetOrCreate(Active).RouterPage;
		}
		
		internal NavigationControlInactiveState _inactive = NavigationControlInactiveState.Collapsed;
		/**
			Specifiy what is done to pages that are inactive.
		*/
		public NavigationControlInactiveState InactiveState
		{
			get { return _inactive; }
			set { _inactive = value; }
		}
		
		protected override void UpdateProgress(Element page, NavigationPageState state, ControlPageData pd)
		{
			var active = Math.Abs(state.Progress) < 1;

			var elm = page as Element;
			if (elm != null && CollapseInactive)
				elm.Visibility = !active ? Visibility.Collapsed : Visibility.Visible;
			if (DisableInactive)
				page.IsEnabled = active;
		}
		
		protected override void CreateTriggers(Element c, ControlPageData pd)
		{
			switch (PageTransition(c))
			{
				case NavigationControlTransition.None:
					break;
					
				case NavigationControlTransition.Standard:
					if (IsHorizontal)
					{
						pd.Enter = new NavigationInternal.EnterHorizontal();
						pd.Exit = new NavigationInternal.ExitHorizontal();
					}
					else
					{
						pd.Enter = new NavigationInternal.EnterVertical();
						pd.Exit = new NavigationInternal.ExitVertical();
					}
					break;
			}
		}
		
		bool CollapseInactive
		{
			get { return _inactive == NavigationControlInactiveState.Collapsed; }
		}
		
		bool DisableInactive
		{
			get { return _inactive == NavigationControlInactiveState.Collapsed
				|| _inactive == NavigationControlInactiveState.Disabled; }
		}

		SwipeNavigate _swipe;
		protected override void UpdateInteraction()
		{
			var needSwipe = _interaction == NavigationControlInteraction.Swipe;
			
			if (needSwipe)
			{
				if (_swipe == null)
				{
					_swipe = new SwipeNavigate();
					_swipe.SwipeDirection = IsHorizontal ? SwipeDirection.Left : SwipeDirection.Up;
					_swipe.AllowedDirections =  _swipeAllow;
					Children.Add(_swipe);
				}
			}
			else
			{
				if (_swipe != null)
					Children.Remove(_swipe);
				_swipe = null;
			}
		}
		
		AllowedNavigationDirections _swipeAllow = AllowedNavigationDirections.Both;
		/**
			Access @SwipeNavigation.AllowedDirections for the swiper on this control
		*/
		public AllowedNavigationDirections AllowedSwipeDirections
		{
			get { return _swipeAllow; }
			set
			{
				_swipeAllow = value;
				if (_swipe != null)
					_swipe.AllowedDirections = value;
			}
		}
		
		internal NavigationControlInteraction _interaction = NavigationControlInteraction.Swipe;
		/* Moved to PageControl from NavigationControl for now since not used in Navigator yet */
		/**
			What interaction should be provided by this control. If custom interaction is desired set to `None`
			and then add your own.
		*/
		public NavigationControlInteraction Interaction
		{
			get { return _interaction; }
			set
			{
				if (_interaction == value)
					return;
				_interaction = value;
				if (IsRootingCompleted)
					UpdateInteraction();
			}
		}

		/**
			Allows providing a @NavigationMotion configuration object to specify the motion of the
			navigation. This refers to the logical motion of the navigation progress itself.
		*/
		[UXContent]
		public MotionConfig Motion
		{
			get 
			{ 
				var q = Navigation;
				return q == null ? null : q.Motion; 
			}
			set 
			{ 
				var q = Navigation;
				if (q != null)
					q.Motion = value; 
			}
		}
		
		Orientation _orient = Orientation.Horizontal;
		/**
			Specifies the orientation of the page layout.
		*/
		public Orientation Orientation
		{
			get { return _orient; }
			set { _orient = value; }
		}
		
		bool IsHorizontal { get { return _orient == Orientation.Horizontal; } }
		
		internal static Selector ActiveIndexName = "ActiveIndex";
		[UXOriginSetter("SetActiveIndex")]
		/**
			The child index of the current active page. 
			
			This can used to get and set the current page from JavaScript as well as listen to page changes. When used in conjunction with an `Each` to create dynamic pages the `ActiveIndex` is an index into that list of items (assuming no other children are added).
			
			@see VisualNavigation.DesiredActiveIndex
		*/
		public int ActiveIndex
		{
			get { return Navigation.DesiredActiveIndex; }
			set { Navigation.DesiredActiveIndex = value; }
		}
		public void SetActiveIndex(int value, IPropertyListener origin)
		{
			Navigation.DesiredActiveIndex = value;
		}
		
		//ISeekableNavigation
		void ISeekableNavigation.BeginSeek() { (Navigation as ISeekableNavigation).BeginSeek(); }
		float2 ISeekableNavigation.SeekRange { get { return Navigation.SeekRange; } }
		void ISeekableNavigation.Seek(UpdateSeekArgs args) { (Navigation as ISeekableNavigation).Seek(args); }
		void ISeekableNavigation.EndSeek(EndSeekArgs args) { (Navigation as ISeekableNavigation).EndSeek(args); }
		
		
		CommonNavigationPages _pages = new CommonNavigationPages();
		/**
			Provides a list of models that define the pages for the page control. The pages have the same structure as `Navigator.Pages` -- but here they do not define a history. To control what is the current page bind to `ActiveIndex`.
			
			The items in the array are objects, either explicitly created or via the Model feature. They should contain the the `$path` property which specifies the path to use. The object itself will be added to the data context for the page, allowing lookups from within the object.
		*/
		public IArray Pages
		{
			get { return _pages.Pages; }
			set { _pages.Pages = value; }
		}
	}

}
