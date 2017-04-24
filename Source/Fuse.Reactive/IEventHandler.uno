using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Threading;

namespace Fuse.Reactive
{
	public interface IEventRecord
	{
		Node Node { get; }
		object Data { get; }
		Selector Sender { get; }
		IEnumerable<KeyValuePair<string, object>> Args { get; }
	}

	public interface IEventHandler
	{
		void Dispatch(IEventRecord e);
	}
}