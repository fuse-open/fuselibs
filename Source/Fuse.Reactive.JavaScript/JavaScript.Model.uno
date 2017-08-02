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

        [UXAttachedPropertySetter("JavaScript.Model"), UXNameScope]
        public static void SetModel(Visual v, IExpression model)
        {
            var js = GetModelScript(v);
            SetupModel(v.Children, js, model);
        }

        static JavaScript _appModel;
        [UXAttachedPropertySetter("Model"), UXNameScope]
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

        static string ParseModelExpression(IExpression exp, JavaScript js, ref string argString)
        {
            if (exp is Data) return ((Data)exp).Key;
            else if (exp is Divide)
            {
                var left = ParseModelExpression(((Divide)exp).Left, js, ref argString);
                var right = ParseModelExpression(((Divide)exp).Right, js, ref argString);
                return left + "/" + right;
            }
            else if (exp is Fuse.Reactive.NamedFunctionCall)
            {
                var nfc = (Fuse.Reactive.NamedFunctionCall)exp;

                for (int i = 0; i < nfc.Arguments.Count; i++)
                {
                    var argName = "__dep" + i;
                    js.Dependencies.Add(new Dependency(argName, nfc.Arguments[i]));
                    if (i > 0) argString = argString + ", ";
                    argString += argName;
                }

                return nfc.Name;
            }
            else throw new Exception("Invalid Model path expression: " + exp);
        }

        static void SetupModel(IList<Node> children, JavaScript js, IExpression model)
        {
            children.Remove(js);
            js.Dependencies.Clear();

            string argString = "";
            string module = ParseModelExpression(model, js, ref argString);
            
            js.Code = "var ComponentStore = require('FuseJS/ComponentStore');\n"+
                    "var model = require('" + module + "');\n"+
                    "module.exports = new ComponentStore(new model(" + argString + "));";

            children.Add(js);            
        }
    }
}
