using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse;
using Fuse.Controls;
using Fuse.Elements;

namespace Fuse.Layouts
{
	/**	
		Specifies the size of a row or column in a Grid.
		
		The string syntax for this definition is:
		
		- `auto`: `Metric="Auto"`, the `Extent` is not relevant
		- `default`:  `Metric="Default"` with an `Extent="1"`
		- `##`: `Metric="Absolute" with `Extent="##"` (## is a size in points)
		- `##*`: `Metric="Proportion" with `Extent="##" (## is the weight of the row/column)
	*/
	public abstract class DefinitionBase : PropertyObject
	{
		internal event Action Changed;
		protected internal void OnChanged() { if (Changed != null) Changed(); }

		protected DefinitionBase() { }
		
		protected DefinitionBase(float extent, Metric metric)
		{
			_extent = extent;
			_metric = metric;
		}
		
		internal DefinitionBase( DefinitionBase copy, CreationType creation )
		{
			Copy(copy, creation);
		}
		
		internal void Copy<T>(T copy, CreationType creation ) where T : DefinitionBase
		{
			Metric = copy.Metric;
			Extent = copy.Extent;
			Creation = creation;
		}
		
		float _actualOffset;
		
		public float ActualOffset
		{
			get { return _actualOffset; }
			internal set
			{
				_actualOffset = value;
			}
		}

		internal enum CreationType
		{
			//an explicit instance of this definition
			Explicit,
			//parsed from a string
			Parsed,
			//using the default via a `Count` property
			Count,
			//implied to fill in empty spaces
			Implied,
		}
		
		internal CreationType Creation = CreationType.Explicit;
		
		internal bool UsesDefault
		{
			get { return Creation == CreationType.Count || Creation == CreationType.Implied; }
		}
		internal bool IsImplied
		{
			get { return Creation == CreationType.Implied; }
		}
		
		Metric _metric = Metric.Proportion;
		public Metric Metric
		{
			get { return _metric; }
			set 
			{ 
				if (_metric != value)
				{
					_metric = value;
					OnChanged();
				}
			}
		}
		
		float _extent = 1;
		public float Extent
		{
			get { return _extent; }
			set
			{
				if (_extent != value)
				{
					_extent = Math.Max(0,value);
					OnChanged();
				}
			}
		}
		
		internal float ActualExtent;
		internal bool HasActualExtent;

		static internal protected void Parse<T>(string data, IList<T> output) where T : DefinitionBase, new()
		{
			output.Clear();
			if (data == null)
				return;

			var s = data.Split(',');
			for (int i = 0; i < s.Length; i++)
				output.Add( Parse<T>(s[i]) );
		}
		static internal protected T Parse<T>(string data) where T : DefinitionBase, new()
		{
			try
			{
				var t = data.Trim().ToLower();
				var n = new T();
				n.Creation = CreationType.Parsed;
				if (t.Length > 0 && t[t.Length-1] == '*')
				{
					var k = t.Substring(0,t.Length-1).Trim();
					n.Extent = float.Parse(k);
					n.Metric = Metric.Proportion;
				}
				else if (t == "auto")
				{
					n.Extent = 1;
					n.Metric = Metric.Auto;
				}
				else if(t == "default")
				{
					n.Extent = 1;
					n.Metric = Metric.Default;
				}
				else
				{
					n.Extent = float.Parse(t);
					n.Metric = Metric.Absolute;
				}
				
				return n;
			}
			catch (Exception e)
			{
				/* swallow number parse exceptions */
				var n = new T();
				n.Extent = 0;
				n.Metric = Metric.Absolute;
				n.Creation = CreationType.Parsed;
				return n;
			}
		}
		
		internal string Serialize()
		{
			switch (Metric)
			{
				case Metric.Auto: return "auto";
				case Metric.Proportion: return Extent + "*";
				case Metric.Default: return "default";
				default: return Extent.ToString();
			}
		}

