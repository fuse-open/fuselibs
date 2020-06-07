//not in project, just kept as a reference for now (until we find replacement)
using Uno;
using Uno.UX;

namespace Fuse.Elements
{
	public enum ElementExpressionType
	{
		ActualPosition,
		ParentPosition,
	}

	public abstract class ElementExpressionBase
	{
		public ElementExpressionType What { get; set; }

		public Element Element { get; set; }

		public float2 Anchor { get; set; }

		public Node RelativeTo { get; set; }

		public float3 Evaluate()
		{
			if (Element == null)
				return float3(0);

			var result = float3(0);

			switch (What)
			{
				case ElementExpressionType.ActualPosition:
				{
					var ap = Element.ActualPosition;
					var az = Element.ActualSize;
					result = float3(ap + az * Anchor,0);
					return result;
				}

				case ElementExpressionType.ParentPosition:
				{
					var az = Element.ActualSize;
					result = float3(az * Anchor,0);
					break;
				}
			}

			var rt = RelativeTo ?? Element.Parent;
			if (rt != null)
			{
				var mat = Element.GetTransformTo(rt);
				result = Vector.Transform(result, mat).XYZ;
			}

			return result;
		}
	}

	public sealed class ElementExpression : ElementExpressionBase, IExpression<float3>
	{}

	public sealed class ElementExpressionXY : ElementExpressionBase, IExpression<float2>
	{
		public float2 IExpression<float2>.Evaluate()
		{
			return Evaluate().XY;
		}
	}
}
