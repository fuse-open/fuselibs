using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse;
using Fuse.Controls;
using Fuse.Elements;

namespace Fuse.Layouts
{
	public enum RowLayoutSizing
	{
		Fixed,
		Fill
	}

	public sealed class RowLayout : Layout
	{
		bool _hasRowSize;
		float _rowSize;

		/**	Set size (height) of a row.

			When set the elements will be arranged to fit in fixed row height `RowSize`, otherwise row height will be dynamic.
		*/
		public float RowSize
		{
			get { return _rowSize; }
			set
			{
				if (!_hasRowSize || _rowSize != value)
				{
					_hasRowSize = true;
					_rowSize = value;
					InvalidateLayout();
				}
			}
		}
		float _rowSpacing = 0;
		/**	Spacing between each row.

			@default 0
		*/
		public float RowSpacing
		{
			get { return _rowSpacing; }
			set
			{
				if (_rowSpacing != value)
				{
					_rowSpacing = value;
					InvalidateLayout();
				}
			}
		}

		float _itemSpacing = 0;
		/**	Spacing between each item of a row.

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

		RowLayoutSizing _sizing = RowLayoutSizing.Fixed;
		/**	Controls whether row fills available space.

			By default `Sizing` is set to `Fixed`, which means each row will be the exact size
			specified in `RowSize`.

			When `Sizing` is set to `Fill` the rows will stretch out to fill the space remaning
			after placing as many items as will fit on the display.

			> Note that `Sizing` only will only affect the layout when the `RowSize` attribute is defined.

			@default Fixed
		*/
		public RowLayoutSizing Sizing
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
		
		int _offset;
		Stack<int> _stack = new Stack<int>();
		
		override public int GetPrevOffset()
		{
			return _stack.Count > 0 ? _stack.Pop() : 0;
		}

		override public int GetNextOffset()
		{
			_stack.Push(_offset);
			return _offset;
		}

		internal override float2 GetContentSize(Visual container, LayoutParams lp)
		{		
			if defined(DEBUG) 
				debug_log "[RowLayout] GetContentSize()";
			return Arrange(container, lp);			
		}

		bool _arranging;
		internal override void ArrangePaddingBox(Visual container, float4 padding, LayoutParams lp)
		{
			if (_arranging)
				return;
			if defined(DEBUG) 
				debug_log "[RowLayout] ArrangePaddingBox()";
			Arrange(container, lp, true, padding);
		}

		float2 Arrange(Visual container, LayoutParams lp, bool doArrange = false, float4 padding = float4(0))
		{	
			_arranging = doArrange;
			
			var rowSize = RowSize;
			var rowSpacing = RowSpacing;
			var useRowSize = _hasRowSize;
			var itemSpacing = ItemSpacing;
			var sizing = Sizing;

			var nlp = lp.CloneAndDerive();

			var vlp = useRowSize ? LayoutParams.CreateXY(float2(0.0f, rowSize), false, true) : LayoutParams.CreateEmpty();
			var hlp = LayoutParams.CreateXY(float2(nlp.X, 0.0f), true, false);
			var slp = vlp.CloneAndDerive();
			
			float x = 0.0f, y = 0.0f, my = 0.0f, sy = 1.0f, sp = 0.0f;
			int i, cx = 0;
			float2 nsz;
			Visual v, z;
			
			v = container.FirstChild<Visual>();
			while (v != null)
			{
				if (AffectsLayout(v))
				{
					for (z = v, x = 0.0f, my = 0.0f, cx = 0; z != null && (x + z.GetMarginSize(vlp).X <= nlp.X); z = z.NextSibling<Visual>(), cx++)
					{
						nsz = z.GetMarginSize(vlp);
						x += nsz.X + itemSpacing;
						my = Math.Max(my, nsz.Y);
					}

					if (y == 0)
						_offset = Math.Max(1, cx);

					if (cx == 0) // shrink cell
					{
						nsz = doArrange ? v.ArrangeMarginBox(float2(padding.X, padding.Y + y), hlp) : v.GetMarginSize(hlp); // aspect scale cell	
						y += nsz.Y + rowSpacing;
						v = v.NextSibling<Visual>();
						continue;
					}
					
					if (useRowSize && sizing == RowLayoutSizing.Fill) // calc row scaling factor sy
					{
						if ((z != null && x - itemSpacing != nlp.X) || (z == null && x - itemSpacing > nlp.X * 0.75f)) // special treatment of last row
						{
							sp = (cx - 1) * itemSpacing;
							sy = (nlp.X - sp) / (x - itemSpacing - sp);
							my *= sy;
						}
						else
						{
							sy = 1.0f;
						}
					}
					for (i = 0, x = 0.0f; v != null && i < cx; v = v.NextSibling<Visual>(), i++)
					{
						slp.SetSize(float2(0.0f, rowSize * sy), false, true); // aspect scale
						nsz = doArrange ? v.ArrangeMarginBox(float2(padding.X + x, padding.Y + y), slp) : v.GetMarginSize(slp);
						x += nsz.X + itemSpacing;
					}
					y += my + rowSpacing;
				}
				else
				{
					v = v.NextSibling<Visual>();
					continue;
				}
			}
			
			_arranging = false;
			return float2(nlp.X, y - rowSpacing);
		}
	}
}