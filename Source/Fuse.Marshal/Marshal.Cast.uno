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
					return Uno.Color.Parse(s);
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
					if (Uno.Color.TryParse(s, out value))
					{
						size = 4;
						return true;
					}

					return false;
				}
			}
			else if (o is IArray)
			{
				var a = (IArray)o;
				float x = 0,y = 0,z = 0,w =0;
				if ( (a.Length > 0 && !TryToFloat( a[0], out x )) ||
					(a.Length > 1 && !TryToFloat( a[1], out y )) ||
					(a.Length > 2 && !TryToFloat( a[2], out z )) ||
					(a.Length > 3 && !TryToFloat( a[3], out w )))
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
		
		/**
			Converts a float3, float4 or equivalently convertible type to a float4. This  uses color conversion rules: it sets the alpha component to 1 if not specified.
			
			@return true if converted successfully, false if no suitable conversion exists. `null` cannot be converted and will return false;
			@param value the result value
		*/
		public static bool TryToColorFloat4(object o, out float4 value)
		{
			value = float4(0);
			int size = 0;
			if (!TryToZeroFloat4(o, out value, out size))
				return false;
			if (size != 4 && size !=3)
				return false;
				
			if (size == 3)
				value[3] = 1;
				
			return true;
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
			Size a = new Size();
			if (!TryToSize(o, out a))
				throw new MarshalException(o, typeof(Size));
			return a;
		}
			
		public static bool TryToSize(object o, out Size result)
		{
			result = new Size();
			
			if (o is Size) 
			{
				result = (Size)o;
				return true;
			}
			if (o is Size2) 
			{
				result = ((Size2)o).X;
				return true;
			}
			if (o is string)
				return TryStringToSize((string)o, out result);
				
			float v;
			if (!TryToFloat(o, out v))
				return false;
			result = new Size(v, Unit.Unspecified);
			return true;
		}

		public static Size2 ToSize2(object o)
		{
			Size2 a = new Size2();
			if (!TryToSize2(o, out a))
				throw new MarshalException(o, typeof(Size2));
			return a;
		}
		
		public static bool TryToSize2(object o, out Size2 result)
		{
			int ignore;
			return TryToSize2(o, out result, out ignore);
		}
		
		/** Convert to a Size type up to Size2 returning the count of the elements provided in the input. */
		public static bool TryToSize2(object o, out Size2 result, out int count)
		{
			result = new Size2();
			count = 0;
			
			if (o is Size2) 
			{
				result = (Size2) o;
				count = 2;
				return true;
			}
			if (o is Size)
			{
				result = new Size2((Size)o, (Size)o);
				count = 1;
				return true;
			}
			if (o is string) 
				return TryStringToSize2((string)o, out result, out count);
			
			if (o is IArray)
			{
				var arr = (IArray)o;
				if (arr.Length < 2) // See not below on TryToZeroFloat about why we can't do != 2 here
					return false;
				Size a = new Size();
				Size b = new Size();
				if (!TryToSize(arr[0], out a) || !TryToSize(arr[1], out b))
					return false;
					
				result = new Size2(a,b);
				count = 2;
				return true;
			}
			
			float4 v;
			int vc;
			//ideally we'd also fail if `vc > 2`, but there's a strange check in `MarshalTest.TestVector` expecting long values to convert to Size/Size2 !
			if (!TryToZeroFloat4(o, out v, out vc) || vc < 1)
				return false;
			if (vc == 1)
				result = new Size2(v.X, v.X);
			else
				result = new Size2(v.X, v.Y);
			count = vc;
			return true;
		}

		static bool TryStringToSize2(string o, out Size2 result, out int count)
		{
			result = new Size2();
			count = 0;
			
			if (o.Contains(","))
			{
				var p = o.Split(',');
				if (p.Length !=2)
					return false;
					
				Size a = new Size();
				Size b = new Size();
				if (!TryStringToSize(p[0], out a) ||
					!TryStringToSize(p[1], out b))
					return false;
				result = new Size2(a,b);
				count = 2;
				return true;
			}
			else
			{
				Size a;
				if (!TryStringToSize(o, out a))
					return false;
				result = new Size2(a,a);
				count = 1;
				return true;
			}
		}

		static bool TryStringToSize(string o, out Size result)
		{
			var s = o.Trim();
			var unit = Unit.Unspecified;
			if (s.EndsWith("%")) { unit = Unit.Percent; s = s.Substring(0, s.Length-1); }
			else if (s.EndsWith("pt")) { unit = Unit.Points; s = s.Substring(0, s.Length-2); }
			else if (s.EndsWith("px")) { unit = Unit.Pixels; s = s.Substring(0, s.Length-2); }
			
			float v;
			if (!float.TryParse(s, out v))
			{
				result = new Size();
				return false;
			}

			result = new Size(v, unit);
			return true;
		}
	}
}
