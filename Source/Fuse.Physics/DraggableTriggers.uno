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

	public abstract class DraggableTrigger: Fuse.Triggers.WhileTrigger
	{
		public Draggable Draggable { get; set; }

		/** Target Element classname that is intersected by a draggable element */
		public string ToTargetClass { get; set; }

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
			IList<Node> resultNode = new List<Node>();
			while(parent != null)
			{
				current = parent;
				parent = parent.Parent;
			}
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

		protected bool IsOverlap(Element source, Element target)
		{
			var area = 0.0f;
			return IsOverlap(source, target, out area);
		}

		protected bool IsOverlap(Element source, Element target, out float overlapArea)
		{
			overlapArea = 0.0f;
			var l1 = float2(source.WorldPosition.X, source.WorldPosition.Y);
			var r1 = l1 + source.ActualSize;
			var l2 = float2(target.WorldPosition.X, target.WorldPosition.Y);
			var r2 = l2 + target.ActualSize;

			// If one visual is on left side of other
			if (l1.X >= r2.X || l2.X >= r1.X)
			{
				return false;
			}

			// If one visual is above other
			if (r2.Y <= l1.Y || r1.Y <= l2.Y)
			{
				return false;
			}

			var area1 = Math.Abs(l1.X - r1.X) * Math.Abs(l1.Y - r1.Y);
			var area2 = Math.Abs(l2.X - r2.X) * Math.Abs(l2.Y - r2.Y);
			var areaI = (Math.Min(r1.X, r2.X) - Math.Max(l1.X, l2.X)) * (Math.Min(r1.Y, r2.Y) - Math.Max(l1.Y, l2.Y));

			overlapArea = area1 + area2 - areaI;

			return true;
		}

		protected Element FindOverlaps()
		{
			var source = Parent as Element;
			var currOverlapedArea = Float.MaxValue;
			Element targetElement = null;
			var nextOverlap = true;
			foreach (var target in _targetInstances)
			{
				float overlapArea;
				var targetEle = target as Element;
				if (IsOverlap(source, targetEle, out overlapArea))
				{
					if (currOverlapedArea > overlapArea)
					{
						currOverlapedArea = overlapArea;
						targetElement = targetEle;
					}
					nextOverlap = true;
				}
				else
					nextOverlap = false;
				if (!nextOverlap && targetElement != null)
					break;
			}
			return targetElement;
		}

		IList<Node> _targetInstances;
		protected IList<Node> TargetInstances
		{
			get { return _targetInstances; }
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			if (ToTargetClass != null)
				UpdateManager.AddDeferredAction(GetTargetClassInstances, LayoutPriority.Post);
		}

		protected override void OnUnrooted()
		{
			_targetInstances = null;
			base.OnUnrooted();
		}

		void GetTargetClassInstances()
		{
			_targetInstances = SearchNodeByTargetClass(Parent as Element, ToTargetClass);
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

			if (Target == null && ToTargetClass == null)
			{
				Fuse.Diagnostics.UserError( "Target property or ToTargetClass property has not been set.", this );
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

		void SetWhileDroppingByActive(Element source, Element target, bool on)
		{
			if (source != null && target != null)
			{
				for (var v = target.FirstChild<WhileDroppingBy>(); v != null; v = v.NextSibling<WhileDroppingBy>())
				{
					if (v.Source == source || source.GetType().FullName == v.SourceClass)
						v.SetActive(on);
				}
			}
		}

		Element _lastOverlapedTarget;
		void IPropertyListener.OnPropertyChanged(PropertyObject obj, Selector prop)
		{
			if (obj == Draggable && prop.Equals("Translation"))
			{
				var source = Parent as Element;
				if (ToTargetClass != null)
				{
					var overlapedTarget = FindOverlaps();
					if (overlapedTarget != null)
					{
						SetActive(true);
						SetWhileDroppingByActive(source, overlapedTarget, true);
						if (_lastOverlapedTarget != overlapedTarget)
						{
							SetWhileDroppingByActive(source, _lastOverlapedTarget, false);
							_lastOverlapedTarget = overlapedTarget;
						}
					}
					else
					{
						SetActive(false);
						foreach (var target in TargetInstances)
							SetWhileDroppingByActive(source, target as Element, false);
					}
				}
				else
				{
					if (IsOverlap(source, Target))
					{
						SetActive(true);
						SetWhileDroppingByActive(source, Target, true);
					}
					else
					{
						SetActive(false);
						SetWhileDroppingByActive(source, Target, false);
					}
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
	*/
	public class WhileDroppingBy : DraggableTrigger
	{
		/** Source element is an element that has draggable behavior on which intersect with the element that has `WhileDroppingBy` trigger */
		public Element Source { get; set; }

		/** Source element classname that has draggable behavior on which intersect with the element that has `WhileDroppingBy` trigger  */
		public string SourceClass { get; set; }

		protected override void OnRooted()
		{
			base.OnRooted();
			if (Source == null && SourceClass == null)
			{
				Fuse.Diagnostics.UserError( "Source property or SourceClass property has not been set.", this );
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
	*/
	public class Dropped: DraggableTrigger
	{
		/** Target visual that will be dropped by this `Dropped` trigger */
		public Element To { get; set; }

		/** a `Draggable` visual that will be dropped to an element that has a `Dropped` trigger */
		public Element By { get; set; }

		/** a `Draggable` visual classname that will be dropped to an element that has a `Dropped` trigger */
		public string ByClass { get; set; }

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
				if (dropped.By == source || dropped.ByClass == source.GetType().FullName)
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
			if (ToTargetClass != null)
			{
				var target = FindOverlaps();
				if (target != null)
					DroppedAction(source, target);
			}
			else if (To != null && IsOverlap(source, To))
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
			if (To == null && ToTargetClass == null && By == null && ByClass == null)
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