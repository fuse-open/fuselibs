using Uno;
using Uno.UX;

using Fuse.Elements;
using Fuse.Gestures.Internal;
using Fuse.Input;
using Fuse.Motion.Simulation;
using Fuse.Scripting;
using Fuse.Triggers;

namespace Fuse.Gestures
{
	/**
		A @TransformGesture that provides rotation.

		This is triggered by a rotating gesture of two points (fingers) on the device.

		For testing on desktop this can be triggered by holding down Ctrl, pressing the mouse button, moving up/down, then left/right. Careful, it interferes with the @ZoomGesture, and is only suitable for desktop testing. (This desktop feature is intended only for testing, so the specifics of how this works should not be relied upon.)
	*/
	public sealed class RotateGesture : TransformGesture
	{
		[UXConstructor]
		public RotateGesture([UXParameter("Target")] InteractiveTransform target)
			: base(target)
		{ 
			Region = BasicBoundedRegion2D.CreateRadians();
		}
		
		/**
			The rotation will be done in increments of this value, expressed in radians.
		*/
		public float Step { get; set; }

		/**
			`Step` specified in degrees.
		*/
		public float StepDegrees 
		{ 
			get { return Math.RadiansToDegrees(Step); }
			set { Step = Math.DegreesToRadians(value); }
		}
		
		protected override void OnRooted()
		{
			base.OnRooted();
			Impl.Rotated += OnRotated;
		}
		
		protected override void OnUnrooted()
		{
			Impl.Rotated -= OnRotated;
			base.OnUnrooted();
		}
		
		float _startRotation;
		protected override void OnStarted()
		{
			_startRotation = Target.Rotation;
			Region.Reset(float2(_startRotation,0));
		}
		
		protected override void OnEnded()
		{
		}
		
		protected override void OnUpdate()
		{
			Target.Rotation = Region.Position.X;
		}
		
		void OnRotated(float angle)
		{
			var q = _startRotation + angle;
			if (Step > 0)
			{
				var s = Math.Floor(q / Step + 0.5f) * Step;
				Region.MoveTo(float2(s,0));
				CheckNeedUpdate();
			}
			else
			{
				Target.Rotation = q;
			}
		}
	}
	
}