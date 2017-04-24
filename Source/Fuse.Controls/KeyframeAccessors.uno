using Uno;
using Uno.UX;

using Fuse.Animations;
using Fuse.Elements;

namespace Fuse.Controls
{
	public static class KeyframeAccessors
	{
		[UXAttachedPropertySetter("Visibility")]
		public static void SetVisibility(Keyframe kf, Visibility v)
		{
			kf.ObjectValue = (object)v;
		}
		
		[UXAttachedPropertyGetter("Visibility")]
		public static Visibility SetVisibility(Keyframe kf)
		{
			return (Visibility)kf.ObjectValue;
		}
	}
}
