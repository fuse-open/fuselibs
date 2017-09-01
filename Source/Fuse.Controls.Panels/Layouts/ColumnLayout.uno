using Uno;
using Uno.Collections;

using Fuse.Elements;

namespace Fuse.Layouts
{
	public enum ColumnLayoutSizing
	{
		Fixed,
		Fill,
	}

	/**	Lays out elements in vertical or horizontal columns.

		The columns will use a vertical orientation by default, but this can be changed
		by setting the `Orientation` attribute to `Horizontal`.

		## Example

			<Panel>
				<ColumnLayout />
				<Each Count="10">
					<Circle Margin="5" Color="Blue" />
				</Each>
			</Panel>
	*/
	public sealed class ColumnLayout : Layout
	{
		Orientation _orientation = Orientation.Vertical;

		/**	The orientation in which columns are arranged.

			@default Orientation.Vertical

			The `Orientation` property can be used to make a horizontal @ColumnLayout:

				<Panel>
					<ColumnLayout Orientation="Horizontal" ColumnCount="4" />
					<Each Count="10">
						<Circle Margin="5" Width="100" Height="100" Color="Blue" />
					</Each>
				</Panel>
		*/
		public Orientation Orientation
		{
			get { return _orientation; }
			set
			{
				if (_orientation != value)
				{
					_orientation = value;
					InvalidateLayout();
				}
			}
		}

		bool _hasColumnCount;
		int _columnCount = 2;

		/**	Number of columns to lay out.

			@default 2

				<Panel Color="Black" >
					<!-- Lay out lots of yellow circles and red rectangles in columns -->
					<ColumnLayout ColumnCount="10" />
					<Each Count="70">
						<Circle Margin="5" Width="10" Height="10" Color="Yellow" />
						<Rectangle Margin="5" Width="10" Height="40" Color="Red" />
					</Each>
				</Panel>
		*/
		public int ColumnCount
		{
			get { return _columnCount; }
			set
			{
				if (!_hasColumnCount || _columnCount != value)
				{
					_columnCount = value;
					_hasColumnCount = true;
					InvalidateLayout();
				}
			}
		}
		
		bool _hasColumnSize;
		float _columnSize;

		/**	Set size of a column.

			When set the elements will be arranged in as many columns of size `ColumnSize` as will fit on
			the display.

			If `Orientation` is set to `Vertical`, which is the default, size means width of the column.
			Otherwise, when `Orientation` is `Horizontal`, size means height.

			> Note that `ColumnSize` and `ColumnCount` are exclusive, and should not be set at the same time.

				<Panel Color="Black">
					<ColumnLayout ColumnSize="12" />
					<Each Count="150">
						<Circle Margin="1" Width="10" Height="10" Color="Yellow" />
						<Rectangle Margin="1" Width="10" Height="40" Color="Red" />
						<Rectangle Margin="1" CornerRadius="4" Width="10" Height="20"  Color="Teal" />
					</Each>
				</Panel>
		*/
		public float ColumnSize
		{
			get { return _columnSize; }
			set
			{
				if (!_hasColumnSize || _columnSize != value)
				{
					_hasColumnSize = true;
					_columnSize = value;
					InvalidateLayout();
				}
			}
		}

		float _columnSpacing = 0;
		/**	Spacing between each column.

			@default 0
		*/
		public float ColumnSpacing
		{
			get { return _columnSpacing; }
			set
			{
				if (_columnSpacing != value)
				{
					_columnSpacing = value;
					InvalidateLayout();
				}
			}
		}
		
		float _itemSpacing = 0;
		/**	Spacing between each item of a column.

			@default 0
		*/
		public float ItemSpacing
		{
			get { return _itemSpacing; }
			set
			{
				if (_itemSpacing != value)
				{
					_itemSpacing = value;
					InvalidateLayout();
				}
			}
		}


		ColumnLayoutSizing _sizing = ColumnLayoutSizing.Fixed;
		/**	Controls whether columns fills available space.

			By default `Sizing` is set to `Fixed`, which means each column will be the exact size
			specified in `ColumnSize`.

			When `Sizing` is set to `Fill` the columns will stretch out to fill the space remaning
			after placing as many `ColumnSize`-sized columns as will fit on the display.

			> Note that `Sizing` only will only affect the layout when the `ColumnSize` attribute is defined.

			@default Fixed

				<Panel Color="#000000" >
					<ColumnLayout Sizing="Fill" ColumnSize="50" />
					<Each Count="10">
						<Rectangle Height="30" Color="White" />
						<Rectangle Height="30" Color="Red" />
					</Each>
				</Panel>

		*/
		public ColumnLayoutSizing Sizing
		{
			get { return _sizing; }
			set
			{
				if (_sizing != value)
				{
					_sizing = value;
					InvalidateLayout();
				}
			}
		}
		
