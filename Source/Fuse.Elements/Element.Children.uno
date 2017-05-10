using Uno.UX;
using Uno.Collections;

namespace Fuse.Elements
{
	public abstract partial class Element
	{
		protected override void OnChildAdded(Node node)
		{
			base.OnChildAdded(node);

			var e = node as Fuse.Effects.Effect;
			if (e != null)
				OnEffectAdded(e);
		}

		protected override void OnChildRemoved(Node node)
		{
			var elm = node as Element;
			if (elm != null)
				RemoveChildElementFromBatching(elm);

			var e = node as Fuse.Effects.Effect;
			if (e != null)
				OnEffectRemoved(e);

			base.OnChildRemoved(node);
		}
	}
}
