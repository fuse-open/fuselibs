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
		public abstract bool TryAdd(object a, object b, out object result);
		public abstract bool TrySubtract(object a, object b, out object result);
		public abstract bool TryMultiply(object a, object b, out object result);
		public abstract bool TryDivide(object a, object b, out object result);
		public abstract bool TryLessThan(object a, object b, out bool result);
		public abstract bool TryLessOrEqual(object a, object b, out bool result);
		public abstract bool TryGreaterThan(object a, object b, out bool result);
		public abstract bool TryGreaterOrEqual(object a, object b, out bool result);
		public abstract bool TryEqualTo(object a, object b, out bool result);
		public abstract bool TryMin(object a, object b, out object result);
		public abstract bool TryMax(object a, object b, out object result);
	}

	abstract class Computer<T>: Computer
	{
		public bool TryConvert(object o, out T result)
		{
			return Marshal.TryToType<T>(o, out result);
		}

		public sealed override bool TryAdd(object a, object b, out object result)
		{ 
			T ma = default(T);
			T mb = default(T);
			T tr = default(T);
			if (!TryConvert(a,out ma) || !TryConvert(b, out mb) || !TryAddImpl(ma,mb,out tr))
			{
				result = default(T);
				return false;
			}
			result = tr;
			return true;
		}
		public sealed override bool TrySubtract(object a, object b, out object result) 
		{ 
			T ma = default(T);
			T mb = default(T);
			T tr = default(T);
			if (!TryConvert(a,out ma) || !TryConvert(b, out mb) || !TrySubtractImpl(ma,mb,out tr))
			{
				result = default(T);
				return false;
			}
			result = tr;
			return true;
		}
		public sealed override bool TryMultiply(object a, object b, out object result) 
		{ 
			T ma = default(T);
			T mb = default(T);
			T tr = default(T);
			if (!TryConvert(a,out ma) || !TryConvert(b, out mb) || !TryMultiplyImpl(ma,mb, out tr))
			{
				result = default(T);
				return false;
			}
			result = tr;
			return true;
		}
		public sealed override bool TryDivide(object a, object b, out object result)
		{ 
			T ma = default(T);
			T mb = default(T);
			T tr = default(T);
			if (!TryConvert(a,out ma) || !TryConvert(b, out mb) || !TryDivideImpl(ma,mb, out tr))
			{
				result = default(T);
				return false;
			}
			result = tr;
			return true;
		}
		public sealed override bool TryLessThan(object a, object b, out bool result)
		{ 
			T ma = default(T);
			T mb = default(T);
			result = false;
			if (!TryConvert(a,out ma) || !TryConvert(b, out mb))
				return false;
			return TryLessThanImpl(ma,mb, out result);
		}
		public sealed override bool TryLessOrEqual(object a, object b, out bool result)
		{ 
			T ma = default(T);
			T mb = default(T);
			result = false;
			if (!TryConvert(a,out ma) || !TryConvert(b, out mb))
				return false;
			return TryLessOrEqualImpl(ma,mb, out result);
		}
		public sealed override bool TryGreaterThan(object a, object b, out bool result)
		{ 
			T ma = default(T);
			T mb = default(T);
			result = false;
			if (!TryConvert(a,out ma) || !TryConvert(b, out mb))
				return false;
			return TryGreaterThanImpl(ma,mb, out result);
		}
		public sealed override bool TryGreaterOrEqual(object a, object b, out bool result)
		{ 
			T ma = default(T);
			T mb = default(T);
			result = false;
			if (!TryConvert(a,out ma) || !TryConvert(b, out mb))
				return false;
			return TryGreaterOrEqualImpl(ma,mb, out result);
		}
		public sealed override bool TryEqualTo(object a, object b, out bool result) 
		{ 
			T ma = default(T);
			T mb = default(T);
			result = false;
			if (!TryConvert(a,out ma) || !TryConvert(b, out mb))
				return false;
			return TryEqualToImpl(ma,mb, out result);
		}
		public sealed override bool TryMin(object a, object b, out object result) 
		{ 
			T ma = default(T);
			T mb = default(T);
			T tr = default(T);
			if (!TryConvert(a,out ma) || !TryConvert(b, out mb) || !TryMinImpl(ma,mb, out tr))
			{
				result = default(T);
				return false;
			}
			result = tr;
			return true;
		}
		public sealed override bool TryMax(object a, object b, out object result) 
		{ 
			T ma = default(T);
			T mb = default(T);
			T tr = default(T);
			result = default(T);
			if (!TryConvert(a,out ma) || !TryConvert(b, out mb) || !TryMaxImpl(ma,mb, out tr))
			{
				result = default(T);
				return false;
			}
			result = tr;
			return true;
		}
		
		public virtual bool TryAddImpl(T a, T b, out T result) { result = default(T); return false; }
		public virtual bool TrySubtractImpl(T a, T b, out T result) { result = default(T); return false; }
		public virtual bool TryMultiplyImpl(T a, T b, out T result) { result = default(T); return false; }
		public virtual bool TryDivideImpl(T a, T b, out T result) { result = default(T); return false; }
		public virtual bool TryLessThanImpl(T a, T b, out bool result) { result = false; return false; }
		public virtual bool TryLessOrEqualImpl(T a, T b, out bool result) { result = false; return false; }
		public virtual bool TryGreaterThanImpl(T a, T b, out bool result) { result = false; return false; }
		public virtual bool TryGreaterOrEqualImpl(T a, T b, out bool result) { result = false; return false; }
		public virtual bool TryEqualToImpl(T a, T b, out bool result) { result = false; return false; }
		public virtual bool TryMinImpl(T a, T b, out T result) { result = default(T); return false; }
		public virtual bool TryMaxImpl(T a, T b, out T result) { result = default(T); return false; }
	}

	class StringComputer: Computer<string>
	{
		public override bool TryAddImpl(string a, string b, out string result) { result = a+b; return true; }
		public override bool TryEqualToImpl(string a, string b, out bool result) { result = a==b; return true; }
	}

	class NumberComputer: Computer<double>
	{
		public override bool TryAddImpl(double a, double b, out double result ) { result = a+b; return true; }
		public override bool TrySubtractImpl(double a, double b, out double result ) { result = a-b; return true; }
		public override bool TryMultiplyImpl(double a, double b, out double result) { result = a*b; return true; }
		public override bool TryDivideImpl(double a, double b, out double result) { result = a/b; return true; }
		public override bool TryLessThanImpl(double a, double b, out bool result ) { result = a<b; return true; }
		public override bool TryLessOrEqualImpl(double a, double b, out bool result ) { result = a<=b; return true; }
		public override bool TryGreaterThanImpl(double a, double b, out bool result ) { result =  a>b; return true; }
		public override bool TryGreaterOrEqualImpl(double a, double b, out bool result ) { result = a>=b; return true; }
		public override bool TryEqualToImpl(double a, double b, out bool result ) { result = a==b; return true; }
		public override bool TryMinImpl(double a, double b, out double result) { result = Math.Min(a, b); return true; }
		public override bool TryMaxImpl(double a, double b, out double result) { result = Math.Max(a, b); return true; }
	}

	class SizeComputer: Computer<Size>
	{
		public override bool TryAddImpl(Size a, Size b, out Size result) { result = a+b; return true; }
		public override bool TrySubtractImpl(Size a, Size b, out Size result) { result = a-b; return true; }
		public override bool TryMultiplyImpl(Size a, Size b, out Size result) { result = a*b; return true; }
		public override bool TryDivideImpl(Size a, Size b, out Size result) { result = a/b; return true; }
		public override bool TryLessThanImpl(Size a, Size b, out bool result ) { result = a.Value < b.Value; return true; }
		public override bool TryLessOrEqualImpl(Size a, Size b, out bool result ) { result = a.Value <= b.Value; return true; }
		public override bool TryGreaterThanImpl(Size a, Size b, out bool result ) { result = a.Value > b.Value; return true; }
		public override bool TryGreaterOrEqualImpl(Size a, Size b, out bool result ) { result = a.Value >= b.Value; return true; }
		public override bool TryEqualToImpl(Size a, Size b, out bool result ) { result = a==b; return true; }
		public override bool TryMinImpl(Size a, Size b, out Size result) { result = new Size(Math.Min(a.Value, b.Value), Size.Combine(a.Unit, b.Unit)); return true; }
		public override bool TryMaxImpl(Size a, Size b, out Size result) { result = new Size(Math.Max(a.Value, b.Value), Size.Combine(a.Unit, b.Unit)); return true; }
	}

	class Size2Computer: Computer<Size2>
	{
		public override bool TryAddImpl(Size2 a, Size2 b, out Size2 result) { result = a+b; return true; }
		public override bool TrySubtractImpl(Size2 a, Size2 b, out Size2 result) { result = a-b; return true; }
		public override bool TryMultiplyImpl(Size2 a, Size2 b, out Size2 result) { result = a*b; return true; }
		public override bool TryDivideImpl(Size2 a, Size2 b, out Size2 result) { result = a/b; return true; }
		public override bool TryEqualToImpl(Size2 a, Size2 b, out bool result ) { result = a==b; return true; }
	}

	class Float2Computer: Computer<float2>
	{
		public override bool TryAddImpl(float2 a, float2 b, out float2 result) { result = a+b; return true; }
		public override bool TrySubtractImpl(float2 a, float2 b, out float2 result) { result = a-b; return true; }
		public override bool TryMultiplyImpl(float2 a, float2 b, out float2 result) { result = a*b; return true; }
		public override bool TryDivideImpl(float2 a, float2 b, out float2 result) { result = a/b; return true; }
		public override bool TryEqualToImpl(float2 a, float2 b, out bool result ) { result = a==b; return true; }
	}

	class Float3Computer: Computer<float3>
	{
		public override bool TryAddImpl(float3 a, float3 b, out float3 result) { result = a+b; return true; }
		public override bool TrySubtractImpl(float3 a, float3 b, out float3 result) { result = a-b; return true; }
		public override bool TryMultiplyImpl(float3 a, float3 b, out float3 result) { result = a*b; return true; }
		public override bool TryDivideImpl(float3 a, float3 b, out float3 result) { result = a/b; return true; }
		public override bool TryEqualToImpl(float3 a, float3 b, out bool result ) { result = a==b; return true; }
	}

	class Float4Computer: Computer<float4>
	{
		public override bool TryAddImpl(float4 a, float4 b, out float4 result) { result = a+b; return true; }
		public override bool TrySubtractImpl(float4 a, float4 b, out float4 result) { result = a-b; return true; }
		public override bool TryMultiplyImpl(float4 a, float4 b, out float4 result) { result = a*b; return true; }
		public override bool TryDivideImpl(float4 a, float4 b, out float4 result) { result = a/b; return true; }
		public override bool TryEqualToImpl(float4 a, float4 b, out bool result ) { result = a==b; return true; }
	}
}