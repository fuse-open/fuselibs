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
	public interface ISizeConstraint
	{
		float2 ContentSize { get; }
		float2 TrimSize { get; }
	}

	/**
		A `TransformGesture` interprets pointer gestures and modifies an `InteractiveTransform` in response.

		Note that the `TransformGesture` on its own has no visual impact, it only modifies the `InteractiveTransform`, which provides the actual visual transformation.  For example here is a simple image viewing setup:

			<Panel HitTestMode="LocalBounds">
				<Image File="my_image.jpg">
					<InteractiveTransform ux:Name="ImageTrans"/>
				</Image>
				<ZoomGesture Target="ImageTrans"/>
				<PanGesture Target="ImageTrans"/>
				<RotateGesture Target="ImageTrans"/>
			</Panel>

		One `InteractiveTransform` can be the target of multiple gestures. They will coorindate correctly with each other to provide a unified experience. The `InteractiveTransform` will contain values that represent the total transformation.

		@topic Gestures

		For a complete list of single-finger gestures such as @Tapped, @LongPress etc., see @Triggers.

		## Available gestures

		[subclass Fuse.Gestures.TransformGesture]
	*/
	public abstract class TransformGesture : Behavior
	{
		public InteractiveTransform Target
		{	
			get;
			private set;
		}

		internal BoundedRegion2D Region = BasicBoundedRegion2D.CreatePoints();
	
		internal TransformGesture(InteractiveTransform target)
		{
			Target = target;
		}
		
		internal TwoFinger Impl;
		protected override void OnRooted()
		{
			base.OnRooted();
			Impl = TwoFinger.Attach(Parent);
			Impl.Started += OnStarted;
			Impl.Ended += OnEnded;
		}
		
		protected override void OnUnrooted()
		{
			Impl.Started -= OnStarted;
			Impl.Ended -= OnEnded;
			Impl.Detach();
			Impl = null;
			CheckNeedUpdate();
			base.OnUnrooted();
		}
		
		protected abstract void OnStarted();
		protected abstract void OnEnded();
		
		void Update()
		{
			Region.Update(Time.FrameInterval);
			OnUpdate();
			CheckNeedUpdate();
		}
		
		bool _hasUpdate;
		protected void CheckNeedUpdate()
		{
			var need = IsRootingCompleted && !Region.IsStatic;
			if (need == _hasUpdate)
				return;
				
			_hasUpdate = need;
			if (need)
				UpdateManager.AddAction(Update);
			else
				UpdateManager.RemoveAction(Update);
		}
		
		protected virtual void OnUpdate() { }
	}
	
}