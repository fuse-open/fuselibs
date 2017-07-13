using Fuse.Scripting;

namespace Fuse.Navigation
{
	public partial class Router
	{
		static Router()
		{
			ScriptClass.Register(typeof(Router),
				new ScriptMethod<Router>("bookmark", Bookmark, ExecutionThread.MainThread),
				new ScriptMethod<Router>("getRoute", GetRoute, ExecutionThread.MainThread),
				new ScriptMethod<Router>("goBack", GoBack, ExecutionThread.MainThread),
				new ScriptMethod<Router>("goto", Goto, ExecutionThread.MainThread),
				new ScriptMethod<Router>("gotoRelative", GotoRelative, ExecutionThread.MainThread),
				new ScriptMethod<Router>("modify", Modify, ExecutionThread.MainThread),
				new ScriptMethod<Router>("push", Push, ExecutionThread.MainThread),
				new ScriptMethod<Router>("pushRelative", PushRelative, ExecutionThread.MainThread));
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
		static void Goto(Context c, Router r, object[] args)
		{
			if (!r.IsRootingCompleted) return;

			var where = ParseRoute(c, args);
			if (where != null)
			{
				r.Goto(where);
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
		static void GotoRelative(Context c, Router r, object[] args)
		{
			var route = GetRelative(c, r, args);
			if (route != null)
				r.Goto(route);
		}
		
		/**
			Pushes a new relative route onto the current route stack.
			
			@scriptmethod pushRelative( node, [path, parameter]+ )
			
			@see fuse/navigation/router/push
			@see fuse/navigation/router/gotoRelative
		*/
		static void PushRelative(Context c, Router r, object[] args)
		{
			var route = GetRelative(c, r, args);
			if (route != null)
				r.Push(route);
		}
		
		static Route GetRelative(Context c, Router r, object[] args)
		{
			if (args.Length < 1)
			{
				Diagnostics.UserError( "Router.gotoRelative(): requires 1+ parameters", r );
				return null;
			}
			
			var node = c.Wrap(args[0]) as Node;
			//null is actually okay for `where`
			var where = ParseRoute(c, args, 1);
			
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
		static void Push(Context c, Router r, object[] args)
		{
			if (!r.IsRootingCompleted) return;

			var where = ParseRoute(c, args);
			r.Push(where);
		}
		
		/**
			Pops an item off the history returning to the previous page (the one prior to the last @push operaton).
			If there is no previous item, this will go up instead (return to a higher level path segment).
			
			@scriptmethod goBack()
		*/
		static void GoBack(Context c, Router r, object[] args)
		{
			if (!r.IsRootingCompleted) return;

			if (args.Length != 0)
			{
				Fuse.Diagnostics.UserError( "Router.goBack takes no parameters", r );
				return;
			}
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
		static void Modify(Context c, Router r, object[] args)
		{
			if (!r.IsRootingCompleted) return;
			
			if (args.Length != 1)
			{
				Fuse.Diagnostics.UserError( "`Router.modify` takes one argument", r );
				return;
			}
			
			var obj = args[0] as Fuse.Scripting.Object;
			if (obj == null)
			{
				Fuse.Diagnostics.UserError( "`Router.modify` should be passed an object", r );
				return;
			}
			
			var how = ModifyRouteHow.Goto;
			Route route = null;
			Node relative = null;
			NavigationGotoMode mode = NavigationGotoMode.Transition;
			var style = "";
			
			var keys = obj.Keys;
			for (int i=0; i < keys.Length; ++i)
			{
				var p = keys[i];
				var o = obj[p];
				if (p == "how")
				{
					how = Marshal.ToType<ModifyRouteHow>(o);
				}
				else if (p == "path")
				{
					var path = o as Array;
					if (path == null)
					{
						Fuse.Diagnostics.UserError( "`path` should be an array", r );
						return;
					}
					
					route = ParseRoute(c, path);
				}
				else if (p == "relative")
				{
					relative = c.Wrap(o) as Node;
				}
				else if (p == "transition")
				{
					mode = Marshal.ToType<NavigationGotoMode>(o);
				}
				else if (p == "bookmark")
				{
					var bk = Marshal.ToType<string>(o);
					if (!r.Bookmarks.TryGetValue(bk, out route))
					{	
						Fuse.Diagnostics.UserError( "Unknown bookmark: " + bk, r);
						return;
					}
				}
				else if (p == "style")
				{
					style = Marshal.ToType<string>(o);
				}
				else
				{
					Fuse.Diagnostics.UserError( "Unrecognized argument: " + p, r );
					return;
				}
			}
			
			if (relative != null)
				route = r.GetRelativeRoute(relative, route);
			
			r.Modify( how, route, mode, style );
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
		static void Bookmark(Context c, Router r, object[] args)
		{
			if (!r.IsRootingCompleted) return;
			
			if (args.Length != 1)
			{
				Fuse.Diagnostics.UserError( "`Router.bookmark` takes one argument", r );
				return;
			}
			
			var obj = args[0] as Fuse.Scripting.Object;
			if (obj == null)
			{
				Fuse.Diagnostics.UserError( "`Router.bookmark` should be passed an object", r );
				return;
			}
			
			string name = null;
			IRouterOutlet relative = null;
			Route route = null;
			
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
					var node = c.Wrap(o);
					relative = r.FindOutletUp(node as Node);
					if (relative == null)
					{
						Fuse.Diagnostics.UserError( "Could not find an outlet from the `relative` node", r );
						return;
					}
				}
				else if (p == "path")
				{
					var path = o as Array;
					if (path == null)
					{
						Fuse.Diagnostics.UserError( "`path` should be an array", r );
						return;
					}
					
					route = ParseRoute(c, path);
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
		
		static bool ValidateParameter(Context c, object arg, int depth)
		{
			if (depth > 50)
			{
				Fuse.Diagnostics.UserError("Route parameter must be serializeable, it contains reference loops or is too large", null);
				return false;
			}

			if (arg is Scripting.Object)
			{
				var obj = (Scripting.Object)arg;
				if (obj.InstanceOf(c.Observable))
				{
					Fuse.Diagnostics.UserError("Route parameter must be serializeable, cannot contain Observables.", null);		
					return false;
				}

				var keys = obj.Keys;
				for (var i = 0; i < keys.Length; i++)
				{
					var key = keys[i];
					if (!ValidateParameter(c, obj[key], depth+1)) return false;
				}
			}

			if (arg is Scripting.Array)
			{
				var arr = (Scripting.Array)arg;
				for (var i = 0; i < arr.Length; i++)
				{
					if (!ValidateParameter(c, arr[i], depth+1)) return false;
				}
			}

			if (arg is Scripting.Function) 
			{
				Fuse.Diagnostics.UserError("Route parameter must be serializeable, cannot contain functions.", null);
				return false;
			}

			return true;
		}
		
		static Route ParseRoute(Context c, Array path)
		{
			var cvt = new object[path.Length];
			for (int i=0; i < cvt.Length; ++i)
				cvt[i] = path[i];
			return ParseRoute(c, cvt);
		}
		
		static Route ParseRoute(Context c, object[] args, int pos = 0)
		{
			if (args.Length <= pos) return null;
			if (args.Length <= pos+1) return new Route(args[pos] as string, null, null);

			var arg = args[pos+1];

			if (!ValidateParameter(c, arg, 0)) return null;

			var path = args[pos] as string;
			var parameter = Json.Stringify(arg, true);
			return new Route(path, parameter, ParseRoute(c, args, pos+2));
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
		static void GetRoute(Context c, Router r, object[] args)
		{
			if (args.Length != 1) 
			{
				Diagnostics.UserError("Router.getRoute(): must provide exactly 1 argument.", r);
				return;
			}
			var callback = args[0] as Function;
			if (callback == null) 
			{
				Diagnostics.UserError("Router.getRoute(): argument must be a function.", r);
				return;
			}

			var route = r.GetCurrentRoute();
			c.Invoke(new GetRouteCallback(route, callback, c).Run);
		}
		class GetRouteCallback
		{
			readonly Route _route;
			readonly Function _callback;
			readonly Context _context;
			public GetRouteCallback(Route route, Function callback, Context context)
			{
				_route = route;
				_callback = callback;
				_context = context;
			}
			public void Run() {
				_callback.Call(ToArray());
			}
			Array ToArray()
			{
				var route = _route;
				var len = route.Length;
				var arr = _context.NewArray(len*2);
				for (int i = 0; i < len; i++)
				{
					arr[i*2+0] = route.Path;
					arr[i*2+1] = _context.ParseJson(route.Parameter);
					route = route.SubRoute;
				}
				return arr;
			}
		}
	}
}