		internal static string Serialize<T>(IList<T> columns) where T : DefinitionBase
		{
			var s = "";
			for (int i = 0; i < columns.Count; i++)
			{
				if (i > 0) s += ", ";
				s += columns[i].Serialize();
			}
			return s;
		}
	}

	/**
		How to calculate the size of a row/column in a Grid.
	*/
	public enum Metric
	{
		/**
			The size is an absolute value in points.
		*/
		Absolute,
		/**
			The size is assigned proportionally between all rows/columns with a `Propertion` metric. The space divided is the total size available to the grid less all `Absolute` and `Auto` sized rows/columns.
			
			If the size of the dimension is not known, such as an aligned grid, or the row height in a `StackPanel`, the `Proportion` metric will result in 0 size.
		*/
		Proportion,
		/**
			The size is calculated based on the content of the cells.
		*/
		Auto,
		/** 
			This is the mode used if none is specified. It will behave as `Auto` if the layout size is unavailable, and will behave as `Proportion` if available (when the grid is stretched).
			
			This default is only suitable for grids where the size is known, or stretched to fill the parent. It also works if only one-dimension is known and there is only 1 row or column. Any grid with mulitple rows and columns that are not stretched, should not use this default, opting for `Absolute` or `Auto` instead. 
		*/
		Default,
	}

	public sealed class Column: DefinitionBase
	{
		public Column() { }

		public Column(float width, Metric metric)
			: base( width, metric ) { }
			
		private Column(Column copy, CreationType creation)
			: base( copy, creation ) { }

		public Metric WidthMetric
		{
			get { return base.Metric; }
			set { base.Metric = value; }
		}

		public float Width
		{
			get { return base.Extent; }
			set { base.Extent = value; }
		}

		internal Column CloneDef(CreationType creation) { return new Column(this, creation); }
	}

	public sealed class Row: DefinitionBase
	{
		public Row() { }

		public Row(float height, Metric metric)
			: base( height, metric ) { }

		private Row(Row copy, CreationType creation)
			: base( copy, creation ) { }
			
		public Metric HeightMetric
		{
			get { return base.Metric; }
			set { base.Metric = value; }
		}

		public float Height
		{
			get { return base.Extent; }
			set { base.Extent = value; }
		}

		internal Row CloneDef(CreationType creation) { return new Row(this, creation); }
	}

	public enum GridChildOrder
	{
		RowMajor,
		ColumnMajor,
	}
	
	public sealed class GridLayout : Layout
	{
		[	UXContent]
		public IList<Row> RowList { get { return _rows; } }

		public string Rows
		{
			get { return Row.Serialize(RowList); }
			set
			{
				DefinitionBase.Parse(value, RowList);
				Changed();
			}
		}

		GridChildOrder _childOrder = GridChildOrder.RowMajor;
		public GridChildOrder ChildOrder
		{
			get { return _childOrder; }
			set
			{
				if (_childOrder != value)
				{
					_childOrder = value;
					Changed();
				}
			}
		}
		
		static Row _staticDefaultRow = new Row{ Metric = Metric.Default, Extent = 1 };
		Row _defaultRow = _staticDefaultRow;
		public string DefaultRow
		{
			get { return _defaultRow.Serialize(); }
			set
			{
				_defaultRow = DefinitionBase.Parse<Row>(value);
				ModifyDefault(_rows, _defaultRow);
			}
		}
		
		void ModifyDefault<T>(RootableList<T> list, T primordial ) where T : DefinitionBase, new()
		{
			for (int i=0; i < list.Count; ++i)
			{
				if (list[i].UsesDefault)
				{
					var n = new T();
					n.Copy(primordial, list[i].Creation);
					list.ReplaceAt(i, n);
				}
			}
			Changed();
		}
		
		public int RowCount
		{
			get { return RowList.Count; }
			set { ModifyCount(_rows, value, _defaultRow); }
		}
		
		/** The numbers of rows/cols as specified by the user (no implied items) */
		int UserCount<T>( IList<T> list ) where T : DefinitionBase
		{
			int c = list.Count;
			while (c > 0 && list[c-1].IsImplied)
				c--;
				
			return c;
		}
		
