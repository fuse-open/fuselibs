using Uno;
using Uno.UX;

namespace Fuse.Reactive
{
	[UXFunction("min")]
	public sealed class Min: BinaryOperator
	{
		[UXConstructor]
		public Min([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): base(left, right) {}
		protected override object Compute(object left, object right)
		{
			return Marshal.Min(left, right);
		}

		public override string ToString()
		{
			return "min(" + Left + ", " + Right + ")";
		}
	}

	[UXFunction("max")]
	public sealed class Max: BinaryOperator
	{
		[UXConstructor]
		public Max([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): base(left, right) {}
		protected override object Compute(object left, object right)
		{
			return Marshal.Max(left, right);
		}

		public override string ToString()
		{
			return "max(" + Left + ", " + Right + ")";
		}
	}
	
	[UXFunction("mod")]
	public sealed class Mod : BinaryOperator
	{
		[UXConstructor]
		public Mod([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): base(left, right) {}
		protected override object Compute(object left, object right)
		{
			return Math.Mod( Marshal.ToFloat(left), Marshal.ToFloat(right) );
		}

		public override string ToString()
		{
			return "mod(" + Left + ", " + Right + ")";
		}
	}

	[UXFunction("even")]
	/** True if the rounded value is even, false otherwise*/
	public sealed class Even : UnaryOperator
	{
		[UXConstructor]
		public Even([UXParameter("Operand")] Expression operand): base(operand) {}
		protected override object Compute(object operand)
		{
			float v = 0;
			if (!Marshal.TryToType<float>(operand, out v))
				return null;
				
			var q = (int)Math.Round(v);
			return q % 2 == 0;
		}

		public override string ToString()
		{
			return "even(" + Operand +  ")";
		}
	}
	
	[UXFunction("odd")]
	/** True if the rounded value is odd, false otherwise*/
	public sealed class Odd : UnaryOperator
	{
		[UXConstructor]
		public Odd([UXParameter("Operand")] Expression operand): base(operand) {}
		protected override object Compute(object operand)
		{
			float v = 0;
			if (!Marshal.TryToType<float>(operand, out v))
				return null;
				
			var q = (int)Math.Round(v);
			return q % 2 != 0;
		}

		public override string ToString()
		{
			return "odd(" + Operand +  ")";
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
		public Alternate([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): base(left, right) {}
		protected override object Compute(object left, object right)
		{
			float fvalue = 0;
			float fgroup = 0;
			if (!Marshal.TryToType<float>(left, out fvalue) ||
				!Marshal.TryToType<float>(right, out fgroup))
				return null;
			var value = (int)Math.Round(fvalue);
			var group = (int)Math.Round(fgroup);
			var b = value >= 0 ? 
				(value % (group*2)) < group: 
				( -(value+1) % (group*2)) >= group;
			return b;
		}

		public override string ToString()
		{
			return "alternate(" + Left + ", " + Right + ")";
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
		string _name;
		FloatOp _op;
		internal UnaryFloatOperator(Expression operand, string name, FloatOp op) : 
			base(operand) 
		{
			_name = name;
			_op = op;
		}
		protected override object Compute(object operand)
		{
			float4 v;
			int size;
			if (Marshal.TryToZeroFloat4(operand, out v, out size))
			{	
				switch (size)
				{
					case 1:
						return _op(v[0]);
					case 2:
						return float2((float)_op(v[0]),(float)_op(v[1]));
					case 3:
						return float3((float)_op(v[0]),(float)_op(v[1]),(float)_op(v[2]));
					case 4:
						return float4((float)_op(v[0]),(float)_op(v[1]),(float)_op(v[2]),(float)_op(v[3]));
				}
			}
				
			return null;
		}
		public override string ToString()
		{
			return _name + "(" + Operand +  ")";
		}
	}

	/**
		[subclass Fuse.Reactive.BinaryFloatOperator]
	*/
	public abstract class BinaryFloatOperator : BinaryOperator
	{
		internal delegate double FloatOp(double a, double b);
		string _name;
		FloatOp _op;
		internal BinaryFloatOperator(Expression left, Expression right, string name, FloatOp op) : 
			base(left, right) 
		{
			_name = name;
			_op = op;
		}
		protected override object Compute(object left, object right)
		{
			double lv = 0;
			double rv = 0;
			if (!Marshal.TryToType<double>(left, out lv) ||
				!Marshal.TryToType<double>(right, out rv))
				return null;
			return _op(lv, rv);
		}
		public override string ToString()
		{
			return _name + "(" + Left + "," + Right +  ")";
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
			base(first, second, third) 
		{ }
		protected override object Compute(object a, object b, object t)
		{
			float4 av = float4(0), bv = float4(0);
			int asize = 0, bsize = 0;
			float tv = 0;

			var aValid = Marshal.TryToZeroFloat4(a, out av, out asize);
			var bValid = Marshal.TryToZeroFloat4(b, out bv, out bsize);
			var tValid = Marshal.TryToType<float>(t, out tv);
			if (!aValid)
				Fuse.Diagnostics.UserWarning("The first argument of lerp is not supported.", this);
			if (!bValid)
				Fuse.Diagnostics.UserWarning("The second argument of lerp is not supported.", this);
			if (!tValid)
				Fuse.Diagnostics.UserWarning("The third argument of lerp is not supported.", this);

			if (!aValid ||
				!bValid	||
				!tValid)
				return null;

			int size = Math.Max(asize, bsize);
			
			switch (size)
			{
				case 1:
					return Math.Lerp(av.X, bv.X, tv);
				case 2:
					return Math.Lerp(av.XY, bv.XY, tv);
				case 3:
					return Math.Lerp(av.XYZ, bv.XYZ, tv);
				case 4:
					return Math.Lerp(av, bv, tv);
			}
				
			return null;
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
			base(first, second, third) 
		{ }
		protected override object Compute(object a, object mn, object mx)
		{
			float4 av = float4(0);
			float mxv = 0, mnv = 0;
			int size = 0;
			if (!Marshal.TryToZeroFloat4(a, out av, out size) ||
				!Marshal.TryToType<float>(mn, out mnv) ||
				!Marshal.TryToType<float>(mx, out mxv))
				return null;
			
			if (size == 1)
				return Math.Clamp(av.X, mnv, mxv);
			if (size == 2)
				return Math.Clamp(av.XY, mnv, mxv);
			if (size == 3)
				return Math.Clamp(av.XYZ, mnv, mxv);
			if (size == 4)
				return Math.Clamp(av, mnv, mxv);
				
			return null;
		}
		public override string ToString()
		{
			return "clamp(" + First + "," + Second +  "," + Third + ")";
		}
	}
}