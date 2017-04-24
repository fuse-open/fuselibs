using Uno;
using Uno.Collections;
using Uno.Testing;

using FuseTest;
using Fuse.Elements;
using FuseTest;

namespace Fuse.Controls.Test
{

	public class TextInputTest : TestBase
	{

		////
		////
		////
		////
		//// TODO: Add textinput specific tests
		////
		////
		////
		
		[Test]
		public void TextWrappingTest()
		{
			var t = new TextInput();
			Assert.AreEqual(TextWrapping.NoWrap, t.TextWrapping);
			t.TextWrapping = TextWrapping.Wrap;
			Assert.AreEqual(TextWrapping.Wrap, t.TextWrapping);
		}

		[Test]
		public void AllElementProps()
		{
			var t = new TextInput();
			ElementPropertyTester.All(t);
		}

		[Test]
		public void AllLayoutTets()
		{
			var t = new TextInput();
			ElementLayoutTester.All(t);
		}
		
		[Test]
		public void Text()
		{
			var t = new TextInput();
			var text = t.Value;
			Assert.AreEqual("", text);
			t.Value = "dsopfjsdofijsdofijsdfoij";
			Assert.AreEqual("dsopfjsdofijsdofijsdfoij", t.Value);
		}

		
	}

}
