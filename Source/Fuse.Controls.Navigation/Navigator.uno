using Uno;
using Uno.UX;
using Uno.Collections;

using Fuse.Animations;
using Fuse.Elements;
using Fuse.Internal;
using Fuse.Navigation;
using Fuse.Triggers;

namespace Fuse.Controls
{
	/** General-purpose navigation container with on-demand instantiation and recycling of pages.
		
		@include Docs/Navigator.md
	*/
	public partial class Navigator: NavigationControl, IRouterOutlet 
	{
		/**
			@deprecated Use `DefaultPath` instead
		*/
		public string DefaultTemplate 
		{ 
			get { return DefaultPath; }
			set 
			{ 
				DefaultPath = value; 
				//deprecated: 2016-10-20
				Fuse.Diagnostics.Deprecated( "Use `DefaultPath` instead of `DefaultTemplate`", this );
			}
		}
		
		/**
			Whenever a null or  empty path is specified, use this path instead.  This can select either a template or non-template.
			
			This will also be the page used when the navigator is first initialized, prior to any routing operation. If no default is specified then there will be no active page.
		*/
		public string DefaultPath { get; set; }

		NavigatorGotoState _gotoState = NavigatorGotoState.BringToFront;
		/**
			How is the state of the current @Visual modified after a Goto or Push operation.
			
			The default is `BringToFront`.
			
			If you are creating a custom transition you may also need to modify this setting.
		*/
		public NavigatorGotoState GotoState
		{
			get { return _gotoState; }
			set { _gotoState = value; }
		}
		
		public Navigator()
		{
			//defaults for NavigationControl
			_transition = NavigationControlTransition.Standard;
			
			SetNavigation( new ExplicitNavigation() );
		}

		new Fuse.Navigation.ExplicitNavigation Navigation
		{
			get { return base.Navigation as Fuse.Navigation.ExplicitNavigation; }
		}
		
		MiniList<object> _activeTransitions;
		internal void SetTransitionState(object owner, bool on)
		{
			if (!on)
				_activeTransitions.Remove(owner);
			else if (!_activeTransitions.Contains(owner))
				_activeTransitions.Add(owner);
			UpdateNavigationState();
		}
		
		void UpdateNavigationState()
		{
			var hasTrans = _activeTransitions.Count > 0;
			var hasDefer = _deferred != null;
			var hasPrepared = _prepared != null;
			var isOn = hasTrans || hasDefer;
			// Preparing is used with PartialPrepareGoto which implies a Seek
			Navigation.SetState( hasPrepared ? NavigationState.Seek :
				isOn ? NavigationState.Transition : NavigationState.Stable);
		}
		
		protected override void OnRooted()
		{
			base.OnRooted();
			
			RootInteraction();
			
			_current = new NavPage();
			//the rooting of children could place them in invalid states, fix that now
			CleanupChildren(null);
			Navigation.UpdateProgress(NavigationMode.Bypass);
		
			Visual ignore;
			var pages = AncestorRouterPage != null ? AncestorRouterPage.ChildRouterPages : null;
			if (pages != null && pages.Count > 0)
			{
				((IRouterOutlet)this).Goto( pages[pages.Count-1], NavigationGotoMode.Bypass, 
					RoutingOperation.Goto, "", out ignore );
			}
			else
			{
				if (DefaultPath != null)
				{
					_current = new NavPage{ RouterPage = new RouterPage( DefaultPath ) };
					((IRouterOutlet)this).Goto(_current.RouterPage, NavigationGotoMode.Bypass,
						RoutingOperation.Goto, "", out _current.Visual);
				}
				if (pages != null)
					pages.Add( _current.RouterPage );
			}
		}
		
		protected override void OnUnrooted()
		{
			UnrootInteraction();
			base.OnUnrooted();
		}
		
		Visual _previous;
		Visual _next;
		
		Dictionary<string, List<Visual>> _pathCache = new Dictionary<string,List<Visual>>();

		List<Visual> GetCache(string path)
		{
			if (_pathCache.ContainsKey(path))
				return _pathCache[path];
				
			var v = new List<Visual>();
			_pathCache[path] = v;
			return v;
		}
		
		OutletType IRouterOutlet.Type { get { return RouterOutletType; } }

