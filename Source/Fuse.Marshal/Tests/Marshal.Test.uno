using Uno;
using Uno.UX;
using Uno.Diagnostics;
using Uno.Testing;
using Uno.Collections;
using Uno.Testing;
using FuseTest;

namespace Fuse
{
	enum FooEnum
	{
		Bar,
		Foo
	}

	class A
	{
	}

	class B : A
	{
	}

	public class MarshalTests: TestBase
	{
		public void MarshalToSizeWithGarbage()
		{
			Marshal.ToSize("13@pt");
		}

		[Test]
		public void TryConvertToTest()
		{
			object res;

			using (var dg = new RecordDiagnosticGuard())
			{
				Assert.AreEqual(false, Marshal.TryConvertTo(typeof(double), false, out res, this));
				Assert.AreEqual(true, Marshal.TryConvertTo(typeof(string), false, out res, null));  // becomes "false"
				Assert.AreEqual(true, Marshal.TryConvertTo(typeof(Selector), false, out res, null)); // becomes new Selector("false")
				Assert.AreEqual(false, Marshal.TryConvertTo(typeof(float), false, out res, null));
				Assert.AreEqual(false, Marshal.TryConvertTo(typeof(int), false, out res, null));
				Assert.AreEqual(true, Marshal.TryConvertTo(typeof(bool), false, out res, this));
				Assert.AreEqual(false, (bool)res);
				Assert.AreEqual(false, Marshal.TryConvertTo(typeof(Size), false, out res, this));
				Assert.AreEqual(false, Marshal.TryConvertTo(typeof(Size2), false, out res, null));
				Assert.AreEqual(false, Marshal.TryConvertTo(typeof(float2), false, out res, null));
				Assert.AreEqual(true, Marshal.TryConvertTo(typeof(float3), 3.0, out res, null));
				Assert.AreEqual(float3(3,3,3), (float3)res);
				Assert.AreEqual(false, Marshal.TryConvertTo(typeof(float4), false, out res, null));
				Assert.AreEqual(true, Marshal.TryConvertTo(typeof(FooEnum), "Foo", out res, null));
				Assert.AreEqual(FooEnum.Foo, (FooEnum)res);
				Assert.AreEqual(true, Marshal.TryConvertTo(typeof(DateTime), DateTime.UtcNow, out res, null)); // validates that an instance of a type that the marshal doesn't know about can be converted to itself
				Assert.AreEqual(true, Marshal.TryConvertTo(typeof(A), new B(), out res, null)); // validates that an instance of a type that the marshal doesn't know about can be converted to a base class

				var diagnostics = dg.DequeueAll();
				Assert.AreEqual(2, diagnostics.Count);
				Assert.AreEqual(DiagnosticType.UserError, diagnostics[0].Type);
				Assert.AreEqual(this, diagnostics[0].SourceObject);
				Assert.AreEqual(DiagnosticType.UserError, diagnostics[1].Type);
				Assert.AreEqual(this, diagnostics[1].SourceObject);
			}
		}

		[Test]
		public void SizeParserTest()
		{
			Assert.AreEqual((Size)1337.0f, Marshal.ToSize("1337.00"));
			Assert.AreEqual(Size.Percent(13.37f), Marshal.ToSize("13.3700% "));
			Assert.AreEqual(Size.Points(13.37f), Marshal.ToSize("13.3700pt"));
			Assert.AreEqual(Size.Points(13), Marshal.ToSize("  13pt"));
			Assert.AreEqual(Size.Pixels(13.23f), Marshal.ToSize("13.2300px  "));
			Assert.AreEqual(new Size2(Size.Pixels(13.23f), Size.Percent(55.6f)), Marshal.ToSize2("13.2300px, 55.60%"));
			Assert.AreEqual(new Size2(Size.Pixels(13.23f), Size.Pixels(13.23f)), Marshal.ToSize2("13.2300px"));
			Assert.AreEqual(new Size2((Size)1.0f, (Size)1.0f), Marshal.ToSize2("1"));
			Assert.Throws<MarshalException>(MarshalToSizeWithGarbage);
		}

