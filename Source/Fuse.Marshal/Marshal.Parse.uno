using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse
{
	public static partial class Marshal
	{
		public static object Parse(string s)
		{
			var p = s.Split(',');
			if (p.Length == 2)
			{
				var x = Parse(p[0]);
				var y = Parse(p[1]);
				if (x is Size || y is Size) return new Size2(ToSize(x), ToSize(y));
				else return float2(ToFloat(x), ToFloat(y));
			}
			else if (p.Length == 3)
			{
				var x = Parse(p[0]);
				var y = Parse(p[1]);
				var z = Parse(p[2]);
				return float3(ToFloat(x), ToFloat(y), ToFloat(z));
			}
			else if (p.Length == 4)
			{
				var x = Parse(p[0]);
				var y = Parse(p[1]);
				var z = Parse(p[2]);
				var w = Parse(p[3]);
				return float4(ToFloat(x), ToFloat(y), ToFloat(z), ToFloat(w));
			}

			if (s == "true") return true;
			if (s == "false") return false;

			if (s.Contains("#"))
				return Uno.Color.Parse(s);

			var unit = Unit.Unspecified;
			if (s.EndsWith("px"))
			{
				unit = Unit.Pixels;
				s = s.Substring(0, s.Length-2);
			}
			else if (s.EndsWith("pt"))
			{
				unit = Unit.Points;
				s = s.Substring(0, s.Length-2);
			}
			else if (s.EndsWith("%"))
			{
				unit = Unit.Pixels;
				s = s.Substring(0, s.Length-1);
			}

			var v = double.Parse(s);

			if (unit != Unit.Unspecified) return new Size((float)v, unit);
			else return v;
		}
	}
}
