using Uno;
using Uno.UX;
using Uno.Collections;
using Uno.Compiler;
using Fuse.Scripting;
using Uno.Testing;
using Uno.Threading;
using Uno.IO;

namespace Fuse.Reactive
{
	//the attached properties need to be in a public class.
	public partial class JavaScript
	{
		class ModelData
		{
			public IExpression Model;
			public NameTable NameTable;
		}
		
		//Requires a NameTable that will be set first.
        [UXAttachedPropertySetter("JavaScript.Model"), UXNameScope, UXAuxNameTable("ModelNameTable")]
        public static void SetModel(Visual v, IExpression model)
        {
			var md = v.Properties.Get( _modelHandle ) as ModelData;
			if (md == null)
			{
				md = new ModelData{ Model = model };
				v.Properties.Set( _modelHandle, md );
			}
			else
			{
				md.Model = model;
			}
			
			Complete( md, v );
		}
		
		static void Complete( ModelData md, Visual v )
		{
			v.RemoveAllChildren<ModelJavaScript>();
			
			//avoid creating without the NameTable as unfortunately UX will set the Model prior to the NameTable
			if (md.NameTable == null || md.Model == null)
				return;
				
			var parsed = ModelJavaScript.ParseModelExpression(md.Model, md.NameTable);
			v.Children.Add( new ModelJavaScript(parsed, md.NameTable, null) );
        }

        static PropertyHandle _modelHandle = Properties.CreateHandle();
        
        [UXAttachedPropertySetterAttribute("ModelNameTable")]
        public static void SetModelNameTable(Visual v, NameTable nt)
        {
			var md = v.Properties.Get( _modelHandle ) as ModelData;
			if (md == null)
			{
				md = new ModelData{ NameTable = nt };
				v.Properties.Set( _modelHandle, md );
			}
			else
			{
				md.NameTable = nt;
			}
			
			Complete( md, v );
        }

        //TODO: This should probably be JavaScript.Model, Preview would need to be adjusted as well
        [UXAttachedPropertySetter("Model"), UXNameScope]
        public static void SetAppModel(IRootVisualProvider rootVisualProvider, IExpression model)
        {
			rootVisualProvider.Root.RemoveAllChildren<ModelJavaScript>();

			var _appModel = ModelJavaScript.CreateFromPreviewState(rootVisualProvider.Root, model);
			rootVisualProvider.Root.Children.Add(_appModel);
        }
	}
	
	class ModelJavaScript : JavaScript, IPreviewStateSaver
	{
		internal class ParsedModelExpression
		{
			public IExpression Source;
			public string ModuleName;
			public string ClassName;
			public List<string> Args = new List<string>();
			public List<Dependency> Dependencies = new List<Dependency>();
			
			public string ArgString
			{
				get
				{
					var str = "";
					for (int i=0; i < Args.Count; ++i)
						str += ", " + Args[i];
					return str;
				}
			}
			
			public bool CompatibleTo( ParsedModelExpression o )
			{
				//there is no way to migrate these now as they might refer to tree objects, thus reject entirely
				if (Args.Count != 0 || o.Args.Count != 0 ||	
					Dependencies.Count != 0 || o.Dependencies.Count != 0)
					return false;
					
				return o.ModuleName == ModuleName &&
					o.ClassName == ClassName;
			}
		}
		
		internal static ParsedModelExpression ParseModelExpression(IExpression exp, NameTable nt)
        {
            if (exp is Data) {
                var className = ((Data)exp).Key;
                return new ParsedModelExpression{ ClassName = className, ModuleName = className,
					Source = exp };
            } 
            else if (exp is Divide)
            {
                var left = ParseModelExpression(((Divide)exp).Left, nt);
                var right = ParseModelExpression(((Divide)exp).Right, nt);
                
                if (left.Args.Count > 0 || left.Dependencies.Count > 0)
					throw new Exception( "Invalid Model path expression: " + exp);
                
                right.ModuleName = left.ModuleName + "/" + right.ModuleName;
                right.Source = exp;
                return right;
            }
            else if (exp is Fuse.Reactive.NamedFunctionCall)
            {
                var nfc = (Fuse.Reactive.NamedFunctionCall)exp;

                var result = new ParsedModelExpression{ ClassName = nfc.Name, ModuleName = nfc.Name,
					Source = exp };
                for (int i = 0; i < nfc.Arguments.Count; i++)
                {
					var argName = "__dep" + i;
					var c = nfc.Arguments[i] as Constant;
                    result.Dependencies.Add(new Dependency(argName, nfc.Arguments[i]));
					result.Args.Add( argName );
                }

                return result;
            }
            else throw new Exception("Invalid Model path expression: " + exp);
        }

        void SetupModel()
        {
			if (_model == null)
			{
				Code = "";
				return;
			}

            //TODO: this should not be necessary. It's done because there's a UX processor error, we get
            //the IExpression prior to it being complete
            var module = ParseModelExpression( _model.Source, _nameTable );
            //var module = _model;
            
            Dependencies.Clear();
			for (int i=0; i < module.Dependencies.Count; ++i)
				Dependencies.Add( module.Dependencies[i] );
			
            var code = "var Model = require('FuseJS/Model');\n"+
					"var ViewModelAdapter = require('FuseJS/ViewModelAdapter')\n";
					
			code += "var self = this;\n"+
					"var modelClass = require('" + module.ModuleName + "');\n"+
                    "if (!(modelClass instanceof Function) && 'default' in modelClass) { modelClass = modelClass.default }\n"+
                    "if (!(modelClass instanceof Function) && '" + module.ClassName +"' in modelClass) { modelClass = modelClass."+ module.ClassName +" }\n"+
                    "if (!(modelClass instanceof Function)) { throw new Error('\"" + module.ModuleName + "\" does not export a class or function required to construct a Model'); }\n"+
                    "var modelInstance = Object.create(modelClass.prototype);\n"+
					"module.exports = new Model(modelInstance, function() {\n"+
                    "    modelClass.call(modelInstance" + module.ArgString + ");\n"+
					"    ViewModelAdapter.adaptView(self, module, modelInstance);\n"+
                    "    return modelInstance;\n"+
                    "});\n";
			Code = code;
        }
		
		string _previewStateModelId; //if null then not migrated
		
		static public ModelJavaScript CreateFromPreviewState(Visual where, IExpression model)
		{
			string previewStateId = "ModelJavaScript-App";
			var parsed = ParseModelExpression(model, null);
			
			var previewState = PreviewState.Find(where);
			if (previewState != null && previewState.Current != null)
			{
				var previous = previewState.Current.Consume( previewStateId ) as ModelJavaScript;
				if (previous != null)
				{
					if (previous._model.CompatibleTo(parsed))
						return previous;
					else
						previous.Dispose();
				}
			}
			
			//app-level model does not have a nametable otherwise migration would not be possible
			var js = new ModelJavaScript(parsed, null, previewStateId );
			return js;
		}
		
		ParsedModelExpression _model;
		internal ModelJavaScript(ParsedModelExpression model, NameTable nt,
			string previewStateId)
			: base(nt)
		{
			_previewStateModelId = previewStateId;
			_model = model;
			FileName=  "(model-script)";
		}
		
		protected override void OnRooted()
		{
			//TODO: prior to base.OnRooted is questionable... The TODO: in SetupModel though is part of the
			//reason we can't easily fix this now. Ideally the constructor would just set the needed values
			SetupModel();
			
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