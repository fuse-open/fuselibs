using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse.Internal;
using Fuse.Reactive.Internal;

namespace Fuse.Reactive
{
	/* The code that deals primarily with managing the window items */
	public partial class Instantiator
	{
		Node GetLastNodeFromIndex(int windowIndex)
		{
			if (windowIndex >= _windowItems.Count)
				windowIndex = _windowItems.Count - 1;
				
			while (windowIndex >= 0)
			{
				var lastList = _windowItems[windowIndex].Nodes;
				if (lastList != null && lastList.Count != 0)
					return lastList[lastList.Count-1].GetLastNodeInGroup();

				//support an odd case where an each-item doesn't have any children
				windowIndex--;
			}
			
			return this;
		}
		bool _pendingNew;

		// Used to test that Instance internals behaves correctly
		// in light of https://github.com/fusetools/fuselibs-public/issues/227
		extern (UNO_TEST) internal static int InsertCount;
		
		/** Inserts a new item into the _windowItems. The actual creation of the objects may be deferred. */
		void InsertNew(int dataIndex)
		{
			if defined (UNO_TEST) InsertCount++; 

			if (dataIndex < Offset ||
				(HasLimit && (dataIndex - Offset) >= Limit))
				return;
				
			var windowIndex = DataToWindowIndex(dataIndex);
			if ( windowIndex > _windowItems.Count || windowIndex < 0)
				return;		

			var data = GetData(dataIndex);
			InsertNewWindowItem( windowIndex, data );
		}
		
		/** Inserts a new window item associated with the given data */
		void InsertNewWindowItem( int windowIndex, object data )
		{
			var wi = new WindowItem{ Data = data };
			_windowItems.Insert( windowIndex, wi );
			
			if (Defer == InstanceDefer.Immediate)
			{
				CompleteWindowItem(wi, windowIndex);
			}
			else if (!_pendingNew)
			{
				if (Defer == InstanceDefer.Deferred)
					DeferredManager.AddPending(this, float2(DeferredPriority,NodeDepth) );
				else
					UpdateManager.AddDeferredAction(CompleteWindowItemsAction);
				_pendingNew = true;
			}
			
			OnUpdatedWindowItems();
		}
		
		bool IDeferred.Perform()
		{
			_pendingNew = CompleteWindowItems(true);
			return !_pendingNew;
		}
		
		void CompleteWindowItemsAction()
		{
			CompleteWindowItems(false);
			_pendingNew = false;
		}
		
		bool CompleteWindowItems(bool one)
		{
			//in case unrooted somehow in the meantime
			if (!IsRootingStarted)
				return false;
				
			bool first = true;
			for (int i=0; i < _windowItems.Count; ++i)
			{
				var wi = _windowItems[i];
				if (wi.Nodes == null)
				{
					if (!first && one)
						return true;
						
					CompleteWindowItem(wi, i);
					first = false;
				}
			}

			//remove whatever is leftover
			RemovePendingAvailableItems();
			return false;
		}
		
		struct TemplateMatch
		{
			//if true then all templates used and `Template` is ignored
			public bool All;
			//the specific Template to use
			public Template Template;
			
			public bool Matches(TemplateMatch b) 
			{
				if (All != b.All)
					return false;
				return Template == b.Template;
			}
		}
		
		TemplateMatch GetDataTemplate(object data)
		{
			// Algorithm for picking matching the right template
			Template useTemplate = null;
			Template defaultTemplate = null;
			
			// Priority 1 - If a TemplateSource and TemplateKey is specified
			if (_templateSource != null && TemplateKey != null)
			{
				var t = _templateSource.FindTemplate(TemplateKey);
				if (t != null)
					useTemplate = t;
			}

			// Priority 2 - use the local templates collection and look for a matching key (if set)
			if (useTemplate == null)
			{
				var key = GetDataKey(data, MatchKey) as string;
				//match Order in FindTemplate (latest is preferred)
				for (int i=Templates.Count-1; i>=0; --i) {
					var f = Templates[i];
					if (f.IsDefault) defaultTemplate = f;
					if (key != null && f.Key == key)
						useTemplate = f;
				}
			}

			// Priority 3 - Use the default template or all templates if no match specified
			if (useTemplate == null)
			{
				if (MatchKey != null || defaultTemplate != null)
					useTemplate = defaultTemplate; //may still be null
				else
					return new TemplateMatch{ All = true, Template = null }; //only unspecified can use complete list
			}
				
			return new TemplateMatch{ All = false, Template = useTemplate };
		}
		
		void CompleteWindowItem(WindowItem wi, int windowIndex)
		{
			wi.Id = GetDataId(wi.Data);
			
			var match = GetDataTemplate(wi.Data);
			var reuse = AddMatchingTemplates(wi, match);
			
			if ( (wi.Template.All && Templates.Count != wi.Nodes.Count) ||
				(wi.Template.Template != null && wi.Nodes.Count != 1))
			{
				Fuse.Diagnostics.InternalError( "inconsistent instance state", this );
			}
			

			//find last node prior to where we want to introduce
			var lastNode = GetLastNodeFromIndex(windowIndex-1);

			//InsertOrMove is slower than Insert, thus optimize if we can 
			if (reuse)
				Parent.InsertOrMoveNodesAfter( lastNode, wi.Nodes.GetEnumerator() );
			else
				Parent.InsertNodesAfter( lastNode, wi.Nodes.GetEnumerator() );
		}
		
