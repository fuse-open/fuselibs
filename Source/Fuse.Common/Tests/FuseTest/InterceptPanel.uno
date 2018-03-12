using Uno;
using Uno.UX;

using Fuse;
using Fuse.Controls;

namespace FuseTest
{
	/**
		Can intercept and count certain events. This assists in tracking performance expectations that would otherwise not be visible.
	*/
	public class InterceptPanel : LayoutControl
	{
		public int GetContentSizeCount = 0;
		protected override float2 GetContentSize( LayoutParams lp )
		{
			GetContentSizeCount++;
			return base.GetContentSize(lp);
		}
		
		public void Reset()
		{
			GetContentSizeCount = 0;
		}
	}
}
