using Uno;
using Uno.UX;
using Uno.Collections;
using Fuse.Scripting;
using Fuse.Triggers;
using Fuse.Animations;
using Fuse.Elements;

namespace Fuse.Navigation
{
	/*
		This is a collection of static methods related to Navigation but that don't really have anything to
		do with the `Navigation` type itself.
	*/
	public abstract partial class Navigation
	{
		internal static IBaseNavigation GetLocalNavigation(Visual node)
		{
			var n = GetNavigationNavigation(node);
			if (n != null)
				return n;

			var t = node as IBaseNavigation;
			if (t != null)
				return t;
				
			for (int i = 0; i < node.Children.Count; i++)
			{
				var c = node.Children[i] as IBaseNavigation;
				//mean to check only behaviours (as was a distinct list before), so exclude visuals
				if (c != null && !(c is Visual)) return c;
			}
			return null;
		}

		public static INavigation TryFind(Visual node)
		{
			//always take the first navigtaon object, even if it isn't an `INavigation`. This prevents
			//confusing lookup across navigation bounds for different triggers
			return TryFindBaseNavigation(node) as INavigation;
		}
		
		public static IBaseNavigation TryFindBaseNavigation(Node node, out Visual parent)
		{
			parent = null;
			if (!node.IsRootingStarted)
			{
				Fuse.Diagnostics.InternalError( "TryFindBaseNavigation requires rooting to have started", node );
				return null;
			}
			
			while (node != null)
			{
				var v = node as Visual;
				if (v != null)
				{
					var n = GetLocalNavigation(v);
					if (n != null)
					{
						parent = v;
						return n;
					}
				}
				node = node.ContextParent;
			}

			return null;
		}
		
		public static IBaseNavigation TryFindBaseNavigation(Node node)
		{
			Visual v;
			return TryFindBaseNavigation(node, out v);
		}

		/**
			This version of TryFindPage is suitable only for single lookups during event response
			and the value should not be cached since it may change.
		*/
		public static Visual TryFindPage(Visual node)
		{
			INavigation nav;
			Visual bind;
			return TryFindPage(node, out nav, out bind);
		}
		
		/**
			Locates the Page best associated with the provided node.
			
			This is not public since the difficulty in using this API is too high. Look at using the NavigationPageProxy
			object to bind correctly.
			
			@param node where to look for a page. This scans upwards.
			@param nav this associated navigation object
			@param pageBind non-null if this is an explicit page binding, in which case you need
				to listen for binding changes
			@return the page associated with @node, or `null` if none is found. The rooting status
				of this page must be checked, since if it isn't rooted the other parameter are
				not defined.
		*/
		internal static Visual TryFindPage(Node node, out INavigation nav, out Visual pageBind)
		{
			var prev = node as Visual;
			nav = null;
			pageBind = null;
			
			if (!node.IsRootingStarted)
			{
				Fuse.Diagnostics.InternalError( "TryFindPage requires rooting to have started", node );
				return null;
			}
			
			bool first = true;
			while (node != null)
			{
				var v = node as Visual;
				if (v != null)
				{
					//explicit page overrides
					var p = NavigationPageProperty.GetNavigationPage(v);
					if (p != null)
					{
						pageBind = v;
						
						if (p.IsRootingStarted)
						{
							nav = TryFind(p);
							if (nav == null)
							{
								Fuse.Diagnostics.UserWarning( "`Page` set to a value that is not within an navigation", p );
								return null;
							}
						}
						return p;
					}

					// The search Page can never be the navigation for itself
					if (!first)
					{
						var n = GetLocalNavigation(v);
						if (n != null)
						{
							nav = n  as INavigation;
							//closest nav does not represent a proper page nav
							if (nav == null)
								return null;
							return prev;
						}
					}
					
					//the most recent Visual, not just Node, is the page
					prev = v;
				}

				first = false;
				node = node.ContextParent;
			}

			return null;
		}

		static readonly PropertyHandle _contextHandle = Fuse.Properties.CreateHandle();
		[UXAttachedPropertySetter("Navigation.Navigation")]
		public static void SetNavigationNavigation(Visual n, IBaseNavigation ctx)
		{
			n.Properties.Set(_contextHandle, ctx);
		}

		[UXAttachedPropertyGetter("Navigation.Navigation")]
		public static IBaseNavigation GetNavigationNavigation(Visual n)
		{
			object v;
			if (n.Properties.TryGet(_contextHandle, out v))
				return (IBaseNavigation)v;
			return null;
		}

		[UXAttachedPropertyResetter("Navigation.Navigation")]
		public static void ResetNavigationNavigation(Visual n)
		{
			n.Properties.Clear(_contextHandle);
		}

		public static bool IsPage(Node n)
		{
			var v = n as Visual;
			if (v == null) return false;
			return v.LayoutRole == LayoutRole.Standard;
		}
	}
	
	/**
		Use this class to listen for changes on a page in a navigation. This takes cares of the various
		overrides on Page/Navigation and rooting order considerations.
	*/
	public class NavigationPageProxy : IPagePropertyListener
	{
		Action _ready;
		Action _unready;
		Visual _source;
		
		public Visual Page { get; private set; }
		
		INavigation _navigation;
		public INavigation Navigation { get { return _navigation; } }
		
		Visual _pageBind;
		internal Visual PageBind { get { return _pageBind; } }
		
		bool _waitRootingCompleted;
		
		public NavigationPageProxy( Action ready, Action unready )
		{
			_ready = ready;
			_unready = unready;
		}
		
		public void Rooted( Visual source )
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
			//https://github.com/fusetools/fuselibs/issues/1879
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
			_ready();
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
			
			Rooted(_source);
		}
		
		public void Unrooted()
		{
			if (Page != null)
			{
				//ready() only called when Navigation != null
				if (_navigation != null)
					_unready();
					
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
				Unrooted();
				Rooted(source);
			}
		}
	}
	
}
		
