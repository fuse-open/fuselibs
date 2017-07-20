using Uno;
using Uno.Collections;
using Uno.Testing;
using Fuse;
using Fuse.Elements;
using Fuse.Input;
using FuseTest;

namespace Fuse.Test
{
	public class MockElement : Element
	{
		public MockElement()
		{
			IsContextEnabledChanged += OnIsContextEnabledChanged;
		}

		protected override void OnDraw(DrawContext dc)
		{
		}

		public int IsContextEnabledChangedCount { get; private set; }
		private void OnIsContextEnabledChanged(object sender, EventArgs args)
		{
			IsContextEnabledChangedCount += 1;
		}
	}

	public class ElementEventTest : TestBase
	{
		[Test]
		public void PanelPlaced()
		{
			var p = new UX.PanelPlaced();
			using (var root = TestRootPanel.CreateWithChild(p, int2(1000)))
			{
				root.StepFrameJS();
				Assert.AreEqual("10", p.placedX.Value);
				Assert.AreEqual("20", p.placedY.Value);
				Assert.AreEqual("50", p.placedWidth.Value);
				Assert.AreEqual("60", p.placedHeight.Value);
			}
		}

		[Test]
		public void PanelPressed()
		{
			var p = new UX.PanelPointerEvents();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				var pointerEventData = new PointerEventData()
				{
					PointIndex = 0,
					WindowPoint = float2(10 + 10, 10 + 20),
					PointerType = Uno.Platform.PointerType.Touch,
					IsPrimary = true,
				};

				Fuse.Input.Pointer.RaisePressed(root, pointerEventData);
				root.StepFrameJS();

				Assert.AreEqual("pressed", p.eventName.Value);
				Assert.AreEqual("20", p.x.Value);
				Assert.AreEqual("30", p.y.Value);
				Assert.AreEqual("10", p.localX.Value);
				Assert.AreEqual("10", p.localY.Value);
			}
		}

		[Test]
		public void ImageElementIsContextEnabledEventTest()
		{
			var element = new MockElement();
			Assert.AreEqual(0, element.IsContextEnabledChangedCount);

			element.IsEnabled = false;
			Assert.AreEqual(1, element.IsContextEnabledChangedCount);

			element.IsEnabled = true;
			Assert.AreEqual(2, element.IsContextEnabledChangedCount);
		}
	}
}
