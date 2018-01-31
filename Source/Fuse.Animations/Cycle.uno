using Uno;
using Uno.UX;

namespace Fuse.Animations
{
	/** The shape of the waveform @Cycle uses to cycle between the Low and High value */
	public enum CycleWaveform
	{
		/** The value oscillates from Low to High in a sinusoidal shape */
		Sine,
		/** The value is linearly interpolated from Low to High  and High to Low */
		Triangle,
		/** The value is linearly interpolated from Low to High and then jumps back to Low. This is useful for repeated animations in a single direction. */
		Sawtooth,
		/** The value switches between Low and High */
		Square,
	}

	/** How the state is restored when the animator is played backwards */
	public enum CycleRestore
	{
		/** Plays backwards towards the resting state */
		Backward,
		/** Plays forward towards the resting state */
		Forward,
	}
	
	[UXAutoGeneric("Cycle","Target")]
	/** 
		Animates a repeating cycle between a high and low value using a given waveform.
		
		The cycling of the animation continues even when the `Trigger.Progress` reaches 1. When a trigger is deactivated the cycling will play backwards, possibly beyond reaching Progress=1, until it finds a suitable rest state. This ensure that `Cycle` does not produce any jarring switches when the triggers are activated and deactivated.
		
		## Example
		
		The below example creates a simple pulsing effect on the panel while it is pressed.
		
			<Panel Color="Blue" ux:Name="panel1" Width="100" Height="100">
				<WhilePressed>
					<Cycle Target="panel1.Width" Low="80" High="120" Frequency="0.5"/>
				</WhilePressed>
			</Panel>
			
		By adjusting the `Waveform` you can creates animations that wrap-around instead of bouncing back and forth.
		
			<Cycle Target="panel.X" Low="-100" High="100" Waveform="Triangle"/>
			
		The "wrap-around" here is simply the nature of the triangular waveform -- the default waveform is sinusoidal.
		
		## Formula
		
		The properties are defined to be a simple interface, but it may be easier to understand see how they all relate in an expression. Given a current time offset the value of the `Target` is defined roughly as:
		
			Target.Value = Lerp( Low, High, Easing( Waveform(Time) ) ) * Base + Offset
			
		`Low` and `High` can only be scalar values. `Cycle` checks whether these values cross zero, or one. If they do, it will start at that value, and return to that value when done (this is the default value for `ProgressOffset`). This allows a smooth return to rest state in animation.
		
		Modifying `Base` and `Offset` allows you to use `Cycle` with non-scalar values. Though be aware not all combinations of value can provide for a smooth return to the rest state.
	*/
	public class Cycle<T> : OpenAnimator
	{
		/** The property that is animated. */
		public Property<T> Target { get; private set; }
		/** The lowest scalar value in the cycle. */
		public float Low { get; set; }
		/** The highest scalar value in the cycle. */
		public float High { get; set; }
		
		/**
			Applied as a multiplier to the progress value. This allows using `Cycle` on properties that are not scalars, such as `float2`.
			
			Refer to the formula in the description of @Cycle
			
			The default is the identity value: `1` for a scalar, `1,1` for a float2, etc.
		*/
		public T Base { get; set; }
		
		/**
			Specifies the offset value applied to the Value formula.
			
			Refer to the formula in the description of @Cycle
			
			The default is zero.
		*/
		public T Offset { get; set; }
		
		[UXConstructor]
		public Cycle( Property<T> Target )
		{
			if (Target == null)
				throw new ArgumentNullException( "Target" );
			this.Target = Target;
			var blender = Internal.BlenderMap.Get<T>();
			Base = blender.One;
			Offset = blender.Zero;
		}

		double _frequency = 1;
		/** The frequency, in hertz, of the wave: how many times per second the cycle repeats. */
		public double Frequency
		{
			get { return _frequency; }
			set { _frequency = value; }
		}
		
		bool _hasBackFrequency;
		double _backFrequency;
		/** The frequency, in hertz, to use when animating back towards the rest position. */
		public double FrequencyBack
		{
			get { return _hasBackFrequency ? _backFrequency : Frequency; }
			set 
			{
				_backFrequency = value;
				_hasBackFrequency = true;
			}
		}

		CycleWaveform _waveform = CycleWaveform.Sine;
		/** The shape of the waveform used in the cycle. */
		public CycleWaveform Waveform
		{
			get { return _waveform; }
			set { _waveform = value; }
		}
		
		CycleRestore _restore = CycleRestore.Backward;
		/**
			How to return the value to the original/rest state when being played backwards/deactivated.
		*/
		public CycleRestore Restore
		{
			get { return _restore; }
			set { _restore = value; }
		}
		
		internal override AnimatorState CreateState(CreateStateParams p)
		{
			return new CycleState<T>(this, p);
		}

