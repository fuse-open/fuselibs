using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Runtime.InteropServices;
using System.Threading.Tasks;
using JR = Jurassic;

namespace Fuse.Scripting.Jurassic
{
	public class ContextHandle
	{

		public JR.ScriptEngine Engine { get { return _engine; } }

		readonly JR.ScriptEngine _engine;

		public ContextHandle(JR.ScriptEngine engine)
		{
			_engine = engine;
		}
	}

	public static class ContextImpl
	{
		public static ContextHandle Create()
		{
			return new ContextHandle(new JR.ScriptEngine());
		}

		public static void ThrowJavaScriptException(ContextHandle handle, string message)
		{
			throw new JR.JavaScriptException(handle.Engine, "Error", message);
		}

		public static ObjectHandle MakeObject(ContextHandle handle)
		{
			var objectInstance = handle.Engine.Object.Construct();
			return new ObjectHandle(objectInstance);
		}

		public static ArrayHandle MakeArray(ContextHandle handle)
		{
			var arrayInstance = handle.Engine.Array.Construct();
			return new ArrayHandle(arrayInstance);
		}

		public static object Evaluate(ContextHandle handle, string code)
		{
			var result = Helpers.Try(() => handle.Engine.Evaluate((code)));
			return Helpers.ToHandle(result);
		}

		public static object Evaluate(ContextHandle handle, string name, string code)
		{
			var result = Helpers.Try(() => handle.Engine.Evaluate(new JR.StringScriptSource(code, name)));
			return Helpers.ToHandle(result);
		}

		public static ObjectHandle GetGlobalObject(ContextHandle handle)
		{
			return new ObjectHandle(handle.Engine.Global);
		}

		public static void Dispose(ContextHandle handle) { }
	}



}
