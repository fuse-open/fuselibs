using Uno;
using Uno.UX;
using Fuse.Scripting;

namespace Fuse
{
	/** Contains information about a new size and location for a visual element.
		
		Event handlers for the [Element.Placed](api:fuse/elements/element/placed) event will be called with
		an instance of `PlacedArgs`, containing the following fields:
		
			{
				x,      // X-coordinate of the element's new position
				y,      // Y-coordinate of the element's new position
				width,  // The new width of the element.
				height  // The new height of the element
			}

		All coordinates are in the parent node's local space, in points.
	*/
	public class PlacedArgs: EventArgs, IScriptEvent
	{
		public bool HasPrev { get; private set; }
		public float2 PrevPosition { get; private set; }
		public float2 PrevSize { get; private set; }
		public float2 NewSize { get; private set; }
		public float2 NewPosition { get; private set; }
		
		internal PlacedArgs(bool hasPrev, float2 prevPosition, float2 newPosition, 
			float2 prevSize, float2 newSize)
		{
			HasPrev = hasPrev;
			PrevPosition = prevPosition;
			PrevSize = prevSize;
			NewSize = newSize;
			NewPosition = newPosition;
		}

		public void Serialize(IEventSerializer serializer) 
		{
			serializer.AddDouble("x", NewPosition.X);
			serializer.AddDouble("y", NewPosition.Y);
			serializer.AddDouble("width", NewSize.X);
			serializer.AddDouble("height", NewSize.Y);
		}

		public object DefaultValue {
			get { return null; }
		}
	}

	public delegate void PlacedHandler(object sender, PlacedArgs args);

	public interface IActualPlacement
	{
		float3 ActualSize { get; }
		float3 ActualPosition { get; } 
		event PlacedHandler Placed;
	}

	public interface ITranslationMode : ITransformMode
	{
		float3 GetAbsVector(Translation t);
	}

	public static class TranslationModes
	{
		class LocalMode: ITranslationMode 
		{
			public float3 GetAbsVector(Translation t) { return t.Vector; }
			public object Subscribe(ITransformRelative transform) { return null; }
			public void Unsubscribe(ITransformRelative transform, object sub) { }
		}

		class SizeMode: ITranslationMode 
		{
			public virtual float3 GetAbsVector(Translation t) { return SizeOf(t.RelativeNode) * t.Vector; }
			public object Subscribe(ITransformRelative transform) 
			{ 
				var n = transform.RelativeNode as IActualPlacement;
				if (n != null)
					n.Placed += transform.OnTransformChanged;
				return transform.RelativeNode;
			}
			public void Unsubscribe(ITransformRelative transform, object sub) 
			{ 
				(sub as IActualPlacement).Placed -= transform.OnTransformChanged;
			}
		}

		class ParentSizeMode: ITranslationMode 
		{
			public float3 GetAbsVector(Translation t) { return SizeOf(t.RelativeNode.Parent) * t.Vector; }
			public object Subscribe(ITransformRelative transform) 
			{ 
				var n = transform.RelativeNode.Parent as IActualPlacement;
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

		static float3 SizeOf( Node node )
		{
			var isz = node as IActualPlacement;
			if (isz == null)
				return float3(0);
			return isz.ActualSize;
		}
		
		[UXGlobalResource("Local")] 
		/** Translates an @Visual in local units. */
		public static readonly ITranslationMode Local = new LocalMode();
		
		[UXGlobalResource("Size")] 
		/** Translates an @Element in units where 1.0 is the actual size of the element in a given dimension. */
		public static readonly ITranslationMode Size = new SizeMode();
		
		[UXGlobalResource("ParentSize")] 
		/** Translates an @Element in units where 1.0 is the actual size of the parent element in a given dimension. */
		public static readonly ITranslationMode ParentSize = new ParentSizeMode();
		
		class WidthMode: SizeMode 
		{
			public override float3 GetAbsVector(Translation t) { return SizeOf(t.RelativeNode).X * t.Vector; }
		}
		[UXGlobalResource("Width")] 
		/** Translates an @Element in units where 1.0 is the width of relative element. */
		public static readonly ITranslationMode Width = new WidthMode();
		
		class HeightMode: SizeMode 
		{
			public override float3 GetAbsVector(Translation t) { return SizeOf(t.RelativeNode).Y * t.Vector; }
		}
		[UXGlobalResource("Height")] 
		/** Translates an @Element in units where 1.0 is the height of relative element. */
		public static readonly ITranslationMode Height = new HeightMode();
	}

	/** Represents a linear offset in space. 
		For animated translation, consider using a @Move animator instead of
		animating the properties of this class.
	*/
	public sealed class Translation: RelativeTransform<ITranslationMode>
	{
		public Translation()
			: base(TranslationModes.Local)
		{ }
		
		float _x;
		/** The translation offset on the X-axis. 
			This value is in units as specified by the @RelativeTo property. Defaults
			to local units, which is equivalent to points, unless a parent node applies
			a scaling transformation.
		*/
		public float X
		{
			get { return _x; }
			set
			{
				if (_x != value)
				{
					_x = value;
					OnMatrixChanged();
				}
			}
		}
		
		/** The translation vector on the XY-plane. 
			This vector is in units as specified by the @RelativeTo property. Defaults
			to local units, which is equivalent to points, unless a parent node applies
			a scaling transformation.
		*/
		public float2 XY
		{
			get { return float2(_x,_y); }
			set 
			{
				if (_x != value.X || _y != value.Y)
				{
					_x = value.X;
					_y = value.Y;
					OnMatrixChanged();
				}
			}
		}

		float _y;
		/** The translation offset on the Y-axis. 
			This value is in units as specified by the @RelativeTo property. Defaults
			to local units, which is equivalent to points, unless a parent node applies
			a scaling transformation.
		*/
		public float Y
		{
			get { return _y; }
			set
			{
				if (_y != value)
				{
					_y = value;
					OnMatrixChanged();
				}
			}
		}

		float _z;
		/** The translation offset on the Z-axis. 
			This property is only meaningful if used with @RelativeTo set to @Local (the default).
			This is mainly used for 3D transforms. For translation in the 2D plane,
			use @X and @Y.
		*/
		public float Z
		{
			get { return _z; }
			set
			{
				if (_z != value)
				{
					_z = value;
					OnMatrixChanged();
				}
			}
		}

		/** The translation vector in 3D. 
			Setting this property is a shortcut for setting @X, @Y and @Z separately.
		*/
		public float3 Vector
		{
			get { return float3(X, Y, Z); }
			set
			{
				if (_x != value.X || _y != value.Y || _z != value.Z)
				{
					_x = value.X;
					_y = value.Y;
					_z = value.Z;
					OnMatrixChanged();
				}
			}
		}


		public override void AppendTo(FastMatrix m, float weight)
		{
			var v = RelativeTo.GetAbsVector(this) * weight;
			m.AppendTranslation(v.X, v.Y, v.Z);
		}

		public override void PrependTo(FastMatrix m)
		{
			var v = RelativeTo.GetAbsVector(this);
			m.PrependTranslation(v.X, v.Y, v.Z);
		}
		
		public override bool IsFlat 
		{ 
			get
			{
				const float zeroTolerance = 1e-05f;
				return Math.Abs(Z) < zeroTolerance;
			}
		}
	}
}
