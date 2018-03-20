using Uno;
using Uno.UX;

namespace Fuse.Reactive
{
	[UXFunction("min")]
	public sealed class Min: BinaryOperator
	{
		[UXConstructor]
		public Min([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): 
			base(left, right, "min") {}
			
		protected override bool TryCompute(object left, object right, out object result)
		{
			return Marshal.TryMin(left, right, out result);
		}
	}

	[UXFunction("max")]
	public sealed class Max: BinaryOperator
	{
		[UXConstructor]
		public Max([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right) : 
			base(left, right, "max") {}
			
		protected override bool TryCompute(object left, object right, out object result)
		{
			return Marshal.TryMax(left, right, out result);
		}
	}
	
	[UXFunction("mod")]
	public sealed class Mod : BinaryOperator
	{
		[UXConstructor]
		public Mod([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right) : 
			base(left, right, "mod") {}
			
		protected override bool TryCompute(object left, object right, out object result)
		{
			result = Math.Mod( Marshal.ToFloat(left), Marshal.ToFloat(right) );
			return true;
		}
	}

	[UXFunction("even")]
	/** True if the rounded value is even, false otherwise*/
	public sealed class Even : UnaryOperator
	{
		[UXConstructor]
		public Even([UXParameter("Operand")] Expression operand): base(operand, "even") {}
		protected override bool TryCompute(object operand, out object result)
		{
			result = null;
			float v = 0;
			if (!Marshal.TryToType<float>(operand, out v))
				return false;
				
			var q = (int)Math.Floor(v + 0.5f);
			result = q % 2 == 0;
			return true;
		}
	}
	
	[UXFunction("odd")]
	/** True if the rounded value is odd, false otherwise*/
	public sealed class Odd : UnaryOperator
	{
		[UXConstructor]
		public Odd([UXParameter("Operand")] Expression operand): base(operand, "odd") {}
		protected override bool TryCompute(object operand, out object result)
		{
			result = null;
			float v = 0;
			if (!Marshal.TryToType<float>(operand, out v))
				return false;
				
			var q = (int)Math.Floor(v + 0.5f);
			result = q % 2 != 0;
			return true;
		}
	}

	[UXFunction("alternate")]
	/**
		Alternate between true/false values for ranges of integers.
		
			alternate( value, groupSize )
			
		Input values are rounded to the nearest integer.
		
		Example:
		
			alternate( value, 3 )
			
		This will yield true for values 0,1,2, false for 3,4,5, true for 6,7,8, false for 9,10,11, etc.
	*/
	public sealed class Alternate : BinaryOperator
	{
		[UXConstructor]
		public Alternate([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right) : 
			base(left, right, "alternate") {}
			
		protected override bool TryCompute(object left, object right, out object result)
		{
			result = null;
			float fvalue = 0;
			float fgroup = 0;
			if (!Marshal.TryToType<float>(left, out fvalue) ||
				!Marshal.TryToType<float>(right, out fgroup))
				return false;
			var value = (int)Math.Floor(fvalue + 0.5f);
			var group = (int)Math.Floor(fgroup + 0.5f);
			var b = value >= 0 ? 
				(value % (group*2)) < group: 
				( -(value+1) % (group*2)) >= group;
			result = b;
			return true;
		}
	}

	/** 
		Common base for floating point operations 
	
		All the derived expressions support 1-4 component input values and will return a value of the same size.
		
		[subclass Fuse.Reactive.UnaryFloatOperator]
	*/
	public abstract class UnaryFloatOperator : UnaryOperator
	{
		internal delegate double FloatOp(double value);
		FloatOp _op;
		internal UnaryFloatOperator(Expression operand, string name, FloatOp op) : 
			base(operand, name)
		{
			_op = op;
		}
		protected sealed override bool TryCompute(object operand, out object result)
		{
			result = null;
			float4 v;
			int size;
			if (Marshal.TryToZeroFloat4(operand, out v, out size))
			{	
				switch (size)
				{
					case 1:
						result = (float)_op(v[0]);
						return true;
					case 2:
						result = float2((float)_op(v[0]),(float)_op(v[1]));
						return true;
					case 3:
						result = float3((float)_op(v[0]),(float)_op(v[1]),(float)_op(v[2]));
						return true;
					case 4:
						result = float4((float)_op(v[0]),(float)_op(v[1]),(float)_op(v[2]),(float)_op(v[3]));
						return true;
				}
			}
				
			return false;
		}
	}

	/**
		[subclass Fuse.Reactive.BinaryFloatOperator]
	*/
	public abstract class BinaryFloatOperator : BinaryOperator
	{
		internal delegate double FloatOp(double a, double b);
		FloatOp _op;
		internal BinaryFloatOperator(Expression left, Expression right, string name, FloatOp op) : 
			base(left, right, name) 
		{
			_op = op;
		}
		
		protected sealed override bool TryCompute(object left, object right, out object result)
		{
			result = null;
			
			double lv = 0;
			double rv = 0;
			if (!Marshal.TryToType<double>(left, out lv) ||
				!Marshal.TryToType<double>(right, out rv))
				return false;
			result = _op(lv, rv);
			return true;
		}
	}
	
