using Uno;
using Uno.Testing;
using Uno.UX;

using FuseTest;

namespace Fuse.Test
{
	public class RootingTest : TestBase
	{
		[Test]
		public void Ordering()
		{
			var p = new UX.RootingOrdering();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				p.Children.Remove(p.P1);
				p.Children.Add(p.P1);

				p.W2.Value = false;
				p.W2.Value = true;
			}
		}

		[Test]
		public void Paradox()
		{
			try
			{
				var p = new UX.RootingParadox();
				using (var root = TestRootPanel.CreateWithChild(p))
					Assert.IsTrue(false); // we shouldn't get here
			} catch( Exception ex ) {
				//just ensure we've detected a rooting problem
				Assert.IsTrue( ex.Message.IndexOf( "rooting" ) != -1 );
			}
		}

		[Test]
		[Ignore("https://github.com/fusetools/fuselibs/issues/2244")]
		public void UnrootDuringRoot()
		{
			var p = new UX.UnrootDuringRoot();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.IsFalse(p.B1.Value);
				Assert.IsFalse(p.Children.Contains(p.P2));
				Assert.IsFalse(p.P2.IsRootingCompleted);
			}
		}

		[Test]
		/** This is a variant that we actually supported when these tests were first written. */
		public void UnrootVariant()
		{
			var p = new UX.UnrootVariant();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.IncrementFrame();

				p.B2.Value = true;
				root.PumpDeferred();
				Assert.IsFalse(p.B1.Value);
				Assert.IsFalse(p.Children.Contains(p.P2));
				Assert.IsFalse(p.P2.IsRootingCompleted);

				root.IncrementFrame();
				//B2 is not true, so it will skip the action during rooting
				p.B1.Value = true;
				Assert.IsTrue(p.B1.Value);
				Assert.IsTrue(p.Children.Contains(p.P2));
				Assert.IsTrue(p.P2.IsRootingCompleted);
			}
		}
	}
}
