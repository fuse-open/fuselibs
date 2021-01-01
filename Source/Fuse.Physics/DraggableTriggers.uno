using Uno;
using Uno.UX;
using Uno.Collections;
using Fuse.Elements;
using Fuse.Scripting;

namespace Fuse.Physics
{
	public class DraggableEventArgs : EventArgs, IScriptEvent
	{
		internal Body Body { get; private set; }
		internal float3 Position { get; private set; }
		public Visual Visual { get { return Body.Visual; } }

		internal DraggableEventArgs(Body body, float3 position)
		{
			Body = body;
			Position = position;
		}

		void IScriptEvent.Serialize(IEventSerializer s)
		{
			s.AddObject("position", Position);
		}
	}

	public delegate void DraggableEventHandler(object sender, DraggableEventArgs args);

	public abstract class DraggableEventTrigger: Fuse.Triggers.Trigger
	{
		public event DraggableEventHandler Handler;

		internal void OnTriggered(Body body, float3 position)
		{
			Pulse();

			if (Handler != null)
			{
				var args = new DraggableEventArgs(body, position);
				Handler(this, args);
			}
		}
	}

	/**
		a Trigger that pulse when drag has been started by Draggable Element
	*/
	public class DragStarted: DraggableEventTrigger
	{
	}

	/**
		a Trigger that pulse when drag has been ended by Draggable Element
	*/
	public class DragEnded: DraggableEventTrigger
	{
	}

	public class OverlapInfo
	{
		public Element OverlappedElement;
		public float OverlappedArea;

		public OverlapInfo()
		{
			OverlappedElement = null;
			OverlappedArea = Float.MinValue;
		}

		public OverlapInfo(Element element, float area)
		{
			OverlappedElement = element;
			OverlappedArea = area;
		}

	}

	public abstract class DraggableTrigger: Fuse.Triggers.WhileTrigger
	{
		public Draggable Draggable { get; set; }

		/** Target Element classname that is intersected by a draggable element */
		public string ToTargetUxClass { get; set; }

		/** Minimum cover area to consider if two Visual is overlapped. range in 0 - 1 */
		float _areaThreshold = Float.MinValue;
		public float AreaThreshold
		{
			get { return _areaThreshold; }
			set
			{
				if (_areaThreshold != value)
					_areaThreshold = value;
			}
		}

		bool _activated;
		new protected void SetActive(bool on)
		{
			if (!_activated && on)
			{
				base.SetActive(true);
				_activated = true;
			}
			if (_activated && !on)
			{
				base.SetActive(false);
				_activated = false;
			}
		}

		IList<Node> SearchNodeByTargetClass(Element source, string targetClass)
		{
			var current = source as Visual;
			var parent = source.Parent;
			while(parent != null)
			{
				current = parent;
				parent = parent.Parent;
			}
			IList<Node> resultNode = new List<Node>();
			SearchNodeByClassName(current.Children, targetClass, resultNode);
			return resultNode;
		}

		bool SearchNodeByClassName(IList<Node> nodes, string className, IList<Node> resultNodes)
		{
			if (nodes != null)
				foreach (var node in nodes)
				{
					var target = node as Element;
					if (target != null)
					{
						if (target.GetType().FullName == className)
							resultNodes.Add(target);
						if (SearchNodeByClassName(target.Children, className, resultNodes))
							return true;
					}
				}
			return false;
		}

		protected float CheckOverlap(Element source, Element target)
		{
			var overlapArea = Float.MinValue;
			var l1 = float2(source.WorldPosition.X, source.WorldPosition.Y);
			var r1 = l1 + source.ActualSize;
			var l2 = float2(target.WorldPosition.X, target.WorldPosition.Y);
			var r2 = l2 + target.ActualSize;

			// If one visual is on left side of other
			if (l1.X >= r2.X || l2.X >= r1.X)
			{
				return overlapArea;
			}

			// If one visual is above other
			if (r2.Y <= l1.Y || r1.Y <= l2.Y)
			{
				return overlapArea;
			}

			var area1 = Math.Abs(l1.X - r1.X) * Math.Abs(l1.Y - r1.Y);
			var area2 = Math.Abs(l2.X - r2.X) * Math.Abs(l2.Y - r2.Y);
			var areaI = (Math.Min(r1.X, r2.X) - Math.Max(l1.X, l2.X)) * (Math.Min(r1.Y, r2.Y) - Math.Max(l1.Y, l2.Y));

			overlapArea = (area1 >= area2) ? areaI /area2 : areaI / area1;
			return overlapArea;
		}

