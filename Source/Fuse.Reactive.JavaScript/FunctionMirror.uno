using Uno;
using Uno.Collections;
using Uno.Testing;
using Uno.Threading;
using Fuse.Scripting;

namespace Fuse.Reactive
{
	class FunctionMirror: DiagnosticSubject, IEventHandler, IRaw
	{
		readonly Function _func;

		public object Raw { get { return _func; } }
		public object ReflectedRaw { get { return _func; } }

		public FunctionMirror(Function func)
		{
			_func = func;
		}

		class CallClosure
		{
			readonly FunctionMirror _f;
			readonly IEventRecord _e;

			public CallClosure(FunctionMirror f, IEventRecord e)
			{
				_f = f;
				_e = e;
			}

			public void Call()
			{
				_f.ClearDiagnostic();

				var obj = JavaScript.Worker.Context.NewObject();
				if (_e.Node != null) obj["node"] = JavaScript.Worker.Unwrap(_e.Node);
				if (_e.Data != null) obj["data"] = JavaScript.Worker.Unwrap(_e.Data);
				if (_e.Sender != null) obj["sender"] = _e.Sender;

				if (_e.Args != null)
					foreach (var arg in _e.Args) obj[arg.Key] = JavaScript.Worker.Unwrap(arg.Value);

				try
				{
					_f._func.Call(obj);
				}
				catch( ScriptException ex )
				{
					if defined(FUSELIBS_NO_TOASTS)
						_f.SetDiagnostic(ex);
					else
						JavaScript.UserScriptError( "JavaScript call error", ex, this );
				}
			}
		}

		public void Dispatch(IEventRecord e)
		{
			JavaScript.Worker.Invoke(new CallClosure(this, e).Call);
		}
	}

	
}
