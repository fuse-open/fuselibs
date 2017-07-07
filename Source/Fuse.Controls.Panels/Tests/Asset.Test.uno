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
	public class AssetTest : TestBase
	{
		int UniqueAssetCount 
		{ 
			get 
			{
				int sum = 0;
				foreach (var e in Fuse.Controls.Asset._rootedAssets)
					if (e.Value.Assets.Count > 0) sum++;
				return sum;
			}
		}

		[Test]
		public void AssetBasics()
		{
			var c = new UX.AssetTest();
			var root = TestRootPanel.CreateWithChild(c);

			Assert.AreEqual(6, UniqueAssetCount);
			c.icon7.Number = 13;
			root.StepFrame();
			Assert.AreEqual(6+1, UniqueAssetCount);
			c.icon7.Number = 5;
			root.StepFrame();
			Assert.AreEqual(6, UniqueAssetCount);
			c.icon4.Number = 13;
			root.StepFrame();
			Assert.AreEqual(6+1, UniqueAssetCount);
			c.icon9.Number = 13;
			root.StepFrame();
			Assert.AreEqual(6+1, UniqueAssetCount);

			root.Children.Remove(c);
			root.StepFrame();
			Assert.AreEqual(0, UniqueAssetCount);
		}
	}
}