		bool IsZeroCrossing
		{
			get { return Low<=0 && High>=0; }
		}

		bool IsOneCrossing
		{
			get { return Low<=1 && High>=1; }
		}
		
		/**
			Calculated ProgressOffset based on High/Low to start at a rest state of 0.
		*/
		double RestProgress
		{
			get
			{
				double v = 0;
				if (IsZeroCrossing)
					v = (0-Low) / (High - Low);
				else if(IsOneCrossing)
					v = (1-Low) / (High - Low);
				
				switch (Waveform)
				{
					case CycleWaveform.Sine:
						return Math.Asin( 2*(v-0.5) ) / (Math.PI * 2);
					case CycleWaveform.Triangle:
						return v * 0.5;
					case CycleWaveform.Sawtooth:
						return v;
					case CycleWaveform.Square:
						return v; //who knows, but it's a square waveform, it's jerky anyway
				}
				return v;
			}
		}
		
		float _progressOffset = 0;
		bool _hasProgressOffset = false;
		/**
			Specifies the progress when Cycle should start, and defines the rest state. By default this is calculated to be a suitable rest position to avoid animation jerk when it turns on/off.
		*/
		public float ProgressOffset
		{
			//enforce that an easing prevents RestProgress from being known (would need invert easings)
			get { return _hasProgressOffset || _easing != null ? _progressOffset : (float)RestProgress; }
			set
			{
				_hasProgressOffset = true;
				_progressOffset = value;
			}
		}
		
		Easing _easing = null;
		/** 
			Specifies an easing applied to the waveform value. The default is `Linear`, meaning the waveform range of 0...1 is used directly (mapped to the `Low` ... `High` range). An `Easing` provides a different mapping for the values. 
		
			Note this value is applied on top of the `Waveform`, thus typically `Triangle` or `Sawtooth` are used if an `Easing` is desired. 
		*/
		[UXContent]
		public Easing Easing
		{
			get { return _easing; }
			set 
			{ 
				_easing = value; 
			}
		}
		
		internal double WaveformFunc( double i, double offset )
		{
			switch( Waveform )
			{
				case CycleWaveform.Sine:
					return Math.Sin((i + offset) * Math.PI * 2) / 2 + 0.5;
				case CycleWaveform.Triangle:
				{
					var a = Math.Mod( i + offset, 1 );
					if (a < 0.5)
						return a * 2;
					return 1 + 2 * (0.5 - a);
				}
				case CycleWaveform.Sawtooth:
				{
					var a = Math.Mod(i + offset, 1);
					return a;
				}
				case CycleWaveform.Square:
				{
					var a = Math.Mod( i + offset, 1 );
					return a < 0.5 ? 0 : 1;
				}
			}
			
			return i;
		}
	}

	class CycleState<T> : OpenAnimatorState
	{
		IMixerHandle<T> mixHandle;
		Cycle<T> Animator;
		Internal.Blender<T> blender;

		public CycleState( Cycle<T> animator, CreateStateParams p )
			: base(animator, p)
		{
			this.Animator = animator;
			mixHandle = Animator.Mixer.Register( Animator.Target, Animator.MixOp );
			blender = Internal.BlenderMap.Get<T>();
		}

		public override void Disable()
		{
			if (mixHandle == null)
				return;

			mixHandle.Unregister();
			mixHandle = null;
			progress = 0;
		}

		bool InRange( double low, double high, double value )
		{
			if (low < high)
				return value >= low && value <= high;
			return value >= high && value <= low;
		}

		double progress;
		protected override bool Seek(bool on, float interval, float strength, SeekDirection dir)
		{
			if (mixHandle == null)
			{
				Fuse.Diagnostics.InternalError( "invalid seek", this );
				return true;
			}

			bool done = false;
			var oldProgress = progress;
			
			var freq = interval < 0 ? Animator.FrequencyBack : Animator.Frequency;
			if (dir == SeekDirection.Backward && Animator.Restore == CycleRestore.Forward)
				interval = Math.Abs(interval);
			progress = progress + interval * freq;
			if (on)
			{
				progress = Math.Mod( progress, 1 );
			}
			else if (oldProgress <= 0 || progress <= 0 ||
				progress >= 1 || oldProgress >= 1 )
			{
				progress = 0;
				done = true;
			}

			var s = Animator.WaveformFunc( progress, Animator.ProgressOffset );
			if (Animator.Easing != null)
				s = Animator.Easing.Map((float)s);
				
			var value = blender.Add( Animator.Offset,
				blender.Weight( Animator.Base, Math.Lerp( Animator.Low, Animator.High, (float)s) ) );
			mixHandle.Set( value, strength );
			return done;
		}
	}

}
