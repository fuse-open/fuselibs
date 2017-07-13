using Uno;
using Uno.UX;
using Uno.Testing;

using FuseTest;
using Fuse.Controls;

namespace Fuse.Test
{
	class TestPanel : Panel
	{
		public int OnArrangeMarginBoxCount { get; set; }
		protected override float2 OnArrangeMarginBox(float2 position, LayoutParams lp)
		{
			OnArrangeMarginBoxCount = OnArrangeMarginBoxCount + 1;
			return base.OnArrangeMarginBox(position, lp);
		}

		public int OnAdjustMarginBoxPositionCount { get; set; }
		internal override void OnAdjustMarginBoxPosition(float2 position)
		{
			OnAdjustMarginBoxPositionCount = OnAdjustMarginBoxPositionCount + 1;
			base.OnAdjustMarginBoxPosition(position);
		}
	}

	class TestDockPanel : DockPanel
	{
		public int OnArrangeMarginBoxCount { get; set; }
		protected override float2 OnArrangeMarginBox(float2 position, LayoutParams lp)
		{
			OnArrangeMarginBoxCount = OnArrangeMarginBoxCount + 1;
			return base.OnArrangeMarginBox(position, lp);
		}
	}


	/*
		This spot-tests scenarios where optimization should avoid arranging, or calculating the size
		on controls.
	*/
	public class VisualLayoutTest : TestBase
	{
		[Test]
		public void DockPanel()
		{
			var p = new UX.VisualMarginDockPanel();
			using (var r = TestRootPanel.CreateWithChild(p, int2(500,1000)))
			{
				p.P2.OnArrangeMarginBoxCount = 0;
				p.P1.OnArrangeMarginBoxCount = 0;
				p.D2.OnArrangeMarginBoxCount = 0;

				p.P1.InvalidateLayout();
				r.IncrementFrame();

				Assert.AreEqual(0, p.P2.OnArrangeMarginBoxCount );
				Assert.AreEqual(1, p.P1.OnArrangeMarginBoxCount );
				Assert.AreEqual(0, p.D2.OnArrangeMarginBoxCount );
				
				p.P2.OnArrangeMarginBoxCount = 0;
				p.P1.OnArrangeMarginBoxCount = 0;
				//TODO: p.D1.OnArrangeMarginBoxCount = 0;

				p.P2.InvalidateLayout();
				r.IncrementFrame();
				Assert.AreEqual(1, p.P2.OnArrangeMarginBoxCount );
				Assert.AreEqual(0, p.P1.OnArrangeMarginBoxCount );
				//TODO: Assert.AreEqual(0, p.D1.OnArrangeMarginBoxCount );
				
				p.P4.OnArrangeMarginBoxCount = 0;
				p.P3.OnArrangeMarginBoxCount = 0;
				p.D2.OnArrangeMarginBoxCount = 0;
				p.P6.OnArrangeMarginBoxCount = 0;
				p.P5.OnArrangeMarginBoxCount = 0;
				p.P7.OnArrangeMarginBoxCount = 0;
				p.P7.OnAdjustMarginBoxPositionCount = 0;

				p.P3.Width = Size.Points(60);
				r.IncrementFrame();
				Assert.AreEqual(0, p.P4.OnArrangeMarginBoxCount );
				Assert.AreEqual(1, p.P3.OnArrangeMarginBoxCount );
				Assert.AreEqual(1, p.D2.OnArrangeMarginBoxCount );
				Assert.AreEqual(0, p.P6.OnArrangeMarginBoxCount );
				Assert.AreEqual(1, p.P5.OnArrangeMarginBoxCount );
				
				Assert.AreEqual(0, p.P7.OnArrangeMarginBoxCount );
				Assert.AreEqual(1, p.P7.OnAdjustMarginBoxPositionCount );
				Assert.AreEqual(float2(60,0), p.P7.ActualPosition);
			}
		}
	}
}
