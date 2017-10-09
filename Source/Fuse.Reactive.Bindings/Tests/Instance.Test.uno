using Uno;
using Uno.UX;
using Uno.Testing;

using FuseTest;

namespace Fuse.Reactive.Bindings.Test
{
	public class InstanceTest : TestBase
	{
		[Test]
		public void TemplateNodeGroup()
		{
			var p = new UX.Instance.TemplateNodeGroup();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "zero,one,two", GetText(p));
			}
		}
		
		[Test]
		//a regression occurred when a derived class set Items (Charting does this)
		public void RootItems()
		{
			var e = new UX.Instance.RootItems();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.PumpDeferred();
				Assert.AreEqual("3,2", GetDudZ(e));
			}
		}
	
	}
	
	public class RootInstantiator : Instantiator
	{
		protected override void OnRooted()
		{
			base.OnRooted();
			_items = new object[]{2,3};
			OnItemsChanged();
		}
	}
}
