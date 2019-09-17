using Uno;
using Uno.UX;
using Uno.Collections;
using Uno.Compiler;
using Uno.IO;
using Uno.Text;
using Fuse;
using Fuse.Reactive;
using Fuse.Scripting;

namespace Fuse.Models
{
	public class ModelJavaScript : JavaScript, IPreviewStateSaver
	{
		class ModelData
		{
			public string ModulePath;
			public NameTable NameTable;
			public IExpression Arguments;
			public bool HasArguments = false;
		}
		static PropertyHandle _modelHandle = Properties.CreateHandle();

		//Requires a NameTable that will be set first.
		[UXAttachedPropertySetter("JavaScript.Model"), UXAuxNameTable("ModelNameTable")]
		public static void SetModel(Visual v, string modulePath)
		{
			var md = GetOrCreateModelData(v);
			md.ModulePath = modulePath;
			OnModelDataChanged(md, v);
		}

		[UXAttachedPropertyGetter("JavaScript.Model")]
		public static string GetModel(Visual v)
		{
			return GetOrCreateModelData(v).ModulePath;
		}

		[UXAttachedPropertySetter("ModelNameTable")]
		public static void SetModelNameTable(Visual v, NameTable nt)
		{
			var md = GetOrCreateModelData(v);
			md.NameTable = nt;
			OnModelDataChanged(md, v);
		}

		[UXAttachedPropertyGetter("ModelNameTable")]
		public static NameTable GetModelNameTable(Visual v)
		{
			return GetOrCreateModelData(v).NameTable;
		}

		[UXAttachedPropertySetter("ModelArgs")]
		public static void SetModelArgs(Visual v, IExpression args)
		{
			var md = GetOrCreateModelData(v);
			md.Arguments = args;
			md.HasArguments = true;
			OnModelDataChanged(md, v);
		}

		[UXAttachedPropertyGetter("ModelArgs")]
		public static IExpression GetModelArgs(Visual v)
		{
			return GetOrCreateModelData(v).Arguments;
		}

		static void OnModelDataChanged(ModelData md, Visual v)
		{
			v.RemoveAllChildren<ModelJavaScript>();

			//avoid creating without the NameTable as unfortunately UX will set the Model prior to the NameTable
			if (md.NameTable == null || string.IsNullOrEmpty(md.ModulePath))
				return;

			v.Children.Add(new ModelJavaScript(md));
		}

		static ModelData GetOrCreateModelData(Visual v)
		{
			var md = v.Properties.Get(_modelHandle) as ModelData;
			if (md == null)
			{
				md = new ModelData();
				v.Properties.Set(_modelHandle, md);
			}
			return md;
		}

		//TODO: This should probably be JavaScript.Model, Preview would need to be adjusted as well
		[UXAttachedPropertySetter("Model")]
		public static void SetAppModel(IRootVisualProvider rootVisualProvider, string modulePath)
		{
			rootVisualProvider.Root.RemoveAllChildren<ModelJavaScript>();

			var appModel = ModelJavaScript.CreateFromPreviewState(rootVisualProvider.Root, modulePath);
			rootVisualProvider.Root.Children.Add(appModel);
		}

		static IExpression[] UnpackArgs(IExpression argsExpr)
		{
			var vector = argsExpr as Reactive.Vector;
			if (vector != null)
			{
				var vectorArgs = vector.Arguments;
				var outputArgs = new IExpression[vectorArgs.Count];
				for (var i = 0; i < vectorArgs.Count; ++i)
					outputArgs[i] = vectorArgs[i];

				return outputArgs;
			}

			return new[] { argsExpr };
		}

		string GenerateArgsStringAndPopulateDependencies()
		{
			var argsString = "";
			if (!_hasArgs)
				return argsString;

			var args = UnpackArgs(_args);
			for (var i = 0; i < args.Length; ++i)
			{
				var depName = "__modelArg" + i;
				argsString += ", " + depName;
				Dependencies.Add(new Dependency(depName, args[i]));
			}

			return argsString;
		}

		void SetupModel()
		{
			if (string.IsNullOrEmpty(_modulePath))
			{
				Code = string.Empty;
				return;
			}

			ZoneJS.Initialize();

			var argsString = GenerateArgsStringAndPopulateDependencies();
			var code =
					"var Model = require('FuseJS/Internal/Model');\n"+
					"var ViewModelAdapter = require('FuseJS/Internal/ViewModelAdapter')\n"+
					"var self = this;\n"+
					"var modelClass = require('" + _modulePath + "');\n"+
					"if (!(modelClass instanceof Function) && 'default' in modelClass) { modelClass = modelClass.default }\n"+
					"if (!(modelClass instanceof Function)) { throw new Error('\"" + _modulePath + "\" does not export a class or function required to construct a Model'); }\n"+
					"var modelInstance = Object.create(modelClass.prototype);\n"+
					"module.exports = new Model(modelInstance, function() {\n"+
					"    modelClass.call(modelInstance" + argsString + ");\n"+
					"    ViewModelAdapter.adaptView(self, module, modelInstance);\n"+
					"    return modelInstance;\n"+
					"});\n";
			Code = code;
		}

		string _previewStateModelId; //if null then not migrated

		static public ModelJavaScript CreateFromPreviewState(Visual where, string modulePath)
		{
			string previewStateId = "ModelJavaScript-App";

			var previewState = PreviewState.Find(where);
			if (previewState != null && previewState.Current != null)
			{
				var previous = previewState.Current.Consume( previewStateId ) as ModelJavaScript;
				if (previous != null)
				{
					if (previous._modulePath == modulePath)
						return previous;
					else
						previous.Dispose();
				}
			}

			//app-level model does not have a nametable otherwise migration would not be possible
			var md = new ModelData
			{
				ModulePath = modulePath
			};

			return new ModelJavaScript(md, previewStateId);
		}

		string _modulePath;
		IExpression _args;
		bool _hasArgs;

		private ModelJavaScript(ModelData md, string previewStateId = null)
			: base(md.NameTable)
		{
			_previewStateModelId = previewStateId;
			_modulePath = md.ModulePath;
			_args = md.Arguments;
			_hasArgs = md.HasArguments;
			FileName = "(model-script)";
		}

		protected override void OnBeforeSubscribeToDependenciesAndDispatchEvaluate()
		{
			SetupModel();

			if (_previewStateModelId != null)
			{
				var previewState = PreviewState.Find(this);
				if (previewState != null)
					previewState.AddSaver(this);
			}
		}

		void IPreviewStateSaver.Save(PreviewStateData data)
		{
			_preserveModuleInstance = true;
			data.Set( _previewStateModelId, this );
		}

		void Dispose()
		{
			_preserveModuleInstance = false;
			DisposeModuleInstance();
		}
	}
}
