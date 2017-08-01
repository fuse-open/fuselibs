using Uno;

using Fuse.Scripting;

namespace Fuse.Controls
{
	public partial class ScrollViewPager
	{
		static ScrollViewPager()
		{
			ScriptClass.Register(typeof(ScrollViewPager),
				new ScriptMethod<ScrollViewPager>("check", check, ExecutionThread.MainThread));
		}
		
		static void check(Context c, ScrollViewPager s, object[] args)
		{
			if (args.Length != 0)
			{
				Fuse.Diagnostics.UserError( "`check` does not take any arguments" , s );
				return;
			}

			//defer to allow deferred Each handling to create items
			UpdateManager.AddDeferredAction(s.CheckPosition, UpdateStage.Layout, LayoutPriority.Post);
		}
	}
}
