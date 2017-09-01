using Uno;
using Uno.UX;

namespace Fuse
{
	public interface IScalingMode : ITransformMode
	{
		float3 GetScaleVector(Scaling t);
	}
	
	public static class ScalingModes
	{
		class IdentityMode : IScalingMode
		{
			public float3 GetScaleVector(Scaling t) { return t.Vector; }
			//TODO: implement
			public object Subscribe(ITransformRelative transform) { return null; } 
			public void Unsubscribe(ITransformRelative transform, object sub) { }
		}
		
		[UXGlobalResource("Identity")] public static readonly IScalingMode Identity = new IdentityMode();
	}


	/**
		Enlarges or shrinks the element by the factor specified.

		# Example
		The following example will make the `Rectangle` twice as big as the original size:

			<Rectangle Width="100" Height="100">
				<Scaling Factor="2"/>
			</Rectangle>

		For animated scaling, consider using a @Scale animator instead of animating the properties of this class.
		
		The standard options for `RelativeTo` are:
		
		* `Identity`: The default. This treats `Factor` as a multiplier. For example, `Factor="2"` scales a Visual to twice its size
		*  `SizeFactor`: Scales relative to the target size of `RelativeNode` multiplied by `Factor`. The actual scaling is then the required amount to scale the source element to that target size.
		* `SizeChange`: Scales relative to the previous size of the visual prior to a layout change. The actual scaling is then the required amount to scale the source element to that target size.
	*/
	public sealed class Scaling: RelativeTransform<IScalingMode>
	{
		public Scaling()
			: base(ScalingModes.Identity)
		{ }

		/**
			Specifies the multiple of the target size to scale to.
			
			The default is 0. Two common use-cases are `Factor="1"`, to scale to a new target size, and `Factor="0"` to shrink to nothing.
		*/
		public float Factor
		{
			get { return _vector.X; }
			set
			{
				if (_vector != float3(value))
				{
					_vector = float3(value);
					OnMatrixChanged();
				}
			}
		}

		float3 _vector = float3(1);
		/**
			The amount to apply the size change in each dimension.
			
			The default is `float3(1)`.
		*/
		public float3 Vector
		{
			get { return _vector; }
			set
			{
				if (_vector != value)
				{
					_vector = value;
					OnMatrixChanged();
				}
			}
		}
		
		/** Shortcut to `Vector.X` */
		public float X
		{
			get { return Vector.X; }
			set { Vector = float3(value,Vector.Y,Vector.Z); }
		}
		
		/** Shortcut to `Vector.Y` */
		public float Y
		{
			get { return Vector.Y; }
			set { Vector = float3(Vector.X,value,Vector.Z); }
		}

		/** Shortcut to `Vector.Z` */
		public float Z
		{
			get { return Vector.Z; }
			set { Vector = float3(Vector.X,Vector.Y,value); }
		}
		
		float3 EffectiveVector
		{
			get
			{
				return RelativeTo.GetScaleVector(this);
			}
		}
		
		bool IsIdentity(float3 v)
		{
			const float zeroTolerance = 1e-05f;
			return Math.Abs(v.X-1) < zeroTolerance &&
				Math.Abs(v.Y-1) < zeroTolerance &&
				Math.Abs(v.Z-1) < zeroTolerance;
		}

		public override void AppendTo(FastMatrix m, float weight)
		{
			var v = EffectiveVector;
			if (!IsIdentity(v))
				m.AppendScale(Math.Lerp(float3(1),v,weight));
		}

		public override void PrependTo(FastMatrix m)
		{
			var v = EffectiveVector;
			if (!IsIdentity(v))
				m.PrependScale(v);
		}
		
		public override bool IsFlat 
		{ 
			get { return true; } //even with Z != 0 it can't add depth, thus still flat
		}
	}
}
