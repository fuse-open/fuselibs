using Uno;
using Uno.Collections;

using Fuse.Reactive;

namespace Fuse.Navigation
{
	class RouterPage
	{
		public string Path;
		public string Parameter;
		public object Context;
		[WeakReference]
		public Node Node;
		
		public Visual Visual 
		{ 	
			get { return Node as Visual; } 
			set { Node = value; }
		}
		
		//if there is an Outlet descendent of this page it should use this to track it's pages. This will
		//keep the pages hierarchy/history during navigation.
		ObserverMap<RouterPage> _childRouterPages;
		public ObserverMap<RouterPage> ChildRouterPages
		{
			get 
			{
				if (_childRouterPages == null)
					_childRouterPages = new PagesMap(this);
				return _childRouterPages;
			}
		}
		
		public RouterPage Clone()
		{
			var np = new RouterPage();
			np.Path = Path;
			np.Parameter = Parameter;
			np.Context = Context;
			np._childRouterPages = _childRouterPages;
			//np.Node = Node;
			return np;
		}
		
		public override string ToString() 
		{
			return Path + "?" + Parameter + " " + Visual + " " + 
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
		[WeakReference]
		RouterPage _owner;
		
		public PagesMap( RouterPage owner )
		{
			_owner = owner;
		}
		
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
			if (_owner == null || _owner.Node == null)
				return;
				
			RouterPage.BubbleHistoryChanged(_owner.Node);
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
