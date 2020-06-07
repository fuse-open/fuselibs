using Uno;
using Uno.UX;
using Uno.Testing;

using FuseTest;

namespace Fuse.Reactive.Test
{
	public class UnaryOperatorTest : TestBase
	{
		[Test]
		//tests the deprecated functionality, since it's weird, and not covered by normal unary tests
		public void Deprecated()
		{
			using (var dg = new RecordDiagnosticGuard())
			{
				var p = new UX.UnaryOperator.Deprecated();
				using (var root = TestRootPanel.CreateWithChild(p))
				{
					Assert.AreEqual( "abc", p.d1.ObjectValue);

					p.a.Value = null;
					root.PumpDeferred();
					Assert.AreEqual( "lost", p.d1.ObjectValue);
					Assert.AreEqual( "null", p.d2.ObjectValue);

					var msgs = dg.DequeueAll();
					Assert.IsTrue(msgs.Count > 0);
					for (int i=0; i < msgs.Count; ++i)
						Assert.IsTrue( msgs[i].Message.IndexOf( "deprecated" ) != -1);
				}
			}
		}

		public void Basic()
		{
			var p = new UX.UnaryOperator.Basic();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "[ab]", p.a.StringValue);
				Assert.AreEqual( "x", p.b.StringValue);
				Assert.AreEqual( "[hi]", p.c.StringValue);

				Assert.AreEqual(true, p.d.BoolValue);
				Assert.AreEqual(false, p.e.BoolValue);
				Assert.AreEqual(false, p.f.BoolValue);
				Assert.AreEqual(true, p.g.BoolValue);
			}
		}
	}

	[UXFunction("_unDep")]
	class UnDep : UnaryOperator
	{
		[UXConstructor]
		public UnDep([UXParameter("Operand")] Expression op) : base(op)
		{}

		protected override void OnNewOperand(IListener listener, object operand)
		{
			if (operand != null)
				listener.OnNewData(this, operand);
			else
				listener.OnNewData(this, "null");
		}

		protected override void OnLostOperand(IListener listener)
		{
			listener.OnNewData(this, "lost");
		}
	}


	[UXFunction("_unJoin")]
	class UnJoin : UnaryOperator
	{
		[UXConstructor]
		public UnJoin([UXParameter("Operand")] Expression operand)
			: base(operand, "_unJoin")
		{}

		protected override bool TryCompute(object op, out object result)
		{
			result = "[" + op.ToString() + "]";
			return true;
		}
	}

}
