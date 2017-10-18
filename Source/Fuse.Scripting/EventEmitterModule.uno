using Uno.IO;
using Uno.UX;
using Uno;

namespace Fuse.Scripting
{
	static class EventEmitterModule
	{
		static Scripting.Function _instance;
		public static Scripting.Function GetConstructor(Context c)
		{
			if (_instance == null)
			{
				var fileSource = Bundle.Get("Fuse.Scripting.JavaScript").GetFile("FuseJS/EventEmitter.js");
				var exports = new FileModule(fileSource).EvaluateExports(c, "FuseJS/EventEmitter");
				_instance = exports as Scripting.Function;
				if (_instance == null)
					throw new Exception("Unable to get a FuseJS/EventEmitter instance");

			}
			return _instance;
		}
	}
}