		void ModifyCount<T>(IList<T> list, int count, T primordial ) where T : DefinitionBase, new()
		{
			if (count == list.Count)
				return;
				
			//due to data-binding setting a default of 0 we can't trigger an error on <= 0, but only <0
			//but setting 0 is really just a way to resetting the explicit count and letting explicit Column
			//and ColumnSpan properties take precedence
			if (count < 0)
			{
				Fuse.Diagnostics.UserError( "RowCount and ColumnCount must be >= 1", this );
				return;
			}
				
			while (list.Count < count) 
			{
				var n = new T();
				n.Copy(primordial, DefinitionBase.CreationType.Count);
				list.Add(n);
			}
			while (list.Count > count) 
				list.RemoveLast();
			for (int i=0; i < list.Count; ++i)
			{
				//non-implied items retain their current status, this allows extended a grid
				//without modifying the current items
				if (list[i].IsImplied)
					list[i].Creation = DefinitionBase.CreationType.Count;
			}
			Changed();
		}
		

		[UXContent]
		public IList<Column> ColumnList { get { return _columns; } }

		public string Columns
		{
			get { return Column.Serialize(ColumnList); }
			set
			{
				DefinitionBase.Parse(value, ColumnList);
				Changed();
			}
		}

		static Column _staticDefaultColumn = new Column{ Metric = Metric.Default, Extent = 1 };
		Column _defaultColumn = _staticDefaultColumn;
		public string DefaultColumn
		{
			get { return _defaultColumn.Serialize(); }
			set
			{
				_defaultColumn = DefinitionBase.Parse<Column>(value);
				ModifyDefault(_columns, _defaultColumn);
			}
		}
		
		public int ColumnCount
		{
			get { return ColumnList.Count; }
			set { ModifyCount(_columns, value, _defaultColumn); }
		}
		
		Column GetColumnData(int column)
		{
			if (column >= 0 && column < _columns.Count)
				return _columns[column];
			return null;
		}
		
		Row GetRowData(int row)
		{
			if (row >= 0 && row < _rows.Count)
				return _rows[row];
			return null;
		}
		
		float _cellSpacing = 0;
		public float CellSpacing
		{
			get { return _cellSpacing; }
			set
			{
				if (_cellSpacing != value)
				{
					_cellSpacing = value;
					Changed();
				}
			}
		}
		
		Alignment _contentAlignment = Alignment.Default;
		public Alignment ContentAlignment
		{
			get { return _contentAlignment; }
			set
			{
				if (_contentAlignment != value)
				{
					_contentAlignment = value;
					Changed();
				}
			}
		}

		static readonly PropertyHandle _rowProperty = Fuse.Properties.CreateHandle();
		static readonly PropertyHandle _actualRowProperty = Fuse.Properties.CreateHandle();
		static readonly PropertyHandle _rowSpanProperty = Fuse.Properties.CreateHandle();
		static readonly PropertyHandle _columnProperty = Fuse.Properties.CreateHandle();
		static readonly PropertyHandle _actualColumnProperty = Fuse.Properties.CreateHandle();
		static readonly PropertyHandle _columnSpanProperty = Fuse.Properties.CreateHandle();
		
		public static void SetRow(Visual elm, int row)
		{
			elm.Properties.Set(_rowProperty, row);
			InvalidateAncestorLayout(elm);
		}

		public static int GetRow(Visual elm)
		{
			object v;
			if (elm.Properties.TryGet(_rowProperty, out v)) return (int)v;
			else return 0;
		}

		int GetActualRow(Visual elm)
		{
			object v;
			if (elm.Properties.TryGet(_actualRowProperty, out v)) 
				return (int)v;
			//it's not part of the proper grid
			return -1;
		}

		public static void ResetRow(Visual elm)
		{
			elm.Properties.Clear(_rowProperty);
			InvalidateAncestorLayout(elm);
		}

		public static void SetRowSpan(Visual elm, int span)
		{
			elm.Properties.Set(_rowSpanProperty, span);
			InvalidateAncestorLayout(elm);
		}

