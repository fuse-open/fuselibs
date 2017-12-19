using Uno;
using Uno.Collections;

using Fuse.Reactive;

namespace Fuse.Navigation
{
	delegate void ChildRouterPagesUpdated();
	
	/**
		Represents a logical page in navigation. This creates a state-based navigation with these properties:
		
		- A router is not the master of the state, only a user of it
		- the navigation state can persist without actual controls
		- two-way binding with JavaScript variables
		- pages are not strictly coupled to visuals
		
		The `Path`, `Parameter` and `Context` form a unique page. These cannot be changed. Each unique page requires a new `RouterPage`. This doesn't prevent a control from reusing the same Visual for multiple pages.
		
		Navigation controls form a hierarchy of pages up to the root. If there is a Router this will be the root, otherwise the highest control will be the root. An intervening Router can create a separate hieararchy.
	*/
	class RouterPage
	{
		//The Path can't be read-only due to when/where the normalization/defaulting can happen
		public string Path { get; private set; }
		public readonly string Parameter;
		public readonly object Context;
		
		public RouterPage( string path, string parameter = null, object context = null )
		{
			Path = path;
			Parameter = parameter;
			Context = context;
		}
		
		/**
			Creates a "default" page, the initial state for migration and most high-level navigation controls. Navigation must always have a current page: the stack cannot be completely empty.
		*/
		public static RouterPage CreateDefault()
		{
			return new RouterPage(null, null, null);
		}
		
		/** This may be used to normalize an unspecified path to the default, or undergo other normalization */
		public void DefaultPath( string defaultPath )
		{
			if (Path == null || Path == "")
				Path = defaultPath;
		}
		
		PagesMap _childRouterPages;
		/**
			If there is an Outlet descendent of this page it should use this to track it's pages. This will 	keep the pages hierarchy/history during navigation. This maintains a navigation state independent of controls, and also allows local histories to persist even when not active.
		*/
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
		
		static public IObject GetNavigationRequest( object data )
		{
			var obj = data as IObject;
			if (obj == null || !obj.ContainsKey( "$navigationRequest" ) )
				return null;
			return obj["$navigationRequest"] as IObject;
		}
	}
	
	class PagesMap : ObserverMap<RouterPage>
	{
		static public string GetObjectPath( object data )
		{
			string path = null;
			var obj = data as IObject;
			if (obj != null && obj.ContainsKey("$__fuse_classname")) //set implicitly by Model API
				path = Marshal.ToType<string>(obj["$__fuse_classname"]);
			if (obj != null && obj.ContainsKey("$path"))
				path = Marshal.ToType<string>(obj["$path"]);
				
			return path;
		}
		
		static public bool HasObjectPath( object data )
		{
			var obj = data as IObject;
			if (obj != null && (obj.ContainsKey("$path") || obj.ContainsKey("$__fuse_classname")))
				return true;
			return false;
		}

		public event ChildRouterPagesUpdated Updated;
		
		protected override RouterPage Map(object v)
		{
			return new RouterPage( GetObjectPath(v), null, v );
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
					nxtrp = new RouterPage( r.Path, r.Parameter );
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
