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
		public abstract object Add(object a, object b);
		public abstract object Subtract(object a, object b);
		public abstract object Multiply(object a, object b);
		public abstract object Divide(object a, object b);
		public abstract bool LessThan(object a, object b);
		public abstract bool LessOrEqual(object a, object b);
		public abstract bool GreaterThan(object a, object b);
		public abstract bool GreaterOrEqual(object a, object b);
		public abstract bool EqualTo(object a, object b);
		public abstract object Min(object a, object b);
		public abstract object Max(object a, object b);
	}

	abstract class Computer<T>: Computer
	{
		public abstract T Convert(object o);
		public sealed override object Add(object a, object b) { return Add(Convert(a), Convert(b)); }
		public sealed override object Subtract(object a, object b) { return Subtract(Convert(a), Convert(b)); }
		public sealed override object Multiply(object a, object b) { return Multiply(Convert(a), Convert(b)); }
		public sealed override object Divide(object a, object b) { return Divide(Convert(a), Convert(b)); }
		public sealed override bool LessThan(object a, object b) { return LessThan(Convert(a), Convert(b)); }
		public sealed override bool LessOrEqual(object a, object b) { return LessOrEqual(Convert(a), Convert(b)); }
		public sealed override bool GreaterThan(object a, object b) { return GreaterThan(Convert(a), Convert(b)); }
		public sealed override bool GreaterOrEqual(object a, object b) { return GreaterOrEqual(Convert(a), Convert(b)); }
		public sealed override bool EqualTo(object a, object b) { return EqualTo(Convert(a), Convert(b)); }
		public sealed override object Min(object a, object b) { return Min(Convert(a), Convert(b)); }
		public sealed override object Max(object a, object b) { return Max(Convert(a), Convert(b)); }
		public virtual T Add(T a, T b) { throw new ComputeException("Add", a, b); }
		public virtual T Subtract(T a, T b) { throw new ComputeException("Subtract", a, b); }
		public virtual T Multiply(T a, T b) { throw new ComputeException("Multiply", a, b); }
		public virtual T Divide(T a, T b) { throw new ComputeException("Divide", a, b); }
		public virtual bool LessThan(T a, T b) { throw new ComputeException("LessThan", a, b); }
		public virtual bool LessOrEqual(T a, T b) { throw new ComputeException("LessOrEqual", a, b); }
		public virtual bool GreaterThan(T a, T b) { throw new ComputeException("GreaterThan", a, b); }
		public virtual bool GreaterOrEqual(T a, T b) { throw new ComputeException("GreaterOrEqual", a, b); }
		public virtual bool EqualTo(T a, T b) { throw new ComputeException("EqualTo", a, b); }
		public virtual T Min(T a, T b) { throw new ComputeException("Min", a, b); }
		public virtual T Max(T a, T b) { throw new ComputeException("Max", a, b); }
	}

	class StringComputer: Computer<string>
	{
		public override string Convert(object obj) { return obj.ToString(); }
		public override string Add(string a, string b) { return a+b; }
		public override bool EqualTo(string a, string b) { return a==b; }
	}

	class NumberComputer: Computer<double>
	{
		public override double Convert(object obj) { return Marshal.ToDouble(obj); }
		public override double Add(double a, double b) { return a+b; }
		public override double Subtract(double a, double b) { return a-b; }
		public override double Multiply(double a, double b) { return a*b; }
		public override double Divide(double a, double b) { return a/b; }
		public override bool LessThan(double a, double b) { return a<b; }
		public override bool LessOrEqual(double a, double b) { return a<=b; }
		public override bool GreaterThan(double a, double b) { return a>b; }
		public override bool GreaterOrEqual(double a, double b) { return a>=b; }
		public override bool EqualTo(double a, double b) { return a==b; }
		public override double Min(double a, double b) { return Math.Min(a, b); }
		public override double Max(double a, double b) { return Math.Max(a, b); }
	}

	class SizeComputer: Computer<Size>
	{
		public override Size Convert(object obj) { return Marshal.ToSize(obj); }
		public override Size Add(Size a, Size b) { return a+b; }
		public override Size Subtract(Size a, Size b) { return a-b; }
		public override Size Multiply(Size a, Size b) { return a*b; }
		public override Size Divide(Size a, Size b) { return a/b; }
		public override bool LessThan(Size a, Size b) { return a.Value < b.Value; }
		public override bool LessOrEqual(Size a, Size b) { return a.Value <= b.Value; }
		public override bool GreaterThan(Size a, Size b) { return a.Value > b.Value; }
		public override bool GreaterOrEqual(Size a, Size b) { return a.Value >= b.Value; }
		public override bool EqualTo(Size a, Size b) { return a==b; }
		public override Size Min(Size a, Size b) { return new Size(Math.Min(a.Value, b.Value), Size.Combine(a.Unit, b.Unit)); }
		public override Size Max(Size a, Size b) { return new Size(Math.Max(a.Value, b.Value), Size.Combine(a.Unit, b.Unit)); }
	}

	class Size2Computer: Computer<Size2>
	{
		public override Size2 Convert(object obj) { return Marshal.ToSize2(obj); }
		public override Size2 Add(Size2 a, Size2 b) { return a+b; }
		public override Size2 Subtract(Size2 a, Size2 b) { return a-b; }
		public override Size2 Multiply(Size2 a, Size2 b) { return a*b; }
		public override Size2 Divide(Size2 a, Size2 b) { return a/b; }
		public override bool EqualTo(Size2 a, Size2 b) { return a==b; }
	}

	class Float2Computer: Computer<float2>
	{
		public override float2 Convert(object obj) { return Marshal.ToFloat2(obj); }
		public override float2 Add(float2 a, float2 b) { return a+b; }
		public override float2 Subtract(float2 a, float2 b) { return a-b; }
		public override float2 Multiply(float2 a, float2 b) { return a*b; }
		public override float2 Divide(float2 a, float2 b) { return a/b; }
		public override bool EqualTo(float2 a, float2 b) { return a==b; }
	}

	class Float3Computer: Computer<float3>
	{
		public override float3 Convert(object obj) { return Marshal.ToFloat3(obj); }
		public override float3 Add(float3 a, float3 b) { return a+b; }
		public override float3 Subtract(float3 a, float3 b) { return a-b; }
		public override float3 Multiply(float3 a, float3 b) { return a*b; }
		public override float3 Divide(float3 a, float3 b) { return a/b; }
		public override bool EqualTo(float3 a, float3 b) { return a==b; }
	}

	class Float4Computer: Computer<float4>
	{
		public override float4 Convert(object obj) { return Marshal.ToFloat4(obj); }
		public override float4 Add(float4 a, float4 b) { return a+b; }
		public override float4 Subtract(float4 a, float4 b) { return a-b; }
		public override float4 Multiply(float4 a, float4 b) { return a*b; }
		public override float4 Divide(float4 a, float4 b) { return a/b; }
		public override bool EqualTo(float4 a, float4 b) { return a==b; }
	}
}