using Uno;
using Uno.UX;
using Uno.Testing;

using FuseTest;

namespace Fuse.Reactive.Test
{
	/**
		QuaternaryOperator is part of the Uno-level API, this tries to cover the intended high-level functionality.
	*/
	public class QuaternaryOperatorTest : TestBase
	{
		[Test]
		public void Basic()
		{
			var p = new UX.QuaternaryOperator.Basic();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "nope", p.a.ObjectValue );
				Assert.AreEqual( "nope", p.b.ObjectValue );
				Assert.AreEqual( "nope", p.c.ObjectValue );
				Assert.AreEqual( "nope", p.d.ObjectValue );
				Assert.AreEqual( "nope", p.e.ObjectValue );
				
				p.strct.Value = p.strctData1.Value;
				root.PumpDeferred();
				Assert.AreEqual( "nope", p.a.ObjectValue );
				Assert.AreEqual( "nope", p.b.ObjectValue );
				Assert.AreEqual( "nope", p.c.ObjectValue );
				Assert.AreEqual( "nope", p.d.ObjectValue );
				Assert.AreEqual( "xyz*", p.e.ObjectValue );
				
				p.strct.Value = p.strctData2.Value;
				root.PumpDeferred();
				Assert.AreEqual( "nope", p.a.ObjectValue );
				Assert.AreEqual( "nope", p.b.ObjectValue );
				Assert.AreEqual( "nope", p.c.ObjectValue );
				Assert.AreEqual( "xy*w", p.d.ObjectValue );
				Assert.AreEqual( "nope", p.e.ObjectValue );
				
				p.strct.Value = p.strctData3.Value;
				root.PumpDeferred();
				Assert.AreEqual( "nope", p.a.ObjectValue );
				Assert.AreEqual( "nope", p.b.ObjectValue );
				Assert.AreEqual( "x*zw", p.c.ObjectValue );
				Assert.AreEqual( "nope", p.d.ObjectValue );
				Assert.AreEqual( "nope", p.e.ObjectValue );
				
				p.strct.Value = p.strctData4.Value;
				root.PumpDeferred();
				Assert.AreEqual( "nope", p.a.ObjectValue );
				Assert.AreEqual( "*yzw", p.b.ObjectValue );
				Assert.AreEqual( "nope", p.c.ObjectValue );
				Assert.AreEqual( "nope", p.d.ObjectValue );
				Assert.AreEqual( "nope", p.e.ObjectValue );
				
				p.strct.Value = p.strctData5.Value;
				root.PumpDeferred();
				Assert.AreEqual( "xyzw", p.a.ObjectValue );
				Assert.AreEqual( "xyzw", p.b.ObjectValue );
				Assert.AreEqual( "xyzw", p.c.ObjectValue );
				Assert.AreEqual( "xyzw", p.d.ObjectValue );
				Assert.AreEqual( "xyzw", p.e.ObjectValue );
			}
		}
	}
	
	[UXFunction("_quaJoin")]
	class QuaJoin : QuaternaryOperator
	{
		[UXConstructor]
		public QuaJoin([UXParameter("First")] Expression first, [UXParameter("Second")] Expression second,
			[UXParameter("Third")] Expression third, [UXParameter("Fourth")] Expression fourth)
			: base(first, second, third, fourth)
		{}
			
		protected override object Compute(object first, object second, object third, object fourth)
		{
			return (first == null ? "*" : first.ToString()) +
				(second == null ? "*" : second.ToString()) +
				(third == null ? "*" : third.ToString()) +
				(fourth == null ? "*" : fourth.ToString());
		}
	}
	
	[UXFunction("_quaJoin1")]
	class QuaJoin1 : QuaJoin
	{
		[UXConstructor]
		public QuaJoin1([UXParameter("First")] Expression first, [UXParameter("Second")] Expression second,
			[UXParameter("Third")] Expression third, [UXParameter("Fourth")] Expression fourth)
			: base(first, second, third, fourth)
		{}
			
		protected override bool IsFirstOptional { get { return true; } }
	}
	
	[UXFunction("_quaJoin2")]
	class QuaJoin2 : QuaJoin
	{
		[UXConstructor]
		public QuaJoin2([UXParameter("First")] Expression first, [UXParameter("Second")] Expression second,
			[UXParameter("Third")] Expression third, [UXParameter("Fourth")] Expression fourth)
			: base(first, second, third, fourth)
		{}
			
		protected override bool IsSecondOptional { get { return true; } }
	}

	[UXFunction("_quaJoin3")]
	class QuaJoin3 : QuaJoin
	{
		[UXConstructor]
		public QuaJoin3([UXParameter("First")] Expression first, [UXParameter("Second")] Expression second,
			[UXParameter("Third")] Expression third, [UXParameter("Fourth")] Expression fourth)
			: base(first, second, third, fourth)
		{}
			
		protected override bool IsThirdOptional { get { return true; } }
	}

	[UXFunction("_quaJoin4")]
	class QuaJoin4 : QuaJoin
	{
		[UXConstructor]
		public QuaJoin4([UXParameter("First")] Expression first, [UXParameter("Second")] Expression second,
			[UXParameter("Third")] Expression third, [UXParameter("Fourth")] Expression fourth)
			: base(first, second, third, fourth)
		{}
			
		protected override bool IsFourthOptional { get { return true; } }
	}
}
