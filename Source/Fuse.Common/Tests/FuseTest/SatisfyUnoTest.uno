using Uno;
using Uno.Testing;

namespace FuseTest
{
	/** 
		FuseTest is picked up as a test suite due to naming convention, but will then fail since there are no tests in it. This is just a dummy test to make sure it runs and keeps TC happy.
	*/
	public class SatisfyUnoTest
	{
		[Test]
		public void Test()
		{
			Assert.IsTrue(true);
		}
	}
}