using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Testing;

using Fuse.Controls;
using Fuse.Navigation;
using Fuse.Reactive;

using FuseTest;

namespace Fuse.Reactive.Test
{
	public class ExpressionFormatTest : TestBase
	{
		[Test]
		public void NameValuePair()
		{
			var e = new UX.NameValuePair();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual("(boo: False)", e.t.Value);
				e.flip.Perform();
				root.StepFrameJS();
				Assert.AreEqual("(bar: fooTrue)", e.t.Value);
				Assert.AreEqual("123", e.tbar.Value);
				Assert.AreEqual("456", e.tfoo.Value);
			}
		}
		
		[Test]
		[Ignore("https://github.com/fusetools/fuselibs-public/issues/253")]
		public void StringList()
		{
			var e = new UX.ExpressionFormat.StringList();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
			/* Cannot be compiled due to parse error in UX file
				var a = e.a.ArrayValue;
				Assert.AreEqual( 1, a.Length );
				Assert.AreEqual( "one", a[0] );
				
				var b = e.b.ArrayValue;
				Assert.AreEqual( 2, b.Length );
				Assert.AreEqual( "one", b[0] );
				Assert.AreEqual( "two", b[0] );
			*/
			}
		}
		
		[Test]
		public void JoinList()
		{
			var e = new UX.ExpressionFormat.JoinList();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				Assert.AreEqual( "#2=one,two", e.a.ObjectValue );
				Assert.AreEqual( "#2=one,two", e.b.StringValue );
				
				var a = e.c.ArrayValue;
				Assert.AreEqual( 2, a.Length );
				Assert.AreEqual( "#0=", a[0] );
				Assert.AreEqual( "#2=a,b", a[1] );
			}
		}
		
		[Test]
		[Ignore("https://github.com/fusetools/fuselibs-public/issues/253")]
		public void JoinListArray()
		{
			var e = new UX.ExpressionFormat.JoinListArray();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				var a = e.d.ArrayValue;
				Assert.AreEqual( 1, a.Length );
				Assert.AreEqual( "#2=a,b", a[0] );
			}
		}
	}
}

namespace FuseTest
{
	[UXFunction("testJoin")]
	public class TestJoin : SimpleVarArgFunction
	{
		protected override void OnNewArguments( Argument[] args, IListener listener )
		{
			var q = "#" + args.Length + "=";
			for (int i=0; i < args.Length; ++i)
			{
				if (i > 0)
					q = q + ",";
				q = q + args[i].Value;
			}
			listener.OnNewData(this, q);
		}
	}
}
