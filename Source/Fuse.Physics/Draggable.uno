using Fuse.Elements;

namespace Fuse.Physics
{
	public enum Axis2D
	{
		XY,
		X,
		Y
	}
	
	/**
		@mount Physics
	*/
	public class Draggable : Behavior, IRule
	{
		Body _body;

		public Element Bounds { get; set; }
		
		/**
			Sets the draggable behavior to be locked to a single axis.
			Can be set to X, Y or XY (the default, unconstrained)
		*/
		public Axis2D Axis { get; set; }

		protected override void OnRooted()
		{
			base.OnRooted();

			_body = Body.Pin(Parent);
			_body.World.AddRule(this);

			Fuse.Input.Pointer.AddHandlers(Parent, OnPressed, OnMoved, OnReleased);
		}

		protected override void OnUnrooted()
		{
			_body.World.RemoveRule(this);
			_body.Unpin();
			_body = null;

			Fuse.Input.Pointer.RemoveHandlers(Parent, OnPressed, OnMoved, OnReleased);

			base.OnUnrooted();
		}

		float3 GetPointerPosition(Fuse.Input.PointerEventArgs args)
		{
			// TODO: transform into local space
			return float3(args.WindowPoint, 0);
		}

		bool _hasLock;
		float3 _pos;

		void OnPressed(object sender, Fuse.Input.PointerPressedArgs args)
		{
			if (_hasLock) return;

			if (args.TryHardCapture(this, OnPointerLost, args.Visual))
			{
				_hasLock = _body.TryLockMotion(this);
				if (!_hasLock) return;

				WhileDragging.Begin(_body.Visual);

				_pos = GetPointerPosition(args);
			}
		}

		void OnPointerLost()
		{
			if (_hasLock)
			{
				_hasLock = false;
				_body.UnlockMotion();
				WhileDragging.End(_body.Visual);
			}
		}

		float3 _forceMotion;

		void OnMoved(object sender, Fuse.Input.PointerMovedArgs args)
		{
			if (!_hasLock) return;

			var newPos = GetPointerPosition(args);
			var delta =  newPos - _pos;
			_pos = newPos;
			
			switch(Axis)
			{
				case Axis2D.X:
					delta.Y = 0;
					break;
				case Axis2D.Y:
					delta.X = 0;
					break;
			}

			_forceMotion += delta;
		}

		void OnReleased(object sender, Fuse.Input.PointerReleasedArgs args)
		{
			if (_hasLock)
			{
				args.ReleaseCapture(this);

				_hasLock = false;
				_body.UnlockMotion();
				WhileDragging.End(_body.Visual);
			}
		}

		void IRule.Update(double deltaTime, World world)
		{
			_body.Move(_forceMotion);
			_body.ApplyForce(_forceMotion*0.3f / (float)deltaTime);
			_body.ConstrainToBounds(Bounds);

			_forceMotion = float3(0);
		}

	}

	/**
		Active while the element is being dragged.

		@examples Docs/WhileDragging.md
	*/
	public class WhileDragging : Fuse.Triggers.Trigger
	{
		internal static void Begin(Visual n)
		{
			for (var v = n.FirstChild<WhileDragging>(); v != null; v = v.NextSibling<WhileDragging>())
				v.Activate();
		}

		internal static void End(Visual n)
		{
			for (var v = n.FirstChild<WhileDragging>(); v != null; v = v.NextSibling<WhileDragging>())
				v.Deactivate();
		}
	}
}
