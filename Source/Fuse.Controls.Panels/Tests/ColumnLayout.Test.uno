using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Testing;

using Fuse.Elements;
using Fuse.Layouts;
using Fuse.Resources;
using FuseTest;

namespace Fuse.Controls.Test
{
	public class ColumnLayoutTest : TestBase
	{
		[Test]
		public void Layout1()
		{
			var p = new UX.ColumnLayout1();
			using (var root = TestRootPanel.CreateWithChild(p, int2(100)))
			{
				Assert.AreEqual(float2(0,0), p.P1.ActualPosition);
				Assert.AreEqual(float2(45,50), p.P1.ActualSize);
				Assert.AreEqual(float2(55,0), p.P2.ActualPosition);
				Assert.AreEqual(float2(0,55), p.P3.ActualPosition);
				Assert.AreEqual(float2(0,120), p.P4.ActualPosition);
				Assert.AreEqual(2, p.L.SourceLineNumber);
				Assert.AreEqual("UX/ColumnLayout1.ux", p.L.SourceFileName);
			}
		}

		[Test]
		public void Layout2()
		{
			var p = new UX.ColumnLayout2();
			using (var root = TestRootPanel.CreateWithChild(p, int2(100)))
			{
				Assert.AreEqual(float2(0,0), p.P1.ActualPosition);
				Assert.AreEqual(float2(100,25), p.P1.ActualSize);
				Assert.AreEqual(float2(0,25), p.P2.ActualPosition);
				Assert.AreEqual(float2(0,50), p.P3.ActualPosition);
				Assert.AreEqual(float2(0,75), p.P4.ActualPosition);
				Assert.AreEqual(float2(90,75), p.P5.ActualPosition);
				Assert.AreEqual(float2(100,0), p.P6.ActualPosition);
				Assert.AreEqual(2, p.L.SourceLineNumber);
				Assert.AreEqual("UX/ColumnLayout2.ux", p.L.SourceFileName);
			}
		}

		[Test]
		public void Layout3()
		{
			var p = new UX.ColumnLayout3();
			using (var root = TestRootPanel.CreateWithChild(p, int2(250,300)))
			{
				Assert.AreEqual(float2(25,0), p.ActualPosition);
				Assert.AreEqual(float2(200,300),p.ActualSize);
				Assert.AreEqual(float2(0,0), p.P1.ActualPosition);
				Assert.AreEqual(float2(100,50), p.P1.ActualSize);
				Assert.AreEqual(float2(100,0), p.P2.ActualPosition);
				Assert.AreEqual(float2(0,50), p.P3.ActualPosition);
				Assert.AreEqual(float2(100,50), p.P4.ActualPosition);
				Assert.AreEqual(2, p.L.SourceLineNumber);
				Assert.AreEqual("UX/ColumnLayout3.ux", p.L.SourceFileName);
			}
		}

		[Test]
		public void Layout4()
		{
			var p = new UX.ColumnLayout4();
			using (var root = TestRootPanel.CreateWithChild(p, int2(120)))
			{
				Assert.AreEqual(2,p.L.ColumnCount);
				Assert.AreEqual(50,p.L.ColumnSize);
				Assert.AreEqual(2, p.L.SourceLineNumber);
				Assert.AreEqual("UX/ColumnLayout4.ux", p.L.SourceFileName);
			}
		}

		[Test]
		public void Layout5()
		{
			var p = new UX.ColumnLayout5();
			using (var root = TestRootPanel.CreateWithChild(p, int2(1000,300)))
			{
				Assert.AreEqual(float2(400,0), p.ActualPosition);
				Assert.AreEqual(float2(200,300),p.ActualSize);
				Assert.AreEqual(float2(0,0), p.P1.ActualPosition);
				Assert.AreEqual(float2(100,50), p.P1.ActualSize);
				Assert.AreEqual(float2(100,0), p.P2.ActualPosition);
				Assert.AreEqual(float2(0,50), p.P3.ActualPosition);
				Assert.AreEqual(float2(100,50), p.P4.ActualPosition);
				Assert.AreEqual(2, p.L.SourceLineNumber);
				Assert.AreEqual("UX/ColumnLayout5.ux", p.L.SourceFileName);
			}
		}

		[Test]
		public void TooSmall()
		{
			var p = new UX.ColumnLayout.TooSmall();
			using (var root = TestRootPanel.CreateWithChild(p,int2(100)))
			{
				Assert.AreEqual(float2(100,50),p.P1.ActualSize);
			}
		}

	}
}
