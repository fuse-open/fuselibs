using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Testing;

using Fuse.Controls.Test.Helpers;
using Fuse.Elements;
using Fuse.Layouts;
using Fuse.Resources;
using FuseTest;

using FuseTest;

namespace Fuse.Controls.Test
{
	public class ColumnLayoutTest : TestBase
	{
		[Test]
		public void Layout1()
		{
			var root = new TestRootPanel();
			var p = new UX.ColumnLayout1();
			root.Children.Add(p);
			root.Layout(int2(100));
			
			Assert.AreEqual(float2(0,0), p.P1.ActualPosition);
			Assert.AreEqual(float2(45,50), p.P1.ActualSize);
			Assert.AreEqual(float2(55,0), p.P2.ActualPosition);
			Assert.AreEqual(float2(0,55), p.P3.ActualPosition);
			Assert.AreEqual(float2(0,120), p.P4.ActualPosition);
		}
		
		[Test]
		public void Layout2()
		{
			var root = new TestRootPanel();
			var p = new UX.ColumnLayout2();
			root.Children.Add(p);
			root.Layout(int2(100));
			
			Assert.AreEqual(float2(0,0), p.P1.ActualPosition);
			Assert.AreEqual(float2(100,25), p.P1.ActualSize);
			Assert.AreEqual(float2(0,25), p.P2.ActualPosition);
			Assert.AreEqual(float2(0,50), p.P3.ActualPosition);
			Assert.AreEqual(float2(0,75), p.P4.ActualPosition);
			Assert.AreEqual(float2(90,75), p.P5.ActualPosition);
			Assert.AreEqual(float2(100,0), p.P6.ActualPosition);
		}
		
		[Test]
		public void Layout3()
		{
			var root = new TestRootPanel();
			var p = new UX.ColumnLayout3();
			root.Children.Add(p);
			root.Layout(int2(250,300));
			
			Assert.AreEqual(float2(25,0), p.ActualPosition);
			Assert.AreEqual(float2(200,300),p.ActualSize);
			Assert.AreEqual(float2(0,0), p.P1.ActualPosition);
			Assert.AreEqual(float2(100,50), p.P1.ActualSize);
			Assert.AreEqual(float2(100,0), p.P2.ActualPosition);
			Assert.AreEqual(float2(0,50), p.P3.ActualPosition);
			Assert.AreEqual(float2(100,50), p.P4.ActualPosition);
		}
		
		[Test]
		public void Layout4()
		{
			var root = new TestRootPanel();
			var p = new UX.ColumnLayout4();
			root.Children.Add(p);
			root.Layout(int2(120));
			
			Assert.AreEqual(2,p.L.ColumnCount);
			Assert.AreEqual(50,p.L.ColumnSize);
		}
		
		[Test]
		public void Layout5()
		{
			var root = new TestRootPanel();
			var p = new UX.ColumnLayout5();
			root.Children.Add(p);
			root.Layout(int2(1000,300));
			
			Assert.AreEqual(float2(400,0), p.ActualPosition);
			Assert.AreEqual(float2(200,300),p.ActualSize);
			Assert.AreEqual(float2(0,0), p.P1.ActualPosition);
			Assert.AreEqual(float2(100,50), p.P1.ActualSize);
			Assert.AreEqual(float2(100,0), p.P2.ActualPosition);
			Assert.AreEqual(float2(0,50), p.P3.ActualPosition);
			Assert.AreEqual(float2(100,50), p.P4.ActualPosition);
		}
		
	}
}
