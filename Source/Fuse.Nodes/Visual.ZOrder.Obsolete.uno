using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse
{
	public partial class Visual
	{
        /** Whether this visual has any visual child nodes. */
        public bool HasVisualChildren { get { return VisualChildCount > 0; } }

		[Obsolete("Use FirstChild<Visual>() instead")]
		public Visual FirstVisualChild
		{ 
			get
			{
				return FirstChild<Visual>();
			}
		}

		/** Returns the visual child with the given index. 
		
			For performance reasons, avoid using this function. 
		*/
		[Obsolete("Deprecated for performance reasons. Iterate over collection manually instead.")]
		public Visual GetVisualChild(int index)
		{
			var c = _firstChild;
			int i = 0;
			while (c != null)
			{
				var v = c as Visual;
				if (v != null)
				{
					if (i == index) return v;
					i++;
				}
				c = c._nextSibling;
			}
			return null;
		}

		[Obsolete("Use LastChild<Visual>() instead")]
		public Visual LastVisualChild	
		{ 
			get
			{
				return LastChild<Visual>();
			}
		}

		[Obsolete("Use VisualChildCount instead")]
		public int ZOrderChildCount
		{
			get 
			{ 
				return VisualChildCount;
			}
		}

        [Obsolete("Iterate over ZOrder instead")]
		public Visual GetZOrderChild(int index)
		{
			return GetCachedZOrder()[index];
		}
    }
}