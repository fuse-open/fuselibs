using Uno;
using Uno.UX;

using Fuse;

namespace Fuse.Elements
{
	/** @hide Not sure how this ended up public */
	public struct BoxPlacement
	{
		//the size of the margin box
		public float2 MarginBox;
		//the position of the padding box
		public float2 Position;
		//the size of the padding box
		public float2 Size;
		
		bool NoGood(float value)
		{
			return Float.IsInfinity(value) || Float.IsNaN(value);
		}
		bool NoGoodSize(float value)
		{
			return NoGood(value) || value < 0;
		}
		
		internal bool SanityConstrain()
		{
			var ret = false;
			if (NoGoodSize(MarginBox.X))
			{
				ret = true;
				MarginBox.X = 0;
			}
			if (NoGoodSize(MarginBox.Y))
			{
				ret = true;
				MarginBox.Y = 0;
			}
			if (NoGoodSize(Size.X))
			{
				ret = true;
				Size.X = 0;
			}
			if (NoGoodSize(Size.Y))
			{
				ret = true;
				Size.Y = 0;
			}
			if (NoGood(Position.X))
			{
				ret = true;
				Position.X = 0;
			}
			if (NoGood(Position.Y))
			{
				ret = true;
				Position.Y = 0;
			}
			
			return ret;
		}
	}
	
	abstract class BoxSizing
	{
		abstract public BoxPlacement CalcBoxPlacement(Element element, float2 position, LayoutParams lp);
		
		/**
			Return the size of the margin box given these LayoutParams for the available margin area.
		*/
		abstract public float2 CalcMarginSize(Element element, LayoutParams lp);
		
		/**
			Calculate the size of padding box to be used for arrangement with these LayoutParams for
			the padding box. This should not consider box sizing contrains, such as Limit, but just
			return the "natural" padding size for the given LayoutParams.
		*/
		abstract public float2 CalcArrangePaddingSize(Element element, LayoutParams lp);

		virtual public void RequestLayout(Element element) { }
		
		virtual public LayoutDependent IsContentRelativeSize(Element element)
		{
			//assume child relative (worst case)
			return LayoutDependent.Yes;
		}
		
		protected float UnitSize( Element element, Size value,
			float relative, bool hasRelative, out bool known )
		{
			known = true;
			var u = value.DetermineUnit();

			if (u == Unit.Points)
				return value.Value;

			if (u == Unit.Pixels)
				return value.Value / element.AbsoluteZoom;
				
			//Percent
			if (hasRelative)
				return value.Value * relative / 100f;

			known = false;
			return 0;
		}
		
		protected SimpleAlignment EffectiveHorizontalAlignment(Element element)
		{
			var raw = AlignmentHelpers.GetHorizontalAlign(element.Alignment);
			
			if (raw == Alignment.Left)
				return SimpleAlignment.Begin;
			if (raw == Alignment.Right)
				return SimpleAlignment.End;
			if (raw == Alignment.HorizontalCenter)
				return SimpleAlignment.Center;
				
			if (element.HasBit(FastProperty1.X))
				return SimpleAlignment.Begin;
				
			return SimpleAlignment.Center;
		}
		
		protected SimpleAlignment EffectiveVerticalAlignment(Element element)
		{
			var raw = AlignmentHelpers.GetVerticalAlign(element.Alignment);
			
			if (raw == Alignment.Top)
				return SimpleAlignment.Begin;
			if (raw == Alignment.Bottom)
				return SimpleAlignment.End;
			if (raw == Alignment.VerticalCenter)
				return SimpleAlignment.Center;
				
			if (element.HasBit(FastProperty1.Y))
				return SimpleAlignment.Begin;
			
			return SimpleAlignment.Center;
		}
		
		protected float SimpleToAnchor( SimpleAlignment align )
		{
			if (align == SimpleAlignment.Begin)
				return 0;
			if (align == SimpleAlignment.End)
				return 100;
			return 50;
		}
		
