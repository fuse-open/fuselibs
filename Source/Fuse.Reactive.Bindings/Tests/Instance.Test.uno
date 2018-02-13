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
	
		[Test]
		public void Item()
		{
			var e = new UX.Instance.Item();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				
				Assert.AreEqual( "F2", GetText(e.a));
				Assert.AreEqual( "O3", GetText(e.b));
				
				e.callNext.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "T4", GetText(e.b));
				
				e.callClear.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "", GetText(e.b));
				
				e.callDefault.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "D5", GetText(e.b));
			}
		}
		
		[Test]
		public void ItemNull()
		{
			var e = new UX.Instance.ItemNull();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				Assert.AreEqual(null, e.FirstChild<DudElement>() );
				
				e.a.Value = null;
				root.PumpDeferred();
				Assert.AreEqual(null, e.FirstChild<DudElement>() );
				
				e.a.Value = "X";
				root.PumpDeferred();
				Assert.AreEqual( ":X:", GetDudZ(e));
				
				e.a.Value = null;
				root.PumpDeferred();
				Assert.AreEqual(null, e.FirstChild<DudElement>() );
			}
		}
		
		[Test]
		public void IsEnabled()
		{
			var e = new UX.Instance.IsEnabled();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				Assert.AreEqual( "", GetText(e.a));
				Assert.AreEqual( "", GetText(e.b));
				
				e.callShow.Perform();
				e.ia.IsEnabled = true;
				root.StepFrameJS();
				Assert.AreEqual( "boop", GetText(e.a));
				Assert.AreEqual( "beep", GetText(e.b));
			}
		}
		
		[Test]
		public void Match()
		{
			var e = new UX.Instance.Match();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				Assert.AreEqual("D,X", GetText(e));
				
				e.ma.Match = "a";
				e.mb.Match = "q";
				e.callH.Perform();
				root.StepFrameJS();
				
				Assert.AreEqual("A,H,h,X", GetText(e));
			}
		}
		
		[Test]
		public void Defaults()
		{
			var e = new UX.Instance.Defaults();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				Assert.AreEqual( "B,D,G,H", GetText(e));
			}
		}
	}
	
	public class RootInstantiator : Instantiator
	{
		protected override void OnRooted()
		{
			base.OnRooted();
			SetItemsDerivedRooting( new object[]{2,3} );
		}
	}
}
