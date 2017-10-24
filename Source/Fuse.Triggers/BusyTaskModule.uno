using Uno;
using Uno.UX;
using Uno.Collections;
using Fuse.Scripting;

namespace Fuse.Triggers
{
	[UXGlobalModule]
	/**
		@deprecated Use the @Busy behavior instead
	*/
	public class BusyTaskModule: NativeModule
	{
		static BusyTaskModule _module;

		public BusyTaskModule()
		{
			if (_module == null)
			{
				_module = this;
				Resource.SetGlobalKey(this, "FuseJS/BusyTask");
			}
		}

		class ConstructorClosure
		{
			readonly Context _c;
			public ConstructorClosure(Context c)
			{
				_c = c;
			}

			static bool _warning = false;
			
			public object Construct(Context context, object[] args)
			{
				if (!_warning) 
				{
					//DEPRECATED: 2017-01-09
					Fuse.Diagnostics.Deprecated( "Use the `Busy` behavior instead of FuseJS/BusyTask", this );
					_warning = true;
				}
				
				if (args.Length == 0 || args.Length > 2)
					throw new Error("new BusyTask() - must provide 1 or 2 arguments");
				var n = _c.Wrap(args[0]) as Node;
				if (n == null) throw new Error("new BusyTask() - argument must be an UX node");
				
				var act = BusyTaskActivity.Processing;
				if (args.Length == 2)
					act = Marshal.ToType<BusyTaskActivity>(args[1]);

				return _c.Unwrap(new BusyTask(n, BusyTask.Type.UnrootingDone,act));
			}
		}

		override object CreateExportsObject(Context c)
		{
			return new Callback(new ConstructorClosure(c).Construct);
		}
	}
}