		bool _prepareBack;
		void IRouterOutlet.PartialPrepareGoto(double progress)
		{
			if (_prepared == null)
			{
				Fuse.Diagnostics.InternalError( "PartialPrepareGoto without Prepare", this );
				return;
			}
		
			//it may be an explicit null (for Nav without a default template)
			var preparedVisual = _prepared.Visual;
			if (preparedVisual != null)
				Navigation.SetPageProgress(preparedVisual, 
					_prepareBack ? (float)progress-1 : (1 -(float)progress), false);
				
			var currentVisual = _current.Visual;
			if (currentVisual != null)
				Navigation.SetPageProgress(currentVisual, 
					_prepareBack ? (float)progress : -(float)progress, false);
			Navigation.UpdateProgress(NavigationMode.Seek);
		}
		
		void IRouterOutlet.CancelPrepare()
		{
			if (_prepared == null)
			{
				Fuse.Diagnostics.InternalError( "PartialPrepareGoto without Prepare", this );
				return;
			}

			CleanupPrepared();
			Navigation.UpdateProgress(NavigationMode.Switch);
			UpdateNavigationState();
		}
		
		struct PrepareResult
		{
			public RoutingResult Routing;
			public bool UsedPrepared;
			public NavPage Page;
		}
		
		/* This unfortunately has to duplicate logic from various locations in Prepare. The Router
			needs to know in advacned what will happen without anything changing. */
		RoutingResult IRouterOutlet.CompareCurrent(RouterPage routerPage, out Visual pageVisual)
		{
			pageVisual = null;
			Visual currentVisual;
			var current = (this as IRouterOutlet).GetCurrent(out currentVisual);
			
			if (DefaultPath != null)
				routerPage.DefaultPath( DefaultPath );
				
			if (routerPage.Path != current.Path || (currentVisual == null && routerPage.Path != null))
				return RoutingResult.Change;
				
			pageVisual = currentVisual;
			if (routerPage.Parameter == current.Parameter &&
				routerPage.Context == current.Context)
				return RoutingResult.NoChange;
				
			return RoutingResult.MinorChange;
		}
		
		PrepareResult Prepare(NavPage curPage, 
			RouterPage routerPage, RoutingOperation operation)
		{
			if (DefaultPath != null)
				routerPage.DefaultPath( DefaultPath );
				
			var curPageVisual = curPage.Visual;
			if (routerPage.Path == curPage.RouterPage.Path && curPageVisual != null)
			{
				//no change
				if (routerPage.Parameter == curPage.RouterPage.Parameter &&
					routerPage.Context == curPage.RouterPage.Context)
					return new PrepareResult{ Page = curPage, Routing = RoutingResult.NoChange };
					
				// https://github.com/fusetools/fuselibs-private/issues/2982
				var compat = CommonNavigation.CompatibleParameter(routerPage.Parameter, curPage.RouterPage.Parameter) && routerPage.Context == curPage.RouterPage.Context;
					
				//reusable page with parameter change
				var reuse = operation == RoutingOperation.Goto && IsReuseLevel(curPageVisual, ReuseType.Any);
					
				var replace = operation == RoutingOperation.Replace &&
					IsReuseLevel(curPageVisual, ReuseType.Replace);
					
				//always reuse non-templates as there is only one
				var nonTemplate = !GetControlPageData(curPageVisual).FromTemplate;
					
				if (compat || reuse || replace || nonTemplate)
				{
					var np = new NavPage{ Visual = curPageVisual, RouterPage = routerPage };
					var result = new PrepareResult{ Page = np, Routing = RoutingResult.MinorChange };
					PageData.GetOrCreate(curPageVisual).AttachRouterPage(result.Page.RouterPage);
					return result;
				}
			}
			
			var preparedVisual = _prepared != null ? _prepared.Visual : null;
			if (curPage != _prepared && preparedVisual != null)
			{
				if (_prepared.RouterPage.Path == routerPage.Path && 
					_prepared.RouterPage.Parameter == routerPage.Parameter)
				{
					PageData.GetOrCreate(preparedVisual).AttachRouterPage(_prepared.RouterPage);
					return new PrepareResult{ Page = _prepared, Routing = RoutingResult.Change,
						UsedPrepared = true };
				}
			}
			
			Visual useVisual = null;
			if (routerPage.Path == null) //this is a valid path element  https://github.com/fusetools/fuselibs-private/issues/1869
			{
				useVisual = null;
			}
			else
			{
				var cache = GetCache(routerPage.Path);

				//prefer pages that result in the least least change in state
				int priority = 0;
				int useAt = -1;
				for (int i = 0; i < cache.Count; i++)
				{
					var c = cache[i];
					// Don't reuse pages currently being remove-animated
					if (c.HasPendingRemove)
						continue;
						
					var np = 0;
					if (c.IsRootingStarted)
					{
						if (c.Parameter == routerPage.Parameter)
							np = 10; //always reuse the exact same page
						else if (IsReuseLevel(c, ReuseType.Inactive))
							np = 5;
					}
					else if(IsReuseLevel(c, ReuseType.Removed))
						np = 1;
					
					if (np > priority)
					{
						priority = np;
						useAt = i;
						useVisual = c;
					}
				}
				
				if (useAt >= 0)
					cache.RemoveAt(useAt);

				if (useVisual == null)
				{
					useVisual = GetVisual(routerPage.Path);
					if (useVisual == null)
						return new PrepareResult{ Routing = RoutingResult.Invalid };
				}
			}

			if (useVisual != null)
			{
				PageData.GetOrCreate(useVisual).AttachRouterPage(routerPage);
				if (!Children.Contains(useVisual))
					Children.Add(useVisual);
			}

			var nvp = new NavPage{ Visual = useVisual, RouterPage = routerPage };
			return new PrepareResult{ Page = nvp, Routing = RoutingResult.Change };
		}
		
