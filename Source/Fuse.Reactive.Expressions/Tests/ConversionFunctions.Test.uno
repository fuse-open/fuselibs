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
	}
}