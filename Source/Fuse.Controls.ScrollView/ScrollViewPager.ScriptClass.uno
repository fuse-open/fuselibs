using Uno;

using Fuse.Scripting;

namespace Fuse.Controls
{
	public partial class ScrollViewPager
	{
		static ScrollViewPager()
		{
			ScriptClass.Register(typeof(ScrollViewPager),
				new ScriptMethod<ScrollViewPager>("check", check));
		}
		
		static void check(ScrollViewPager s)
		{
			//defer to allow deferred Each handling to create items
			s.Check();
		}
	}
}