		/* Should be called whenever the RouterPage.Visual is about to be cleared or replaced.*/
		void AddToCache(NavPage page, Visual target)
		{
			var visual = page.Visual;
			if (visual == target)
				return;
				
			//cache templates that can be reused
			if (visual != null && page.RouterPage.Path != null && IsReuseLevel(visual, ReuseType.Removed)
				&& GetControlPageData(visual).FromTemplate)
				GetCache(page.RouterPage.Path).Add(visual);
		}
		
		void CleanupPrepared(Visual newTarget = null)
		{
			if (_prepared == null)
				return;
				
			var visual = _prepared.Visual;
			if (visual != _current.Visual && visual != null && visual != newTarget)
			{
				//this can happen if Prepare is called while in the middle of another prepare
				Navigation.SetPageProgress( visual, _prepareBack ? 1 : -1 );
			}

			AddToCache(_prepared, newTarget);
			_prepared = null;
		}
		
		//this is the simplest way to test things (like Pages) that should invoke `Goto`. 
		extern(UNO_TEST) internal Action<RouterPage, NavigationGotoMode, RoutingOperation, 
			string,RoutingResult> _testInterceptGoto;
		
		RoutingResult IRouterOutlet.Goto(RouterPage routerPage, NavigationGotoMode gotoMode, 
			RoutingOperation operation, string operationStyle, out Visual pageVisual)
		{
			var result = GotoImpl(routerPage, gotoMode, operation, operationStyle, out pageVisual);
			
			if defined(UNO_TEST)
			{
				if (_testInterceptGoto != null)
					_testInterceptGoto(routerPage, gotoMode, operation, operationStyle, result);
			}
			
			return result;
		}
		
		RoutingResult GotoImpl(RouterPage routerPage, NavigationGotoMode gotoMode, 
			RoutingOperation operation, string operationStyle, out Visual pageVisual)
		{
			pageVisual = null;
			
			if (gotoMode == NavigationGotoMode.Prepare)
			{
				CleanupPrepared();
				
				var r = Prepare(_current, routerPage, operation);
				if (r.Routing == RoutingResult.Invalid)
					return RoutingResult.Invalid;
				_prepared = r.Page;
				
				_prepareBack = operation == RoutingOperation.Pop;
				
				var args = new NavigatorSwitchedArgs(this){
					OldPath = _current.RouterPage.Path,
					NewPath = _prepared.RouterPage.Path,
					OldParameter = _current.RouterPage.Parameter,
					NewParameter = _prepared.RouterPage.Parameter,
					OldVisual = _current.Visual,
					NewVisual = _prepared.Visual,
					Operation = operation,
					OperationStyle = operationStyle,
					Mode = gotoMode };
				OnSwitched(args);
				
				pageVisual = _prepared.Visual;
				UpdateNavigationState();
				return r.Routing;
			}
				
			//force a pending deferred to resolve
			ResolveDeferred();
			
			var result = Prepare(_current, routerPage, operation);
			if (result.Routing == RoutingResult.Invalid)
				return result.Routing;
				
			if (result.Page == null)
			{
				Fuse.Diagnostics.InternalError( "Unexpected null page", this );
				return RoutingResult.Invalid;
			}
			pageVisual = result.Page.Visual;
			
			if (result.Routing != RoutingResult.Change)
			{
				_current = result.Page;
				return result.Routing;
			}

			CleanupPrepared(result.Page.Visual);
			SwitchToPage(result.Page, gotoMode, operation, operationStyle, result.UsedPrepared);
			return RoutingResult.Change;
		}
		