		int LeastAt( float[] c )
		{
			float sz = c[0];
			int i = 0;
			
			for (int j=1; j < c.Length; j++)
			{
				if (c[j] < sz)
				{
					sz = c[j];
					i = j;
				}
			}
			
			return i;
		}
		
		float Max(float[] c)
		{
			var mx = c[0];
			for (int j=1; j < c.Length; j++)
				mx = Math.Max(mx, c[j]);
			return mx;
		}
		
		internal override float2 GetContentSize(Visual container, LayoutParams lp)
		{
			return Arrange(container, lp);
		}
		
		internal override void ArrangePaddingBox(Visual container, float4 padding, LayoutParams lp)
		{
			Arrange(container, lp, true, padding);
		}
		
		float2 Arrange(Visual container, LayoutParams lp, 
			bool doArrange = false, float4 padding=float4(0) )
		{
			bool vert = Orientation == Orientation.Vertical;
			
			var columnCount = Math.Max(1,ColumnCount);
			var columnSize = ColumnSize;
			var columnSpace = columnSize + ColumnSpacing;
			var useColumnSize = _hasColumnSize;
			
			var avail = lp.GetAvailableSize();
			avail -= padding.XY + padding.ZW;
			
			if (!useColumnSize && ((vert && !lp.HasX) || (!vert && !lp.HasY)))
			{
				//assume all columns contain max/fixed-size elements
				var mx = float2(0);
				for (var v = container.FirstChild<Visual>(); v != null; v = v.NextSibling<Visual>())
				{
					if (!AffectsLayout(v))
						continue;
					var c = v.GetMarginSize(LayoutParams.CreateEmpty());
					mx = Math.Max( mx, c);
				}
				
				//fall-through to normal sizing
				columnSize = vert ? mx.X : mx.Y;
				columnSpace = columnSize + ColumnSpacing;
				useColumnSize = true;
			}
			
			if (useColumnSize)
			{
				if (!_hasColumnCount)
				{
					if (vert)
						columnCount = (int)Math.Floor( (avail.X + ColumnSpacing) / columnSpace);
					else
						columnCount = (int)Math.Floor( (avail.Y + ColumnSpacing) / columnSpace);
					columnCount = Math.Max(1,columnCount);
				}
					
				if (Sizing == ColumnLayoutSizing.Fill)
				{
					columnSpace = ((vert ? avail.X : avail.Y) + ColumnSpacing) / columnCount;
					columnSize = columnSpace - ColumnSpacing;
				}
			}
			else
			{
				columnSpace = ((vert ? avail.X : avail.Y) + ColumnSpacing) / columnCount;
				columnSize = columnSpace - ColumnSpacing;
			}

			var at = new float[columnCount];
			
			for (var v = container.FirstChild<Visual>(); v != null; v = v.NextSibling<Visual>())
			{
				var avs = float2(vert ? columnSize : 0.0f, vert ? 0.0f : columnSize);
				int col = LeastAt(at);
				float2 nsz;

				if (at[col] > 0)
					at[col] += ItemSpacing;

				if (doArrange)
				{
					if (ArrangeMarginBoxSpecial(v, padding, lp))
						continue;
					var pos = vert ?
						float2( padding.X + col*columnSpace, padding.Y + at[col] ) :
						float2( padding.X + at[col], padding.Y + col*columnSpace );
						
					nsz = v.ArrangeMarginBox(pos, LayoutParams.CreateXY(avs,vert, !vert));
				}
				else if (AffectsLayout(v))
				{
					nsz = v.GetMarginSize(LayoutParams.CreateXY(avs,vert,!vert));
				}
				else
				{
					continue;
				}
					
				at[col] += vert ? nsz.Y : nsz.X;
			}

			if (doArrange)
			{
				//store values for reading if not explicit
				if (!_hasColumnSize)
					_columnSize = columnSize;
				if (!_hasColumnCount)
					_columnCount = columnCount;
			}
			
			var size = (columnCount * columnSpace) - ColumnSpacing;
			var q = vert ? float2(size, Max(at)) : float2(Max(at), size);
			return q;
		}
		
	}
}