		IList<Element> FilteredTarget(Element source)
		{
			var maxX = source.WorldPosition.X;
			var maxY = source.WorldPosition.Y;
			IList<Element> nodes = new List<Element>();
			foreach (var target in _targetInstances)
			{
				var targetElement = target as Element;
				var targetX = targetElement.WorldPosition.X + targetElement.ActualSize.X;
				var targetY = targetElement.WorldPosition.Y + targetElement.ActualSize.Y;
				if (maxX < targetX && maxY < targetY)
					nodes.Add(targetElement);
			}
			return nodes;
		}

		protected OverlapInfo FindBestOverlaps(Element source)
		{
			var overlapInfo = new OverlapInfo();
			var filteredTarget = FilteredTarget(source);
			foreach (var target in filteredTarget)
			{
				var targetEle = target as Element;
				var currOverlapedArea = CheckOverlap(source, targetEle);
				if (currOverlapedArea > 0)
				{
					if (overlapInfo.OverlappedArea < currOverlapedArea)
					{
						overlapInfo.OverlappedElement = targetEle;
						overlapInfo.OverlappedArea = currOverlapedArea;
					}
				}
			}
			filteredTarget = null;
			return overlapInfo;
		}

		IList<Node> _targetInstances;
		protected IList<Node> TargetInstances
		{
			get { return _targetInstances; }
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			if (ToTargetUxClass != null)
				UpdateManager.AddDeferredAction(GetTargetClassInstances, LayoutPriority.Post);
		}

		protected override void OnUnrooted()
		{
			_targetInstances = null;
			base.OnUnrooted();
		}

		void GetTargetClassInstances()
		{
			_targetInstances = SearchNodeByTargetClass(Parent as Element, ToTargetUxClass);
		}
	}

	/**
		a Trigger that activate when Draggable Element is intersected with the `Target` element

		#Example:

		```
		<App>
			<JavaScript>
				var Observable = require("FuseJS/Observable");
				var dataToTransfer = new Observable("Data to transfer");
				module.exports = { dataToTransfer, dataReceived: function (args) { console.dir(args.data); } }
			</JavaScript>
			<ClientPanel>
				<Panel ux:Name="source" X="40" Y="80" Size="80">
					<Rectangle Layer="Background" Color="#afa" ux:Name="bg" />
					<Draggable />
					<Shadow Distance="0" Size="0" ux:Name="shadow" />
					<WhilePressed>
						<Scale Vector="1.2" Duration="0.2" />
						<Change shadow.Size="5" Duration="0.2" />
						<Change shadow.Distance="3" Duration="0.2" />
						<Change shadow.Color="#666" Duration="0.1" />
					</WhilePressed>
					<WhileDragging>
						<Change shadow.Size="10" Duration="0.1" />
						<Change shadow.Distance="6" Duration="0.1" />
						<Change shadow.Color="#333" Duration="0.1" />
					</WhileDragging>
					<WhileDraggingOver Target="dropPanel">
						<Change bg.Color="#0f0" />
						<Change bg.StrokeWidth="2" Duration="0.2" />
						<Change bg.StrokeColor="#f00" Duration="0.2" />
					</WhileDraggingOver>
					<Dropped To="dropPanel" Data="{dataToTransfer}">
						<Set source.Size="50" />
					</Dropped>
				</Panel>

				<Panel Size="80" X="80" Y="500" Color="#ccc" ux:Name="dropPanel">
					<WhileDroppingBy Source="source">
						<Change dropPanel.Color="#0ff" Duration="0.2" />
					</WhileDroppingBy>
					<Dropped By="source" Handler="{dataReceived}">
						<Scale Vector="1.2" Duration="0.2" />
					</Dropped>
				</Panel>
			</ClientPanel>
		</App>
		```

		@experimental
	*/
	public class WhileDraggingOver : DraggableTrigger, IPropertyListener
	{
		/** Target Element that is intersected by a draggable element */
		public Element Target { get; set; }

		protected override void OnRooted()
		{
			base.OnRooted();

			if (Draggable == null)
			{
				var v = Parent as Element;
				if (v != null)
					Draggable = v.FirstChild<Draggable>();
			}
			if (Draggable != null)
				Draggable.AddPropertyListener(this);
			else
			{
				Fuse.Diagnostics.UserError( "Could not find a Draggable", this );
				return;
			}

			if (Target == null && ToTargetUxClass == null)
			{
				Fuse.Diagnostics.UserError( "Target property or ToTargetUxClass property has not been set.", this );
				return;
			}
		}

