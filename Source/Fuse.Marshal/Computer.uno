using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse
{
	public class ComputeException: Exception
	{
		public ComputeException(string op, object a, object b) 
			: base("Cannot '" + op + "'' objects of type '" + a.GetType() + "'' and '" + b.GetType() + "'")
		{}
	}

	abstract class Computer
	{
		public enum TypeOp
		{
			Add,
			Subtract,
			Multiply,
			Divide,
			Min,
			Max,
		}
		public abstract bool TryOp( TypeOp op, object a, object b, out object result );
		
		public enum BoolOp
		{
			LessThan,
			LessOrEqual,
			GreaterThan,
			GreaterOrEqual,
			EqualTo,
		}
		public abstract bool TryOp( BoolOp op, object a, object b, out bool result );
	}

	abstract class Computer<T>: Computer
	{
		public override bool TryOp( TypeOp op, object a, object b, out object result )
		{
			T ma = default(T);
			T mb = default(T);
			T tr = default(T);
			if (!Marshal.TryToType<T>(a, out ma) ||
				!Marshal.TryToType<T>(b, out mb) ||
				!TryOpImpl(op, ma, mb, out tr))
			{
				result = default(T);
				return false;
			}
			result = tr;
			return true;
		}
		
		protected abstract bool TryOpImpl( TypeOp op, T a, T b, out T result );
		
		public bool TryConvert(object o, out T result)
		{
			return Marshal.TryToType<T>(o, out result);
		}

		public override bool TryOp( BoolOp op, object a, object b, out bool result)
		{ 
			T ma = default(T);
			T mb = default(T);
			result = false;
			if (!Marshal.TryToType<T>(a, out ma) ||
				!Marshal.TryToType<T>(b, out mb))
				return false;
			return TryOpImpl(op, ma,mb, out result);
		}
		
		protected abstract bool TryOpImpl( BoolOp op, T a, T b, out bool result );
	}

	class StringComputer: Computer<string>
	{
		protected override bool TryOpImpl( TypeOp op, string a, string b, out string result )
		{
			switch(op)
			{
				case TypeOp.Add: result = a + b; return true;
			}
			
			result = null;
			return false;
		}
		
		protected override bool TryOpImpl( BoolOp op, string a, string b, out bool result )
		{
			switch(op)
			{
				case BoolOp.EqualTo: result = a == b; return true;
			}
			
			result = false;
			return false;
		}
	}

	class NumberComputer: Computer<double>
	{
		protected override bool TryOpImpl( TypeOp op, double a, double b, out double result )
		{
			switch(op)
			{
				case TypeOp.Add: result = a + b; return true;
				case TypeOp.Subtract: result = a - b; return true;
				case TypeOp.Multiply: result = a * b; return true;
				case TypeOp.Divide: result = a/b; return true;
				case TypeOp.Min: result = Math.Min(a,b); return true;
				case TypeOp.Max: result = Math.Max(a,b); return true;
			}
			
			result = 0;
			return false;
		}
		
		protected override bool TryOpImpl( BoolOp op, double a, double b, out bool result )
		{
			switch(op)
			{
				case BoolOp.EqualTo: result = a == b; return true;
				case BoolOp.LessThan: result = a < b; return true;
				case BoolOp.LessOrEqual: result = a <= b; return true;
				case BoolOp.GreaterThan: result = a > b; return true;
				case BoolOp.GreaterOrEqual: result = a >= b; return true;
			}
			
			result = false;
			return false;
		}
	}

	class BoolComputer: Computer<bool>
	{
		protected override bool TryOpImpl( TypeOp op, bool a, bool b, out bool result )
		{
			result = false;
			return false;
		}

		protected override bool TryOpImpl( BoolOp op, bool a, bool b, out bool result )
		{
			switch(op)
			{
				case BoolOp.EqualTo:
					result = a == b;
					return true;
			}

			result = false;
			return false;
		}
	}

	class SizeComputer: Computer<Size>
	{
		protected override bool TryOpImpl( TypeOp op, Size a, Size b, out Size result )
		{
			switch(op)
			{
				case TypeOp.Add: result = a + b; return true;
				case TypeOp.Subtract: result = a - b; return true;
				case TypeOp.Multiply: result = a * b; return true;
				case TypeOp.Divide: result = a/b; return true;
				case TypeOp.Min: 
					result = new Size(Math.Min(a.Value, b.Value), Size.Combine(a.Unit, b.Unit)); 
					return true;
				case TypeOp.Max:
					result = new Size(Math.Max(a.Value, b.Value), Size.Combine(a.Unit, b.Unit)); 
					return true;
			}
			
			result =  new Size();
			return false;
		}
	
		protected override bool TryOpImpl( BoolOp op, Size a, Size b, out bool result )
		{
			switch(op)
			{
				case BoolOp.EqualTo: result = a == b; return true;
				case BoolOp.LessThan: result = a.Value < b.Value; return true;
				case BoolOp.LessOrEqual: result = a.Value <= b.Value; return true;
				case BoolOp.GreaterThan: result = a.Value > b.Value; return true;
				case BoolOp.GreaterOrEqual: result = a.Value >= b.Value; return true;
			}
			
			result = false;
			return false;
		}
	}

	class Size2Computer: Computer<Size2>
	{
		protected override bool TryOpImpl( TypeOp op, Size2 a, Size2 b, out Size2 result )
		{
			switch(op)
			{
				case TypeOp.Add: result = a + b; return true;
				case TypeOp.Subtract: result = a - b; return true;
				case TypeOp.Multiply: result = a * b; return true;
				case TypeOp.Divide: result = a/b; return true;
			}
			
			result = new Size2();
			return false;
		}
		
		protected override bool TryOpImpl( BoolOp op, Size2 a, Size2 b, out bool result )
		{
			switch(op)
			{
				case BoolOp.EqualTo: result = a == b; return true;
			}
			
			result = false;
			return false;
		}
	}

	class Float2Computer: Computer<float2>
	{
		protected override bool TryOpImpl( TypeOp op, float2 a, float2 b, out float2 result )
		{
			switch(op)
			{
				case TypeOp.Add: result = a + b; return true;
				case TypeOp.Subtract: result = a - b; return true;
				case TypeOp.Multiply: result = a * b; return true;
				case TypeOp.Divide: result = a/b; return true;
			}
			
			result = float2(0);
			return false;
		}
		
		protected override bool TryOpImpl( BoolOp op, float2 a, float2 b, out bool result )
		{
			switch(op)
			{
				case BoolOp.EqualTo: result = a == b; return true;
			}
			
			result = false;
			return false;
		}
	}

	class Float3Computer: Computer<float3>
	{
		protected override bool TryOpImpl( TypeOp op, float3 a, float3 b, out float3 result )
		{
			switch(op)
			{
				case TypeOp.Add: result = a + b; return true;
				case TypeOp.Subtract: result = a - b; return true;
				case TypeOp.Multiply: result = a * b; return true;
				case TypeOp.Divide: result = a/b; return true;
			}
			
			result = float3(0);
			return false;
		}
		
		protected override bool TryOpImpl( BoolOp op, float3 a, float3 b, out bool result )
		{
			switch(op)
			{
				case BoolOp.EqualTo: result = a == b; return true;
			}
			
			result = false;
			return false;
		}
	}

	class Float4Computer: Computer<float4>
	{
		protected override bool TryOpImpl( TypeOp op, float4 a, float4 b, out float4 result )
		{
			switch(op)
			{
				case TypeOp.Add: result = a + b; return true;
				case TypeOp.Subtract: result = a - b; return true;
				case TypeOp.Multiply: result = a * b; return true;
				case TypeOp.Divide: result = a/b; return true;
			}
			
			result = float4(0);
			return false;
		}
		
		protected override bool TryOpImpl( BoolOp op, float4 a, float4 b, out bool result )
		{
			switch(op)
			{
				case BoolOp.EqualTo: result = a == b; return true;
			}
			
			result = false;
			return false;
		}
	}
}