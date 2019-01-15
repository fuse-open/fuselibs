using Uno;
using Uno.UX;
using Fuse.Animations;
using Fuse.Elements;

namespace Fuse.Triggers
{
	public class LayoutTransitionedArgs : VisualEventArgs
	{
		public LayoutTransitionedArgs(Visual node) 
			: base(node)
		{}
	}
	public delegate void LayoutTransitionedHandler(object sender, LayoutTransitionedArgs args);
	sealed class LayoutTransitioned : VisualEvent<LayoutTransitionedHandler, LayoutTransitionedArgs>
	{
		protected override void Invoke(LayoutTransitionedHandler handler, object sender,
			LayoutTransitionedArgs args)
		{
			handler(sender, args);
		}
	}

	static public class LayoutTransition
	{
		static LayoutTransitioned _transitioned = new LayoutTransitioned();
		public static VisualEvent<LayoutTransitionedHandler, LayoutTransitionedArgs>
			Transitioned { get { return _transitioned; } }
			
		class WorldPositionChangeMode: ITranslationMode
		{
			public float3 GetAbsVector(Translation t)
			{
				return GetWorldPositionChange(t.RelativeNode) * t.Vector;
			}
			//results are fixed
			public object Subscribe(ITransformRelative transform) { return null; } 
			public void Unsubscribe(ITransformRelative transform, object sub) { }
		}

		[UXGlobalResource("LayoutChange")]  //TODO: remove this, deprecated
		public static readonly ITranslationMode PositionLayoutChange = new WorldPositionChangeMode();
		[UXGlobalResource("WorldPositionChange")]
		public static readonly ITranslationMode WorldPositionChange = new WorldPositionChangeMode();
		static PropertyHandle _worldPositionChange = new PropertyHandle();

		internal static float3 GetWorldPositionChange(Node n)
		{
			var v = n.Properties.Get(_worldPositionChange);
			if (v != null) return (float3)v;
			else return float3(0);
		}

		internal static void SetWorldPositionChange(Node n, float3 change)
		{
			n.Properties.Set(_worldPositionChange, change);
		}

		class PositionChangeMode: ITranslationMode
		{
			public float3 GetAbsVector(Translation t)
			{
				float2 oldPos, newPos;
				if (!GetPositionChange(t.RelativeNode, out oldPos, out newPos))
					return float3(0);
				return float3(oldPos - newPos,0) * t.Vector;
			}
			//results are fixed
			public object Subscribe(ITransformRelative transform) { return null; }
			public void Unsubscribe(ITransformRelative transform, object sub)  { }
		}

		[UXGlobalResource("PositionChange")]
		public static readonly ITranslationMode PositionChange = new PositionChangeMode();
		static PropertyHandle _positionChange = new PropertyHandle();

		internal static bool GetPositionChange(Node n, out float2 oldPos, out float2 newPos)
		{
			var v = n.Properties.Get(_positionChange);
			float4 f = v == null ? float4(0) : (float4)v;
			oldPos = f.XY;
			newPos = f.ZW;

			return v != null;
		}

		internal static void SetPositionChange(Visual n, float2 oldPos, float2 newPos)
		{
			n.Properties.Set(_positionChange, float4(oldPos, newPos));
		}


		class ResizeChangeMode: IResizeMode
		{
			public bool GetSizeChange(Visual n, Visual relative, out float2 baseSize, out float2 deltaSize)
			{
				float2 oldSize, newSize;
				var b = LayoutTransition.GetSizeChange(n, out oldSize, out newSize);
				deltaSize = oldSize - newSize;
				baseSize = newSize;
				return b;
			}
			
			//TODO: public TransformModeFlags Flags { get { return TransformModeFlags.None; } }
		}

		class ScaleChangeMode : IScalingMode
		{
			public float3 GetScaleVector(Scaling v)
			{
				float2 oldSize, newSize;
				var b = LayoutTransition.GetSizeChange(v.RelativeNode, out oldSize, out newSize);
				const float zeroTolerance = 1e-05f;
				if (!b || newSize.Y < zeroTolerance || newSize.X < zeroTolerance )
					return v.Vector;

				var n = oldSize / newSize;
				return float3(n,1) * v.Vector;
			}
			
			//fixed results...?
			public object Subscribe(ITransformRelative transform) { return null; } 
			public void Unsubscribe(ITransformRelative transform, object sub) { }
		}

