using Uno;

namespace Fuse.Reactive
{
	public partial class Instantiator
	{
		void CompleteActionGood()
		{
			TrimAndPad();
			SetValid();
			CompleteNodeAction();
		}
		
		void IObserver.OnSet(object newValue)
		{
			if (!_listening) return;

			RemoveAll();
			CompleteActionGood();
		}
		
		void IObserver.OnFailed(string message)
		{
			if (!_listening) return;

			RemoveAll();
			
			SetFailed(message);
			CompleteNodeAction();
		}
		
		void IObserver.OnAdd(object addedValue)
		{
			if (!_listening) return;

			CompleteActionGood();
		}
		
		void IObserver.OnRemoveAt(int index)
		{
			if (!_listening) return;

			RemoveAt(index);
			CompleteActionGood();
		}

		void IObserver.OnInsertAt(int index, object value)
		{
			if (!_listening) return;
			InsertNew(index);
			
			CompleteActionGood();
		}

		void IObserver.OnNewAt(int index, object value)
		{
			if (!_listening) return;

			RemoveAt(index);
			InsertNew(index);
			CompleteActionGood();
		}

		void IObserver.OnNewAll(IArray values)
		{
			if (!_listening) return;

			RemoveAll();
			CompleteActionGood();
		}

		void IObserver.OnClear()
		{
			if (!_listening) return;

			RemoveAll();
			CompleteActionGood();
		}
	}
}