		public static int GetRowSpan(Visual elm)
		{
			object v;
			if (elm.Properties.TryGet(_rowSpanProperty, out v)) return (int)v;
			else return 1;
		}

		public static void ResetRowSpan(Visual elm)
		{
			elm.Properties.Clear(_rowSpanProperty);
			InvalidateAncestorLayout(elm);
		}

		public static void SetColumn(Visual elm, int col)
		{
			elm.Properties.Set(_columnProperty, col);
			InvalidateAncestorLayout(elm);
		}

		public static int GetColumn(Visual elm)
		{
			object v;
			if (elm.Properties.TryGet(_columnProperty, out v)) return (int)v;
			else return 0;
		}
		
		void CalcActualPositions(Visual container)
		{
			bool rowMajor = ChildOrder == GridChildOrder.RowMajor;
			
			//find expected max column
			int minorCount = Math.Max(1,rowMajor ? UserCount(ColumnList) : UserCount(RowList));
			for (var e = container.FirstChild<Visual>(); e != null; e = e.NextSibling<Visual>())
			{
				if (!AffectsLayout(e)) continue;

				if (rowMajor)
					minorCount = Math.Max( minorCount, GetColumn(e) + GetColumnSpan(e) );
				else
					minorCount = Math.Max( minorCount, GetRow(e) + GetRowSpan(e) );
			}

			//this is the next available position in the minor-axis, per major-axis. This is used so that
			//spanning cells aren't overwritten in subsequent automatic positioning.
			//any "known" location resets the automatic indexing to just after that position, thereby
			//breaking the avail system (we'll live with limitaiton that for now)
			var majorAvail = new List<int>(minorCount);
			for (int c=0; c< minorCount; c++)
				majorAvail.Add(0);
				
			int rowAt = 0;
			int colAt = 0;
			
			int maxRow = 0;
			int maxCol = 0;
			
			for (var elm = container.FirstChild<Visual>(); elm != null; elm = elm.NextSibling<Visual>())
			{
				if (!AffectsLayout(elm)) continue;

				object v;
				bool haveCol = false, haveRow = false;
				if (elm.Properties.TryGet(_columnProperty, out v))
				{
					colAt = (int)v;
					haveCol = true;
				}
				
				if (elm.Properties.TryGet(_rowProperty, out v))
				{
					rowAt = (int)v;
					haveRow = true;
				}
				
				if (haveRow && !haveCol)
					colAt = 0;
				if (haveCol && !haveRow)
					rowAt = 0;
				
				if (!haveRow && !haveCol)
				{
					if ( rowMajor )
					{
						while (rowAt < majorAvail[colAt])
						{
							colAt++;
							if (colAt >= minorCount)
							{
								rowAt++;
								colAt=0;
							}
						}
					}
					else
					{
						while (colAt < majorAvail[rowAt])
						{
							rowAt++;
							if (rowAt >= minorCount)
							{
								colAt++;
								rowAt=0;
							}
						}
					}
				}
					
				elm.Properties.Set(_actualRowProperty, rowAt);
				elm.Properties.Set(_actualColumnProperty, colAt);
				
				var xs = GetColumnSpan(elm);
				var ys = GetRowSpan(elm);

				maxRow = Math.Max(maxRow, rowAt + ys);
				maxCol = Math.Max(maxCol, colAt + xs);
				
				//if an explicit position moves earlier in the grid (that it's natural child ordering)
				//the behaviour of  majorAvail, and auto-position becomes undefined
				if (rowMajor)
				{
					for (int c=colAt; c < Math.Min(minorCount, colAt+xs); c++)
						majorAvail[c] = rowAt + ys;
				}
				else
				{
					for (int c=rowAt; c < Math.Min(minorCount, rowAt+ys); c++)
						majorAvail[c] = colAt + xs;
				}
			}
			
			//trim/expand missing rows/columns
			TrimPad( _rows, maxRow, _defaultRow );
			TrimPad( _columns, maxCol, _defaultColumn );
		}

