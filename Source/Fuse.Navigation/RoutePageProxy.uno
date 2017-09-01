using Uno;
using Uno.Collections;
using Uno.UX;

namespace Fuse.Navigation
{
	/**
		The level of navigation that determines whether a page is active or inactive.
	*/
	public enum RoutePagePath
	{
		/** Only the most recent ancestor navigation considered. A page can be active in the local navigation, even if that navigation resides in a page which is not active itself. */
		Local,
		/** The full path is considered  -- from here through all navigation instances to the root. A page is only active if all it's ancestor pages are active. */
		Full,
	}
	
	/**
		When an Activated/Deactivated trigger fires on navigation change.
	*/
	public enum RoutePageTriggerWhen
	{
		/** Will trigger as soon as a change is known, prior to animation completion */
		Immediate,
		/** Will trigger once the navigation is stable, after the transition is complete */
		Stable,
	}
	
	/**
		Extends the `NavigationPageProxy` to watch all outlet pages back to the route.
	*/
	class RoutePageProxy
	{
		public delegate void ProgressUpdated( double progress );
		public delegate void ActiveChanged( bool isActive, bool isRoot );
		
		RoutePagePath _path = RoutePagePath.Full;
		public RoutePagePath Path 
		{ 
			get { return _path; }
			set { _path = value; }
		}
		
		RoutePageTriggerWhen _triggerWhen = RoutePageTriggerWhen.Stable;
		public RoutePageTriggerWhen TriggerWhen
		{
			get { return _triggerWhen; }
			set { _triggerWhen = value; }
		}
		
		public Visual Page { get; private set; }
		
		Visual _source;
		//if null then not watching for progress
		ProgressUpdated _progressUpdated;
		
		//if null then not watching for active changes
		ActiveChanged _activeChanged;
		bool _isActive;
		
		struct Level
		{
			public NavigationPageProxy PageProxy;
			public bool Listening;
		}
		List<Level> _levels = new List<Level>();
		
		/** `Init()` must be called to finish initialization. */
		public RoutePageProxy( Visual source, ProgressUpdated progressUpdated )
		{
			_progressUpdated = progressUpdated;
			_source = source;
		}
		
		/** `Init()` must be called to finish initialization. */
		public RoutePageProxy( Visual source, ActiveChanged activeChanged )
		{
			_activeChanged = activeChanged;
			_source = source;
		}

		/** Call after configuration is completed. This could start the actual registration and messaging */
		public void Init()
		{
			var level = new Level{
				PageProxy = new NavigationPageProxy(),
			};
			_levels.Add(level);
			level.PageProxy.Init(NavReady, NavUnready, _source);
		}
		
		public void Dispose()
		{
			for (int i=0; i < _levels.Count; ++i)
				Dispose(_levels[i]);
			_levels.Clear();
			_source = null;
			_progressUpdated = null;
			_activeChangedPending = false;
		}
		
		void Dispose(Level level)
		{	
			Unlisten(level);
			if (level.PageProxy != null)
			{
				level.PageProxy.Dispose();
				level.PageProxy = null;
			}
		}
		
		int GetLevel(object sender)
		{
			for (int i=0; i < _levels.Count; ++i)
			{
				if (sender == _levels[i].PageProxy)
					return i;
			}
			Fuse.Diagnostics.InternalError( "Unexpected sender", this );
			return -1;
		}
		
		void NavReady(object sender)
		{
			var levelNdx = GetLevel(sender);
			if (levelNdx == -1)
				return;
			var level = _levels[levelNdx];
			Listen(level);
			DiscardLevels(levelNdx+1);
			
			if (Path == RoutePagePath.Full)
			{
				if (ExtendListen(level))
					return;
			}
				
			InitialUpdate();
		}
		
		bool ExtendListen(Level level)
		{
			var nav = level.PageProxy.Page.Parent;
			//only if it's a router outlet
			var outlet = nav as IRouterOutlet;
			if (outlet == null || outlet.Type == OutletType.None)
				return false;
			
			//only if it actually has a parent
			INavigation ignoreNav;
			Visual ignorePage;
			var q = Fuse.Navigation.Navigation.TryFindPage(nav, out ignoreNav, out ignorePage);
			if (q == null)
				return false;
			
			var nextLevel = new Level{
				PageProxy = new NavigationPageProxy()
			};
			_levels.Add(nextLevel);
			nextLevel.PageProxy.Init(NavReady, NavUnready, nav);
			return true;
		}
		