		[UXGlobalResource("LayoutChange")]  //TODO: remove this one, deprecated
		public static readonly IResizeMode SizeLayoutChange = new ResizeChangeMode();
		[UXGlobalResource("SizeChange")]
		public static readonly IResizeMode ResizeSizeChange = new ResizeChangeMode();
		[UXGlobalResource("SizeChange")]
		public static readonly IScalingMode ScalingSizeChange = new ScaleChangeMode();

		static PropertyHandle _sizeChange = Properties.CreateHandle();

		internal static void SetSizeChange(Node n, float2 oldSize, float2 newSize)
		{
			n.Properties.Set(_sizeChange, float4(oldSize, newSize));
		}

		internal static bool GetSizeChange(Node n, out float2 oldSize, out float2 newSize)
		{
			object res = null;
			if (n != null && n.Properties.TryGet(_sizeChange, out res))
			{
				var f = (float4)res;
				oldSize = f.XY;
				newSize = f.ZW;
				return true;
			}
			else
			{
				oldSize = float2(0);
				newSize = float2(0);
				return false;
			}
		}
	}
	
	public enum LayoutAnimationType
	{
		Implicit = 1<<0,
		Explicit = 1<<1,
		Both = Implicit | Explicit,
	}

	/**
		Triggers when the layout of an element changes

		When an Element has certain properties like Width, Height or Margin
		(collectively reffered to as "layout properties") changed or when its
		location in the visual tree changes, we can trigger a `LayoutAnimation`.

		Calculating layout for a large UX-document can be quite costly. When
		animating layout properties with Change animators, we run the risk of
		forcing a new layout to be calculated each frame. This can very easily
		lead to frame drops.

		The `LayoutAnimation` trigger can be used to make this more pleasant.
		For example, instead of animating the Width of an Element using Change,
		we can use Set and react to this change using a LayoutAnimation. Inside
		LayoutAnimation we specify how our element should move/resize from its
		previous position to its new position.

		## Example

		This example shows three rectangles, a teal, a red and a blue one. If
		the red or blue rectangle is clucked, the Width and Alignment
		properties of the teal rectangle gets smoothly animated.

			<StackPanel>
				<Rectangle ux:Name="panel" Width="100" Height="100" CornerRadius="5" Color="Teal" Alignment="Center">
					<LayoutAnimation>
						<Resize X="1" Y="1" RelativeTo="SizeChange" Duration="0.25"/>
						<Move X="1" Y="1" RelativeTo="PositionChange" Duration="0.25"/>
					</LayoutAnimation>
				</Rectangle>
				<Rectangle Color="Red" CornerRadius="5" Width="100" Height="50">
					<Clicked>
						<Set panel.Alignment="Left"/>
						<Set panel.Width="200"/>
					</Clicked>
				</Rectangle>
				<Rectangle Color="Blue" CornerRadius="5" Width="100" Height="50">
					<Clicked>
						<Set panel.Alignment="Right"/>
						<Set panel.Width="50"/>
					</Clicked>
				</Rectangle>
			</StackPanel>
	*/
	public class LayoutAnimation: Trigger
	{
		LayoutAnimationType _type = LayoutAnimationType.Both;
		public LayoutAnimationType Type
		{
			get { return _type; }
			set { _type = value; }
		}
		
		Element _element;
		protected override void OnRooted()
		{
			base.OnRooted();
			_element = Parent as Element;
			if (_element == null)
			{
				Fuse.Diagnostics.UserError( "LayoutAnimation can only be used on an Element", this);
				return;
			}

			_element.Placed += OnPlaced;
			_element.Preplacement += OnPreplacement;
			_element.ignoreTempArrange = true;
			LayoutTransition.Transitioned.AddHandler(_element, OnTransitioned);
		}

		protected override void OnUnrooted()
		{
			if (_element != null)
			{
				_element.ignoreTempArrange = false;
				_element.Placed -= OnPlaced;
				_element.Preplacement -= OnPreplacement;
				LayoutTransition.Transitioned.RemoveHandler(_element, OnTransitioned);
			}
			base.OnUnrooted();
		}

		int _hasOld, _frameTrans;
		float4x4 _oldWorld, _oldLocal;
		float2 _oldPosition;
		float2 _oldSize;
		Visual _oldParent;

