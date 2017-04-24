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
		The `JavaScript` tag is used to run JavaScript and assigns its `module.export` as data context for the parent visual.

		@topic JavaScript

		@include Docs/JavaScriptRemarks.md
	*/
	public class JavaScript: Behavior, IModuleProvider, ValueForwarder.IValueListener, Node.ISiblingDataProvider
	{
		static int _javaScriptCounter;
		static ThreadWorker _worker;
		internal static ThreadWorker Worker { get { return _worker; } }

		protected ScriptModule _scriptModule;

		[UXConstructor]
		public JavaScript([UXAutoNameTable] NameTable nameTable)
		{
			if (_worker == null)
				_worker = new ThreadWorker();

			_scriptModule = new RootableScriptModule(_worker, nameTable);
		}

		static object _resetHookMutex = new object();

		protected override void OnRooted()
		{
			base.OnRooted();
			_javaScriptCounter++;
			DispatchEvaluate();
		}

		protected override void OnUnrooted()
		{
			SetDataContext(null);

			if (_moduleResult != null)
			{
				_moduleResult.Dispose();
				_moduleResult = null;
			}
			if(--_javaScriptCounter <= 0)
			{
				AppInitialized.Reset();
				// When all JavaScript nodes is unrooted, send a reset event to all global NativeModules.
				foreach(var nm in Resource.GetGlobalsOfType<NativeModule>())
				{
					nm.InternalReset();
				}
			}
			base.OnUnrooted();
		}

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

		void OnReset()
		{
			if (IsRootingCompleted) DispatchEvaluate();
		}

		void DispatchEvaluate()
		{
			if (!IsRootingStarted) return;
			new EvaluateDataContext(Worker, this);
		}

		object _currentDc;
		IDisposable _sub;
		
		void SetDataContext(object newDc)
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

		class EvaluateDataContext
		{
			readonly ThreadWorker _worker;
			readonly JavaScript _js;

			// UI thread
			public EvaluateDataContext(ThreadWorker worker, JavaScript js)
			{
				_js = js;
				_worker = worker;
				_worker.Invoke(Evaluate);
			}

			// JS thread
			void Evaluate()
			{
				_dc = _worker.Reflect(_js.EvaluateExports());
				UpdateManager.PostAction(SetDataContext);
			}

			object _dc;

			// UI thread
			void SetDataContext()
			{
				_js.SetDataContext(_dc);
			}
		}

		ModuleResult _moduleResult;

		object EvaluateExports()
		{
			EvaluateModule();

			if (_moduleResult != null)
				return _moduleResult.Object["exports"];

			return null;
		}

		static string previousErrorFile;

		void EvaluateModule()
		{
			var globalId = Uno.UX.Resource.GetGlobalKey(this);

			lock (_resetHookMutex)
			{
				var newModuleResult = _scriptModule.Evaluate(_worker.Context, globalId);
				newModuleResult.AddDependency(DispatchEvaluate);

				if (newModuleResult.Error == null)
				{
					_moduleResult = newModuleResult;
					
					if (previousErrorFile == FileName + LineNumber)
					{
						Diagnostics.UserSuccess("JavaScript error in " + FileName + " fixed!", this);
						previousErrorFile = null;
					}
				}
				else
				{
					var se = newModuleResult.Error;

					// Don't report chain-errors of already reported errors
					if (!se.Message.Contains(ScriptModule.ModuleContainsAnErrorMessage))
					{
						JavaScript.UserScriptError( "JavaScript error", se, this );
						previousErrorFile = FileName + LineNumber;
					}
				}
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
