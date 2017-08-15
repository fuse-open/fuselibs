using Fuse.Scripting;
using Uno;
using Uno.Collections;
using Uno.Text;
using Uno.Threading;
using Uno.IO;
using Uno.UX;

namespace Fuse.Reactive
{
	static class DateTimeConverterHelpers
	{
		const long DotNetTicksInJsTick = 10000L;
		const long UnixEpochInDotNetTicks = 621355968000000000L;

		public static DateTime ConvertDateToDateTime(Scripting.Object date)
		{
			var jsTicks = (long)(double)ThreadWorker.Wrap(date.CallMethod("getTime"));
			var dotNetTicksRelativeToUnixEpoch = jsTicks * DotNetTicksInJsTick;
			var dotNetTicks = dotNetTicksRelativeToUnixEpoch + UnixEpochInDotNetTicks;

			return new DateTime(dotNetTicks, DateTimeKind.Utc);
		}

		public static object ConvertDateTimeToJSDate(DateTime dt, Scripting.Function dateCtor)
		{
			// TODO: This assumes dt's `Kind` is set to `Utc`. The `Ticks` value may have to be adjusted if `Kind` is `Local` or `Unspecified`.
			//  Currently we don't support other `Kind`'s than `Utc`, but when we do, this code should be updated accordingly.
			//  Something like: `if (dt.Kind != DateTimeKind.Utc) { dt = dt.ToUniversalTime(); }`
			var dotNetTicks = dt.Ticks;
			var dotNetTicksRelativeToUnixEpoch = dotNetTicks - UnixEpochInDotNetTicks;
			var jsTicks = dotNetTicksRelativeToUnixEpoch / DotNetTicksInJsTick;

			return dateCtor.Call((double)jsTicks);
		}
	}

	partial class ThreadWorker
	{
		/** Wraps an object that came from the script VM in an appropriate wrapper
			for use in the Uno world. */
		public static object Wrap(object obj)
		{
			if (obj is Scripting.External) return ((Scripting.External)obj).Object;
			else if (obj is Scripting.Object)
			{
				var sobj = (Scripting.Object)obj;

				if (sobj.InstanceOf(FuseJS.Date))
				{
					return DateTimeConverterHelpers.ConvertDateToDateTime(sobj);
				}
				else if (sobj.ContainsKey("external_object"))
				{
					var ext = sobj["external_object"] as Scripting.External;
					if (ext != null) return ext.Object;
				}
			}
			if (obj is float) return (double)(float)obj;
			if (obj is int) return (double)(int)obj;
			if (obj is uint) return (double)(uint)obj;
			return obj;
		}

		object Scripting.IThreadWorker.Wrap(object obj)
		{
			return ThreadWorker.Wrap(obj);
		}

		/** Takes an object from the Uno world, removes any wrapping applied by @Wrap
			and returns an object appropriate for passing into the scripting VM */
		public object Unwrap(object dc)
		{
			if (dc == null) return null;
			else if (dc is string) return dc;
			else if (dc is IRaw) return ((IRaw)dc).ReflectedRaw;
			else if (dc is Scripting.Function) return dc;
			else if (dc is Scripting.Object) return dc;
			else if (dc is Scripting.Array) return dc;
			else if (dc is float2) return ToArray((float2)dc);
			else if (dc is float3) return ToArray((float3)dc);
			else if (dc is float4) return ToArray((float4)dc);
			else if (dc is int2) return ToArray((int2)dc);
			else if (dc is int3) return ToArray((int3)dc);
			else if (dc is int4) return ToArray((int4)dc);
			else if (dc is DateTime) return DateTimeConverterHelpers.ConvertDateTimeToJSDate((DateTime)dc, FuseJS.DateCtor);
			else if (dc.GetType().IsClass) return WrapScriptClass(dc);
			else if (dc.GetType().IsEnum) return dc.ToString();
			else return dc;
		}

		Scripting.Array ToArray(float2 v)
		{
			return Context.NewArray((double)v.X, (double)v.Y);
		}

		Scripting.Array ToArray(float3 v)
		{
			return Context.NewArray((double)v.X, (double)v.Y, (double)v.Z);
		}

		Scripting.Array ToArray(float4 v)
		{
			return Context.NewArray((double)v.X, (double)v.Y, (double)v.Z, (double)v.W);
		}

		Scripting.Array ToArray(int2 v)
		{
			return Context.NewArray((double)v.X, (double)v.Y);
		}

		Scripting.Array ToArray(int3 v)
		{
			return Context.NewArray((double)v.X, (double)v.Y, (double)v.Z);
		}

		Scripting.Array ToArray(int4 v)
		{
			return Context.NewArray((double)v.X, (double)v.Y, (double)v.Z, (double)v.W);
		}
	}
}
