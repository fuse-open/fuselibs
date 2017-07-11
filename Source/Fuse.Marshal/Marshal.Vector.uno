using Uno.UX;

namespace Fuse
{
	public static partial class Marshal
	{
		static object ToVector(IArray arr)
		{
			if (arr.Length == 1) 
			{
				if (arr[0] is Size) return (Size)arr[0];
				else return Marshal.ToFloat(arr[0]);
			}
			else if (arr.Length == 2)
			{
				if (arr[0] is Size || arr[1] is Size) return new Size2(Marshal.ToSize(arr[0]), Marshal.ToSize(arr[1]));
				else return float2(Marshal.ToFloat(arr[0]), Marshal.ToFloat(arr[1]));
			}
			else if (arr.Length == 3)
			{
				return float3(Marshal.ToFloat(arr[0]), Marshal.ToFloat(arr[1]), Marshal.ToFloat(arr[2]));
			}
			else if (arr.Length == 4)
			{
				return float4(Marshal.ToFloat(arr[0]), Marshal.ToFloat(arr[1]), Marshal.ToFloat(arr[2]), Marshal.ToFloat(arr[3]));
			}
			else throw new MarshalException(arr, typeof(float4));
		}

		static object TryConvertArrayToVector(object arg)
		{
			var arr = arg as IArray;
			if (arr != null) return ToVector(arr);
			return arg;
		}
	}
}