		protected void EffectiveAnchor( Element element, SimpleAlignment halign, SimpleAlignment valign, 
			out Size2 anchor)
		{
			if (element.HasBit(FastProperty1.Anchor))
			{	
				anchor = element.Anchor;
				return;
			}
			
			anchor = new Size2(new Size(SimpleToAnchor(halign), Unit.Percent), new Size(SimpleToAnchor(valign), Unit.Percent));
		}
		
		[Flags]
		protected enum ConstraintFlags
		{
			None = 0,
			ImplicitMax = 1<<1,
		}
		protected LayoutParams GetConstraints( Element element, LayoutParams lp,
			ConstraintFlags flags = ConstraintFlags.None)
		{
			var c = LayoutParams.CreateEmpty();
			
			bool known = false;
			
			if (!element.Width.IsAuto)
			{
				var x = UnitSize(element, element.Width, lp.RelativeX, lp.HasRelativeX, out known);
				if (known)
					c.SetX(x);
			}
			else if (lp.HasX && //classic WPF, default alignment with no x/y is stretching
				AlignmentHelpers.GetHorizontalAlign(element.Alignment) == Alignment.Default && 
				!element.HasBit(FastProperty1.X))
			{
				c.SetX(lp.X);
			}

			if (!element.Height.IsAuto)
			{
				var y = UnitSize(element, element.Height, lp.RelativeY, lp.HasRelativeY, out known);
				if (known)
					c.SetY(y);
			}
			else if (lp.HasY && 
				AlignmentHelpers.GetVerticalAlign(element.Alignment) == Alignment.Default && 
				!element.HasBit(FastProperty1.Y))
			{
				c.SetY(lp.Y);
			}
			
			known = false;
			Size limit = 0; //unused
			if (element.HasBit(FastProperty1.MaxWidth))
			{
				limit = element.MaxWidth;
				known = true;
			}
			else if( flags.HasFlag(ConstraintFlags.ImplicitMax) && element.Width.IsAuto)
			{
				limit = lp.X;
				known = lp.HasX;
			}
			if (known)
			{
				var mx = UnitSize(element, limit, lp.RelativeX, lp.HasRelativeX, out known);
				if (known)
					c.ConstrainMaxX(mx);
			}
			
			known = false;
			if (element.HasBit(FastProperty1.MaxHeight))
			{
				limit = element.MaxHeight;
				known = true;
			}
			else if ( flags.HasFlag(ConstraintFlags.ImplicitMax) && element.Height.IsAuto)
			{
				limit = lp.Y;
				known = lp.HasY;
			}
			if (known)
			{
				var my = UnitSize(element, limit, lp.RelativeY, lp.HasRelativeY, out known);
				if (known)
					c.ConstrainMaxY(my);
			}
			
			if (element.HasBit(FastProperty1.MinWidth))
			{
				var mn = UnitSize(element, element.MinWidth, lp.RelativeX, lp.HasRelativeX, out known);
				if (known)
					c.ConstrainMinX( mn );
			}
			
			if (element.HasBit(FastProperty1.MinHeight))
			{
				var mn = UnitSize(element, element.MinHeight, lp.RelativeY, lp.HasRelativeY, out known);
				if (known)
					c.ConstrainMinY( mn );
			}
			
			return c;
		}
		
	}
	
	class StandardBoxSizing : BoxSizing
	{
		static public StandardBoxSizing Singleton = new StandardBoxSizing();
		
