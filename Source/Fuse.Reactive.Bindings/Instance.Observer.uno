using Uno;
using Uno.Collections;

using Fuse.Reactive.Internal;

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

			//use the shortcut if possible (saves overhead)
			if (!TryUpdateAt(index, value))
			{
				RemoveAt(index);
				InsertNew(index);
			}
			CompleteActionGood();
		}

		void PatchTo(IArray values)
		{
			//collect new ids in the window
			var newIds = new List<object>();
			var limit = CalcOffsetLimitCountOf(values.Length);
			for (int i=0; i < limit; ++i)
				newIds.Add( GetDataKey(values[i+Offset], ObjectId ) );
				
			var curIds = new List<object>();
			for (int i=0; i < _windowItems.Count; ++i)
			{
				if (!_windowItems[i].Removed)
					curIds.Add( _windowItems[i].Id);
			}
			
			var ops = PatchList.Patch( curIds, newIds, PatchAlgorithm.Simple, null );
			for (int i=0; i < ops.Count; ++i)
			{
				var op = ops[i];
				switch (op.Op)
				{
					case PatchOp.Remove:
						RemoveAt(op.A + Offset);
						break;
					case PatchOp.Insert:
						InsertNewWindowItem(DataToWindowIndex(op.A + Offset), values[op.Data]);
						break;
					case PatchOp.Update:
						if (!TryUpdateAt(op.A + Offset, values[op.Data]))
						{
							RemoveAt(op.A + Offset);
							InsertNewWindowItem(DataToWindowIndex(op.A + Offset), values[op.Data]);
						}
						break;
				}
			}
		}
		
		void IObserver.OnNewAll(IArray values)
		{
			if (!_listening) return;

			if (ObjectMatch != InstanceObjectMatch.None)
				PatchTo(values);
			else
				RemoveAll(); //the TrimAndPad in `CompleteActionGood` restores the list
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
