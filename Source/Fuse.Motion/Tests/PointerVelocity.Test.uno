using Uno;
using Uno.Testing;
using FuseTest;

namespace Fuse.Motion.Simulation.Test
{
	public class PointerVelocityTest : TestBase
	{
		[Test]
		public void AndroidRelease()
		{
			var v = new PointerVelocity<float>();
			v.AddSample( 0, 0.01 );
			v.AddSample( 10, 0.01 );
			v.AddSample( 10, 0.01, SampleFlags.Release );
			//recorded output value, checks that the Release check is in place
			Assert.AreEqual( 400.00000, v.CurrentVelocity );
		}
	}
}