		override public BoxPlacement CalcBoxPlacement(Element element, float2 position, LayoutParams lp)
		{
			var margin = element.Margin;
			var avSize = lp.Size;

			var marginBox = element.GetMarginSize( lp );
			var paddingBox = marginBox - margin.XY - margin.ZW;
			avSize -= margin.XY + margin.ZW;
			
			avSize = Math.Max( float2(0), avSize );
			paddingBox = Math.Max( float2(0), paddingBox );

			var s = float2(0);
			if (element.Visibility != Visibility.Collapsed)
				s = paddingBox;

			var p = position;

			var halign = EffectiveHorizontalAlignment(element);
			if (!lp.HasX)
				halign = SimpleAlignment.Begin;
				
			var valign = EffectiveVerticalAlignment(element);
			if (!lp.HasY)
				valign = SimpleAlignment.Begin;

			p.X += margin.X;
			switch (halign)
			{
				case SimpleAlignment.Begin: break;
				case SimpleAlignment.Center: p.X += avSize.X * 0.5f; break;
				case SimpleAlignment.End: p.X += avSize.X; break;
			}

			p.Y += margin.Y;
			switch (valign)
			{
				case SimpleAlignment.Begin: break;
				case SimpleAlignment.Center: p.Y += avSize.Y * 0.5f; break;
				case SimpleAlignment.End: p.Y += avSize.Y; break;
			}

			//apply offsetting, x,y
			bool ignore;
			if (element.HasBit(FastProperty1.Offset))
			{
				var offset = element.Offset;

				var o = float2(
					UnitSize( element, offset.X, avSize.X, lp.HasX, out ignore ),
					UnitSize( element, offset.Y, avSize.Y, lp.HasY, out ignore )
					);
				p += o;
			}
			
			if (element.HasBit(FastProperty1.X))
			{
				var o = element.X;
				p.X += UnitSize( element, o, avSize.X, lp.HasX, out ignore );
			}
			
			if (element.HasBit(FastProperty1.Y))
			{
				var o = element.Y;
				p.Y += UnitSize( element, o, avSize.Y, lp.HasY, out ignore );
			}

			//apply anchoring
			Size2 anchor;
			EffectiveAnchor( element, halign, valign, out anchor );
			element.ActualAnchor = float2( UnitSize( element, anchor.X, s.X, true, out ignore ),
				UnitSize( element, anchor.Y, s.Y , true, out ignore ) );
			p -= element.ActualAnchor;

			BoxPlacement bp;
			bp.MarginBox = marginBox;
			bp.Position = p;
			bp.Size = s;
			
			return bp;
		}
		
		override public float2 CalcMarginSize(Element element, LayoutParams lp)
		{
			if (element.Visibility == Visibility.Collapsed)
				return float2(0);

			var margin = float4(0);
			if (element.HasBit(FastProperty1.Margin))
			{
				margin = element.Margin;
				lp = lp.Clone();
				lp.RemoveSize(margin);
			}

			var sz = element.GetArrangePaddingSize(lp);
			sz += margin.XY + margin.ZW;
			return sz;
		}
		
		override public float2 CalcArrangePaddingSize(Element element, LayoutParams lp)
		{
			var c = GetConstraints(element, lp, 
				ImplicitMax ? ConstraintFlags.ImplicitMax : ConstraintFlags.None);
			var child = lp.CloneAndDerive();
			child.BoxConstrain(c);
			var sz = child.Size;
			
			if (!child.HasSize)
			{
				var pad = element.Padding;
				var hasPad = element.HasBit(FastProperty1.Padding);
				if (hasPad)
					child.RemoveSize(pad);
				sz = element.InternGetContentSize(child);
				sz += pad.XY + pad.ZW;
			}
			
			sz = c.PointConstrain( sz );
			
			if(element.SnapToPixels)
				sz = SnapUp(element, sz);
			
			return sz;
		}

		protected bool ImplicitMax = true;
		
		float pixelEpsilon = 0.005f;
		float2 SnapUp(Element element, float2 p)
		{
			var s = Math.Ceil(p * element.AbsoluteZoom - pixelEpsilon) / element.AbsoluteZoom;
			return s;
		}
		
		override public LayoutDependent IsContentRelativeSize(Element element)
		{
			bool ha = AlignmentHelpers.GetHorizontalAlign(element.Alignment) != Alignment.Default;
			bool w = !element.Width.IsAuto;
				
			bool va = AlignmentHelpers.GetVerticalAlign(element.Alignment) != Alignment.Default;
			bool h = !element.Height.IsAuto;
				
			if (w && h)
				return LayoutDependent.No;
				
			if (ha || va)
				return LayoutDependent.Yes;
				
			return LayoutDependent.Maybe;
		}
	}
	
	class NoImplicitMaxBoxSizing : StandardBoxSizing
	{
		static public new NoImplicitMaxBoxSizing Singleton = new NoImplicitMaxBoxSizing();
		
		public NoImplicitMaxBoxSizing()
		{
			ImplicitMax = false;
		}
	}
}