		void TrimPad<T>( IList<T> list, int count, T primordial ) where T : DefinitionBase, new()
		{
			while (list.Count < count)
			{
				//UNO: I can't find any way to create a clone that can return type T, or be casted as such
				var n = new T();
				n.Copy(primordial, DefinitionBase.CreationType.Implied);
				list.Add(n);
			}
			for (int i= list.Count-1; i >= count; --i)
			{
				if (!list[i].IsImplied)
					break;
					
				list.RemoveAt(i);
			}
		}

		int GetActualColumn(Visual elm)
		{
			object v;
			if (elm.Properties.TryGet(_actualColumnProperty, out v)) 
				return (int)v;
			//it's not part of the proper grid
			return -1;
		}

		public static void ResetColumn(Visual elm)
		{
			elm.Properties.Clear(_columnProperty);
			InvalidateAncestorLayout(elm);
		}

		public static void SetColumnSpan(Visual elm, int span)
		{
			elm.Properties.Set(_columnSpanProperty, span);
			InvalidateAncestorLayout(elm);
		}

		public static int GetColumnSpan(Visual elm)
		{
			object v;
			if (elm.Properties.TryGet(_columnSpanProperty, out v)) 
			{
				return (int)v;
			}
			return 1;
		}

		public static void ResetColumnSpan(Visual elm)
		{
			elm.Properties.Clear(_columnSpanProperty);
			InvalidateAncestorLayout(elm);
		}

		readonly RootableList<Row> _rows = new RootableList<Row>();
		readonly RootableList<Column> _columns = new RootableList<Column>();

		void Changed()
		{
			InvalidateLayout();
		}

		void DefinitionAdded(DefinitionBase r)
		{ 
			if (AddListener(r))
				Changed();
		}

		void DefinitionRemoved(DefinitionBase r)
		{
			if (RemoveListener(r))
				Changed();
		}

		bool AddListener( DefinitionBase item )
		{
			if (item.Creation != DefinitionBase.CreationType.Explicit)
				return false;
			item.Changed += Changed;
			return true;
		}
		
		bool RemoveListener( DefinitionBase item )
		{
			//this may seem wrong since the Creation type can change, except that nothing can ever
			//lose the Explicit type
			if (item.Creation != DefinitionBase.CreationType.Explicit)
				return false;
			item.Changed -= Changed;
			return true;
		}
		
		protected override void OnRooted()
		{
			base.OnRooted();
			_rows.RootSubscribe(DefinitionAdded, DefinitionRemoved);
			_columns.RootSubscribe(DefinitionAdded, DefinitionRemoved);
		}
		
		protected override void OnUnrooted()
		{
			base.OnUnrooted();
			_columns.RootUnsubscribe();
			_rows.RootUnsubscribe();
		}

		internal override float2 GetContentSize(Visual container, LayoutParams lp)
		{
			return Measure(container, lp);	
		}

		float EffectiveCellSpacing
		{
			get
			{
				//make pixel sized spacing to get consistent element spacing
				return SnapUp(CellSpacing);
			}
		}
		
		Metric EffectiveMetric(Metric src, bool expand)
		{
			if (src == Metric.Default)
				return expand ? Metric.Proportion : Metric.Auto;
			return src;
		}
		
		float GetTotalProportion<T>(IList<T> list, bool expand) where T : DefinitionBase
		{
			var total = 0.0f;
			for (int i = 0; i < list.Count; i++)
			{
				var c = list[i];
				if (EffectiveMetric(c.Metric,expand) == Metric.Proportion)
					total += c.Extent;
			}
			return total;
		}

		void CalcFill<T>(IList<T> list, float available, float proportion, bool expand) where T : DefinitionBase
		{
			// in pixel snapping ensure each is pixel sized, evenly spreading extra pixels
			var extraWidth = 0f;
			var colWidth = available / proportion;
				
			for (int i = 0; i < list.Count; i++)
			{
				var c = list[i];

				if (EffectiveMetric(c.Metric,expand) != Metric.Proportion)
					continue;
				
				var w = Snap( c.Extent * colWidth + extraWidth );
				extraWidth += c.Extent * colWidth - w;
				c.ActualExtent = w;
				c.HasActualExtent = true;
			}
		}
		
