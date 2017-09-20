using Uno;
using Uno.Threading;
using Uno.Testing;
using Uno.Collections;

using Fuse.Reactive;
using Fuse.Scripting;
using Fuse.Controls;
using FuseTest;

namespace Fuse.Scripting.Test
{
	public class ReadonlyPropertyPanel : Panel
	{
		static ReadonlyPropertyPanel()
		{
			ScriptClass.Register(
				typeof(ReadonlyPropertyPanel),
				new ScriptReadonlyProperty("stringProperty", "fusetools"),
				new ScriptReadonlyProperty("numberProperty", 13.37));
		}
	}

	public class ScriptReadonlyPropertyTest : TestBase
	{
		[Test]
		public void StringTest()
		{
			var child = new UX.ScriptReadonlyPropertyTest();
			using (var root = TestRootPanel.CreateWithChild(child))
			{
				root.StepFrameJS();
				Assert.AreEqual("fusetools", child.Properties.StringProperty);
			}
		}

		[Test]
		public void NumberTest()
		{
			var child = new UX.ScriptReadonlyPropertyTest();
			using (var root = TestRootPanel.CreateWithChild(child))
			{
				root.StepFrameJS();
				Assert.AreEqual(13.37, child.Properties.NumberProperty);
			}
		}
	}
}
