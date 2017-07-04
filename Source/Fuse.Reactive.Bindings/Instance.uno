using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse.Internal;
using Fuse.Triggers;

namespace Fuse.Reactive
{
	public enum InstanceDefer
	{
		/** Items will be added immediately to the tree. */
		Immediate,
		/** Item changes will be buffered and added once per frame. */
		Frame,
		/** Items will be added as though they are wrapped in a @Deferred node. */
		Deferred,
	}
	
	public enum InstanceReuse
	{
		/** Instances are not reused */
		None,
		/** Instances can be reused in the same frame */
		Frame,
	}
	
	public enum InstanceObjectMatch
	{
		/** New objects are always new, never matched to an existing one */
		None,
		/** The `ObjectId` is used to compare objects */
		FieldId,
	}
	
	[UXContentMode("Template")]
	/** Base class for behaviors that can instantiate templates from a source.

		This class can not be directly instantiated or inherited because its constructors are internal. Use one of the
		provided derived classes instead: @Each or @Instance.
	*/
	public partial class Instantiator: Behavior, IObserver, Node.ISubtreeDataProvider, IDeferred
	{
		IList<Template> _templates;
		RootableList<Template> _rootTemplates;
		
		protected internal Instantiator(IList<Template> templates)
		{
			_templates = templates;
		}

		protected internal Instantiator()
		{
		}

		/** Specifies a list of templates that will be used to reflect the data in `Items`.

			Typically, this collection is not referred to directly. Rather, it will contain all of the children of the `Each` tag in UX.
		*/
		[UXPrimary]
		public IList<Template> Templates
		{
			get
			{
				if (_templates != null)
					return _templates;
					
				_rootTemplates = new RootableList<Template>();
				if (IsRootingCompleted)
					_rootTemplates.Subscribe(OnTemplatesChanged, OnTemplatesChanged);
				_templates = _rootTemplates;
				return _templates;
			}
		}

		InstanceDefer _defer = InstanceDefer.Frame;
		/** Defers the creation items to avoid processing bottlenecks.
		
			The default is `Frame`.
		*/
		public InstanceDefer Defer
		{
			get { return _defer; }
			set { _defer = value; }
		}
		
		InstanceReuse _reuse = InstanceReuse.None;
		/** Attempts to reuse template instances when items are being removed and created.
		
			The default is `None`
			
			Be aware that when using this feature several other features may no longer work as expected, such as:
				- RemovingAnimation: the reused items are not actually removed
				- AddingAnimation: the resused items are not actually added, just moved
				- Completed: As a reused item is not added/removed it will not trigger a second time
				
			This feature will remain experimental until we can figure out which of these issues can be solved, avoided, or just need to be accepted.
				
			@experimental
		*/
		public InstanceReuse Reuse
		{
			get { return _reuse; }
			set { _reuse = value; }
		}
		
		InstanceObjectMatch _objectMatch = InstanceObjectMatch.None;
		public InstanceObjectMatch ObjectMatch
		{
			get { return _objectMatch; }
			set { _objectMatch = value; }
		}
		
		string _objectId = null;
		public string ObjectId
		{
			get { return _objectId; }
			set 
			{ 
				_objectId = value; 
				ObjectMatch = InstanceObjectMatch.FieldId;
			}
		}
		
		float _deferredPriority = 0;
		/**
			For `Defer="Deferred"` specifies the deferrefed priority.
			
			@see Defererred.Priority
		*/
		public float DeferredPriority
		{
			get { return _deferredPriority; }
			set { _deferredPriority = value; }
		}
		
		/** Specifies a visual that contains templates that can override the default `Templates` provided in this object.

			If specified together with @TemplateKey, this instantiator will prefer to pick template from the
			specified `TemplateSource` that matches the `TemplateKey` property. If no match is found, it falls back
			to using the regular list of `Templates`.

			This property is useful if you are creating a component and want to allow certain templates inside the
			component to be overridden by the user.

			## Example

			This example uses `Each`, but it applies equally to `Instance` and other subclasses of `Instantiator`.

				<Panel ux:Class="MyListControl">
					<StackPanel>
						<Each Count="10" TemplateSource="this" TemplateKey="ListItem">
							<Text Value="This is an item" />
						</Each>
					</StackPanel>
				</Panel>

			If we instantiate `<MyListControl>` now, it will display the text "This is an item" 10 times.

			However, we can override the template like this:

				<MyListControl>
					<Rectangle ux:Template="ListItem" Color="Red">
						<Text>This is a red item</Text>
					</Rectangle>
				</MyListControl>

			This will display a red rectangle with the text "This is a red item" 10 times, instead of the default
			template defined in the component itself.

			The `TemplateSource` property, along with the templates in the source, as well as the `TemplateKey`, must be set prior to
			rooting to take effect.
		*/
		public ITemplateSource TemplateSource
		{
			get { return _weakTemplateSource; }
			set { _weakTemplateSource = value; }
		}
		//https://github.com/fusetools/fuselibs-public/issues/135
		[WeakReference]
		ITemplateSource _weakTemplateSource;
		ITemplateSource _templateSource; //captured at rooting time

