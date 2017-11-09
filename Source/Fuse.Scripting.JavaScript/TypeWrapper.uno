using Fuse.Scripting;
using Uno;
using Uno.Collections;
using Uno.Text;
using Uno.Threading;
using Uno.IO;
using Uno.UX;

namespace Fuse.Scripting.JavaScript
{
	static class TypeWrapper
	{
		/** Wraps an object that came from the script VM in an appropriate wrapper
			for use in the Uno world. */
		public static object Wrap(JSContext context, object obj)
		{
			if (obj is Scripting.External) return ((Scripting.External)obj).Object;
			else if (obj is Scripting.Object)
			{
				var sobj = (Scripting.Object)obj;

				if (sobj.InstanceOf(context, context.FuseJS.Date))
				{
					return DateTimeConverterHelpers.ConvertDateToDateTime(context, sobj);
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

		/** Takes an object from the Uno world, removes any wrapping applied by @Wrap
			and returns an object appropriate for passing into the scripting VM */
		public static object Unwrap(JSContext context, object dc)
		{
			if (dc == null) return null;
			else if (dc is string) return dc;
			else if (dc is IRaw) return ((IRaw)dc).ReflectedRaw;
			else if (dc is Scripting.Function) return dc;
			else if (dc is Scripting.Object) return dc;
			else if (dc is Scripting.Array) return dc;
			else if (dc is float2) return ToArray(context, (float2)dc);
			else if (dc is float3) return ToArray(context, (float3)dc);
			else if (dc is float4) return ToArray(context, (float4)dc);
			else if (dc is int2) return ToArray(context, (int2)dc);
			else if (dc is int3) return ToArray(context, (int3)dc);
			else if (dc is int4) return ToArray(context, (int4)dc);
			else if (dc is DateTime) return DateTimeConverterHelpers.ConvertDateTimeToJSDate(context, (DateTime)dc, context.FuseJS.DateCtor);
			else if (dc.GetType().IsClass) return WrapScriptClass(context, dc);
			else if (dc.GetType().IsEnum) return dc.ToString();
			else return dc;
		}

		static Scripting.Array ToArray(JSContext context, float2 v)
		{
			return context.NewArray((double)v.X, (double)v.Y);
		}

		static Scripting.Array ToArray(JSContext context, float3 v)
		{
			return context.NewArray((double)v.X, (double)v.Y, (double)v.Z);
		}

		static Scripting.Array ToArray(JSContext context, float4 v)
		{
			return context.NewArray((double)v.X, (double)v.Y, (double)v.Z, (double)v.W);
		}

		static Scripting.Array ToArray(JSContext context, int2 v)
		{
			return context.NewArray((double)v.X, (double)v.Y);
		}

		static Scripting.Array ToArray(JSContext context, int3 v)
		{
			return context.NewArray((double)v.X, (double)v.Y, (double)v.Z);
		}

		static Scripting.Array ToArray(JSContext context, int4 v)
		{
			return context.NewArray((double)v.X, (double)v.Y, (double)v.Z, (double)v.W);
		}

		static object WrapScriptClass(JSContext context, object obj)
		{
			var so = obj as IScriptObject;
			if (so != null && so.ScriptObject != null) return so.ScriptObject;

			var ext = new External(obj);

			var sc = ScriptClass.Get(obj.GetType());
			if (sc == null) return ext;

			var ctor = context.GetClass(sc);
			var res = ctor.Construct(context, ext);

			if (so != null) so.SetScriptObject(res, context);
			return res;
		}
	}
}
