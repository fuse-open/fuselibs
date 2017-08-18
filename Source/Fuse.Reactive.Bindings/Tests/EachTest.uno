using Uno;
using Uno.UX;
using Uno.Testing;

using Fuse.Controls;
using Fuse.Elements;
using FuseTest;

namespace Fuse.Reactive.Test
{
	// This is here because a test depends on an obsolete entrypoint
	// Visual.GetVisualChild
	static class VisualExtensions
	{
		public static Visual GetVisualChildImpl(this Visual parent, int index)
		{
			var c = parent.FirstChild<Visual>();
			int i = 0;
			while (c != null)
			{
				if (i == index) return c;
				i++;
				c = c.NextSibling<Visual>();
			}
			return null;
		}
	}

	public class EachTest : TestBase
	{
		[Test]
		public void DoubleSubscribe()
		{
			var e = new UX.Each.DoubleSubscribe();
			Instance.InsertCount = 0;
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual(6, e.sp.Children.Count);
				Assert.AreEqual(3, Instance.InsertCount);
				Instance.InsertCount = 0;
				e.sw.Value = true;
				root.StepFrameJS();
				Assert.AreEqual(10, e.sp.Children.Count);
				Assert.AreEqual(3, Instance.InsertCount);
				Instance.InsertCount = 0;
				e.sw.Value = false;
				root.StepFrameJS();
				Assert.AreEqual(6, e.sp.Children.Count);
				Assert.AreEqual(0, Instance.InsertCount);
				Instance.InsertCount = 0;

				// Weridly, second time it failed to add the items back
				// https://github.com/fusetools/fuselibs-public/issues/227
				e.sw.Value = true;
				root.StepFrameJS();
				Assert.AreEqual(10, e.sp.Children.Count);
				Assert.AreEqual(3, Instance.InsertCount);
			}
		}

		[Test]
		public void Basic()
		{
			var e = new UX.Each.Basic();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual(30,e.C1.ZOrderChildCount);
				Assert.AreEqual("5", (e.C1.GetVisualChildImpl(5) as Text).Value);

				//do in a loop to try and catch a few race conditions
				int baseCount = 30;
				int step = 0;
				while (baseCount > 6)
				{
					e.CallAdd.Perform();
					root.StepFrameJS();
					Assert.AreEqual(baseCount+1,e.C1.ZOrderChildCount);
					Assert.AreEqual("" + (step+5), (e.C1.GetVisualChildImpl(5) as Text).Value);
					
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
		}
		
		[Test]
		/**
			Ensures children are added in the correct location
		*/
		public void Order()
		{
			var e = new UX.Each.Order();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				
				Assert.AreEqual(4,e.C1.ZOrderChildCount);
				Assert.AreEqual(e.C2, e.C1.GetVisualChildImpl(0));
				Assert.AreEqual(new Selector("Q0"), e.C1.GetVisualChildImpl(1).Name);
				Assert.AreEqual(new Selector("Q1"), e.C1.GetVisualChildImpl(2).Name);
				Assert.AreEqual(e.C3, e.C1.GetVisualChildImpl(3));
				
				e.CallRemove.Perform();
				e.CallRemove.Perform();
				root.StepFrameJS();
				Assert.AreEqual(2,e.C1.ZOrderChildCount);
				
				e.CallAdd.Perform();
				root.StepFrameJS();
				Assert.AreEqual(3,e.C1.ZOrderChildCount);
				Assert.AreEqual(e.C2, e.C1.GetVisualChildImpl(0));
				Assert.AreEqual(new Selector("Q2"), e.C1.GetVisualChildImpl(1).Name);
				Assert.AreEqual(e.C3, e.C1.GetVisualChildImpl(2));
			}
		}
		
		[Test]
		//variation on https://github.com/fusetools/fuselibs/issues/2802
		public void EachEach()
		{
			var e = new UX.Each.Each();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual( "G0-0,G0-1,G1-0,G1-1", GetText(e));
				
				e.CallAdd.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "G0-0,G0-1,G1-0,G1-1,G2-0,G2-1", GetText(e));
				
