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
			np.Node = Node;
			return np;
		}
		
		public override string ToString() 
		{
			return Path + "?" + Parameter + " " + Visual + " " + 
				(Context == null ? "no-ctx" : ("@" + Context.GetHashCode()));
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

}
