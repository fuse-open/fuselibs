using Uno;
using Uno.UX;

namespace Fuse.Animations
{
	[UXAutoGeneric("Change", "Target")]
	/**
		Temporarily changes the value of a property while its containing trigger is active. To permanently change a value, use the @Set animator.

		**Tip**: You can specify @(Units) with `Value` as long as the unit matches the original unit of the `Target`.

		Because the task of setting a target property and value is so common, UX has a special syntax for this. Instead of

			<Change Target="target.Property" Value="Value"/>

		one can do the following:

			<Change target.Property="Value"/>

		# Example
		
		As with other animators, you can also specify a `Duration`:
		
			<Panel ux:Name="panel" Color="#000">
				<WhilePressed>
					<Change panel.Color="#fff" Duration="0.5" />
				</WhilePressed>
			</Panel>
		
		If the value is continuous this will result in a continously interpolated change in value.
		If the value cannot be continuously animated, the value will change discretely.
		
		@remarks Docs/Change/Remarks.md
	*/
	public sealed class Change<T> : TrackAnimator
	{
		/**
			The property that we intend to animaite
		*/
		public Property<T> Target { get; private set; }

		/**
			Specifies the target value to change to.
		*/
		public T Value
		{
			get
			{
				return IsContinuous ? ContinuousConverter.Out(_vectorValue) : (T)_objectValue;
			}
			set
			{
				if (IsContinuous)
					_vectorValue = ContinuousConverter.In(value);
				else
					_objectValue = value;
			}
		}
		
		internal Converter<T> ContinuousConverter;
		
		[UXConstructor]
		public Change([UXParameter("Target")] Property<T> target)
		{
			if (target == null)
				throw new ArgumentNullException(nameof(target));

			Target = target;

			if (IsContinuous)
			{
				object v;
				if (typeof(T) == typeof(float))
					v = ConverterFloat.Singleton;
				else if (typeof(T) == typeof(float2))
					v = ConverterFloat2.Singleton;
				else if (typeof(T) == typeof(float3))
					v = ConverterFloat3.Singleton;
				else if (typeof(T) == typeof(float4))
					v = ConverterFloat4.Singleton;
				else if (typeof(T) == typeof(double))
					v = ConverterDouble.Singleton;
				else if (typeof(T) == typeof(Size))
					v = ConverterSize.Singleton;
				else if (typeof(T) == typeof(Size2))
					v = ConverterSize2.Singleton;
				else
					throw new Exception( "Unsupported change type: " + typeof(T) );
				ContinuousConverter = (Converter<T>)v;
			}
			else
			{
				Mixer = Fuse.Animations.Mixer.DefaultDiscrete;
				MarkDiscrete();
			}
		}

		internal override AnimatorState CreateState(CreateStateParams p)
		{ 
			if (IsContinuous)
				return new ContinuousTrackChangeState<T>(this, p); 
			return new DiscreteTrackChangeState<T>(this, p);
		}
		
		bool IsContinuous
		{
			get 
			{
				return 
					typeof(T) == typeof(float) ||
					typeof(T) == typeof(float2) ||
					typeof(T) == typeof(float3) ||
					typeof(T) == typeof(float4) ||
					typeof(T) == typeof(double) ||
					typeof(T) == typeof(Size) ||
					typeof(T) == typeof(Size2);
			}
		}

		/** Specifies the X component of the target Value */
		public float X
		{
			get { return _vectorValue.X; }
			set { _vectorValue.X = value; }
		}
		
		/** Specifies the X component of the target Value in degrees */
		public float DegreesX
		{
			get { return Math.RadiansToDegrees(X); }
			set { X = Math.DegreesToRadians(value); }
		}
		
		/** Specifies the Y component of the target Value */
		public float Y
		{
			get { return _vectorValue.Y; }
			set { _vectorValue.Y = value; }
		}
		
		/** Specifies the Y component of the target Value in degrees */
		public float DegreesY
		{
			get { return Math.RadiansToDegrees(Y); }
			set { Y = Math.DegreesToRadians(value); }
		}
		
		/** Specifies the Z component of the target Value */
		public float Z
		{
			get { return _vectorValue.Z; }
			set { _vectorValue.Z = value; }
		}
		