		Visual GetVisual(string path)
		{
			var f = FindTemplate(path);
			if (f != null)
				return InstantiateTemplate(f, path);
		
			var q = FindPage(new Selector(path));
			if (q != null)
				return q;
				
			//Not UserError since we can't be certain it's trivially the users problem due to static
			//history in the router
			Fuse.Diagnostics.InternalError( "Can not navigate to '" + path + "', not found!", this );
			return null;
		}
		
		Visual InstantiateTemplate(Template f, string path)
		{
			var useVisual = f.New() as Visual;
			if (useVisual == null) 
			{
				Fuse.Diagnostics.UserError( "Result of '" + path + "' template is not a Visual!", this );
				return null;
			}
			useVisual.Name = path; //TODO: what is overwritten, maybe a private variable is needed
			GetControlPageData(useVisual).FromTemplate = true;
			return useVisual;
		}
		
		Visual FindPage(Selector path)
		{
			for (var c = FirstChild<Visual>(); c != null; c = c.NextSibling<Visual>())
			{
				if (c.Name != path)
					continue;
					
				if (GetControlPageData(c).FromTemplate)
					continue;
					
				return c;
			}
			
			return null;
		}
		
		class NavPage
		{
			public Visual Visual;
			public RouterPage RouterPage;
			
			public NavPage()
			{
				RouterPage = RouterPage.CreateDefault();
			}
		}
		
		NavPage _current = new NavPage();
		NavPage _prepared;
		
		RouterPage IRouterOutlet.GetCurrent(out Visual pageVisual)
		{
			//the _deferred is the effective current path (even if not yet the active node)
			if (_deferred != null)
			{
				pageVisual = _deferred.Page.Visual;
				return _deferred.Page.RouterPage;
			}
			pageVisual = _current.Visual;
			return _current.RouterPage;
		}
		
		/*
			The current page should be transitioned to this new one. This prepares that transition, but
			may delay it waiting for the page's busy status to clear.
		*/
		void SwitchToPage(NavPage newPage, 
			NavigationGotoMode gotoMode, RoutingOperation operation, string operationStyle,
			bool usedPrepared)
		{
			var args = new NavigatorSwitchedArgs(this){
				OldPath = _current.RouterPage.Path,
				NewPath = newPage.RouterPage.Path,
				OldParameter = _current.RouterPage.Parameter,
				NewParameter = newPage.RouterPage.Parameter,
				OldVisual = _current.Visual,
				NewVisual = newPage.Visual,
				Operation = operation,
				OperationStyle = operationStyle,
				Mode = gotoMode };
			OnSwitched(args);
			
			var newVisual = newPage.Visual;
			if (newVisual != null && !usedPrepared)
			{
				//force page into desired current state (TODO: only when necessary -- reuse)
				var ds = operation == RoutingOperation.Pop ? -1 : 
					operation == RoutingOperation.Goto ? 1 : 1;
					
				Navigation.SetPageProgress(newVisual, ds, ds, false);
				Navigation.UpdateProgress(NavigationMode.Bypass);
			}
			
			_deferred = new DeferSwitch{
				Page = newPage,
				GotoMode = gotoMode,
				Operation = operation};
			CleanupListenBusy();
			UpdateNavigationState();
			UpdateManager.AddDeferredAction( SwitchDeferred, LayoutPriority.Later );
		}
		
		void CleanupListenBusy()
		{
			_listenTimeout = false;
			if (_listenBusy != null)
			{
				BusyTask.RemoveListener(_listenBusy, BusyChanged);
				UpdateManager.RemoveAction(OnUpdate);
				_listenBusy =  null;
			}
		}
		
		Node _listenBusy;
		double _listenStart;
		bool _listenTimeout = false;
		void BusyChanged()
		{
			UpdateManager.AddDeferredAction( SwitchDeferred, LayoutPriority.Later );
		}
		
