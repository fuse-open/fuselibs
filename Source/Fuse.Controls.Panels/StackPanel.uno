using Uno;

using Fuse.Elements;
using Fuse.Layouts;

namespace Fuse.Controls
{
	
	/** Stacks children vertically (default) or horizontally. 

		The default layout is a vertical stack, but one can use the Orientation property to specify that the stack should be laid out horizontally.

			<StackPanel Orientation="Horizontal">
				... elements ...
			</StackPanel>

		You can use the @ItemSpacing property to make some space between elements. It differs from setting Margin on each child, in that it only 
		adjusts the space directly between the elements, not the space around each of them. 

		## Example

		The following example shows three Panels in a StackPanel, spaced using the ItemSpacing property:

			<StackPanel ItemSpacing="20">
				<Panel Height="100" Background="Red"/>
				<Panel Height="100" Background="Green"/>
				<Panel Height="100" Background="Blue"/>
			</StackPanel>
	*/
	public class StackPanel : Panel
	{
		readonly StackLayout _stackLayout;

		public StackPanel()
		{
			Layout = _stackLayout = new StackLayout();
		}

		/** The direction of stacking. Defaults to `Vertical`. */
		public Orientation Orientation
		{
			get { return _stackLayout.Orientation; }
			set { _stackLayout.Orientation = value; }
		}

		/** Adds distance between elements in the stacking direction.

			You can use the ItemSpacing property to make some space between elements. It differs from setting Margin on each child, in that it only 
			adjusts the space directly between the elements, not the space around each of them. 

			## Example

			The following example shows three Panels in a StackPanel, spaced using the ItemSpacing property:

				<StackPanel ItemSpacing="20">
					<Panel Height="100" Background="Red"/>
					<Panel Height="100" Background="Green"/>
					<Panel Height="100" Background="Blue"/>
				</StackPanel>
		*/
		public float ItemSpacing
		{
			get { return _stackLayout.ItemSpacing; }
			set { _stackLayout.ItemSpacing = value; }
		}

		/** The alignment of the content within the stack panel. */
		public Alignment ContentAlignment
		{
			get { return _stackLayout.ContentAlignment; }
			set { _stackLayout.ContentAlignment = value; }
		}

		/** The algorithm to use when stacking items. */
		public StackLayoutMode Mode
		{
			get { return _stackLayout.Mode; }
			set { _stackLayout.Mode = value; }
		}
	}
}
