using Uno;
using Uno.UX;

using Fuse.Animations;

namespace Fuse.Elements
{
	public static class TranslationModes
	{
		class OffsetMode : ITranslationMode
		{
			public float3 GetAbsVector(Translation t)
			{
				var n = t.RelativeNode;
				var dstElement = n as Element;
				var dst = float3(0);
				if (dstElement != null)
					dst = GetDstOffset(dstElement);
				
				if (t.Parent == null || t.Parent.Parent == null)
					return float3(0);
					
				var m = Matrix.Mul(t.RelativeNode.WorldTransform, t.Parent.Parent.WorldTransformInverse);
				var localP = Vector.Transform(dst, m).XYZ;
				
				var localOff = float3(0);
				var elm = t.Parent as Element;
				if (elm != null)
					localOff = -(float3(elm.ActualPosition,0) + GetSrcOffset(elm));
				float3 worldChange = localP + localOff;
				
				return worldChange * t.Vector;
			}
			
			class Subscriptions
			{
				public Visual Relative, TargetParent;
				public Element Target;
			}
			
			public object Subscribe(ITransformRelative transform) 
			{ 
				var s = new Subscriptions { 
					Relative = transform.RelativeNode, 
					TargetParent = transform.Target.Parent,
					Target = transform.Target as Element };
				s.Relative.WorldTransformInvalidated += transform.OnTransformChanged;
				s.TargetParent.WorldTransformInvalidated += transform.OnTransformChanged;
				if (s.Target != null)
					s.Target.Placed += transform.OnTransformChanged;
				return s;
			}
			public void Unsubscribe(ITransformRelative transform, object sub) 
			{ 
				var s = sub as Subscriptions;
				s.Relative.WorldTransformInvalidated -= transform.OnTransformChanged;
				s.TargetParent.WorldTransformInvalidated -= transform.OnTransformChanged;
				if (s.Target != null)
					s.Target.Placed -= transform.OnTransformChanged;
			}
			
			protected virtual float3 GetDstOffset(Element e) { return float3(0); }
			protected virtual float3 GetSrcOffset(Element e) { return float3(0); }
		}
		
		class PositionOffsetMode : OffsetMode
		{
		}
		
		class TransformOriginOffsetMode : OffsetMode
		{
			protected override float3 GetDstOffset(Element e)
			{
				return e.TransformOrigin.GetOffset(e);
			}
			
			protected override float3 GetSrcOffset(Element e)
			{
				return e.TransformOrigin.GetOffset(e);
			}
		}

		[UXGlobalResource("TransformOriginOffset")] 
		public static readonly ITranslationMode TransformOriginOffset = new TransformOriginOffsetMode();
		[UXGlobalResource("PositionOffset")]
		public static readonly ITranslationMode PositionOffset = new PositionOffsetMode();
		
		class SizeFactorMode : IScalingMode
		{
			public float3 GetScaleVector(Scaling t)
			{
				var dst = t.RelativeNode as Element;
				var src = t.Parent as Element;
				if (dst == null || src == null)
					return float3(1);
					
				var sz = src.ActualSize;
				const float zeroTolerance = 1e-05f;
				if (sz.X < zeroTolerance || sz.Y < zeroTolerance)
					return float3(1);
					
				var rel = float3(dst.ActualSize / sz, 1) - float3(1);
				return rel * t.Vector + float3(1);
			}
			
			public object Subscribe(ITransformRelative transform) 
			{
				var n = transform.RelativeNode as IActualPlacement;
				if (n != null)
					n.Placed += transform.OnTransformChanged;
				return n; 
			} 
			public void Unsubscribe(ITransformRelative transform, object sub) 
			{ 
				if (sub != null)
					(sub as IActualPlacement).Placed -= transform.OnTransformChanged;
			}
		}
		
		[UXGlobalResource("SizeFactor")]
		public static readonly IScalingMode SizeFactor = new SizeFactorMode();

		/**
			Change mode appropriate for a Resize between two nodes.
		*/
		class RelativeResizeChangeMode : IResizeMode
		{
			public bool GetSizeChange(Visual target, Visual relative, out float2 baseSize, out float2 deltaSize)
			{
				if (!(target is Element) || !(relative is Element))
				{
					baseSize = float2(0);
					deltaSize = float2(0);
					return false;
				}
					
				var targetSize = (target as Element).IntendedSize;
				var relativeSize = (relative as Element).ActualSize;
				deltaSize = relativeSize - targetSize;
				baseSize = targetSize;
				return true;
			}

			/*TODO: public object Subscribe(Transform transform) 
			{ 
				var  n = transform.RelativeNode
				return null; 
			}
				
			public void Unsubscribe(Transform transform, object sub) { }

			public TransformModeFlags Flags { get { return TransformModeFlags.Size; } }*/
		}
		[UXGlobalResource("Size")]
		public static readonly IResizeMode Size = new RelativeResizeChangeMode();
		
	}
}