		void OnUpdate()
		{
			var elapsed = Time.FrameTime - _listenStart;
			if (elapsed > DeferPageSwitchTimeout)
			{
				_listenTimeout = true;
				UpdateManager.AddDeferredAction( SwitchDeferred, LayoutPriority.Later );
			}
		}
		
		BusyTaskActivity _deferPageSwitch = BusyTaskActivity.Preparing;
		/**
			Defers the transition to a page until it is not busy. This property specifies which busy activities block the transition to the page.
		*/
		public BusyTaskActivity DeferPageSwitch
		{
			get { return _deferPageSwitch; }
			set { _deferPageSwitch = value; }
		}
		
		float _deferPageSwitchTimeout = 1;
		/**
			Limits how long should be waited for a deferred page switch.
			
			This is useful to prevent an unexpected preparation failure from blocking the transition forever.
		*/
		public float DeferPageSwitchTimeout
		{
			get { return _deferPageSwitchTimeout; }
			set { _deferPageSwitchTimeout = value; }
		}
		
		/* Deferred action that checks if the page can be switched now */
		void SwitchDeferred()
		{
			var deferred = _deferred;
			if (deferred == null)
				return;
				
			var deferredVisual = deferred.Page.Visual;
			if (deferredVisual != null && !_listenTimeout)
			{
				var busy = BusyTask.GetBusyActivity(deferredVisual);
				if ( (busy & DeferPageSwitch) != BusyTaskActivity.None)
				{
					if (_listenBusy == null)
					{
						_listenBusy = deferredVisual;
						_listenStart = Time.FrameTime;
						_listenTimeout = false;
						BusyTask.AddListener(_listenBusy, BusyChanged);
						UpdateManager.AddAction(OnUpdate);
					}
					return;
				}
			}
			
			ResolveDeferred();
		}
		
		void ResolveDeferred()
		{
			if (_deferred == null)
				return;
				
			var deferred = _deferred;
			_deferred = null;
			
			//cleanup old visual
			var deferredVisual = deferred.Page.Visual;
			var currentVisual = _current.Visual;
			if (deferredVisual != currentVisual && currentVisual != null &&
				deferred.Operation != RoutingOperation.Goto)
			{
				Navigation.SetPageProgress(currentVisual, 
					deferred.Operation == RoutingOperation.Push ? -1 : 1, 0, false );
			}

			AddToCache(_current, deferredVisual);
			_current = deferred.Page;
			
			//in goto drop all other children
			if (deferred.Operation == RoutingOperation.Goto)
				CleanupChildren(deferredVisual);
			
			if (deferredVisual != null && GotoState == NavigatorGotoState.BringToFront)
				BringToFront(deferredVisual); //for new nodes and reused ones, ensure in front by default
	
			Navigation.Goto(deferredVisual, deferred.GotoMode);
			
			CheckInteraction();
			UpdateNavigationState();
		}
		
		class DeferSwitch
		{
			public NavPage Page;
			public NavigationGotoMode GotoMode;
			public RoutingOperation Operation;
		}
		DeferSwitch _deferred;
		
		void OnSwitched(NavigatorSwitchedArgs args)
		{
			if (Switched != null)
				Switched(this,args);
		}
		
		void CleanupChildren(Visual exclude = null)
		{
			for (var c = LastChild<Visual>(); c != null; c = c.PreviousSibling<Visual>())
			{
				if (Fuse.Navigation.Navigation.IsPage(c) && c != exclude)
				{
					if (IsRemoveLevel(c, RemoveType.Cleared) || GetReuse(c) == ReuseType.None)
						BeginRemoveChild(c);
					else if (Math.Abs(Navigation.GetPageState(c).Progress) < 1) //ensure it isn't active
						Navigation.SetPageProgress(c, -1, -1, false);
				}
			}
		}
		
		internal event NavigationSwitchedHandler Switched;
		
		protected override void CreateTriggers(Element c, ControlPageData pd)
		{
			switch (PageTransition(c))
			{
				case NavigationControlTransition.None:
					break;
					
				case NavigationControlTransition.Standard:
					pd.Enter = new NavigationInternal.NavEnterHorizontal();
					pd.Exit = new NavigationInternal.NavExitHorizontal();
					
					var q = new NavigationInternal.NavRemoveHorizontal();
					var t = new Element_Opacity_Property(c);
					var fade = new Change<float>(t);
					fade.Duration = 0.3f;
					fade.Value = 0;
					q.Animators.Add(fade);
					pd.Removing = q;
					break;
			}
		}