		[Test]
		public void OperatorTest()
		{
			TestScalar(13.0f);
			TestScalar(13.0);
			TestScalar(13);
			TestScalar(float2(13.0f, 11));
			TestScalar(float3(13.0f, 11, 10));
			TestScalar(float4(13.0f, 11, 9, 23));
			TestScalar(new Size(13.0f, Unit.Points));
			TestScalar(new Size2(new Size(13.0f, Unit.Points), new Size(15.0f, Unit.Points)));
			TestScalar(Marshal.ToDouble("13.0"));
			TestScalar(Marshal.ToDouble("13."));
			TestScalar(Marshal.ToDouble("13"));

			TestVector(7.0f, float4(7.0f, 7.0f, 7.0f, 7.0f));
			TestVector(7.0, float4(7.0f, 7.0f, 7.0f, 7.0f));			
			TestVector(7, float4(7.0f, 7.0f, 7.0f, 7.0f));

			TestVector((Size)7.0f, float4(7.0f, 7.0f, 7.0f, 7.0f));
			TestVector(new Size2(7.0f, 8.0f), float4(7.0f, 8.0f, 7.0f, 8.0f));

			TestVector(float2(7.0f, 8.0f), float4(7.0f, 8.0f, 7.0f, 8.0f));
			TestVector(float3(7.0f, 8.0f, 9.0f), float4(7.0f, 8.0f, 9.0f, 1.0f));			
			TestVector(float4(7.0f, 8.0f, 9.0f, 10.0f), float4(7.0f, 8.0f, 9.0f, 10.0f));

			object v = new Size(13, Unit.Percent);
			Assert.AreEqual(13, Marshal.ToSize(v).Value);
			Assert.AreEqual(Unit.Percent, Marshal.ToSize(v).Unit);

			v = new Size2(new Size(14, Unit.Percent), new Size(15, Unit.Pixels));
			Assert.AreEqual(14, Marshal.ToSize(v).Value);
			Assert.AreEqual(Unit.Percent, Marshal.ToSize(v).Unit);
			var x = Marshal.ToSize2(v).X;
			Assert.AreEqual(14, x.Value);
			Assert.AreEqual(Unit.Percent, x.Unit);
			var y = Marshal.ToSize2(v).Y;
			Assert.AreEqual(15, y.Value);
			Assert.AreEqual(Unit.Pixels, y.Unit);
		}

		object CheckMarshalAdd(object a, object b)
		{
			object result;
			Assert.IsTrue(Marshal.TryAdd(a,b, out result));
			return result;
		}
		
		object CheckMarshalSubtract(object a, object b)
		{
			object result;
			Assert.IsTrue(Marshal.TrySubtract(a,b, out result));
			return result;
		}
		
		object CheckMarshalMultiply(object a, object b)
		{
			object result;
			Assert.IsTrue(Marshal.TryMultiply(a,b, out result));
			return result;
		}

		object CheckMarshalDivide(object a, object b)
		{
			object result;
			Assert.IsTrue(Marshal.TryDivide(a,b, out result));
			return result;
		}
		
		// Expects the incoming value to be an equivalent of double 13.0
		void TestScalar(object v)
		{
			Assert.AreEqual(13.0+51, Marshal.ToDouble(CheckMarshalAdd(v, 51.0f)));
			Assert.AreEqual(13.0+51, Marshal.ToDouble(CheckMarshalAdd(v, 51.0)));
			Assert.AreEqual(13.0+51, Marshal.ToDouble(CheckMarshalAdd(v, 51)));

			Assert.AreEqual(13.0-51.0, Marshal.ToDouble(CheckMarshalSubtract(v, 51.0f)));
			Assert.AreEqual(13.0-51.0, Marshal.ToDouble(CheckMarshalSubtract(v, 51.0)));
			Assert.AreEqual(13.0-51.0, Marshal.ToDouble(CheckMarshalSubtract(v, 51)));

			Assert.AreEqual(13.0*51.0, Marshal.ToDouble(CheckMarshalMultiply(v, 51.0f)));
			Assert.AreEqual(13.0*51.0, Marshal.ToDouble(CheckMarshalMultiply(v, 51.0)));
			Assert.AreEqual(13.0*51.0, Marshal.ToDouble(CheckMarshalMultiply(v, 51)));

			Assert.AreEqual(13.0/51.0, Marshal.ToDouble(CheckMarshalDivide(v, 51.0f)));
			Assert.AreEqual(13.0/51.0, Marshal.ToDouble(CheckMarshalDivide(v, 51.0)));
			Assert.AreEqual(13.0/51.0, Marshal.ToDouble(CheckMarshalDivide(v, 51)));
		}

