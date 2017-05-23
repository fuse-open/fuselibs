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
			//this rounds floats automatically it seems
			var q = (int)Math.Floor(Marshal.ToType<float>(operand)+0.5f);
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
			var q = (int)Math.Floor(Marshal.ToType<float>(operand)+0.5f);
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
			var value = (int)Math.Floor(Marshal.ToType<float>(left)+0.5f);
			var group = (int)Math.Floor(Marshal.ToType<float>(right)+0.5f);
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
			if (Marshal.TryMarshalToFloat4(operand, out v, out size))
			{	
				if (size == 1)
					return _op(v[0]);
				if (size == 2)
					return float2((float)_op(v[0]),(float)_op(v[1]));
				if (size == 3)
					return float3((float)_op(v[0]),(float)_op(v[1]),(float)_op(v[2]));
				if (size == 4)
					return float4((float)_op(v[0]),(float)_op(v[1]),(float)_op(v[2]),(float)_op(v[3]));
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
			return _op(Marshal.ToType<double>(left), Marshal.ToType<double>(right));
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

	[UXFunction("lerp")]
	/**
		Calculates the linear interpolation between two values.
		
			lerp( from, to, step )
			
		When step==0 the result is `from`, when step==1 the result is `to`. Partial values are linearly interpolated. Step values <0 and >1 are also supported.
		
		The input supports a 1-4 component value for `from` and `to`. The result will be same size. 
		`step` must always be a single value.
	*/
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
			if (!Marshal.TryMarshalToFloat4(a, out av, out asize) ||	
				!Marshal.TryMarshalToFloat4(b, out bv, out bsize))
				return null;
			int size = Math.Max(asize, bsize);
			
			var tv = Marshal.ToType<float>(t);
			
			if (size == 1)
				return Math.Lerp(av.X, bv.X, tv);
			if (size == 2)
				return Math.Lerp(av.XY, bv.XY, tv);
			if (size == 3)
				return Math.Lerp(av.XYZ, bv.XYZ, tv);
			if (size == 4)
				return Math.Lerp(av, bv, tv);
				
			return null;
		}
		public override string ToString()
		{
			return "lerp(" + First + "," + Second +  "," + Third + ")";
		}
	}
	
}