using Uno;

namespace Fuse.Charting
{
	/**
		Common utility functions, separated out for common use and/or easier testing.
	*/
	static class DataUtils
	{
		/**
			Adjusts a value range to produce pleasant stepping increments.
		*/
		static public void GetStepping( ref int steps, ref float min, ref float max )
		{
			var oMin = min;
			var oMax = max;
			var desiredSteps = steps;
			var range = max - min;

			//find magnitude and steps in powers of 10
			var step = range / steps;
			var mag10 = Math.Ceil( Math.Log(step) / Math.Log(10) );
			var baseStepSize = Math.Pow( 10, mag10 );
			
			//find common divisions to get closer to desiredSteps
			var trySteps = new[]{ 5, 4, 2, 1 };
			for (int i=0; i < trySteps.Length; ++i )
			{
				var stepSize = baseStepSize / trySteps[i];
				var ns = Math.Floor(range / stepSize + 0.5f);
				//bail if anything didn't work, We can't check float.ZeroTolernace anywhere since we should
				//work on arbitrary range values
				if (Float.IsNaN(baseStepSize) || Float.IsNaN(ns) || (ns < 1))
					return;
					
				min = Math.Floor( oMin / stepSize )  * stepSize;
				max = Math.Ceil( oMax / stepSize ) * stepSize;
				steps = (int)Math.Floor((max-min) / stepSize + 0.5f);
				
				if (steps <= desiredSteps)
					break;
			}
		}
		
		/**
			Does a magnitude sensitive division. This is required for charting since we can't assume any kind of absolute zero tolerance (the input data could just be small ranges)
		*/
		static public float RelDiv( float num, float den )
		{
			//NOTE: no `frexp` function to get exponent
			var expNum = Math.Log2(Math.Abs(num));
			var expDen = Math.Log2(Math.Abs(den));
			if (expNum - expDen > 20)
				return 0; //garbage-in garbage-out, charting won't deal with infinity
			return num / den;
		}
		
		static public float4 RelDiv( float4 num, float4 den )
		{
			return float4(
				RelDiv(num[0],den[0]),
				RelDiv(num[1],den[1]),
				RelDiv(num[2],den[2]),
				RelDiv(num[3],den[3]));
		}
	}
}
