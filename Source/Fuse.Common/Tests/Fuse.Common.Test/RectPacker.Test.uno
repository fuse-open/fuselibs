using Uno.Collections;
using Uno.Testing;
using Uno;

using Fuse.Internal;
using FuseTest;

namespace Fuse.Test
{
	public class RectPackerTest : TestBase
	{
		[Test]
		public void InsertSameSize()
		{
			var packerSize = int2(200, 100);
			var packerRect = new Recti(int2(0), packerSize);
			var packer = new RectPacker(packerSize);
			var size = int2(10, 10);

			var rects = new List<Recti>();
			{
				Recti rect;
				while (packer.TryAdd(size, out rect))
				{
					rects.Add(rect);
					Assert.IsTrue(packerRect.Contains(rect));
				}
			}

			Assert.IsTrue(rects.Count == (packerSize / size).X * (packerSize / size).Y);
			for (int i = 0; i < rects.Count; ++i)
			{
				for (int j = i + 1; j < rects.Count; ++j)
				{
					Assert.IsFalse(rects[i].Intersects(rects[j]));
				}
			}
		}

		[Test]
		public void InsertDifferentSizes()
		{
			var packerSize = int2(1234, 457);
			var packerRect = new Recti(int2(0), packerSize);
			var packer = new RectPacker(packerSize);

			var rects = new List<Recti>();
			{
				int i = 0;
				var size = int2(1, 1);
				Recti rect;
				while (packer.TryAdd(size, out rect))
				{
					rects.Add(rect);
					Assert.IsTrue(packerRect.Contains(rect));
					++i;
					size = int2(10 + i % 13, 10 + i % 17);
				}
			}

			Assert.IsTrue(rects.Count > 0); // Otherwise it's a pretty shitty packer

			for (int i = 0; i < rects.Count; ++i)
			{
				for (int j = i + 1; j < rects.Count; ++j)
				{
					Assert.IsFalse(rects[i].Intersects(rects[j]));
				}
			}
		}
	}
}
