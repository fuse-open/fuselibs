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
		A @TransformGesture that provides zooming.

		This is triggered by dragging two pointers (fingers) over the device. Either moving towards each other (pinching) to reduce the zoom, or moving away from each other to increase the zoom.

		For testing on desktop this can be simulated by holding down Ctrl, pressing the mouse button, and moving cursor up or down.
		Note that this desktop feature is for testing, so the specifics of how this works should not be relied upon.

		## Example

		Shows a red circle we can use two fingers to zoom in or out.

			<Panel>
				<InteractiveTransform ux:Name="transform" />
				<ZoomGesture Target="transform" />
				<Panel>
					<Text Value="Resize me" Color="White" FontSize="25" Alignment="Center" />
					<Circle Width="350" Height="350" Color="Red" />
				</Panel>
			</Panel>
	*/
	public sealed class ZoomGesture : TransformGesture
	{
		[UXConstructor]
		public ZoomGesture([UXParameter("Target")] InteractiveTransform target)
			: base(target)
		{ 
			Region = BasicBoundedRegion2D.CreateExponential();
		}
		
		protected override void OnRooted()
		{
			base.OnRooted();
			Impl.Zoomed += OnZoomed;
		}
		
		protected override void OnUnrooted()
		{
			Impl.Zoomed -= OnZoomed;
			base.OnUnrooted();
		}
		
		float _prevZoom, _startZoom;
		protected override void OnStarted()
		{
			_startZoom = Target.ZoomFactor;
			_prevZoom = Math.Log(_startZoom);
			
			Region.Position = float2(_prevZoom,0);
			Region.MinPosition = float2(Math.Log(Minimum),0);
			Region.MaxPosition = float2(Math.Log(Maximum),0);
			Region.StartUser();
			CheckNeedUpdate();
		}
		
		protected override void OnEnded()
		{
			Region.EndUser();
			CheckNeedUpdate();
		}
		
		void OnZoomed(float factor)
		{
			var current = _startZoom * factor;
			var step = Math.Log(current) - _prevZoom;
			Region.StepUser(float2(step,0));
			_prevZoom = Math.Log(current);
			
			Target.ZoomFactor = Math.Exp(Region.Position.X);
		}
		
		protected override void OnUpdate()
		{
			Target.SetZoomFactor(Math.Exp(Region.Position.X), null);
		}
		
		float _maximum = float.PositiveInfinity;
		/**
			The maximum zoom factor that will be set by this gesture.
		*/
		public float Maximum
		{
			get { return _maximum; }
			set { _maximum = value; }
		}
		
		float _minimum = 0;
		/**
			The minimum zoom factor that will be set by this gesture.
		*/
		public float Minimum
		{
			get { return _minimum; }
			set { _minimum = value; }
		}
	}
}