		/** Specifies a template key that is used to look up in the @TemplateSource to find an override of the default
			`Templates` provided in this object.

			This property, along with the templates in the @TemplateSource, must be set prior to
			rooting to take effect.
		*/
		public string TemplateKey
		{
			get; set;
		}

		void OnTemplatesChanged(Template factory)
		{
			if (!IsRootingCompleted) return;
			Repopulate();
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			OnItemsChanged();
			
			if (_rootTemplates != null)
				_rootTemplates.Subscribe(OnTemplatesChanged, OnTemplatesChanged);
			_templateSource = _weakTemplateSource;
		}

		protected override void OnUnrooted()
		{
			if (_subscription != null)
			{
				_subscription.Dispose();
				_subscription = null;
				_listening = false;
			}

			RemoveAll();
			RemovePendingAvailableItems();

			if (_rootTemplates != null)
				_rootTemplates.Unsubscribe();
			_templateSource = null;
				
			_completedRemove = null;
			base.OnUnrooted();
		}

		int _offset = 0;
		internal int Offset
		{
			get { return _offset; }
			set
			{
				if (_offset == value)
					return;
					
				if (value < 0)
				{
					Fuse.Diagnostics.UserError( "Offset cannot be less than 0", this );
					value = 0;
				}
				
				if (!IsRootingCompleted)
				{
					_offset = value;
					return;
				}
				
				//slide the window in both directions as necessary
				var dataCount = GetDataCount();
				while (_offset < value)
				{
					if (_offset < dataCount)
						RemoveAt(_offset);
						
					_offset++;
					var end = _offset + Limit - 1;
					if (HasLimit && end < dataCount)
						InsertNew(end);
				}
				
				while (_offset > value)
				{
					var end = _offset + Limit - 1;
					if (HasLimit && end < dataCount)
						RemoveAt(_offset + Limit - 1);
						
					_offset--;
					if (_offset < dataCount)
						InsertNew(_offset);
				}
			}
		}
		
		int _limit = 0;
		bool _hasLimit;
		internal int Limit
		{
			get { return _limit; }
			set
			{
				if (_hasLimit && _limit == value)
					return;
					
				if (value < 0)
				{
					Fuse.Diagnostics.UserError( "Limit cannot be less than 0", this );
					value = 0;
				}
				
				_hasLimit = true;
				_limit = value;
				if (IsRootingCompleted)
					TrimAndPad();
			}
		}
		
		void TrimAndPad()
		{
			//trim excess
			if (HasLimit)
			{
				for (int i=WindowItemsActiveCount - _limit; i > 0; --i)
					RemoveLastActive();
			}
				
			//add new
			var dataCount = GetDataCount();
			var add = HasLimit ?
				Math.Min(_limit - WindowItemsActiveCount, dataCount - (Offset + WindowItemsActiveCount)) : 
				(dataCount - (Offset + WindowItemsActiveCount));
			for (int i=0; i < add; ++i)
				Append();
		}
		
		int CalcOffsetLimitCountOf( int length )
		{
			var q = Math.Max( 0, length - Offset );
			return HasLimit ? Math.Min( Limit, q ) : q;
		}
		
		internal bool HasLimit { get { return _hasLimit; } }

		protected internal object _items;
		
		class CountItem { }
		
		int _count;
		protected internal int Count
		{
			get { return _count; }
			set
			{
				if (_count == value)
					return;
					
				_count = value;
				var items = new object[_count];
				for (int i=0; i < _count; ++i)
					items[i] = new CountItem();
				_items = items;
				OnItemsChanged();
			}
		}
		
		bool _listening;

		protected internal void OnItemsChanged()
		{
			if (!IsRootingStarted) return;

			RemoveAll();

			var obs = _items as IObservable;
			if (obs != null)
			{
				if (_subscription != null) _subscription.Dispose();
				_listening = true;
				_subscription = obs.Subscribe(this);
			}
			else
			{
				Repopulate();
			}
		}

