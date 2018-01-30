using Uno;
using Uno.UX;

namespace Fuse
{
	/** 
		Transforms are used to move, rotate, scale and skew elements beyond their assigned placement by the Fuse layout engine.

		@topic Transforms
		
		Transforms are added to elements just like other elements and triggers.

		# Example
		In this example, we scale a circle to become three times its original size:

			<Circle Color="Green" Width="50" Height="50">
				<Scaling Factor="3" />
			</Circle>

		## Available transforms
		[subclass Fuse.Transform]

		@remarks Docs/TransformsRemarks.md
	*/
	public abstract class Transform: Node
	{
		public abstract void PrependTo(FastMatrix matrix);
		public abstract void AppendTo(FastMatrix matrix, float weight = 1);
		
		internal event Action<Transform> MatrixChanged;

		protected void OnMatrixChanged(object igoreSender = null, object ignoreArgs = null)
		{
			if (MatrixChanged != null)
				MatrixChanged(this);
		}
		
		/** Whether this tranform keeps the object strictly in the XY-plane. 
			This property is used for optimization and must be computed correctly
			in derived classes.
		*/
		public abstract bool IsFlat { get; }
	}

	/**
		Rotates the element by the degrees specified.

		# Example
		The following example rotates a rectangle 45 degrees

			<Rectangle Width="100" Height="50">
				<Rotation Degrees="90"/>
			</Rectangle>

		For animated rotations, consider using a @Rotate animator instead of animating
		the properties of this class.

	*/
	public sealed class Rotation: Transform
	{
		const float _zeroTolerance = 1e-05f;

		float3 _euler;
		/** The rotation in radians for each axis. */
		public float3 EulerAngle
		{
			get { return _euler; }
			set 
			{
				if (_euler != value)
				{
					_euler = value;
					OnMatrixChanged();
				}
			}
		}
		
		/** The rotation in degrees for each axis. */
		public float3 EulerAngleDegrees
		{
			get { return Math.RadiansToDegrees(_euler); }
			set 
			{
				var r = Math.DegreesToRadians(value);
				if (_euler != r)
				{
					_euler = r;
					OnMatrixChanged();
				}
			}
		}
		
		/** The rotation in degrees.
			This controls the rotation on Z-axis, i.e. the only meaningful axis of rotation
			for 2D graphics. Same as @DegreesZ.
		*/
		public float Degrees
		{
			get { return DegreesZ; }
			set { DegreesZ = value; }
		}
		
		/** The rotation in radians.
			This controls the rotation on Z-axis, i.e. the only meaningful axis of rotation
			for 2D graphics. Same as @AngleZ.
		*/
		public float Angle
		{
			get { return AngleZ; }
			set { AngleZ = value; }
		}

		/** The rotation in degrees on the Z-axis.
			Same as @Degrees.
		*/
		public float DegreesZ
		{
			get { return Math.RadiansToDegrees(_euler.Z); }
			set { AngleZ = Math.DegreesToRadians(value); }
		}
		
		public float AngleZ
		{
			get { return _euler.Z; }
			set
			{
				if (_euler.Z != value)
				{
					_euler.Z = value;
					OnMatrixChanged();
				}
			}
		}
		
		/** The rotation in degrees on the Y-axis.
			This is mainly used for 3D rotation. For a rotation in the 2D plane, use @Degrees.
		*/
		public float DegreesY
		{
			get { return Math.RadiansToDegrees(_euler.Y); }
			set { AngleY = Math.DegreesToRadians(value); }
		}

		public float AngleY
		{
			get {return _euler.Y; }
			set
			{
				if (_euler.Y != value)
				{
					_euler.Y = value;
					OnMatrixChanged();
				}
			}
		}
		
		public float DegreesX
		{
			get { return Math.RadiansToDegrees(_euler.X); }
			set { AngleX = Math.DegreesToRadians(value); }
		}
		
		public float AngleX
		{
			get { return _euler.X; }
			set
			{
				if (_euler.X != value)
				{
					_euler.X = value;
					OnMatrixChanged();
				}
			}
		}
		
		bool HasRotation
		{
			get 
			{
				return Math.Abs(_euler.X) + Math.Abs(_euler.Y) + Math.Abs(_euler.Z)
					> _zeroTolerance;
			}
		}
		
		public override void AppendTo(FastMatrix m, float weight)
		{
			if (HasRotation)
				m.AppendRotationQuaternion( Quaternion.FromEulerAngle(_euler*weight) );
		}

		public override void PrependTo(FastMatrix m)
		{
			if (HasRotation)
				m.PrependRotationQuaternion( Quaternion.FromEulerAngle(_euler) );
		}
		
		public override bool IsFlat 
		{ 
			get { return Math.Abs(_euler.X) < _zeroTolerance
				&& Math.Abs(_euler.Y) < _zeroTolerance; }
		}
	}

	/**
		Applies a shear to the visual (skews it). If you wish to animate the shear use a @Skew animator instead.
		
		A shear is 2D, applying to only the X, and Y axes.
	*/
	public sealed class Shear: Transform
	{
		float2 _vector; //in radians
		/** The amount of shear in each axes. This is an angle measurement, in radians, from the axis. */
		public float2 Vector
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
		
