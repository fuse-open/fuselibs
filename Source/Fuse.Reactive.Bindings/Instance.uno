using Uno;
using Uno.UX;

using Fuse.Triggers;

namespace Fuse.Reactive
{
	/** Creates and inserts an instance of the given template(s). */
	public class Instance: Instantiator
	{
		public Instance() 
		{
			Count = 1;
		}
	}
}