	[UXFunction("sin")]
	/** The trigonometric sine of the input angle (in radians) */
	public sealed class Sin : UnaryFloatOperator
	{
		[UXConstructor]
		public Sin([UXParameter("Operand")] Expression operand)
			: base(operand,"sin", Math.Sin) {}
	}
	
	[UXFunction("cos")]
	/** The trigonometric cosine of the input angle (in radians) */
	public sealed class Cos : UnaryFloatOperator
	{
		[UXConstructor]
		public Cos([UXParameter("Operand")] Expression operand)
			: base(operand, "cos", Math.Cos) {}
	}
	
	[UXFunction("tan")]
	/** The trigonometric tangent of the input angle (in radians) */
	public sealed class Tan : UnaryFloatOperator
	{
		[UXConstructor]
		public Tan([UXParameter("Operand")] Expression operand)
			: base(operand, "tan", Math.Tan) {}
	}
	
	/** The invserse trigonometric sine of the input */
	[UXFunction("asin")]
	public sealed class Asin : UnaryFloatOperator
	{
		[UXConstructor]
		public Asin([UXParameter("Operand")] Expression operand)
			: base(operand,"asin", Math.Asin) {}
	}
	
	[UXFunction("acos")]
	/** The invserse trigonometric cosine of the input */
	public sealed class Acos : UnaryFloatOperator
	{
		[UXConstructor]
		public Acos([UXParameter("Operand")] Expression operand)
			: base(operand, "acos", Math.Acos) {}
	}
	
	[UXFunction("atan")]
	/** The invserse trigonometric tangent of the input */
	public sealed class Atan : UnaryFloatOperator
	{
		[UXConstructor]
		public Atan([UXParameter("Operand")] Expression operand)
			: base(operand, "atan", Math.Atan) {}
	}
	
	[UXFunction("atan2")]
	/** 
		The invserse trigonometric tangent of the input components 
		
			atan2(y, x)
	*/
	public sealed class Atan2 : BinaryFloatOperator
	{
		[UXConstructor]
		public Atan2([UXParameter("Left")] Expression left, [UXParameter("Left")] Expression right)
			: base(left, right, "atan2", Math.Atan2) {}
	}
	
	/**
		The inverse trigonometric tangent of the input components. Like `atan2` but uses the input vector for the X and Y values.
		
			atanVector( v ) == atan2( v.Y, v.X )
	*/
	[UXFunction("atanVector")]
	public sealed class AtanVector : UnaryOperator
	{
		[UXConstructor]
		public AtanVector([UXParameter("Operand")] Expression operand)
			: base(operand, "atanVector")
		{ }
		
		protected sealed override bool TryCompute(object operand, out object result)
		{
			result = null;
			var v = float2(0);
			if (!Marshal.TryToType<float2>(operand, out v))
				return false;
				
			result = Math.Atan2(v.Y, v.X);
			return true;
		}
	}
	

	[UXFunction("abs")]
	public sealed class Abs : UnaryFloatOperator
	{
		[UXConstructor]
		public Abs([UXParameter("Operand")] Expression operand)
			: base(operand, "abs", Math.Abs) {}
	}

	[UXFunction("sqrt")]
	public sealed class Sqrt : UnaryFloatOperator
	{
		[UXConstructor]
		public Sqrt([UXParameter("Operand")] Expression operand)
			: base(operand, "sqrt", Math.Sqrt) {}
	}
	
	[UXFunction("ceil")]
	public sealed class Ceil : UnaryFloatOperator
	{
		[UXConstructor]
		public Ceil([UXParameter("Operand")] Expression operand)
			: base(operand, "ceil", Math.Ceil) {}
	}
	
	[UXFunction("floor")]
	public sealed class Floor : UnaryFloatOperator
	{
		[UXConstructor]
		public Floor([UXParameter("Operand")] Expression operand)
			: base(operand, "floor", Math.Floor) {}
	}
	
	[UXFunction("degreesToRadians")]
	public sealed class DegreesToRadians : UnaryFloatOperator
	{
		[UXConstructor]
		public DegreesToRadians([UXParameter("Operand")] Expression operand)
			: base(operand, "degreesToRadians", Math.DegreesToRadians) {}
	}

	[UXFunction("radiansToDegrees")]
	public sealed class RadiansToDegrees : UnaryFloatOperator
	{
		[UXConstructor]
		public RadiansToDegrees([UXParameter("Operand")] Expression operand)
			: base(operand, "radiansToDegrees", Math.RadiansToDegrees) {}
	}

	[UXFunction("exp")]
	public sealed class Exp : UnaryFloatOperator
	{
		[UXConstructor]
		public Exp([UXParameter("Operand")] Expression operand)
			: base(operand, "exp", Math.Exp) {}
	}

	[UXFunction("exp2")]
	public sealed class Exp2 : UnaryFloatOperator
	{
		[UXConstructor]
		public Exp2([UXParameter("Operand")] Expression operand)
			: base(operand, "exp2", Math.Exp2) {}
	}

