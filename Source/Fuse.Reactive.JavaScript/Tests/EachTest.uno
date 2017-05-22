using Uno;
using Uno.UX;
using Uno.Testing;

using Fuse.Controls;
using FuseTest;

namespace Fuse.Reactive.Test
{
	public class EachTest : TestBase
	{
		[Test]
		public void Basic()
		{
			var e = new UX.BasicEach();
			var root = TestRootPanel.CreateWithChild(e);
			
			root.StepFrameJS();
			Assert.AreEqual(30,e.C1.ZOrderChildCount);
			Assert.AreEqual("5", (e.C1.GetVisualChild(5) as Text).Value);

			//do in a loop to try and catch a few race conditions
			int baseCount = 30;
			int step = 0;
			while (baseCount > 6)
			{
				e.CallAdd.Perform();
				root.StepFrameJS();
				Assert.AreEqual(baseCount+1,e.C1.ZOrderChildCount);
				Assert.AreEqual("" + (step+5), (e.C1.GetVisualChild(5) as Text).Value);
				
				e.CallRemove.Perform();
				root.StepFrameJS();
				Assert.AreEqual(baseCount,e.C1.ZOrderChildCount);
				
				e.CallRemoveAt.Perform();
				root.StepFrameJS();
				Assert.AreEqual(baseCount-1,e.C1.ZOrderChildCount);
				
				//two removal + one addiiton
				baseCount--;
				//two removals at location 5, so id goes up by two
				step+=2;
			}
			
			e.CallClear.Perform();
			root.StepFrameJS();
			Assert.AreEqual(0,e.C1.ZOrderChildCount);
		}
		
		[Test]
		/**
			Ensures children are added in the correct location
		*/
		public void Order()
		{
			var e = new UX.EachOrder();
			var root = TestRootPanel.CreateWithChild(e);
			
			root.StepFrameJS();
			
			Assert.AreEqual(4,e.C1.ZOrderChildCount);
			Assert.AreEqual(e.C2, e.C1.GetVisualChild(0));
			Assert.AreEqual(new Selector("Q0"), e.C1.GetVisualChild(1).Name);
			Assert.AreEqual(new Selector("Q1"), e.C1.GetVisualChild(2).Name);
			Assert.AreEqual(e.C3, e.C1.GetVisualChild(3));
			
			e.CallRemove.Perform();
			e.CallRemove.Perform();
			root.StepFrameJS();
			Assert.AreEqual(2,e.C1.ZOrderChildCount);
			
			e.CallAdd.Perform();
			root.StepFrameJS();
			Assert.AreEqual(3,e.C1.ZOrderChildCount);
			Assert.AreEqual(e.C2, e.C1.GetVisualChild(0));
			Assert.AreEqual(new Selector("Q2"), e.C1.GetVisualChild(1).Name);
			Assert.AreEqual(e.C3, e.C1.GetVisualChild(2));
		}
		
		[Test]
		//variation on https://github.com/fusetools/fuselibs/issues/2802
		public void EachEach()
		{
			var e = new UX.EachEach();
			var root = TestRootPanel.CreateWithChild(e);
			
			root.StepFrameJS();
			Assert.AreEqual( "G0-0,G0-1,G1-0,G1-1", GetText(e));
			
			e.CallAdd.Perform();
			root.StepFrameJS();
			Assert.AreEqual( "G0-0,G0-1,G1-0,G1-1,G2-0,G2-1", GetText(e));
			
			e.CallRemove1.Perform();
			root.StepFrameJS();
			Assert.AreEqual( "G0-0,G0-1,G2-0,G2-1", GetText(e));
		}
		
		[Test]
		/* Tests changes in the Limit/Offset properties */
		public void EachWindow()
		{
			var e = new UX.Each.Window();
			var root = TestRootPanel.CreateWithChild(e);
			root.StepFrameJS();
			
			Assert.AreEqual( 100, e.E.DataCount );
			Assert.AreEqual( 5, e.E.WindowItemsCount );
			Assert.AreEqual( "0,1,2,3,4", GetText(e) );
			
			var childOffset = 2;
			
			var three = e.Children[childOffset+3] as Text;
			Assert.AreEqual( "3", three.Value );
			
			e.E.Offset = 3;
			root.StepFrameJS();
			Assert.AreEqual( "3,4,5,6,7", GetText(e) );
			Assert.AreEqual( 5, e.E.WindowItemsCount );
			
			//it must use the existing children if possible
			Assert.AreEqual( three, e.Children[childOffset+0] );
			
			e.E.Limit = 6;
			root.StepFrameJS();
			Assert.AreEqual( "3,4,5,6,7,8", GetText(e) );
			Assert.AreEqual( 6, e.E.WindowItemsCount );
			Assert.AreEqual( three, e.Children[childOffset+0] );
			
			e.E.Offset = 98;
			root.StepFrameJS();
			Assert.AreEqual( "98,99", GetText(e) );
			Assert.AreEqual( 2, e.E.WindowItemsCount );
		}
		
