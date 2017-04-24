using System;
using Jurassic;
using Jurassic.Library;

namespace Fuse.Scripting.Jurassic
{

	public class FunctionProxy : FunctionInstance
	{
		readonly Func<object[], object> _callback;

		public FunctionProxy(ScriptEngine engine, Func<object[], object> callback)
			: base(engine)
		{
			_callback = callback;
		}

		public FunctionProxy(ObjectInstance prototype, Func<object[], object> callback)
			: base(prototype)
		{
			_callback = callback;
		}

		public FunctionProxy(ScriptEngine engine, ObjectInstance prototype, Func<object[], object> callback)
			: base(engine, prototype)
		{
			_callback = callback;
		}

		public override object CallLateBound(object thisObject, params object[] argumentValues)
		{
			if (_callback != null)
			{
                var args = Helpers.ToHandles(argumentValues);
				return Helpers.FromHandle(_callback(args));
			}
			return null;
		}
	}
}