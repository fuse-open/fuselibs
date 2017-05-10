using Uno;

namespace Fuse.Animations
{
	enum TransformPriority
	{
		Shear = 4000,
		Rotate = 3000,
		Scale = 2000,
		Translate = 1000,
	}
	
	/** Transform animators animate the translation, rotation or scaling of a visual.

		@topic Transform animators

		Transform animators do not affect the layout of an @Element, instead it animates relative to
		the result of layout. This means transform animators are very fast and are appropriate for
		real-time transitions.

		## Available transform animators

		[subclass Fuse.Animations.TransformAnimator]
	*/
	public abstract class TransformAnimator<TransformType> : TrackAnimator
		where TransformType : Transform, new()
	{
		internal TransformAnimator()
		{
			MixOp = MixOp.Add;
		}

		/** The animation amount on the X-axis. 

			The animation amount can also be set using the `Vector` property, and other properties in different
			subclasses.
			
			This property has different defaults, means different things in different subclasses:
			
			* For @Move, this property denotes points, unless distorted by scaling. Default is 0.
			* For @Rotate, this property denotes radians. Default is 0.
			* For @Scale, this property denotes a scale factor, where 1 is unchanged scale. Default is 1.
		*/
		public float X
		{
			get { return _vectorValue.X; }
			set { _vectorValue.X = value; }
		}
		
		/** The animation amount on the Y-axis. 

			The animation amount can also be set using the `Vector` property, and other properties in different
			subclasses.
			
			This property has different defaults, means different things in different subclasses:
			
			* For @Move, this property denotes points, unless distorted by scaling. Default is 0.
			* For @Rotate, this property denotes radians. Default is 0.
			* For @Scale, this property denotes a scale factor, where 1 is unchanged scale. Default is 1.
		*/
		public float Y
		{
			get { return _vectorValue.Y; }
			set { _vectorValue.Y = value; }
		}
		
		/** The animation amount on the Z-axis. 

			The animation amount can also be set using the `Vector` property, and other properties in different
			subclasses.
			
			This property has different defaults, means different things in different subclasses:
			
			* For @Move, this property denotes points, unless distorted by scaling. Default is 0.
			* For @Rotate, this property denotes radians. Default is 0.
			* For @Scale, this property denotes a scale factor, where 1 is unchanged scale. Default is 1.
		*/
		public float Z
		{
			get { return _vectorValue.Z; }
			set { _vectorValue.Z = value; }
		}

		/** The animation amount in the 3 different dimensions.

			The animation amount can also be set using the `X`, `Y` and `Z` properties, and other properties in different
			subclasses.
			
			This property has different defaults, means different things in different subclasses:
			
			* For @Move, this property denotes points, unless distorted by scaling. Default is 0,0,0.
			* For @Rotate, this property denotes radians. Default is 0,0,0.
			* For @Scale, this property denotes a scale factor, where 1,1,1 is unchanged scale. Default is 1,1,1.
		*/
		public float3 Vector
		{
			get { return _vectorValue.XYZ; }
			set { _vectorValue = float4(value, _vectorValue.W); }
		}

		/** Lets you move an element relative to another by specifyig a @Visual to which this transform is relative. 

			If this proeprty is set you may use the following `RelativeTo` modes:

			* `Size`: Works the same way it would without `RelativeNode`, but measures the size of the `RelativeNode` instead.
			* `ParentSize`: Same as `Size` but measures the `RelativeNode`'s parent size instead.
			* `PositionOffset`: Moves the element to be in the same position as the element specified by `RelativeNode`.
			  The offset is measured as the difference in `ActualPosition` between the two elements.
			  Note that because `X`, `Y` and `Vector` will be interpreted as a factor, you need to specify `X="1" Y="1"` or `Vector="1"` for anything to actually happen.
			* `TransformOriginOffset`: Works like `PositionOffset`, but instead measures the difference in `TransformOrigin`.
		*/
		public Visual RelativeNode 
		{ 
			get;
			set;
		}

		/** The visual that should be animated. If not set, the containing visual is animated by default. */
		public Visual Target { get; set; }
		
		/** When multiple transforms are applied they are applied in a priority order. This setting allows you to override the default priority to get a new order. */
		public int Priority { get; set; }
		
		internal abstract void Update(Visual elm, TransformType transform, float4 value);
		
		internal override AnimatorState CreateState(CreateStateParams p) 
		{ 
			return new TransformAnimatorState<TransformType>(this, p);
		}
	}
	
