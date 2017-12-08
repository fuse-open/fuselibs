using Fuse.Scripting;

namespace Fuse.Navigation
{
	public partial class Router
	{
		static Router()
		{
			ScriptClass.Register(typeof(Router),
				new ScriptMethod<Router>("bookmark", Bookmark),
				new ScriptMethod<Router>("getRoute", GetRoute),
				new ScriptMethod<Router>("goBack", GoBack),
				new ScriptMethod<Router>("goto", Goto),
				new ScriptMethod<Router>("gotoRelative", GotoRelative),
				new ScriptMethod<Router>("modify", Modify),
				new ScriptMethod<Router>("push", Push),
				new ScriptMethod<Router>("pushRelative", PushRelative));
		}

		/**
			Goto a new route. This clears the history.
			
			@scriptmethod  goto( [path, parameter]+ )
			
			The parameters form a repeating set of pairs. The `path` is the name of the page or template
			to use. `parameter` is the dynamic property to assign to the path; it may be `null` if not relevant
			at this level.
			
				router.goto( "home", null, "contact", null, "view", { id: "john" } )
				
			This specifies a three-level path. The first two levels, `home` and `contact` do not have any property.
			The third level `view` specifies the `id` of the user that will be viewed.
		*/
		static void Goto( Router r, object[] args)
		{
			if (!r.IsRootingCompleted) return;

			var where = RouterRequest.ParseFlatRoute(args);
			if (where != null)
			{
				r.Modify( ModifyRouteHow.Goto, where, NavigationGotoMode.Transition, "" );
			}
			else
			{
				Diagnostics.UserError("Router.goto(): invalid route provided", r);
			}
		}
		
		/**
			Goto a new relative route.
			
			@scriptmethod gotoRelative( node, [path, parameter]+ )
			
			This specifies a path relative to the `node` outlet: 
			the @Navigator or @PageControl at, or up from, `node`.
			The path fragment starting at that outlet will be replaced with the new path.
			A `goto` is done on this resulting path.
			
				<Router ux:Name="router"/>
				<Navigator>
					<Navigator ux:Template="one" ux:Name="inner">
						<Panel ux:Template="a"/>
						<Panel ux:Template="b"/>
					
			If the current route is `one/a` a call to `gotoRelative( inner, "b" )` will go to the route `one/b`.
			The relative path replaces the path starting at `inner`.
			
			@see fuse/navigation/router/goto
		*/
		static void GotoRelative(Router r, object[] args)
		{
			var route = GetRelative(r, args);
			if (route != null)
				r.Modify( ModifyRouteHow.Goto, route, NavigationGotoMode.Transition, "" );
		}
		
		/**
			Pushes a new relative route onto the current route stack.
			
			@scriptmethod pushRelative( node, [path, parameter]+ )
			
			@see fuse/navigation/router/push
			@see fuse/navigation/router/gotoRelative
		*/
		static void PushRelative(Router r, object[] args)
		{
			var route = GetRelative(r, args);
			if (route != null)
				r.Modify( ModifyRouteHow.Push, route, NavigationGotoMode.Transition, "" );
		}
		
		static RouterPageRoute GetRelative(Router r, object[] args)
		{
			if (args.Length < 1)
			{
				Diagnostics.UserError( "Router.gotoRelative(): requires 1+ parameters", r );
				return null;
			}
			
			var node = args[0] as Node;
			//null is actually okay for `where`
			var where = RouterRequest.ParseFlatRoute(args, 1);
			
			return r.GetRelativeRoute(node, where);
		}

		/**
			Pushes a new route on the current route stack.
			
			@scriptmethod push( [path, parameter]+ )
			
			The parameters form a repeating set of pairs. The `path` is the name of the page or template
			to use. `parameter` is the dynamic property to assign to the path; it may be `null` if not relevant
			at this level.
			
				router.push( "home", null, "contact", null, "view", { id: "john" } )
				
			This specifies a three-level path. The first two levels, `home` and `contact` do not have any property.
			The third level `view` specifies the `id` of the user that will be viewed.
		*/
		static void Push(Router r, object[] args)
		{
			if (!r.IsRootingCompleted) return;

			var where = RouterRequest.ParseFlatRoute(args);
			r.Modify( ModifyRouteHow.Push, where, NavigationGotoMode.Transition, "" );
		}
		
		/**
			Pops an item off the history returning to the previous page (the one prior to the last @push operaton).
			If there is no previous item, this will go up instead (return to a higher level path segment).
			
			@scriptmethod goBack()
		*/
		static void GoBack(Router r)
		{
			if (!r.IsRootingCompleted) return;

			r.GoBack();
		}
		
