using Uno.UX;

namespace Fuse.Elements
{
    public static class LayoutMasterAttr
    {
		/**
			Determines how the layout of the @(Element.LayoutMaster:master element) is used to control the size of this one.
		*/
        [UXAttachedPropertySetter("LayoutMaster.LayoutMasterMode")]
        public static void SetLayoutMasterMode(Element elm, LayoutMasterMode mode)
        {
            LayoutMasterBoxSizing.GetLayoutMasterData(elm).Mode = mode;
        }

        [UXAttachedPropertyGetter("LayoutMaster.LayoutMasterMode")]
        public static LayoutMasterMode GetLayoutMasterMode(Element elm)
        {
            return LayoutMasterBoxSizing.GetLayoutMasterData(elm).Mode;
        }
    }
}
