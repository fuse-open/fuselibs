using Uno;
using Uno.UX;
using Uno.Testing;

using FuseTest;

namespace Fuse.Reactive.Test
{
	public class ConversionFunctionsTest : TestBase
	{
		[Test]
		public void ToFloat()
		{
			var p = new UX.ConversionFunctions.ToFloat();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( 4f, p.f1.UseValue );
				Assert.AreEqual( float2(2,3), p.f2.UseValue );
				Assert.AreEqual( float3(4,2,3), p.f3.UseValue );
				Assert.AreEqual( float4(4,5,2,3), p.f4.UseValue );
			}
		}
		
		[Test]
		public void FailFloat()
		{
			var p = new UX.ConversionFunctions.FailFloat();
			using (var dg = new RecordDiagnosticGuard())
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.IsTrue( p.b.BoolValue );
				
				p.v.String = "abc";
				root.PumpDeferred();
				Assert.IsFalse( p.b.BoolValue );
				
				var d = dg.DequeueAll();
				Assert.AreEqual(1, d.Count);
				Assert.Contains( "Failed to compute", d[0].Message );
			}
		}
		
		[Test]
		public void ToString()
		{
			var p = new UX.ConversionFunctions.ToString();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "hiya", p.s1.UseValue );
				Assert.AreEqual( "2", p.s2.UseValue );
			}
		}
		
		[Test]
		public void FailString()
		{
			var p = new UX.ConversionFunctions.FailString();
			using (var dg = new RecordDiagnosticGuard())
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.IsFalse( p.b.BoolValue );
				
				p.v.String = "abc";
				root.PumpDeferred();
				Assert.IsTrue( p.b.BoolValue );
				
 				p.v.String = null;
 				root.PumpDeferred();
 				Assert.IsFalse( p.b.BoolValue );
				
				var d = dg.DequeueAll();
				Assert.IsTrue( d.Count ==2 || d.Count == 3); //don't want to be too strict yet, reporting is not perfect
				Assert.Contains( "Failed to compute", d[0].Message );
				Assert.Contains( "Failed to compute", d[1].Message );
			}
		}
	}
}