				e.CallRemove1.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "G0-0,G0-1,G2-0,G2-1", GetText(e));
			}
		}
		
		[Test]
		/* Tests changes in the Limit/Offset properties */
		public void EachWindowBasic()
		{
			var e = new UX.Each.Window();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
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
		}
		
		[Test]
		/* Tests changes in the Observable while using the Limit/Offset properties */
		public void EachWindowMod()
		{
			var e = new UX.Each.WindowMod();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
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
		}
		
		[Test]
		/* Tests Each with Limit and Count. Since Count doesn't expose an index we can't actually tell 
		if the "correct" items are used. This is thus just to ensure nothing breaks. */
		public void EachLimitCount()
		{
			var e = new UX.Each.LimitCount();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
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
		public void FunctionBasic()
		{
			var e = new UX.Each.Function.Basic();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual("1-1-0,2-2-1,3-3-2", GetText(e));
			}
		}
		
		[Test]
		//ensure values are updated as each items change
		public void FunctionOrder()
		{
			var e = new UX.Each.Function.Order();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual("0-0,1-1", GetText(e));
				
				e.CallInsert.Perform();
				root.StepFrameJS();
				Assert.AreEqual("2-0,0-1,1-2", GetText(e));
				
				e.CallRemove.Perform();
				root.StepFrameJS();
				Assert.AreEqual("2-0,1-1", GetText(e));
				
				e.CallReplace.Perform();
				root.StepFrameJS();
				Assert.AreEqual("3-0", GetText(e));
			}
		}
		
		[Test]
		//nested Each lookup
		public void FunctionArg()
		{
			var e = new UX.Each.Function.Arg();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
 				root.StepFrame();
 				Assert.AreEqual("0-0,0-1,1-0,1-1", GetText(e));
			}
		}

		[Test]
		public void Reuse()
		{
			var e = new UX.Each.Reuse();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				var z0 = GetZChildren(e.s);
				
				e.e.Offset = 1;
				root.StepFrame();
				var z1 = GetZChildren(e.s);
				Assert.AreEqual("5,4,3,2,1", GetDudZ(e.s));
				
				Assert.AreEqual(z0[0],z1[1]);
				Assert.AreEqual(z0[4],z1[0]); //node actually reused
				
				//ensure layout was invalidated
				Assert.AreEqual(float2(0,40),(z1[0] as Element).ActualPosition);
				Assert.AreEqual(float2(0,0),(z1[4] as Element).ActualPosition);
				Assert.IsTrue(e.e.TestIsAvailableClean);
			}
		}
		
		[Test]
		public void ReuseRemove()
		{
			var e  = new UX.Each.ReuseRemove();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual("9,8,7,6,5,4,3,2,1,0", GetDudZ(e.s));
		
				e.Remove.Perform();
				root.StepFrameJS();
				Assert.AreEqual("9,8,7,6,5,4,3,1,0", GetDudZ(e.s));
			}
		}
		
		[Test]
		//same setup as Reuse but ensures the nodes are not reused (Reuse="None", as default)
		public void ReuseNone()
		{
			var e = new UX.Each.ReuseNone();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				var z0 = GetZChildren(e.s);
				
				e.e.Offset = 1;
				root.StepFrame();
				var z1 = GetZChildren(e.s);
				Assert.AreEqual("5,4,3,2,1", GetDudZ(e.s));
				
				Assert.AreEqual(z0[0],z1[1]);
				Assert.AreNotEqual(z0[4],z1[0]); //node not reused
				Assert.IsTrue(e.e.TestIsAvailableClean);
			}
		}
		
		[Test]
		public void ReuseTemplates()
		{
			var e = new UX.Each.ReuseTemplates();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				var z0 = GetZChildren(e.s);
				Assert.AreEqual("107,6,105,4", GetDudZ(e.s));
				
				e.e.Offset = 2;
				root.StepFrame();
				var z1 = GetZChildren(e.s);
				Assert.AreEqual("105,4,103,2", GetDudZ(e.s));
				
				Assert.AreEqual(z0[3],z1[1]);
				Assert.AreEqual(z0[0],z1[2]);//reuse
				Assert.AreEqual(z0[1],z1[3]);//reuse
				Assert.IsTrue(e.e.TestIsAvailableClean);
			}
		}

		static Visual[] GetZChildren(Visual root)
		{
			var list = new Visual[root.ZOrderChildCount];
			for (int i=0; i < root.ZOrderChildCount; ++i)
				list[i] = root.GetZOrderChild(i);
			return list;
		}
		
		[Test]
		//index() retains the previous value if the item is removed, or rather it doesn't update if there is no value
		public void FunctionRemove()
		{
			var e = new UX.Each.Function.Remove();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
 				root.StepFrameJS();
 				Assert.AreEqual("0-0,1-1,2-2", GetText(e));
 				
 				e.CallReplace.Perform();
 				root.StepFrameJS();
 				//it's not certain if the new element is guaranteed to be in this place
 				Assert.AreEqual("3-0,0-0,1-1,2-2", GetText(e));
 				//Assert.AreEqual("0-0,1-1,2-2,3-0", GetText(e));
			}
		}
		
		[Test]
		//there's no way to test this feature yet
		[Ignore("https://github.com/fusetools/fuselibs/issues/4199")]
		public void FunctionDefault()
		{
			var e = new UX.Each.Function.Default();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
 				root.StepFrame();
 				Assert.AreEqual("0,1,2", GetText(e));
			}
		}
		
		[Test]
		//any node inside the Each will work for lookup
		public void FunctionSearch()
		{
			var e = new UX.Each.Function.Search();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
 				root.StepFrame();
 				Assert.AreEqual("0,1,2", GetRecursiveText(e));
			}
		}
		
		[Test]
		//ensure ordering when items are added/removed at the same time
		public void RemoveAdd()
		{
			var e = new UX.Each.RemoveAdd();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual("0,1,2,3,4,5,6,7,8,9", GetText(e));
				
				e.CallStep1.Perform();
				root.StepFrameJS();
				Assert.AreEqual("0,1,3,a2,a1,5,6,7,8,9", GetText(e));
				
				e.CallStep2.Perform();
				root.StepFrameJS();
				Assert.AreEqual("0,1,3,a2,a1,5,6,b1,8,9", GetText(e));
				
				e.CallStep3.Perform();
				root.StepFrameJS();
				Assert.AreEqual("c2", GetText(e));
			}
		}
		
		[Test]
		public void IdentityKey()
		{
			var e = new UX.Each.IdentityKey();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				var z0 = GetZChildren(e.s);
				Assert.AreEqual("30,20,10", GetDudZ(e.s));
				
				e.CallReplace.Perform();
				root.StepFrameJS();
				var z1 = GetZChildren(e.s);
				Assert.AreEqual("30,21,10",GetDudZ(e.s));
				
				for (int i=0; i < z0.Length; ++i)
					Assert.AreEqual( z0[i], z1[i] );
				Assert.IsTrue(e.e.TestIsAvailableClean);
				
				e.CallReplaceAll.Perform();
				root.StepFrameJS();
				var z2 = GetZChildren(e.s);
				Assert.AreEqual("32,12,22",GetDudZ(e.s));
				
				Assert.AreEqual( z0[0], z2[0] );
				Assert.AreEqual( z0[1], z2[2] );
				Assert.AreEqual( z0[2], z2[1] );
				Assert.IsTrue(e.e.TestIsAvailableClean);
				
				e.CallClear.Perform();
				root.StepFrameJS();
			}
		}
		
		[Test]
		public void IdentityKeyString()
		{
			var e = new UX.Each.IdentityKeyString();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				var z0 = GetZChildren(e.s);
				Assert.AreEqual("three,two,one", GetDudZ(e.s));
				
				e.CallReplace.Perform();
				root.StepFrameJS();
				var z1 = GetZChildren(e.s);
				Assert.AreEqual("three,two,one",GetDudZ(e.s));
				
				for (int i=0; i < z0.Length; ++i)
					Assert.AreEqual( z0[i], z1[i] );
				Assert.IsTrue(e.e.TestIsAvailableClean);
				
				e.CallReplaceAll.Perform();
				root.StepFrameJS();
				var z2 = GetZChildren(e.s);
				Assert.AreEqual("three,one,two",GetDudZ(e.s));
				
				Assert.AreEqual( z0[0], z2[0] );
				Assert.AreEqual( z0[1], z2[2] );
				Assert.AreEqual( z0[2], z2[1] );
				Assert.IsTrue(e.e.TestIsAvailableClean);
				
				e.CallClear.Perform();
				root.StepFrameJS();
			}
		}
		
		[Test]
		public void IdentityKeyOrder()
		{
			var e = new UX.Each.IdentityKeyOrder();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				var z0 = GetZChildren(e.s);
				Assert.AreEqual("50,40,30,20,10", GetDudZ(e.s));
			
				e.CallReplaceAll1.Perform();
				root.StepFrameJS();
				var z1 = GetZChildren(e.s);
				Assert.AreEqual("51,40,31,20,11", GetDudZ(e.s)); //40,20 linger with RemovingAnimation
				
				for (int i=0; i< 5; ++i)
					Assert.AreEqual(z0[i],z1[i]);
				
				//clear up removing ones
				root.StepFrame(1.1f);
				Assert.AreEqual( 3, GetZChildren(e.s).Length );
				Assert.AreEqual("51,31,11", GetDudZ(e.s));
				
				e.CallReplaceAll2.Perform();
				root.StepFrameJS();
				var z2 = GetZChildren(e.s);
				Assert.AreEqual("82,52,72,32,11,62", GetDudZ(e.s)); //11 lingers (...,62,11 is another acceptble order)
				
				Assert.AreEqual(z0[0],z2[1]);
				Assert.AreEqual(z0[2],z2[3]);
				
				//clear up removing ones
				root.StepFrame(1.1f);
				Assert.AreEqual( 5, GetZChildren(e.s).Length );
				Assert.AreEqual("82,52,72,32,62", GetDudZ(e.s));
			}
		}
		
		[Test]
		//ensure templates are updated if a matching object is used. Unfortunately this doesn't actually test
		//the short path in `Instance.TryUpdateAt` is actually called.
		public void ReuseTemplatesReplace()
		{
			var e = new UX.Each.ReuseTemplatesReplace();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				var z0 = GetZChildren(e);
				Assert.AreEqual("140,30,120,10", GetDudZ(e));
				
				e.CallReplace1.Perform();
				root.StepFrameJS();
				var z1 = GetZChildren(e);
				Assert.AreEqual("140,30,121,10", GetDudZ(e));
				Assert.AreEqual(z0[2],z1[2]);
				
				e.CallReplace2.Perform();
				root.StepFrameJS();
				var z2 = GetZChildren(e);
				Assert.AreEqual("140,30,22,10", GetDudZ(e));
				Assert.AreNotEqual(z0[2],z2[2]);
				
				Assert.IsTrue(e.each.TestIsAvailableClean);
			}
		}
		
		[Test]
		//ensure updated observables reflect their data
		public void Observable()
		{
			var e = new UX.Each.Observable();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				var z0 = GetZChildren(e);
				Assert.AreEqual("30,20,10", GetDudZ(e));
				
				e.CallUpdate.Perform();
				root.StepFrameJS();
				var z1 = GetZChildren(e);
				Assert.AreEqual("30,21,10", GetDudZ(e));
				Assert.AreEqual(z0[1], z1[1]);
			}
		}
		
		[Test]
		//catches probelms with not having any templates, or having no matching templates
		public void ZeroTemplates()
		{
			var e = new UX.Each.ZeroTemplates();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				
				Assert.AreEqual( 0, GetZChildren(e.a).Length );
				Assert.AreEqual( 0, GetZChildren(e.b).Length );
			}
		}
		
		[Test]
		public void DefaultTemplates()
		{
			var e = new UX.Each.DefaultTemplates();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual( "Y,X,Y", GetDudZ(e.b) );
				Assert.AreEqual( "A", GetDudZ(e.c));
				Assert.AreEqual( "A", GetDudZ(e.d));
				Assert.AreEqual( "Q", GetDudZ(e.e));
				Assert.AreEqual( "A,A", GetDudZ(e.f));
			}
		}
		
		[Test]
		public void Multiple()
		{
			var e = new UX.Each.Multiple();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				Assert.AreEqual( "1,2,1,2", GetText(e));
			}
		}
		
		[Test]
		//change TemplateSource after rooting
		public void TemplateSource()
		{
			var e=  new UX.Each.TemplateSource();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				Assert.AreEqual( "A", GetDudZ(e.tb));
				
				e.each.TemplateSource = e.tb;
				root.PumpDeferred();
				Assert.AreEqual( "B", GetDudZ(e.tb));
				
				e.each.TemplateSource = e.tc;
				root.PumpDeferred();
				Assert.AreEqual( "C", GetDudZ(e.tb));
				
				e.each.TemplateSource = null;
				root.PumpDeferred();
				Assert.AreEqual( "A", GetDudZ(e.tb));
			}
		}
		
		[Test]
		public void ReplaceWithLess()
		{
			var e = new UX.Each.ReplaceWithLessData();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();

				Assert.AreEqual(3*2+1, e.grid.Children.Count);
				
				e.monthsToMaturitySlider.Value = 12;
				root.StepFrameJS();
				Assert.AreEqual(12*2+1, e.grid.Children.Count);

				e.monthsToMaturitySlider.Value = 100;
				root.StepFrameJS();
				Assert.AreEqual(100*2+1, e.grid.Children.Count);

				e.monthsToMaturitySlider.Value = 200;
				root.StepFrameJS();
				Assert.AreEqual(200*2+1, e.grid.Children.Count);

				e.monthsToMaturitySlider.Value = 50;
				root.StepFrameJS();
				Assert.AreEqual(50*2+1, e.grid.Children.Count);
			}
		}
	}
}