		/**
			Performs a Push, Goto, or Replace operation on the router with extended options.

			> Note: there is also a UX interface @ModifyRoute, @PushRoute, @GotoRoute
			
			@scriptmethod modify( navigationSpec )
			
			The navigationSpec is a JavaScript object that specifies all the properties for the router operation, 
			for example:
			
				router.modify({
					how: "Goto",
					path: [ "one", {}, "two", {} ],
					transition: "Bypass",
				})
				
			This gotos to the "one/two" page without a transition.
			
			The options are:
			
				- `how`: One of:
					- `Goto`: Clears the current route stack, like `goto()`
					- `Push`: Pushes a new path onto the route stack, like `push()`
					- `Replace`: Replaces the current item on the route stack wtih a new path
				- `path`: An array specifying the path and parameter parts in pairs.
				- `transition`: An optional argument:
					- `Transition`: A normal animated transition. This is the default.
					- `Bypass`: A bypass transtiion that skips animation.
				- `relative`: An optional node that indicates the path is relative to this router outlet. The path is specified like in `gotoRelative`
				- `style`: The style of the operation, which can be used as a matching criteria in transitions.
		*/
		static void Modify(Router r, object[] args)
		{
			if (!r.IsRootingCompleted) return;
			
			if (args.Length != 1)
			{
				Fuse.Diagnostics.UserError( "`Router.modify` takes one argument", r );
				return;
			}
			
			var obj = args[0] as IObject;
			if (obj == null)
			{
				Fuse.Diagnostics.UserError( "`Router.modify` should be passed an object", r );
				return;
			}
			
			var request = new RouterRequest(RouterRequest.Flags.FlatRoute);
			if (!request.AddArguments(obj))
				return;

			request.MakeRequest(r);
		}

		/**
			Registers a named bookmark for the router. `bookmark` is a key/value pair, formatted as an object containing the following:

			 * `name`(string) : Name of the bookmark
			 * `path`(array)  : Path to be navigated to. This uses the same notation as `navigate()`.

			This example registers a bookmark, `"optionsPage"`, with the path `"options"`:

				router.bookmark({
					name: "optionsPage",
					path: [ "options", { } ]
				});
			
			@scriptmethod bookmark( bookmark )
			
			
		*/
		static void Bookmark(Router r, object[] args)
		{
			if (!r.IsRootingCompleted) return;
			
			if (args.Length != 1)
			{
				Fuse.Diagnostics.UserError( "`Router.bookmark` takes one argument", r );
				return;
			}
			
			var obj = args[0] as IObject;
			if (obj == null)
			{
				Fuse.Diagnostics.UserError( "`Router.bookmark` should be passed an object", r );
				return;
			}
			
			//TODO: Switch to using RouterRequest
			string name = null;
			IRouterOutlet relative = null;
			RouterPageRoute route = null;
			
			var keys = obj.Keys;
			for (int i=0; i < keys.Length; ++i)
			{
				var p = keys[i];
				var o = obj[p];
				
				if (p =="name")
				{
					name = Marshal.ToType<string>(o);
				}
				else if (p =="relative")
				{
					var node = o as Node;
					relative = r.FindOutletUp(node);
					if (relative == null)
					{
						Fuse.Diagnostics.UserError( "Could not find an outlet from the `relative` node", r );
						return;
					}
				}
				else if (p == "path")
				{
					var path = o as IArray;
					if (path == null)
					{
						Fuse.Diagnostics.UserError( "`path` should be an array", r );
						return;
					}
					
					route = RouterRequest.ParseFlatRoute(path);
				}
				else
				{
					Fuse.Diagnostics.UserError( "Unrecognized argument: " + p, r );
					return;
				}
			}
			
			if (relative != null)
			{
				var current = r.GetCurrent(r.Parent, relative);
				route = current == null ? route : current.Append(route);
			}
			
			if (name == null)
			{
				Fuse.Diagnostics.UserError( "A `name` is required for the bookmark", r );
				return;
			}
			
			r.Bookmarks[name] = route;
		}
		
		/** Requests the current route (async) and calls a callback when ready.
			
			@scriptmethod getRoute(callback)

			The callback receives an array on the form `[path, parameter]+`.

			Example:

				router.getRoute(function(route) {
					route[0] // first path segment
					route[1] // first parameter
					route[2] // second path segment
					route[3] // second parameter
					// and so on
				})
		*/
		static object GetRoute(Context c, Router r, object[] args)
		{
			if (args.Length != 1) 
			{
				Diagnostics.UserError("Router.getRoute(): must provide exactly 1 argument.", r);
				return null;
			}
			var callback = args[0] as Function;
			if (callback == null) 
			{
				Diagnostics.UserError("Router.getRoute(): argument must be a function.", r);
				return null;
			}

			UpdateManager.PostAction(new GetRouteCallback(c.ThreadWorker, r, callback).RunUI);
			return null;
		}

		class GetRouteCallback
		{
			readonly IThreadWorker _threadWorker;
			readonly Router _router;
			readonly Function _callback;

			Route _route;

			public GetRouteCallback(IThreadWorker threadWorker, Router router, Function callback)
			{
				_threadWorker = threadWorker;
				_router = router;
				_callback = callback;
			}

			public void RunUI()
			{
				_route = _router.GetCurrentRoute();
				_threadWorker.Invoke(RunJS);
			}

			public void RunJS(Scripting.Context context)
			{
				_callback.Call(context, ToArray(context, _route));
			}

			static Array ToArray(Scripting.Context context, Route route)
			{
				var len = route.Length;
				var arr = context.NewArray(len*2);
				for (int i = 0; i < len; i++)
				{
					arr[i*2+0] = route.Path;
					arr[i*2+1] = context.ParseJson(route.Parameter);
					route = route.SubRoute;
				}
				return arr;
			}
		}
	}
}