		protected override void OnUnrooted()
		{
			if (Draggable != null)
			{
				Draggable.RemovePropertyListener(this);
				Draggable = null;
			}
			_lastOverlapedTarget = null;
			base.OnUnrooted();
		}

		void InActivateWhileDroppingBy(Element source, Element target)
		{
			if (source != null && target != null)
			{
				for (var v = target.FirstChild<WhileDroppingBy>(); v != null; v = v.NextSibling<WhileDroppingBy>())
				{
					if ((v.Source == source || source.GetType().FullName == v.SourceUxClass))
						v.SetActive(false);
				}
			}
		}

		void ChangeStateWhileDroppingBy(Element source, Element target, float overlapArea)
		{
			if (source != null && target != null)
			{
				for (var v = target.FirstChild<WhileDroppingBy>(); v != null; v = v.NextSibling<WhileDroppingBy>())
				{
					if ((v.Source == source || source.GetType().FullName == v.SourceUxClass) && overlapArea > v.AreaThreshold)
						v.SetActive(true);
					else
						v.SetActive(false);
				}
			}
		}

		Element _lastOverlapedTarget;
		void IPropertyListener.OnPropertyChanged(PropertyObject obj, Selector prop)
		{
			if (obj == Draggable && prop.Equals("Translation"))
			{
				var source = Parent as Element;
				if (ToTargetUxClass != null)
				{
					var overlapedTarget = FindBestOverlaps(source);
					if (overlapedTarget.OverlappedElement != null)
					{
						if (overlapedTarget.OverlappedArea > AreaThreshold)
							SetActive(true);
						else
							SetActive(false);

						ChangeStateWhileDroppingBy(source, overlapedTarget.OverlappedElement, overlapedTarget.OverlappedArea);
					}
					else
					{
						SetActive(false);
					}
					if (overlapedTarget.OverlappedElement != _lastOverlapedTarget)
					{
						InActivateWhileDroppingBy(source, _lastOverlapedTarget);
						_lastOverlapedTarget = overlapedTarget.OverlappedElement;
					}
				}
				else
				{
					var overlapped = CheckOverlap(source, Target);
					if (overlapped > AreaThreshold)
						SetActive(true);
					else
						SetActive(false);

					ChangeStateWhileDroppingBy(source, Target, overlapped);
				}
			}
		}
	}

	/**
		a Trigger that activate when the element that has `WhileDroppedBy` trigger is intersected with `Source` element (Draggable Element)

		#Example:

		```
		<App>
			<JavaScript>
				var Observable = require("FuseJS/Observable");
				var dataToTransfer = new Observable("Data to transfer");
				module.exports = { dataToTransfer, dataReceived: function (args) { console.dir(args.data); } }
			</JavaScript>
			<ClientPanel>
				<Panel ux:Name="source" X="40" Y="80" Size="80">
					<Rectangle Layer="Background" Color="#afa" ux:Name="bg" />
					<Draggable />
					<Shadow Distance="0" Size="0" ux:Name="shadow" />
					<WhilePressed>
						<Scale Vector="1.2" Duration="0.2" />
						<Change shadow.Size="5" Duration="0.2" />
						<Change shadow.Distance="3" Duration="0.2" />
						<Change shadow.Color="#666" Duration="0.1" />
					</WhilePressed>
					<WhileDragging>
						<Change shadow.Size="10" Duration="0.1" />
						<Change shadow.Distance="6" Duration="0.1" />
						<Change shadow.Color="#333" Duration="0.1" />
					</WhileDragging>
					<WhileDraggingOver Target="dropPanel">
						<Change bg.Color="#0f0" />
						<Change bg.StrokeWidth="2" Duration="0.2" />
						<Change bg.StrokeColor="#f00" Duration="0.2" />
					</WhileDraggingOver>
					<Dropped To="dropPanel" Data="{dataToTransfer}">
						<Set source.Size="50" />
					</Dropped>
				</Panel>

				<Panel Size="80" X="80" Y="500" Color="#ccc" ux:Name="dropPanel">
					<WhileDroppingBy Source="source">
						<Change dropPanel.Color="#0ff" Duration="0.2" />
					</WhileDroppingBy>
					<Dropped By="source" Handler="{dataReceived}">
						<Scale Vector="1.2" Duration="0.2" />
					</Dropped>
				</Panel>
			</ClientPanel>
		</App>

		@experimental
	*/
	public class WhileDroppingBy : DraggableTrigger
	{
		/** Source element is an element that has draggable behavior on which intersect with the element that has `WhileDroppingBy` trigger */
		public Element Source { get; set; }

