using Uno;

namespace Fuse.Navigation
{
	public enum RoutingOperation
	{
		Goto,
		Push,
		Replace,
		Pop,
	}
	
	[Flags]
	public enum OutletType
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
	public enum RoutingResult
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
	
	/**	Represents an object that handle navigation to one @Route path element. */
	public interface IRouterOutlet
	{
		/** Navigates the outlet to the given path, with the given parameter. 

			@param path Identifies the @Visual that this outlet should navigate to. This may be modified to indicate a normalized path.
			@param parameter An object that should become the @Parameter of the @Visual when displayed. It can be `null`. This may be modified to indicate a normalized path.
			@param gotoMode Specifies whether the router should transition (animate) to the new state,
				or bypass (go directly) to the new state.
			@param operation specifies what routing operation is being performed to generate this
				request. The operation is only relevant during transition and does not become a persistent part of the route.
			@param active the Visual targetted by this routing request
			@param operationStyle identifies the style of transition that is being performed. This has no concrete semantic meaning; it is defined by a user and optionally matched inside a trigger. The style is only relevant during transition and does not become a persistent part of the route.
				
			@return what happened as a result of this request. This assists the router in combining this operation into the entire routing request.
		*/
		RoutingResult Goto(ref string path, ref string parameter, NavigationGotoMode gotoMode, 
			RoutingOperation operation, string operationStyle, out Visual active);
			
		void PartialPrepareGoto(	double progress);
		void CancelPrepare();
			
		void GetCurrent(out string path, out string parameter, out Visual active);

		/**
			Get the path and parameter of the given active page. 
			
			@return true if it was a valid page and the path/paraemeter are valid. false otherwise.
		*/
		bool GetPath(Visual active, out string path, out string parameter);
		
		OutletType Type { get; }
	}
}