		void OnPreplacement(object sender, PreplacementArgs args)
		{
			if (!Type.HasFlag(LayoutAnimationType.Implicit))
				return;
				
			//track only one change per frame
			if (_hasOld == UpdateManager.FrameIndex)
				return;

			if (!args.HasPrev)
				return;
			
			_hasOld = UpdateManager.FrameIndex;

			_oldWorld = _element.WorldTransform;
			_oldPosition = _element.ActualPosition;
			_oldSize = _element.ActualSize;
			_oldParent = _element.Parent;
			_oldLocal = _element.LocalTransform;
		}

		void OnPlaced(object sender, PlacedArgs args)
		{
			if (!Type.HasFlag(LayoutAnimationType.Implicit))
				return;
				
			if (_hasOld != UpdateManager.FrameIndex)
				return;
			//explicit transitions have precedence
			if (_frameTrans == UpdateManager.FrameIndex)
				return;

			//this assumes the local transform only includes the new position and an existing LayoutAnimation
			float2 oldPosition = _oldLocal.M41M42;
			float2 oldSize = _oldSize;

			var m = Matrix.Mul( _oldWorld, _element.Parent.WorldTransformInverse );
			float3 worldChange = m.M41M42M43 - float3(_element.IntendedPosition,0);

			LayoutTransition.SetWorldPositionChange(_element, worldChange);
			LayoutTransition.SetPositionChange(_element, oldPosition, _element.IntendedPosition);
			LayoutTransition.SetSizeChange(_element, oldSize, _element.IntendedSize);

			BypassActivate();
			Deactivate();
		}
		
		void OnTransitioned(object sender, LayoutTransitionedArgs args)
		{
			if (!Type.HasFlag(LayoutAnimationType.Explicit))
				return;
				
			_frameTrans = UpdateManager.FrameIndex;
			BypassActivate();
			Deactivate();
		}
	}
	
}

namespace Fuse.Triggers.Actions
{
	/**
		Lets you create a temporary layout change.
		This can be used to do visual layout transitions without needing actual layout changes.

		It has no noticeable effect on its own, and needs to be combined with a @(LayoutAnimation).
		The @(LayoutAnimation) will in turn be triggered by this action.

		# Example
		This example demonstrates `TransitionLayout` in action when a button is clicked.

			<DockPanel>
				<Panel Dock="Top" Height="20" ux:Name="originElement" />
				<Button Height="100" Dock="Bottom" Text="Transition!">
					<LayoutAnimation>
						<Move X="1" Y="1" RelativeTo="WorldPositionChange" Duration="1" />
						<Resize X="1" Y="1" RelativeTo="SizeChange" Duration="1" />
					</LayoutAnimation>
					<Clicked>
						<TransitionLayout From="originElement" />
					</Clicked>
				</Button>
			</DockPanel>

		When clicked, the @(Button) in this example will perform a transition over 1 second from the position and size of `originElement` (top edge of the @(DockPanel)) to its actual position and size (bottom edge of the @(DockPanel)).
	*/
	public class TransitionLayout : TriggerAction
	{
		/** Explicit target that will be transitioned. If not specified the Element ancestor of the action will be used*/
		public Element Target { get; set; }
		/** Transition the element from this one. */
		public Element From { get; set; }
		
		protected override void Perform(Node target)
		{
			//use Visual search for future-proofing this logic (it could be transitioned, just not supported now)
			_perform = Target ?? (target.FindByType<Visual>() as Element);
			if (_perform == null || From == null)
			{
				Fuse.Diagnostics.UserError( "Missing `From` or cannot find `Element` target", this );
				return;
			}

			//defer calculations until after layout since either element may have changed layout
			UpdateManager.AddDeferredAction(Transition,UpdateStage.Layout, LayoutPriority.Placement);
		}
		
		Element _perform;
		void Transition()
		{
			float2 oldPosition = From.LocalTransform.M41M42;
			float2 oldSize = From.ActualSize;
			
			var m = Matrix.Mul( From.WorldTransform, _perform.Parent.WorldTransformInverse );
			float3 worldChange = m.M41M42M43 - float3(_perform.IntendedPosition,0);
			
			LayoutTransition.SetWorldPositionChange(_perform, worldChange);
			LayoutTransition.SetPositionChange(_perform, oldPosition, _perform.IntendedPosition);
			LayoutTransition.SetSizeChange(_perform, oldSize, _perform.IntendedSize);
			
			LayoutTransition.Transitioned.RaiseWithoutBubble(new LayoutTransitionedArgs(_perform));
		}
		
	}
}