		/** Source element classname that has draggable behavior on which intersect with the element that has `WhileDroppingBy` trigger  */
		public string SourceUxClass { get; set; }

		protected override void OnRooted()
		{
			base.OnRooted();
			if (Source == null && SourceUxClass == null)
			{
				Fuse.Diagnostics.UserError( "Source property or SourceUxClass property has not been set.", this );
				return;
			}
		}
	}

	public class DroppableEventArgs : EventArgs, IScriptEvent
	{
		internal object Data { get; private set; }
		public Visual Visual { get; private set; }

		internal DroppableEventArgs(Visual visual, object data)
		{
			Visual = visual;
			Data = data;
		}

		void IScriptEvent.Serialize(IEventSerializer s)
		{
			s.AddObject("data", Data);
		}
	}

	public delegate void DroppableEventHandler(object sender, DroppableEventArgs args);

	public enum DataTransferMode
	{
		Copy,
		Move
	}

	public enum TargetMissAction
	{
		Stay,
		Return
	}

	/**
		a Trigger that pulse when draggable element has been dropped to the target or target element has received draggable element

		@experimental
	*/
	public class Dropped: DraggableTrigger
	{
		/** Target visual that will be dropped by this `Dropped` trigger */
		public Element To { get; set; }

		/** a `Draggable` visual that will be dropped to an element that has a `Dropped` trigger */
		public Element By { get; set; }

		/** a `Draggable` visual classname that will be dropped to an element that has a `Dropped` trigger */
		public string ByUxClass { get; set; }

		/** Data that can be transferred to the element when drag n drop activity has been finished  */
		object _data;
		[UXOriginSetter("SetData")]
		public object Data
		{
			get { return _data; }
			set { SetData(value, null); }
		}

		static Selector _dataName = "Data";
		public void SetData(object value, IPropertyListener origin)
		{
			if (_data != value)
			{
				_data = value;
				OnPropertyChanged(_dataName);
			}
		}

		/** Transfer mode of the data that has been sent.   */
		DataTransferMode _mode = DataTransferMode.Copy;
		public DataTransferMode DataTranferMode
		{
			get { return _mode; }
			set
			{
				if (_mode != value)
					_mode = value;
			}
		}

		TargetMissAction _missAction = TargetMissAction.Stay;
		public TargetMissAction TargetMissAction
		{
			get { return _missAction; }
			set
			{
				if (_missAction != value)
					_missAction = value;
			}
		}

		/** Called when data has been received when drag n drop activity has been finished */
		public event DroppableEventHandler Handler;

		void DroppedAction(Element source, Element to)
		{
			Pulse();
			for (var dropped = to.FirstChild<Dropped>(); dropped != null; dropped = dropped.NextSibling<Dropped>())
			{
				if (dropped.By == source || dropped.ByUxClass == source.GetType().FullName)
				{
					dropped.Pulse();
					dropped.Data = Data;
					if (dropped.Handler != null)
					{
						var args = new DroppableEventArgs(source, Data);
						dropped.Handler(this, args);
						if (DataTranferMode == DataTransferMode.Move)
							Data = null;
					}
				}
			}
		}

		internal void OnTriggered(Body body, float3 position)
		{
			var source = Parent as Element;
			if (ToTargetUxClass != null)
			{
				var target = FindBestOverlaps(source);
				if (target.OverlappedElement != null)
					DroppedAction(source, target.OverlappedElement);
			}
			else if (To != null && CheckOverlap(source, To) > 0)
			{
				DroppedAction(source, To);
			}
			else
			{
				if (TargetMissAction == TargetMissAction.Return)
				{
					if (Draggable != null)
						Draggable.Translation = float2(0,0);
				}
			}
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			if (To == null && ToTargetUxClass == null && By == null && ByUxClass == null)
			{
				Fuse.Diagnostics.UserError( "To property or By property has not been set.", this );
				return;
			}
			if (Draggable == null)
			{
				var v = Parent as Element;
				if (v != null)
				{
					Draggable = v.FirstChild<Draggable>();
				}
			}
		}

		protected override void OnUnrooted()
		{
			Handler = null;
			Draggable = null;
			base.OnUnrooted();
		}
	}

}