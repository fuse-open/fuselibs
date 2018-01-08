using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse
{
	public static partial class Marshal
	{
		static Dictionary<Type, Computer> _computers = new Dictionary<Type, Computer>();

		static Marshal()
		{
			var number = new NumberComputer();
			_computers.Add(typeof(double), number);
			_computers.Add(typeof(float), number);
			_computers.Add(typeof(int), number);
			_computers.Add(typeof(short), number);
			_computers.Add(typeof(sbyte), number);
			_computers.Add(typeof(uint), number);
			_computers.Add(typeof(ushort), number);
			_computers.Add(typeof(byte), number);
			_computers.Add(typeof(bool), new BoolComputer());

			_computers.Add(typeof(Size), new SizeComputer());
			_computers.Add(typeof(Size2), new Size2Computer());
			_computers.Add(typeof(string), new StringComputer());
			_computers.Add(typeof(float2), new Float2Computer());
			_computers.Add(typeof(float3), new Float3Computer());
			_computers.Add(typeof(float4), new Float4Computer());

			AddConverter(new FileSourceConverter());
		}

		static Type DominantType(Type a, Type b)
		{
			if (a == typeof(float4)) return a;
			if (b == typeof(float4)) return b;
			if (a == typeof(float3)) return a;
			if (b == typeof(float3)) return b;
			if (a == typeof(Size2)) return a;
			if (b == typeof(Size2)) return b;
			if (a == typeof(Size)) return a;
			if (b == typeof(Size)) return b;
			return a;
		}

		static bool TryOp(Computer.TypeOp op, object a, object b, out object result)
		{
			result = null;
			if (a == null || b == null) return false;
			a = TryConvertArrayToVector(a);
			var ta = a.GetType();
			var tb = b.GetType();
			var t = DominantType(ta, tb);

			Computer c;
			if (_computers.TryGetValue(t, out c)) 
				return c.TryOp(op, a, b, out result);
			return false;
		}
		
		public static bool TryAdd(object a, object b, out object result) 
		{ return TryOp( Computer.TypeOp.Add, a, b, out result ); }
		
		public static bool TrySubtract(object a, object b, out object result) 
		{ return TryOp( Computer.TypeOp.Subtract, a, b, out result ); }
		
		public static bool TryMultiply(object a, object b, out object result) 
		{ return TryOp( Computer.TypeOp.Multiply, a, b, out result ); }
		
		public static bool TryDivide(object a, object b, out object result) 
		{ return TryOp( Computer.TypeOp.Divide, a, b, out result ); }
		
		public static bool TryMin(object a, object b, out object result) 
		{ return TryOp( Computer.TypeOp.Min, a, b, out result ); }
		
		public static bool TryMax(object a, object b, out object result) 
		{ return TryOp( Computer.TypeOp.Max, a, b, out result ); }
		
		static bool TryOp(Computer.BoolOp op, object a, object b, out bool result)
		{
			result = false;
			if (a == null || b == null) return false;
			var t = DominantType(a.GetType(), b.GetType());

			Computer c;
			if (_computers.TryGetValue(t, out c)) 
				return c.TryOp(op, a, b, out result);
			return false;
		}
		
		public static bool TryLessThan(object a, object b, out bool result)
		{ return TryOp(Computer.BoolOp.LessThan, a, b, out result ); }
		
		public static bool TryLessOrEqual(object a, object b, out bool result)
		{ return TryOp(Computer.BoolOp.LessOrEqual, a, b, out result ); }

		public static bool TryGreaterThan(object a, object b, out bool result)
		{ return TryOp(Computer.BoolOp.GreaterThan, a, b, out result ); }

		public static bool TryGreaterOrEqual(object a, object b, out bool result)
		{ return TryOp(Computer.BoolOp.GreaterOrEqual, a, b, out result ); }
		
		public static bool TryEqualTo(object a, object b, out bool result)
		{ return TryOp(Computer.BoolOp.EqualTo, a, b, out result ); }


		[Obsolete]
		static object DepOp(Computer.TypeOp op, object a, object b)
		{
			object result = null;
			if (!TryOp(op, a,b,out result))
				throw new ComputeException("" + op, a, b);
			return result;
		}
		
		[Obsolete]
		/** @deprecated Use TryAdd instead. 2018-01-02*/
		public static object Add(object a, object b)
		{ return DepOp( Computer.TypeOp.Add, a, b); }
		
		[Obsolete]
		/** @deprecated Use TrySubtract instead. 2018-01-02*/
		public static object Subtract(object a, object b)
		{ return DepOp( Computer.TypeOp.Subtract, a, b); }
		
		[Obsolete]
		/** @deprecated Use TryMultiply instead. 2018-01-02*/
		public static object Multiply(object a, object b)
		{ return DepOp( Computer.TypeOp.Multiply, a, b); }
		
		[Obsolete]
		/** @deprecated Use TryDivide instead. 2018-01-02*/
		public static object Divide(object a, object b)
		{ return DepOp( Computer.TypeOp.Divide, a, b); }
		
		[Obsolete]
		/** @deprecated Use TryMin instead. 2018-01-02*/
		public static object Min(object a, object b)
		{ return DepOp( Computer.TypeOp.Min, a, b); }
		
		[Obsolete]
		/** @deprecated Use TryMax instead. 2018-01-02*/
		public static object Max(object a, object b)
		{ return DepOp( Computer.TypeOp.Max, a, b); }
		
		[Obsolete]
		static object DepOp(Computer.BoolOp op, object a, object b)
		{
			bool result;
			if (!TryOp(op,a,b, out result))
				throw new ComputeException("" + op, a, b);
			return result;
		}
		
		[Obsolete]
		/** @deprecated Use TryLessThan instead. 2018-01-02 */
		public static object LessThan(object a, object b)
		{ return DepOp(Computer.BoolOp.LessThan, a, b); }
		
		[Obsolete]
		/** @deprecated Use TryLessOrEqual instead. 2018-01-02 */
		public static object LessOrEqual(object a, object b)
		{ return DepOp(Computer.BoolOp.LessOrEqual, a, b); }
		
		[Obsolete]
		/** @deprecated Use TryGreaterThan instead. 2018-01-02 */
		public static object GreaterThan(object a, object b)
		{ return DepOp(Computer.BoolOp.GreaterThan, a, b); }
		
		[Obsolete]
		/** @deprecated Use TryGreaterOrEqual instead. 2018-01-02 */
		public static object GreaterOrEqual(object a, object b)
		{ return DepOp(Computer.BoolOp.GreaterOrEqual, a, b); }
		
		[Obsolete]
		/** @deprecated Use TryEqualTo instead. 2018-01-02 */
		public static object EqualTo(object a, object b)
		{ return DepOp(Computer.BoolOp.EqualTo, a, b); }
	}
}