		class WindowItem
		{
			/* Will be null if the nodes haven't been created. This is distinct from being non-null but having a
			count of zero. */
			public List<Node> Nodes; 
			//this is either the one speicfic matching template, or null to indicate the full set
			public Template Template;
			//the raw data associated with the item
			public object Data;
			//non-null if `Data` as an Observable
			public ObservableLink DataLink;
			//logical identifier used for matching, null if none
			public object Id;
			//this item is removed from the data/window but pending child removal
			public bool Removed;
			
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
			
			public void Dispose()
			{
				if (DataLink != null)
					DataLink.Dispose();
			}
			
			public bool IsRemovedEmpty
			{
				get { return Removed && (Nodes == null || Nodes.Count == 0); }
			}
		}
		
		/**
			A list of all items which have been added to the Instantiator. This only includes the items
			within the range of Offset+Limit.
			
			This list should only be modified via the InsertNew, RemoveAt, and RemoveAll functions.
		*/
		ObjectList<WindowItem> _windowItems = new ObjectList<WindowItem>();
		
		int WindowItemsActiveCount 
		{
			get 
			{ 
				var c = 0;
				for (int i=0; i < _windowItems.Count; ++i)
				{
					if (!_windowItems[i].Removed)
						c++;
				}
				return c;
			}
		}
		
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

		internal int WindowItemsCount { get { return WindowItemsActiveCount; } }
		
		internal int DataIndexOfChild(Node child)
		{
			var c = Offset;
			for (int i = 0; i < _windowItems.Count; i++)
			{
				var wi = _windowItems[i];
				var list = wi.Nodes;
				if (list == null)
					continue;
					
				for (int n = 0; n < list.Count; n++)
				{
					if (list[n] == child)
						return wi.Removed ? -1 : c;
				}
					
				if (!wi.Removed)	
					c++;
			}
			return -1;
		}

		object GetData(int dataIndex)
		{
			var e = _items as object[];
			if (e != null) return e[dataIndex];

			var a = _items as IArray;
			if (a != null) return a[dataIndex];

			return null;
		}
		
		int GetDataCount()
		{
			var e = _items as object[];
			if (e != null) return e.Length;

			var a = _items as IArray;
			if (a != null) return a.Length;

			return 0;
		}
		
		internal int DataCount { get { return GetDataCount(); } }

		object Node.ISubtreeDataProvider.GetData(Node n)
		{
			WindowItem v;
			if (_dataMap.TryGetValue(n, out v))
			{
				//https://github.com/fusetools/fuselibs/issues/3312
				//`Count` does not introduce data items
				if (v.Data is CountItem)
					return null;
					
				return v.CurrentData;
			}

			return null;
		}

		void Repopulate()
		{
			var e = _items as object[];
			var a = _items as IArray;

			if (e != null)
			{
				ReplaceAll(e);
				return;
			}
			else if (a != null)
			{
				RemoveAll();
				for (int i = 0; i < a.Length; i++) InsertNew(i);
			}
		}

		BusyTask _busyTask;
		void SetValid()
		{
			if (Parent != null)
				BusyTask.SetBusy(Parent, ref _busyTask, BusyTaskActivity.None );
		}

		void SetFailed(string message)
		{
			if (Parent != null)
				BusyTask.SetBusy(Parent, ref _busyTask, BusyTaskActivity.Failed, message );
		}

		IDisposable _subscription;

		//Items with Ids will be stored in this list...
		Dictionary<object, WindowItem> _availableItemsById = new Dictionary<object,WindowItem>();
		//...since we don't have a MultiDictionary this second list stores those with null ids
		ObjectList<WindowItem> _availableItems = new ObjectList<WindowItem>();
		bool _pendingAvailableItems;
		