		/**
			Replaces the data for the current item if it has an id and template match.
		
			@return true if the replacement was successful, false otherwise
		*/
		bool TryUpdateAt(int dataIndex, object newData)
		{
			if (Identity == InstanceIdentity.None)
				return false;
			
			var windowIndex = DataToWindowIndex(dataIndex);
			if (windowIndex < 0 || windowIndex >= _windowItems.Count)
				return false;
				
			var wi = _windowItems[windowIndex];
			var newId = GetDataId(newData);
			if (wi.Id == null || !Object.Equals(wi.Id, newId))
				return false;
				
			var tpl = GetDataTemplate(newData);
			if (!wi.Template.Matches(tpl))
				return false;

				
			var oldData = wi.CurrentData;
			wi.Data = newData;
			UpdateData(wi, oldData);
			return true;
		}

		/* `null` for the template indicates to use all templates, otherwise a specific one will be used. 
			
			@return true if reusing existing nodes, false if new nodes
		*/
		bool AddMatchingTemplates(WindowItem item, TemplateMatch f)
 		{
			bool reuse = false;
			object oldData = null;
			var av = GetAvailableNodes(f, item.Id);
			if (av != null)
			{
				item.Nodes = av.Nodes;
				oldData = av.CurrentData;
				av.Nodes = null;
				reuse = true;
			}
			else if (f.All)
			{
				item.Nodes = new List<Node>();
				for (int i=0; i < Templates.Count; ++i) 
					AddTemplate(item, Templates[i]);
			}
			else if (f.Template == null)
			{
				//needed to indicate we've generated the nodes, there just aren't any.
				item.Nodes = new List<Node>();
			}
			else
			{
				item.Nodes = new List<Node>();
				AddTemplate(item, f.Template);
			}

			UpdateData(item, oldData);
 			item.Template = f;
 			return reuse;
 		}
 		
 		void AddTemplate(WindowItem item, Template f)
 		{
			var elm = f.New() as Node;
			if (elm == null)
			{
				Fuse.Diagnostics.InternalError( "Template contains a non-Node", this );
				return;
			}
			item.Nodes.Add(elm);
 		}
 		
 		
		//Items with Ids will be stored in this list...
		Dictionary<object, WindowItem> _availableItemsById = new Dictionary<object,WindowItem>();
		//...since we don't have a MultiDictionary this second list stores those with null ids
		ObjectList<WindowItem> _availableItems = new ObjectList<WindowItem>();
		bool _pendingAvailableItems;
		
		/**
			Finds a matching item.
			
			The template match can be null, but this will specifically match only an item that had null
			before (meaning all templates were used). This limits cache reuse to either a specific template
			or all of them (which is the only high-level matching possible, so this covers all use-cases).
		*/
		WindowItem GetAvailableNodes(TemplateMatch f, object id)
		{
			if (id != null && _availableItemsById != null)
			{
				WindowItem item;
				if (_availableItemsById.TryGetValue(id, out item) && f.Matches(item.Template))
				{
					_availableItemsById.Remove(id);
					return item;
				}
			}
			
			if (Reuse != InstanceReuse.None && _availableItems != null)
			{
				for (int i=0; i < _availableItems.Count; ++i)
				{
					var av = _availableItems[i];
					if (f.Matches(av.Template))
					{
						_availableItems.RemoveAt(i);
						return av;
					}
				}
			}
			
			return null;
		}
		
		/* Test interface to ensure we aren't leaking resources. */
		internal bool TestIsAvailableClean
		{
			get 
			{ 
				return (_availableItems == null || _availableItems.Count == 0) &&
					(_availableItemsById == null || _availableItemsById.Count ==0);
			}
		}
		
		void CompleteNodeAction()
		{
			if (Reuse == InstanceReuse.Frame)
			{
				if (!_pendingAvailableItems)
				{
					UpdateManager.AddDeferredAction(RemovePendingAvailableItemsAction);
					_pendingAvailableItems = true;
				}
			}
			//we must nonetheless keep the nodes around until any pending new nodes have resolved
			else if (!_pendingNew)
			{
				RemovePendingAvailableItems();
			}
		}
		
		void RemovePendingAvailableItemsAction()
		{
			//The pendingNew handler will have to clear the remaining nodes
			if (!_pendingNew)	
				RemovePendingAvailableItems();
			_pendingAvailableItems = false;
		}
		
