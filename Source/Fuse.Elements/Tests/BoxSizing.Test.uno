using Uno;
using Uno.Compiler;
using Uno.Testing;

using FuseTest;
using Fuse.Resources;

namespace Fuse.Elements.Test
{
	public class BoxSizingTest : TestBase
	{
		[Test]
		public void Min()
		{
			var p = new global::UX.MinSizing();
			using (var root = new TestRootPanel())
			{
				root.Children.Add(p);
				root.Layout(int2(1000));
				
				Assert.AreEqual(float2(100,50),p.E1.ActualSize);
				Assert.AreEqual(float2(600,300),p.E2.ActualSize);
				Assert.AreEqual(float2(150,80),p.E3.ActualSize);
				
				Assert.AreEqual(float2(100,50),p.P1.ActualSize);
				Assert.AreEqual(float2(100,50),p.P2.ActualSize);
				Assert.AreEqual(float2(100,50),p.P3.ActualSize);
			}
		}
		
		[Test]
		public void Explicit()
		{
			var p = new global::UX.ExplicitSizing();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000)))
			{
				while (p.E1.Source.State != ImageSourceState.Ready ||
				       p.E2.Source.State != ImageSourceState.Ready)
				{
					Uno.Threading.Thread.Sleep(10);
					root.StepFrame();
				}

				Assert.AreEqual(float2(300,150),p.E1.ActualSize);
				Assert.AreEqual(float2(100,50),p.E2.ActualSize);
				
				Assert.AreEqual(float2(200,80),p.M1.ActualSize);
				Assert.AreEqual(float2(400,120),p.M2.ActualSize);

				//resources should clean up
 				root.Children.Remove(p);
				root.CleanLowMemory();
 				Assert.AreEqual(0,Fuse.Resources.DisposalManager.TestMemoryResourceCount);
			}
		}
		
		[Test]
		public void Max()
		{
			var p = new global::UX.MaxSizing();
			using (var root = new TestRootPanel())
			{
				root.Children.Add(p);
				root.Layout(int2(1000));
				
				Assert.AreEqual(float2(100,50),p.E1.ActualSize);
				Assert.AreEqual(float2(160,80),p.E2.ActualSize);
				Assert.AreEqual(float2(200,50),p.E3.ActualSize);
				Assert.AreEqual(float2(200,100),p.E4.ActualSize);
				
				Assert.AreEqual(float2(100,50),p.P1.ActualSize);
				Assert.AreEqual(float2(100,50),p.P2.ActualSize);
				Assert.AreEqual(float2(100,50),p.P3.ActualSize);
			}
		}
	}
}
