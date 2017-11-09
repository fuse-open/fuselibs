using Uno.Text;
using Fuse.Scripting;

namespace Fuse.Reactive
{
	static class DebugLog
	{
		public static void Init(Context c)
		{
			c.GlobalObject["debug_log"] = (Callback)Log;
		}

		static object Log(Context context, object[] args)
		{
			for (int i = 0; i < args.Length; i++)
			{
				debug_log((args[i] != null) ? args[i].ToString() : "null");
			}

			return null;
		}
	}

	static class Console
	{
		public static void Init(Context c)
		{

			var console = c.NewObject();
			console["log"] = (Callback)Log;
			console["warn"] = (Callback)Warn;
			console["info"] = (Callback)Info;
			console["error"] = (Callback)Error;
			console["dir"] = (Callback)Dir;
			c.GlobalObject["console"] = console;
		}

		static object LogInternal(Context context, object[] args, Uno.Diagnostics.DebugMessageType debugMessageType)
		{
			var formatted = Format(context, args);
			Uno.Diagnostics.Debug.Log(formatted, debugMessageType);
			return null;
		}

		static object Log(Context context, object[] args)
		{
			return LogInternal(context, args, Uno.Diagnostics.DebugMessageType.Debug);
		}

		static object Warn(Context context, object[] args)
		{
			return LogInternal(context, args, Uno.Diagnostics.DebugMessageType.Warning);
		}

		static object Info(Context context, object[] args)
		{
			return LogInternal(context, args, Uno.Diagnostics.DebugMessageType.Information);
		}

		static object Error(Context context, object[] args)
		{
			return LogInternal(context, args, Uno.Diagnostics.DebugMessageType.Error);
		}

		static string Format(Context context, object[] args)
		{
			var sb = new StringBuilder();
			
			for (var i = 0; i < args.Length; ++i)
			{
				if (i != 0)
					sb.Append(" ");
				
				sb.Append(ToString(context, args[i]));
			}

			return sb.ToString();
		}

		static Function _toStringFunction;
		static string ToString(Context context, object obj)
		{
			if (_toStringFunction == null)
			{
				_toStringFunction = (Function) context.Evaluate("fuse-builtins",
					"(function(obj) {" +
					"	if (obj instanceof Error) return obj.stack;" +
					"	return '' + obj;" +
					"})"
				);
			}

			return _toStringFunction.Call(context, obj).ToString();
		}

		static object Dir(Context context, object[] args)
		{
			const int maxDepth = 1; // Only walk down one level for now
			var builder = new StringBuilder();
			for (int i = 0; i < args.Length; i++)
			{
				Dir(builder, args[i], maxDepth);
			}
			debug_log(builder.ToString());
			return null;
		}

		static void Dir(StringBuilder builder, object obj, int maxDepth = 0, int indent = 0)
		{
			indent++;
			if(obj == null)
			{
				builder.AppendLine("null");
				return;
			}

			if (obj is int || obj is float || obj is double)
			{
				builder.AppendLine(obj.ToString());
				return;
			}

			if (obj is bool)
			{
				builder.AppendLine(obj.ToString().ToLower());
				return;
			}

			if (obj is string)
			{
				builder.AppendLine("\"" + obj.ToString() + "\"");
				return;
			}

			if (obj is Fuse.Scripting.Function)
			{
				//var f = obj as Fuse.Scripting.Function;
				builder.AppendLine("function"); //TODO: print function name
				return;
			}

			if (obj is Fuse.Scripting.Object)
			{
				var o = (Fuse.Scripting.Object)obj;
				builder.AppendLine("Object"); //TODO: print object type
				if (indent <= maxDepth)
				{
					foreach (var k in o.Keys)
					{
						Indent(builder, indent);
					 	builder.Append("" + k + ": ");
						Dir(builder, o[k], maxDepth, indent);
					}
				}
				return;
			}

			if (obj is Fuse.Scripting.Array)
			{
				var a = (Fuse.Scripting.Array)obj;
				builder.AppendLine("Array[" + a.Length + "]");
				if (indent <= maxDepth)
				{
					for (int i = 0; i < a.Length; i++)
					{
						Indent(builder, indent);
						builder.Append("" + i + ": ");
						Dir(builder, a[i], maxDepth, indent);
					}
				}
				return;
			}

			builder.AppendLine(obj.ToString());
		}

		static void Indent(StringBuilder builder, int indent)
		{
			for (int i = 0; i < indent; i++)
				builder.Append("  ");
		}

	}
}
