using Uno;
using Uno.UX;
using Uno.Collections;
using Uno.Compiler;
using Fuse.Scripting;
using Uno.Testing;
using Uno.Threading;

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
		static ThreadWorker _worker;
		internal static ThreadWorker Worker { get { return _worker; } }

		readonly NameTable _nameTable;
		RootableScriptModule _scriptModule;
		internal RootableScriptModule ScriptModule { get { return _scriptModule; } }

		[UXConstructor]
		public JavaScript([UXAutoNameTable] NameTable nameTable)
		{
			if (_worker == null)
			{
				_worker = new ThreadWorker();
				Fuse.Scripting.ScriptModule.AddMagicPath(".FuseJS/", TransformModel);
			}
			
			_nameTable = nameTable;
			_scriptModule = new RootableScriptModule(_worker, nameTable);
		}

		protected override void OnRooted()
		{
			SetupModel();

			base.OnRooted();
			_javaScriptCounter++;
			SubscribeToDependenciesAndDispatchEvaluate();
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

		extern(!FUSELIBS_NO_TOASTS)
		internal static void UserScriptError(string msg, ScriptException ex, object obj,
			[CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0,
			[CallerMemberName] string memberName = "" )
		{
			msg = msg + " in " + ex.FileName + " line " + ex.LineNumber;
			Fuse.Diagnostics.UserError(msg, obj, filePath, lineNumber, memberName, ex);
		}

		Module IModuleProvider.GetModule()
		{
			if (IsRootingCompleted) throw new Exception("Cannot require() a rooted module");
			return _scriptModule;
		}

		object _currentDc;
		IDisposable _sub;
		
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

		object _siblingData;
		void SetSiblingData(object data)
		{
			var oldSiblingData = _siblingData;
			_siblingData = data;
			if (Parent != null) Parent.BroadcastDataChange(oldSiblingData, data);
		}

		object Node.ISiblingDataProvider.Data
		{
			get { return _siblingData; }
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
	}
}