	class TransformAnimatorState<TransformType> : TrackAnimatorState
		where TransformType : Transform, new()
	{
		new TransformAnimator<TransformType> Animator;
		IMixerHandle<Transform> mixHandle;
		internal TransformType transform = new TransformType();
		Uno.Action<Transform> _matAct;
		
		public TransformAnimatorState( TransformAnimator<TransformType> animator, 
			CreateStateParams p )
			: base(animator, p, animator.Target)
		{ 
			this.Animator = animator;
			mixHandle = Animator.Mixer.RegisterTransform(Visual, Animator.MixOp, Animator.Priority);
			
			//Workaround for https://github.com/fusetools/Uno/issues/50
			_matAct = OnMatrixChanged;
			(transform as Transform).MatrixChanged += _matAct;
			Node.Relate(Visual, (Transform)transform);
		}
		
		public override void Disable()
		{
			if (mixHandle == null)
				return;
			mixHandle.Unregister();
			mixHandle = null;
			(transform as Transform).MatrixChanged -= _matAct;
			Node.Unrelate(Visual, (Transform)transform);
			_matAct = null;
			transform = null;
		}
		
		float _lastStrength;
		bool _inSeek;
		protected override void SeekValue(float4 value, float strength)
		{
			if (mixHandle == null || transform == null)
			{
				debug_log "Invalid seek";
				return;
			}
			
			//to distinguish our changes from event ones
			_inSeek = true;
			Animator.Update( Visual, transform, value );
			_lastStrength = strength;
			mixHandle.Set( transform, _lastStrength );
			_inSeek = false;
		}
		
		//this is needed since for size relative transforms the size may change yet there be
		//no change in animator progress
		internal void OnMatrixChanged(Transform ignore)
		{
			if (!_inSeek && mixHandle != null && transform != null)
				mixHandle.Set( transform, _lastStrength );
		}
	}

	/** Animates the translation a visual element.

		`Move` does not affect layout, so the element will just get an offset from its actual location.

		Example:
			
			<WhilePressed>
				<Move X="50" Duration="1" Easing="BackOut" />
			</WhilePressed>

		When pressed, this will move the element by 50 points in the X direction over 1 second, with
		a back-out easing curve.

		## Relative motion

		You may want for an element to move relative to its own size or some other elements size.
		To achieve this we can use the @RelativeTo property, for instance:

			<Move X="0.5" RelativeTo="Size" />

		The above line moves the element by 50% of its own size to the right.
	*/
	public sealed class Move: TransformAnimator<Translation>
	{
		public Move()
		{
			Priority = (int)TransformPriority.Translate;
		}
		
		ITranslationMode _relativeTo = TranslationModes.Local;
		/** Specifies what the movement should be relative to.

			By default, when we specify `X` and `Y` offsets the @Move animator for example, the values are
			understood to be points in the local coordinate system. However, sometimes we need to
			specify a distance that are not known at design time, but is relative to the size of something else.
			This is where this property comes in handy.

			There are multiple options for this property:
			
			 * `Local` Moves the given amount of points in the X and/or Y direction.
			 * `Size` Moves the given amount times the size of the element. So X="1" moves the element by its entire width in the X direction.
			 * `ParentSize` Same as `Size` but uses the elements parents size instead.
			 * `PositionChange` Used in response to a @(LayoutAnimation) to move the element by the amount of change in position within it's parent.
			 * `WorldPositionChange` Used in response to a @(LayoutAnimation) to move the element by the amount of change in position relative to the entire display.
			 * `Keyboard` Moves the element relative to the size of the keyboard.
			 * `LayoutChange` Deprecated. Use `PositionChange` instead.

			For advanced use cases, you can also implement your own @ITranslationMode and assign to this property.
		*/
		public ITranslationMode RelativeTo 
		{ 
			get { return _relativeTo; }
			set { _relativeTo = value; }
		}

		internal override void Update(Visual elm, Translation t, float4 value)
		{
			t.RelativeNode = RelativeNode ?? elm;
			t.RelativeTo = RelativeTo;
			t.Vector = value.XYZ;
		}
	}

	/**
		Rotates the Visual. This does the same transform as @Rotation.

		The standard units for angle are radians. Use the `Degrees...` properties to specify in degrees.

		# Example
		This example rotates a panel while the mouse pointer hovers over it

			<Panel>
				<WhileHovering>
					<Rotate Degrees="90" Duration="0.5"/>
				</WhileHovering>
			</Panel>
	*/
	public sealed class Rotate: TransformAnimator<Rotation>
	{
		public Rotate()
		{
			Priority = (int)TransformPriority.Rotate;
		}
		
