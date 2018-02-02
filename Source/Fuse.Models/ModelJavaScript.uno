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
		
		static void OnModelDataChanged(ModelData md, Visual v)
		{
			v.RemoveAllChildren<ModelJavaScript>();
			
			//avoid creating without the NameTable as unfortunately UX will set the Model prior to the NameTable
			if (md.NameTable == null || md.ModulePath == null)
				return;
			
			v.Children.Add( new ModelJavaScript(md.NameTable, md.ModulePath, null) );
		}
		
		[UXAttachedPropertySetter("ModelNameTable")]
		public static void SetModelNameTable(Visual v, NameTable nt)
		{
			var md = GetOrCreateModelData(v);
			md.NameTable = nt;
			OnModelDataChanged(md, v);
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

		void SetupModel()
		{
			if (_modulePath == null)
			{
				Code = string.Empty;
				return;
			}

			ZoneJS.Initialize();

			var code = 
					"var Model = require('FuseJS/Internal/Model');\n"+
					"var ViewModelAdapter = require('FuseJS/Internal/ViewModelAdapter')\n"+
					"var self = this;\n"+
					"var modelClass = require('" + _modulePath + "');\n"+
					"if (!(modelClass instanceof Function) && 'default' in modelClass) { modelClass = modelClass.default }\n"+
					"if (!(modelClass instanceof Function)) { throw new Error('\"" + _modulePath + "\" does not export a class or function required to construct a Model'); }\n"+
					"var modelInstance = Object.create(modelClass.prototype);\n"+
					"module.exports = new Model(modelInstance, function() {\n"+
					"    modelClass.call(modelInstance);\n"+
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
			var js = new ModelJavaScript(null, modulePath, previewStateId);
			return js;
		}
		
		string _modulePath;
		internal ModelJavaScript(NameTable nt, string modulePath, string previewStateId)
			: base(nt)
		{
			_previewStateModelId = previewStateId;
			_modulePath = modulePath;
			FileName = "(model-script)";
			SetupModel();
		}
		
		protected override void OnRooted()
		{
			base.OnRooted();
			
			if (_previewStateModelId != null)
			{
				var previewState = PreviewState.Find(this);
				if (previewState != null)
					previewState.AddSaver(this);
			}
		}
		
		protected override void OnUnrooted()
		{
			base.OnUnrooted();
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
