using Uno;

using Fuse.Navigation;

namespace Fuse.Controls
{
	/**
		Provides common behaviour in navigation controls.
	*/
	static class CommonNavigation
	{
		public static Visual FindPath(Visual parent, string path)
		{
			Visual useVisual = null;
			for (var n = parent.FirstChild<Visual>(); n != null; n = n.NextSibling<Visual>())
			{
				if ((string)n.Name == path)
				{
					useVisual = n;
					break;
				}
			}
			
			if (!Fuse.Navigation.Navigation.IsPage(useVisual))
			{
				Diagnostics.InternalError("Can not navigate to '" + path + "', not found!", parent);
				return null;
			}
			
			return useVisual;
		}
		
		public static RoutingResult CompareCurrent(Visual parent, Visual current, 
			RouterPage routerPage, out Visual pageVisual)
		{
			pageVisual = null;
			var useVisual = CommonNavigation.FindPath(parent, routerPage.Path);
			if (useVisual == null)
				return RoutingResult.Invalid;
				
			if (current != useVisual)
				return RoutingResult.Change;
				
			pageVisual = useVisual;
			var pageData = PageData.GetOrCreate(pageVisual);
			if (useVisual.Parameter == routerPage.Parameter &&
				routerPage.Context == pageData.Context)
				return RoutingResult.NoChange;
				
			//TODO: Navigator only returns MinorChange here, never Change
			return CompatibleParameter(useVisual.Parameter, routerPage.Parameter) ?
				RoutingResult.MinorChange : RoutingResult.Change;
		}
		
		public static bool IsEmptyParameter(string a)
		{
			//the last tests are for a JS empty string, empty object, and null. The value is expected to be a JSON
			//serialized string.
			return a == null || a == "" || a == "\"\"" || a == "{}" || a == "null";
		}
		
		public static bool CompatibleParameter( string a, string b )
		{
			if (a == b)
				return true;
				
			return IsEmptyParameter(a) && IsEmptyParameter(b);
		}

		public static RoutingResult Goto(NavigationControl nav, RouterPage routerPage, NavigationGotoMode gotoMode, 
			RoutingOperation operation, string operationStyle, out Visual pageVisual)
		{
			pageVisual = null;
			
			var useVisual = CommonNavigation.FindPath(nav, routerPage.Path);
			if (useVisual == null)
				return RoutingResult.Invalid;

			pageVisual = useVisual;
			var pageData = PageData.GetOrCreate(useVisual);
			bool same = useVisual.Parameter == routerPage.Parameter &&
				pageData.Context == routerPage.Context;
			pageData.AttachRouterPage(routerPage);
			if (useVisual == nav.Active) 
				return same ? RoutingResult.NoChange : RoutingResult.MinorChange;
			
			nav.Navigation.Goto(useVisual, gotoMode);
			return RoutingResult.Change;
		}
		
	}
}
