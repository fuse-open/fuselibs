using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse;
using Fuse.Controls;
using Fuse.Elements;

namespace Fuse.Layouts
{

	public enum Dock
	{
		Left, Right, Top, Bottom, Fill
	}

	public sealed class DockLayout : Layout
	{

		static readonly PropertyHandle _dockProperty = Fuse.Properties.CreateHandle();

		public static void SetDock(Visual elm, Dock dock)
		{
			elm.Properties.Set(_dockProperty, dock);
			elm.InvalidateLayout();
		}

		public static Dock GetDock(Visual elm)
		{
			object val;
			if (elm.Properties.TryGet(_dockProperty, out val))
			{
				return (Dock)val;
			}
			return Dock.Fill;
		}

		public static void ResetDock(Visual elm)
		{
			elm.Properties.Clear(_dockProperty);
			elm.InvalidateLayout();
		}

		internal override float2 GetContentSize(Visual elements, LayoutParams lp)
		{
			var nlp = lp.CloneAndDerive();
			nlp.SetRelativeSize(lp.Size,lp.HasX,lp.HasY);
			return MeasureSubtree(elements, elements.Children_first, nlp);
		}

		//LayoutParams is mutated (not relevant if a struct)
		float2 MeasureSubtree(Visual elements, Node child, LayoutParams lp)
		{
			Visual c = child as Visual;
			if (child == null)
			{
				//max size of all fill children
				var mx = float2(0);
				for (var cn = elements.Children_first; cn != null; cn = cn.Children_next)
				{
					c = cn as Visual;
					if (!AffectsLayout(c)) continue;

					if (GetDock(c) == Dock.Fill)
					{
						var sz = c.GetMarginSize(lp);
						mx = Math.Max( sz, mx );
					}
				}
				return mx;
			}

			if (c == null) return MeasureSubtree(elements, child.Children_next, lp);

			switch (GetDock(c))
			{
				case Dock.Left:
				case Dock.Right:
				{
					var nlp = lp.Clone();
					nlp.RetainXY(false, nlp.HasY);
					var cds = c.GetMarginSize( nlp );
					
					lp.RemoveSize(float2(cds.X,0));
					var subtree = MeasureSubtree(elements, child.Children_next, lp);
					return float2(cds.X + subtree.X, 
						Math.Max(cds.Y, subtree.Y));
				}

				case Dock.Top:
				case Dock.Bottom:
				{
					var nlp = lp.Clone();
					nlp.RetainXY(nlp.HasX, false);
					var cds = c.GetMarginSize( nlp );
					
					lp.RemoveSize(float2(0,cds.Y));
					var subtree = MeasureSubtree(elements, child.Children_next, lp);
					return float2(Math.Max(cds.X, subtree.X), 
						cds.Y + subtree.Y);
				}

				case Dock.Fill:
					return MeasureSubtree(elements, child.Children_next, lp);
			}
			
			return float2(0);
		}

		internal override void ArrangePaddingBox(Visual elements, float4 padding, 
			LayoutParams lp)
		{
			var availablePosition = padding.XY;
			var availableSize = lp.Size - padding.XY - padding.ZW;

			var nlp = lp.CloneAndDerive();
			nlp.SetRelativeSize(lp.Size,lp.HasX,lp.HasY);
			
			for (var cn = elements.Children_first; cn != null; cn = cn.Children_next)
			{
				var c = cn as Visual;
				if (c == null) continue;
				if (ArrangeMarginBoxSpecial(c, padding, lp))
					continue;

				var d = GetDock(c);
				var horz =  d== Dock.Left || d == Dock.Right;
				nlp.SetSize(availableSize,!horz,horz);
				var desiredSize = c.GetMarginSize( nlp );

				switch (d)
				{
					case Dock.Left:
						desiredSize.Y = availableSize.Y;
						nlp.SetSize(desiredSize);
						c.ArrangeMarginBox(availablePosition, nlp);
						availablePosition.X += desiredSize.X;
						availableSize.X -= desiredSize.X;
						break;

					case Dock.Right:
						desiredSize.Y = availableSize.Y;
						nlp.SetSize(desiredSize);
						c.ArrangeMarginBox(float2(availablePosition.X+availableSize.X-desiredSize.X, availablePosition.Y),
							nlp);
						availableSize.X -= desiredSize.X;
						break;

					case Dock.Top:
						desiredSize.X = availableSize.X;
						nlp.SetSize(desiredSize);
						c.ArrangeMarginBox(availablePosition, nlp);
						availablePosition.Y += desiredSize.Y;
						availableSize.Y -= desiredSize.Y;
						break;

					case Dock.Bottom:
						desiredSize.X = availableSize.X;
						nlp.SetSize(desiredSize);
						c.ArrangeMarginBox(float2(availablePosition.X, availablePosition.Y+availableSize.Y-desiredSize.Y),
							nlp);
						availableSize.Y -= desiredSize.Y;
						break;
						
					case Dock.Fill:
						break;
				}
				
				availableSize = Math.Max(availableSize, float2(0));
			}
			
			nlp.SetSize(availableSize);
			for (var cn = elements.Children_first; cn != null; cn = cn.Children_next)
			{
				var c = cn as Visual;
				if (!AffectsLayout(c)) continue;
				
				if (GetDock(c) != Dock.Fill)
					continue;
				c.ArrangeMarginBox(availablePosition, nlp);
			}

		}

	}

}