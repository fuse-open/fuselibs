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
                v.Children.Add(js);
            }
            return js;
        }

        static void RemoveModelScript(Visual v)
        {
            var script = v.Properties.Get(_modelHandle) as JavaScript;
            if (script != null)
            {
                v.Children.Remove(script);
                v.Properties.RemoveFromList(_modelHandle, script);
            }
        }

        [UXAttachedPropertySetter("JavaScript.Model")]
        public static void SetModel(Visual v, string model)
        {
            if (string.IsNullOrEmpty(model))
                RemoveModelScript(v);
            else
            {
                var js = GetModelScript(v);
                js.Code = "var ComponentStore = require('FuseJS/ComponentStore');\n"+
                          "var model = require('" + model + "');\n"+
                          "module.exports = new ComponentStore(new model());";
            }
        }

        static JavaScript _appModel;

        [UXAttachedPropertySetter("Model")]
        public static void SetModel(AppBase app, string model)
        {
            MakeDummyNameTable();
            if (_appModel == null)
            {
                _appModel = new JavaScript(_dummyNameTable);
                _appModel.FileName = "(model-script)";
            }

            if (string.IsNullOrEmpty(model))
                app.Children.Remove(_appModel);
            else
            {
                app.Children.Add(_appModel);

                _appModel.Code = "var ComponentStore = require('FuseJS/ComponentStore');\n"+
                          "var model = require('" + model + "');\n"+
                          "module.exports = new ComponentStore(new model());";
            }
        }
    }
}