		/** A standard 2D rotation of the visual, which is the same as the Z-axis rotation */
		public float Degrees 
		{ 
			get { return DegreesZ; }
			set { DegreesZ = value; }
		}

		/** Degrees rotation around the X-axis. */
		public float DegreesX
		{
			get { return Math.RadiansToDegrees(X); }
			set { X = Math.DegreesToRadians(value); }
		}
	
		/** Degrees rotation around the Y-axis. */
		public float DegreesY
		{
			get { return Math.RadiansToDegrees(Y); }
			set { Y = Math.DegreesToRadians(value); }
		}
		
		/** Degrees rotation around the Z-axis. */
		public float DegreesZ
		{
			get { return Math.RadiansToDegrees(Z); }
			set { Z = Math.DegreesToRadians(value); }
		}

		internal override void Update(Visual elm, Rotation t, float4 value)
		{
			t.EulerAngle = value.XYZ;
		}
	}

	/**
		Scales the element. Note that scale doesn't actually change the elements size. This means that the rest of the UI layout wont be affected and the animation is guaranteed to be fast.

		You can scale an element uniformly along all axes by using the `Factor` property. Alternatively, you can also scale on a per-axis basis using `Vector` or `X`, `Y`, and `Z`.

		**Tip**: You can use `Scale` relative to something using the `RelativeTo` property. The two choices are:

		* `SizeChange` - scales relative to the change in size of the element specified by the `RelativeNode` property.
		* `SizeFactor` - scales with a factor relative to another element, specified by `RelativeNode`. A factor of `1` would make it the same size as the `RelativeNode`, while a factor of `0.5` would make it half the size, and so on.

		# Example
		The following example scales a rectangle when it is being pressed

			<Rectangle>
				<WhilePressed>
					<Scale Factor="2" Duration="0.4"/>
				</WhilePressed>
			</Rectangle>

		@see Scaling
	*/
	public sealed class Scale: TransformAnimator<Scaling>
	{
		IScalingMode _relativeTo = ScalingModes.Identity;
		/** See @Scaling.RelativeTo */
		public IScalingMode RelativeTo 
		{ 
			get { return _relativeTo; }
			set { _relativeTo = value; }
		}
		
		public Scale() 
		{ 
			Priority = (int)TransformPriority.Scale;
			_vectorValue = float4(1); 
		}

		/** See @Scaling.Factor */
		public float Factor 
		{ 
			get { return X; }
			set { _vectorValue = float4(value); }
		}

		internal override void Update(Visual elm, Scaling t, float4 value)
		{
			t.RelativeNode = RelativeNode ?? elm;
			t.RelativeTo = RelativeTo;
			t.Vector = value.XYZ;
		}
	}
	
	/**
		Allows you to animate a skew transform on an element.

		# Example
		This example animates a skew on a panel as it is being pressed

			<Panel Background="#F00">
				<WhilePressed>
					<Skew DegreesX="30" Duration="0.4"/>
				</WhilePressed>
			</Panel>

		@see Shear
	*/
	public sealed class Skew : TransformAnimator<Shear>
	{
		public Skew()
		{
			Priority = (int)TransformPriority.Shear;
		}
		
		internal override void Update(Visual elm, Shear t, float4 value)
		{
			t.Vector = value.XY;
		}
		
		/** Shear angle from X axis in degrees */
		public float DegreesX
		{
			get { return Math.RadiansToDegrees(X); }
			set { X = Math.DegreesToRadians(value); }
		}

		/** Shear angle from Y axis in degrees */
		public float DegreesY
		{
			get { return Math.RadiansToDegrees(Y); }
			set { Y = Math.DegreesToRadians(value); }
		}
	    
		/** Shear angle from the X and Y axes, in radians */
		public float2 XY
		{
			get { return _vectorValue.XY; }
			set { _vectorValue = float4(value,_vectorValue.Z,_vectorValue.W); }
		}

		/** Shear angle in Degrees. */
		public float2 DegreesXY
		{
			get { return float2(Math.RadiansToDegrees(X), Math.RadiansToDegrees(Y)); }
			set { XY = float2(Math.DegreesToRadians(value.X), Math.DegreesToRadians(value.Y)); }
		}
	}
	
}