		void CalcInitialExtents<T>(IList<T> list, bool expand, 
			out float used, out bool hasAuto ) where T : DefinitionBase
		{
			hasAuto = false;
			used = 0;
			
			for (int i = 0; i < list.Count; i++)
			{
				var c = list[i];
				c.ActualExtent = 0.0f;
				c.HasActualExtent = false;
				if (c != null && EffectiveMetric(c.Metric,expand) == Metric.Absolute)
				{
					c.ActualExtent = c.Extent;
					c.HasActualExtent = true;
					used += c.Extent;
				}
				
				if (EffectiveMetric(c.Metric,expand) == Metric.Auto)
					hasAuto = true;
			}
		}
		
		float CalcTotalExtentAndOffset<T>(IList<T> list, float effectiveCellSpacing) where T : DefinitionBase
		{
			var total = 0.0f;
			for (int i = 0; i < list.Count; i++)
			{
				if (i > 0)
					total += effectiveCellSpacing;
					
				var c = list[i];
				c.ActualOffset = total;
				total += c.ActualExtent;
			}
			
			return total;
		}
		
		float2 GetAutoSize( Visual child, int x0, int y0, bool expandX, bool expandY,
			out bool knowX, out bool knowY,
			out bool autoX, out bool autoY)
		{
			int xs = GetColumnSpan(child);
			int ys = GetRowSpan(child);
			
			var sz = float2(0);
			knowX = true;
			knowY = true;
			//we can't do auto-sizing on things that span in that direction
			autoX = xs == 1;
			autoY = ys == 1;
			for( int x = x0; x < x0 + xs; x++ )
			{
				var colData = GetColumnData(x);
				if (colData == null || EffectiveMetric(colData.Metric,expandX) == Metric.Auto)
				{
					knowX = false;
				}
				else
				{
					autoX = false;
					if (!colData.HasActualExtent)
						knowX = false;
					else
						sz.X += colData.ActualExtent;
				}
					
				for( int y = y0; y < y0 + ys; y++ )
				{
					var rowData = GetRowData(y);
					if (rowData == null || EffectiveMetric(rowData.Metric,expandY) == Metric.Auto)
					{
						knowY = false;
					}
					else
					{
						autoY = false;
						if (!rowData.HasActualExtent)
							knowY = false;
						else
							sz.Y += rowData.ActualExtent;
					}
				}
			}
			
			return sz;
		}
		
		void CalcAuto(Visual container, ref float availableWidth, ref float availableHeight, bool secondPass,
			bool hasFirstHorzSize, bool hasFirstVertSize,
			bool expandWidth, bool expandHeight)
		{
			for (var child = container.FirstChild<Visual>(); child != null; child = child.NextSibling<Visual>())
			{
				if (!AffectsLayout(child)) continue;

				int x = GetActualColumn(child);
				int y = GetActualRow(child);

				var colData = GetColumnData(x);
				if (colData == null)
					continue;
				var rowData = GetRowData(y);
				if (rowData == null)
					continue;
					
				var sizeMatch = (EffectiveMetric(rowData.Metric,expandHeight) == Metric.Proportion && !hasFirstVertSize)
					|| (EffectiveMetric(colData.Metric,expandWidth) == Metric.Proportion && !hasFirstHorzSize);
				if (sizeMatch != secondPass)
					continue;
				
				bool knowX = false;
				bool knowY = false;
				bool autoX = false;
				bool autoY = false;
				float2 knowSize = GetAutoSize(child, x,y, expandWidth, expandHeight,
					out knowX, out knowY, out autoX, out autoY);
				if (!autoX && !autoY)
					continue;
				var clp = LayoutParams.CreateXY( knowSize,
					knowX && !autoX,  
					knowY && !autoY);
				var cds = child.GetMarginSize(clp);

				if (autoX)
				{
					var w = Math.Max(colData.ActualExtent, cds.X);
					availableWidth -= (w - colData.ActualExtent);
					colData.ActualExtent = w;
					colData.HasActualExtent = true;
				}
				
				if (autoY)
				{
					var h = Math.Max(rowData.ActualExtent, cds.Y);
					availableHeight -= (h - rowData.ActualExtent);
					rowData.ActualExtent = h;
					rowData.HasActualExtent = true;
				}
			}
			
			availableWidth = Math.Max(availableWidth, 0.0f);
			availableHeight = Math.Max(availableHeight, 0.0f);
		}
		
