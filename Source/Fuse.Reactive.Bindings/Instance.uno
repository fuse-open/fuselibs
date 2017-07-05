using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse.Triggers;

namespace Fuse.Reactive
{
	[UXContentMode("Template")]
	/** Base class for behaviors that can instantiate templates from a source.

		This class can not be directly instantiated or inherited because its constructors are internal. Use one of the
		provided derived classes instead: @Each or @Instance.
	*/
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
			OnItemsChanged();
			
			if (_rootTemplates != null)
				_rootTemplates.Subscribe(OnTemplatesChanged, OnTemplatesChanged);
			_templateSource = _weakTemplateSource;
		}

		IDisposable _itemsSubscription;

		protected override void OnUnrooted()
		{
			if (_itemsSubscription != null)
			{
				_itemsSubscription.Dispose();
				_itemsSubscription = null;
			}

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
			
			WindowItem wi;
			if (_dataMap.TryGetValue(n, out wi))
			{
				if (!wi.Nodes.Remove(n))
					Fuse.Diagnostics.InternalError( "inconsistent Nodes list state", this );
					
				_dataMap.Remove(n);
				
				if (wi.Nodes.Count == 0)
					wi.Dispose();
			}
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