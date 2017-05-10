using Uno;
using Uno.Collections;
using Uno.UX;
using Fuse.Layouts;
using Fuse.Elements;

namespace Fuse.Controls
{
	
	/** Lays out children in a grid formation.

		## RowCount and ColumnCount properties

		If what you need is a certain number of equally sized rows and/or columns,
		you can use the @RowCount and @ColumnCount properties.

			<Grid RowCount="4" ColumnCount="2"/>

		By default, elements in the grid are placed in the order they appear in UX, from left to right,
		top to bottom. However, you can explicitly specify per element which grid cell they should be placed
		in using the `Row` and `Column` properties.

			<Grid RowCount="1" ColumnCount="2">
				<Rectangle Row="0" Column="1" Color="Red"/>
				<Rectangle Row="0" Column="0" Color="Blue"/>
			</Grid>

		If you want an element to occupy multiple rows or columns,
		you can use the `RowSpan` and `ColumnSpan` properties.

			<Grid RowCount="2" ColumnCount="2">
				<Rectangle ColumnSpan="2" RowSpan="2" Color="Red"/>
			</Grid>

		## Rows and Columns properties

		More fine grained control of how the rows and column sizes are calculated can be achieved with the
		@Rows and @Columns properties. These properties accept a comma separated list of *grid sizes* which
		can take on a few different forms. The values can either be absolute, relative or automatic.

		Example of a Grid with 3 rows of size 10, 10 and 50 points, and 3 columns, the first each occupy 20%
		of the available space and the last one occupies 60%.

			<Grid Rows="10,10,50" Columns="1*,1*,3*"/>

		The proportional column sizes here are calculated by first summing all the values (1+1+3 = 5).
		Then we divide our value by the total (1/5 = 20%, 1/5 = 20%, 3/5 = 60%).
		
		Note that proportional sizes only make sense if the grid is expanding to fill the parent panel, or
		has a fixed size. If it is shrinking to fit it's contents the proportional rows/columns will have zero
		size.

		The following Grid has 2 rows where the first row gets the height of the tallest element in that row,
		and the second row takes up any remaining space:

			<Grid Rows="auto,1*" />

	*/
	public class Grid : Panel
	{

		[UXAttachedPropertySetter("Grid.Row")]
		/**
			The index of the row the element occupies while in a @Grid.
			If not set, the grid will place the element in a cell according to its position in the child list.
		*/
		public static void SetRow(Element elm, int row)
		{
			GridLayout.SetRow(elm, row);
		}

		[UXAttachedPropertyGetter("Grid.Row")]
		public static int GetRow(Element elm)
		{
			return GridLayout.GetRow(elm);
		}

		[UXAttachedPropertyResetter("Grid.Row")]
		public static void ResetRow(Element elm)
		{
			GridLayout.ResetRow(elm);
		}

		[UXAttachedPropertySetter("Grid.RowSpan")]
		/** The number of rows this element occupies in a @Grid. Defaults to 1. */
		public static void SetRowSpan(Element elm, int span)
		{
			GridLayout.SetRowSpan(elm, span);
		}

		[UXAttachedPropertyGetter("Grid.RowSpan")]
		public static int GetRowSpan(Element elm)
		{
			return GridLayout.GetRowSpan(elm);
		}

		[UXAttachedPropertyResetter("Grid.RowSpan")]
		public static void ResetRowSpan(Element elm)
		{
			GridLayout.ResetRowSpan(elm);
		}

		[UXAttachedPropertySetter("Grid.Column")]
		/**
			The index of the column the element occupies while in a @Grid.
			If not set, the grid will place the element in a cell according to its position in the child list.
		*/
		public static void SetColumn(Element elm, int col)
		{
			GridLayout.SetColumn(elm, col);
		}

		[UXAttachedPropertyGetter("Grid.Column")]
		public static int GetColumn(Element elm)
		{
			return GridLayout.GetColumn(elm);
		}

		[UXAttachedPropertyResetter("Grid.Column")]
		public static void ResetColumn(Element elm)
		{
			GridLayout.ResetColumn(elm);
		}

		[UXAttachedPropertySetter("Grid.ColumnSpan")]
		/** The number of columns this element occupies in a @Grid. Defaults to 1. */
		public static void SetColumnSpan(Element elm, int span)
		{
			GridLayout.SetColumnSpan(elm, span);
		}

		[UXAttachedPropertyGetter("Grid.ColumnSpan")]
		public static int GetColumnSpan(Element elm)
		{
			return GridLayout.GetColumnSpan(elm);
		}

		[UXAttachedPropertyResetter("Grid.ColumnSpan")]
		public static void ResetColumnSpan(Element elm)
		{
			GridLayout.ResetColumnSpan(elm);
		}

		[UXContent]
		/** The list of Row objects.

			These objects are typically created when parsing the @Rows string.
			
			@advanced
		*/
		public IList<Row> RowList { get { return _gridLayout.RowList; } }

