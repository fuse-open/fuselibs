using Uno;
using Uno.Collections;
using Uno.Text;
using Uno.Threading;
using Uno.IO;
using Uno.UX;

namespace Fuse.Reactive
{
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

				if (sobj.ContainsKey("external_object"))
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
			else if (dc is IRaw) return ((IRaw)dc).Raw;
			else if (dc is Scripting.Function) return dc;
			else if (dc is float2) return ToArray((float2)dc);
			else if (dc is float3) return ToArray((float3)dc);
			else if (dc is float4) return ToArray((float4)dc);
			else if (dc is int2) return ToArray((int2)dc);
			else if (dc is int3) return ToArray((int3)dc);
			else if (dc is int4) return ToArray((int4)dc);
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
