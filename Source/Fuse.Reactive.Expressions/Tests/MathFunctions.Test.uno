using Uno;
using Uno.UX;
using Uno.Testing;

using FuseTest;

namespace Fuse.Reactive.Test
{
	public class MathFunctionsTest : TestBase
	{
		[Test]
		public void Mod()
		{
			var p = new UX.MathFunctions.Mod();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(1, p.c.Integer);

				p.b.Float = 3.5f;
				root.PumpDeferred();
				Assert.AreEqual(3.0f, p.c.Float);

				p.a.Float = -9.5f;
				root.PumpDeferred();
				Assert.AreEqual(1f, p.c.Float);

				p.b.Float = -3f;
				root.PumpDeferred();
				Assert.AreEqual(-0.5f, p.c.Float);
			}
		}

		[Test]
		public void EvenOdd()
		{
			var p = new UX.MathFunctions.EvenOdd();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.IsTrue(p.b.Boolean);
				Assert.IsFalse(p.c.Boolean);

				p.a.Integer = -3;
				root.PumpDeferred();
				Assert.IsFalse(p.b.Boolean);
				Assert.IsTrue(p.c.Boolean);

				p.a.Float = 2.6f; //rounds to 3
				root.PumpDeferred();
				Assert.IsFalse(p.b.Boolean);
				Assert.IsTrue(p.c.Boolean);

				p.a.Float = -2.3f; //rounds to -2
				root.PumpDeferred();
				Assert.IsTrue(p.b.Boolean);
				Assert.IsFalse(p.c.Boolean);
			}
		}

		[Test]
		public void Alternate()
		{
			var p = new UX.MathFunctions.Alternate();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.IsFalse(p.b.Boolean);

				var ts = new[]{ -6, -5, -4, 0, 1, 2, 6 };
				var fs = new[]{ -7, -3, -2, -1, 3, 4, 5 };
				for (int i=0; i < ts.Length; ++i)
				{
					p.a.Integer = ts[i];
					root.PumpDeferred();
					Assert.IsTrue(p.b.Boolean);
					p.a.Integer = fs[i];
					root.PumpDeferred();
					Assert.IsFalse(p.b.Boolean);
				}
			}
		}

		[Test]
		public void Simple()
		{
			var p = new UX.MathFunctions.Simple();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				var values = new[]{ 1.0f, 0.5f, 0.0f, -0.55f, 0.7f, -0.4f };
				for (int i=0; i < values.Length; ++i)
				{
					var v = values[i];
					//first time comes from 1.0 value in the UX on rooting
					if (i !=0)
					{
						p.a.Float = v;
						root.PumpDeferred();
					}
					Assert.AreEqual( Math.Sin(v), p.sin.Float );
					Assert.AreEqual( Math.Cos(v), p.cos.Float );
					Assert.AreEqual( Math.Tan(v), p.tan.Float );
					Assert.AreEqual( Math.Asin(v), p.asin.Float );
					Assert.AreEqual( Math.Acos(v), p.acos.Float );
					Assert.AreEqual( Math.Atan(v), p.atan.Float );
					Assert.AreEqual( Math.Abs(v), p.abs.Float );
					Assert.AreEqual( Math.Ceil(v), p.ceil.Float );
					Assert.AreEqual( Math.Floor(v), p.floor.Float );
					Assert.AreEqual( Math.DegreesToRadians(v), p.degreesToRadians.Float );
					Assert.AreEqual( Math.RadiansToDegrees(v), p.radiansToDegrees.Float );
					Assert.AreEqual( Math.Exp(v), p.exp.Float );
					Assert.AreEqual( Math.Exp2(v), p.exp2.Float );
					Assert.AreEqual( Math.Fract(v), p.fract.Float );
					Assert.AreEqual( Math.Sign(v), p.sign.Float );
					Assert.AreEqual( Math.Floor(v + 0.5f), p.round.Float );
					Assert.AreEqual( Trunc.Op(v), p.trunc.Float );
					//some have special exceptions where the Inf/NaN value doesn't compare right on some platforms
					if (v > 0)
					{
						Assert.AreEqual( Math.Log(v), p.log.Float );
						Assert.AreEqual( Math.Log2(v), p.log2.Float );
					}
					if (v >= 0)
					{
						Assert.AreEqual( Math.Sqrt(v), p.sqrt.Float );
						Assert.AreEqual( Math.Pow(v,0.5f), p.pow.Float);
					}

					Assert.AreEqual( Math.Atan2(v,0.5f), p.atan2.Float);
				}
			}
		}

		[Test]
		public void TruncOp()
		{
			Assert.AreEqual(0, Trunc.Op(0.5));
			Assert.AreEqual(0, Trunc.Op(-0.7));
			Assert.AreEqual(5, Trunc.Op(5.9));
			Assert.AreEqual(-110, Trunc.Op(-110.7));
		}

		[Test]
		public void Vector()
		{
			var p = new UX.MathFunctions.Vector();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				var values = new[]{ float4(1,2,3,4) };
				for (int i=0; i < values.Length; ++i)
				{
					var v = values[i];
					//first time comes from 1.0 value in the UX on rooting
					if (i !=0)
					{
						p.a.Float4 = v;
						root.PumpDeferred();
					}
					Assert.AreEqual( Math.Sin(v), p.sin.Float4 );
					Assert.IsTrue( p.sin.Object is float4 );

					p.a.Float3 = v.YZW;
					root.PumpDeferred();
					Assert.AreEqual( Math.Sin(v.YZW), p.sin.Float3 );
					//special assignment is needed in test since assing to `Object` converts to a SolidColor :/
					Assert.AreEqual( Math.Sin(v.YZW), p.sin3.Float3 );
					Assert.IsTrue( p.sin3.Object is float3 );

					p.a.Float2 = v.XW;
					root.PumpDeferred();
					Assert.AreEqual( Math.Sin(v.XW), p.sin.Float2 );
					Assert.AreEqual( Math.Sin(v.XW), p.sin2.Float2 );
					Assert.IsTrue( p.sin2.Object is float2 );
				}
			}
		}

		[Test]
		public void Lerp()
		{
			var p = new UX.MathFunctions.Lerp();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				p.t.Float = 0.5f;
				p.a.Float = 10;
				p.b.Float = 20;
				root.PumpDeferred();
				Assert.AreEqual(15, p.lerp.Float);

				p.a.Float2 = float2(0,10);
				p.b.Float2 = float2(10,0);
				root.PumpDeferred();
				Assert.AreEqual(float2(5), p.lerp.Float2);

				p.a.Float3 = float3(1,0,10);
				p.b.Float3 = float3(1,10,0);
				root.PumpDeferred();
				Assert.AreEqual(float3(1,5,5), p.lerp.Float3);

				p.a.Float4 = float4(1,0,50,10);
				p.b.Float4 = float4(1,10,100,0);
				root.PumpDeferred();
				Assert.AreEqual(float4(1,5,75,5), p.lerp.Float4);
			}
		}

		[Test]
		public void Clamp()
		{
			var p = new UX.MathFunctions.Clamp();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				p.a.Value = 0.5f;
				p.mn.Value = 10;
				p.mx.Value = 20;
				root.PumpDeferred();
				Assert.AreEqual(10, p.clamp.Float);

				p.a.Value = float2(0,15);
				root.PumpDeferred();
				Assert.AreEqual(float2(10,15), p.clamp.Float2);

				p.a.Value = float3(21,0,8);
				root.PumpDeferred();
				Assert.AreEqual(float3(20,10,10), p.clamp.Float3);

				p.a.Value = float4(1,0,50,15);
				root.PumpDeferred();
				Assert.AreEqual(float4(10,10,20,15), p.clamp.Float4);
			}
		}

		[Test]
		public void Add()
		{
			var p = new UX.MathFunctions.Add();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( 13.0, p.c.Object ); //this is expecting a double
				Assert.AreEqual( float2(13,27), p.c2.Object );
				Assert.AreEqual( float3(13,27,35), p.c3.Object );
				Assert.AreEqual( float4(13,27,35,46), p.c4.Object );
			}
		}

		[Test]
		public void Negate()
		{
			var p = new UX.MathFunctions.Negate();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( -10.0, p.b.Object ); //this is expecting a double
				Assert.AreEqual( 20.0, p.b2.Object );
			}
		}

		[Test]
		//functions where the conversion was being handled by the Marshal class. This is just a base sanity check
		public void MarshalFunctions()
		{
			var p = new UX.MathFunctions.MarshalFunctions();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( float2(13,27), p.add.Object );
				Assert.AreEqual( float2(7,13), p.sub.Object );
				Assert.AreEqual( float2(30,140), p.mul.Object );
				Assert.AreEqual( float2(10f/3, 20f/7), p.div.Object );

				Assert.AreEqual( 5.0, p.min.Object );
				Assert.AreEqual( 10.0, p.max.Object );

				Assert.AreEqual( false, p.lt.Object );
				Assert.AreEqual( true, p.gt.Object );
				Assert.AreEqual( false, p.lte.Object );
				Assert.AreEqual( true, p.gte.Object );
				Assert.AreEqual( false, p.eq.Object );
				Assert.AreEqual( true, p.neq.Object );

				Assert.AreEqual( false, p.and.Object );
				Assert.AreEqual( true, p.or.Object );
			}
		}

	}
}
