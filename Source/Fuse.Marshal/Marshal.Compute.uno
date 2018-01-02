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

		public static bool TryAdd(object a, object b, out object result)
		{
			result = null;
			if (a == null || b == null) return false;
			a = TryConvertArrayToVector(a);
			var ta = a.GetType();
			var tb = b.GetType();

			//TODO: doesn't the _computer handle this?
			if (ta == typeof(string) || tb == typeof(string))
			{
				result = a.ToString() + b.ToString();
				return true;
			}
			
			var t = DominantType(ta, tb);

			Computer c;
			if (_computers.TryGetValue(t, out c)) 
				return c.TryAdd(a, b, out result);
			return false;
		}
		
		[Obsolete]
		/** @deprecated Use TryAdd instead. 2018-01-02*/
		public static object Add(object a, object b)
		{
			object result = null;
			if (!TryAdd(a,b,out result))
				throw new ComputeException("Add", a, b);
			return result;
		}

		public static bool TrySubtract(object a, object b, out object result)
		{
			result = null;
			if (a == null || b == null) return false;
			a = TryConvertArrayToVector(a);
			var t = DominantType(a.GetType(), b.GetType());

			Computer c;
			if (_computers.TryGetValue(t, out c)) 
				return c.TrySubtract(a, b, out result);
			return false;
		}
			
		[Obsolete]
		/** @deprecated Use TrySubtract instead. 2018-01-02 */
		public static object Subtract(object a, object b)
		{
			object result = null;
			if (!TrySubtract(a,b,out result))
				throw new ComputeException("Subtract", a, b);
			return result;
		}

		public static bool TryMultiply(object a, object b, out object result)
		{
			result = null;
			if (a == null || b == null) return false;
			a = TryConvertArrayToVector(a);
			var t = DominantType(a.GetType(), b.GetType());

			Computer c;
			if (_computers.TryGetValue(t, out c)) 
				return c.TryMultiply(a, b, out result);
			return false;
		}
			
		[Obsolete]
		/** @deprecated Use TryMultiply instead. 2018-01-02 */
		public static object Multiply(object a, object b)
		{
			object result;
			if (!TryMultiply(a,b,out result))
				throw new ComputeException("Multiply", a, b);
			return result;
		}

		public static bool TryDivide(object a, object b, out object result)
		{
			result = null;
			if (a == null || b == null) return false;
			a = TryConvertArrayToVector(a);
			var t = DominantType(a.GetType(), b.GetType());

			Computer c;
			if (_computers.TryGetValue(t, out c)) 
				return c.TryDivide(a, b, out result);
			return true;
		}
			
		[Obsolete]
		/** @deprecated Use TryDivide instead. 2018-01-02 */
		public static object Divide(object a, object b)
		{
			object result;
			if (!TryDivide(a,b,out result))
				throw new ComputeException("Divide", a, b);
			return result;
		}

		public static bool TryLessThan(object a, object b, out bool result)
		{
			result = false;
			if (a == null || b == null) return false;
			var t = DominantType(a.GetType(), b.GetType());

			Computer c;
			if (_computers.TryGetValue(t, out c)) 
				return c.TryLessThan(a, b, out result);
			return true;
		}
		
		[Obsolete]
		/** @deprecated Use TryLessThan instead. 2018-01-02 */
		public static object LessThan(object a, object b)
		{
			bool result;
			if (!TryLessThan(a,b, out result))
				throw new ComputeException("LessThan", a, b);
			return result;
		}
			
		public static bool TryLessOrEqual(object a, object b, out bool result)
		{
			result = false;
			if (a == null || b == null) return false;
			var t = DominantType(a.GetType(), b.GetType());

			Computer c;
			if (_computers.TryGetValue(t, out c)) 
				return c.TryLessOrEqual(a, b, out result);
			return true;
		}
		
		[Obsolete]
		/** @deprecated Use TryLessOrEqual instead. 2018-01-02 */
		public static object LessOrEqual(object a, object b)
		{
			bool result;
			if (!TryLessOrEqual(a,b, out result))
				throw new ComputeException("LessOrEqual", a, b);
			return result;
		}

		public static bool TryGreaterThan(object a, object b, out bool result)
		{
			result = false;
			if (a == null || b == null) return false;
			var t = DominantType(a.GetType(), b.GetType());

			Computer c;
			if (_computers.TryGetValue(t, out c)) 
				return c.TryGreaterThan(a, b, out result);
			return true;
		}
		
		[Obsolete]
		/** @deprecated Use TryGreaterThan instead. 2018-01-02 */
		public static object GreaterThan(object a, object b)
		{
			bool result;
			if (!TryGreaterThan(a,b, out result))
				throw new ComputeException("GreaterThan", a, b);
			return result;
		}

		public static bool TryGreaterOrEqual(object a, object b, out bool result)
		{
			result = false;
			if (a == null || b == null) return false;
			var t = DominantType(a.GetType(), b.GetType());

			Computer c;
			if (_computers.TryGetValue(t, out c)) 
				return c.TryGreaterOrEqual(a, b, out result);
			return true;
		}
		
		[Obsolete]
		/** @deprecated Use TryGreaterOrEqual instead. 2018-01-02 */
		public static object GreaterOrEqual(object a, object b)
		{
			bool result;
			if (!TryGreaterOrEqual(a,b, out result))
				throw new ComputeException("GreaterOrEqual", a, b);
			return result;
		}
		
		public static bool TryEqualTo(object a, object b, out bool result)
		{
			result = false;
			if (a == null || b == null) return false;
			var t = DominantType(a.GetType(), b.GetType());

			Computer c;
			if (_computers.TryGetValue(t, out c)) 
				return c.TryEqualTo(a, b, out result);
			return true;
		}
		
		[Obsolete]
		/** @deprecated Use TryEqualTo instead. 2018-01-02 */
		public static object EqualTo(object a, object b)
		{
			bool result;
			if (!TryEqualTo(a,b, out result))
				throw new ComputeException("Equal", a, b);
			return result;
		}
		
		public static bool TryMin(object a, object b, out object result)
		{
			result = null;
			if (a == null || b == null) return false;
			var t = DominantType(a.GetType(), b.GetType());

			Computer c;
			if (_computers.TryGetValue(t, out c)) 
				return c.TryMin(a, b, out result);
			return true;
		}

		[Obsolete]
		/** @deprecated Use TryMin instead. 2018-01-02 */
		public static object Min(object a, object b)
		{
			object result;
			if (!TryMin(a,b,out result))
				throw new ComputeException("Min", a, b);
			return result;
		}

		public static bool TryMax(object a, object b, out object result)
		{
			result = null;
			if (a == null || b == null) return false;
			var t = DominantType(a.GetType(), b.GetType());

			Computer c;
			if (_computers.TryGetValue(t, out c)) 
				return c.TryMax(a, b, out result);
			return true;
		}
			
		[Obsolete]
		/** @deprecated Use TryMax instead. 2018-01-02 */
		public static object Max(object a, object b)
		{
			object result;
			if (!TryMax(a,b,out result))
				throw new ComputeException("Max", a, b);
			return result;
		}
	}
}
