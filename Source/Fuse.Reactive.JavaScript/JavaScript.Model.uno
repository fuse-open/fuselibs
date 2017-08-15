using Uno;
using Uno.UX;
using Uno.Collections;
using Uno.Compiler;
using Fuse.Scripting;
using Uno.Testing;
using Uno.Threading;

namespace Fuse.Reactive
{
    public partial class JavaScript
    {
        static PropertyHandle _modelHandle = Properties.CreateHandle();

        IExpression _model;

        void SetupModel()
        {
            if (_model != null)
                SetupModel(Parent.Children, this, _model);
        }

        static JavaScript GetModelScript(Visual v, NameTable nt = null)
        {
            var js = v.Properties.Get(_modelHandle) as JavaScript;
            if (js == null || nt != null)
            {
                var oldJs = js;
                
                js = new JavaScript(nt);
                js.FileName = "(model-script)";
                if (oldJs != null) 
                {
                    v.Children.Remove(oldJs);
                    js._model = oldJs._model;
                } 
                v.Children.Add(js);
                v.Properties.Set(_modelHandle, js);
            }
            return js;
        }

        [UXAttachedPropertySetter("JavaScript.Model"), UXNameScope, UXAuxNameTable("ModelNameTable")]
        public static void SetModel(Visual v, IExpression model)
        {
            var js = GetModelScript(v);
            js._model = model;
        }

        [UXAttachedPropertySetterAttribute("ModelNameTable")]
        public static void SetModelNameTable(Visual v, NameTable nt)
        {
            GetModelScript(v, nt);
        }

        static JavaScript _appModel;
        [UXAttachedPropertySetter("Model"), UXNameScope]
        public static void SetModel(AppBase app, IExpression model)
        {
            if (_appModel == null)
            {
                _appModel = new JavaScript(null);
                _appModel.FileName = "(model-script)";
                app.Children.Add(_appModel);
            }
			SetupModel(app.Children, _appModel, model);
        }

        static string ParseModelExpression(IExpression exp, JavaScript js, ref string argString, List<string> thisSymbols)
        {
            if (exp is Data) return ((Data)exp).Key;
            else if (exp is Divide)
            {
                var left = ParseModelExpression(((Divide)exp).Left, js, ref argString, thisSymbols);
                var right = ParseModelExpression(((Divide)exp).Right, js, ref argString, thisSymbols);
                return left + "/" + right;
            }
            else if (exp is Fuse.Reactive.NamedFunctionCall)
            {
                var nfc = (Fuse.Reactive.NamedFunctionCall)exp;

                for (int i = 0; i < nfc.Arguments.Count; i++)
                {
					var argName = "__dep" + i;
                    var nt = js._nameTable;
					var c = nfc.Arguments[i] as Constant;
                    if (nt != null && c != null && c.Value == nt.This)
                    {
                        thisSymbols.Add(argName);
                    }
					else
					{
						js.Dependencies.Add(new Dependency(argName, nfc.Arguments[i]));
					}
					if (i > 0) argString = argString + ", ";
					argString += argName;
                }

                return nfc.Name;
            }
            else throw new Exception("Invalid Model path expression: " + exp);
        }

        static void SetupModel(IList<Node> children, JavaScript js, IExpression model)
        {
            js.Dependencies.Clear();

            string argString = "";
			var thisSymbols = new List<string>();
            string module = ParseModelExpression(model, js, ref argString, thisSymbols);
            
            var code = "var Model = require('FuseJS/Model');\n"+
					"var ViewModelAdapter = require('FuseJS/ViewModelAdapter')\n";

			for (var i = 0; i < thisSymbols.Count; i++)
				code += "var " + thisSymbols[i] + " = new ViewModelAdapter(module, this);\n";
					
			code += "var modelClass = require('" + module + "');\n"+
                    "if (!(modelClass instanceof Function) && 'default' in modelClass) { modelClass = modelClass.default }\n"+
                    "if (!(modelClass instanceof Function)) { throw new Error('\"" + module + "\" does not export a class or function required to construct a Model'); }\n"+
                    "module.exports = new Model(new modelClass(" + argString + "));";

			js.Code = code;
        }
    }
}
