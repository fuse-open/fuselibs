using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Navigation
{
	/** Describes what happens when the back button is pressed. */
	public enum BackButtonAction
	{
		/** Calls the router's GoBack function. */
		GoBack,
		/** Does nothing. */
		None
	}
	
	/** @deprecated */
	public enum RouterGoBackBehavior
	{
		GoBack,
		GoBackAndUp,
	}

	public enum ModifyRouteHow
	{
		Push,
		Goto,
		Replace,
		GoBack,
		PrepareBack,
		PreparePush,
		PrepareGoto,
		FinishPrepared,
	}
	
	/** Manages routing and navigation history for part or all of a Fuse app.

		> Note: It is recommended that you first read the [Navigation guide](/docs/navigation/navigation) for a full overview of Fuse's navigation system.

		The `Router` class, along with _router outlets_ such as @Navigator and @PageControl, forms the basis of navigation in Fuse.
		To navigate in a Fuse app, a _route_ is sent to a `Router` instance. This route consists of one or many parts, which each consist of a string path that
		identifies a target to navigate to, and optionally, some data to send to this target when navigating to it.

		When a `Router` receives a route, it will recursively perform navigation for the different parts of the route.
		For each part, it will search its immediate UX tree to locate a router outlet that will use this part's string path to navigate to part of the app.
		This could represent, for example, the template key of a template in a @Navigator, or the name of a @Page in a @PageControl.

		A router can go directly between routes with `goto`, or navigate heirarchically using `push` and `goBack`.

		Typically, an app will use a single, global `Router` instance which will work from the @App root, and represents a single _navigation context_ for the entire app.
		It's possible, however, to create separate routers for different localized parts of the UX tree, which can be useful if, for example, a different history needs to be
		kept for part of the app.

		## Example

		The following example illustrates a basic navigation setup using a @Router and @Navigator.
		For a complete introduction and proper examples of Fuse's navigation system, see the [Navigation guide](/docs/navigation/navigation).

			<JavaScript>
				module.exports = {
					gotoFirst: function() { router.goto("firstPage"); },
					gotoSecond: function() { router.goto("secondPage"); }
				};
			</JavaScript>

			<Router ux:Name="router" />

			<DockPanel>
				<Navigator DefaultTemplate="firstPage">
					<Page ux:Template="firstPage">
						<Text Alignment="Center">This is the first page.</Text>
					</Page>
					<Page ux:Template="secondPage">
						<Text Alignment="Center">This is the second page.</Text>
					</Page>
				</Navigator>

				<Grid Dock="Bottom" Columns="1*,1*">
					<Button Text="First page" Padding="20" Clicked="{gotoFirst}" />
					<Button Text="Second page" Padding="20" Clicked="{gotoSecond}" />
				</Grid>
			</DockPanel>
			
			
		## Page Navigation Order
		
		The history of the router follows the standard history ordering, newest routes are at the front of the history, older routes at the back.
		
		The router however does not decide on the navigation order of the pages in the individual controls, as described in [Navigation Order](articles:navigation/navigationorder.md). This is controlled by each outlet being used.
	*/
	public partial class Router : Node, IBaseNavigation, IPreviewStateSaver
	{
		protected override void OnRooted()
		{
			base.OnRooted();

			Fuse.Input.Keyboard.KeyPressed.AddGlobalHandler(OnKeyPressed);

			if (IsMasterRouter)
			{
				//only the root-most router can be master
				var n = Parent;
				bool root = true;
				while (n != null)
				{
					if (HasOtherRouter(n))
					{
						root = false;
						break;
					}
					n = n.Parent;
				}
				
				if (root)
				{
					var ps = PreviewState.Find( this );
					if (ps != null)
					{
						ps.AddSaver(this);
						
						var psd = ps.Current;
						if (psd != null)
						{
							var storedPage = psd.Consume( _previewStateId ) as RouterPage;
							if (storedPage != null)
								_rootPage = storedPage;
						}
					}
				}
			}
		}

		protected override void OnUnrooted()
		{
			var ps = PreviewState.Find( this);
			if (ps != null)
				ps.RemoveSaver(this);
				
			Fuse.Input.Keyboard.KeyPressed.RemoveGlobalHandler(OnKeyPressed);
			
			base.OnUnrooted();
		}
		
		const string _previewStateId = "router";
		void IPreviewStateSaver.Save( PreviewStateData psd )
		{
			psd.Set( _previewStateId, _rootPage );
		}
		
		bool _isMasterRouter = true;
		/**
			If `true` indicates this is the primary router of the application -- has implications for integration
			with Preview.
		*/
		public bool IsMasterRouter
		{
			get { return _isMasterRouter; }
			set { _isMasterRouter = value; }
		}

		public delegate void BackAtRootPressedHandler(object sender,EventArgs args);
		/**
			Raised when the user pressed the back button (hardware or simulated) and there is no back page (root of navigation stack).
		*/
		public event BackAtRootPressedHandler BackAtRootPressed;
		void OnKeyPressed(object sender, Fuse.Input.KeyEventArgs args)
		{
			if (args.Key == Uno.Platform.Key.BackButton)
			{
				if (BackButtonAction == BackButtonAction.GoBack) 
				{
					if (!GoBack())
					{
						if (BackAtRootPressed != null)
							BackAtRootPressed(this, new EventArgs());
					}
				}
			}
		}

		BackButtonAction _backButtonAction = BackButtonAction.GoBack;
		/** Specifies what happens when the device's back button is pressed.
			The default is `GoBack`. If your app has multiple routers or you want
			to handle back button logic manually, you can set this to `None`.
		*/
		public BackButtonAction BackButtonAction 
		{
			get { return _backButtonAction; }
			set { _backButtonAction = value; }
		}

		public Route GetCurrentRoute()
		{
			return GetHistoryRoute(0).ToRoute();
		}
		
		RouterPageRoute GetCurrentRouterPageRoute()
		{
			return GetHistoryRoute(0);
		}
		
		/**	Clears the history and navigates to the specified route. */
		public void Goto(Route route, string operationStyle = "")
		{
			Modify( ModifyRouteHow.Goto, RouterPageRoute.Convert(route), NavigationGotoMode.Transition, operationStyle );
		}

		/** Pushes the current route (if any) on navigation history and navigates to the specified route. */
		public void Push(Route route, string operationStyle = "")
		{
			Modify( ModifyRouteHow.Push, RouterPageRoute.Convert(route), NavigationGotoMode.Transition, operationStyle );
		}

		internal void Modify( ModifyRouteHow how, Route route, NavigationGotoMode mode,
			string operationStyle )
		{
			Modify( how, RouterPageRoute.Convert(route), mode, operationStyle );
		}
		
		internal void Modify( ModifyRouteHow how, RouterPageRoute route, NavigationGotoMode mode,
			string operationStyle )
		{
			switch( how )
			{
				case ModifyRouteHow.Goto:
					SetRoute(route, mode, RoutingOperation.Goto, operationStyle);
					break;
					
				case ModifyRouteHow.Push:
					SetRoute(route, mode, RoutingOperation.Push, operationStyle);
					break;
					
				case ModifyRouteHow.Replace:
					SetRoute(route, mode, RoutingOperation.Replace, operationStyle);
					break;
					
				case ModifyRouteHow.GoBack:
					Pop();
					break;
					
				case ModifyRouteHow.PrepareBack:
					if (route != null)
						Fuse.Diagnostics.UserWarning( "PrepareBack does not support an explicit route", this );
					
					var popRoute = GetHistoryRoute(1);
					if (popRoute == null)
					{
						Fuse.Diagnostics.UserError( "There is no history for PrepareBack", this );
						return;
					}

					PrepareRoute(popRoute, RoutingOperation.Pop, operationStyle);
					break;
					
				case ModifyRouteHow.PreparePush:
					PrepareRoute(route, RoutingOperation.Push, operationStyle);
					break;
					
				case ModifyRouteHow.PrepareGoto:
					PrepareRoute(route, RoutingOperation.Goto, operationStyle);
					break;
					
				case ModifyRouteHow.FinishPrepared:
					FinishPrepared();
					break;
			}
			
		}
		
		internal Dictionary<string,RouterPageRoute> Bookmarks = new Dictionary<string,RouterPageRoute>();
		
		
		RouterGoBackBehavior _goBackBehavior = RouterGoBackBehavior.GoBack;
		/** 
			@deprecated Exists only to get back deprecated GoUp behavior 2018-03-14 
			@advanced
		*/
		public RouterGoBackBehavior GoBackBehavior
		{
			get { return _goBackBehavior; }
			set 
			{ 
				_goBackBehavior = value; 
				if (value == RouterGoBackBehavior.GoBackAndUp)
					Fuse.Diagnostics.Deprecated( "Up behavior is deprecated as it isn't well defined.", this );
			}
		}
		
		/** Goes back to the previous page in the navigation history, or up one level in the route if the history is empty.
			
			If the navigation history is nonempty, this pops the previous item from the history and makes
			that the current route. 
			
			If the navigation history is empty, this method goes to a route one level above the current
			route. If the current route is already a top level route, this method does nothing. 
		*/
		public bool GoBack()
		{
			if (CanGoBack) 
			{
				Pop();
				return true;
			}
			else if (GoBackBehavior == RouterGoBackBehavior.GoBackAndUp)
			{
				return GoUp();
			}
			
			return false;
		}
		public void IBaseNavigation.GoBack() { GoBack(); }

		public bool CanGoBack
		{
			get
			{
				//be strict for typical use
				return GetHistoryRoute(1) != null;
			}
		}
		
		bool GoUp()
		{
			var cur = GetCurrentRouterPageRoute();
			if (cur == null) 
				return false;
				
			var up = cur.Up();
			if (up != cur) 
			{
				SetRoute(up, NavigationGotoMode.Transition, RoutingOperation.Pop, "");
				return true;
			}
			
			return false;
		}

		void Pop()
		{
			var route = GetHistoryRoute(1);
			if (route == null)
			{
				Fuse.Diagnostics.UserError( "Cannot pop() - history is empty", this );
				return;
			}
			SetRoute(route, NavigationGotoMode.Transition, RoutingOperation.Pop, "");
		}

		RouterPageRoute _prepareCurrent, _prepareNext;
		RoutingOperation _prepareOperation;
		string _prepareOperationStyle;
		double _prepareProgress = 0;
		IRouterOutlet _prepareOutlet;
		void PrepareRoute(RouterPageRoute r, RoutingOperation operation, string operationStyle)
		{
			_prepareCurrent = GetCurrentRouterPageRoute();
			_prepareNext = SetRouteImpl(Parent, _rootPage, r, NavigationGotoMode.Prepare, operation,
				operationStyle, out _prepareOutlet);
			_prepareOperation = operation;
			_prepareProgress = 0;
			_prepareOperationStyle = operationStyle;
		}
		
		void FinishPrepared()
		{
			if (_prepareOutlet == null)
				return;

			SetRoute(_prepareNext, NavigationGotoMode.Transition, _prepareOperation, _prepareOperationStyle);
			ClearPrepared();
		}
		
		void ClearPrepared()
		{
			_prepareOutlet = null;
			_prepareCurrent = null;
			_prepareNext = null;
		}
		
		public double PrepareProgress
		{
			get { return _prepareProgress; }
			set { SetPrepareProgress(value); }
		}
		
		void SetPrepareProgress(double value)
		{
			if (_prepareCurrent == null || _prepareNext == null	 || _prepareOutlet == null)
				return;

			int depth = GetOutletDepth(_prepareOutlet);
			var pc = _prepareCurrent.SubDepth(depth);
			var pn = _prepareNext.SubDepth(depth);
			
			if (pc == null || pn == null)
			{
				Fuse.Diagnostics.InternalError( "Invalid outlet depth in prepare progress", this );
				return;
			}
			
			_prepareProgress = value;
			_prepareOutlet.PartialPrepareGoto(_prepareProgress);
		}
		
		public void CancelNavigation()
		{
			if (_prepareOutlet != null)
			{
				_prepareOutlet.CancelPrepare();
				ClearPrepared();
			}
			else
			{
				//ideally we could tell the outlets anyway, but without a clear use-case it's not sure
				//how that should work -- and they'd all have to know they are navigating first
				Fuse.Diagnostics.InternalError( "No active navigation that can be cancelled" );
			}
		}
		
		RouterPageRoute SetRoute(RouterPageRoute r, NavigationGotoMode gotoMode, RoutingOperation operation, 
			string operationStyle, bool userRequest = true)
		{
			if (r == null)
				throw new Exception( "Route cannot be null" );
				
			//prepared routes are cleared when the actual route is changed
			ClearPrepared();
			
			var current = GetCurrentRouterPageRoute();
			
			IRouterOutlet ignore;
			var outR = SetRouteImpl(Parent, _rootPage, r, gotoMode, operation, operationStyle, out ignore);
			if (outR == null)
			{
				var msg = "Unable to navigate to route: " + r.Format();
				if (userRequest)
					Fuse.Diagnostics.UserError( msg, this );
				else
					Fuse.Diagnostics.InternalError( msg, this );
					
				//try to cleanup on error and go to previous state
				SetRouteImpl(Parent, _rootPage, current, NavigationGotoMode.Bypass, RoutingOperation.Goto,
					"", out ignore);
			}
			
			OnHistoryChanged();
			return outR;
		}
		
		/* This has become an unfortunate monstrosity of logic. All the standard use-cases are covered by tests but the overall logic is a bit confusing. It may not produce the desired/expected history in non-standard uses.  It should not however produce a garbage state: the current route will always be valid. A proper cleanup would require passing a separate pageOperation, distinct from operation.  Or it may be cleaner to take a list of RouterPage instead of a Route, and determine the history/pages changes separately. */
		RouterPageRoute SetRouteImpl(Visual root, RouterPage rootPage, RouterPageRoute r, 
			NavigationGotoMode gotoMode, 
			RoutingOperation operation, string operationStyle, out IRouterOutlet majorChange,
			bool canReuse = true)
		{	
			var pages = rootPage.ChildRouterPages;
			majorChange = null;
			var outlet = FindOutletDown(root);
			if (outlet == null)
			{
				Fuse.Diagnostics.InternalError( "No router outlet found to handle route: " + r, this );
				return null;
			}
			
			RouterPage page = r.RouterPage;
			Visual pageVisual = null;
			var didTransition = outlet.CompareCurrent(page, out pageVisual);
			if (didTransition == RoutingResult.Invalid)
				return null;
			
			//pushing/goto up to the leaf route can reuse existing matching pages
			bool leafOp = r.SubRoute == null && operation != RoutingOperation.Goto;
			bool reusePage = canReuse && didTransition == RoutingResult.NoChange && !leafOp;
			if (reusePage)
				page = outlet.GetCurrent(out pageVisual);
			
			if (gotoMode != NavigationGotoMode.Prepare)
			{
				switch (operation)
				{
					case RoutingOperation.Goto:
						pages.Clear();
						pages.Add(page);
						break;
						
					case RoutingOperation.Push:
						if (!canReuse)
						{
							pages.Clear();
							pages.Add(page);
						}
						else if (!reusePage)
							pages.Add(page);
						break;
						
					case RoutingOperation.Replace:
						if (!reusePage)
						{
							if (pages.Count  > 0)
								pages[pages.Count-1] = page;
							else
								pages.Add(page);
						}
						break;
						
					case RoutingOperation.Pop:
						if (canReuse && !reusePage)
						{
							if (pages.Count >0)
								pages.RemoveAt(pages.Count -1);
						}
						break;
				}
			}
			
			
			if (didTransition != RoutingResult.NoChange)
			{
				didTransition = outlet.Goto(page, gotoMode, operation, operationStyle, out pageVisual);
				if (didTransition == RoutingResult.Invalid)
					return null;
			}
			
			bool trackMajorChange = true;
			if (didTransition == RoutingResult.Change)
			{
				gotoMode = NavigationGotoMode.Bypass;
				majorChange = outlet;
				trackMajorChange = false;
			}

			RouterPageRoute outSubRoute = null;
			if (r.SubRoute != null)
			{
				if (pageVisual == null)
				{
					Fuse.Diagnostics.InternalError( "SubRoute requested but outlet has no active path: " + r, this );
					return null;
				}
				
				IRouterOutlet subMajorChange;
				outSubRoute = SetRouteImpl(pageVisual, page, r.SubRoute, gotoMode, operation, 
					operationStyle, out subMajorChange, reusePage );
				if (trackMajorChange)
					majorChange = subMajorChange;
				if (outSubRoute == null)
					return null;
			}
			else
			{
				outSubRoute = GetCurrent(pageVisual);
			}
			
			return new RouterPageRoute( page, outSubRoute);
		}
		
		RouterPageRoute GetCurrent(Visual from, IRouterOutlet to = null)
		{
			if (from == null)
				return null;
				
			var outlet = FindOutletDown(from);
			if (outlet == null || outlet == to)
				return null;
				
			Visual pageVisual;
			var page = outlet.GetCurrent(out pageVisual);
			return new RouterPageRoute( page, GetCurrent(pageVisual, to));
		}
		
		RouterPageRoute GetRouteUpToRouter(Node from)
		{
			RouterPageRoute route = null;
			
			while (from != null)
			{
				Node page;
				var outlet = FindOutletUp(from, out page);
				if (outlet == null)
					break;
					
				var v = page as Visual;
				var pd = v != null ? PageData.Get(v) : null;
				RouterPage opage = null;
				Visual ignore;
				if (pd == null || pd.RouterPage == null)
					opage = outlet.GetCurrent(out ignore);
				else
					opage = pd.RouterPage;
				route = new RouterPageRoute( opage, route );
				
				from = (outlet as Node).Parent;
			}
			
			return route;
		}
		
		/* Find the nearest ancestor that is a Page in a RouterOutlet, but do not cross a Router. */
		static internal Visual FindRouterOutletPage(Node from)
		{
			while (from != null && from.Parent != null)
			{
				if (HasRouter(from))
					return null;

				var ro = AsRouterOutlet(from.Parent);
				if (ro != null)
				{
					var v = from as Visual;
					if (v != null) return v;
					Fuse.Diagnostics.InternalError( "Unexpected request for RouterOutlet page", from );
				}
				
				from = from.Parent;
			}
			
			return null;
		}
		
		int GetOutletDepth(IRouterOutlet outlet)
		{
			int c=0;
			//TODO: check this assumption somewhere
			var n = (outlet as Node).Parent;
			while (n != null && n != Parent)
			{
				n = n.Parent;
				if (n is IRouterOutlet)
					c++;
			}
			
			return c;
			}
		
		IRouterOutlet FindOutletDown(Node active)
		{
			var ro = AsRouterOutlet(active);
			if (ro != null) return ro;
			
			var v = active as Visual;
			if (v != null)
			{
				//a new router breaks the chain (to allow sub-navigation)
				//must check before since it could be anywhere in the children
				if (HasOtherRouter(v))
					return null;
				
				for (var ue = v.FirstChild<Node>(); ue != null; ue = ue.NextSibling<Node>())
				{
					ro = FindOutletDown(ue);
					if (ro != null) return ro;
				}
			}
			return null;
		}
		
		static IRouterOutlet AsRouterOutlet(Node n)
		{
			var ro = n as IRouterOutlet;
			if (ro != null && ro.Type.HasFlag(OutletType.Outlet) ) return ro;
			return null;
		}
		
		IRouterOutlet FindOutletUp(Node active)
		{
			Node ignore;
			return FindOutletUp(active, out ignore);
		}
		
		IRouterOutlet FindOutletUp(Node active, out Node page)
		{
			page = active;
			while (active != null)
			{
				var ro = AsRouterOutlet(active);
				if (ro != null) return ro;
			
				//prevent crossing bounds
				var v = active as Visual;
				if (v != null && HasRouter(v))
					return null;
					
				page = active;
				active = active.Parent;
			}
			return null;
		}
		
		internal Route GetRelativeRoute(Node from, Route rel)
		{
			return GetRelativeRoute( from, RouterPageRoute.Convert(rel) ).ToRoute();
		}
		
		internal RouterPageRoute GetRelativeRoute(Node from, RouterPageRoute rel)
		{	
			if (!IsRootingCompleted || !from.IsRootingCompleted)
			{
				Fuse.Diagnostics.UserError( "Cannot calculate relative node if not rooted", this );
				return null;
			}
				
			var outlet = FindOutletUp(from);
			if (outlet == null)
			{
				Diagnostics.UserError( "Did not find an outlet relative to the provided Node", this );
				return null;
			}
			
			var current = GetRouteUpToRouter( (outlet as Node).Parent );
			//this might be a top-level RouterOutlet so check for a null
			var route = current == null ? rel : current.Append( rel );
			return route;
		}
		
		bool HasOtherRouter(Visual n)
		{
			var r = n.FirstChild<Router>();
			return r != null && r != this;
		}
		
		static bool HasRouter(Node n)
		{
			var v = n as Visual;
			if (v == null)
				return false;
			return v.FirstChild<Router>() != null;
		}
		
		void IBaseNavigation.GoForward() { }
		bool IBaseNavigation.CanGoForward { get { return false; } }
		
		public event HistoryChangedHandler IBaseNavigation.HistoryChanged;
		internal void OnHistoryChanged()
		{
			if (HistoryChanged != null)
				HistoryChanged(this);
		}
		
		internal static Router TryFindRouter(Node n)
		{
			var p = n;
			while (p != null)
			{
				var v = p as Visual;
				if (v != null)
				{
					var r = v.FirstChild<Router>();
					if (r != null)
						return r;
				}
				
				p = p.Parent;
			}
			
			return null;
		}
		
		RouterPage _rootPage = RouterPage.CreateDefault();
		/* The root of the navigation hierachy. */
		internal RouterPage RootPage
		{
			get { return _rootPage; }
		}
		
		/* Get a Route from the history stack, where 0 is the current route, -1 the previous, etc. */
		internal RouterPageRoute GetHistoryRoute( int at )
		{
			var gha = new GetHistoryAt{ At = at };
			var list = new List<RouterPage>();
			EnumerateHistory( gha.HistoryAction, list, _rootPage );
			return gha.Result;
		}
		
		class GetHistoryAt
		{
			public int At;
			
			public RouterPageRoute Result;
			
			public bool HistoryAction( List<RouterPage> stack )
			{
				RouterPageRoute r = null;
				for (int i=stack.Count-1; i>=0; --i)
					r = new RouterPageRoute( stack[i], r );
		
				if (At == 0)
					Result = r;
					
				At--;
				return At >= 0;
			}
		}
		
		internal int TestHistoryCount 
		{
			get
			{
				var thc = new TestHistoryCounter();
				var list = new List<RouterPage>();
				EnumerateHistory( thc.HistoryAction, list, _rootPage );
				return thc.Count - 1;
			}
		}

		class TestHistoryCounter
		{
			public int Count;

			public bool HistoryAction( List<RouterPage> stack )
			{
				Count++;
				return true;
			}
		}

		delegate bool HistoryAction( List<RouterPage> stack );
		
		bool EnumerateHistory( HistoryAction action, List<RouterPage> stack, RouterPage rp )
		{
			if (rp == null)
				return true;
			
			var cp = rp.ChildRouterPages;
			if (cp == null || cp.Count == 0)
				return action(stack);
			
			for (int i= cp.Count -1; i >= 0; --i) 
			{
				var childPage = cp[i];
				stack.Add( childPage );
				var q = EnumerateHistory( action, stack, childPage );
				stack.RemoveAt( stack.Count -1 );
				if (!q)
					return false;
			}
			
			return true;
		}

		/* An invaluable tool for debugging. */		
		internal string TestDumpHistory()
		{
			return "*\n" + TestDumpHistory(_rootPage, "");
		}
		
		string TestDumpHistory(RouterPage rp, string indent )
		{
			if (rp == null)
				return "";
				
			var cp = rp.ChildRouterPages;
			string ret = indent + rp.Path + " @" + rp.GetHashCode() + "\n";
			
			if (cp == null)
				return ret;
				
			for (int i=cp.Count - 1; i >= 0; --i)
			{
				var childPage = cp[i];
				ret += TestDumpHistory( childPage, indent + "    " );
			}
			
			return ret;
		}
	}
}