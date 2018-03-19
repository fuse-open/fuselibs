using Uno;
using Uno.Testing;

using Fuse.Input;
using FuseTest;

namespace Fuse.Test
{
	public class KeyboardTest : TestBase
	{
		[Test]
		public void NullFocus()
		{
			var p = new UX.KeyboardFocus();
			using (var root = TestRootPanel.CreateWithChild(p))
			using (var keyGlobal = new KeyboardHandler())
			using (var keyB = new KeyboardHandler(p.B))
			using (var trp = new TestRootSingletonsGuard(root))
			{
				//should not crash
				//https://github.com/fusetools/fuselibs-private/issues/2948
				Keyboard.RaiseKeyPressed(Uno.Platform.Key.Left, false, false, false, false);
				Assert.AreEqual(root.RootViewport, keyGlobal.LastKeyPressedArgs.Visual);
				Assert.AreEqual(null, keyB.LastKeyPressedArgs);

				Focus.GiveTo(p.B);
				Keyboard.RaiseKeyPressed(Uno.Platform.Key.B, false, false, false, false);
				Assert.AreEqual(p.B, keyGlobal.LastKeyPressedArgs.Visual);
				Assert.AreEqual(p.B, keyB.LastKeyPressedArgs.Visual);
			}
		}
		
	}
}