		WindowItem GetAvailableNodes(Template f, object id)
		{
			if (id != null && _availableItemsById != null)
			{
				WindowItem item;
				if (_availableItemsById.TryGetValue(id, out item) && f == item.Template)
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
					if (f == av.Template)
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
		
		internal bool TestIsRemovedClean
		{
			get { return WindowItemsActiveCount == _windowItems.Count; }
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
		}
		
		void RemovePendingAvailableItems()
		{
			if (_availableItems != null)
			{
				for (int i=0; i < _availableItems.Count; ++i)
				{	
					var av = _availableItems[i];
					for (int n=0; n < av.Nodes.Count; ++n)
						RemoveFromParent(av.Nodes[n]);
				}
				_availableItems.Clear();
			}
			
			if (_availableItemsById != null)
			{
				foreach (var kvp in _availableItemsById)
				{
					for (int n=0; n < kvp.Value.Nodes.Count; ++n)
						RemoveFromParent(kvp.Value.Nodes[n]);
				}
				_availableItemsById.Clear();
			}
			
			for (int i=_windowItems.Count-1; i>=0; --i)
			{
				if (_windowItems[i].IsRemovedEmpty)
					_windowItems.RemoveAt(i);
			}
			
			_pendingNew = false;
		}
		
		void RemoveWindowItem(WindowItem wi)
		{
			wi.Removed = true;
			if (wi.Nodes == null)
			{
				_windowItems.Remove(wi);
				return;
			}
			
			if (wi.Id != null)
			{
				if (_availableItemsById == null)	
					_availableItemsById = new Dictionary<object,WindowItem>();

				if (_availableItemsById.ContainsKey(wi.Id))
					wi.Id = null; //clear id on duplicates for simplicity (will end up being added to _availableItems)
				else
					_availableItemsById[wi.Id] = wi;
			}
			
			//not an else, since Id can change above
			if (wi.Id == null)
			{
				if (_availableItems == null)
					_availableItems = new ObjectList<WindowItem>();
				_availableItems.Add( wi );
			}
		}
		
		int DataToWindowIndex(int dataIndex)
		{
			var raw = dataIndex - Offset;
			if (raw < 0)
				return raw;
				
			var removed = 0;
			for (int wi=0; wi < _windowItems.Count; ++wi)
			{
				if (!_windowItems[wi].Removed)
				{
					if (raw <= 0)
						return wi;
				
					raw--;
				}
				else
					removed++;
			}

			return dataIndex - Offset + removed;
		}
	
		void RemoveAt(int dataIndex)
		{
			var windowIndex = DataToWindowIndex(dataIndex);
			if ( windowIndex < 0 || windowIndex >= _windowItems.Count)
				return;
			
			RemoveWindowItem(_windowItems[windowIndex]);
		
 			SetValid();		
			OnUpdatedWindowItems();
		}
		
		void RemoveLastActive()
		{
			RemoveAt(Offset + WindowItemsActiveCount - 1);
		}
		
		void Append()
		{
			InsertNew(Offset + WindowItemsActiveCount);
		}

		void ReplaceAll(object[] dcs)
		{
			RemoveAll();

			for (int i = 0; i < dcs.Length; i++) InsertNew(i);
		}

		/** Removes all items from _windowItems */
		void RemoveAll()
		{
			if (_windowItems.Count == 0) return;

			for (int i=0; i < _windowItems.Count; ++i)
			{
				var wi = _windowItems[i];
				if (!wi.Removed)
					RemoveWindowItem(wi);
			}
			OnUpdatedWindowItems();
		}
		
		//prevents creation of this delegate each time an item is removed
		Action<Node> _completedRemove;
		void RemoveFromParent(Node n)
		{
			if (_completedRemove == null)
				_completedRemove = CompletedRemove;
			Parent.BeginRemoveChild(n, _completedRemove);
		}
		
		void CompletedRemove(Node n)
		{
			n.OverrideContextParent = null;
			
			WindowItem wi;
			if (_dataMap.TryGetValue(n, out wi))
			{
				if (!wi.Nodes.Remove(n))
					Fuse.Diagnostics.InternalError( "inconsistent Nodes list state", this );
					
				_dataMap.Remove(n);
				
				if (wi.Nodes.Count == 0)
					wi.Dispose();
					
				_windowItems.Remove(wi);
			}

		}

		string _matchKey;

		/** Name of the field on each data object which selects templates for the data objects.

			If set, the `Each` will instantiate the template with a name matching the `MatchKey` instead of the 
			default template for each data item.

			## Example

			MatchKey can be used together with `ux:Template` to select the correct template based on
			a string field in the data source. 

			Instead of:

				<Each Items="{listData}">
				<Deferred>
					<Match Value="{type}">
						<Case String="month">
							<Panel ...
			Do:

				<Each Items="{listData}" MatchKey="type">
					<Deferred ux:Template="month">
						<Panel ...
		*/
		public string MatchKey
		{
			get { return _matchKey; }
			set
			{
				if (_matchKey != value)
				{
					_matchKey = value;
					OnItemsChanged();
				}
			}
		}

		object GetDataKey(object data, string key)
		{
			var so = data as IObject;

			if (so != null && key != null)
			{
				if (so.ContainsKey(key))
					return so[key];
			}

			return null;
		}

		bool _pendingNew;
		
		/** Inserts a new item into the _windowItems. The actual creation of the objects may be deferred. */
		void InsertNew(int dataIndex)
		{
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
				if (wi.Removed)
					continue;
					
				if (wi.Nodes == null)
				{
					if (!first && one)
						return true;
						
					CompleteWindowItem(wi, i);
					first = false;
				}
			}

			//TODO: this seems like it's in the wrong location
			//remove whatever is leftover
			RemovePendingAvailableItems();
			return false;
		}
		
		Template GetDataTemplate(object data)
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
				var key = GetDataKey(data, _matchKey) as string;
				//match Order in FindTemplate (latest is preferred)
				for (int i=Templates.Count-1; i>=0; --i) {
					var f = Templates[i];
					if (f.IsDefault) defaultTemplate = f;
					if (key != null && f.Key != key) continue;

					if (useTemplate == null) useTemplate = f;
				}
			}

