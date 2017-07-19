using Uno;

using Fuse.Scripting;

namespace Fuse.Navigation
{
	/**
		Combines the logic for making router navigation requests into one class. This is to ensure
		that the various interfaces `ModifyRoute`, expression `modifyRoute()` and JS `router.modify`
		all behave the same way.
	*/
	class RouterRequest
	{
		public ModifyRouteHow How;
		public Route Route;
		[WeakReference]
		public Node Relative;
		public NavigationGotoMode Transition;
		public string Style;
		public string Bookmark;
		
		public RouterRequest()
		{
			Reset();
		}
		
		public void Reset()
		{
			How = ModifyRouteHow.Goto;
			Route = null;
			Relative = null;
			Transition = NavigationGotoMode.Transition;
			Style = "";
		}
		
		public bool AddArgument(string name, object value)
		{
			if (name == "how")
			{
				How = Marshal.ToType<ModifyRouteHow>(value);
			}
			else if (name == "path")
			{
				var path = value as Fuse.Scripting.Array;
				if (path == null)
				{
					Fuse.Diagnostics.UserError( "`path` should be an array", this );
					return false;
				}
				
				Route = ParseRoute(path);
			}
			else if (name == "relative")
			{
				Relative = ParseNode(value);
			}
			else if (name == "transition")
			{
				Transition = Marshal.ToType<NavigationGotoMode>(value);
			}
			else if (name == "bookmark")
			{
				Bookmark = Marshal.ToType<string>(value);
			}
			else if (name == "style")
			{
				Style = Marshal.ToType<string>(value);
			}
			else
			{
				Fuse.Diagnostics.UserError( "Unrecognized argument: " + name, this );
				return false;
			}
			
			return true;
		}
		
		public bool MakeRequest(Router router)
		{
			var targetRoute = Route;
			
			if (Bookmark != null)
			{
				if (targetRoute != null)
				{
					Fuse.Diagnostics.UserError( "A path and bookmark cannot both be specified", router);
					return false;
				}
				
				if (!router.Bookmarks.TryGetValue(Bookmark, out targetRoute))
				{	
					Fuse.Diagnostics.UserError( "Unknown bookmark: " + Bookmark, router);
					return false;
				}
			}
			
			if (Relative != null)
				targetRoute = router.GetRelativeRoute(Relative, targetRoute);
				
			router.Modify( How, targetRoute, Transition, Style );
			return true;
		}

		static public Route ParseRoute(Fuse.Scripting.Array path)
		{
			var cvt = new object[path.Length];
			for (int i=0; i < cvt.Length; ++i)
				cvt[i] = path[i];
			return ParseRoute(cvt);
		}
		
		static public Route ParseRoute(object[] args, int pos = 0)
		{
			if (args.Length <= pos) return null;
			if (args.Length <= pos+1) return new Route(args[pos] as string, null, null);

			var arg = args[pos+1];

			if (!ValidateParameter(arg, 0)) return null;

			var path = args[pos] as string;
			var parameter = Json.Stringify(arg, true);
			return new Route(path, parameter, ParseRoute(args, pos+2));
		}
		
		static bool ValidateParameter(object arg, int depth = 0)
		{
			if (depth > 50)
			{
				Fuse.Diagnostics.UserError("Route parameter must be serializeable, it contains reference loops or is too large", null);
				return false;
			}

			if (arg is Scripting.Object)
			{
				var obj = (Scripting.Object)arg;
				if (obj is Fuse.Reactive.IObservable)
				{
					Fuse.Diagnostics.UserError("Route parameter must be serializeable, cannot contain Observables.", null);		
					return false;
				}

				var keys = obj.Keys;
				for (var i = 0; i < keys.Length; i++)
				{
					var key = keys[i];
					if (!ValidateParameter(obj[key], depth+1)) return false;
				}
			}

			if (arg is Scripting.Array)
			{
				var arr = (Scripting.Array)arg;
				for (var i = 0; i < arr.Length; i++)
				{
					if (!ValidateParameter(arr[i], depth+1)) return false;
				}
			}

			if (arg is Scripting.Function) 
			{
				Fuse.Diagnostics.UserError("Route parameter must be serializeable, cannot contain functions.", null);
				return false;
			}

			return true;
		}
		
		protected virtual Node ParseNode(object value)
		{
			return value as Node;
		}
		
	}

}