		[Test]
		/* Tests changes in the Observable while using the Limit/Offset properties */
		public void EachWindowMod()
		{
			var e = new UX.Each.WindowMod();
			var root = TestRootPanel.CreateWithChild(e);
			root.StepFrameJS();
			
			Assert.AreEqual( "10,11,12,13,14", GetText(e.C) );
			
			e.CallAdd.Perform();
			root.StepFrameJS();
			Assert.AreEqual( "10,11,12,13,14", GetText(e.C) );
			
			e.CallRemoveAt.Perform();
			root.StepFrameJS();
			Assert.AreEqual( "10,11,13,14,15", GetText(e.C) );
			
			e.CallRemove.Perform();
			root.StepFrameJS();
			Assert.AreEqual( "11,13,14,15,16", GetText(e.C) );
			
			e.CallInsert.Perform();
			root.StepFrameJS();
			Assert.AreEqual( "11,13,ins,14,15", GetText(e.C) );
			
			e.CallClear.Perform();
			root.StepFrameJS();
			Assert.AreEqual( "", GetText(e.C) );
			
			e.CallAdd.Perform();
			root.StepFrameJS();
			Assert.AreEqual( "", GetText(e.C) );
			e.E.Offset = 0;
			root.PumpDeferred();
			Assert.AreEqual( "add", GetText(e.C) );
			
			e.CallReplaceAll1.Perform();
			root.StepFrameJS();
			Assert.AreEqual( "r0", GetText(e.C) );
			
			e.CallReplaceAll5.Perform();
			e.E.Offset = 1;
			e.E.Limit = 2;
			root.StepFrameJS();
			Assert.AreEqual( "r2,r3", GetText(e.C) );
			
			//try rerooting to ensure sanity
			root.Children.Remove(e);
			Assert.AreEqual( 1, e.C.Children.Count ); //Each only
			root.StepFrameJS();
			root.Children.Add(e);
			root.StepFrameJS();
			Assert.AreEqual( "1,2", GetText(e.C) );
		}
		
		[Test]
		/* Tests Each with Limit and Count. Since Count doesn't expose an index we can't actually tell 
		if the "correct" items are used. This is thus just to ensure nothing breaks. */
		public void EachLimitCount()
		{
			var e = new UX.Each.LimitCount();
			var root = TestRootPanel.CreateWithChild(e);
			root.PumpDeferred();
			
			Assert.AreEqual( "*,*,*,*,*", GetText(e) );
			
			e.E.Offset = 8;
			root.PumpDeferred();
			Assert.AreEqual( "*,*", GetText(e) );
			
			root.Children.Remove(e);
			e.E.Offset = 7;
			root.Children.Add(e);
			root.PumpDeferred();
			Assert.AreEqual( "*,*,*", GetText(e) );
		}
		
		[Test]
		public void Issue3312()
		{
			var e = new UX.Each.Issue3312();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual( "Jane,Alex", GetText(e.P1));
			}
		}
		
		[Test]
		public void Issue3430()
		{
			var e = new UX.Each.Issue3430();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual("1,2", GetText(e.S));
				
				e.increment.Perform();
				root.StepFrameJS();
				Assert.AreEqual("1,2,1,2,3,4,5", e.OC.JoinValues());
				Assert.AreEqual("1,2,1,2,3,4,5", GetText(e.S));
				
				//removeRange had the same underlying problem
				e.decrement.Perform();
				root.StepFrameJS();
				Assert.AreEqual("1,2,4,5", e.OC.JoinValues());
				Assert.AreEqual("1,2,4,5", GetText(e.S));
			}
		}
		
		[Test]
		public void Fail()
		{
			var e = new UX.Each.Fail();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual("0,1", GetText(e.C));
				
				e.CallFail.Perform();
				root.StepFrameJS();
				Assert.AreEqual("fail", GetText(e.C));
				
				e.CallRestore.Perform();
				root.StepFrameJS();
				Assert.AreEqual("R0,R1", GetText(e.C));
			}
		}
		
		[Test]
		//tests an issue with Offset going beyond end of data
		public void Offset()
		{
			var e = new UX.Each.Offset();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual("3,4,5,6,7,8,9", GetText(e));
			}
		}
		
		[Test]
		public void Expression()
		{
			var e = new UX.Each.Expression();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual("1-1-0,2-2-1,3-3-2", GetText(e));
			}
		}
	}
}
