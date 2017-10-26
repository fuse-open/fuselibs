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
	}
	
	[UXFunction("_binJoin")]
	class BinJoin : BinaryOperator
	{
		[UXConstructor]
		public BinJoin([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right)
			: base(left, right)
		{}
			
		protected override object Compute(object left, object right)
		{
			return left.ToString() + right.ToString();
		}
	}
	
	[UXFunction("_binJoinR")]
	class BinJoinR : BinaryOperator
	{
		[UXConstructor]
		public BinJoinR([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right)
			: base(left, right)
		{}
			
		protected override bool IsRightOptional { get { return true; } }
		
		protected override object Compute(object left, object right)
		{
			return left.ToString() + (right == null ? "+" : right.ToString());
		}
	}
	
	[UXFunction("_binJoinLR")]
	class BinJoinLR : BinaryOperator
	{
		[UXConstructor]
		public BinJoinLR([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right)
			: base(left, right)
		{}
			
		protected override bool IsLeftOptional { get { return true; } }
		protected override bool IsRightOptional { get { return true; } }
		
		protected override object Compute(object left, object right)
		{
			return (left == null ? "+" : left.ToString()) + (right == null ? "+" : right.ToString());
		}
		
		protected override void OnLostOperands(IListener listener)
		{
			Fuse.Diagnostics.InternalError( "shouldn't happen since both are optional" );
		}
	}
}
