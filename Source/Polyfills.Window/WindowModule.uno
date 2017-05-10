using Uno;
using Uno.UX;
using Uno.IO;
using Uno.Collections;
using Fuse.Scripting;

namespace Polyfills.Window
{
	[UXGlobalModule]
	public sealed class WindowModule : FileModule, IModuleProvider
	{
		public Module GetModule()
		{
			return this;
		}
		
		static readonly WindowModule _instance;
		static FileSource _fileSourceInstance; 
		
		static FileSource GetWindow()
		{
			if(_fileSourceInstance == null)
				_fileSourceInstance = Bundle.Get("Polyfills.Window").GetFile("js/Window.js");

			return _fileSourceInstance;
		}

		public WindowModule() : base(GetWindow())
		{
			if(_instance == null)
				Resource.SetGlobalKey(_instance = this, "Polyfills/Window");
		}
	}
}