		float2 Measure(Visual container, LayoutParams lp)
		{
			var effectiveCellSpacing = EffectiveCellSpacing;
			
			CalcActualPositions(container);
			
			var fillHorizontal = lp.HasX;
			var fillVertical = lp.HasY;
			var lpAvail = lp.GetAvailableSize();
			var availableWidth = lpAvail.X - effectiveCellSpacing * Math.Max(0,_columns.Count-1);
			var availableHeight = lpAvail.Y - effectiveCellSpacing * Math.Max(0,_rows.Count-1);

			//ideally these would be related to the logical layout parameters, but that isn't really possible,
			//thus they are just taken from the layout fill properties
			var expandWidth = fillHorizontal;
			var expandHeight = fillVertical;
			
			// Reserve space for and measure cols/rows with absolute metrics and reset size for all others
			bool hasAutoCol;
			float usedWidth;
			CalcInitialExtents(_columns, expandWidth, out usedWidth, out hasAutoCol);

			bool hasAutoRow;
			float usedHeight;
			CalcInitialExtents(_rows, expandHeight, out usedHeight, out hasAutoRow);

			availableWidth = Math.Max(availableWidth - usedWidth, 0.0f);
			availableHeight = Math.Max(availableHeight - usedHeight, 0.0f);

			//if there is no auto then we can do fill proportions now (Allows a few more use-cases with still
			//just one pass on children)
			float widthProportion = GetTotalProportion(_columns, expandWidth);
			float heightProportion = GetTotalProportion(_rows, expandHeight);
			
			bool hasFirstHorzSize = false;
			if (!hasAutoCol && fillHorizontal)
			{	
				CalcFill(_columns, availableWidth, widthProportion, expandWidth);
				hasFirstHorzSize = true;
			}
			
			bool hasFirstVertSize = false;
			if (!hasAutoRow && fillVertical)
			{	
				CalcFill(_rows, availableHeight, heightProportion, expandHeight);
				hasFirstVertSize = true;
			}
			
			// Measure cols/rows with auto metrics in both dimensions
			CalcAuto(container, ref availableWidth, ref availableHeight, false, hasFirstHorzSize, hasFirstVertSize,
				expandWidth, expandHeight);

			// do fill for axes not done before
			if (fillHorizontal && !hasFirstHorzSize)
				CalcFill(_columns, availableWidth, widthProportion, expandWidth);
			
			if (fillVertical && !hasFirstVertSize)
				CalcFill(_rows, availableHeight, heightProportion, expandHeight);
			
			//measure again for auto cells that didn't get measured the first pass
			CalcAuto(container, ref availableWidth, ref availableHeight, true, hasFirstHorzSize, hasFirstVertSize,
				expandWidth, expandHeight);

			// Place rows/cols
			float totalWidth = CalcTotalExtentAndOffset(_columns, effectiveCellSpacing);
			float totalHeight = CalcTotalExtentAndOffset(_rows, effectiveCellSpacing);

			CheckMeasureSettings(lp.HasX, lp.HasY);
			return float2(totalWidth, totalHeight);
		}
		
		bool _checkMeasureWarning;
		/*
			Checks the limitations as noted on Metric.Default
		*/
		void CheckMeasureSettings(bool hasX, bool hasY)
		{
			bool bad = false;
			if (HasDefaultMetric(_rows) && !hasY && _rows.Count > 1)
				bad = true;
			if (HasDefaultMetric(_columns) && !hasX && _columns.Count > 1)
				bad = true;
				
			if (bad && !_checkMeasureWarning)
			{
				_checkMeasureWarning = true;
				Fuse.Diagnostics.UserError( "A grid is using incompatible layout parameters which may result in incorrect layout. A grid using `Default` row or column sizing must have only one row or column, or have a known size. Add a `DefaultRow` or `DefaultColumn` to get the desired sizing.", this );
			}
		}
		
