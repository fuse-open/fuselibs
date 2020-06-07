using Uno;
using Uno.UX;

using Uno.Matrix;

namespace Fuse.Elements
{
	public interface ITransformOrigin
	{
		float3 GetOffset(Element elm);
	}

	class ExplicitTransformOrigin : ITransformOrigin
	{
		/* No change response is needed since this is private to the property on Element, which handles invalidation */
		public Size2 Origin;

		float SizePart( Size sz, float relative, float pixelsPerPoint )
		{
			var u = sz.DetermineUnit();

			switch (u)
			{
				case Unit.Points:
					return sz.Value;

				case Unit.Pixels:
					return sz.Value / pixelsPerPoint;

				case Unit.Percent:
					return sz.Value * relative / 100;
			}

			return 0;
		}

		public float3 GetOffset(Element elm)
		{
			var pixelsPerPoint = elm.Viewport.PixelsPerPoint;

			return float3( SizePart(Origin.X, elm.ActualSize.X, pixelsPerPoint),
				SizePart(Origin.Y, elm.ActualSize.Y, pixelsPerPoint), 0 );
		}
	}

	public static class TransformOrigins
	{
		class TopLeftOrigin : ITransformOrigin
		{
			public float3 GetOffset(Element elm) { return float3(0); }
		}

		class CenterOrigin : ITransformOrigin
		{
			public float3 GetOffset(Element elm) { return float3(elm.ActualSize/2,0); }
		}

		class AnchorOrigin : ITransformOrigin
		{
			public float3 GetOffset(Element elm) { return float3(elm.ActualAnchor,0); }
		}

		class BoxCenter : ITransformOrigin
		{
			public float2 Depth;

			public float3 GetOffset(Element elm)
			{
				var depth = Vector.Dot(Depth, elm.ActualSize);
				var q =float3(elm.ActualSize/2, depth/2);
				return q;
			}
		}

		[UXGlobalResource("TopLeft")]
		public static readonly ITransformOrigin TopLeft = new TopLeftOrigin();

		[UXGlobalResource("Center")]
		public static readonly ITransformOrigin Center = new CenterOrigin();

		[UXGlobalResource("Anchor")]
		public static readonly ITransformOrigin Anchor = new AnchorOrigin();

		[UXGlobalResource("HorizontalBoxCenter")]
		public static readonly ITransformOrigin HorizontalBoxCenter =
			new BoxCenter{ Depth=float2(0,1) };
		[UXGlobalResource("VerticalBoxCenter")]
		public static readonly ITransformOrigin VerticalBoxCenter =
			new BoxCenter{ Depth=float2(1,0) };
	}

	public abstract partial class Element
	{
		public static readonly ITransformOrigin DefaultTransformOrigin = TransformOrigins.Center;

		/** Specifies the origin of transformation used by transformation behaviors and animators such as @Move, @Scale, @Rotation, @Scaling, etc.

			The possible values are:

			 * `Center` (default) Transforms originate at the center of the element.
			 * `TopLeft` Transforms originate at the top left corner of the element.
			 * `Anchor` Transforms originate around the point specified by the @Element.Anchor property.
			 * `HorizontalBoxCenter` Simulates the effect of the element being the front-facing side of a cube in 3D space, using the width of the element for determining the depth of the cube. Without the element being in a @Viewport this will have no illusion of depth, effectively rendering it useless.
			 * `VerticalBoxCenter` Like `HorizontalBoxCenter` except it uses the height of the element for determining depth.
		*/
		public ITransformOrigin TransformOrigin
		{
			get { return Get(FastProperty1.TransformOrigin, DefaultTransformOrigin); }
			set
			{
				if (TransformOrigin != value)
				{
					Set(FastProperty1.TransformOrigin, value, DefaultTransformOrigin);
					InvalidateLocalTransform();
				}
			}
		}

		static public Selector ExplicitTransformOriginName = "ExplicitTransformOrigin";

		[UXOriginSetter("SetExplicitTransformOrigin")]
		public Size2 ExplicitTransformOrigin
		{
			get
			{
				var to = TransformOrigin as ExplicitTransformOrigin;
				if (to != null)
					return to.Origin;
				return new Size2();
			}
			set { SetExplicitTransformOrigin(value, this); }
		}

		public void SetExplicitTransformOrigin(Size2 value, IPropertyListener origin)
		{
			var to = TransformOrigin as ExplicitTransformOrigin;
			if (to == null)
			{
				to = new ExplicitTransformOrigin();
				to.Origin = value;
				TransformOrigin = to;
			}
			else
			{
				if (to.Origin == value)
					return;

				to.Origin = value;
				InvalidateLocalTransform();
			}

			OnPropertyChanged(ExplicitTransformOriginName, origin);
		}

		static void InvalidateLocalTransform(Element elm)
		{
			elm.InvalidateLocalTransform();
		}


		public override Box LocalBounds
		{
			get
			{
				return new Box(float3(0), float3(ActualSize, 0));
			}
		}

		protected override void PrependTransformOrigin(FastMatrix m)
		{
			var off = TransformOrigin.GetOffset(this);
			m.PrependTranslation(off);
		}

		protected override void PrependInverseTransformOrigin(FastMatrix m)
		{
			var off = TransformOrigin.GetOffset(this);
			m.PrependTranslation(-off);
		}

		protected override void PrependImplicitTransform(FastMatrix m)
		{
			var actualPosition = ActualPosition;
			if (actualPosition.X != 0 || actualPosition.Y != 0)
			{
				m.PrependTranslation(float3(actualPosition.XY, 0));
			}
		}

		protected override void InvalidateLocalTransform()
		{
			InvalidateVisualComposition();
			var p = AncestorElement;
			if (p != null)
				p.InvalidateRenderBounds();

			if (ElementBatchEntry != null)
				ElementBatchEntry.InvalidateTransform();

			base.InvalidateLocalTransform();

			NotifyTreeRendererTransformChanged();
		}

	}
}
