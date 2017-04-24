using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse
{
	public class MarshalException: Exception
	{
		public MarshalException(object v, Type t) : base("Cannot convert '" + v + "' to required target type '" + t + "'") {}
	}

	public static partial class Marshal
	{
		public static bool ToBool(object v)
		{
			if (v is bool) return (bool)v;
			else if (v is string) 
			{
				var s = (string)v;
				if (s == "true") return true;
				if (s == "True") return true;
				if (s == "false") return false;
				if (s == "False") return false;
			}
			throw new MarshalException(v, typeof(bool));
		}

		public static double ToDouble(object v)
		{
			double res;
			if (ToDouble(v, out res)) return res;
			throw new MarshalException(v, typeof(double));
		}

		public static bool ToDouble(object v, out double res)
		{
			if (v is double) { res = (double)v; return true; }
			else if (v is float) { res = (double)(float)v; return true; }
			else if (v is string) { return ToDouble((string)v, out res); }
			else if (v is int) { res = (double)(int)v; return true; }
			else if (v is float2) { res = ((float2)v).X; return true; }
			else if (v is float3) { res = ((float3)v).X; return true; }
			else if (v is float4) { res = ((float4)v).X; return true; }
			else if (v is Size) { res = ((Size)v).Value; return true; }
			else if (v is Size2) 
			{ 
				var s = (Size2)v;
				var x = s.X;
				res = x.Value; 
				return true; 
			}
			else if (v is uint) { res = (double)(uint)v; return true; }
			else if (v is short) { res = (double)(short)v; return true; }
			else if (v is ushort) { res = (double)(ushort)v; return true; }
			else if (v is byte) { res = (double)(byte)v; return true; }
			else if (v is sbyte) { res = (double)(sbyte)v; return true; }

			res = default(double);
			return false;
		}

		public static bool ToDouble(string s, out double res)
		{
			return double.TryParse(s, out res);
		}

		public static float4 ToFloat4(object o)
		{
			if (o is float4) return (float4)o;
			else if (o is float3)
			{
				var f = (float3)o;
				return float4(f.X, f.Y, f.Z, 1.0f);
			}
			else if (o is float2)
			{
				var f = (float2)o;
				return float4(f.X, f.Y, f.X, f.Y);
			}
			else if (o is string)
			{
				var s = (string)o;
				if (s.StartsWith("#"))
					return Uno.Color.FromHex(s);
			}
			else if (o is Size)
			{
				var s = (Size)o;
				return float4(s.Value);
			}
			else if (o is Size2)
			{
				var s = (Size2)o;
				var x = s.X;
				var y = s.Y;
				return float4(x.Value, y.Value, x.Value, y.Value);
			}
			else if (o is IArray)
			{
				var a = (IArray)o;
				var x = a.Length > 0 ? ToFloat(a[0]) : 0.0f;
				var y = a.Length > 1 ? ToFloat(a[1]) : 0.0f;
				var z = a.Length > 2 ? ToFloat(a[2]) : 0.0f;
				var w = a.Length > 3 ? ToFloat(a[3]) : 1.0f;
				return float4(x,y,z,w);
			}

			double d;
			if (ToDouble(o, out d))
			{
				var f = (float)d;
				return float4(f);
			}

			throw new MarshalException(o, typeof(float4));
		}

		public static float3 ToFloat3(object o)
		{
			if (o is float3) return (float3)o;
			else return ToFloat4(o).XYZ;
		}

		public static float2 ToFloat2(object o)
		{
			if (o is float2) return (float2)o;
			else return ToFloat4(o).XY;
		}

		public static float ToFloat(object o)
		{
			if (o is float) return (float)o;
			else return (float)ToDouble(o);
		}

		public static int ToInt(object o)
		{
			if (o is int) return (int)o;
			else return (int)ToDouble(o);
		}

		public static uint ToUInt(object o)
		{
			if (o is uint) return (uint)o;
			else return (uint)ToDouble(o);
		}

		public static short ToShort(object o)
		{
			if (o is short) return (short)o;
			else return (short)ToInt(o);
		}

		public static ushort ToUShort(object o)
		{
			if (o is ushort) return (ushort)o;
			else return (ushort)ToUInt(o);
		}

		public static sbyte ToSByte(object o)
		{
			if (o is sbyte) return (sbyte)o;
			else return (sbyte)ToInt(o);
		}

		public static short ToByte(object o)
		{
			if (o is byte) return (byte)o;
			else return (byte)ToUInt(o);
		}

		public static Size ToSize(object o)
		{
			if (o is Size) return (Size)o;
			else if (o is Size2) return ((Size2)o).X;
			else return ToFloat(o);
		}

		public static Size2 ToSize2(object o)
		{
			if (o is Size2) return (Size2) o;
			else if (o is Size) return new Size2((Size)o, (Size)o);
			else return new Size2(ToFloat2(o).X, ToFloat2(o).Y);
		}
	}
}