using Uno;
using Uno.UX;

namespace Fuse.Controls
{
	public abstract partial class EllipticalShape : Shape
	{
		static Selector EndAngleName = new Selector( "EndAngle" );
		static Selector StartAngleName=  new Selector( "StartAngle" );
		static Selector LengthAngleName = new Selector( "LengthAngle" );
		
		float _startAngle, _endAngle;
		bool _hasAngle;
		
		/** The angle in radians where the slice begins. */
		public float StartAngle
		{
			get { return _startAngle; }
			set
			{
				if (_hasAngle && _startAngle == value)
					return;
					
				_startAngle = value;
				_hasAngle = true;
				InvalidateSurfacePath();
				OnPropertyChanged(StartAngleName);
			}
		}
		
		/** The angle in radians where the slice ends. */
		public float EndAngle
		{
			get { return _endAngle; }
			set
			{
				if (_endAngle == value)
					return;
					
				_endAngle = value;
				InvalidateSurfacePath();
				OnPropertyChanged(EndAngleName);
			}
		}
		
		internal bool UseAngle
		{
			get
			{
				if (!_hasAngle)
					return false;

				//used to ensure that a full length gets drawn fully and hit test (otherwise would become
				//a partial as it wraps)
				const float zeroTolerance = 1e-05f;
				if (_hasLengthAngle && (Math.Abs(_lengthAngle) >= (2*Math.PIf-zeroTolerance)))
					return false;
					
				return true;
			}
		}
		
		//track distinct from EndAngle to allow animation just on StartAngle with a LengthAngle
		float _lengthAngle;
		bool _hasLengthAngle;
		/** An offset in radians from `StartAngle`. This can be used instead of `EndAngle`. */
		public float LengthAngle
		{
			get { return _lengthAngle; }
			set
			{
				if (_hasLengthAngle && _lengthAngle == value)
					return;
					
				_lengthAngle = value;
				_hasLengthAngle = true;
				InvalidateSurfacePath();
				OnPropertyChanged(LengthAngleName);
			}
		}
		
		/** The angle in degrees where the slice begins. */
		public float StartAngleDegrees
		{
			get { return Math.RadiansToDegrees(_startAngle); }
			set { StartAngle = Math.DegreesToRadians(value); }
		}
		/** The angle in degrees where the slice ends. */
		public float EndAngleDegrees
		{
			get { return Math.RadiansToDegrees(_endAngle); }
			set { EndAngle = Math.DegreesToRadians(value); }
		}
		
		/** An offset in degrees from `StartAngle`. This can be used instead of `EndAngleDegrees`. */
		public float LengthAngleDegrees
		{
			get { return Math.RadiansToDegrees(_lengthAngle); }
			set { LengthAngle = Math.DegreesToRadians(value); }
		}
		
		internal float EffectiveEndAngle
		{
			get
			{
				return _hasLengthAngle ? _startAngle + _lengthAngle : _endAngle;
			}
		}

		internal float EffectiveEndAngleDegrees
		{
			get { return Math.RadiansToDegrees(EffectiveEndAngle); }
		}
	}
}
