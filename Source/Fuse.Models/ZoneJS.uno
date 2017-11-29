using Uno;
using Uno.UX;
using Fuse.Scripting;

namespace Fuse.Models
{
	internal class ZoneJS : IModuleProvider
	{
		static ZoneJS _instance;

		internal ZoneJS()
		{
			if (_instance != null)
				return;

			_module = LoadModule();
			Resource.SetGlobalKey(_instance = this, "FuseJS/Internal/ZoneJS");
		}

		Module _module;
		Module IModuleProvider.GetModule()
		{
			return _module;
		}

		static Module LoadModule()
		{
			if defined(DEBUG)
				return new FileModule(import("FuseJS/Internal/zone.js"));
			else
				return new FileModule(import("FuseJS/Internal/zone.min.js"));
		}

		public static void Initialize()
		{
			new ZoneJS();
		}
	}
}
