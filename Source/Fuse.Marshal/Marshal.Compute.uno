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

		public static object Add(object a, object b)
		{
			if (a == null || b == null) return null;
			a = TryConvertArrayToVector(a);
			var ta = a.GetType();
			var tb = b.GetType();

			if (ta == typeof(string) || tb == typeof(string))
				return a.ToString() + b.ToString();
			
			var t = DominantType(ta, tb);

			Computer c;
			if (_computers.TryGetValue(t, out c)) 
				return c.Add(a, b);
			
			throw new ComputeException("Add", a, b);
		}

		public static object Subtract(object a, object b)
		{
			if (a == null || b == null) return null;
			a = TryConvertArrayToVector(a);
			var t = DominantType(a.GetType(), b.GetType());

			Computer c;
			if (_computers.TryGetValue(t, out c)) 
				return c.Subtract(a, b);
			
			throw new ComputeException("Subtract", a, b);
		}

		public static object Multiply(object a, object b)
		{
			if (a == null || b == null) return null;
			a = TryConvertArrayToVector(a);
			var t = DominantType(a.GetType(), b.GetType());

			Computer c;
			if (_computers.TryGetValue(t, out c)) 
				return c.Multiply(a, b);
			
			throw new ComputeException("Multiply", a, b);
		}

		public static object Divide(object a, object b)
		{
			if (a == null || b == null) return null;
			a = TryConvertArrayToVector(a);
			var t = DominantType(a.GetType(), b.GetType());

			Computer c;
			if (_computers.TryGetValue(t, out c)) 
				return c.Divide(a, b);
			
			throw new ComputeException("Divide", a, b);
		}

		public static object LessThan(object a, object b)
		{
			if (a == null || b == null) return null;
			var t = DominantType(a.GetType(), b.GetType());

			Computer c;
			if (_computers.TryGetValue(t, out c)) 
				return c.LessThan(a, b);
			
			throw new ComputeException("LessThan", a, b);
		}

		public static object LessOrEqual(object a, object b)
		{
			if (a == null || b == null) return null;
			var t = DominantType(a.GetType(), b.GetType());

			Computer c;
			if (_computers.TryGetValue(t, out c)) 
				return c.LessOrEqual(a, b);
			
			throw new ComputeException("LessOrEqual", a, b);
		}


		public static object GreaterThan(object a, object b)
		{
			if (a == null || b == null) return null;
			var t = DominantType(a.GetType(), b.GetType());

			Computer c;
			if (_computers.TryGetValue(t, out c)) 
				return c.GreaterThan(a, b);
			
			throw new ComputeException("GreaterThan", a, b);
		}

		public static object GreaterOrEqual(object a, object b)
		{
			if (a == null || b == null) return null;
			var t = DominantType(a.GetType(), b.GetType());

			Computer c;
			if (_computers.TryGetValue(t, out c)) 
				return c.GreaterOrEqual(a, b);
			
			throw new ComputeException("GreaterOrEqual", a, b);
		}

		public static object EqualTo(object a, object b)
		{
			if (a == null || b == null) return null;
			var t = DominantType(a.GetType(), b.GetType());

			Computer c;
			if (_computers.TryGetValue(t, out c)) 
				return c.EqualTo(a, b);
			
			throw new ComputeException("EqualTo", a, b);
		}

		public static object Min(object a, object b)
		{
			if (a == null || b == null) return null;
			var t = DominantType(a.GetType(), b.GetType());

			Computer c;
			if (_computers.TryGetValue(t, out c)) 
				return c.Min(a, b);
			
			throw new ComputeException("Min", a, b);
		}

		public static object Max(object a, object b)
		{
			if (a == null || b == null) return null;
			var t = DominantType(a.GetType(), b.GetType());

			Computer c;
			if (_computers.TryGetValue(t, out c)) 
				return c.Max(a, b);
			
			throw new ComputeException("Max", a, b);
		}
	}
}
