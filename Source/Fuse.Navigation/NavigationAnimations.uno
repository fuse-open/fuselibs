using Uno;
using Uno.Collections;
using Fuse;
using Fuse.Animations;
using Fuse.Triggers;

namespace Fuse.Navigation
{
	static class NavTriggerUtil
	{
		static public bool CrossesZero(double a, double b)
		{
			return (a < 0 && b > 0) ||
				(a > 0 && b <0);
		}

		static public AnimationVariant Opposite(AnimationVariant v)
		{
			return v== AnimationVariant.Forward ? AnimationVariant.Backward :
				AnimationVariant.Forward;
		}
	}

	/**
		These triggers are used to animate pages as they move to and away from the active page.
		
		The basic behavior of this trigger depends on whether the navigation is continuous, such as a `PageControl` or `LinearNavigation`, or is discrete, such as `Navigator` or `DirectNavigation`.
		
		When used with continuous navigation a `Duration` property is not needed on the animators. The progress is mapped from the progress of the page itself in the navigation.
		
		When used with a discrete navigation a `Duration` is required. There is no smooth page progress change, it will simply flip between multiple states. Here the duration of the trigger will be used to do the animation.
		
		[subclass Fuse.Navigation.NavigationAnimation]
		
		See [Navigation Order](articles:navigation/navigationorder.md)
	*/
	public abstract class NavigationAnimation : Trigger
	{
		internal NavigationAnimation() { }

		protected Visual PageContext { get { return _proxy.Page; } }
		protected INavigation NavContext { get { return _proxy.Navigation; } }
		NavigationPageProxy _proxy;
		
		protected override void OnRooted()
		{
			base.OnRooted();
			_proxy = new NavigationPageProxy();
			_proxy.Init(NavReady,NavUnready,Parent);
		}
		
		void NavReady(object s)
		{
			_proxy.Navigation.PageProgressChanged += OnNavigationStateChanged;
			ForceUpdate();
		}

		protected override void OnUnrooted()
		{
			_proxy.Dispose();
			_proxy = null;
			_delay = false;
			base.OnUnrooted();
		}
		
		void NavUnready(object s)
		{
			_proxy.Navigation.PageProgressChanged -= OnNavigationStateChanged;
		}

		protected abstract void ForceUpdate();
		internal abstract void OnNavigationStateChanged(object sender, NavigationArgs state);

		float _scale = 1;
		/**
			Modifies the scale of the mapping from page progress to trigger progress.
			
			The progress of these triggers is based on the page progress in the navigation. Pages have a distance from the active page. While some controls limit the distance to just `0..1`, others, like a `PageControl`, allow for pages to have a distance greater than `1` away. By default this trigger reaches progress 1 when the page reaches a distance of 1, anything greater than 1 will not further modify the trigger.
			
			The `Scale` property allows changing that mapping. For example, a scale of `0.5` would mean that a page must reach a distance of 2 away from the active one before the trigger reaches a progress of 1.
			
			See [Navigation Order](articles:navigation/navigationorder.md)
		*/
		public float Scale
		{
			get { return _scale; }
			set { _scale = value; }
		}

		bool _delay;
		AnimationVariant _delayVariant;
		double _delayProgress;
		internal void GoProgress(double p, AnimationVariant variant, NavigationArgs state)
		{
			//https://github.com/fusetools/fuselibs-private/issues/1622
			//do not optimize a check of if (p == Progress) return;

			if (state.Mode == NavigationMode.Switch)
			{
				//a fix of https://github.com/fusetools/fuselibs-private/issues/2652
				//PlayTo(p, variant);
				_delayVariant = variant;
				_delayProgress = p;
				if (!_delay)
				{
					_delay = true;
					UpdateManager.PerformNextFrame(GoProgressPlay);
				}
			}
			else if (state.Mode == NavigationMode.Seek)
			{
				_delay = false;
				DirectSeek(p, variant);
			}
			else
			{
				_delay = false;
				BypassSeek(p, variant);
			}
		}
		
		void GoProgressPlay()
		{
			if (!_delay)
				return;
			_delay = false;
			PlayTo(_delayProgress, _delayVariant);
		}
	}

	/**
		[subclass Fuse.Navigation.EnterExitAnimation]
	*/
	public abstract class EnterExitAnimation : NavigationAnimation
	{
		protected override void ForceUpdate()
		{
			var p = NavContext.GetPageState(PageContext).Progress;
			if (IsMatch(p))
				Seek( Scale * Math.Abs(p) );
		}

		bool IsMatch(double progress)
		{
			return (PositiveProgress && progress >= 0.0) ||
				(NegativeProgress && progress <= 0.0);
		}

		protected bool PositiveProgress, NegativeProgress;

		internal override void OnNavigationStateChanged(object sender, NavigationArgs state)
		{
			var ps = NavContext.GetPageState(PageContext);
			var d = (Math.Abs(ps.PreviousProgress) < Math.Abs(ps.Progress)) ?
				AnimationVariant.Forward : AnimationVariant.Backward;
			if (!IsMatch(ps.Progress))
			{
				Seek(0,d);
				return;
			}

			GoProgress(Scale * Math.Abs(ps.Progress), d, state);
		}
	}

