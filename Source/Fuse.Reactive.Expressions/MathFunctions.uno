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

	/** Common base for floating point operations */
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
			return _op(Marshal.ToType<double>(operand));
		}
		public override string ToString()
		{
			return _name + "(" + Operand +  ")";
		}
	}
	
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

	
}