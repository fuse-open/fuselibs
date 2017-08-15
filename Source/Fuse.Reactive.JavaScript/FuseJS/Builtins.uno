using Uno;
using Uno.IO;
using Fuse.Scripting;

namespace Fuse.Reactive.FuseJS
{
	internal class Builtins
	{
		static FuseJS.TimerModule _timer;

		internal readonly Function Observable;
		internal readonly Function TreeObservable;
		internal readonly Function EventEmitter;
		internal readonly Function Date;
		internal readonly Function DateCtor;

		internal Builtins(Fuse.Scripting.Context context)
		{
			// Init builtin objects
			DebugLog.Init(context);
			Console.Init(context);

			// NOTE: the promise library uses setTimeout, so we load that first
			object res;
			if (Uno.UX.Resource.TryFindGlobal("FuseJS/Timer", IsModule, out res))
				_timer = (FuseJS.TimerModule)res;
			else
				_timer = new Fuse.Reactive.FuseJS.TimerModule();
			
			var setTimout = (Scripting.Function) context.Evaluate("fuse-builtins: setTimeout", import("setTimeout.js").ReadAllText());
			if (setTimout != null && _timer != null)
				setTimout.Call(_timer.EvaluateExports(context, "FuseJS/Timer"), context.GlobalObject);
			else
				throw new Exception("Could not load setTimout function to context.");

			if defined(ios)
			{
				// fix for ios 10 broken promise implementation, ensure we always use our polyfill instead
				// This resets the default Promise implementation in JavascriptCore
				context.Evaluate("fuse-builtins", "Promise = undefined;");
			}
			context.Evaluate("fuse-builtins: es6-promise", import("../3rdparty/es6-promise.min.js").ReadAllText());
			context.Evaluate("fuse-builtins: es6-promise", "ES6Promise.polyfill();");

			//load/register Diagnostics
			new DiagnosticsImplModule();
			new FileModule(import("Diagnostics.js")).EvaluateExports(context, "FuseJS/Diagnostics");
			
			Observable = (Scripting.Function)new FileModule(import("Observable.js")).EvaluateExports(context, "FuseJS/Observable");
			TreeObservable = (Scripting.Function)new FileModule(import("TreeObservable.js")).EvaluateExports(context, "FuseJS/TreeObservable");
			EventEmitter = EventEmitterModule.GetConstructor(context);
			Date = (Scripting.Function)context.Evaluate("fuse-builtins", "Date");
			DateCtor = (Scripting.Function)context.Evaluate("fuse-builtins", "(function(ticks) { return new Date(ticks); })");
			
			res = null;
			// TODO: This should eventually be an optional module. It's here until we accept to break stuff.
			if (Uno.UX.Resource.TryFindGlobal("Polyfills/Window", IsModule, out res))
				((Module)res).Evaluate(context, "Polyfills/Window");
		}
		
		static bool IsModule(object module)
		{
			return module is Module;
		}

		internal double MinTimeout
		{
			get
			{
				if (_timer != null)
					return _timer.MinTimeout;
				return double.MaxValue;
			}
		}

		internal void UpdateModules(Fuse.Scripting.Context context)
		{
			if(_timer != null)
				_timer.UpdateModule();
		}
	}
}