		/** Shortcut to `Degrees.X` */
		public float DegreesX 
		{ 
			get { return _vector.X; }
			set 
			{ 
				var r = Math.DegreesToRadians(value);
				if (_vector.X != r)
				{
					_vector.X = r;
					OnMatrixChanged();
				}
			}
		}

		/** Shortcut to `Degrees.Y` */
		public float DegreesY 
		{ 
			get { return _vector.Y; }
			set 
			{ 
				var r = Math.DegreesToRadians(value);
				if (_vector.Y != r)
				{
					_vector.Y = r;
					OnMatrixChanged();
				}
			}
		}

		/** Specifies the amount of shear in degrees. @See `Vector` */
		public float2 Degrees
		{
			get { return float2(DegreesX, DegreesY); }
			set
			{
				Vector = float2(Math.DegreesToRadians(value.X),
					Math.DegreesToRadians(value.Y));
			}
		}
		
		public override void AppendTo(FastMatrix m, float weight)
		{
			var v = Vector * weight;
			m.AppendShear(v.X, v.Y);
		}

		public override void PrependTo(FastMatrix m)
		{
			var v = Vector;
			m.PrependShear(v.X,v.Y);
		}
		
		public override bool IsFlat 
		{ 
			get { return true; }
		}
	}

	public interface ITransformRelative
	{
		Visual Target { get; }
		Visual RelativeNode { get; }
		void OnTransformChanged(object ignoredSender, object ignoredArgs);
	}
	
	/**
		A singleton interface that calculates the transform.
	*/
	public interface ITransformMode
	{
		/**
			Perform the event subscriptions necessary to support this transform. Changes should invoke
			Transform.OnMatrixChanged.
			
			The transform will be rooted when this is called.
			
			You don't need to subscribe to changes on the `Transform` properties, those are all implicitly handled.
			
			@return An object that contains subscription information that can be used by `Unsubscribe`
				to remove the subscriptions. `null` can be returned in which case `Unsubscribe` *may* not
				be called.
				
				The use of an opaque return value is an optimization for the most common situations
				in fuselibs: either no subscription, or a subscription to a single existing object.
		*/
		object Subscribe(ITransformRelative transform);
		
		/**
			Unsubscribe from the events subscribed via `Subscribe`. Do not rely on properties of
			the `Transform` being the same as when `Subscribe` was called, make use of the returned
			object.
		*/
		void Unsubscribe(ITransformRelative transform, object sub);
	}
	
	/**
		A common base that provides for translation relative to other nodes.
	*/
	public abstract class RelativeTransform<TransformMode> : Transform, ITransformRelative
		where TransformMode : ITransformMode
	{
		Visual _relativeNode;
		public Visual RelativeNode
		{
			get { return _relativeNode ?? Parent; }
			set
			{
				if (_relativeNode == value)
					return;

				_relativeNode = value;
				CheckSubscription(false);
			}
		}
		
		TransformMode _relativeTo;
		public TransformMode RelativeTo
		{
			get { return _relativeTo; }
			set
			{
				if (_relativeTo == value)
					return;

				ClearSubscription(); //must do prior to RelativeTo changing
				_relativeTo = value;
				CheckSubscription(false);
			}
		}
		
		internal RelativeTransform(TransformMode defaultTransform)
		{
			_relativeTo = defaultTransform;
		}

		Visual ITransformRelative.Target { get { return Parent; } }
		Visual ITransformRelative.RelativeNode { get { return RelativeNode; } }
		void ITransformRelative.OnTransformChanged(object s, object a) { OnMatrixChanged(); }
		
		protected override void OnRooted()
		{
			base.OnRooted();
			CheckSubscription(true);
		}

		protected override void OnUnrooted()
		{
			ClearRootingCompleted();
			ClearSubscription();
			base.OnUnrooted();
		}

		void ClearSubscription()
		{
			if (_subscription != null)
			{
				//UNO: https://github.com/fusetools/uno/issues/645
				(RelativeTo as ITransformMode).Unsubscribe(this, _subscription);
				_subscription = null;
			}
		}

		Visual _waitRootingCompleted;
		void ClearRootingCompleted()
		{
			if (_waitRootingCompleted != null)
			{
				_waitRootingCompleted.RootingCompleted -= OnRootingCompleted;
				_waitRootingCompleted = null;
			}
		}		
		void OnRootingCompleted()
		{
			CheckSubscription(false);
		}
		
		object _subscription;
		void CheckSubscription(bool fromRooted)
		{
			if (!fromRooted && !IsRootingCompleted)
				return;

			if (RelativeNode != null && !RelativeNode.IsRootingStarted)
			{
				ClearRootingCompleted();
				_waitRootingCompleted = RelativeNode;
				_waitRootingCompleted.RootingCompleted += OnRootingCompleted;
				return;
			}
			
			ClearSubscription();
			//UNO: https://github.com/fusetools/uno/issues/645
			_subscription = (RelativeTo as ITransformMode).Subscribe(this);
			OnMatrixChanged();
		}
	}
	
	
}
