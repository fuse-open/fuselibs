using Uno;
using Uno.UX;
using Fuse;
using Fuse.Layouts;
using Fuse.Elements;

namespace Fuse.Controls
{

	/** Lays out its children in vertical or horizontal groups.

		The `CollectionPanel` will use a vertical orientation by default, but this can be changed
		by setting the `Orientation` attribute to `Horizontal`.

		## Example

			<CollectionPanel GroupCount="3">
				<Each Count="10">
					<Circle Margin="5" Color="Blue" />
				</Each>
			</CollectionPanel>
	*/
	public class CollectionPanel: Panel
	{

		Orientation _orientation = Orientation.Vertical;

		/**	The orientation in which groups are arranged.

			@default Orientation.Vertical

			The `Orientation` property can be used to make a horizontal @CollectionPanel:

				<CollectionPanel Orientation="Horizontal" GroupCount="4">
					<Each Count="10">
						<Circle Margin="5" Width="100" Height="100" Color="Blue" />
					</Each>
				</CollectionPanel>
		*/
		public Orientation Orientation
		{
			get { return _columnLayout.Orientation; }
			set { _columnLayout.Orientation = value; }
		}

		/**	Number of groups to lay out.

			@default 2

				<CollectionPanel Color="Black" GroupCount="10">
					<!-- Lay out lots of yellow circles and red rectangles in groups -->
					<Each Count="70">
						<Circle Margin="5" Width="10" Height="10" Color="Yellow" />
						<Rectangle Margin="5" Width="10" Height="40" Color="Red" />
					</Each>
				</CollectionPanel>
		*/
		public int GroupCount
		{
			get { return _columnLayout.ColumnCount; }
			set { _columnLayout.ColumnCount = value; }
		}

		/**	Set size of a group.

			When set the elements will be arranged in as many groups of size `GroupSize` as will fit on
			the display.

			> Note that `GroupSize` and `GroupCount` are exclusive, and should not be set at the same time.

				<CollectionPanel Color="Black" GroupSize="12">
					<Each Count="150">
						<Circle Margin="1" Width="10" Height="10" Color="Yellow" />
						<Rectangle Margin="1" Width="10" Height="40" Color="Red" />
						<Rectangle Margin="1" CornerRadius="4" Width="10" Height="20"  Color="Teal" />
					</Each>
				</CollectionPanel>
		*/
		public float GroupSize
		{
			get { return _columnLayout.ColumnSize; }
			set { _columnLayout.ColumnSize = value; }
		}

		/**	Spacing between each group.

			@default 0
		*/
		public float GroupSpacing
		{
			get { return _columnLayout.ColumnSpacing; }
			set { _columnLayout.ColumnSpacing = value; }
		}

		/**	Spacing between each item of a group.

			@default 0
		*/
		public float ItemSpacing
		{
			get { return _columnLayout.ItemSpacing; }
			set { _columnLayout.ItemSpacing = value; }
		}

		/**	Controls whether groups fills available space.

			By default `Sizing` is set to `Fixed`, which means each group will be the exact size
			specified in `GroupSize`.

			When `Sizing` is set to `Fill` the groups will stretch out to fill the space remaning
			after placing as many `GroupSize`-sized groups as will fit on the display.

			> Note that `Sizing` only will only affect the layout when the `GroupSize` attribute is defined.

			@default Fixed

				<CollectionPanel Color="#000000" Sizing="Fill" GroupSize="50" >
					<Each Count="10">
						<Rectangle Height="30" Color="White" />
						<Rectangle Height="30" Color="Red" />
					</Each>
				</CollectionPanel>

		*/
		public ColumnLayoutSizing Sizing
		{
			get { return _columnLayout.Sizing; }
			set { _columnLayout.Sizing = value; }
		}

		readonly ColumnLayout _columnLayout;

		public CollectionPanel()
		{
			Layout = _columnLayout = new ColumnLayout();
		}
	}
}
