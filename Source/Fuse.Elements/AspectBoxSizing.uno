using Uno;
using Uno.UX;

namespace Fuse.Elements
{
	[Flags]
	public enum AspectConstraint
	{
		/** The min/max layout constraints are ignored and the preferred aspect correct size is used */
		None = 0,
		/** The size will be adjusted to fit first within the maximum, then to meet the minimum size requirements. The aspect ratio is preserved. */
		Preserve = 1 << 0,
		/** The size is trimmed, or expanded, to meet the minimum/maximum layout constraints. The desired aspect ratio is not preserved. */
		Trim = 1 << 1,
		/** Applies the Preserve and then Trim rules. This is the default. */
		PreserveTrim = Preserve | Trim,
	}
	
	internal sealed class FillAspectBoxSizing : BoxSizing
	{
		static public FillAspectBoxSizing Singleton = new FillAspectBoxSizing();
		
		override public BoxPlacement CalcBoxPlacement(Element element, float2 position, LayoutParams lp)
		{
			return StandardBoxSizing.Singleton.CalcBoxPlacement(element, position, lp);
		}
		
		override public float2 CalcMarginSize(Element element, LayoutParams lp)
		{
			return StandardBoxSizing.Singleton.CalcMarginSize(element, lp);
		}
		
		override public float2 CalcArrangePaddingSize(Element element, LayoutParams lp)
		{	
			var cs = GetConstraints( element, lp, ConstraintFlags.ImplicitMax );
			var c = lp.CloneAndDerive();
			c.BoxConstrain(cs);
			
			var aspect = element.Aspect;
			
			var sz = float2(0);
			if (c.HasSize)
				sz = Pick(c.Size,aspect);
			else if(c.HasX)
				sz = float2(c.X, c.X / aspect);
			else if(c.HasY)
				sz = float2(c.Y * aspect, c.Y);
			
			var ac = element.AspectConstraint;
			
			if (ac.HasFlag(AspectConstraint.Preserve))
			{
				if (c.HasMaxSize)
					sz = Fit(sz, c.MaxSize, aspect);
				else if (c.HasMaxX)
					sz = Fit(sz, float2(c.MaxX,sz.Y), aspect);
				else if (c.HasMaxY)
					sz = Fit(sz, float2(sz.X, c.MaxY), aspect);
					
				if (c.HasMinX && sz.X < c.MinX)
					sz = float2(c.MinX, c.MinX / aspect);
				if (c.HasMinY && sz.Y < c.MinY)
					sz = float2(c.MinY * aspect, c.MinY);
			}

			if (ac.HasFlag(AspectConstraint.Trim))
			{
				//then just hard constraints (aspect breaking), matching that in StandardBoxSizing
				if (c.HasMaxX && sz.X > c.MaxX)
					sz.X = c.MaxX;
				if (c.HasMinX && sz.X < c.MinX)
					sz.X = c.MinX;
				if (c.HasMaxY && sz.Y > c.MaxY)
					sz.Y = c.MaxY;
				if (c.HasMinY && sz.Y < c.MinY)
					sz.Y = c.MinY;
			}

			return sz;
		}
		
		float2 Pick(float2 sz, float aspect)
		{
			var y = sz.X / aspect;
			if (y <= sz.Y)
				return float2(sz.X, y);
				
			return float2(sz.Y * aspect, sz.Y);
		}
		
		float2 Fit(float2 sz, float2 max, float aspect)
		{
			if (sz.X <= max.X && sz.Y <= max.Y)
				return sz;
				
			if (sz.X > max.X)	
				return float2(max.X, max.X / aspect);
			return float2(max.Y * aspect, max.Y);
		}
	}
	
	public partial class Element
	{
		public const float DefaultAspect = 1;

		/**
			The aspect ratio that an element must fulfill in layout.
			
			This is the X:Y ratio. `2` is twice as wide as tall and `0.5` is half as wide as tall.
			
			@remarks Docs/BoxSizing.md
		*/
		public float Aspect
		{
			get { return Get(FastProperty1.Aspect, DefaultAspect); }
			set 
			{ 
				if (Aspect != value)
				{
					Set(FastProperty1.Aspect, value, DefaultAspect);
					InvalidateLayout();
				}
			}
		}

		public const AspectConstraint DefaultAspectConstraint = AspectConstraint.PreserveTrim;
		
		/**
			Determines how the aspect ratio is maintained in a situation when it violates the min or max sizing constraints.
			
			@remarks Docs/BoxSizing.md
		*/
		public AspectConstraint AspectConstraint
		{
			get { return Get(FastProperty1.AspectConstraint, DefaultAspectConstraint); }
			set 
			{ 
				if (AspectConstraint != value)
				{
					Set(FastProperty1.AspectConstraint, value, DefaultAspectConstraint); 
					InvalidateLayout();
				}
			}
		}
	}
}