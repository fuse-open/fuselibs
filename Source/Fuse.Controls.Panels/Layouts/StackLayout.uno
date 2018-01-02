using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse;
using Fuse.Controls;
using Fuse.Elements;

namespace Fuse.Layouts
{

	public enum Orientation
	{
		Horizontal,
		Vertical
	}

	public enum StackLayoutMode
	{
		Standard,
		TwoPass,
	}
	
	public sealed class StackLayout : Layout
	{

		Orientation _orientation = Orientation.Vertical;
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

		public void ResetOrientation()
		{
			_orientation = Orientation.Vertical;
			InvalidateLayout();
		}
		
		float _itemSpacing = 0;
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
		
		StackLayoutMode _mode = StackLayoutMode.Standard;
		public StackLayoutMode Mode
		{
			get { return _mode; }
			set
			{
				if (_mode != value)
				{
					_mode = value;
					InvalidateLayout();
				}
			}
		}


		internal override float2 GetContentSize(Visual container, LayoutParams lp)
		{
			var orientation = Orientation;

			var vert = orientation == Orientation.Vertical;
			var nlp = lp.CloneAndDerive();
			nlp.RetainAxesXY(vert, !vert);

			var size = GetElementsSize(container, nlp);
			
			if (Mode == StackLayoutMode.TwoPass)
			{
				bool recalc = false;
				if (orientation == Orientation.Vertical)
				{
					if (!nlp.HasX)
					{
						nlp.SetX(size.X);
						recalc = true;
					}
				}
				else
				{
					if (!nlp.HasY)
					{
						nlp.SetY(size.Y);
						recalc = true;
					}
				}
				
				if (recalc)
					size = GetElementsSize(container, nlp);
			}
				
			return size;
		}

		float EffectiveItemSpacing
		{
			get
			{
				//make pixel sized spacing to get consistent element spacing
				return SnapUp( ItemSpacing );
			}
		}
		
		float2 GetElementsSize(Visual container, LayoutParams lp)
		{
			var orientation = Orientation;
			var desiredSize = float2(0);

			var effectiveSpacing = EffectiveItemSpacing;
			bool firstItem = true;
			for (var c = container.FirstChild<Visual>(); c != null; c = c.NextSibling<Visual>())
			{
				if (!AffectsLayout(c)) continue;

				var spacing = effectiveSpacing;
				if (firstItem)
				{
					spacing = 0;
					firstItem = false;
				}
				
				var cds = c.GetMarginSize(lp);

				if (orientation == Orientation.Horizontal)
				{
					desiredSize.X += cds.X + spacing;
					desiredSize.Y = Math.Max(desiredSize.Y, cds.Y);
				}
				else
				{
					desiredSize.X = Math.Max(desiredSize.X, cds.X);
					desiredSize.Y += cds.Y + spacing;
				}
			}
			return desiredSize;
		}

		SimpleAlignment EffectiveContentAlignment
		{
			get
			{
				var ca = ContentAlignment;
				if (ca == Alignment.Default && Container != null) 
					ca = Container.Alignment;
					
				if (Orientation == Orientation.Vertical)
					return AlignmentHelpers.GetVerticalSimpleAlign(ca);
				else
					return AlignmentHelpers.GetHorizontalSimpleAlign(ca);
			}
		}
		
		internal override void ArrangePaddingBox(Visual container, float4 padding, 
			LayoutParams lp)
		{
			var d = 0.0f;
			var orientation = Orientation;
			var paddingOffset = padding.XY;
			var pad = padding.XY + padding.ZW;
			var nlp = lp.CloneAndDerive();
			nlp.RemoveSize(pad);

			float2 axis;
			if (orientation == Orientation.Vertical)
			{
				nlp.RetainAxesXY(true,false);
				axis = float2(0,1);
			}
			else
			{
				nlp.RetainAxesXY(false, true);
				axis = float2(1,0);
			}

			var effectiveSpacing = EffectiveItemSpacing;
			var hasItem = false;
			for (var c = container.FirstChild<Visual>(); c != null; c = c.NextSibling<Visual>())
			{
				if (ArrangeMarginBoxSpecial(c, padding, lp)) //TODO: hmm, used to drop X/Y Flag
					continue;
				
				if (hasItem)
					d += effectiveSpacing;
				var cds = c.ArrangeMarginBox( axis*d + paddingOffset, nlp);
				d += Vector.Dot(cds,axis);
				hasItem = true;
			}
	
			var sa = EffectiveContentAlignment;
			if (sa != SimpleAlignment.Begin)
			{
				float off;
				if (sa == SimpleAlignment.End)
					off = Vector.Dot(lp.Size-pad,axis) - d;
				else
					off = Vector.Dot(lp.Size-pad,axis)/2 - d/2;

				for (var e = container.FirstChild<Visual>(); e != null; e = e.NextSibling<Visual>())
				{
					if (AffectsLayout(e))
					{
						var old = e.MarginBoxPosition;
						e.AdjustMarginBoxPosition( old + axis*off );
					}
				}
			}
		}
	}
}