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
        static NameTable _dummyNameTable;
        static void MakeDummyNameTable()
        {
            _dummyNameTable = new NameTable(null, new string[0]);
            _dummyNameTable.This = AppBase.Current;
        }

        static PropertyHandle _modelHandle = Properties.CreateHandle();

        static JavaScript GetModelScript(Visual v)
        {
            MakeDummyNameTable();
            var js = v.Properties.Get(_modelHandle) as JavaScript;
            if (js == null)
            {
                js = new JavaScript(_dummyNameTable);
                js.FileName = "(model-script)";
                v.Properties.Set(_modelHandle, js);
            }
            return js;
        }

        [UXAttachedPropertySetter("JavaScript.Model")]
        public static void SetModel(Visual v, IExpression model)
        {
            var js = GetModelScript(v);
            SetupModel(v.Children, js, model);
        }

        static JavaScript _appModel;
        [UXAttachedPropertySetter("Model")]
        public static void SetModel(AppBase app, IExpression model)
        {
            MakeDummyNameTable();
            if (_appModel == null)
            {
                _appModel = new JavaScript(_dummyNameTable);
                _appModel.FileName = "(model-script)";
            }
            SetupModel(app.Children, _appModel, model);
        }

        static void SetupModel(IList<Node> children, JavaScript js, IExpression model)
        {
            children.Remove(js);
            js.Dependencies.Clear();

            string module;
            string argString = "";
            if (model is Fuse.Reactive.Name)
            {
                module = ((Fuse.Reactive.Name)model).Identifier;
                
            }
            else if (model is Fuse.Reactive.NamedFunctionCall)
            {
                var nfc = (Fuse.Reactive.NamedFunctionCall)model;
                module = nfc.Name;

                for (int i = 0; i < nfc.Arguments.Count; i++)
                {
                    var argName = "__dep" + i;
                    js.Dependencies.Add(new Dependency(argName, nfc.Arguments[i]));
                    if (i > 0) argString = argString + ", ";
                    argString += argName;
                }
            }
            else throw new Exception("Unsupported Model expression");

            js.Code = "var ComponentStore = require('FuseJS/ComponentStore');\n"+
                    "var model = require('" + module + "');\n"+
                    "module.exports = new ComponentStore(new model(" + argString + "));";

            children.Add(js);            
        }
    }
}
