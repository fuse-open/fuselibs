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
				new ScriptMethod<NavigationControl>("gotoPath", gotoPath, ExecutionThread.MainThread),
				new ScriptMethod<NavigationControl>("seekToPath", seekToPath, ExecutionThread.MainThread));
		}
		
		/**
			Go to the desired page. This may reuse the existing page if it is compatible.
			
			This is not a router method. It is a local change to the navigation control. If used in a router it will modify the current path and not alter the history.
			
			@scriptmethod gotoPath( path [, parameter] )
			@param path the name of the path to use
			@param parameter an optional parameter for the page
		*/
		static void gotoPath(Context c, NavigationControl nav, object[] args)
		{
			alterPath(c, nav, args, "gotoPath", NavigationGotoMode.Transition);
		}
		
		/**
			Go to the desired page without using a transition (bypass mode). This may reuse the existing page if it is compatible.
			
			This is not a router method. It is a local change to the navigation control. If used in a router it will modify the current path and not alter the history.
			
			@scriptmethod seekToPath( path [, parameter] )
			@param path the name of the path to use
			@param parameter an optional parameter for the page
		*/
		static void seekToPath(Context c, NavigationControl nav, object[] args)
		{
			alterPath(c, nav, args, "seekToPath", NavigationGotoMode.Bypass);
		}
		
		static void alterPath(Context c, NavigationControl nav, object[] args, string opName,
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
			var rPage = new RouterPage{ Path = path, Parameter = param };
			outlet.Goto(rPage, gotoMode, RoutingOperation.Goto, "");
		}
	}
}