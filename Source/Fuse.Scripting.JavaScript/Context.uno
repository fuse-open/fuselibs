using Uno;
using Uno.Collections;
using Uno.Text;
using Uno.Threading;
using Uno.IO;
using Uno.UX;

namespace Fuse.Scripting.JavaScript
{
	public abstract class Context: Fuse.Scripting.Context
	{
		protected Context() : base () {}

		public override Fuse.Scripting.IThreadWorker ThreadWorker
		{
			get
			{
				return Fuse.Reactive.JavaScript.Worker;
			}
		}

		internal static Context Create()
		{
			if defined(USE_JAVASCRIPTCORE) return new Fuse.Scripting.JavaScriptCore.Context();
			else if defined(USE_V8) return new Fuse.Scripting.V8.Context();
			else if defined(USE_DUKTAPE) return new Fuse.Scripting.Duktape.Context();
			else throw new Exception("No JavaScript VM available for this platform");
		}
	}
}
