using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse.Triggers;

namespace Fuse.Reactive
{
	/* (rough overview of inner workings, as of 2017-07-10)
	
		Instantiator instantiates one or more templates for a collection of items.
		
		## Source data and active window
		
		The source data of the items is either `Items` or `Count`. `Items` will introduce each item as the data
		context for the added nodes. If this in turn is an obsevable it will be subscribed vai `ObserverLink`
		and the resulting data set as the context.
		
		`Offset` and `Limit` create a window on the items -- this specifies a range within the source data
		for which items should currently be instantiated. "Active" items are those in this range. The 
		`Instance.WindowItems.uno` source groups together logic dealing with these items.
		The _windowItems collection store only items which are in this range. The logic of the rest of code
		works on this assumption. 
		
		There is no reference to source data outside of the active window. An exception is data that lingers as 
		the context data for deleted items.
		
		`Instance.Observer` updates the list of windowItems as changes are made.
		
		
		## Deferred / Reuse / Cache
		
		The WindowItem structure is created prior to the instantiation of nodes. This is deferred until 
		later in the same frame, or spread across several frames if `Defer` is specified. This deferal
		also allows reusing nodes via `Reuse` and `Identity`. Changes to the active window are essentially
		queued up and resolved once per frame.
		
		If using an `Identity` the `replaceAll` function will additionally use a patching function to
		improve insertions and removals. This helps preserve the order of children to produce
		satisfying visuals with Adding/RemovingAnimation.
		
		Removed window items are first placed in the `_availableItems` list. When new nodes are created
		this list is checked first.  Note the `WindowItem` itself is not reused, only the referenced nodes.
		Nodes are reused while they are still rooted.  Unused nodes are cleared at the end of the frame,
		when they are removed from the parent element.
		
		
		## Template selection
		
		The Instantiator has an internal list of templates (the children of the `Each` or `Instance`). The
		`TemplateSource`, `TemplateKey` and `MatchKey` properties control which templates are
		instantiated (note that `TemplateSource` introduces another source of templates, not just the
		internal list).
		
		Refer to `TemplateMatch` and `GetDataTemplate` to see which templates are instantiated.
		
	*/
	
	/** Base class for behaviors that can instantiate templates from a source.

		This class can not be directly instantiated or inherited because its constructors are internal. Use one of the
		provided derived classes instead: @Each or @Instance.
	*/
	[UXContentMode("Template")]
	public partial class Instantiator: Behavior, IObserver, Node.ISubtreeDataProvider, IDeferred
	{
		protected internal Instantiator(IList<Template> templates)
		{
			_templates = templates;
		}

		protected internal Instantiator()
		{
		}

		void OnTemplatesChanged(Template factory)
		{
			if (!IsRootingCompleted) return;
			Repopulate();
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			RefreshItems();
			
			if (_rootTemplates != null)
				_rootTemplates.Subscribe(OnTemplatesChanged, OnTemplatesChanged);
			_templateSource = _weakTemplateSource;
		}

		IDisposable _itemsSubscription;
		void DisposeItemsSubscription()
		{
			_isListeningItems = false;
			if (_itemsSubscription != null)
			{
				_isListeningItems = false;
				_itemsSubscription.Dispose();
				_itemsSubscription = null;
			}
		}
		bool _isListeningItems;
		bool IsListeningItems { get { return _isListeningItems; } }
		void StartListeningItems()
		{
			_isListeningItems = true;
		}

		protected override void OnUnrooted()
		{
			DisposeItemsSubscription();

			RemoveAll();
			RemovePendingAvailableItems();

			if (_rootTemplates != null)
				_rootTemplates.Unsubscribe();
			_templateSource = null;
				
			_completedRemove = null;
			base.OnUnrooted();
		}
		
		int CalcOffsetLimitCountOf( int length )
		{
			var q = Math.Max( 0, length - Offset );
			return HasLimit ? Math.Min( Limit, q ) : q;
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
			return GetLastNodeFromIndex(_windowItems.Count -1);
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
