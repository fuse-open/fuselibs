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
			if (windowIndex >= _watcher.WindowItemCount)
				windowIndex = _watcher.WindowItemCount - 1;
				
			while (windowIndex >= 0)
			{
				var lastList = _watcher.GetWindowItem(windowIndex).Nodes;
				if (lastList != null && lastList.Count != 0)
					return lastList[lastList.Count-1].GetLastNodeInGroup();

				//support an odd case where an each-item doesn't have any children
				windowIndex--;
			}
			
			return this;
		}
		bool _pendingNew;
		
		/** Inserts a new window item associated with the given data */
		void ItemsWindowList<WindowItem>.IListener.AddedWindowItem( int windowIndex, WindowItem wi )
		{
			PrepareWindowItem( windowIndex, wi );
			OnUpdatedWindowItems();
		}
		
		void PrepareWindowItem( int windowIndex, WindowItem wi )
		{
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
			for (int i=0; i < _watcher.WindowItemCount; ++i)
			{
				var wi = _watcher.GetWindowItem(i);
				if (wi.Nodes == null)
				{
					if (!first && one)
						return true;
						
					CompleteWindowItem(wi, i);
					first = false;
				}
			}

			//remove whatever is leftover
			RemoveAvailableItems();
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
				var key = _watcher.GetDataKey(data, MatchKey) as string;
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
			var match = GetDataTemplate(wi.CurrentData);
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

			PrepareDataContext(item);
			//TODO: It's questionalbe that the below is required, surely rooting should be enough for DataContext changes?  It doesn't appear to be an issue in the Instantiaor though.
			BroadcastDataChange(item, oldData);
 			item.Template = f;
 			return reuse;
 		}
 		
 		void PrepareDataContext(WindowItem wi)
 		{
			for (int i=0; i < wi.Nodes.Count; ++i)
			{
				var n = wi.Nodes[i];
				n.OverrideContextParent = this;
				_dataMap[n] = wi;
			}
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
		
		void ScheduleRemoveAvailableItems()
		{
			if (Reuse == InstanceReuse.Frame)
			{
				if (!_pendingAvailableItems)
				{
					UpdateManager.AddDeferredAction(RemoveAvailableItemsAction);
					_pendingAvailableItems = true;
				}
			}
			//we must nonetheless keep the nodes around until any pending new nodes have resolved
			else if (!_pendingNew)
			{
				RemoveAvailableItems();
			}
		}
		
		void RemoveAvailableItemsAction()
		{
			//The pendingNew handler will have to clear the remaining nodes
			if (!_pendingNew)	
				RemoveAvailableItems();
			_pendingAvailableItems = false;
		}
		
		void RemoveAvailableItems()
		{
			if (_availableItems != null)
			{
				for (int i=0; i < _availableItems.Count; ++i)
					DisposeWindowItem(_availableItems[i]);
				_availableItems.Clear();
			}
			
			if (_availableItemsById != null)
			{
				foreach (var kvp in _availableItemsById)
					DisposeWindowItem(kvp.Value);
				_availableItemsById.Clear();
			}
			
			_pendingNew = false;
		}
		
		void DisposeWindowItem( WindowItem wi)
		{
			CleanupWindowItem(wi);
			wi.Dispose();
		}
		
		void CleanupWindowItem( WindowItem wi )
		{
			if (wi.Nodes != null)
			{
				for (int n=0; n < wi.Nodes.Count; ++n)
					RemoveFromParent(wi.Nodes[n]);
				wi.Nodes = null;
			}
		}

		/* A removed item is added to the  list of available nodes and can be reused by a new incoming item. The available nodes are kept as children of the parent, they are not removed. */
		void ItemsWindowList<WindowItem>.IListener.RemovedWindowItem(WindowItem wi)
		{
			if (wi.Nodes == null || wi.Nodes.Count == 0)
				return;
			
			bool generic = wi.Id == null;
			if (wi.Id != null)
			{
				if (_availableItemsById == null)	
					_availableItemsById = new Dictionary<object,WindowItem>();

				if (_availableItemsById.ContainsKey(wi.Id))
					generic = true;
				else
					_availableItemsById[wi.Id] = wi;
			}
			
			if (generic)
			{
				if (_availableItems == null)
					_availableItems = new ObjectList<WindowItem>();
				_availableItems.Add( wi );
			}
			
			ScheduleRemoveAvailableItems();
			OnUpdatedWindowItems();
		}
		
		void RecreateTemplates()
		{
			for (int i = 0; i < _watcher.WindowItemCount; i++)
				CleanupWindowItem( _watcher.GetWindowItem(i) );
				
			for (int i = 0; i < _watcher.WindowItemCount; i++)
				PrepareWindowItem( i, _watcher.GetWindowItem(i) );
			
			ScheduleRemoveAvailableItems();
		}
		
		class WindowItem : WindowListItem
		{
			/* Will be null if the nodes haven't been created. This is distinct from being non-null but having a
			count of zero. */
			public List<Node> Nodes; 
			//which templates were used to create the item
			public TemplateMatch Template;
		}
		
		void ItemsWindowList<WindowItem>.IListener.OnCurrentDataChanged(WindowItem wi, object oldData)
		{
			//check for new template
			var tpl = GetDataTemplate(wi.CurrentData);
			if (!tpl.Matches( wi.Template) )
			{
				var index = _watcher.GetWindowItemIndex(wi);
				if (index == -1)
				{
					Fuse.Diagnostics.InternalError( "Invalid WindowItem updated", this );
					return;
				}
				
				CleanupWindowItem(wi);
				PrepareWindowItem(index, wi);
				return;
			}
			BroadcastDataChange(wi, oldData);
		}
		
		void BroadcastDataChange(WindowItem wi, object oldData)
		{
			if (wi.Nodes == null)
				return;
				
			for (int i=0; i < wi.Nodes.Count; ++i)
				wi.Nodes[i].BroadcastDataChange(oldData, wi.CurrentData);
		}
		
		ItemsWindowList<WindowItem> _watcher;
		
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

		internal int WindowItemsCount { get { return _watcher.WindowItemCount; } }
	}
}
