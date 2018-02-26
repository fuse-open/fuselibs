//using Uno;
using Uno.UX;
using Uno.Collections;
using Uno.Compiler;
using Fuse.Scripting;
using Uno.Testing;
using Uno.Threading;
using Fuse.Reactive;

namespace Fuse.Reactive
{
	/**
		The `JavaScript` tag is used to run JavaScript and assigns its `module.exports` as data context for the parent visual.

		**Note:** ECMAScript 5.1 is the only JavaScript version that is supported across all platforms.
		While newer JavaScript features might work on some devices, this can't be guaranteed (particularly for earlier iOS versions).

		@topic JavaScript

		@include Docs/JavaScriptRemarks.md
	*/
	public partial class JavaScript: Behavior, IModuleProvider, ValueForwarder.IValueListener, Node.ISiblingDataProvider, IContext
	{
		static int _javaScriptCounter;
		static internal Fuse.Scripting.JavaScript.ThreadWorker Worker;

		internal readonly NameTable _nameTable;
		Fuse.Scripting.JavaScript.RootableScriptModule _scriptModule;
		internal Fuse.Scripting.JavaScript.RootableScriptModule ScriptModule { get { return _scriptModule; } }

		// Not ideal, the tag shouldnt own the VM, but until the VM has it's own class this method lives here
		static internal void EnsureVMStarted()
		{
			if (Worker == null)
				Worker = new Fuse.Scripting.JavaScript.ThreadWorker();
		}

		[UXConstructor]
		public JavaScript([UXAutoNameTable] NameTable nameTable)
		{
			EnsureVMStarted();
			_nameTable = nameTable;
			_scriptModule = new Fuse.Scripting.JavaScript.RootableScriptModule(Worker, nameTable);
		}

		protected virtual void OnBeforeSubscribeToDependenciesAndDispatchEvaluate() {}

		protected override void OnRooted()
		{
			base.OnRooted();
			_javaScriptCounter++;

			OnBeforeSubscribeToDependenciesAndDispatchEvaluate();

			//for migration we could preserve the _moduleInstance across rooting
			if (_moduleInstance == null || !_moduleInstance.ReflectExports())
				SubscribeToDependenciesAndDispatchEvaluate();

			//must be explicit set each time to preserve
			_preserveModuleInstance = false;
		}

		protected override void OnUnrooted()
		{
			DisposeDependencySubscriptions();
			SetDataContext(null);

			DisposeModuleInstance();

			if(--_javaScriptCounter <= 0)
			{
				AppInitialized.Reset();
				// When all JavaScript nodes is unrooted, send a reset event to all global NativeModules.
				foreach(var nm in Uno.UX.Resource.GetGlobalsOfType<NativeModule>())
				{
					nm.InternalReset();
				}
			}
			base.OnUnrooted();
		}

		Module IModuleProvider.GetModule()
		{
			if (IsRootingCompleted) throw new Uno.Exception("Cannot require() a rooted module");
			return _scriptModule;
		}

		object _currentDc;
		Uno.IDisposable _sub;

		internal void SetDataContext(object newDc)
		{
			DisposeSubscription();

			var oldDc = _currentDc;
			_currentDc = newDc;

			var obs = newDc as IObservable;
			if (obs != null)
			{
				SetSiblingData(null);
				_sub = new ValueForwarder(obs, this);
			}
			else
			{
				SetSiblingData(newDc);
			}

			if (oldDc != null) ValueMirror.Unsubscribe(oldDc);
		}

		void ValueForwarder.IValueListener.NewValue(object data)
		{
			SetSiblingData(data);
		}

		void ValueForwarder.IValueListener.LostValue()
		{
			SetSiblingData(null);
		}

		object _siblingData;
		void SetSiblingData(object data)
		{
			var oldSiblingData = _siblingData;
			_siblingData = data;
			if (Parent != null) Parent.BroadcastDataChange(oldSiblingData, data);
		}

		ContextDataResult ISiblingDataProvider.TryGetDataProvider( DataType type, out object provider )
		{
			provider = type == DataType.Key ? _siblingData : null;
			return ContextDataResult.Continue;
		}

		void DisposeSubscription()
		{
			if (_sub != null)
			{
				_sub.Dispose();
				_sub = null;
			}
		}

		[UXContent, UXVerbatim]
		/** The inline JavaScript code. */
		public string Code
		{
			get { return _scriptModule.Code; }
			set
			{
				if (_scriptModule.Code != value)
				{
					_scriptModule.Code = value;
				}
			}
		}

		[UXLineNumber]
		/** @advanced */
		public int LineNumber
		{
			get { return _scriptModule.LineNumberOffset; }
			set { _scriptModule.LineNumberOffset = value; }
		}

		/** The JavaScript file to read the code from. */
		public FileSource File
		{
			get { return _scriptModule.File; }
			set { _scriptModule.File = value; }
		}

		[UXSourceFileName]
		/** @advanced */
		public string FileName
		{
			get { return _scriptModule.FileName; }
			set { _scriptModule.FileName = value; }
		}
		
		/** 
			Limits the names injected directly into the JavaScript code namespace.
			
			It is recommend you use `Names="Require"` for a cleaner JavaScript namespace and to avoid any potential issues with invalid JavaScript symbol names.  Named items from UX can be accessed via `require("ux:Name")`
		*/
		public Fuse.Scripting.JavaScript.ScriptModuleNames Names
		{
			get { return _scriptModule.ModuleNames; }
			set { _scriptModule.ModuleNames = value; }
		}
		
	}
}
