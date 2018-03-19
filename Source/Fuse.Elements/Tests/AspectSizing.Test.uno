using Uno;
using Uno.Compiler;
using Uno.Testing;

using FuseTest;

namespace Fuse.Elements.Test
{
	public class AspectSizingTest : TestBase
	{
		[Test]
		public void Basic()
		{
			var p = new global::UX.AspectSizing();
			using (var root = new TestRootPanel())
			{
				root.Children.Add(p);
				
				root.Layout(int2(1000,500));
				
				Assert.AreEqual(float2(50,25),p.P1.ActualSize);
				Assert.AreEqual(float2(5,5),p.P1.ActualPosition);
				Assert.AreEqual(float2(100,50),p.P2.ActualSize);
				Assert.AreEqual(float2(900,450),p.P2.ActualPosition);
				
				Assert.AreEqual(float2(500,250),p.P3.ActualSize);
				Assert.AreEqual(float2(200,100),p.P4.ActualSize);
				Assert.AreEqual(float2(125,250),p.P5.ActualSize);
				Assert.AreEqual(float2(100,200),p.P6.ActualSize);
				
				Assert.AreEqual(float2(20,5),p.P7.ActualSize);
				Assert.AreEqual(float2(80,20),p.P8.ActualSize);
				Assert.AreEqual(float2(20,5),p.P9.ActualSize);
				Assert.AreEqual(float2(80,20),p.P10.ActualSize);
				
				Assert.AreEqual(float2(50,80),p.P11.ActualSize);
				Assert.AreEqual(float2(80,50),p.P12.ActualSize);

				Assert.AreEqual(float2(50,50),p.P13.ActualSize);
				Assert.AreEqual(float2(50,25),p.P14.ActualSize);
				Assert.AreEqual(float2(100,50),p.P15.ActualSize);
				Assert.AreEqual(float2(50,50),p.P16.ActualSize);
			}
		}
		
		[Test]
		public void Margin()
		{
			var p = new global::UX.AspectMargin();
			using (var root = new TestRootPanel())
			{
				root.Children.Add(p);
				
				root.Layout(int2(1000,500));
				Assert.AreEqual(float2(400,400),p.P1.ActualSize);
				Assert.AreEqual(float2(300,50),p.P1.ActualPosition);
			}
		}
		
		[Test]
		public void DockMargin()
		{
			//https://github.com/fusetools/fuselibs-private/issues/1473
			var p = new global::UX.DockAspect();
			using (var root = new TestRootPanel())
			{
				root.Children.Add(p);
				
				root.Layout(int2(1000,500));
				Assert.AreEqual(float2(400,400),p.P1.ActualSize);
				Assert.AreEqual(float2(300,50),p.P1.ActualPosition);
			}
		}
	}
}