		void Listen(Level level)
		{
			if (!level.Listening)
			{
				if (_progressUpdated != null)
					level.PageProxy.Navigation.PageProgressChanged += OnNavigationProgressChanged;
				if (_activeChanged != null)
				{
					level.PageProxy.Navigation.ActivePageChanged += OnActivePageChanged;
					level.PageProxy.Navigation.StateChanged += OnStateChanged;
				}
				level.Listening = true;
			}
		}
		
		void Unlisten(Level level)
		{
			if (level.Listening)
			{
				if (_progressUpdated != null)
					level.PageProxy.Navigation.PageProgressChanged -= OnNavigationProgressChanged;
				if (_activeChanged != null)
				{
					level.PageProxy.Navigation.ActivePageChanged -= OnActivePageChanged;
					level.PageProxy.Navigation.StateChanged -= OnStateChanged;
				}
				level.Listening = false;
			}
		}
		
		void DiscardLevels(int start)
		{
			for (int i=_levels.Count-1; i >= start; --i)
			{
				Dispose(_levels[i]);
				_levels.RemoveAt(i);
			}
		}
		
		void NavUnready(object sender)
		{
			var level = GetLevel(sender);
			if (level == -1)
				return;
				
			Unlisten(_levels[level]);
			DiscardLevels(level+1);
		}
		
		double GetProgress()
		{
			float p = 1; //defensive value for odd state
			for (int i=0; i < _levels.Count; ++i)
			{
				var level = _levels[i];
				//NavReady may not have been called on the level yet (this happens during some rooting setups)
				if (!level.PageProxy.IsReady)
					return 1;
				
				var pp = level.PageProxy.Navigation.GetPageState(level.PageProxy.Page);
				var lp = pp.Progress;
				if (i == 0 || Math.Abs(lp) > Math.Abs(p) )
					p = lp;
			}
			return p;
		}
		
		void InitialUpdate()
		{
			if (_progressUpdated != null)
				_progressUpdated(GetProgress());

			if (_activeChanged != null)
			{
				bool ignoreStable;
				GetState( out _isActive, out ignoreStable );
				_activeChanged( _isActive, true );
			}	
		}
		
		void OnNavigationProgressChanged(object sender, NavigationArgs state)
		{
			if (_progressUpdated != null)
				_progressUpdated(GetProgress());
		}
		
		void GetState( out bool isActive, out bool isStable)
		{
			isActive = false;
			isStable = true;
			if (_levels.Count == 0) //defensive
				return;
				
			isActive = true;
			for (int i=0; i < _levels.Count; ++i)
			{
				bool la = _levels[i].PageProxy.Navigation.ActivePage == _levels[i].PageProxy.Page;
				isActive = isActive && la;
				
				bool s = _levels[i].PageProxy.Navigation.State == NavigationState.Stable;
				isStable = isStable && s;
			}
		}
		
		bool _activeChangedPending;
		void OnActivePageChanged(object s, Visual active)
		{
			ScheduleActiveChanged();
		}
		
		void ScheduleActiveChanged()
		{
			//changes in the full path need to be seen as one, thus a deferred action is required to not
			//react to a partial change
			if (_activeChangedPending)
				return;
			_activeChangedPending = true;
			UpdateManager.AddDeferredAction(UpdateActive);
		}
		
		void OnStateChanged(object s, ValueChangedArgs<NavigationState> state)
		{
			ScheduleActiveChanged();
		}
		
		void UpdateActive()
		{
			if (!_activeChangedPending)
				return;
			_activeChangedPending = false;
			
			bool newActive, stable;
			GetState( out newActive, out stable );
			if (newActive == _isActive || (!stable && TriggerWhen == RoutePageTriggerWhen.Stable) )
				return;
			_isActive = newActive;
			_activeChanged(_isActive, false);
		}
	}
}
