using Uno;
using Uno.Collections;

namespace Fuse.Reactive.Internal
{
	enum PatchOp
	{
		//remove(a)
		Remove,
		//insert(to a, with data)
		Insert,
		//update(at a, with data)
		Update,
	}
	
	struct PatchItem
	{
		public PatchOp Op;
		public int A;
		public int Data;
	}
	
	enum PatchAlgorithm
	{
		/** Removes all the items then adds the new list */
		RemoveAll,
		/**
			Supports a few common cases for `Each` and `replaceAll`. In particular it can do in-place removal of items
			if nothing else changes.
		*/
		Simple,
		//Levenstein would be a nice addition (too costly?)
	}

	/**
		Determines a list of operations to convert from one list of items into another.
	*/
	class PatchList
	{
		static public List<PatchItem> Patch<T>( IList<T> from, IList<T> to, PatchAlgorithm algo,
			T emptyKey )
		{
			switch( algo )
			{
				case PatchAlgorithm.RemoveAll:
					return PatchRemoveAll( from, to );
				case PatchAlgorithm.Simple:
					return new SimpleAlgorithm<T>(from,to, emptyKey).Calc();
			}
			
			return null;
		}
		
		/** 
			Removes all items then adds in the new ones.
		*/
		static List<PatchItem> PatchRemoveAll<T>( IList<T> from, IList<T> to )
		{
			var ops = new List<PatchItem>();
			for (int i=0; i < from.Count; ++i)
				ops.Add( new PatchItem{ Op = PatchOp.Remove, A = 0 } );
				
			for (int i=0; i < to.Count; ++i)
				ops.Add( new PatchItem{ Op = PatchOp.Insert, A = i, Data = i } );
				
			return ops;
		}
		
		/** Formats the list of patches for testing/debugging */
		static public string Format(IList<PatchItem> list)
		{
			var q = "";
			for (int i=0; i<list.Count; ++i)
			{
				if (i>0) q += ",";
				var item = list[i];
				switch (item.Op)
				{
					case PatchOp.Remove:
						q += "R" + item.A;
						break;
					case PatchOp.Insert:
						q += "I" + item.A + "=" + item.Data;
						break;
					case PatchOp.Update:
						q += "U" + item.A + "=" + item.Data;
						break;
				}
			}
			return q;
		}
	}

	/**
		Iterates over the from list and finds corresponding anchors in the to list. Items in the from list before
		the anchor are remove. Items in the to list before the anchor are inserted. The matching item is updated.
	*/
	class SimpleAlgorithm<T>
	{
		IList<T> _from, _to;
		Dictionary<T,int> _toIndex;
		List<bool> _toUsed;
		List<PatchItem> _ops;
		T _emptyKey;
		
		public SimpleAlgorithm( IList<T> from, IList<T> to, T emptyKey )
		{
			_emptyKey = emptyKey;
			_from = from;
			_to = to;
			_toIndex = Index(to);
			
			//track which ones are used in the to list
			_toUsed = new List<bool>(to.Count);
			for (int i=0; i < to.Count; ++i)
				_toUsed.Add(false);
				
			_ops = new List<PatchItem>();
		}
		
		struct Location
		{
			public int From, To;
			
			public override string ToString()
			{
				return From + "," + To;
			}
		}
		Dictionary<T,int> Index( IList<T> to )
		{
			var d = new Dictionary<T,int>();
			for (int i=0; i < to.Count; ++i)
			{
				if (!Object.Equals(to[i],_emptyKey))
					d[to[i]] = i;
			}
			return d;
		}

		public List<PatchItem> Calc()
		{
			int fromAt = 0;
			//position in output list relative to fromAt
			int oPos = 0;
			while (fromAt < _from.Count)
			{
				var anchor = FindNextAnchor( fromAt );
				if (anchor.From == -1)
				{
					while (fromAt < _from.Count)
					{
						_ops.Add( new PatchItem{ Op = PatchOp.Remove, A = fromAt + oPos });
						fromAt++;
						oPos--;
					}
					break;
				}
				
				var rem = fromAt + oPos;
				for (int i=0; i < anchor.To; ++i)
				{
					if (_toUsed[i])
						continue;
						
					_ops.Add( new PatchItem{ Op = PatchOp.Insert, A = oPos + anchor.From, Data = i });
					oPos++;
					_toUsed[i] = true;
				}
				while (fromAt < anchor.From)
				{
					_ops.Add( new PatchItem{ Op = PatchOp.Remove, A = rem });
					oPos--;
					fromAt++;
				}
				_ops.Add( new PatchItem{ Op = PatchOp.Update, A = fromAt + oPos, Data = anchor.To });
				_toUsed[anchor.To] = true;
				fromAt++;
			}
			
			AppendRemainingTo(fromAt + oPos);
			return _ops;
		}
		
		void AppendRemainingTo(int oPos)
		{
			for (int i=0; i < _to.Count; ++i)
			{
				if (_toUsed[i])
					continue;
					
				_ops.Add( new PatchItem{ Op = PatchOp.Insert, A = oPos, Data = i });
				_toUsed[i] = true;
				oPos++;
			}
		}
		
		/** Find the next item in the from list that's also still in the to list */
		Location FindNextAnchor( int fromAt )
		{
			while (fromAt < _from.Count)
			{
				int faLoc = -1;
				if (Object.Equals(_from[fromAt],_emptyKey) ||
					!_toIndex.TryGetValue(_from[fromAt], out faLoc) || 
					_toUsed[faLoc])
				{
					fromAt++;
					continue;
				}
				
				return new Location{ From = fromAt, To =  faLoc };
			}
			
			return new Location{ From = -1, To = -1 };
		}
	}
	
}
