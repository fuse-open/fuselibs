using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Jurassic;
using Jurassic.Library;

namespace Fuse.Scripting.Jurassic
{

	public class FunctionHandle
	{
		public FunctionInstance FunctionInstance { get { return _functionInstance; } }

		readonly FunctionInstance _functionInstance;

		public FunctionHandle(FunctionInstance functionInstance)
		{
			_functionInstance = functionInstance;
		}

		public override bool Equals(object obj)
		{
			var ah = obj as FunctionHandle;
			if (ah == null) return false;
			return _functionInstance.Equals(ah.FunctionInstance);
		}
	}

	public static class FunctionImpl
	{
		public static FunctionHandle FromScriptCallback(ContextHandle contextHandle, Func<object[], object> callback)
		{
			var proxy = new FunctionProxy(contextHandle.Engine, callback);
			return new FunctionHandle(proxy);
		}

		public static object Call(FunctionHandle handle, params object[] args)
		{
			var arguments = Helpers.FromHandles(args);
			object result = null;
			result = Helpers.Try(() => handle.FunctionInstance.Call(null, arguments));
			return Helpers.ToHandle(result);
		}

		public static object Construct(FunctionHandle handle, params object[] args)
		{
			var arguments = Helpers.FromHandles(args);
			object result = null;
			result = Helpers.Try(() => handle.FunctionInstance.ConstructLateBound(arguments));
			return Helpers.ToHandle(result);
		}
	}
}
