using Uno;
using Uno.Testing;
using Uno.UX;

using Fuse;

using FuseTest;

namespace Fuse.Test
{
	public class LetTest : TestBase
	{
		[Test]
		public void Explicit()
		{
			var p = new UX.Let.Explicit();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(2, p.d.Value);
				Assert.AreEqual(2, p.e.Value);
				Assert.AreEqual(7, p.f.Value);
				Assert.AreEqual(7, p.g.Value);
				
				p.a.Value = 3;
				root.PumpDeferred();
				Assert.AreEqual(3, p.d.Value);
				Assert.AreEqual(3, p.e.Value);
				
				p.set.Pulse();
				root.StepFrame();
				Assert.AreEqual(4, p.d.Value);
				Assert.AreEqual(4, p.e.Value);
			}
		}
		
		[Test]
		public void SimpleBind()
		{
			var p = new UX.Let.SimpleBind();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(51, p.d.Value);
				
				p.slider.Value = 3;
				root.PumpDeferred();
				Assert.AreEqual(4, p.d.Value);
			}
		}

		[Test]
		//tests interactions with JS Observable (ensures they are passed-thru/handled naturally)
		public void Observable()
		{
			var p = new UX.Let.Observable();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				
				Assert.AreEqual(2, p.d.Value);
				Assert.AreEqual(2, p.dp.Value);
				Assert.AreEqual("3,2,1", GetDudZ(p.e));
				Assert.AreEqual("3,2,1", GetDudZ(p.ep));
				
				p.callStep1.Perform();
				root.StepFrameJS();
				Assert.AreEqual(3, p.d.Value);
				Assert.AreEqual(3, p.dp.Value);
				Assert.AreEqual("4,3,2,1", GetDudZ(p.e));
				Assert.AreEqual("4,3,2,1", GetDudZ(p.ep));
			}
		}
		
		[Test]
		public void TwoWayProperty()
		{
			var p = new UX.Let.TwoWayProperty();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "init", p.inner.t.Value );
				Assert.AreEqual( "init", p.inner.pt.Value );
				Assert.AreEqual( "init", p.inner.lTitle.Value );
				Assert.AreEqual( "init", p.inner.title );
				
				p.inner.set.Pulse();
				root.StepFrame();
				Assert.AreEqual( "flip", p.inner.t.Value );
				Assert.AreEqual( "flip", p.inner.pt.Value );
				Assert.AreEqual( "flip", p.inner.lTitle.Value );
				Assert.AreEqual( "flip", p.inner.title );
			}
		}
		
		[Test]
		[Ignore("https://github.com/fuse-open/fuselibs/issues/740")]
		public void Array()
		{
			var p = new UX.Let.Array();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "5,4,3,2,1", GetDudZ(p));
			}
		}
		
		[Test]
		public void ExpressionChain()
		{
			var p = new UX.Let.ExpressionChain();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( 5, p.oc.Value );
				
				p.set.Pulse();
				root.StepFrame();
				Assert.AreEqual( 7, p.oc.Value );
			}
		}
		
		[Test]
		public void Null()
		{
			var p = new UX.Let.Null();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( false, p.ha.BoolValue );
				Assert.AreEqual( false, p.hb.BoolValue );
				Assert.AreEqual( true, p.hc.BoolValue ); //can't be undefiend due to `Property` binding
				Assert.AreEqual( false, p.hd.BoolValue );
				
				p.d.Value = null;
				p.nl.Value = p.nb.Value;
				root.PumpDeferred();
				Assert.AreEqual( true, p.ha.BoolValue );
				Assert.AreEqual( true, p.hc.BoolValue );
				Assert.AreEqual( true, p.hd.BoolValue );
			}
		}
		
		[Test]
		//tests many of the expected binding scenarios for Let...
		public void Float()
		{
			var p = new UX.Let.Float();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( 2, p.ao.Value );
				Assert.AreEqual( 2, p.bo.Value );
				
				p.wt.Value = true;
				root.StepFrame();
				Assert.AreEqual( 5, p.ao.Value );
				Assert.AreEqual( 5, p.bo.Value );
				
				p.wt.Value = false;
				root.StepFrame();
				Assert.AreEqual( 2, p.ao.Value );
				Assert.AreEqual( 2, p.bo.Value );
				
				p.tl.PulseForward();
				root.StepFrame();
				Assert.AreEqual( 3, p.ao.Value );
				Assert.AreEqual( 3, p.bo.Value );
				
				//slider binding
				for (int i=0; i < 3; ++i)
				{
					Assert.AreEqual( 50 + i, p.sl.Value );
					Assert.AreEqual( 50 + i, p.sv.Value );
					p.sl.Value = -10 + i;
					root.PumpDeferred();
					Assert.AreEqual( -10 + i, p.sv.Value );
					Assert.AreEqual( -10 + i, p.sl.Value );
					
					p.sv.Value = 50 + (i+1);
					root.PumpDeferred();
				}
			}
		}
		
		[Test]
		public void String()
		{
			var p = new UX.Let.String();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "abc", p.ta.Value );
				Assert.AreEqual( "*", p.dn.StringValue );
				Assert.AreEqual( "", p.de.StringValue );
				
				p.ta.Value = "def";
				root.PumpDeferred();
				Assert.AreEqual( "def", p.a.Value );
				
			}
		}
		
		[Test]
		public void Float2()
		{
			var p = new UX.Let.Float2();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( float2(10,20), p.rc.Value );
				Assert.AreEqual( float2(10,20), p.b.Value );
				Assert.AreEqual( float2(10,20), p.db.ObjectValue );
				
				p.rc.Value = float2(-10,5);
				root.PumpDeferred();
				Assert.AreEqual( float2(-10,5), p.a.Value );
				Assert.AreEqual( float2(-10,5), p.b.Value );
				Assert.AreEqual( float2(-10,5), p.db.ObjectValue );
			}
		}
		
		[Test]
		public void Float3()
		{
			var p = new UX.Let.Float3();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( float3(10,20,30), p.c.Value );
				Assert.AreEqual( float3(10,20,30), p.b.Value );
				Assert.AreEqual( float3(10,20,30), p.db.ObjectValue );
				
				p.c.Value = float3(-10,5,1);
				root.PumpDeferred();
				Assert.AreEqual( float3(-10,5,1), p.a.Value );
				Assert.AreEqual( float3(-10,5,1), p.b.Value );
				Assert.AreEqual( float3(-10,5,1), p.db.ObjectValue );
			}
		}
		
		[Test]
		public void Float4()
		{
			var p = new UX.Let.Float4();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( float4(10,20,30,40), p.c.Value );
				Assert.AreEqual( float4(10,20,30,40), p.b.Value );
				Assert.AreEqual( float4(10,20,30,40), p.db.ObjectValue );
				
				p.c.Value = float4(-10,5,0,1);
				root.PumpDeferred();
				Assert.AreEqual( float4(-10,5,0,1), p.a.Value );
				Assert.AreEqual( float4(-10,5,0,1), p.b.Value );
				Assert.AreEqual( float4(-10,5,0,1), p.db.ObjectValue );
			}
		}
		
		[Test]
		public void Bool()
		{
			var p = new UX.Let.Bool();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(false, p.da.BoolValue);
				Assert.AreEqual(false, p.t.Value);
				Assert.AreEqual("f", p.ds.StringValue);
				
				p.t.Value = true;
				root.PumpDeferred();
				Assert.AreEqual(true, p.da.BoolValue);
				Assert.AreEqual(true, p.a.Value);
				Assert.AreEqual("t", p.ds.StringValue);
			}
		}
		
		[Test]
		public void Size()
		{
			var p = new UX.Let.Size();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( new Size(10, Unit.Unspecified), p.p.X );
				Assert.AreEqual( new Size(20, Unit.Percent), p.p.Y );
				Assert.AreEqual( new Size2( new Size(10, Unit.Unspecified), new Size(20,Unit.Percent)), p.p.Offset );
			}
		}
		
		[Test]
		//an overly complex chain of conversions and types
		public void Conversion()
		{
			var p = new UX.Let.Conversion();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				//TODO: Once the "size" function is merged from https://github.com/fuse-open/fuselibs/pull/905
				//Assert.AreEqual( new Size2( new Size(20, Unit.Percent), new Size(30,Unit.Percent)), p.p1.Offset );
				Assert.AreEqual( new Size2( new Size(10, Unit.Unspecified), new Size(20,Unit.Points)), p.p2.Offset );
			}
		}
		
		[Test]
		//ensures the LetType works with ux:Property (as Let does)
		public void Property()
		{
			var p = new UX.Let.Property();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "title", p.lp.sc.Value );
				Assert.AreEqual( float2(10,20), p.lp.rc.Value );
				
				p.lp.sc.Value = "bye";
				p.lp.rc.Value = float2(5,10);
				root.PumpDeferred();
				Assert.AreEqual( "bye", p.ss.Value );
				Assert.AreEqual( float2(5,10), p.sf2.Value );
			}
		}
	}
}