		/** The sizes of the rows of the grid as a comma-separated list of grid sizes. 

			Can not be used together with @RowCount.

			Grid sizes are denoted as follows:

			* Plain numbers, e.g. `100` means a fixed size of 100 points (device independent pixels).
			* `auto` indicates that the row/column should take up the smallest possible size that contains content elements.
			* Numbers postfixed with `*` denote a proportional ratio of the remaining space after all fixed size and `auto` rows/columns are subtracted.

			Example of a Grid with 3 rows where the first two each occupy 20% of the available space, and the last one occupies 60%:

				<Grid Rows="1*,1*,3*"/>
				
			The sizes here are calculated by first summing all the values (1+1+3 = 5).
			Then we divide our value by the total (1/5 = 20%, 1/5 = 20%, 3/5 = 60%).

			Example of a Grid with 4 rows where the first row is 100 points wide, the next row takes as much space as needed (`auto`), and the last two rows
			share the remaining space with a 1:2 ratio:

				<Grid Rows="100,auto,1*,2*" />
		*/
		public string Rows
		{
			get { return _gridLayout.Rows; }
			set { _gridLayout.Rows = value; }
		}

		/** @deprecated */
		public string RowData
		{
			get
			{
				Fuse.Diagnostics.Deprecated("Grid.RowData has been deprecated. Use Grid.Rows instead", this);
				return _gridLayout.Rows;
			}
			set
			{
				Fuse.Diagnostics.Deprecated("Grid.RowData has been deprecated. Use Grid.Rows instead", this);
				_gridLayout.Rows = value;
			}
		}

		/** If specified, children will be distributed into the given number of rows, of equal height.

			Can not be used together with @Rows.
		*/
		public int RowCount
		{
			get { return _gridLayout.RowCount; }
			set { _gridLayout.RowCount = value; }
		}

		/** The default grid size of an automatically created row.

			Default is `1*` - all rows equally sharing remaining space.
			
			This default only makes sense if your `Grid` expands to fill an area. If the grid shrinks to fit the contents, such as when it is aligned, or in a DockPanel, StackPanel, or ScrollView, then this default will not work. You may instead want `auto` as the default.
			
			See @Rows and @RowCount.
		*/
		public string DefaultRow
		{
			get { return _gridLayout.DefaultRow; }
			set { _gridLayout.DefaultRow = value; }
		}
		
		[UXContent]
		/** The list of Column objects.

			These objects are typically created when parsing the @Columns string.

			@advanced
		*/
		public IList<Column> ColumnList { get { return _gridLayout.ColumnList; } }

		/** The sizes of the columns of the grid as a comma-separated list.

			Can not be used together with @ColumnCount.

			Grid sizes are denoted as follows:

			* Plain numbers, e.g. `100` means a fixed size of 100 points (device independent pixels).
			* `auto` indicates that the row/column should take up the smallest possible size that contains content elements.
			* Numbers postfixed with `*` denote a proportional ratio of the remaining space after all fixed size and `auto` rows/columns are subtracted.

			Example of a Grid with 3 columns where the first two each occupy 20% of the available space, and the last one occupies 60%:

				<Grid Columns="1*,1*,3*"/>
				
			The sizes here are calculated by first summing all the values (1+1+3 = 5).
			Then we divide our value by the total (1/5 = 20%, 1/5 = 20%, 3/5 = 60%).

			Example of a Grid with 4 columns where the first row is 100 points wide, the next row takes as much space as needed (`auto`), and the last two columns
			share the remaining space with a 1:2 ratio:

				<Grid Columns="100,auto,1*,2*" />
		*/
		public string Columns
		{
			get { return _gridLayout.Columns; }
			set { _gridLayout.Columns = value; }
		}

		/** @deprecated */
		public string ColumnData
		{
			get
			{
				Fuse.Diagnostics.Deprecated("Grid.ColumnData has been deprecated. Use Grid.Columns instead", this);
				return _gridLayout.Columns;
			}
			set
			{
				Fuse.Diagnostics.Deprecated("Grid.ColumnData has been deprecated. Use Grid.Columns instead", this);
				_gridLayout.Columns = value;
			}
		}

		/** If specified, children will be distributed into the given number of columns, of equal width.

			Can not be used together with @Columns.
		*/
		public int ColumnCount
		{
			get { return _gridLayout.ColumnCount; }
			set { _gridLayout.ColumnCount = value; }
		}

		/** The default grid size of an automatically created column.

			Default is `1*` - all columns equally sharing remaining space.
			
			See @Columns and @ColumnCount.
		*/
		public string DefaultColumn
		{
			get { return _gridLayout.DefaultColumn; }
			set { _gridLayout.DefaultColumn = value; }
		}

		readonly GridLayout _gridLayout;
		/** The spacing between cells, in points. */
		public float CellSpacing
		{
			get { return _gridLayout.CellSpacing; }
			set { _gridLayout.CellSpacing = value; }
		}

		/** The alignment of content within the cells. */
		public Alignment ContentAlignment
		{
			get { return _gridLayout.ContentAlignment; }
			set { _gridLayout.ContentAlignment = value; }
		}

		/** Whether the children are ordered in rows or columns for automatic cell placement. */
		public GridChildOrder ChildOrder
		{
			get { return _gridLayout.ChildOrder; }
			set { _gridLayout.ChildOrder = value; }
		}
		
		public Grid()
		{
			Layout = _gridLayout = new GridLayout();
		}
		
		
	}
}
