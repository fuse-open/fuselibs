using Uno;

namespace Fuse.Internal
{
	public static class Statistics
	{
		//aka Low Pass filter
		//https://stackoverflow.com/questions/1023860/exponential-moving-average-sampled-at-varying-times
		public static double ExponentialMovingAverage( double current, double sample, double elapsed, 
			double period )
		{
			var alpha = ContinuousFilterAlpha(elapsed, period);
			return current + alpha * (sample - current);
		}
		
		public static double ContinuousFilterAlpha( double elapsed, double period )
		{
			return (1 - Math.Pow( Math.E, -elapsed / period ));
		}
	}
}
