using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse.Triggers;
using Fuse.Internal;

namespace Fuse.Reactive
{
	/**
		Allows for the deferred creation of items to avoid processing bottlenecks.
		
		@see Instantiator.Defer
	*/
	public enum InstanceDefer
	{
		/** Items will be added immediately to the tree. */
		Immediate,
		/** Item changes will be buffered and added once per frame. */
		Frame,
		/** Items will be added as though they are wrapped in a @Deferred node. */
		Deferred,
	}
	
	/**
		Which nodes can be reused as the items list changes.
		
		@see Instantiator.Reuse
	*/
	public enum InstanceReuse
	{
		/** Instances are not reused */
		None,
		/** Instances can be reused in the same frame */
		Frame,
	}

	/**
		How @Instance and @Each recognize an object is the same.
	
		@see Instantiator.Identity
	*/
	public enum InstanceIdentity
	{
		/** New objects are always new, never matched to an existing one */
		None,
		/** The `IdentityKey` is used to compare objects. This value is chosen implicitly if `IdentityKey` is used. */
		Key,
		/** Use the object itself as the matching key. Suitable for when the object is a plain string or number. */
		Object,
	}
	
	/**
		Which templates are instantiating when no specific match is found.
		
		@see Instantiator.Defaults
	*/
	public enum InstanceDefaults
	{
		/** The standard strategy is used: if no matching specifiers use all templates, or the ones marked default if they exist */
		Standard,
		/** Only ones marked default will be used as defaults */
		Default,
		/** No defaults will be used */
		None,
	}

	/* `WindowItem` and `TemplateMatch` are meant to be private to `Instantiator`.  They've been
		outside to solve a  build error on DotNet/Windows shown on AppVeyor 
		(not reproducible on DotNet/OSX) 
		UNO: https://github.com/fusetools/uno/issues/1503
	*/
	class WindowItem : WindowListItem
	{
		/* Will be null if the nodes haven't been created. This is distinct from being non-null but having a
		count of zero. */
		public List<Node> Nodes; 
		//which templates were used to create the item
		public TemplateMatch Template;
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
		
	/* (rough overview of inner workings, as of 2017-12-28)
	
		Instantiator instantiates one or more templates for a collection of items.
		
		The source data is managed by `ItemsWindowList` which deals with subscriptions, inner subscriptions on observables and patching the list (with identities). It creates a window over the data, using the `Offset` and` Limit` properties.
		
		The WindowItem structure is created prior to the instantiation of nodes. Nodes will be created later in the same frame, or spread across several frames if `Defer` is specified. This deferal 	also allows reusing nodes via `Reuse` and `Identity`. Changes to the active window are essentially queued up and resolved once per frame.
		
		Removed window items are first placed in the `_availableItems` list. When new nodes are created this list is checked first.  Nodes are reused while they are still rooted.  Unused nodes are cleared at the end of the frame, when they are removed from the parent element.
		
		The Instantiator has an internal list of templates (the children of the `Each` or `Instance`). The `TemplateSource`, `TemplateKey` and `MatchKey` properties control which templates are instantiated (note that `TemplateSource` introduces another source of templates, not just the internal list).
	*/
	
