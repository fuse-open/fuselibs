using Uno;
using Uno.Testing;

using FuseTest;

namespace Fuse.Animations.Test
{
	public class ChangeTest : TestBase
	{
		[Test]
		/*
			This basically performs the calculation that will be done through the layers of the animation
			system. It should match what is done in the AverageMixer.
			
			These tests are important to ensure the correct clamping on over/under weighted/eased
			items undergoing Change.
		*/
		public void MixOpSingle()
		{	
			var p = new UX.ChangeMixOpSingle();
			using (var root = TestRootPanel.CreateWithChild(p, int2(100,1000)))
			{
				for (float i=0; i <= 1; i+= 0.01f)
				{
					var progress = Math.Min(1,i);
					var e = Easing.BackInOut.Map(progress);

					p.T1.Progress = progress;
					root.IncrementFrame();
					Assert.AreEqual(50 + (100-50) * e, p.R1.Height.Value, 1e-4);
					Assert.AreEqual( Math.Lerp(50,100, Math.Clamp(e,0,1)), p.R2.Height.Value, 1e-4);
					Assert.AreEqual(50 + 100 * e, p.R3.Height.Value, 1e-4);
				}
			}
		}
		
		[Test]
		/*
			Like MixOpSingle but expressed somewhat simpler in the case of Weight.
		*/
		public void MixOpDouble()
		{	
			var p = new UX.ChangeMixOpDouble();
			using (var root = TestRootPanel.CreateWithChild(p, int2(100,1000)))
			{
				for (float i1=0; i1 <= 1; i1+= 0.01f)
				{
					var progress1 = Math.Min(1,i1);
					var e1 = Easing.BackInOut.Map(progress1);

					p.T1.Progress = progress1;
					for (float i2=0; i2 <= 1; i2 += 0.01f)
					{
						var progress2 = Math.Min(1,i2);
						var e2 = Easing.ElasticInOut.Map(progress2);

						var partWeight = Math.Max(e1,0) + Math.Max(e2,0);
						var fullWeight = Math.Max(1, partWeight);
						p.T2.Progress = progress2;
						root.IncrementFrame();
						Assert.AreEqual(50 + (100-50) * e1 + (200-50) * e2, p.R1.Height.Value, 1e-4);
						Assert.AreEqual(
							50 * Math.Max(0, 1 - Math.Min(1,partWeight)) +
							100 * Math.Max(e1,0)/fullWeight +
							200 * Math.Max(e2,0)/fullWeight,
							p.R2.Height.Value, 1e-4);
						Assert.AreEqual(50 + 100 * e1 + 200 * e2, p.R3.Height.Value, 1e-4);
					}
				}
			}
		}
	}
}
