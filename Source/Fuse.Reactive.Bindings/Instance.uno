using Uno;
using Uno.Collections;
using Uno.UX;
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
	
	[UXContentMode("Template")]
	/** Base class for behaviors that can instantiate templates from a source.

		This class can not be directly instantiated or inherited because its constructors are internal. Use one of the
		provided derived classes instead: @Each or @Instance.
	*/
	public class Instantiator: Behavior, IObserver, ITemplateObserver, Node.ISubtreeDataProvider, IDeferred
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
		public Visual TemplateSource
		{
			get; set;
		}

		/** Specifies a template key that is used to look up in the @TemplateSource to find an override of the default
			`Templates` provided in this object.

			This property, along with the templates in the @TemplateSource, must be set prior to
			rooting to take effect.
		*/
		public string TemplateKey
		{
			get; set;
		}

		void ITemplateObserver.OnTemplatesChangedWileRooted()
		{
			Repopulate();
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

			if (_rootTemplates != null)
				_rootTemplates.Unsubscribe();
				
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
				while (_windowItems.Count > _limit)
					RemoveAt( Offset + _windowItems.Count - 1 );
			}
				
			//add new
			var dataCount = GetDataCount();
			if (HasLimit)
			{
				while (_windowItems.Count < _limit && (Offset + _windowItems.Count) < dataCount)
					InsertNew(Offset + _windowItems.Count);
			}
			else
			{
				while ( (Offset + _windowItems.Count) < dataCount)
					InsertNew(Offset + _windowItems.Count);
			}
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
			//this is a separate list so we can call `Visual.InsertNodes` with `Nodes` alone
			public List<Template> Templates;
			public object Data;
			
			public WindowItem()
			{
			}
		}
		
		/**
			A list of all items which have been added to the Instantiator. This only includes the items
			within the range of Offset+Limit.
			
			This list should only be modified via the InsertNew, RemoveAt, and RemoveAll functions.
		*/
		List<WindowItem> _windowItems = new List<WindowItem>();
		
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
		
		internal int DataIndexOfChild(Node child)
		{
			for (int i = 0; i < _windowItems.Count; i++)
			{
				var list = _windowItems[i].Nodes;
				if (list == null)
					continue;
					
				for (int n = 0; n < list.Count; n++)
					if (list[n] == child) return i + Offset;
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
			object v;
			if (_dataMap.TryGetValue(n, out v))
			{
				var ol = v as ObservableLink;
				if (ol != null) return ol.Data;

				//https://github.com/fusetools/fuselibs/issues/3312
				//`Count` does not introduce data items
				if (!(v is CountItem))
					return v;
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

		void IObserver.OnSet(object newValue)
		{
			if (!_listening) return;

			RemoveAll();
			TrimAndPad();
			SetValid();
		}
		
		void IObserver.OnFailed(string message)
		{
			if (!_listening) return;

			RemoveAll();
			SetFailed(message);
		}
		
		void IObserver.OnAdd(object addedValue)
		{
			if (!_listening) return;

			TrimAndPad();
			SetValid();
		}
		
		void IObserver.OnRemoveAt(int index)
		{
			if (!_listening) return;

			RemoveAt(index);
			TrimAndPad();
			SetValid();
		}

		/* Removes the item from the list of windowItems and cleans up associated nodes. */
		void RemoveAt(int dataIndex)
		{
			var windowIndex = dataIndex - Offset;
			if ( windowIndex < 0 || windowIndex >= _windowItems.Count)
				return;
			
			var list = _windowItems[windowIndex].Nodes;
			if (list != null)
			{
				for (int i=0; i < list.Count; ++i)
					RemoveFromParent(list[i]);
			}
 
			_windowItems.RemoveAt(windowIndex);
 			SetValid();		
			OnUpdatedWindowItems();
		}

		void IObserver.OnInsertAt(int index, object value)
		{
			if (!_listening) return;
			InsertNew(index);
			TrimAndPad();

			SetValid();
		}

		void IObserver.OnNewAt(int index, object value)
		{
			if (!_listening) return;

			RemoveAt(index);
			InsertNew(index);
			TrimAndPad();
		}

		void IObserver.OnNewAll(IArray values)
		{
			if (!_listening) return;

			RemoveAll();
			TrimAndPad();
			SetValid();
		}

		void IObserver.OnClear()
		{
			if (!_listening) return;

			RemoveAll();
			SetValid();
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

			var items = _windowItems;
			_windowItems = new List<WindowItem>();

			for (int i = 0; i < items.Count; i++)
			{
				var l = items[i].Nodes;
				if (l == null)
					continue;
				for (int n = 0; n < l.Count; n++)
					RemoveFromParent(l[n]);
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
			_dataMap.Remove(n);
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

		string GetMatchKey(object data)
		{
			var so = data as IObject;

			if (so != null && _matchKey != null)
			{
				if (so.ContainsKey(_matchKey))
					return so[_matchKey] as string;
			}

			return null;
		}

		bool _pendingNew;
		
		/** Inserts a new item into the _windowItems. The actual creation of the objects may be deferred. */
		void InsertNew(int dataIndex)
		{
			var windowIndex = dataIndex - Offset;
			if ( (HasLimit && windowIndex >= Limit) || windowIndex < 0)
				return;		

			var data = GetData(dataIndex);
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
				if (_windowItems[i].Nodes == null)
				{
					if (!first && one)
						return true;
						
					CompleteWindowItem(_windowItems[i], i);
					first = false;
				}
			}
			return false;
		}
		
		void CompleteWindowItem(WindowItem wi, int windowIndex)
		{
			wi.Nodes = new List<Node>();
			wi.Templates = new List<Template>();

			bool anyMatched = false;
			Template defaultTemplate = null;

			// Algorithm for picking matching the right template

			// Priority 1 - If a TemplateSource and TemplateKey is specified
			// look for a template in the source that matches the key.
			// If found, use that
			if (TemplateSource != null && TemplateKey != null)
			{
				var t = TemplateSource.FindTemplate(TemplateKey);

				if (t != null)
				{
					anyMatched = true;
					AddTemplate(wi, t);
				}
			}

			// Priority 2 - If the template source wasn't matched, use the local
			// Templates collection and look for a matching key (if set)
			if (!anyMatched)
			{
				var key = GetMatchKey(wi.Data);
				foreach (var f in Templates)
				{
					if (f.IsDefault) defaultTemplate = f;
					if (key != null && f.Key != key) continue;

					anyMatched = true;

					AddTemplate(wi, f);
				}
			}

			// Priority 3 - Use the default template if provided
			if (!anyMatched && defaultTemplate != null)
			{
				AddTemplate(wi, defaultTemplate);
			}

			//find last node prior to where we want to introduce
			var lastNode = GetLastNodeFromIndex(windowIndex-1);

			Parent.InsertNodes( Parent.Children.IndexOf(lastNode) + 1, wi.Nodes.GetEnumerator() );
		}

		class ObservableLink: ValueObserver
		{
			Node _target;

			public ObservableLink(IObservable obs, Node target)
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
				_target.BroadcastDataChange(oldData, newData);
			}
		}

		Dictionary<Node,object> _dataMap = new Dictionary<Node,object>();


		void AddTemplate(WindowItem item, Template f)
 		{
 			var elm = f.New() as Node;
			if (elm == null)
			{
				Fuse.Diagnostics.InternalError( "Template contains a non-Node", this );
				return;
			}

			var obs = item.Data as IObservable;
			if (obs != null)
			{
				_dataMap[elm] = new ObservableLink(obs, elm);
			}
			else
			{
				_dataMap[elm] = item.Data;	
			}
			
 			elm.OverrideContextParent = this;
 			if (item.Nodes.Count != item.Templates.Count)
				throw new Exception( "WindowItem list corruption" );
				
 			item.Nodes.Add(elm);
 			item.Templates.Add(f);
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