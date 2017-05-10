using Uno;
using Uno.Collections;
using Uno.UX;
using Fuse.Animations;

namespace Fuse.Triggers
{
	/**
		Active while the context has failed.

		This trigger can be used inside a @Video, an @Image, or an @Each element.

		@examples Docs/VideoTriggers.md
		
		`<WhileFailed>` is equivalent to `<WhileBusy Activity="Failed" IsHandled="true"/>`
	*/
	public class WhileFailed : WhileBusy
	{
		public WhileFailed()
		{
			Activity = BusyTaskActivity.Failed;
			IsHandled = true;
		}
	}
}
