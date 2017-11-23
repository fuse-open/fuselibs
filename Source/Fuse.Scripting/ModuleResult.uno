using Uno;
using Uno.Collections;
using Uno.Text;
using Uno.Threading;
using Uno.IO;
using Uno.UX;

namespace Fuse.Scripting
{
	public class ModuleResult
	{
		public readonly Context Context;
		public readonly string Id;
		public readonly Module Module;

		readonly Scripting.Object _object;
		[Obsolete("Use GetObject(Context) instead")]
		public Scripting.Object Object { get { return _object; } }

		public Scripting.Object GetObject(Context c)
		{
			return _object;
		}

		[Obsolete("Use GetExports(Context)")]
		public object Exports { get { return _object["exports"]; } }

		public object GetExports(Context c) { return _object["exports"]; }

		public ScriptException Error { get; internal set; }

		bool _globalKeyListening;
		bool _fileListening;

		public ModuleResult(Context context, string id, Module mod, Scripting.Object obj)
		{
			Context = context;
			Module = mod;
			_object = obj;
			Id = id;

			// Watch global key for changes
			if (Id != null)
			{
				_globalKeyListening = true;
				Uno.UX.Resource.AddGlobalKeyListener(OnGlobalKeyChanged);
			}

			// Watch source file for changes
			if (Module.GetFile() != null)
			{
				Module.GetFile().DataChanged += OnDataChanged;
				_fileListening = true;
			}

			// Other implementations of Module (e.g. NativeModule)
			// can't change at runtime, so just silent ignore
		}

		void OnGlobalKeyChanged(string key)
		{
			if (key == Id) Invalidate();
		}

		List<Action> _invalidateCallbacks = new List<Action>();

		public void AddDependency(Action invalidateCallback)
		{
			_invalidateCallbacks.Add(invalidateCallback);
		}

		void OnDataChanged(object sender, EventArgs args)
		{
			Invalidate();
		}

		public override string ToString()
		{
			if (Id != null) return Id;
			if (Module.GetFile() != null) return Module.GetFile().Name;
			return "(unknown module)";
		}

		/** Marks the module result as invalid. This means the module
			is garbage and should not be used again after all dependants
			are notified.  */
		public void Invalidate()
		{
			Dispose();

			// Take copy to avoid stackoverflow on circular dependencies
			// Circular require()-dependencies are legal in JS
			var callbacks = _invalidateCallbacks.ToArray();
			_invalidateCallbacks.Clear();

			foreach (var c in callbacks)
				c();
		}

		public void Dispose()
		{
			if (_fileListening)
			{
				Module.GetFile().DataChanged -= OnDataChanged;
				_fileListening = false;
			}

			if (_globalKeyListening)
			{
				Uno.UX.Resource.RemoveGlobalKeyListener(OnGlobalKeyChanged);
				_globalKeyListening = false;
			}

			if (Id != null) Context.DeleteGlobalModuleResult(this);

			Context.Invoke(OnDisposed);
		}

		void OnDisposed(Scripting.Context context)
		{
			if (_object.ContainsKey("disposed"))
			{
				var disposed = _object["disposed"] as Scripting.Array;
				if (disposed != null)
				{
					for (int i = 0; i < disposed.Length; i++)
					{
						var func = (Function)disposed[i];
						if (func != null) func.Call(context);
					}
				}
			}
		}

	}
}
