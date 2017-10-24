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
	}
}
