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
			if (TryToDouble(v, out res)) return res;
			throw new MarshalException(v, typeof(double));
		}

		/**
			@deprecated Name kept for compatibility, use `TryToDouble` instead 2017-10-19
		*/
		[Obsolete]
		public static bool ToDouble(object v, out double res)
		{
			return TryToDouble( v, out res );
		}
		
		public static bool TryToDouble( object v, out double res )
		{
			if (v is double) { res = (double)v; return true; }
			else if (v is float) { res = (double)(float)v; return true; }
			else if (v is string) { return TryToDouble((string)v, out res); }
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
		
		public static bool TryToFloat( object v, out float res )
		{
			double d;
			if (!TryToDouble(v, out d))
			{
				res = default(float);
				return false;
			}
			
			res = (float)d;
			return true;
		}

		/**
			@deprecated use `TryToDouble` instead 2017-10-19
		*/
		[Obsolete]
		public static bool ToDouble(string s, out double res)
		{
			return double.TryParse(s, out res);
		}
		
		public static bool TryToDouble(string s, out double res)
		{
			return double.TryParse(s, out res);
		}

		static float4 ToFloat4(float3 f)
		{
			return float4(f.X, f.Y, f.Z, 1.0f);
		}

		static float4 ToFloat4(float2 f)
		{
			return float4(f.X, f.Y, f.X, f.Y);
		}

		static float4 ToFloat4(float f)
		{
			return float4(f);
		}

		public static float4 ToFloat4(object o)
		{
			if (o is float4)
				return (float4)o;
			else if (o is float3)
				return ToFloat4((float3)o);
			else if (o is float2)
				return ToFloat4((float2)o);
			else if (o is float)
				return ToFloat4((float)o);
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

				switch (a.Length)
				{
					case 0: return default(float4);
					case 1: return ToFloat4(x);
					case 2: return ToFloat4(float2(x, y));
					case 3: return ToFloat4(float3(x, y, z));
					default:
						return float4(x, y, z, w);
				}
			}

			double d;
			if (TryToDouble(o, out d))
			{
				var f = (float)d;
				return float4(f);
			}

			throw new MarshalException(o, typeof(float4));
		}
		
		/**
			Converts a value to a float4. Unlike `ToFloat4` this will zero extend the missing components.
			
			@return true if converted successfully, false if no suitable conversion exists. `null` cannot be converted and will return false;
			@param value the result value (0 padded as necessary)
			@param size the size of the result
			
		*/
		public static bool TryToZeroFloat4(object o, out float4 value, out int size)
		{
			value = float4(0);
			size = 0;
			
			if (o is float4) 
			{
				value = (float4)o;
				size = 4;
				return true;
			}
			
			if (o is float3)
			{
				var f = (float3)o;
				value = float4(f.X, f.Y, f.Z, 0);
				size = 3;
				return true;
			}
			
			if (o is float2)
			{
				var f = (float2)o;
				value = float4(f.X, f.Y, 0, 0);
				size = 2;
				return true;
			}
			
			if (o is string)
			{
				var s = (string)o;
				if (s.StartsWith("#"))
				{
					//TODO: once https://github.com/fusetools/uno/pull/1383 is avialble use Color.TryParse instead
					try
					{
						value = Uno.Color.FromHex(s);
						size = 4;
						return true;
					}
					catch (Exception ex)
					{
						return false;
					}
				}
			}
			else if (o is IArray)
			{
				var a = (IArray)o;
				float x = 0,y = 0,z = 0,w =0;
				if (!TryToFloat( a[0], out x ) ||
					!TryToFloat( a[1], out y ) ||
					!TryToFloat( a[2], out z ) ||
					!TryToFloat( a[3], out w ))
					return false;
					
				value = float4(x,y,z,w);
				size = a.Length;
				return true;
			}

			double d;
			if (TryToDouble(o, out d))
			{
				var f = (float)d;
				value = float4(f,0,0,0);
				size = 1;
				return true;
			}

			return false;
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
			else if (o is string) return StringToSize((string)o);
			else return ToFloat(o);
		}

		public static Size2 ToSize2(object o)
		{
			if (o is Size2) return (Size2) o;
			else if (o is Size) return new Size2((Size)o, (Size)o);
			else if (o is string) return StringToSize2((string)o);
			else if (o is IArray) return ToSize2(ToVector((IArray)o));
			else return new Size2(ToFloat2(o).X, ToFloat2(o).Y);
		}

		static Size2 StringToSize2(string o)
		{
			if (o.Contains(","))
			{
				var p = o.Split(',');
				return new Size2(StringToSize(p[0]), StringToSize(p[1]));
			}
			else
			{
				var s = StringToSize(o);
				return new Size2(s, s);
			}
		}

		static Size StringToSize(string o)
		{
			var s = o.Trim();
			var unit = Unit.Unspecified;
			if (s.EndsWith("%")) { unit = Unit.Percent; s = s.Substring(0, s.Length-1); }
			else if (s.EndsWith("pt")) { unit = Unit.Points; s = s.Substring(0, s.Length-2); }
			else if (s.EndsWith("px")) { unit = Unit.Pixels; s = s.Substring(0, s.Length-2); }
			
			float v;
			if (!float.TryParse(s, out v))
			{
				throw new MarshalException(o, typeof(Size));
			}

			return new Size(v, unit);
		}
	}
}