		bool HasDefaultMetric<T>( IList<T> list ) where T : DefinitionBase
		{
			for (int i=0; i < list.Count; ++i) {
				if (list[i].Metric == Metric.Default)
					return true;
			}
			return false;
		}

		Alignment EffectiveContentAlignment
		{
			get
			{
				var ca = ContentAlignment;
				if (ca == Alignment.Default)
				{
					if (Container != null)
						ca = Container.Alignment;
					else
						ca = Alignment.TopLeft;
				}
				return ca;
			}
		}
		
		internal override void ArrangePaddingBox(Visual container, float4 padding, 
			LayoutParams lp)
		{
			var remainSize = lp.Size - padding.XY - padding.ZW;
			var measured = Measure( container, LayoutParams.Create(remainSize) );

			var off = float2(0);
			var eca = EffectiveContentAlignment;
			switch (AlignmentHelpers.GetHorizontalSimpleAlign(eca))
			{
				case SimpleAlignment.Begin:
					off.X = padding.X;
					break;
				case SimpleAlignment.Center:
					off.X = remainSize.X/2 - measured.X/2 + padding.X;
					break;
				case SimpleAlignment.End:
					off.X = lp.X - measured.X - padding.Z;
					break;
			}
			switch (AlignmentHelpers.GetVerticalSimpleAlign(eca))
			{
				case SimpleAlignment.Begin:
					off.Y = padding.Y;
					break;
				case SimpleAlignment.Center:
					off.Y = remainSize.Y/2 - measured.Y/2 + padding.Y;
					break;
				case SimpleAlignment.End:
					off.Y = lp.Y - measured.Y - padding.W;
					break;
			}
			
			var effectiveCellSpacing = EffectiveCellSpacing;
			var nlp = lp.CloneAndDerive();
			for (var child = container.FirstChild<Visual>(); child != null; child = child.NextSibling<Visual>())
			{
				if (ArrangeMarginBoxSpecial(child, padding, lp))
					continue;

				var column = GetActualColumn(child);
				var row = GetActualRow(child);
				var rowSpan = GetRowSpan(child);
				var columnSpan = GetColumnSpan(child);

				float x = 0;
				float y = 0;
				float w = remainSize.X;
				float h = remainSize.Y;

				if (column >= 0 && column < _columns.Count)
				{
					var c = _columns[column];
					x = c.ActualOffset;
					w = c.ActualExtent;

					for (int s = column + 1; s < Math.Min(_columns.Count, column + columnSpan); ++s)
					{
						w += _columns[s].ActualExtent + effectiveCellSpacing;
					}
				}

				if (row >= 0 && row < _rows.Count)
				{
					var r = _rows[row];
					y = r.ActualOffset;
					h = r.ActualExtent;

					for (int s = row + 1; s < Math.Min(_rows.Count, row + rowSpan); ++s)
					{
						h += _rows[s].ActualExtent + effectiveCellSpacing;
					}
				}

				nlp.SetSize(float2(w,h));
				child.ArrangeMarginBox(off + float2(x, y), nlp);
			}
		}
		
		internal override LayoutDependent IsMarginBoxDependent( Visual child )
		{
			var c = GetColumnData( GetActualColumn(child) );
			var r = GetRowData( GetActualRow(child) );

			//either the gridhasn't been arranged or it's not part of the grid proper, either way it doesn't
			//affect the margin box
			if (c == null || r == null)
				return LayoutDependent.No;

			return EffectiveMetric(c.Metric,false) != Metric.Auto && 
				EffectiveMetric(r.Metric,false) != Metric.Auto ?
				LayoutDependent.No : LayoutDependent.Yes;
		}
	}
}