		void RemovePendingAvailableItems()
		{
			if (_availableItems != null)
			{
				for (int i=0; i < _availableItems.Count; ++i)
				{	
					var av = _availableItems[i];
					if (av.Nodes == null)
						continue;
					for (int n=0; n < av.Nodes.Count; ++n)
						RemoveFromParent(av.Nodes[n]);
					av.Unlink();
				}
				_availableItems.Clear();
			}
			
			if (_availableItemsById != null)
			{
				foreach (var kvp in _availableItemsById)
				{
					if (kvp.Value.Nodes == null)
						continue;
					for (int n=0; n < kvp.Value.Nodes.Count; ++n)
						RemoveFromParent(kvp.Value.Nodes[n]);
					kvp.Value.Unlink();
				}
				_availableItemsById.Clear();
			}
			
			_pendingNew = false;
		}
		
		void RemoveWindowItem(WindowItem wi)
		{
			if (wi.Nodes == null || wi.Nodes.Count == 0)
				return;
			
			if (wi.Id != null)
			{
				if (_availableItemsById == null)	
					_availableItemsById = new Dictionary<object,WindowItem>();

				if (_availableItemsById.ContainsKey(wi.Id))
					wi.Id = null; //clear id on duplicates for simplicity (will end up being added to _availableItems)
				else
					_availableItemsById[wi.Id] = wi;
			}
			
			//not an `else`, since Id can change above
			if (wi.Id == null)
			{
				if (_availableItems == null)
					_availableItems = new ObjectList<WindowItem>();
				_availableItems.Add( wi );
			}
		}
		
		int DataToWindowIndex(int dataIndex)
		{
			return dataIndex - Offset;
		}
	
		void RemoveAt(int dataIndex)
		{
			var windowIndex = DataToWindowIndex(dataIndex);
			if ( windowIndex < 0 || windowIndex >= _windowItems.Count)
				return;
			
			RemoveWindowItem(_windowItems[windowIndex]);
			_windowItems.RemoveAt(windowIndex);
		
 			SetValid();		
			OnUpdatedWindowItems();
		}
		
		void RemoveLastActive()
		{
			RemoveAt(Offset + _windowItems.Count - 1);
		}
		
		void Append()
		{
			InsertNew(Offset + _windowItems.Count);
		}

		/** Removes all items from _windowItems */
		void RemoveAll()
		{
			if (_windowItems.Count == 0) return;

			for (int i=0; i < _windowItems.Count; ++i)
			{
				var wi = _windowItems[i];
				RemoveWindowItem(wi);
			}
			_windowItems.Clear();
			OnUpdatedWindowItems();
		}
		
		void Repopulate()
		{
			RemoveAll();

			var e = _items as object[];
			if (e != null) 
			{
				for (int i = 0; i < e.Length; i++) InsertNew(i);
			}
			else
			{
				var a = _items as IArray;
				if (a != null) 
				{
					for (int i = 0; i < a.Length; i++) InsertNew(i);
				}
			}

			CompleteActionGood();
		}
		

		class WindowItem
		{
			/* Will be null if the nodes haven't been created. This is distinct from being non-null but having a
			count of zero. */
			public List<Node> Nodes; 
			//which templates were used to create the item
			public TemplateMatch Template;
			//the raw data associated with the item
			public object Data;
			//non-null if `Data` as an Observable
			public ObservableLink DataLink;
			//logical identifier used for matching, null if none
			public object Id;
			
			public WindowItem()
			{
			}
			
			public object CurrentData
			{
				get
				{
					return DataLink != null ? DataLink.Data : Data;
				}
			}
			
			//cleans up the memory link from DataLink to Each by fixating the current data.
			public void Unlink()
			{
				if (DataLink != null)
				{
					Data = DataLink.Data;
					DataLink.Dispose();
					DataLink = null;
				}
			}
		}
		
		/**
			A list of all items which have been added to the Instantiator. This only includes the items
			within the range of Offset+Limit.
			
			This list should only be modified via the InsertNew, RemoveAt, and RemoveAll functions.
		*/
		ObjectList<WindowItem> _windowItems = new ObjectList<WindowItem>();
		
		internal event Action UpdatedWindowItems;
		bool _pendingUpdateWindowItems;
		void OnUpdatedWindowItems()
		{
			if (UpdatedWindowItems == null || _pendingUpdateWindowItems)	
				return;
				
			//defer to accumulate changes to the list
			_pendingUpdateWindowItems = true;
			UpdateManager.AddDeferredAction(PostUpdatedWindowItems);
		}
		
		void PostUpdatedWindowItems()
		{
			if (UpdatedWindowItems != null)
				UpdatedWindowItems();
			_pendingUpdateWindowItems = false;
		}

		internal int WindowItemsCount { get { return _windowItems.Count; } }
		
		/**
			Matches the length of active items to the desired length based on `Offset` and `Limit`.
			This will add missing items and remove excess items.
		*/
		void TrimAndPad()
		{
			//trim excess
			if (HasLimit)
			{
				for (int i=_windowItems.Count - _limit; i > 0; --i)
					RemoveLastActive();
			}
				
			//add new
			var dataCount = GetDataCount();
			var add = HasLimit ?
				Math.Min(_limit - _windowItems.Count, dataCount - (Offset + _windowItems.Count)) : 
				(dataCount - (Offset + _windowItems.Count));
			for (int i=0; i < add; ++i)
				Append();
		}
	}
}