		// Expects the incoming value to be equivalent of the given reference vector
		void TestVector(object v, float4 r)
		{
			var f = float4(8, 1, 3, 4);
			var k = f;
			Assert.AreEqual(f+r, Marshal.ToFloat4(CheckMarshalAdd(k, v)));
			Assert.AreEqual(f-r, Marshal.ToFloat4(CheckMarshalSubtract(k, v)));
			Assert.AreEqual(f*r, Marshal.ToFloat4(CheckMarshalMultiply(k, v)));
			Assert.AreEqual(f/r, Marshal.ToFloat4(CheckMarshalDivide(k, v)));

			Assert.AreEqual((f+r).XYZ, Marshal.ToFloat3(CheckMarshalAdd(k, v)));
			Assert.AreEqual((f-r).XYZ, Marshal.ToFloat3(CheckMarshalSubtract(k, v)));
			Assert.AreEqual((f*r).XYZ, Marshal.ToFloat3(CheckMarshalMultiply(k, v)));
			Assert.AreEqual((f/r).XYZ, Marshal.ToFloat3(CheckMarshalDivide(k, v)));

			Assert.AreEqual((f+r).XY, Marshal.ToFloat2(CheckMarshalAdd(k, v)));
			Assert.AreEqual((f-r).XY, Marshal.ToFloat2(CheckMarshalSubtract(k, v)));
			Assert.AreEqual((f*r).XY, Marshal.ToFloat2(CheckMarshalMultiply(k, v)));
			Assert.AreEqual((f/r).XY, Marshal.ToFloat2(CheckMarshalDivide(k, v)));

			Assert.AreEqual((f+r).X, Marshal.ToFloat(CheckMarshalAdd(k, v)));
			Assert.AreEqual((f-r).X, Marshal.ToFloat(CheckMarshalSubtract(k, v)));
			Assert.AreEqual((f*r).X, Marshal.ToFloat(CheckMarshalMultiply(k, v)));
			Assert.AreEqual((f/r).X, Marshal.ToFloat(CheckMarshalDivide(k, v)));

			var vr = r;
			Assert.AreEqual(r+Marshal.ToFloat4(v), Marshal.ToFloat4(CheckMarshalAdd(vr, v)));
			Assert.AreEqual(r-Marshal.ToFloat4(v), Marshal.ToFloat4(CheckMarshalSubtract(vr, v)));
			Assert.AreEqual(r*Marshal.ToFloat4(v), Marshal.ToFloat4(CheckMarshalMultiply(vr, v)));
			Assert.AreEqual(r/Marshal.ToFloat4(v), Marshal.ToFloat4(CheckMarshalDivide(vr, v)));

			//It's somewhat questionable that a float4 can convert to a Size/Size2, but alas, it was supported before :(
			Assert.AreEqual(new Size2(r.X, r.Y), Marshal.ToSize2(v));
			Assert.AreEqual(new Size(r.X, Unit.Unspecified), Marshal.ToSize(v));

		}
		
		[Test]
		[Obsolete]
		public void Deprecated()
		{
			Assert.AreEqual( 8.0, Marshal.Add(3.0,5.0));
			Assert.AreEqual( -2.0, Marshal.Subtract(3.0,5.0));
			Assert.AreEqual( 15.0, Marshal.Multiply(3.0,5.0));
			Assert.AreEqual( 0.6, Marshal.Divide(3.0,5.0));
			Assert.AreEqual( 3.0, Marshal.Min(3.0,5.0));
			Assert.AreEqual( 5.0, Marshal.Max(3.0,5.0));
		}

		[Test]
		public void VectorMarshaling()
		{
			var p = new UX.VectorMarshalling();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(float4(1, 1, 1, 1), p.Literal1.Margin);
				Assert.AreEqual(float4(1, 2, 1, 2), p.Literal2.Margin);
				Assert.AreEqual(float4(1, 2, 3, 4), p.Literal4.Margin);

				Assert.AreEqual(float4(1, 1, 1, 1), p.Constant1.Margin);
				Assert.AreEqual(float4(1, 2, 1, 2), p.Constant2.Margin);
				Assert.AreEqual(float4(1, 2, 3, 4), p.Constant4.Margin);
			}
		}
		
		[Test]
		public void TryToZeroFloat4()
		{
			//https://github.com/fuse-open/fuselibs/issues/592
			float4 val;
			int size;
			Assert.IsFalse( Marshal.TryToZeroFloat4( "#ch", out val, out size ) );
			Assert.IsFalse( Marshal.TryToZeroFloat4(  new ListWrapper(
				new object[]{ 1,2, new Junk()}), out val, out size ) );
			Assert.IsFalse( Marshal.TryToZeroFloat4(  new ListWrapper(
				new object[]{ 1, "abc"}), out val, out size ) );
				
			Assert.IsTrue( Marshal.TryToZeroFloat4(  new ListWrapper(
				new object[]{ 1, 2, 3}), out val, out size ) );
			Assert.AreEqual( float4(1,2,3,0), val );
			Assert.IsTrue( Marshal.TryToZeroFloat4(  new ListWrapper(
				new object[]{}), out val, out size ) );
			Assert.AreEqual( float4(0,0,0,0), val );
		}
	}
	
	class Junk{}
	class ListWrapper: IArray
	{
		readonly object[] _list;
		public ListWrapper(object[] list)
		{
			_list = list;
		}
		public int Length { get { return _list.Length; } }
		public object this [int index] { get { return _list[index]; } }
	}
}
