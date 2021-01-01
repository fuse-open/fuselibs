using Uno;
using Uno.UX;
using Uno.Testing;

using FuseTest;

namespace Fuse.Reactive.Test
{
	/**
		BinaryOperator is part of the Uno-level API, this tries to cover the intended high-level functionality.
	*/
	public class BinaryOperatorTest : TestBase
	{
		[Test]
		public void Basic()
		{
			var p = new UX.BinaryOperator.Basic();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "abcd", p.a.StringValue);
				Assert.AreEqual( null, p.b.ObjectValue );
				Assert.AreEqual( null, p.c.ObjectValue );
				Assert.AreEqual( "*", p.d.StringValue );
				Assert.AreEqual( "++", p.e.StringValue );

				p.strct.Value = p.strctData1.Value;
				root.PumpDeferred();
				Assert.AreEqual( null, p.c.ObjectValue );
				Assert.AreEqual( "x+", p.d.StringValue );
				Assert.AreEqual( "x+", p.e.StringValue );

				p.strct.Value = p.strctData2.Value;
				root.PumpDeferred();
				Assert.AreEqual( null, p.c.ObjectValue );
				Assert.AreEqual( "*", p.d.StringValue );
				Assert.AreEqual( "+y", p.e.StringValue );

				p.strct.Value = p.strctData3.Value;
				root.PumpDeferred();
				Assert.AreEqual( "xy", p.c.StringValue );
				Assert.AreEqual( "xy", p.d.StringValue );
				Assert.AreEqual( "xy", p.e.StringValue );
			}
		}

		[Test]
		public void Error()
		{
			var p = new UX.BinaryOperator.Error();
			using (var dg = new RecordDiagnosticGuard())
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.IsFalse( p.iq.BoolValue );

				p.b.Value = "triggerBad";
				root.PumpDeferred();

				var d = dg.DequeueAll();
				Assert.IsTrue( d.Count == 1 || d.Count == 2 ); //TODO: there is a double OnNewData somewhere, not relevant to this feature though!
				Assert.Contains( "Failed to compute", d[0].Message );

				Assert.IsFalse( p.iq.BoolValue );

				p.b.Value = 2;
				root.PumpDeferred();
				Assert.IsTrue( p.iq.BoolValue );
				Assert.AreEqual( "12", p.q.StringValue );
			}
		}
	}

	[UXFunction("_binJoin")]
	class BinJoin : BinaryOperator
	{
		[UXConstructor]
		public BinJoin([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right)
			: base(left, right, Flags.None)
		{}

		protected BinJoin([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right,
			Flags flags)
			: base(left, right, flags)
		{}

		protected override bool TryCompute(object left, object right, out object result)
		{
			//for Error test
			if (right == "triggerBad")
			{
				result = null;
				return false;
			}

			result = left.ToString() + right.ToString();
			return true;
		}
	}

	[UXFunction("_binJoinR")]
	class BinJoinR : BinaryOperator
	{
		[UXConstructor]
		public BinJoinR([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right)
			: base(left, right, Flags.Optional1)
		{}

		protected override bool TryCompute(object left, object right, out object result)
		{
			result = left.ToString() + (right == null ? "+" : right.ToString());
			return true;
		}
	}

	[UXFunction("_binJoinLR")]
	class BinJoinLR : BinaryOperator
	{
		[UXConstructor]
		public BinJoinLR([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right)
			: base(left, right, Flags.Optional0 | Flags.Optional1)
		{}

		protected override bool TryCompute(object left, object right, out object result)
		{
			result = (left == null ? "+" : left.ToString()) + (right == null ? "+" : right.ToString());
			return true;
		}
	}
}