	/** Base class for behaviors that can instantiate templates from a source.

		This class can not be directly instantiated or inherited because its constructors are internal. Use one of the
		provided derived classes instead: @Each or @Instance.
	*/
	[UXContentMode("Template")]
	public partial class Instantiator: Behavior, Node.ISubtreeDataProvider, IDeferred,
		ItemsWindowList<WindowItem>.IListener
	{
		/** @hide */
		protected internal Instantiator(IList<Template> templates)
		{
			_templates = templates;
			_watcher = new ItemsWindowList<WindowItem>(this);
		}

		/** @hide */
		protected internal Instantiator()
		{
			_watcher = new ItemsWindowList<WindowItem>(this);
		}

		void OnTemplatesChanged(Template factory)
		{
			if (!IsRootingCompleted) return;
			RecreateTemplates();
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			_watcher.Rooted();
			
			if (_rootTemplates != null)
				_rootTemplates.Subscribe(OnTemplatesChanged, OnTemplatesChanged);
			_templateSource = _weakTemplateSource;
		}


		protected override void OnUnrooted()
		{
			_watcher.Unrooted();
			RemoveAvailableItems();

			if (_rootTemplates != null)
				_rootTemplates.Unsubscribe();
			_templateSource = null;
				
			_completedRemove = null;
			base.OnUnrooted();
		}

		BusyTask _busyTask;
		void ItemsWindowList<WindowItem>.IListener.SetValid()
		{
			if (Parent != null)
				BusyTask.SetBusy(Parent, ref _busyTask, BusyTaskActivity.None );
		}

		void ItemsWindowList<WindowItem>.IListener.SetFailed(string message)
		{
			if (Parent != null)
				BusyTask.SetBusy(Parent, ref _busyTask, BusyTaskActivity.Failed, message );
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
 		
		internal override Node GetLastNodeInGroup()
		{
			return GetLastNodeFromIndex(_watcher.WindowItemCount -1);
		}

		extern (UNO_TEST) static internal int InsertCount 
		{ 
			get { return ItemsWindowList<WindowItem>.InsertCount; } 
			set { ItemsWindowList<WindowItem>.InsertCount = value; }
		}
		
		IList<Template> _templates;
		RootableList<Template> _rootTemplates;
		
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
		
		/**
			Reuses existing nodes if the new objects match the old ones.
			
			This field is typically set implicity. It defaults to `None`. Use `IdentityKey` instead if you want to match based on a id field. 
			
			If you need to match on the observable value itself, set this to `Object`, otherwise it works like `IdentityKey`
			
			@see IdentityKey
		*/
		public InstanceIdentity Identity
		{
			get { return _watcher.Identity; }
			set { _watcher.Identity = value; }
		}
		
		/**
			If specified will reuse existing items if a new item is created that has the same id.
			
			The `IdentityKey` is a key into the provided objects. If the key is not found the item will not have an id, and will not be matched.
			
			Matched items keep the same Node instances that they had before. This makes it suitable for using in combination with `LayoutAnimation`. It also makes it possible to use `AddingAnimation` and `RemovingAnimation` with `Each`, as the Node lifetime will now follow the logical lifetime.
			
			This feature works in conjunction with `replaceAt` and `replaceAll` on Observable's.
			
			NOTE: This feature, if using animations, does not yet operate well in combination with `Reuse`. It may result in reuse of unintended items and/or unexpected animations.
			https://github.com/fuse-open/fuselibs/issues/175
		*/
		public string IdentityKey
		{
			get { return _watcher.IdentityKey; }
			set { _watcher.IdentityKey = value; }
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

			If specified together with `TemplateKey`, this instantiator will prefer to pick template from the
			specified `TemplateSource` that matches the `TemplateKey` property. If no match is found, it falls back
			to using the regular list of `Templates`.  Refer to `Defaults`.

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
			set 
			{ 
				_weakTemplateSource = value; 
				
				if (IsRootingCompleted)
				{
					_templateSource = _weakTemplateSource;
					RecreateTemplates();
				}
			}
		}
		//https://github.com/fuse-open/fuselibs/issues/135
		[WeakReference]
		ITemplateSource _weakTemplateSource;
		ITemplateSource _templateSource; //captured at rooting time
		
		string _templateKey = null;
		/** Specifies a template key that is used to look up in the @TemplateSource to find an override of the default
			`Templates` provided in this object.

			This property, along with the templates in the @TemplateSource, must be set prior to
			rooting to take effect.
		*/
		public string TemplateKey
		{
			get { return _templateKey; }
			set 
			{
				if (_templateKey != value)
				{
					_templateKey = value;
					RecreateTemplates();
				}
			}
		}
		
		internal int Offset
		{
			get { return _watcher.Offset; }
			set { _watcher.Offset = value; }
		}
		
		internal int Limit
		{
			get { return _watcher.Limit; }
			set { _watcher.Limit = value; }
		}
		
		internal bool HasLimit { get { return _watcher.HasLimit; } }
		
		/** @hide */
		protected object GetItems() { return _watcher.GetItems(); }
		/** @hide */
		protected void SetItems( object value ) { _watcher.SetItems(value); }
		/** Call to set the items during the OnRooted override (post base.OnRooted call)
			@hide */
		protected void SetItemsDerivedRooting( object value ) { _watcher.SetItemsDerivedRooting(value); }

		/* A placeholder item. A Data context is not provided for these items. */
		internal class NoContextItem { }
		
		string _matchKey;

		/** Name of the field on each data object which selects templates for the data objects.

			If set, the `Each` will instantiate the template with a name matching the `MatchKey`. If no
			match is found then the default template will be used, or no template if there is no default.
			The default template is the one explicitly marked with `ux:DefaultTemplate="true"`.

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
					RecreateTemplates();
				}
			}
		}
		
		string _match;
		/**
			The template which should be instantiated.
			
			Unset by default, meaning all templates will be instantiated (assuming MatchKey, and TemplateKey are also unset).
			
			If you intend on using a binding, or expression, for this value it is recommend to set `Defaults` as well. This avoids an momentary creation of the defaults while the binding has not yet resolved.
			
				<Instance Match="{type}" Defaults="None">
					<Panel ux:Template="side"/>
					<Panel ux:Template="fore"/>
				</Instance>

			`{type}` may resolve to an async JavaScript variable, meaning it won't produce an immediate value. This will result in `Match` not yet having a value, thus all templates would be instantiated by default. `Defaults="None"` prevents this behaviour.
		*/
		public string Match
		{
			get { return _match; }
			set
			{
				if (_match != value)
				{
					_match = value;
					RecreateTemplates();
				}
			}
		}
		
		InstanceDefaults _defaults = InstanceDefaults.Standard;
		/**
			Which templates are instantiating when nothing else matches.
			
			It is recommend to specified `Defaults="Default"` or `Defaults="None"` when using an expression, or binding, for the matching fields. This avoids an issue where the field may be momentarily unset, resulting in all templates being instantiated.
			
			The default is `Standard`: if none of `Match`, `MatchKey` or `TemplateKey` are specified the default will be created. If there is no explicitly marked default then all templates are instantiated.
			
			A default template is marked wtih `ux:DefaultTemplate="true"`
			
				<Each Items="{items}" MatchKey="{type}">
					<FrontCard ux:Template="front"/>
					<BackCard ux:Template="back"/>
					<DefaultCard ux:DefaultTemplate="true"/>
				</Each>
		*/
		public InstanceDefaults Defaults
		{
			get { return _defaults; }
			set 
			{
				if (_defaults != value)
				{
					_defaults = value;
					RecreateTemplates();
				}
			}
		}
		
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
		
		ContextDataResult ISubtreeDataProvider.TryGetDataProvider( Node n, DataType type, out object provider )
		{
			provider = null;
			
			WindowItem v;
			if (_dataMap.TryGetValue(n, out v))
			{
				//https://github.com/fusetools/fuselibs-private/issues/3312
				//`Count` does not introduce data items
				if (v.Data is NoContextItem)
					return ContextDataResult.Continue;
					
				provider = v.CurrentData;
				return type == DataType.Prime ? ContextDataResult.NullProvider : ContextDataResult.Continue;
			}

			return ContextDataResult.Continue;
		}
		
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
		
		
		TemplateMatch GetDataTemplate(object data)
		{
			//if there is no data then nothing should be instantiated
			if (data == null)
				return  new TemplateMatch{ All = false, Template = null };
			
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
				string key = Match ?? _watcher.GetDataKey(data, MatchKey) as string;
					
				//match Order in FindTemplate (latest is preferred)
				for (int i=Templates.Count-1; i>=0; --i) {
					var f = Templates[i];
					if (f.IsDefault) defaultTemplate = f;
					if (key != null && f.Key == key)
						useTemplate = f;
				}
			}

			// Priority 3 - Use the default template or all templates if no match specified
			if (useTemplate == null && Defaults != InstanceDefaults.None)
			{
				if (Defaults == InstanceDefaults.Default)
					useTemplate = defaultTemplate; //may still be null
				else if (MatchKey != null || Match != null || defaultTemplate != null)
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
		
		/** Finds a matching available item for returns. Returns `null` if none found. */
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

		/* Force a cleanup of all templates and cause the nodes to be recreated. */
		void RecreateTemplates()
		{
			for (int i = 0; i < _watcher.WindowItemCount; i++)
				CleanupWindowItem( _watcher.GetWindowItem(i) );
				
			for (int i = 0; i < _watcher.WindowItemCount; i++)
				PrepareWindowItem( i, _watcher.GetWindowItem(i) );
			
			ScheduleRemoveAvailableItems();
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
