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
			//collect new ides in the window
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
			
			//TODO: clean nulls 
			debug_log "From:" + Join(curIds) + "\n  To:" + Join(newIds);
			
			RemoveAll();
		}
		
		static string Join( List<object> t )
		{
			var q = "";
			for (int i=0; i < t.Count; ++i)
			{
				if (i>0) q += ",";
				q += t[i];
			}
			return q;
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