		static PropertyHandle _propReuse = Properties.CreateHandle();
		[UXAttachedPropertySetter("Navigator.Reuse")]
		static public void SetReuse(Visual elm, ReuseType value)
		{
			elm.Properties.Set(_propReuse, value);
		}

		[UXAttachedPropertyGetter("Navigator.Reuse")]
		static public ReuseType GetReuse(Visual elm)
		{
			object res;
			if (elm.Properties.TryGet(_propReuse,out res))
				return (ReuseType)res;
			return ReuseType.Default;
		}
		
		ReuseType _reuse = ReuseType.Replace;
		/**
			Specifies when a page can be reused in navigation, either with the same, or a different parameter. Only pages of the same type are ever reused. Reusing pages avoids the overhead of instantiating new objects and/or adding new items to the UI tree.
			
			The default is `Inactive`.
			
			This can be overridden for individual pages using the `Navigator.Reuse` property on the page.
			
			This property affects template pages only. Non-templates are always reused.
		*/
		public ReuseType Reuse
		{
			get { return _reuse; }
			set { _reuse = value; }
		}
		
		bool IsReuseLevel(Visual elm, ReuseType type)
		{
			//non-template pages are always reused (since multiples can't exist)
			if (!GetControlPageData(elm).FromTemplate)
				return true;
				
			var q = GetReuse(elm);
			if (q == ReuseType.Default)
				q = Reuse;
				
			return (int)q >= (int)type;
		}

		
		static PropertyHandle _propRemove = Properties.CreateHandle();
		[UXAttachedPropertySetter("Navigator.Remove")]
		static public void SetRemove(Visual elm, RemoveType value)
		{
			elm.Properties.Set(_propRemove, value);
		}

		[UXAttachedPropertyGetter("Navigator.Remove")]
		static public RemoveType GetRemove(Visual elm)
		{
			object res;
			if (elm.Properties.TryGet(_propRemove,out res))
				return (RemoveType)res;
			return RemoveType.Default;
		}
		
		RemoveType _remove = RemoveType.Cleared;
		/**
			Specifies when pages are removed from the `Navigator`. Removed pages are no longer part of the UI tree and can thus release their resources. A removed page may still be reused, refer to `Reuse`.
			
			The default is `Cleared`.
			
			This can be overridden for individual pages using the `Navigator.Remove` property on the page.
			
			This property affects only template pages. Non-templates are never removed.
		*/
		public new RemoveType Remove
		{
			get { return _remove; }
			set { _remove = value; }
		}
		
		bool IsRemoveLevel(Visual elm, RemoveType type)
		{
			//only template pages get removed
			if (!GetControlPageData(elm).FromTemplate)
				return false;
				
			var q = GetRemove(elm);
			if (q == RemoveType.Default)
				q = Remove;
				
			return (int)q >= (int)type;
		}

		internal void ReleasePage(Visual v)
		{
			//include ReuseType.None since otherwise they'd linger as children, but remain unusable
			if (IsRemoveLevel(v, RemoveType.Released) || GetReuse(v) == ReuseType.None)
				BeginRemoveChild(v);
		}
		
		protected override void OnChildRemoved(Node elm)
		{
			if (elm == _current.Visual)
				Fuse.Diagnostics.InternalError( "Removing child!" );
			if (_deferred != null && _deferred.Page.Visual == elm)
				Fuse.Diagnostics.InternalError( "removing deferred child" );
			if (_prepared != null && _prepared.Visual == elm)
				Fuse.Diagnostics.InternalError( "removing prepared child" );
			base.OnChildRemoved(elm);
		}

		/** The stack of pages that is the history of this navigator. Only the top-most page will be active. Changes in the list will activate/deactive pages. */
		public IArray Pages
		{
			get { return PageHistory; }
			set { PageHistory = value; }
		}
	}
	
	class Element_Opacity_Property: Uno.UX.Property<float>
	{
		Element _obj;
		public Element_Opacity_Property(Element obj) : base("Opacity") { _obj = obj; }
		public override global::Uno.UX.PropertyObject Object { get { return _obj; } }
		public override float Get(PropertyObject obj) { return ((Element)obj).Opacity; }
		public override void Set(PropertyObject obj, float v, global::Uno.UX.IPropertyListener origin) { ((Element)obj).SetOpacity(v, origin); }
		public override bool SupportsOriginSetter { get { return true; } }
	}
	
}