using Uno;
using Uno.UX;

using Fuse.Navigation;
using Fuse.Scripting;

namespace Fuse.Controls
{
	public abstract partial class NavigationControl
	{
		static NavigationControl()
		{
			ScriptClass.Register(typeof(NavigationControl),
				new ScriptMethod<NavigationControl>("gotoPath", gotoPath),
				new ScriptMethod<NavigationControl>("seekToPath", seekToPath),
				new ScriptMethod<NavigationControl>("modifyPath", modifyPath));
		}
		
		/**
			Go to the desired page. This may reuse the existing page if it is compatible.
			
			This is not a router method. It is a local change to the navigation control. If used in a router it will modify the current path and not alter the history.
			
			@scriptmethod gotoPath( path [, parameter] )
			@param path the name of the path to use
			@param parameter an optional parameter for the page
		*/
		static void gotoPath(NavigationControl nav, object[] args)
		{
			alterPath(nav, args, "gotoPath", NavigationGotoMode.Transition);
		}
		
		/**
			Go to the desired page without using a transition (bypass mode). This may reuse the existing page if it is compatible.
			
			This is not a router method. It is a local change to the navigation control. If used in a router it will modify the current path and not alter the history.
			
			@scriptmethod seekToPath( path [, parameter] )
			@param path the name of the path to use
			@param parameter an optional parameter for the page
		*/
		static void seekToPath(NavigationControl nav, object[] args)
		{
			alterPath(nav, args, "seekToPath", NavigationGotoMode.Bypass);
		}
		
		static void alterPath(NavigationControl nav, object[] args, string opName,
			NavigationGotoMode gotoMode)
		{
			if (args.Length < 1 || args.Length > 2)
			{
				Fuse.Diagnostics.UserError( "NavigationControl." + opName + " requires 1 or 2 arguments", nav);
				return;
			}
			
			var outlet = nav as IRouterOutlet;
			if (outlet == null)
			{
				Fuse.Diagnostics.InternalError( "Must be an IRouterOutlet", nav );
				return;
			}
			
			var path = Marshal.ToType<string>(args[0]);
			string param = null;
			if (args.Length > 1)
				param = Json.Stringify(args[1], true);
			var rPage = new RouterPage( path, param );
			Visual ignore;
			outlet.Goto(rPage, gotoMode, RoutingOperation.Goto, "", out ignore);
		}
		
		/**
			Goto the desired page and modify the local history.
			
			The properties here match the same named properties of `router.modify`
			
			@scriptmethod modifyPath( navigationSpec )
			
			The navigationSpec is a JavaScript object that specifies all the properties for the modification, 
			for example:
			
				nav.modifyPath({
					how: "Goto",
					path: [ "one", {} ],
					transition: "Bypass",
				})
				
			This gotos to the "one" page without a transition.
			
			The options are:
				- `how`: One of:
					- `Goto`: Clears the current route stack, like `goto()`
					- `Push`: Pushes a new path onto the route stack, like `push()`
					- `Replace`: Replaces the current item on the route stack wtih a new path
					- `GoBack`: Returns to the previous page in the local history (or an explictily provided one)
				- `path`: An array specifying the path and parameter parts in pairs, or an object page specification. The result must be a single path component as it affects only the local NavigationControl.
				- `transition`: An optional argument:
					- `Transition`: A normal animated transition. This is the default.
					- `Bypass`: A bypass transtiion that skips animation.
				- `style`: The style of the operation, which can be used as a matching criteria in transitions.
		*/
		static void modifyPath(NavigationControl nav, object[] args)
		{
			if (args.Length != 1)
			{
				Fuse.Diagnostics.UserError( "`modifyPath` takes on argument", nav );
				return;
			}
			
			var obj = args[0] as IObject;
			if (obj == null)
			{
				Fuse.Diagnostics.UserError( "`modifyPath` should be passed an object", nav );
				return;
			}

			//reusing RouterRequest to ensure same meaning and defaults on supported arguments
			var rr = new RouterRequest(RouterRequest.Flags.FlatRoute);
			if (!rr.AddArguments(obj, RouterRequest.Fields.How | RouterRequest.Fields.Transition |	
				RouterRequest.Fields.Style | RouterRequest.Fields.Path))
			{
				Fuse.Diagnostics.UserError( "`modifyPath` unrecognized arguments", nav );
				return;
			}
			
			if (rr.Route != null && rr.Route.SubRoute != null)
			{
				Fuse.Diagnostics.UserError( "`modifyPath` expects one route component", nav );
				return;
			}
			var page = rr.Route != null ? rr.Route.RouterPage : null;
			var childPages = nav.AncestorRouterPage != null ? nav.AncestorRouterPage.ChildRouterPages : null;
			if (rr.How == ModifyRouteHow.GoBack && page == null)
			{
				if (childPages.Count > 1)
					page = childPages[childPages.Count-2];
			}
			if (page == null)
			{
				Fuse.Diagnostics.UserError( "`modifyPath` unable to find route component", nav );
				return;
			}
			
			RoutingOperation op = RoutingOperation.Goto;
			switch (rr.How)
			{
				case ModifyRouteHow.Push:
					if (childPages != null)
						childPages.Add( page );
					op = RoutingOperation.Push;
					break;
					
				case ModifyRouteHow.Goto:
					if (childPages != null)
					{
						childPages.Clear();
						childPages.Add( page );
					}
					op = RoutingOperation.Goto;
					break;
					
				case ModifyRouteHow.Replace:
					if (childPages != null)
					{
						var count = childPages.Count;
						if (count == 0)
							childPages.Add( page );
						else
							childPages[count-1] = page;
					}
					op = RoutingOperation.Replace;
					break;
					
				case ModifyRouteHow.GoBack:
					if (childPages != null)
					{
						if (childPages.Count > 0)
							childPages.RemoveAt( childPages.Count - 1);
						if (childPages.Count > 0)
							childPages[childPages.Count-1] = page;
						else
							childPages.Add( page );
					}
					op = RoutingOperation.Pop;
					break;
					
				default:
					Fuse.Diagnostics.UserError( "Unsupported `How`: " + rr.How, nav );
					return;
			}
			
			var outlet = (IRouterOutlet)nav;
			Visual ignore;
			outlet.Goto( page, rr.Transition, op, rr.Style, out ignore );
		}
	}
}
