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

		internal class ParsedModelExpression
		{
			public IExpression Source;
			public string ModuleName;
			public string ClassName;
			public List<string> Args = new List<string>();
			public List<JavaScript.Dependency> Dependencies = new List<JavaScript.Dependency>();
			
			public string ArgString
			{
				get
				{
					var builder = new StringBuilder();
					for (int i = 0; i < Args.Count; ++i)
					{
						builder.Append(", ");
						builder.Append(Args[i]);
					}
					return builder.ToString();
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

			internal void AssertIsPartial()
			{
				if (Args.Count > 0 || Dependencies.Count > 0)
					throw new Exception( "Invalid Model path expression: " + Source);
			}
		}

		internal static ParsedModelExpression ParseBinaryOp(string symbol, BinaryOperator op, NameTable nt)
		{
			var left = ParseModelExpression(op.Left, nt);
			var right = ParseModelExpression(op.Right, nt);

			left.AssertIsPartial();

			right.ModuleName = left.ModuleName + symbol + right.ModuleName;
			right.Source = op;
			return right;
		}

		internal static ParsedModelExpression ParseModelExpression(IExpression exp, NameTable nt)
		{
			var data = exp as Data;
			if (data != null)
			{
				var className = data.Key;
				return new ParsedModelExpression
				{
					ClassName = className,
					ModuleName = className,
					Source = exp,
				};
			}

			var divide = exp as Divide;
			if (divide != null)
				return ParseBinaryOp("/", divide, nt);

			var multiply = exp as Multiply;
			if (multiply != null)
				return ParseBinaryOp("*", multiply, nt);

			var subtract = exp as Subtract;
			if(subtract != null)
				return ParseBinaryOp("-", subtract, nt);

			var addition = exp as Add;
			if(addition != null)
				return ParseBinaryOp("+", addition, nt);

			var member = exp as Member;
			if (member != null)
			{
				var res = ParseModelExpression(member.BaseObject, nt);
				res.Source = member;
				res.ModuleName += "." + member.Name;
				res.AssertIsPartial();
				return res;
			}

			var nfc = exp as Fuse.Reactive.NamedFunctionCall;
			if (nfc != null)
			{
				var result = new ParsedModelExpression
				{
					ClassName = nfc.Name,
					ModuleName = nfc.Name,
					Source = exp,
				};

				for (int i = 0; i < nfc.Arguments.Count; i++)
				{
					var argName = "__dep" + i;
					result.Dependencies.Add(new JavaScript.Dependency(argName, nfc.Arguments[i]));
					result.Args.Add( argName );
				}

				return result;
			}
			
			throw new Exception("Invalid Model path expression: " + exp);
		}

		void SetupModel()
		{
			if (_model == null)
			{
				Code = string.Empty;
				return;
			}

			ZoneJS.Initialize();

			//TODO: this should not be necessary. It's done because there's a UX processor error, we get
			//the IExpression prior to it being complete
			var module = ParseModelExpression( _model.Source, _nameTable );

			Dependencies.Clear();
			for (int i=0; i < module.Dependencies.Count; ++i)
				Dependencies.Add( module.Dependencies[i] );
			
			var code = 
					"var Model = require('FuseJS/Internal/Model');\n"+
					"var ViewModelAdapter = require('FuseJS/Internal/ViewModelAdapter')\n"+
					"var self = this;\n"+
					"var modelClass = require('" + module.ModuleName + "');\n"+
					"if (!(modelClass instanceof Function) && 'default' in modelClass) { modelClass = modelClass.default }\n"+
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
			FileName = "(model-script)";
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
