using Uno;
using Uno.Collections;

using Fuse.Reactive;

namespace Fuse.Navigation
{
	delegate void ChildRouterPagesUpdated();
	
	class RouterPage
	{
		//These are meant to be readonly, but the initialization is difficult if truly done as such
		public string Path;
		public string Parameter;
		public object Context;
		
		//if there is an Outlet descendent of this page it should use this to track it's pages. This will
		//keep the pages hierarchy/history during navigation.
		PagesMap _childRouterPages;
		public ObserverMap<RouterPage> ChildRouterPages
		{
			get 
			{
				if (_childRouterPages == null)
					_childRouterPages = new PagesMap();
				return _childRouterPages;
			}
		}
		
		public event ChildRouterPagesUpdated ChildRouterPagesUpdated
		{
			add { ((PagesMap)ChildRouterPages).Updated += value; }
			remove { ((PagesMap)ChildRouterPages).Updated -= value; }
		}
		
		public override string ToString() 
		{
			return Path + "?" + Parameter  + " " + 
				(Context == null ? "no-ctx" : ("@" + Context.GetHashCode()));
		}
		
		public string ToPathString()
		{
			var q = Path ?? "";
			if (Parameter != null)
				q += "?" + Parameter;
			if (Context != null)
				q += "<" + Context.GetHashCode() + ">";
			return q;
		}

		internal static void BubbleHistoryChanged( Node at )
		{
			//the only thing that needs this now is the Router, so we don't need to actually bubble
			var router = at.FindBehavior<Router>();
			if (router != null)
				router.OnHistoryChanged();
		}
	}
	
	class PagesMap : ObserverMap<RouterPage>
	{
		public event ChildRouterPagesUpdated Updated;
		
		protected override RouterPage Map(object v)
		{
			return new RouterPage{ Context = v };
		}
		
		protected override object Unmap(RouterPage mv)
		{
			return mv.Context;
		}
	
		protected override void OnUpdated()
		{
			if (Updated != null)
				Updated();
		}
	}
	
	class RouterPageRoute
	{
		public RouterPage RouterPage;
		public RouterPageRoute SubRoute;
		
		public RouterPageRoute( RouterPage routerPage, RouterPageRoute sub )
		{
			RouterPage = routerPage;
			SubRoute = sub;
		}
		
		internal static RouterPageRoute Convert(Route r)
		{
			RouterPageRoute cur = null;
			RouterPageRoute bas = null;
			while (r != null) 
			{
				var nxtrp = r.RouterPage;
				if (nxtrp == null)
					nxtrp = new RouterPage{ Path = r.Path, Parameter = r.Parameter };
				var nxt = new RouterPageRoute( nxtrp, null );
				
				if (cur == null)
				{
					cur = nxt;
					bas =  nxt;
				}
				else
				{
					cur.SubRoute = nxt;
					cur = nxt;
				}
				
				r = r.SubRoute;
			}
			
			return bas;
		}
		
		public Route ToRoute()
		{
			var r = new Route( RouterPage.Path, RouterPage.Parameter, 
				SubRoute != null ? SubRoute.ToRoute() : null );
			r.RouterPage = RouterPage;
			return r;
		}
		
		internal RouterPageRoute Up()
		{
			if (SubRoute == null) return this;
			else if (SubRoute.SubRoute == null) return new RouterPageRoute(RouterPage, null);
			return new RouterPageRoute( RouterPage, SubRoute.Up());
		}
		
		internal string Format()
		{
			var q = RouterPage.ToPathString();
			if (SubRoute != null)
				q += "/" + SubRoute.Format();
			return q;
		}
		
		internal RouterPageRoute SubDepth(int count)
		{
			if (count <0)
			{
				Fuse.Diagnostics.InternalError( "count can't be < 0", this );
				return null;
			}
			
			if (count == 0)
				return this;
				
			if (SubRoute == null)
				return null;
				
			return SubRoute.SubDepth(count-1);
		}
		
		public RouterPageRoute Append( RouterPageRoute subRoute )
		{
			var sub = SubRoute == null ? subRoute : SubRoute.Append(subRoute);
			return new RouterPageRoute(RouterPage, sub);
		}
		
	}
}
