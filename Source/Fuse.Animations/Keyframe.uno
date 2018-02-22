using Uno;
using Uno.UX;
using Uno.Collections;

using Fuse.Internal;

namespace Fuse.Animations
{
	/**
		Allows you to specify several steps for an animation.
	
		# Examples

		The following @(Move) animator will first animate X to 10 over 0.5 second, then from 10 to 15 over 0.5 second. Finally, it will go from an X of 15 to 5 over 1 second.
		
			<Move RelativeTo="ParentSize">
				<Keyframe X="10" Time="0.5"/>
				<Keyframe X="15" Time="1"/>
				<Keyframe X="5" Time="2"/>
			</Move>

		Here is an example of using @Keyframes with a @(Change) animator:
			<Page>
				<SolidColor ux:Name="background" Color="#f00"/>
				<ActivatingAnimation>
					<Change Target="background.Color">
						<Keyframe Value="#0f0" TimeDelta="0.25"/>
						<Keyframe Value="#f00" TimeDelta="0.25"/>
						<Keyframe Value="#ff0" TimeDelta="0.25"/>
						<Keyframe Value="#0ff" TimeDelta="0.25"/>
					</Change>
				</ActivatingAnimation>
			</Page>

		This time we use `TimeDelta` instead of time. With `TimeDelta` we can specify time as a relative term instead of absolute. This means that the order of the @Keyframes matter, but it lets us reason about the keyframes in terms of their duration instead of their absolute time on the timeline.
		
		Note: Despite being a `PropertyObject` the properties in this class are not reactive.
		
	@mount Animation
	*/
	public class Keyframe : PropertyObject
	{
		float4 _value;
		public float4 Value
		{ 
			get { return _value; }
			set { _value = value; }
		}
		
		object _objectValue;
		public object ObjectValue
		{
			get { return _objectValue; }
			set { _objectValue = value; }
		}

		public float X
		{
			get { return _value.X; }
			set { _value.X = value; }
		}
		
		public float Y
		{
			get { return _value.Y; }
			set { _value.Y = value; }
		}
		
		public float Z
		{
			get { return _value.Z; }
			set { _value.Z = value; }
		}
		
		public float2 XY
		{
			get { return _value.XY; }
			set { _value = float4(value,_value.Z,_value.W); }
		}
		
		public float3 XYZ
		{
			get { return _value.XYZ; }
			set { _value = float4(value,_value.W); }
		}
		
		public float DegreesX
		{
			get { return Math.RadiansToDegrees(_value.X); }
			set { _value.X = Math.DegreesToRadians(value); }
		}
		
		public float DegreesY
		{
			get { return Math.RadiansToDegrees(_value.Y); }
			set { _value.Y = Math.DegreesToRadians(value); }
		}
		
		public float DegreesZ
		{
			get { return Math.RadiansToDegrees(_value.Z); }
			set { _value.Z = Math.DegreesToRadians(value); }
		}
		
		public float2 DegreesXY
		{
			get { return float2(Math.RadiansToDegrees(_value.X),Math.RadiansToDegrees(_value.Y)); }
			set { _value = float4(Math.DegreesToRadians(value.X),
				Math.DegreesToRadians(value.Y),_value.Z,_value.W); }
		}
		
		double _timeDelta;
		bool _hasTimeDelta;
		/**
			The time at which this value is reached, specified in seconds since the last `Keyframe`.
		*/
		public double TimeDelta
		{
			get { return _timeDelta; }
			set
			{
				_timeDelta = value;
				_hasTimeDelta = true;
			}
		}
		
		double _time;
		bool _hasTime;
		/**
			The time at which this value is reached, specified in seconds since the start of the timeline.
		*/
		public double Time
		{
			get { return _time; }
			set
			{
				_time = value;
				_hasTime = true;
			}
		}
		
		float4 _tangentIn, _tangentOut;
		bool _hasTangentIn, _hasTangentOut;
		/**
			The direction and strength of the tangent leading into this point.
		*/
		public float4 TangentIn 
		{ 
			get { return _tangentIn; } 
			set
			{
				_tangentIn = value;
				_hasTangentIn = true;
			}
		}
		
		/** 
			The direction and strength of the tangent leading out of this point.
		*/
		public float4 TangentOut 
		{ 
			get { return _tangentOut; } 
			set
			{
				_tangentOut = value;
				_hasTangentOut = true;
			}
		}
		
		/**
			Use the same value for both TangentIn and TangentOut
		*/
		public float4 Tangent
		{
			get { return _tangentOut; }
			set
			{
				TangentIn = value;
				TangentOut = value;
			}
		}
		
		static internal double CompleteFrames( IList<Keyframe> frames,
			float tension, float bias, float continuity )
		{
			double time = 0;
			//complete details per frame
			for (int i=0; i < frames.Count; ++i)
			{
				var prev = frames[Math.Max(0,i-1)];
				var frame = frames[i];
				var next = frames[Math.Min(frames.Count-1,i+1)];
				var next2 = frames[Math.Min(frames.Count-1,i+2)];
				
				if (frame._hasTime)
				{
					frame._timeDelta = frame._time - time;
					time = frame._time;
				}
				else if(frame._hasTimeDelta)
				{
					time = time + frame._timeDelta;
					frame._time = time;
				}
				else
				{
					frame._time = time;
					frame._timeDelta = 0;
				}
				
				float4 ta, tb;
				Curves.KochanekBartelTangent(prev.Value, frame.Value, next.Value, next2.Value,
					tension, bias, continuity, out ta, out tb);
				if (i > 0 && !frame._hasTangentOut)
					frame._tangentOut = ta;
				if (!next._hasTangentIn)
					next._tangentIn = tb;
			}
			
			return time;
		}
	}
}
