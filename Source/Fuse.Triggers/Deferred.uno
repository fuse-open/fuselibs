using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Diagnostics;

using Fuse.Triggers;

namespace Fuse
{
	interface IDeferred
	{
		/** 
			Should perform an iteration of the deferred action. This may be the full action, or a part of it if division is possible.
			
			@return true to indicate the action is complete. false indicates there is more to be done and it should be added back into the priority queue.
		*/
		bool Perform();
	}
	
	static class DeferredManager
	{
		static PriorityQueue<IDeferred> _pending = new PriorityQueue<IDeferred>();

		/**
			The priority is specified as follows:
				priority[0] - the primary ordering, chosen by the user in a property
				priority[1] - the NodeDepth, to allow deeper nodes to initialize first
		*/
		static public void AddPending(IDeferred d, float2 priority = float2(0))
		{
			_pending.Add(d, priority);
			CheckUpdate();
		}
		
		static public void RemovePending(IDeferred d)
		{
			_pending.Remove(d);
			CheckUpdate();
		}
		
		static int _startFrame;
		static bool _update;
		static void CheckUpdate()
		{
			var needUpdate = _pending.Count > 0;
			if (needUpdate == _update)
				return;
				
			_update = needUpdate;
			if (_update)
			{
				UpdateManager.AddAction(OnUpdate);
				_startFrame = UpdateManager.FrameIndex + 1;
			}
			else
			{
				UpdateManager.RemoveAction(OnUpdate);
			}
		}
		
		static double TimeLimit = 0.002;
		
		static internal double TestTimeLimit
		{
			get { return TimeLimit; }
			set { TimeLimit = value; }
		}
		
		static void OnUpdate()
		{
			if (UpdateManager.FrameIndex < _startFrame)
				return;
			
			var startTime = Clock.GetSeconds(); 
			while (!_pending.Empty)
			{
				float4 prio;
				var r = _pending.PopTop(out prio);
				if (!r.Perform())
					_pending.Add(r, prio);
				
				var elapsed = Clock.GetSeconds() - startTime;
				if (elapsed > TimeLimit)
					break;
			}
			
			CheckUpdate();
		}
		
		static internal bool HasPending
		{
			get { return !_pending.Empty; }
		}
	}

	internal static class TestDeferredManager
	{
		static public bool HasPending
		{
			get { return DeferredManager.HasPending; }
		}
	}
	
	[UXContentMode("Template")]
	/**
		Defers the creation of nodes to improve initialization time.
		
		`Deferred` says that the content is not required immediately and may be created somewhat later. This allows the app to startup faster, or to create new pages faster. Without `Deferred` the nodes are initialized all in the same frame, which can lead to delays. With `Deferred` the node creation is staggered over several frames. This allows the app to start rendering and displaying prior to being completely initialized.
		
		A common use is with an @Each:
		
			<Each Items="{items}">
				<Deferred>
					<StackPanel Orientation="Horizontal">
						<Text Value="{name}"/>
						<Text Value="{address}"/>
						<Text Value="{phone}"/>
					</StackPanel>
				</Deferred>
			</Each>
			

		Note that the delay is measured in frames: deferred content will still be added quickly. Nonetheless it may result in some popping of the new elements and a change in layout.

		You only need to use this feature when you are having initializaiton time problems at startup or on new pages. Wrapping the content of @Each in `Deferred` is a simple change that can help when you are using lists of items. The individual pages of a top-level @PageControl may also be suitable for `Deferred`.

		Do not use this on the pages of a @Navigator or other control that accepts templates. Templates are already created on demand and wrapping them in `Deferred` usually won't be helpful.			
	*/
	public class Deferred : Behavior, IDeferred
	{
		IList<Template> _templates;
		
		[UXPrimary]
		public IList<Template> Templates
		{
			get 
			{
				if (_templates == null)
					_templates = new List<Template>();
				return _templates;
			}
		}

		float _priority = 0;
		/**
			Higher priority `Deferred` nodes are created first. Higher number means higher priority.
			
			Items are also ordering by an implicit priority based on the depth in the tree. Deeper nodes have a higher priority. This allows full sub-trees to initialized before moving on to siblings. The `Priority` property is more significant than the depth priority.
		*/
		public float Priority
		{
			get { return _priority; }
			set { _priority = value; }
		}
		
		BusyTask _busyTask;
		protected override void OnRooted()
		{
			base.OnRooted();
			DeferredManager.AddPending(this, float2(Priority,NodeDepth) );
			BusyTask.SetBusy(Parent, ref _busyTask, BusyTaskActivity.Deferring);
		}
		
		protected override void OnUnrooted()
		{
			//in case it is still pending
			DeferredManager.RemovePending(this);
			BusyTask.SetBusy(Parent, ref _busyTask, BusyTaskActivity.None);
			
			if (_added != null)
			{
				for (int i=0; i < _added.Count; ++i)
					Parent.Children.Remove(_added[i]);
				_added = null;
			}
			base.OnUnrooted();
		}

		List<Node> _added;
		bool IDeferred.Perform()
		{
			if (_added != null)
				Fuse.Diagnostics.InternalError( "Duplicate call to Deferred.Perform", this );
				
			_added = new List<Node>();
			for (int i=0; i < Templates.Count; ++i)
			{
				var elm = Templates[i].New() as Node;
				elm.OverrideContextParent = this;
				_added.Add(elm);
			}
			
			Parent.InsertNodesAfter(this, _added.GetEnumerator());
			
			BusyTask.SetBusy(Parent, ref _busyTask, BusyTaskActivity.None);
			return true;
		}
		
		internal override Node GetLastNodeInGroup()
		{
			if (_added == null || _added.Count == 0)
				return this;
			return _added[_added.Count-1];
		}
	}
}