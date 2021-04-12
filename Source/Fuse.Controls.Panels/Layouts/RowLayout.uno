using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse;
using Fuse.Controls;
using Fuse.Elements;
using Fuse.Reactive;

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

		Each _each;
		/**
			The `Each` instance to control. This property is required.
		*/
		public Each Each
		{
			get { return _each; }
			set { _each = value; }
		}

		override protected void OnRooted()
		{
			base.OnRooted();

			if (_each == null)
			{
				// find first Each
				foreach (var child in Container.Children)
				{
					if (child is Each)
					{
						_each = child as Each;
						break;
					}
				}
			}

			if (Each == null)
			{
				Fuse.Diagnostics.UserError( "Require an Each", this );
				return;
			}

			if defined(DEBUG_ROWLAYOUT)
				debug_log "[RowLayout.OnRooted()] Each=" + Each;
		}

		int _offset;
		Stack<int> _offsets = new Stack<int>();

		override public int GetPrevOffset()
		{
			return _offsets.Count > 0 ? _offsets.Pop() : 0;
		}

		override public int GetNextOffset()
		{
			_offsets.Push(_offset);
			return _offset;
		}

		void recalcOffsets(LayoutParams lp)
		{
			var offset = Each.Offset;
			
			if defined(DEBUG_ROWLAYOUT) 
				debug_log "[RowLayout.recalcOffsets()] Each.Offset=" + offset;
			
			_offsets.Clear();
			if (offset > 0)
			{
				var array = Each.Items as IArray;
				if (array != null)
				{
					var rowSize = RowSize;
					var useRowSize = _hasRowSize;
					var itemSpacing = ItemSpacing;
					float x = 0.0f;
					int cx = 0, rx = 0;
					for (int i = 0; i <= offset; i++)
					{
						var item = array[i] as IObject;
						float sy = useRowSize ? rowSize / Marshal.ToFloat(item["height"]) : 1.0f;
						float w = Marshal.ToFloat(item["width"]) * sy;
						if (x + w <= lp.X)
						{
							x += w + itemSpacing;
							cx += 1;
						}
						else
						{
							_offsets.Push(Math.Max(1, cx));
							x = w + itemSpacing;
							cx = 1;
							rx = i;
						}
					}
					Each.Offset = rx;
					//UpdateManager.PerformNextFrame(Container.InvalidateVisual, UpdateStage.Primary, 2); // Fix screen not refreshing on iOS
				}
			}
		}

		float _lastX = -1;

		internal override float2 GetContentSize(Visual container, LayoutParams lp)
		{
			if defined(DEBUG_ROWLAYOUT) 
				debug_log "[RowLayout.GetContentSize()]";

			float2 size = Arrange(container, lp);
			
			if (_lastX != -1 && _lastX != size.X)
				recalcOffsets(lp);
			_lastX = size.X;
			
			return size;
		}

		internal override void ArrangePaddingBox(Visual container, float4 padding, LayoutParams lp)
		{
			if defined(DEBUG_ROWLAYOUT) 
				debug_log "[RowLayout.ArrangePaddingBox()]";
			
			Arrange(container, lp, true, padding);
		}

		float2 Arrange(Visual container, LayoutParams lp, bool doArrange = false, float4 padding = float4(0))
		{	
			var rowSize = RowSize;
			var rowSpacing = RowSpacing;
			var useRowSize = _hasRowSize;
			var itemSpacing = ItemSpacing;
			var sizing = Sizing;

			var vlp = useRowSize ? LayoutParams.CreateXY(float2(0.0f, rowSize), false, true) : LayoutParams.CreateEmpty();
			var hlp = LayoutParams.CreateXY(float2(lp.X, 0.0f), true, false);
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
					for (z = v, x = 0.0f, my = 0.0f, cx = 0; z != null && (x + z.GetMarginSize(vlp).X <= lp.X); z = z.NextSibling<Visual>(), cx++)
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
						if ((z != null && x - itemSpacing != lp.X) || (z == null && x - itemSpacing > lp.X * 0.75f)) // special treatment of last row
						{
							sp = (cx - 1) * itemSpacing;
							sy = (lp.X - sp) / (x - itemSpacing - sp);
							my *= sy;
						}
						else
						{
							sy = 1.0f;
						}
					}
					for (i = 0, x = 0.0f; v != null && i < cx; v = v.NextSibling<Visual>(), i++)
					{
						// TODO: check if no RowSize is specified
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
			return float2(lp.X, y - rowSpacing);
		}
	}
}