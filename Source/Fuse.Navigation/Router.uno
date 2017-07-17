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
			_history.Clear();

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
					if (_masterHistory != null)
						_history = _masterHistory;
					else
						_masterHistory = _history;
					
					UpdateManager.AddDeferredAction(GotoMasterRoute);
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
		static Route _masterCurrent;
		static List<Route> _masterHistory;
		void GotoMasterRoute()
		{
			if (_masterCurrent != null)
				SetRoute(_masterCurrent, NavigationGotoMode.Bypass, RoutingOperation.Goto, "", false);
		}
	
		static internal void TestClearMasterRoute()
		{
			_masterCurrent = null;
			_masterHistory = null;
		}
		
		internal int TestHistoryCount { get { return _history.Count; } }
		
		public Route GetCurrentRoute()
		{
			return GetCurrent(Parent);
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
					_history.Clear();
					current = SetRoute(route, mode, RoutingOperation.Goto, operationStyle);
					OnHistoryChanged(current);
					break;
					
				case ModifyRouteHow.Push:
					_history.Add( GetCurrentRoute() );
					current = SetRoute(route, mode, RoutingOperation.Push, operationStyle);
					OnHistoryChanged(current);
					break;
					
				case ModifyRouteHow.Replace:
					current = SetRoute(route, mode, RoutingOperation.Replace, operationStyle);
					OnHistoryChanged(current);
					break;
					
				case ModifyRouteHow.GoBack:
					Pop();
					break;
					
				case ModifyRouteHow.PrepareBack:
					if (route != null)
						Fuse.Diagnostics.UserWarning( "PrepareBack does not support an explicit route", this );
						
					if (_history.Count == 0)
					{
						Fuse.Diagnostics.UserError( "There is no history for PrepareBack", this );
						return;
					}
					
					var popRoute = _history[_history.Count-1];
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
			if (_history.Count > 0) Pop();
			else GoUp();
		}

		public bool CanGoBack
		{
			get
			{
				//be strict for typical use
				return _history.Count > 0;
				
				/*if (_history.Count > 0)
					return true;
					
				return GetCurrentRoute().HasUp;*/
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
				var c = SetRoute(up, NavigationGotoMode.Transition, RoutingOperation.Pop, "");
				OnHistoryChanged(c);
			}
		}

		void OnUpFromRoot()
		{
			// TODO: Raise event(?) to notify that the user has performed a GoBack
			// while already at root level. This should usually leave the app.
		}

		void Pop()
		{
			if (_history.Count == 0)
			{
				Fuse.Diagnostics.UserError( "Cannot pop() - history is empty", this );
				return;
			}

			var route = _history[_history.Count-1];
			_history.RemoveAt(_history.Count-1);
			var c = SetRoute(route, NavigationGotoMode.Transition, RoutingOperation.Pop, "");
			OnHistoryChanged(c);
		}

		List<Route> _history = new List<Route>();

		Route _prepareCurrent, _prepareNext;
		RoutingOperation _prepareOperation;
		string _prepareOperationStyle;
		double _prepareProgress = 0;
		IRouterOutlet _prepareOutlet;
		void PrepareRoute(Route r, RoutingOperation operation, string operationStyle)
		{
			_prepareCurrent = GetCurrentRoute();
			_prepareNext = SetRouteImpl(Parent, r, NavigationGotoMode.Prepare, operation, operationStyle,
				out _prepareOutlet);
			_prepareOperation = operation;
			_prepareProgress = 0;
			_prepareOperationStyle = operationStyle;
		}
		
		void FinishPrepared()
		{
			if (_prepareOutlet == null)
				return;

			//the operation implies how history is modified
			switch (_prepareOperation)
			{
				case RoutingOperation.Pop:
					if (_history.Count != 0)
						_history.RemoveAt(_history.Count-1);
					break;
					
				case RoutingOperation.Push:
					_history.Add( GetCurrentRoute() );
					break;
					
				case RoutingOperation.Goto:
					_history.Clear();
					break;
			}
			
			var c = SetRoute(_prepareNext, NavigationGotoMode.Transition, _prepareOperation,
				_prepareOperationStyle);
			OnHistoryChanged(c);
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
			//prepared routes are cleared when the actual route is changed
			ClearPrepared();
			
			var current = GetCurrentRoute();
			
			IRouterOutlet ignore;
			var outR = SetRouteImpl(Parent, r, gotoMode, operation, operationStyle, out ignore);
			if (outR == null)
			{
				var msg = "Unable to navigate to route: " + r.Format();
				if (userRequest)
					Fuse.Diagnostics.UserError( msg, this );
				else
					Fuse.Diagnostics.InternalError( msg, this );
					
				//try to cleanup on error and go to previous state
				_history.Clear();
				var c = SetRouteImpl(Parent, current, NavigationGotoMode.Bypass, RoutingOperation.Goto,
					"", out ignore);
				OnHistoryChanged(c);
				return null;
			}
			return outR;
		}
		
		Route SetRouteImpl(Visual root, Route r, NavigationGotoMode gotoMode, 
			RoutingOperation operation, string operationStyle, out IRouterOutlet majorChange)
		{	
			majorChange = null;
			var outlet = FindOutletDown(root);
			if (outlet == null)
			{
				Fuse.Diagnostics.InternalError( "No router outlet found to handle route: " + r, this );
				return null;
			}
			
			Visual active;
			string opath = r.Path;
			string oparameter = r.Parameter;
			var didTransition = outlet.Goto(ref opath, ref oparameter, gotoMode, operation, 
				operationStyle, out active);

			if (didTransition == RoutingResult.Invalid)
				return null;

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
				if (active == null)
				{
					Fuse.Diagnostics.InternalError( "SubRoute requested but outlet has no active path: " + r, this );
					return null;
				}
				else
				{
					if (trackMajorChange)
					{
						outSubRoute = SetRouteImpl(active, r.SubRoute, gotoMode, operation, 
							operationStyle, out majorChange );
					}
					else
					{
						IRouterOutlet ignore;
						outSubRoute = SetRouteImpl(active, r.SubRoute, gotoMode, operation, 
							operationStyle, out ignore );
					}
					if (outSubRoute == null)
						return null;
				}
			}
			else
			{
				outSubRoute = GetCurrent(active);
			}
			
			return new Route(opath, oparameter, outSubRoute);
		}

		Route GetCurrent(Visual from, IRouterOutlet to = null)
		{
			if (from == null)
				return null;
				
			var outlet = FindOutletDown(from);
			if (outlet == null || outlet == to)
				return null;
				
			string opath;
			string oparameter;
			outlet.GetCurrent(out opath, out oparameter, out from);
			return new Route(opath, oparameter, GetCurrent(from, to));
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
				if (v == null || !outlet.GetPath(v, out opath, out oparameter))
					outlet.GetCurrent(out opath, out oparameter, out v);
				route = new Route( opath, oparameter, route );
				
				from = (outlet as Node).Parent;
			}
			
			return route;
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
			var ro = active as IRouterOutlet;
			if (ro != null && ro.Type.HasFlag(OutletType.Outlet) ) return ro;
			
			var v = active as Visual;
			if (v != null)
			{
				//a new router breaks the chain (to allow sub-navigation)
				//must check before since it could be anywhere in the children
				if (HasOtherRouter(v))
					return null;
				
				for (int i = 0; i < v.Children.Count; i++)
				{
					ro = FindOutletDown(v.Children[i]);
					if (ro != null) return ro;
				}
			}
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
				var ro = active as IRouterOutlet;
				if (ro != null && ro.Type.HasFlag(OutletType.Outlet) ) return ro;
			
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
		
		bool HasRouter(Visual n)
		{
			return n.FirstChild<Router>() != null;
		}
		
		void IBaseNavigation.GoForward() { }
		bool IBaseNavigation.CanGoForward { get { return false; } }
		
		public event HistoryChangedHandler IBaseNavigation.HistoryChanged;
		void OnHistoryChanged(Route current)
		{
			//an error in routing (result from SetRoute passed to here)
			if (current == null)
				current = GetCurrentRoute();
				
			if (HistoryChanged != null)
				HistoryChanged(this);
				
			if (IsMasterRouter)
				_masterCurrent = current;
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
	}

	
}