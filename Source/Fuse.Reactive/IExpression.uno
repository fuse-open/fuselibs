using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Threading;

namespace Fuse.Reactive
{
	public interface IListener
	{
		void OnNewData(IExpression source, object data);
	}

	public interface IContext
	{
		/** Creates a subscription to given key in this context.
			
			May return `null` after calling `listener.OnNewData` if the data was synchronously available
			and will never change.
		*/
		IDisposable Subscribe(IExpression source, string key, IListener listener);

		/** Creates a subscription to a given resource key in this context. */
		IDisposable SubscribeResource(IExpression source, string key, IListener listener);

		/** The closest enclosing node of this context */
		Node Node { get; }
	}

	/** Represents a subscription that might support write-back. */
	public interface IWriteable: IDisposable
	{
		/** Attempts to write to the source. 
			Returns whether or not the source was successfully updated.
		*/
		bool TrySetExclusive(object value);
	}

	public interface IExpression
	{
		/** Creates a subscription to the expression in the given data context.

			May return an `IWriteable` if the expression represents a writeable source (e.g. a property).
			
			May return `null` after calling `listener.OnNewData` if the data was synchronously available
			and will never change.
		*/
		IDisposable Subscribe(IContext context, IListener listener);
	}
}
