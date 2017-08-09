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
			var isOn = hasTrans || hasDefer;
			Navigation.SetState(isOn ? NavigationState.Transition : NavigationState.Stable);
		}
		
		protected override void OnRooted()
		{
			base.OnRooted();
			
			RootInteraction();
			
			//the rooting of children could place them in invalid states, fix that now
			CleanupChildren(_current.Visual);
			Navigation.UpdateProgress(NavigationMode.Bypass);
			
			if (DefaultPath != null)
			{
				var path = DefaultPath;
				string parameter = null;
				Visual active = null;
				(this as IRouterOutlet).Goto(ref path, ref parameter, NavigationGotoMode.Bypass,
					RoutingOperation.Goto, "", out active);
			}
			else
			{
				_current.Visual = null;
				_current.Path = null;
				_current.Parameter = null;
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

		bool IsEmptyParameter(string a)
		{
			//the last tests are for a JS empty string, empty object, and null. The value is expected to be a JSON
			//serialized string.
			return a == null || a == "" || a == "\"\"" || a == "{}" || a == "null";
		}
		
		bool CompatibleParameter( string a, string b )
		{
			if (a == b)
				return true;
				
			return IsEmptyParameter(a) && IsEmptyParameter(b);
		}

		bool _prepareReady;
		bool _prepareBack;
		void IRouterOutlet.PartialPrepareGoto(double progress)
		{
			if (!_prepareReady)
			{
				Fuse.Diagnostics.InternalError( "PartialPrepareGoto without Prepare", this );
				return;
			}
		
			//it may be an explicit null (for Nav without a default template)
			if (_prepared.Visual != null)
				Navigation.SetPageProgress(_prepared.Visual, 
					_prepareBack ? (float)progress-1 : (1 -(float)progress), false);
				
			Navigation.SetPageProgress(_current.Visual, 
				_prepareBack ? (float)progress : -(float)progress, false);
			Navigation.UpdateProgress(NavigationMode.Seek);
		}
		
		void IRouterOutlet.CancelPrepare()
		{
			if (!_prepareReady)
			{
				Fuse.Diagnostics.InternalError( "PartialPrepareGoto without Prepare", this );
				return;
			}

			CleanupPrepared();
			Navigation.UpdateProgress(NavigationMode.Switch);
		}
		
		RoutingResult Prepare(NavPage curPage, 
			ref string path, ref string parameter, RoutingOperation operation, out Visual result,
			out bool usedPrepared)
		{
			result = null;
			usedPrepared = false;
			
			if ( (path == null || path == "") && DefaultPath != null)
				path = DefaultPath;
				
			if (path == curPage.Path && curPage.Visual != null)
			{
				result = curPage.Visual;
				
				//no change
				if (parameter == curPage.Parameter)
					return RoutingResult.NoChange;
					
				// https://github.com/fusetools/fuselibs/issues/2982
				var compat = CompatibleParameter(parameter, curPage.Parameter);
					
				//reusable page with parameter change
				var reuse = operation == RoutingOperation.Goto && IsReuseLevel(curPage.Visual, ReuseType.Any);
					
				var replace = operation == RoutingOperation.Replace &&
					IsReuseLevel(curPage.Visual, ReuseType.Replace);
					
				//always reuse non-templates as there is only one
				var nonTemplate = !GetPageData(curPage.Visual).FromTemplate;
					
				if (compat || reuse || replace || nonTemplate)
				{
					curPage.Visual.Prepare(parameter);
					curPage.Parameter = parameter;
					return RoutingResult.MinorChange;
				}
			}
			
			if (curPage != _prepared && _prepared.Visual != null)
			{
				if (_prepared.Path == path && _prepared.Parameter == parameter)
				{
					AddToCache(curPage, _prepared.Visual);
					curPage.CopyFrom(_prepared);
					curPage.Visual.Prepare(parameter);
					result = curPage.Visual;
					usedPrepared = true;
					return RoutingResult.Change;
				}
			}
			
			Visual useVisual = null;
			if (path == null) //this is a valid path element  https://github.com/fusetools/fuselibs/issues/1869
			{
				useVisual = null;
			}
			else
			{
				var cache = GetCache(path);

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
						if (c.Parameter == parameter)
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
					useVisual = GetVisual(path);
					if (useVisual == null)
						return RoutingResult.Invalid;
				}
			}

			if (useVisual != null)
			{
				useVisual.Prepare(parameter);
				if (!Children.Contains(useVisual))
					Children.Add(useVisual);
			}
				
			result = useVisual;
			return RoutingResult.Change;
		}
		
		/* Should be called whenever the NavPage.Visual is about to be cleared or replaced.*/
		void AddToCache(NavPage page, Visual target)
		{
			if (page.Visual == target)
				return;
				
			//cache templates that can be reused
			if (page.Visual != null && page.Path != null && IsReuseLevel(page.Visual, ReuseType.Removed)
				&& GetPageData(page.Visual).FromTemplate)
				GetCache(page.Path).Add(page.Visual);
		}
		
		void CleanupPrepared(Visual newTarget = null)
		{
			if (_prepared.Visual != _current.Visual && _prepared.Visual != null)
			{
				//this can happen if Prepare is called while in the middle of another prepare
				Navigation.SetPageProgress( _prepared.Visual, _prepareBack ? 1 : -1 );
			}

			AddToCache(_prepared, newTarget);
			_prepared.Reset();
			_prepareReady = false;
		}
		
		//this is the simplest way to test things (like Pages) that should invoke `Goto`. 
		extern(UNO_TEST) internal Action<string, string, NavigationGotoMode, RoutingOperation, string> _testInterceptGoto;
		
		RoutingResult IRouterOutlet.Goto(ref string path, ref string parameter, NavigationGotoMode gotoMode, 
			RoutingOperation operation, string operationStyle, out Visual active)
		{
			if defined(UNO_TEST)
			{
				if (_testInterceptGoto != null)
					_testInterceptGoto(path, parameter, gotoMode, operation, operationStyle );
			}
				
			if (gotoMode == NavigationGotoMode.Prepare)
			{
				CleanupPrepared();
				_prepared.CopyFrom(_current);
				bool ignore;
				var r = Prepare(_prepared, ref path, ref parameter, operation, out active, out ignore);
				_prepared.Visual = active;
				_prepared.Path = path;
				_prepared.Parameter = parameter;
				
				_prepareReady = true;
				_prepareBack = operation == RoutingOperation.Pop;
				
				var args = new NavigatorSwitchedArgs(this){
					OldPath = _current.Path,
					NewPath = path,
					OldParameter = _current.Parameter,
					NewParameter = parameter,
					OldVisual = _current.Visual,
					NewVisual = active,
					Operation = operation,
					OperationStyle = operationStyle,
					Mode = gotoMode };
				OnSwitched(args);
				return r;
			}
				
			//force a pending deferred to resolve
			ResolveDeferred();
			
			bool usedPrepared;
			var result = Prepare(_current, ref path, ref parameter, operation, out active, out usedPrepared);
			if (result != RoutingResult.Change)
				return result;

			CleanupPrepared(active);
			SwitchToPage(path, parameter, active, gotoMode, operation, operationStyle, usedPrepared);
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
			GetPageData(useVisual).FromTemplate = true;
			return useVisual;
		}
		
		Visual FindPage(Selector path)
		{
			for (var c = FirstChild<Visual>(); c != null; c = c.NextSibling<Visual>())
			{
				if (c.Name != path)
					continue;
					
				if (GetPageData(c).FromTemplate)
					continue;
					
				return c;
			}
			
			return null;
		}
		
		class NavPage
		{
			public string Path;
			public string Parameter;
			public Visual Visual;
			
			public void Reset()
			{
				Path = null;
				Parameter = null;
				Visual = null;
			}
			
			public void CopyFrom(NavPage o)
			{
				Path = o.Path;
				Parameter = o.Parameter;
				Visual = o.Visual;
			}
		}
		NavPage _current = new NavPage();
		NavPage _prepared = new NavPage();
		
		void IRouterOutlet.GetCurrent(out string path, out string parameter, out Visual active)
		{
			//the _deferred is the effective current path (even if not yet the active node)
			if (_deferred != null)
			{
				path = _deferred.Path;
				parameter = _deferred.Parameter;
				active = _deferred.Page;
			}
			else
			{
				path = _current.Path;
				parameter = _current.Parameter;
				active = _current.Visual;
			}
		}
		
		bool IRouterOutlet.GetPath(Visual active, out string path, out string parameter)
		{
			path = active.Name;
			parameter = active.Parameter;
			return active.Parent == this;
		}

		/*
			The current page should be transitioned to this new one. This prepares that transition, but
			may delay it waiting for the page's busy status to clear.
		*/
		void SwitchToPage(string path, string parameter, Visual v, 
			NavigationGotoMode gotoMode, RoutingOperation operation, string operationStyle,
			bool usedPrepared)
		{
			var args = new NavigatorSwitchedArgs(this){
				OldPath = _current.Path,
				NewPath = path,
				OldParameter = _current.Parameter,
				NewParameter = parameter,
				OldVisual = _current.Visual,
				NewVisual = v,
				Operation = operation,
				OperationStyle = operationStyle,
				Mode = gotoMode };
			OnSwitched(args);
			
			if (v != null && !usedPrepared)
			{
				//force page into desired current state (TODO: only when necessary -- reuse)
				var ds = operation == RoutingOperation.Pop ? -1 : 
					operation == RoutingOperation.Goto ? 1 : 1;
				Navigation.SetPageProgress(v, ds, ds, false);
				Navigation.UpdateProgress(NavigationMode.Bypass);
			}
			
			_deferred = new DeferSwitch{
				Path = path,
				Parameter = parameter,
				Page = v,
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
				
			if (deferred.Page != null && !_listenTimeout)
			{
				var busy = BusyTask.GetBusyActivity(deferred.Page);
				if ( (busy & DeferPageSwitch) != BusyTaskActivity.None)
				{
					if (_listenBusy == null)
					{
						_listenBusy = deferred.Page;
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
			if (deferred.Page != _current.Visual && _current.Visual != null &&
				deferred.Operation != RoutingOperation.Goto)
			{
				Navigation.SetPageProgress(_current.Visual, 
					deferred.Operation == RoutingOperation.Push ? -1 : 1, 0, false );
			}

			AddToCache(_current, deferred.Page);
			_current.Path = deferred.Path;
			_current.Parameter = deferred.Parameter;
			_current.Visual = deferred.Page;
			
			//in goto drop all other children
			if (deferred.Operation == RoutingOperation.Goto)
				CleanupChildren(deferred.Page);
			
			if (deferred.Page != null && GotoState == NavigatorGotoState.BringToFront)
				BringToFront(deferred.Page); //for new nodes and reused ones, ensure in front by default
	
			Navigation.Goto(deferred.Page, deferred.GotoMode);
			
			CheckInteraction();
			UpdateNavigationState();
		}
		
		class DeferSwitch
		{
			public string Path;
			public string Parameter;
			public Visual Page;
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
		
		protected override void CreateTriggers(Element c, PageData pd)
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

		static PropertyHandle _propIsReusable = Properties.CreateHandle();
		[UXAttachedPropertySetter("Navigator.IsReusable")]
		static public void SetIsReusable(Visual elm, bool value)
		{
			//deprecated 2016-07-13
			Fuse.Diagnostics.Deprecated( "Use `Reuse=\"Any\"` instead", elm );
			SetReuse(elm, value ? ReuseType.Any : ReuseType.Replace);
		}

		[UXAttachedPropertyGetter("NavigationControl.IsReusable")]
		static public bool GetIsReusable(Visual elm)
		{
			return GetReuse(elm) == ReuseType.Any;
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
			if (!GetPageData(elm).FromTemplate)
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
			if (!GetPageData(elm).FromTemplate)
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