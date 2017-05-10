using Uno;
using Uno.UX;

using Fuse.Scripting;

namespace Fuse.Controls
{
	public partial class EdgeNavigator
	{
		static EdgeNavigator()
		{
			ScriptClass.Register(typeof(EdgeNavigator),
				new ScriptMethod<EdgeNavigator>("dismiss", dismiss, ExecutionThread.MainThread),
				new ScriptMethod<EdgeNavigator>("open", open, ExecutionThread.MainThread));
		}

		/**
			Closes any open edge panels.
			
			@scriptmethod dismiss()
		*/
		static void dismiss(Context c, EdgeNavigator e, object[] args)
		{
			if (args.Length != 0)
			{
				Fuse.Diagnostics.UserError( "EdgeNavigator.dismiss takes no arguments", e );
				return;
			}

			e.Dismiss();
		}
		
		/**
			Opens an edge panel.
			
			@scriptmethod open(edge)
			@param edge The enum name of the edge to open @Fuse.Navigation.NavigationEdge
		*/
		static void open(Context c, EdgeNavigator e, object[] args)
		{
			if (args.Length != 1)
			{
				Fuse.Diagnostics.UserError( "EdgeNaviagator.open requires 1 parameter (edge)", e );
				return;
			}
			
			var edge = Marshal.ToType<Fuse.Navigation.NavigationEdge>(args[0]);
			e.GotoEdge(edge);
		}
		
	}
}
