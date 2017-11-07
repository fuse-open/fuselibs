using Uno;
using Uno.Testing;
using Uno.Collections;

using Fuse.Elements;

using FuseTest;

namespace Fuse.Elements.Test
{
	class MockElement : Element
	{
		public double DrawCost;

		VisualBounds _renderBounds;
		public VisualBounds RenderBounds
		{
			get
			{
				return _renderBounds;
			}

			set
			{
				_renderBounds = value;
				InvalidateRenderBounds();
			}
		}

		public static int DrawCount;
		public override void Draw(DrawContext dc)
		{
			DrawCount++;
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			AddDrawCost(DrawCost);
		}

		protected override void OnUnrooted()
		{
			RemoveDrawCost(DrawCost);
			base.OnUnrooted();
		}

		protected override VisualBounds CalcRenderBounds()
		{
			return RenderBounds;
		}
	}

	public class ElementBatcherTest : TestBase
	{
		[Test]
		public void Basic()
		{
			using (var rootPanel = new TestRootPanel())
			{
				Assert.AreNotEqual(0, ElementAtlasFramebuffer.Size.X);
				Assert.AreNotEqual(0, ElementAtlasFramebuffer.Size.Y);

				var batcher = new ElementBatcher();
				var elements = new List<MockElement>();
				for (int i = 0; i < 20; ++i)
				{
					var elm = new MockElement() {
						DrawCost = 2,
						RenderBounds = VisualBounds.Rect(float2(0, 0), float2(10, 10))
					};

					elements.Add(elm);
					batcher.AddElement(elm);
					rootPanel.Children.Add(elm);
				}

				var dc = new DrawContext(rootPanel.RootViewport);

				foreach (var elm in elements)
				{
					Assert.IsTrue(ElementBatcher.ShouldBatchElement(elm));
				}

				MockElement.DrawCount = 0;
				batcher.Draw(dc);
				Assert.AreEqual(MockElement.DrawCount, 0);

				foreach (var elm in elements)
					Assert.AreNotEqual(elm.ElementBatchEntry, null);
			}
		}

		[Test]
		public void MoveAfterFirstDraw()
		{
			const float tolerance = 2.0f / 255;

			var p = new UX.ElementBatcher.MoveAfterFirstDraw();
			using (var root = TestRootPanel.CreateWithChild(p, int2(40, 110)))
			{
				var edgeMargin = 1;

				using (var fb = root.CaptureDraw())
				{
					fb.AssertSolidRectangle(float4(1, 0, 0, 1), new Recti(int2(0 + edgeMargin, 100 + edgeMargin), int2(20 - 2 * edgeMargin, 10 - 2 * edgeMargin)), tolerance);
				}

				p._translation.X = 15;
				root.StepFrame();

				using (var fb = root.CaptureDraw())
				{
					fb.AssertSolidRectangle(float4(1, 0, 0, 1), new Recti(int2(15 + edgeMargin, 100 + edgeMargin), int2(20 - 2 * edgeMargin, 10 - 2 * edgeMargin)), tolerance);
					fb.AssertPixel(float4(0, 0, 0, 0), int2(15 - edgeMargin, 105));
				}

			}
		}

		[Test]
		public void ZeroSizeAfterFirstDraw()
		{
			var p = new UX.ElementBatcher.ZeroSizeAfterFirstDraw();
			using (var root = TestRootPanel.CreateWithChild(p, int2(10, 13)))
			{
				// Due to precision issues while blitting on AMD hardware, we sadly need a surprisingly
				// large tolerance here. The test still tests what it tries too, though.
				var tolerance = 3.0f / 255;

				using (var fb = root.CaptureDraw())
				{
					fb.AssertSolidRectangle(float4(0, 0, 1, 1), new Recti(int2(0,  0), int2(10,  1)), tolerance); // Guard
					fb.AssertSolidRectangle(float4(0, 1, 0, 1), new Recti(int2(0,  1), int2(10, 10)), tolerance);
					fb.AssertSolidRectangle(float4(1, 0, 0, 1), new Recti(int2(0, 11), int2(10,  1)), tolerance); // Poison
					fb.AssertSolidRectangle(float4(0, 0, 1, 1), new Recti(int2(0, 12), int2(10,  1)), tolerance); // Guard
				}

				p.Poison.Height = 0;
				p.Poison.Background = null;
				root.StepFrame();

				using (var fb = root.CaptureDraw())
				{
					fb.AssertSolidRectangle(float4(0, 0, 1, 1), new Recti(int2(0,  0), int2(10,  1)), tolerance); // Guard
					fb.AssertSolidRectangle(float4(0, 1, 0, 1), new Recti(int2(0,  1), int2(10, 10)), tolerance);
					fb.AssertSolidRectangle(float4(0, 0, 1, 1), new Recti(int2(0, 11), int2(10,  1)), tolerance); // Guard
				}
			}
		}
	}
}
