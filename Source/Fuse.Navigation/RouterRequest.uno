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
		
		[Flags]
		public enum Flags
		{
			None = 0,
			//the path and parameters are specified as a flat array (JS interface)
			FlatRoute = 1 << 0,
		}
		Flags _flags;
		
		public RouterRequest(Flags flags = Flags.None)
		{
			_flags = flags;
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
				if (_flags.HasFlag(Flags.FlatRoute))
				{
					var path = value as IArray;
					if (path == null)
					{
						Fuse.Diagnostics.UserError( "`path` should be an array", this );
						return false;
					}
					
					//TODO: conver to bool form like ParseNVPRoute
					Route = ParseFlatRoute(path);
				}
				else
				{
					if (!ParseNVPRoute(value, out Route))
						return false;
				}
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

		static public Route ParseFlatRoute(IArray path)
		{
			//TODO: It would make more sense to wrap object[] as an IArray, and rewrite the object[] function
			var cvt = new object[path.Length];
			for (int i=0; i < cvt.Length; ++i)
				cvt[i] = path[i];
			return ParseFlatRoute(cvt);
		}
		
		static public Route ParseFlatRoute(object[] args, int pos = 0)
		{
			if (args.Length <= pos) return null;
			if (args.Length <= pos+1) return new Route(args[pos] as string, null, null);

			var arg = args[pos+1];

			if (!ValidateParameter(arg, 0)) return null;

			var path = args[pos] as string;
			var parameter = Json.Stringify(arg, true);
			return new Route(path, parameter, ParseFlatRoute(args, pos+2));
		}
		
		static public bool ParseNVPRoute(object value, out Route route)
		{
			route = null;
			
			if (value is string)
			{
				route = new Route((string)value);
				return true;
			}

			if (value is IArray)
			{
				var iarr = value as IArray;
				for (int i= ((iarr.Length-1)/2)*2; i>=0; i -= 2)
				{
					string path;
					if (!Marshal.TryToType<string>(iarr[i], out path))
					{
						Fuse.Diagnostics.UserError( "invalid path component: " + iarr[i], value);
						return false;
					}
					string param = null;
					if (i+1 < iarr.Length)
					{
						object va = iarr[i+1];
						//TODO: awaiting changes that would make this unnecessary
						if (va is IArray)
							va = NameValuePair.ObjectFromArray( (IArray)va );
						param = Json.Stringify( va, true);
					}
					
					route =  new Route(path, param, route);
				}
				
				return true;
			}
			
			Fuse.Diagnostics.UserError("incompatible path", value);
			return false;
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
