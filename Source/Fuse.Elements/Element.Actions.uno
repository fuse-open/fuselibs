using Fuse.Triggers.Actions;

namespace Fuse.Elements
{
	/** Elements are visuals that cover a rectangular 2D region.

		@topic Elements

		@include Docs/Element.md

		# Available Element classes

		[subclass Fuse.Elements.Element]
	*/
	public partial class Element: IShow, IHide, ICollapse
	{
		void IShow.Show() { Visibility = Visibility.Visible; }
		void ICollapse.Collapse() { Visibility = Visibility.Collapsed; }
		void IHide.Hide() { Visibility = Visibility.Hidden; }
	}

}