	/**
		Specifies an animation for a page that is behind the active page.

		Animates from 0 to 1 as the page progress goes from 0 to -1. For discrete navigation changes the duration of the animators will be used.

		## Example

		This example shows the use of both `ExitingAnimation` and `EnteringAnimation` in a custom transition for three panels in a @(PageControl):

			<Panel ux:Class="CustomPanel" TransformOrigin="TopLeft">
				<EnteringAnimation>
					<Rotate Degrees="90"/>
				</EnteringAnimation>
				<ExitingAnimation>
					<Rotate Degrees="-90" />
				</ExitingAnimation>
			</Panel>
			<PageControl Transition="None">
				<CustomPanel Background="#F00" />
				<CustomPanel Background="#0F0" />
				<CustomPanel Background="#00F" />
			</PageControl>
			
		See [Navigation Order](articles:navigation/navigationorder.md)
	*/
	public class ExitingAnimation : EnterExitAnimation
	{
		public ExitingAnimation()
		{
			NegativeProgress = true;
		}
	}

	/**	
		Specifies an animation for a page that is in front of the active one.

		Animates from 0 to 1 as the page progress goes from 0 to 1. For discrete navigation changes the duration of the animators will be used.
		
		For clarity, if the page is coming from the front, such as navigating forward in a `PageControl`, the trigger animates from 1 to 0. This is just a natural result of the page's progress changing from 1 to 0.

		## Example

		This example shows the use of both `EnteringAnimation` and `ExitingAnimation` in a custom transition for three panels in a @(PageControl):

			<Panel ux:Class="CustomPanel" TransformOrigin="TopLeft">
				<EnteringAnimation>
					<Rotate Degrees="90"/>
				</EnteringAnimation>
				<ExitingAnimation>
					<Rotate Degrees="-90" />
				</ExitingAnimation>
			</Panel>
			<PageControl Transition="None">
				<CustomPanel Background="#F00" />
				<CustomPanel Background="#0F0" />
				<CustomPanel Background="#00F" />
			</PageControl>
			
		See [Navigation Order](articles:navigation/navigationorder.md)
	*/
	public class EnteringAnimation : EnterExitAnimation
	{
		public EnteringAnimation()
		{
			PositiveProgress = true;
		}
	}
	/** Specifies an animation for an element that's becoming active.

		If @(SwipeNavigate) is used, one can observe that `ActivatingAnimation` progressed from 0 as soon as the `Page` is entering, stays at 1 as long as the `Page` is active,
		and then progresses towards 0 again as the `Page` is exiting. This is the inverse of `DeactivatingAnimation`'s behavior.

		## Example

		The following example shows an `ActivatingAnimation` animating the `Height` of a `Rectangle`, causing it to reduce in size vertically as a page is being navigated to:

			<PageControl>
				<Panel Background="Red" />
				<Panel Background="Blue">
					<Rectangle Color="Black" Width="100%" Height="0%" Alignment="Top" ux:Name="rect"/>
					<ActivatingAnimation>
						<Change rect.Height="100%" />
					</ActivatingAnimation>
				</Panel>
			</PageControl>

		See [Navigation Order](articles:navigation/navigationorder.md)
	*/
	public class ActivatingAnimation : NavigationAnimation
	{
		protected override void ForceUpdate()
		{
			Seek( InvertProgress(Scale * NavContext.GetPageState(PageContext).Progress) );
		}

		double InvertProgress( double p )
		{
			return 1 - Math.Min( 1, Math.Abs(p) );
		}

		internal override void OnNavigationStateChanged(object sender, NavigationArgs state)
		{
			var ps = NavContext.GetPageState(PageContext);
			var d = (Math.Abs(ps.Progress) < Math.Abs(ps.PreviousProgress) ) ?
				AnimationVariant.Forward : AnimationVariant.Backward;
			//can't miss a state change
			//TODO: Restore this!
			//if (state.Mode != NavigationMode.Bypass &&
			//	NavTriggerUtil.CrossesZero(state.Progress, state.PreviousProgress) )
			//	Seek(1, NavTriggerUtil.Opposite(d));

			GoProgress(InvertProgress(Scale * ps.Progress), d, state);
		}
	}
	/** Specifies an animation for an element that's becoming inactive.

		If @(SwipeNavigate) is used, one can observe that `DeactivatingAnimation` progressed from 1 to 0 as soon as the `Page` is entering, stays at 0 as long as the `Page` is active,
		and then progresses towards 1 again as the `Page` is exiting. This is the inverse of `ActivatingAnimation`'s behavior.

		## Example

		The following example shows a `DeactivatingAnimation` animating the `Height` of a `Rectangle`, causing it to fill the page being navigated to:

			<PageControl>
				<Panel Background="Red" />
				<Panel Background="Blue">
					<Rectangle Color="Black" Width="100%" Height="0%" Alignment="Top" ux:Name="rect"/>
					<DeactivatingAnimation>
						<Change rect.Height="100%" />
					</DeactivatingAnimation>
				</Panel>
			</PageControl>

		See [Navigation Order](articles:navigation/navigationorder.md)
	*/
	public class DeactivatingAnimation : NavigationAnimation
	{
		protected override void ForceUpdate()
		{
			Seek( Math.Abs(Scale * NavContext.GetPageState(PageContext).Progress) );
		}

		internal override void OnNavigationStateChanged(object sender, NavigationArgs state)
		{
			var ps = NavContext.GetPageState(PageContext);
			var d = (Math.Abs(ps.Progress) > Math.Abs(ps.PreviousProgress) ) ?
				AnimationVariant.Forward : AnimationVariant.Backward;
			//can't miss a state change
			//TODO: restore this!
			//if (state.Mode != NavigationMode.Bypass &&
			//	NavTriggerUtil.CrossesZero(state.Progress, state.PreviousProgress) )
			//	Seek(0, NavTriggerUtil.Opposite(d));

			GoProgress(Scale * Math.Abs(ps.Progress), d, state);
		}
	}
}
