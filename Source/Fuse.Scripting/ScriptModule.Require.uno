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
		internal const string ModuleContainsAnErrorMessage = "require(): module contains an error: ";

		class RequireContext
		{
			readonly Context _c;
			readonly ModuleResult _dependant;
			readonly ScriptModule _m;
			readonly Dictionary<string, Dependency> _rt;

			public RequireContext(Context c, ScriptModule m, ModuleResult dependant, Dictionary<string, Dependency> rt)
			{
				_c = c;
				_m = m;
				_dependant = dependant;
				_rt = rt;
			}

			public object Require(Context context, object[] args)
			{
				if (args.Length != 1) throw new Error("require(): accepts exactly one argument, " + args.Length + " provided");

				var id = args[0] as string;
				if (id == null) throw new Error("require(): argument must be a string");

				return Require(context, id);
			}

			static string _lastErrorPath;

			object Require(Context context, string id)
			{
				bool isFile;
				var path = _m.ComputePath(id, out isFile);

				ModuleResult module = _c.TryGetGlobalModuleResult(path);

				if (module == null)
				{
					const string uxPrefix = "ux:";
					if (id.StartsWith(uxPrefix))
					{
						if (_rt == null)
							throw new Error( "require(): unable to resolve ux: prefixes: " + id );
							
						Dependency res;
						if (_rt.TryGetValue(id.Substring(uxPrefix.Length), out res)) return res.Value;
						
						throw new Error("require(): ux name not found: " + id);
					}
					
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
							Diagnostics.UserError("JavaScript error in " + path + " line " + e.LineNumber + ". " + e.Message, this);
							_lastErrorPath = path;
						}
						throw new Error(ModuleContainsAnErrorMessage + id);
					}
				}
				else
				{
					module.AddDependency(_dependant.Invalidate);
				}

				return module.GetExports(context);
			}
		}

		Module TryResolve(string path, bool isFile)
		{
			var file = LookForFile(path);
			if (file != null)
			{
				return new FileModule(new Uno.UX.BundleFileSource(file));
			}

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

		BundleFile LookForFile(string path)
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
