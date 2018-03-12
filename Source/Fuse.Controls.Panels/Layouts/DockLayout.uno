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

		internal override float2 GetContentSize(Visual container, LayoutParams lp)
		{
			var nlp = lp.CloneAndDerive();
			nlp.SetRelativeSize(lp.Size,lp.HasX,lp.HasY);
			return MeasureSubtree(container, container.FirstChild<Node>(), nlp);
		}

		//LayoutParams is mutated (not relevant if a struct)
		float2 MeasureSubtree(Visual container, Node child, LayoutParams lp)
		{
			Visual c = child as Visual;
			if (child == null)
			{
				//max size of all fill children
				var mx = float2(0);
				for (c = container.FirstChild<Visual>(); c != null; c = c.NextSibling<Visual>())
				{
					if (!AffectsLayout(c)) continue;

					if (GetDock(c) == Dock.Fill)
					{
						var sz = c.GetMarginSize(lp);
						mx = Math.Max( sz, mx );
					}
				}
				return mx;
			}

			if (c == null) return MeasureSubtree(container, child.NextSibling<Node>(), lp);

			switch (GetDock(c))
			{
				case Dock.Left:
				case Dock.Right:
				{
					var nlp = lp.Clone();
					nlp.RetainXY(false, nlp.HasY);
					var cds = c.GetMarginSize( nlp );
					
					lp.RemoveSize(float2(cds.X,0));
					var subtree = MeasureSubtree(container, child.NextSibling<Node>(), lp);
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
					var subtree = MeasureSubtree(container, child.NextSibling<Node>(), lp);
					return float2(Math.Max(cds.X, subtree.X), 
						cds.Y + subtree.Y);
				}

				case Dock.Fill:
					return MeasureSubtree(container, child.NextSibling<Node>(), lp);
			}
			
			return float2(0);
		}

		internal override void ArrangePaddingBox(Visual container, float4 padding, 
			LayoutParams lp)
		{
			var availablePosition = padding.XY;
			var availableSize = lp.Size - padding.XY - padding.ZW;

			var nlp = lp.CloneAndDerive();
			nlp.SetRelativeSize(lp.Size,lp.HasX,lp.HasY);
			
			for (var c = container.FirstChild<Visual>(); c != null; c = c.NextSibling<Visual>())
			{
				if (ArrangeMarginBoxSpecial(c, padding, lp))
					continue;

				var d = GetDock(c);
				var horz =  d== Dock.Left || d == Dock.Right;
				nlp.SetSize(availableSize,!horz,horz);
				var desiredSize = d != Dock.Fill ? c.GetMarginSize( nlp ) : float2(0);

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
			for (var c = container.FirstChild<Visual>(); c != null; c = c.NextSibling<Visual>())
			{
				if (!AffectsLayout(c)) continue;
				
				if (GetDock(c) != Dock.Fill)
					continue;
				c.ArrangeMarginBox(availablePosition, nlp);
			}

		}

	}

}