	[UXFunction("fract")]
	public sealed class Fract : UnaryFloatOperator
	{
		[UXConstructor]
		public Fract([UXParameter("Operand")] Expression operand)
			: base(operand, "fract", Math.Fract) {}
	}
	
	[UXFunction("log")]
	public sealed class Log : UnaryFloatOperator
	{
		[UXConstructor]
		public Log([UXParameter("Operand")] Expression operand)
			: base(operand, "log", Math.Log) {}
	}

	[UXFunction("log2")]
	public sealed class Log2 : UnaryFloatOperator
	{
		[UXConstructor]
		public Log2([UXParameter("Operand")] Expression operand)
			: base(operand, "log2", Math.Log2) {}
	}
	
	[UXFunction("sign")]
	public sealed class Sign : UnaryFloatOperator
	{
		[UXConstructor]
		public Sign([UXParameter("Operand")] Expression operand)
			: base(operand, "sign", Math.Sign) {}
	}

	[UXFunction("pow")]
	public sealed class Pow : BinaryFloatOperator
	{
		[UXConstructor]
		public Pow([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right)
			: base(left, right, "pow", Math.Pow) {}
	}

	[UXFunction("round")]
	public sealed class Round : UnaryFloatOperator
	{
		[UXConstructor]
		public Round([UXParameter("Operand")] Expression operand)
			: base(operand, "operand", Math.Round) {}
	}
	
	[UXFunction("trunc")]
	/** Rounds to the next whole integer closer to zero */
	public sealed class Trunc : UnaryFloatOperator
	{
		[UXConstructor]
		public Trunc([UXParameter("Operand")] Expression operand)
			: base(operand, "trunc", Op) {}
			
		internal static double Op(double v)
		{
			return v < 0 ? Math.Ceil(v) : Math.Floor(v);
		}
	}
	
	/**
		Calculates the linear interpolation between two values.
		
			lerp( from, to, step )
			
		When step==0 the result is `from`, when step==1 the result is `to`. Partial values are linearly interpolated. Step values <0 and >1 are also supported.
		
		The input supports a 1-4 component value for `from` and `to`. The result will be same size. 
		`step` must always be a single value.
	*/
	[UXFunction("lerp")]
	public sealed class Lerp : TernaryOperator
	{
		[UXConstructor]
		public Lerp([UXParameter("First")] Expression first, 
			[UXParameter("Second")] Expression second, 
			[UXParameter("Third")] Expression third) : 
			base(first, second, third, Flags.None)
		{ }
		protected override bool TryCompute(object a, object b, object t, out object result)
		{
			result = null;
			float4 av = float4(0), bv = float4(0);
			int asize = 0, bsize = 0;
			float tv = 0;
			if (!Marshal.TryToZeroFloat4(a, out av, out asize) ||	
				!Marshal.TryToZeroFloat4(b, out bv, out bsize) ||
				!Marshal.TryToType<float>(t, out tv))
				return false;
			int size = Math.Max(asize, bsize);
			
			switch (size)
			{
				case 1:
					result = Math.Lerp(av.X, bv.X, tv);
					return true;
				case 2:
					result = Math.Lerp(av.XY, bv.XY, tv);
					return true;
				case 3:
					result = Math.Lerp(av.XYZ, bv.XYZ, tv);
					return true;
				case 4:
					result = Math.Lerp(av, bv, tv);
					return true;
			}
				
			return false;
		}
		public override string ToString()
		{
			return "lerp(" + First + "," + Second +  "," + Third + ")";
		}
	}
	
	/**
		Restricts the range of a value to between two numbers.
		
			clamp( value, min, max)
			
		Returns
		- `min` when `value < min`
		- `max` when `value > max`
		- `value` otherwise
			
		Value may be a 1-4 component value. `min` and `max` must both be a single value.
	*/
	[UXFunction("clamp")]
	public sealed class Clamp : TernaryOperator
	{
		[UXConstructor]
		public Clamp([UXParameter("First")] Expression first, 
			[UXParameter("Second")] Expression second, 
			[UXParameter("Third")] Expression third) : 
			base(first, second, third, Flags.None) 
		{ }
		protected override bool TryCompute(object a, object mn, object mx, out object result)
		{
			result = null;
			float4 av = float4(0);
			float mxv = 0, mnv = 0;
			int size = 0;
			if (!Marshal.TryToZeroFloat4(a, out av, out size) ||
				!Marshal.TryToType<float>(mn, out mnv) ||
				!Marshal.TryToType<float>(mx, out mxv))
				return false;
			
			if (size == 1)
				result = Math.Clamp(av.X, mnv, mxv);
			else if (size == 2)
				result = Math.Clamp(av.XY, mnv, mxv);
			else if (size == 3)
				result = Math.Clamp(av.XYZ, mnv, mxv);
			else if (size == 4)
				result = Math.Clamp(av, mnv, mxv);
			else
				return false;
				
			return true;
		}
		public override string ToString()
		{
			return "clamp(" + First + "," + Second +  "," + Third + ")";
		}
	}
}
