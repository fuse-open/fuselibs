using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse.Internal;

namespace Fuse.Reactive
{
	/* The part that deals with storing/accessing data on the nodes */
	public partial class Instantiator
	{
		Dictionary<Node,WindowItem> _dataMap = new Dictionary<Node,WindowItem>();
		
		internal int DataIndexOfChild(Node child)
		{
			for (int i = 0; i < _watcher.WindowItemCount; i++)
			{
				var wi = _watcher.GetWindowItem(i);
				var list = wi.Nodes;
				if (list == null)
					continue;
					
				for (int n = 0; n < list.Count; n++)
				{
					if (list[n] == child)
						return i + Offset;
				}
			}
			return -1;
		}

		internal int DataCount { get { return _watcher.GetDataCount(); } }
		
		object Node.ISubtreeDataProvider.GetData(Node n)
		{
			WindowItem v;
			if (_dataMap.TryGetValue(n, out v))
			{
				//https://github.com/fusetools/fuselibs/issues/3312
				//`Count` does not introduce data items
				if (v.Data is NoContextItem)
					return null;
					
				return v.CurrentData;
			}

			return null;
		}
	}
}