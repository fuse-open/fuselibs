using Uno;
using Uno.Collections;
using Uno.Testing;
using Uno.Threading;
using Fuse.Scripting;
using Fuse.Reactive;

namespace Fuse.Scripting
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

			public void Call(Scripting.Context context)
			{
				_f.ClearDiagnostic();

				var obj = context.NewObject();
				if (_e.Node != null) obj["node"] = Reactive.JavaScript.Worker.Unwrap(_e.Node);
				if (_e.Data != null) obj["data"] = Reactive.JavaScript.Worker.Unwrap(_e.Data);
				if (_e.Sender != null) obj["sender"] = _e.Sender;

				if (_e.Args != null)
					foreach (var arg in _e.Args) obj[arg.Key] = JavaScript.Worker.Unwrap(arg.Value);

				try
				{
					_f._func.Call(obj);
				}
				catch( ScriptException ex )
				{
					_f.SetDiagnostic(ex);
				}
			}
		}

		public void Dispatch(IEventRecord e)
		{
			JavaScript.Worker.Invoke(new CallClosure(this, e).Call);
		}
	}

	
}
