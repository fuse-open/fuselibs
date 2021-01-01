using Uno;
using Uno.Collections;

using Fuse;
using Fuse.Controls;
using Fuse.Elements;
using Fuse.Layouts;

namespace Fuse.Controls
{
	/** Lays out children one after the other in a given orientation and wraps around whenever it reaches the end.

		You can specify which direction the elements are laid out in by assigning the `FlowDirection` property.
		FlowDirection can either be LeftToRight or RightToLeft.

		The following `WrapPanel` lays out its children horizontally from right to left.

			<WrapPanel FlowDirection="RightToLeft">
			    <Each Count="10">
			        <Rectangle Margin="5" Width="100" Height="100" Color="Blue"/>
			    </Each>
			</WrapPanel>

		The `Orientation` property can be used to make a vertical WrapPanel like so:

			<WrapPanel Orientation="Vertical">
			    <Each Count="10">
			        <Rectangle Margin="5" Width="100" Height="100" Color="Blue"/>
			    </Each>
			</WrapPanel>

		You can also specify the maximum area the `WrapPanel` will allocate an element by using the `ItemWidth` and `ItemHeight` properties.
	*/
	public class WrapPanel : Panel
	{
		/** Specifies the maximum width allocated to an element. */
		public float ItemWidth
		{
			get { return _wrapLayout.ItemWidth; }
			set { _wrapLayout.ItemWidth = value; }
		}

		/** Specifies the maximum height allocated to an element. */
		public float ItemHeight
		{
			get { return _wrapLayout.ItemHeight; }
			set { _wrapLayout.ItemHeight = value; }
		}

		/** The orientation in which children are laid out. Defaults to `Horizontal`.

			The `Orientation` property can be used to make a vertical WrapPanel like so:

				<WrapPanel Orientation="Vertical">
				    <Each Count="10">
				        <Rectangle Margin="5" Width="100" Height="100" Color="Blue"/>
				    </Each>
				</WrapPanel>

			See also the `FlowDirection` property.
		*/
		public Orientation Orientation
		{
			get { return _wrapLayout.Orientation; }
			set { _wrapLayout.Orientation = value; }
		}

		/** The flow direction in which elements are laid out.

			The following `WrapPanel` lays out its children horizontally from right to left.

				<WrapPanel FlowDirection="RightToLeft">
					<Each Count="10">
						<Rectangle Margin="5" Width="100" Height="100" Color="Blue"/>
					</Each>
				</WrapPanel>

		*/
		public FlowDirection FlowDirection
		{
			get { return _wrapLayout.FlowDirection; }
			set { _wrapLayout.FlowDirection = value; }
		}

		/** The alignment of the content within the wrap panel rows. */
		public Alignment RowAlignment
		{
			get { return _wrapLayout.RowAlignment; }
			set { _wrapLayout.RowAlignment = value; }
		}

		readonly WrapLayout _wrapLayout;

		public WrapPanel()
		{
			Layout = _wrapLayout = new WrapLayout();
		}

		public string ID
		{
			get { return _wrapLayout.ID; }
			set { _wrapLayout.ID = value; }
		}
	}
}