			// Priority 3 - Use the default template if provided
			if (useTemplate == null)
				useTemplate = defaultTemplate; //may still be null
				
			return useTemplate;
		}
		
		void CompleteWindowItem(WindowItem wi, int windowIndex)
		{
			wi.Id = GetDataKey(wi.Data, ObjectId);
			
			AddTemplate(wi, GetDataTemplate(wi.Data));
			
			if ( (wi.Template == null && Templates.Count != wi.Nodes.Count) ||
				(wi.Template != null && wi.Nodes.Count != 1))
			{
				Fuse.Diagnostics.InternalError( "inconsistent instance state", this );
			}
			

			//find last node prior to where we want to introduce
			var lastNode = GetLastNodeFromIndex(windowIndex-1);

			Parent.InsertOrMoveNodes( Parent.Children.IndexOf(lastNode) + 1, wi.Nodes.GetEnumerator() );
		}
		
		/**
			Replaces the data for the current item if it has an id and template match.
		
			@return true if the replacement was successful, false otherwise
		*/
		bool TryUpdateAt(int dataIndex, object newData)
		{
			if (ObjectMatch == InstanceObjectMatch.None)
				return false;
			
			var windowIndex = DataToWindowIndex(dataIndex);
			if (windowIndex < 0 || windowIndex >= _windowItems.Count)
				return false;
				
			var wi = _windowItems[windowIndex];
			if (wi.Removed)
				return false;
				
			var newId = GetDataKey(newData, ObjectId);
			if (wi.Id == null || !Object.Equals(wi.Id, newId))
				return false;
				
			var tpl = GetDataTemplate(newData);
			if (wi.Template != tpl)
				return false;

				
			var oldData = wi.CurrentData;
			wi.Data = newData;
			UpdateData(wi, oldData);
			return true;
		}

		class ObservableLink: ValueObserver
		{
			WindowItem _target;

			public ObservableLink(IObservable obs, WindowItem target)
			{
				_target = target;
				Subscribe(obs);
			}

			public override void Dispose()
			{
				base.Dispose();
				_target = null;
				_currentData = null;
			}

			object _currentData;
			public object Data { get { return _currentData; } }

			protected override void PushData(object newData)
			{
				if (_target == null) return;

				var oldData = _currentData;
				_currentData = newData;
				for (int i=0; i < _target.Nodes.Count; ++i)
					_target.Nodes[i].BroadcastDataChange(oldData, newData);
			}
		}

		Dictionary<Node,WindowItem> _dataMap = new Dictionary<Node,WindowItem>();

		
		void AddTemplate(WindowItem item, Template f)
 		{
			object oldData = null;
			var av = GetAvailableNodes(f, item.Id);
			if (av != null)
			{
				item.Nodes = av.Nodes;
				oldData = av.CurrentData;
				av.Nodes = null;
			}
			else
			{
				item.Nodes = new List<Node>();
				var elm = f.New() as Node;
				if (elm == null)
				{
					Fuse.Diagnostics.InternalError( "Template contains a non-Node", this );
					return;
				}
				item.Nodes.Add(elm);
			}

			UpdateData(item, oldData);
 			item.Template = f;
 		}
 		
 		void UpdateData(WindowItem item, object oldData)
 		{
			if (item.DataLink != null)
			{
				item.DataLink.Dispose();
				item.DataLink = null;
			}

			var obs = item.Data as IObservable;
			if (obs != null)
				item.DataLink = new ObservableLink(obs, item);
			
			var nextData = item.CurrentData;
			for (int i=0; i < item.Nodes.Count; ++i)
			{
				var n = item.Nodes[i];
				_dataMap[n] = item;
				n.OverrideContextParent = this;
				if (oldData != null)
					n.BroadcastDataChange(oldData, nextData);
			}
 		}

		internal override Node GetLastNodeInGroup()
		{
			return GetLastNodeFromIndex(_windowItems.Count -1);
		}
		
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
	}

	/** Creates and inserts an instance of the given template(s). */
	public class Instance: Instantiator
	{
		public Instance() 
		{
			Count = 1;
		}
	}
}