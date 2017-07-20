using Uno;
using Uno.Collections;
using Uno.Testing;

using Fuse;
using Fuse.Controls;
using Fuse.Elements;

using FuseTest;

namespace FuseTest
{
	public class ElementPropetiesTest : TestBase
	{

		[Test]
		public void TextBlockPropertyTest()
		{
			var t = new Text();	
			ElementPropertyTester.All(t);
		}

		[Test]
		public void ImagePropertyTest()
		{
			var i = new Image();
			ElementPropertyTester.All(i);
		}

	}

}
