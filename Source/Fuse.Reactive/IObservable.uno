using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Threading;

namespace Fuse.Reactive
{
	public interface IObservable: IArray
	{
		ISubscription Subscribe(IObserver observer);
	}

	public interface ISubscription: IDisposable
	{
		void ClearExclusive();
		void SetExclusive(object newValue);
		void ReplaceAllExclusive(IArray values);
	}
	
	public interface IObserver
	{
		/** Clear all items */
		void OnClear();
		/** Replace all items with these new values (clear old list, set new list) */
		void OnNewAll(IArray values);
		/** Replace the item at the index */
		void OnNewAt(int index, object newValue);
		/** Replace all items with this singular value */
		void OnSet(object newValue);
		/** Add a new item to the list */
		void OnAdd(object addedValue);
		/** Remove an item at the given index */
		void OnRemoveAt(int index);
		/** Insert an item at the given index */
		void OnInsertAt(int index, object value);
		void OnFailed(string message);
	}
}