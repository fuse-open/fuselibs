using Uno;
using Uno.UX;
using Uno.Collections;
using Uno.Text;
using Uno.Threading;
using Uno.IO;

namespace Fuse.Scripting
{
	public partial class ScriptModule
	{
		string GetEffectiveCode()
		{
			var code = Code;

			if (!string.IsNullOrEmpty(Preamble))
				code = Preamble + code;

			if (!string.IsNullOrEmpty(Postamble))
				code = code + Postamble;

			return code;
		}

		int GetPreambleNewlines()
		{
			if (string.IsNullOrEmpty(Preamble))
				return 0;

			int index = -1, count = 0;
			while ((index = Preamble.IndexOf('\n', index + 1)) >= 0)
				count++;
			return count;
		}

		public override void Evaluate(Context c, ModuleResult result)
		{
			var offset = Math.Max(0, LineNumberOffset - (1 + GetPreambleNewlines()));

			// Make the errors come from the right location
			var newlines = new char[offset];
			for (int i = 0; i < offset; ++i)
			{
				newlines[i] = '\n';
			}

			var args = new List<object>();

			var wrappedCode = "(function(" + GenerateArgs(c, result, args) +") { " + new string(newlines) + GetEffectiveCode() + "\n })";
			var moduleFunc = (Function)c.Evaluate(FileName, wrappedCode);

			if (moduleFunc == null)
			{
				throw new Exception("Could not evaluate module '" + FileName + "': JavaScript code contains errors");
			}

			CallModuleFunc(c, moduleFunc, args.ToArray());
		}

		protected virtual Dictionary<string, object> GenerateRequireTable(Context c)
		{
			return null;
		}

		protected virtual string GenerateArgs(Context c, ModuleResult result, List<object> args)
		{
			var module = result.GetObject(c);

			var rt = GenerateRequireTable(c);

			args.Add(module);
			args.Add(module["exports"]);
			args.Add((Callback)new RequireContext(c, this, result, rt).Require);

			return "module, exports, require";
		}

		protected virtual void CallModuleFunc(Context context, Function moduleFunc, object[] args)
		{
			moduleFunc.Call(context, args);
		}
	}
}
