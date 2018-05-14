using Uno;
using Uno.Testing;

using Fuse.Charting;

using FuseTest;

namespace Fuse.Test
{
	public class DataTest: TestBase
	{
		[Test]
		public void GetStepping()
		{
			TestStepping( 10, 0, 73,  8, 0, 80 );
			TestStepping( 10, 0, 99, 10, 0, 100 );
			TestStepping( 10, 0, 105, 6, 0, 120 );
			TestStepping( 10, 0, 943, 10, 0, 1000 );
		}
		
		void TestStepping( int iStep, float iMin, float iMax, int oStep, float oMin, float oMax )
		{
			int steps = iStep;
			float min = iMin;
			float max = iMax;
			DataUtils.GetStepping(ref steps, ref min, ref max);
			Assert.AreEqual( oStep, steps );
			Assert.AreEqual( oMin, min );
			Assert.AreEqual( oMax, max );
		}
	}
}