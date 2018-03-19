using Uno;

namespace Fuse.Navigation
{
	/**
		Use this class to listen for changes on a page in a navigation. This takes cares of the various
		overrides on Page/Navigation and rooting order considerations.
		
		Create this object at rooting time and dispose of it while unrooting.
		
		@hide
		@deprecated This was not meant to be public. It's an internal support mechanism for navigation events. 2017-04-06
	*/
	public class NavigationPageProxy : IPagePropertyListener
	{
		public delegate void StatusChangedHandler(NavigationPageProxy sender);
		StatusChangedHandler _ready;
		StatusChangedHandler _unready;
		Visual _source;
		
		public Visual Page { get; private set; }
		
		INavigation _navigation;
		public INavigation Navigation { get { return _navigation; } }
		
		Visual _pageBind;
		internal Visual PageBind { get { return _pageBind; } }
		
		bool _waitRootingCompleted;

		/** Internal since class was meant to be internal, not public */
		internal NavigationPageProxy() { }
		/** Split from ctor since callers need the address prior to setup completing */
		internal void Init( StatusChangedHandler ready, StatusChangedHandler unready, Visual source )
		{
			_ready = ready;
			_unready = unready;
			RootImpl(source);
		}

		void RootImpl( Visual source)
		{
			_source = source;
			if (_source == null)
			{
				Fuse.Diagnostics.InternalError( "Attempting rooting to null source", this );
				return;
			}
			
			Page = Fuse.Navigation.Navigation.TryFindPage(_source, out _navigation, out _pageBind);
			if (Page == null)
			{
				Fuse.Diagnostics.UserError( "Unable to locate Page", this );
				return;
			}

			//defer setup until watched node is rooted
			//https://github.com/fusetools/fuselibs-private/issues/1879
			if (!Page.IsRootingStarted)
			{
				Page.RootingCompleted += OnPageRootingCompleted;
				_waitRootingCompleted = true;
				_navigation = null;
				_pageBind = null;
				return;
			}

			if (_navigation == null)
			{
				Fuse.Diagnostics.InternalError( "Something went wrong locating a Navigator", this );
				return;
			}
			
			if (_pageBind != null)
				NavigationPageProperty.AddPageWatcher(_pageBind, this);
			if (_ready != null && _navigation != null)
				_ready(this);
		}
		
		/** @returns true if it is ready (the Page and Navigation objects are available) */
		public bool IsReady
		{
			get { return _navigation != null; }
		}
		
		void OnPageRootingCompleted()
		{
			if (!_waitRootingCompleted || Page == null || _source == null)
			{
				Fuse.Diagnostics.InternalError( "Got an undesired ready event", this );
				return;
			}
			
			Page.RootingCompleted -= OnPageRootingCompleted;
			_waitRootingCompleted = false;
			
			RootImpl(_source);
		}
		
		public void Dispose()
		{
			UnrootImpl();
			_ready = null;
			_unready = null;
		}

		void UnrootImpl()
		{
			if (Page != null)
			{
				//ready() only called when Navigation != null
				if (_navigation != null)
					_unready(this);
					
				if (_waitRootingCompleted)
				{
					Page.RootingCompleted -= OnPageRootingCompleted;
					_waitRootingCompleted = false;
				}
			}
				
			if (_pageBind != null)
				NavigationPageProperty.RemovePageWatcher(_pageBind, this);
				
			Page = null;
			_navigation = null;
			_source = null;
		}
		
		void IPagePropertyListener.PageChanged(Visual n)
		{
			var page = Fuse.Navigation.Navigation.TryFindPage(_source);
			if (page != Page)
			{
				var source = _source;
				UnrootImpl();
				RootImpl(source);
			}
		}
		
		//Obsolete stuff
		[Obsolete] //2017-04-06
		public NavigationPageProxy( Action ready, Action unready )
		{
			Fuse.Diagnostics.Deprecated( "NavigationPageProxy is not meant to be used directly, use specific navigation triggers", this );
			var q = new ObsoleteWrapper{ Ready= ready, Unready = unready };
			_ready = q.ReadyImpl;
			_unready = q.UnreadyImpl;
		}
		
		class ObsoleteWrapper
		{
			public Action Ready, Unready;
			public void ReadyImpl(NavigationPageProxy npp) { Ready(); }
			public void UnreadyImpl(NavigationPageProxy npp) { Unready(); }
		}
		
		[Obsolete] //2017-04-06
		public void Rooted( Visual source )
		{
			RootImpl(source);
		}
		
		[Obsolete] //2017-04-06
		public void Unrooted()
		{
			UnrootImpl();
		}
	}
}
		
