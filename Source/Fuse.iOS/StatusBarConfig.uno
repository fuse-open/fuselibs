using Uno.Collections;
using Uno.Platform.iOS;
using Fuse.Platform;

namespace Fuse.iOS
{
	/**
		Configures the appearance of the status bar on *iOS*.
	
		To configure the status bar on *Android*, see [Android.StatusBarConfig](api:fuse/android/statusbarconfig).

		### Example
		
		To configure the status bar on iOS, place an `iOS.StatusBarConfig` somewhere in your UX tree.

			<App>
				<iOS.StatusBarConfig Style="Light" Animation="Slide" IsVisible="True" />
				
				<!-- The rest of our app goes here -->
			</App>
		
		However, we usually want to configure the status bar for Android as well.
		We'll add an additional [Android.StatusBarConfig](api:fuse/android/statusbarconfig).
		
			<iOS.StatusBarConfig Style="Light" Animation="Slide" IsVisible="True" />
			<Android.StatusBarConfig Color="#0003" IsVisible="True" />
	*/
	public class StatusBarConfig: Behavior
	{
		static List<StatusBarConfig> _stack = new List<StatusBarConfig>();

		bool _isVisible, _hasIsVisible;
		/** Whether the status bar should be visible
			@default true
		*/
		public bool IsVisible
		{
			get { return _isVisible; }
			set
			{
				if (!_hasIsVisible || _isVisible != value)
				{
					_isVisible = value;
					_hasIsVisible = true;
					Apply();
				}
			}
		}

		StatusBarStyle _style;
		bool _hasStyle;
		/** The visual style of the status bar
			@default StatusBarStyle.Dark
		*/
		public StatusBarStyle Style
		{
			get { return _style; }
			set
			{
				if (!_hasStyle || _style != value)
				{
					_style = value;
					_hasStyle = true;
					Apply();
				}
			}
		}

		StatusBarAnimation _animation;
		bool _hasAnimation;

		/** The animation style used when hiding or showing the status bar
			@default StatusBarAnimation.None
		*/
		public StatusBarAnimation Animation
		{
			get { return _animation; }
			set
			{
				if (!_hasAnimation || _animation != value)
				{
					_animation = value;
					_hasAnimation = true;
					Apply();
				}
			}
		}


		protected override void OnRooted()
		{
			base.OnRooted();

			_stack.Add(this);
			Apply();
		}

		protected override void OnUnrooted()
		{
			_stack.Remove(this);
			Apply();

			base.OnUnrooted();
		}

		static bool GetIsVisible()
		{
			for (var i = _stack.Count; i --> 0; )
			{
				if (_stack[i]._hasIsVisible)
					return _stack[i].IsVisible;
			}
			return true;
		}

		static StatusBarStyle GetStyle()
		{
			for (var i = _stack.Count; i --> 0; )
			{
				if (_stack[i]._hasStyle)
					return _stack[i].Style;
			}
			return StatusBarStyle.Dark;
		}

		static StatusBarAnimation GetAnimation()
		{
			for (var i = _stack.Count; i --> 0; )
			{
				if (_stack[i]._hasAnimation)
					return _stack[i].Animation;
			}
			return StatusBarAnimation.None;
		}

		static void Apply()
		{
			if defined(IOS)
			{
				var anim = GetAnimation();
				var style = GetStyle();
				var visible = GetIsVisible();
				if (SystemUI.uStatusBarAnimation != anim) SystemUI.uStatusBarAnimation = anim;
				if (SystemUI.uStatusBarStyle != style) SystemUI.uStatusBarStyle = style;
				if (SystemUI.IsTopFrameVisible != visible) SystemUI.IsTopFrameVisible = visible;
			}
		}

	}

}
