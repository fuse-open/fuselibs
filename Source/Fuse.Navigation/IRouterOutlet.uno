using Uno;
using Uno.Collections;

namespace Fuse.Navigation
{
	enum RoutingOperation
	{
		Goto,
		Push,
		Replace,
		Pop,
	}
	
	[Flags]
	enum OutletType
	{
		None = 0,
		/** This IRouterOutlet is an outlet, if not specified it will be skipped over during searching */
		Outlet = 1<<1,
	}
	
	/**
		The result code is used to help Router decide how to combine an entire routing request.
		For example, only the outermost page change should be animated, the inner ones will just
		be at the target page (otherwise you end up with a vertigo inducing layering of animations).
	*/
	enum RoutingResult
	{
		/** There has been no change at all */
		NoChange,
		/** A local non-animated change has occurred, typically meaning the parameter is updated on the current visual */
		MinorChange,
		/** A new visual or major change has occurred */
		Change,
		/** The path/parameter was not valid and thus no change occurred */
		Invalid,
	}

	class RouterPage
	{
		public string Path;
		public string Parameter;
		//[WeakReference] //UNO: this is causing segfaults There is a memory loop without this WeakReference
		public Visual Visual;
		
		//if there is an Outlet descendent of this page it should use this to track it's pages. This will
		//keep the pages hierarchy/history during navigation.
		List<RouterPage> _childRouterPages;
		public List<RouterPage> ChildRouterPages
		{
			get 
			{
				if (_childRouterPages == null)
					_childRouterPages = new List<RouterPage>();
				return _childRouterPages;
			}
		}
		
		public RouterPage Clone()
		{
			var np = new RouterPage();
			np.Path = Path;
			np.Parameter = Parameter;
			np.Visual = Visual;
			return np;
		}
		
		public override string ToString() 
		{
			return Path + "?" + Parameter + " " + Visual;
		}
	}
	
	/**	Represents an object that handle navigation to one @Route path element. */
	interface IRouterOutlet
	{
		/** Navigates the outlet to the given path, with the given parameter. 

			@param page Can be modified by the receiver to normalize the Path/Parameter. The Visual
				parameter will be set as output. The caller passes ownership to the RouterOutlet -- it
				may read data after the call but no longer modify it.
			@param gotoMode Specifies whether the router should transition (animate) to the new state,
				or bypass (go directly) to the new state.
			@param operation specifies what routing operation is being performed to generate this
				request. The operation is only relevant during transition and does not become a persistent part of the route.
			@param operationStyle identifies the style of transition that is being performed. This has no concrete semantic meaning; it is defined by a user and optionally matched inside a trigger. The style is only relevant during transition and does not become a persistent part of the route.
				
			@return what happened as a result of this request. This assists the router in combining this operation into the entire routing request.
		*/
		RoutingResult Goto(RouterPage page, NavigationGotoMode gotoMode, 
			RoutingOperation operation, string operationStyle);

		/*
			If NoChange or MinorChange then page.Visual will be set
		*/
		RoutingResult CompareCurrent(RouterPage page);
			
		void PartialPrepareGoto(	double progress);
		void CancelPrepare();
			
		RouterPage GetCurrent();
		
		OutletType Type { get; }
	}
}