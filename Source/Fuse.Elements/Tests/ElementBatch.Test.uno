using Uno;
using Uno.Testing;
using Uno.Collections;

using Fuse.Elements;

using FuseTest;

namespace Fuse.Elements.Test
{
	public class ElementBatchTest : TestBase
	{
		[Test]
		public void RenderBounds()
		{
			var batcher = new ElementBatcher();
			var atlas = new ElementAtlas();

			var batch = new ElementBatch(batcher, atlas);

			MockElement parent = new MockElement();
			var parentTranslation = new Translation() {
				X = 10,
				Y = 20
			};
			parent.Children.Add(parentTranslation);

			var elements = new MockElement[]
			{
				new MockElement() {
					RenderBounds = VisualBounds.Rect(float2(10, -10), float2(15, 0))
				},
				new MockElement() {
					RenderBounds = VisualBounds.Rect(float2(5, 0), float2(20, 10))
				}
			};

			var childTranslation = new Translation() {
				X = 0,
				Y = 10
			};
			elements[0].Children.Add(childTranslation);

			foreach (var elm in elements)
			{
				parent.Children.Add(elm);
				Assert.IsTrue(atlas.AddElement(elm));
				batch.AddElement(elm);
			}

			Assert.AreEqual(5, batch.RenderBounds.FlatRect.Left);
			Assert.AreEqual(20, batch.RenderBounds.FlatRect.Right);

			Assert.AreEqual(0, batch.RenderBounds.FlatRect.Top);
			Assert.AreEqual(10, batch.RenderBounds.FlatRect.Bottom);

			// batch.AddElement() appends to the current rect; make
			// we reproduce the same result when invalidating.

			batch.InvalidateRenderBounds(elements[0]);

			Assert.AreEqual(5, batch.RenderBounds.FlatRect.Left);
			Assert.AreEqual(20, batch.RenderBounds.FlatRect.Right);

			Assert.AreEqual(0, batch.RenderBounds.FlatRect.Top);
			Assert.AreEqual(10, batch.RenderBounds.FlatRect.Bottom);
		}
	}
}
