using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse;
using Fuse.Controls;
using Fuse.Elements;


namespace Fuse.Layouts
{
	public enum FlowDirection
	{
		LeftToRight, RightToLeft
	}

	public class WrapLayout : Layout
	{
		bool _hasItemHeight = false;
		float _itemHeight;
		public float ItemHeight
		{
			get { return _itemHeight; }
			set
			{
				_itemHeight = value;
				_hasItemHeight = true;
			}
		}

		bool _hasItemWidth = false;
		float _itemWidth;
		public float ItemWidth
		{
			get { return _itemWidth; }
			set
			{
				_itemWidth = value;
				_hasItemWidth = true;
			}
		}

		Orientation _orientation = Orientation.Horizontal;
		public Orientation Orientation
		{
			get { return _orientation; }
			set
			{
				_orientation = value;
			}
		}
		
		bool IsVert
		{	
			get { return Orientation == Orientation.Vertical; }
		}

		FlowDirection _flowDirection = FlowDirection.LeftToRight;
		public FlowDirection FlowDirection
		{
			get { return _flowDirection; }
			set
			{
				_flowDirection = value;
			}
		}

		Alignment _rowAlignment = Alignment.Default;
		/**
			@deprecated 2017-07-07
		*/
		public Alignment RowAlignment
		{
			get { return _rowAlignment; }
			set
			{
				Fuse.Diagnostics.Deprecated( "Use ContentAlignment instead of RowAlignment.", this );
				if (_rowAlignment != value)
				{
					_rowAlignment = value;
					InvalidateLayout();
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
					InvalidateLayout();
				}
			}
		}
		
		OptionalSimpleAlignment EffectiveRowAlignment
		{
			get
			{
				if (IsVert)
					return AlignmentHelpers.GetHorizontalSimpleAlignOptional(RowAlignment);
				else
					return AlignmentHelpers.GetVerticalSimpleAlignOptional(RowAlignment);
			}
		}
		
		public string ID { get; set; }

		internal override float2 GetContentSize(
			IList<Node> elements,
			LayoutParams lp)
		{
			return Arrange(elements, lp, false);
		}
		
		internal override void ArrangePaddingBox(
			IList<Node> elements,
			float4 padding,
			LayoutParams lp)
		{
			Arrange(elements, lp, true, padding);
		}
		
		float2 Arrange(IList<Node> elements, LayoutParams lp,	
			bool doArrange, float4 padding = float4(0))
		{
			var nlp = lp.CloneAndDerive();
			nlp.RemoveSize(padding);
			
			bool hasX, hasY;
			var lpav = nlp.GetAvailableSize( out hasX, out hasY );
			float majorAvail = IsVert ? (hasY ? lpav.Y : float.PositiveInfinity) : (hasX ? lpav.X : float.PositiveInfinity);

			float minorMaxSize = 0;
			float minorUsed = 0;
			float majorUsed = 0;
			float majorMaxUsed = 0;

			//construct child layout parameters. They are essentially unconstrained, but must respect
			//the current max, or treat current size as max if no max
			var clp = nlp.Clone();
			clp.RetainXY(false,false);
			clp.ConstrainMax( lpav, hasX, hasY );
			if (_hasItemWidth)
				clp.SetX(ItemWidth);
			if (_hasItemHeight)
				clp.SetY(ItemHeight);

			var placements = new float4[elements.Count];
			//minorMaxSize in each major row, assinged per element
			var minorSizes = new float[elements.Count];
			// save the available space for each row
			var majorRest = new Dictionary<float, float>();
			//where this row starts
			int majorStart = 0;
			
			for (int i = 0; i < elements.Count;++i)
			{
				var e = elements[i] as Visual;
				if (!AffectsLayout(e))
					continue;

				var eSize = e.GetMarginSize( clp );
				//force sizes if misbehaved
				eSize = float2(
					_hasItemWidth ? ItemWidth : eSize.X,
					_hasItemHeight ? ItemHeight : eSize.Y);

				var cmajorSize = IsVert ? eSize.Y : eSize.X;
				var cminorSize = IsVert ? eSize.X : eSize.Y;
				placements[i].Z = cmajorSize;
				placements[i].W = cminorSize;
				
				//need next row?
				if ( (majorUsed + cmajorSize) > majorAvail && majorUsed > 0)
				{
					for (int j=majorStart; j < i; ++j)
						minorSizes[j] = minorMaxSize;
					majorMaxUsed = Math.Max(majorMaxUsed, majorUsed);
					minorUsed += minorMaxSize;
					
					minorMaxSize = 0;
					majorUsed = 0;
					majorStart = i;
				}
				
				placements[i].X = majorUsed;
				placements[i].Y = minorUsed;
				minorMaxSize = Math.Max(minorMaxSize, cminorSize);
				majorUsed += cmajorSize;
				majorRest[minorUsed] = majorAvail - majorUsed;
			}

			//final bits
			for (int j=majorStart; j < elements.Count; ++j)
				minorSizes[j] = minorMaxSize;
			majorMaxUsed = Math.Max(majorMaxUsed, majorUsed);
			minorUsed += minorMaxSize;

			if (doArrange)
			{	
				var sa = EffectiveRowAlignment;
				var eca = ContentAlignment;
				var sca = IsVert ? AlignmentHelpers.GetVerticalSimpleAlignOptional(ContentAlignment) : AlignmentHelpers.GetHorizontalSimpleAlignOptional(ContentAlignment);
				if (eca != Alignment.Default)
				{
					sa = IsVert ? AlignmentHelpers.GetHorizontalSimpleAlignOptional(ContentAlignment) : AlignmentHelpers.GetVerticalSimpleAlignOptional(ContentAlignment);
				}
				var elp = lp.CloneAndDerive();
				for (int i=0; i < elements.Count; ++i)
				{
					var element = elements[i] as Visual;
					if (element == null) continue;
					if (ArrangeMarginBoxSpecial(element, padding, lp ))
						continue;

					var placement = placements[i];

					switch (sa)
					{
						case OptionalSimpleAlignment.Begin:
							break;
						case OptionalSimpleAlignment.End:
							placement.Y += minorSizes[i] - placement.W;
							break;
						case OptionalSimpleAlignment.Center:
							placement.Y += (minorSizes[i] - placement.W)/2;
							break;
						case OptionalSimpleAlignment.None:
							//stretchs to fill
							placement.W = minorSizes[i];
							break;
					}

					switch (sca)
					{
						case OptionalSimpleAlignment.Begin:
							break;
						case OptionalSimpleAlignment.End:
							placement.X += majorRest[placements[i].Y];
							break;
						case OptionalSimpleAlignment.Center:
							placement.X += majorRest[placements[i].Y] / 2;
							break;
						case OptionalSimpleAlignment.None:
							break;
					}
					
					if (IsVert)
						placement = placement.YXWZ;
					
					if (FlowDirection == FlowDirection.RightToLeft)
						placement = float4( nlp.X - placement.X - placement.Z, placement.YZW );
					
					elp.SetSize(float2(placement.Z,placement.W));
					element.ArrangeMarginBox(
						padding.XY + placement.XY, elp);
				}
			}
			
			var sz = IsVert ? float2(minorUsed, majorMaxUsed)
				: float2(majorMaxUsed, minorUsed);
			return sz;
		}
	}
}