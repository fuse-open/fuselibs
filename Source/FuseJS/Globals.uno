using Uno;
using Uno.UX;
using Fuse.Scripting;

namespace FuseJS
{
	[UXGlobalModule]
	public sealed class Globals : NativeModule
	{
		static readonly Globals _instance;
		public Globals()
		{
			if(_instance != null) return;
			Resource.SetGlobalKey(_instance = this, "FuseJS/Globals");
			AddMember(new NativePromise<string, string>("readAsText", (ResultFactory<string>)readAsText, null));
		}

		static string readAsText(object[] args)
		{
			if (args.Length != 1) throw new Exception("Globals.readAsText(): Exactly one argument expected");

			var key = args[0] as string;
			if (args.Length != 1) throw new Exception("Globals.readAsText(): Argument must be string");

			object res;
			if (Uno.UX.Resource.TryFindGlobal(key, FileSourceAcceptor, out res))
			{
				var fs = (BundleFileSource)res;
				return fs.ReadAllText();
			}

			throw new Exception("Globals.readAsText(): Global resource file '" + key + "' not found");
		}

		static bool FileSourceAcceptor(object obj)
		{
			return obj is BundleFileSource;
		}
	}
}