		/** Specifies the Z component of the target Value in degrees */
		public float DegreesZ
		{
			get { return Math.RadiansToDegrees(Y); }
			set { Y = Math.DegreesToRadians(value); }
		}
		
		/** Specifies the X and Y components of the target Value */
		public float2 XY
		{
			get { return _vectorValue.XY; }
			set { _vectorValue = float4(value,_vectorValue.Z,_vectorValue.W); }
		}
		
		/** Specifies the X and Y components of the target Value in degrees */
		public float2 DegreesXY
		{
			get { return float2(Math.RadiansToDegrees(X), Math.RadiansToDegrees(Y)); }
			set { XY = float2(Math.DegreesToRadians(value.X), Math.DegreesToRadians(value.Y)); }
		}
	}

	class DiscreteTrackChangeState<T> : TrackAnimatorState
	{
		IMixerHandle<T> mixHandle;
		new Change<T> Animator;
		
		public DiscreteTrackChangeState( Change<T> animator, CreateStateParams p )
			: base(animator, p)
		{
			this.Animator = animator;
			mixHandle = Animator.Mixer.Register( Animator.Target, Animator.MixOp );
		}
		
		public override void Disable()
		{
			if (mixHandle == null)
				return;
				
			mixHandle.Unregister();
			mixHandle = null;
		}
		
		protected override void SeekObjectValue( object value, float strength ) 
		{
			if (mixHandle == null)
			{
				debug_log "Invalid Seek";
				return;
			}
			if (value != null && value is T)
				mixHandle.Set( (T)value, strength );
		}
	}
	
	class ContinuousTrackChangeState<T> : TrackAnimatorState
	{
		IMixerHandle<T> mixHandle;
		new Change<T> Animator;
		
		public ContinuousTrackChangeState( Change<T> animator, CreateStateParams p )
			: base(animator, p)
		{
			this.Animator = animator;
			mixHandle = Animator.Mixer.Register( Animator.Target, Animator.MixOp );
		}
		
		public override void Disable()
		{
			if (mixHandle == null)
				return;
				
			mixHandle.Unregister();
			mixHandle = null;
		}
		
		protected override void SeekValue(float4 value, float strength)
		{
			if (mixHandle == null)
			{
				debug_log "Invalid Seek";
				return;
			}
			mixHandle.Set( Animator.ContinuousConverter.Out(value), strength );
		}
	}
	
	abstract class Converter<T>
	{
		abstract public T Out(float4 value);
		abstract public float4 In(T value);
	}
	
	class ConverterFloat : Converter<float>
	{
		public static ConverterFloat Singleton = new ConverterFloat();
		public override float Out(float4 value) { return value.X; }
		public override float4 In(float value) { return float4(value,0,0,0); }
	}

	class ConverterSize : Converter<Size>
	{
		public static ConverterSize Singleton = new ConverterSize();
		public override Size Out(float4 value) { return value.X; }
		public override float4 In(Size value) { return float4(value.Value,0,0,0); }
	}

	class ConverterSize2 : Converter<Size2>
	{
		public static ConverterSize2 Singleton = new ConverterSize2();
		public override Size2 Out(float4 value) { return value.XY; }
		public override float4 In(Size2 value) { return float4((float)value.X, (float)value.Y, 0, 0); }
	}
	
	
	class ConverterFloat2 : Converter<float2>
	{
		public static ConverterFloat2 Singleton = new ConverterFloat2();
		public override float2 Out(float4 value) { return value.XY; }
		public override float4 In(float2 value) { return float4(value,0,0); }
	}
	
	class ConverterFloat3 : Converter<float3>
	{
		public static ConverterFloat3 Singleton = new ConverterFloat3();
		public override float3 Out(float4 value) { return value.XYZ; }
		public override float4 In(float3 value) { return float4(value,0); }
	}
	
	class ConverterFloat4 : Converter<float4>
	{
		public static ConverterFloat4 Singleton = new ConverterFloat4();
		public override float4 Out(float4 value) { return value; }
		public override float4 In(float4 value) { return value; }
	}
	
	class ConverterDouble : Converter<double>
	{
		public static ConverterDouble Singleton = new ConverterDouble();
		public override double Out(float4 value) { return value.X; }
		public override float4 In(double value) { return float4((float)value,0,0,0); }
	}
}
