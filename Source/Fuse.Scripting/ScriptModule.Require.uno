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
		internal static string ModuleContainsAnErrorMessage = "require(): module contains an error: ";

		class RequireContext
		{
			readonly Context _c;
			readonly ModuleResult _dependant;
			readonly ScriptModule _m;

			public RequireContext(Context c, ScriptModule m, ModuleResult dependant)
			{
				_c = c;
				_m = m;
				_dependant = dependant;
			}

			public object Require(object[] args)
			{
				if (args.Length != 1) throw new Error("require(): accepts exactly one argument, " + args.Length + " provided");

				var id = args[0] as string;
				if (id == null) throw new Error("require(): argument must be a string");

				return Require(id);
			}

			static string _lastErrorPath;

			public object Require(string id)
			{
				bool isFile;
				var path = _m.ComputePath(id, out isFile);

				ModuleResult module = _c.TryGetGlobalModuleResult(path);

				if (module == null)
				{
					var mod = _m.TryResolve(path, isFile);

					if (mod == null)
						throw new Error("require(): module not found: " + id);

					module = mod.Evaluate(_c, path);
					module.AddDependency(_dependant.Invalidate);

					if (module.Error == null)
					{
						if (_lastErrorPath == path)
						{
							Diagnostics.UserSuccess("JavaScript error in " + path + " was fixed!", this);
							_lastErrorPath = null;
						}
					}
					else
					{
						var e = module.Error;

						if (!e.Message.Contains(ModuleContainsAnErrorMessage))
						{
							Diagnostics.UserError("JavaScript error in " + path + " line " + e.LineNumber + ". " + e.ErrorMessage, this);
							_lastErrorPath = path;
						}
						throw new Error(ModuleContainsAnErrorMessage + id);
					}
				}
				else
				{
					module.AddDependency(_dependant.Invalidate);
				}

				

				return module.Object["exports"];
			}
		}

		Module TryResolve(string path, bool isFile)
		{
			var mod = LookForModule(path);
			if (mod != null) return mod;

			if (!isFile)
			{
				object res;
				if (Uno.UX.Resource.TryFindGlobal(path, Acceptor, out res))
				{
					var mp = (IModuleProvider)res;
					return mp.GetModule();
				}
			}

			return null;
		}

		string ComputePath(string moduleId, out bool isFile)
		{
			if(moduleId.EndsWith(".js"))
			{
				moduleId = moduleId.Replace(".js", "");
			}
			if (moduleId.StartsWith("."))
			{
				isFile = true;
				return ComputePath(GetSourcePath(), moduleId);
			}
			else if (moduleId.StartsWith("/"))
			{
				isFile = true;
				return ComputePath("", moduleId);
			}

			isFile = false;
			return moduleId;
		}

		string GetSourcePath()
		{
			if (FileName != null) return Path.GetDirectoryName(FileName).Replace('\\', '/').Trim('/');
			else return "";
		}

		static string ComputePath(string sourcePath, string moduleId)
		{
			var parts = moduleId.Split('/');

			for (int i = 0; i < parts.Length; i++)
			{
				if (parts[i] == "") continue;
				else if (parts[i] == ".") continue;
				else if (parts[i] == "..") sourcePath = Path.GetDirectoryName(sourcePath).Replace('\\', '/');
				else if (sourcePath.Length > 0) sourcePath = sourcePath + "/" + parts[i];
				else sourcePath = parts[i];
			}

			return sourcePath;
		}


		static Dictionary<string, Func<string, string>> _magicPaths = new Dictionary<string, Func<string, string>>();
		internal static void AddMagicPath(string path, Func<string, string> preprocessor)
		{
			_magicPaths.Add(path, preprocessor);
		}

		Module LookForModule(string path)
		{
			foreach (var k in _magicPaths) 
			{
				var res = LookForModuleInternal(k.Key + path);
				if (res != null) 
				{
					var code = res.ReadAllText();
					code = k.Value(code); // Transform with preprocessor
					return new CodeModule(res.Bundle, path, code, 0);
				}
			}

			var bf = LookForModuleInternal(path);
			if (bf != null)
				return new FileModule(bf);

			return null;
		}

		BundleFile LookForModuleInternal(string path)
		{
			// Prioritize the local bundle if applicable
			if (Bundle != null)
			{
				foreach (var f in Bundle.Files)
				{
					if (IsPathEqual(f.SourcePath, path)) return f;
				}
			}

			foreach (var f in Bundle.AllFiles)
			{
				if (IsPathEqual(f.SourcePath, path)) return f;
			}
			return null;
		}

		static bool IsPathEqual(string src, string path)
		{
			if (src == path) return true;
			if (src == path + ".js") return true;
			if (src == path + "/index.js") return true;
			return false;
		}

		bool Acceptor(object obj)
		{
			return obj is IModuleProvider;
		}
	}
}
