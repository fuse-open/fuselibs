using Uno;
using Uno.UX;
using Uno.Collections;
using Fuse;

namespace Fuse.Elements
{
	public partial class Element
	{
		static Element()
		{
			if defined(Designer)
			{
				Fuse.Designer.UnoHostInterface.VisualAppearedFactory = Fuse.Elements.Element.VisualAppearedFactory;
				Fuse.Designer.UnoHostInterface.VisualDisappearedFactory = Fuse.Elements.Element.VisualDisappearedFactory;
				Fuse.Designer.UnoHostInterface.VisualTransformChangedFactory = Fuse.Elements.Element.VisualTransformChangedFactory;
				Fuse.Designer.UnoHostInterface.VisualBoundsChangedFactory = Fuse.Elements.Element.VisualBoundsChangedFactory;
			}
		}
	}
}
