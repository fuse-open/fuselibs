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
	public partial class Router : Node, IBaseNavigation
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
					if (_masterRootPage != null)
						_rootPage = _masterRootPage;
					else
						_masterRootPage = _rootPage;
				}
			}
		}

		protected override void OnUnrooted()
		{
			Fuse.Input.Keyboard.KeyPressed.RemoveGlobalHandler(OnKeyPressed);
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

		void OnKeyPressed(object sender, Fuse.Input.KeyEventArgs args)
		{
			if (args.Key == Uno.Platform.Key.BackButton)
			{
				if (BackButtonAction == BackButtonAction.GoBack) GoBack();
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

		/*
			Remembers the current route between reify updates in fuse preview.
			This is kind of a hacky solution for now just to show off a Fuse level feature. It's not
			something that would actually be used/relied on in an exported app.
		*/
		static RouterPage _masterRootPage;
	
		static internal void TestClearMasterRoute()
		{
			_masterRootPage = null;
		}
		
		public Route GetCurrentRoute()
		{
			//return GetCurrent(Parent);
			return GetHistoryRoute(0);
		}
		
		/**	Clears the history and navigates to the specified route. */
		public void Goto(Route route, string operationStyle = "")
		{
			Modify( ModifyRouteHow.Goto, route, NavigationGotoMode.Transition, operationStyle );
		}

		/** Pushes the current route (if any) on navigation history and navigates to the specified route. */
		public void Push(Route route, string operationStyle = "")
		{
			Modify( ModifyRouteHow.Push, route, NavigationGotoMode.Transition, operationStyle );
		}

		internal void Modify( ModifyRouteHow how, Route route, NavigationGotoMode mode,
			string operationStyle )
		{
			Route current = null;
			switch( how )
			{
				case ModifyRouteHow.Goto:
					current = SetRoute(route, mode, RoutingOperation.Goto, operationStyle);
					break;
					
				case ModifyRouteHow.Push:
					current = SetRoute(route, mode, RoutingOperation.Push, operationStyle);
					break;
					
				case ModifyRouteHow.Replace:
					current = SetRoute(route, mode, RoutingOperation.Replace, operationStyle);
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
		
		internal Dictionary<string,Route> Bookmarks = new Dictionary<string,Route>();
		
		/** Goes back to the previous page in the navigation history, or up one level in the route if the history is empty.
			
			If the navigation history is nonempty, this pops the previous item from the history and makes
			that the current route. 
			
			If the navigation history is empty, this method goes to a route one level above the current
			route. If the current route is already a top level route, this method does nothing. 
		*/
		public void GoBack()
		{
			if (CanGoBack) Pop();
			else GoUp();
		}

		public bool CanGoBack
		{
			get
			{
				//be strict for typical use
				return GetHistoryRoute(1) != null;
			}
		}
		
		void GoUp()
		{
			var cur = GetCurrentRoute();
			var up = cur.Up();
			if (up == cur) 
			{
				OnUpFromRoot();
			}
			else 
			{
				SetRoute(up, NavigationGotoMode.Transition, RoutingOperation.Pop, "");
			}
		}

		void OnUpFromRoot()
		{
			// TODO: Raise event(?) to notify that the user has performed a GoBack
			// while already at root level. This should usually leave the app.
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

		Route _prepareCurrent, _prepareNext;
		RoutingOperation _prepareOperation;
		string _prepareOperationStyle;
		double _prepareProgress = 0;
		IRouterOutlet _prepareOutlet;
		void PrepareRoute(Route r, RoutingOperation operation, string operationStyle)
		{
			_prepareCurrent = GetCurrentRoute();
			_prepareNext = SetRouteImpl(Parent, _rootPage, r, NavigationGotoMode.Prepare, operation, operationStyle,
				out _prepareOutlet);
			_prepareOperation = operation;
			_prepareProgress = 0;
			_prepareOperationStyle = operationStyle;
		}
		
		void FinishPrepared()
		{
			if (_prepareOutlet == null)
				return;

			var c = SetRoute(_prepareNext, NavigationGotoMode.Transition, _prepareOperation,
				_prepareOperationStyle);
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
		
		Route SetRoute(Route r, NavigationGotoMode gotoMode, RoutingOperation operation, 
			string operationStyle, bool userRequest = true)
		{
			if (r == null)
				throw new Exception( "Route cannot be null" );
				
			//prepared routes are cleared when the actual route is changed
			ClearPrepared();
			
			var current = GetCurrentRoute();
			
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
		Route SetRouteImpl(Visual root, RouterPage rootPage, Route r, NavigationGotoMode gotoMode, 
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
			
			RouterPage page;
			if (r.RouterPage != null)
				page = r.RouterPage;
			else
				page = new RouterPage{ Path = r.Path, Parameter = r.Parameter };
			var didTransition = outlet.CompareCurrent(page);
			if (didTransition == RoutingResult.Invalid)
				return null;
			
			//pushing/goto up to the leaf route can reuse existing matching pages
			bool leafPush = r.SubRoute == null && operation == RoutingOperation.Push;
			bool reusePage = canReuse && didTransition == RoutingResult.NoChange && !leafPush;
			if (reusePage)
				page = outlet.GetCurrent();
			
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
				didTransition = outlet.Goto(page, gotoMode, operation, operationStyle);
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

			Route outSubRoute = null;
			if (r.SubRoute != null)
			{
				if (page.Visual == null)
				{
					Fuse.Diagnostics.InternalError( "SubRoute requested but outlet has no active path: " + r, this );
					return null;
				}
				
				IRouterOutlet subMajorChange;
				outSubRoute = SetRouteImpl(page.Visual, page, r.SubRoute, gotoMode, operation, 
					operationStyle, out subMajorChange, reusePage );
				if (trackMajorChange)
					majorChange = subMajorChange;
				if (outSubRoute == null)
					return null;
			}
			else
			{
				outSubRoute = GetCurrent(page.Visual);
			}
			
			return new Route(page.Path, page.Parameter, outSubRoute);
		}
		
		Route GetCurrent(Visual from, IRouterOutlet to = null)
		{
			if (from == null)
				return null;
				
			var outlet = FindOutletDown(from);
			if (outlet == null || outlet == to)
				return null;
				
			var page = outlet.GetCurrent();
			return new Route( page.Path, page.Parameter, GetCurrent(page.Visual, to));
		}
		
		Route GetRouteUpToRouter(Node from)
		{
			Route route = null;
			
			while (from != null)
			{
				Node page;
				var outlet = FindOutletUp(from, out page);
				if (outlet == null)
					break;
					
				string opath = "";
				string oparameter = "";
				var v = page as Visual;
				var pd = v != null ? PageData.Get(v) : null;
				if (pd == null || pd.RouterPage == null)
				{
					var opage = outlet.GetCurrent();
					opath = opage.Path;
					oparameter = opage.Parameter;
					v = opage.Visual;
				}
				else
				{
					opath = pd.RouterPage.Path;
					oparameter = pd.RouterPage.Parameter;
				}
				route = new Route( opath, oparameter, route );
				
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
		
		RouterPage _rootPage = new RouterPage();
		/* The root of the navigation hierachy. */
		internal RouterPage RootPage
		{
			get { return _rootPage; }
		}
		
		/* Get a Route from the history stack, where 0 is the current route, -1 the previous, etc. */
		internal Route GetHistoryRoute( int at )
		{
			var gha = new GetHistoryAt{ At = at };
			var list = new List<RouterPage>();
			EnumerateHistory( gha.HistoryAction, list, _rootPage );
			return gha.Result;
		}
		
		class GetHistoryAt
		{
			public int At;
			
			public Route Result;
			
			public bool HistoryAction( List<RouterPage> stack )
			{
				Route r = null;
				for (int i=stack.Count-1; i>=0; --i)
				{
					r = new Route( stack[i].Path, stack[i].Parameter, r );
					r.RouterPage = stack[i];
				}
		
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