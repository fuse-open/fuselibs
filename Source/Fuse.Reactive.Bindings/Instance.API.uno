using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse.Internal;

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
		/** The `ObjectId` is used to compare objects. This is set implicitly if `ObjectId` is set. */
		FieldId,
		/** Use the object itself as the matching key. Suitable for when the object is a plain string or number. */
		Object,
	}
	
	/* The protected and public API of the instantiator. */
	public partial class Instantiator
	{
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
		
		InstanceObjectMatch _objectMatch = InstanceObjectMatch.None;
		/**
			Reuses existing nodes if the new objects match the old ones.
			
			This field is typically set implicity. It defaults to `None`. Use `ObjectId` instead if you want to match based on a id field. 
			
			If you need to match on the observable value itself, set this to `Object`, otherwise it works like `ObjectId`
			
			@see MatchId
		*/
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
		
		bool IsListeningItems { get { return _itemsSubscription != null; } }
		
		protected internal void OnItemsChanged()
		{
			if (!IsRootingStarted) return;

			RemoveAll();

			var obs = _items as IObservable;
			if (obs != null)
			{
				if (_itemsSubscription != null) _itemsSubscription.Dispose();
				_itemsSubscription = obs.Subscribe(this);
			}
			else
			{
				Repopulate();
			}
		}
		
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
					OnItemsChanged();
				}
			}
		}
	}
}