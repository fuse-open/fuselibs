using Uno;
using Uno.Collections;
using Uno.UX;
using Fuse.Animations;

namespace Fuse.Triggers
{
	/**
		Active while the @Video is playing.

		This trigger is for use inside the `Video` element.

		@examples Docs/VideoTriggers.md
	*/
	public class WhilePlaying : WhileTrigger
	{
		static PropertyHandle _whilePlayingProp = Properties.CreateHandle();

		static bool IsPlaying(Visual n)
		{
			var v = n.Properties.Get(_whilePlayingProp);
			if (!(v is bool)) return false;
			return (bool)v;
		}

		public static void SetState(Visual n, bool playing)
		{
			var v = IsPlaying(n);
			if (v != playing)
			{
				n.Properties.Set(_whilePlayingProp, playing);
				for (var wl = n.FirstChild<WhilePlaying>(); wl != null; wl = wl.NextSibling<WhilePlaying>())
					wl.SetActive(playing);
			}
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			SetActive(IsPlaying(Parent));
		}
	}

	/**
		Active while the @Video is paused.

		This trigger is for use inside the `Video` element.

		@examples Docs/VideoTriggers.md
	*/
	public class WhilePaused : WhileTrigger
	{
		static PropertyHandle _whilePausedProp = Properties.CreateHandle();

		static bool IsPaused(Visual n)
		{
			var v = n.Properties.Get(_whilePausedProp);
			if (!(v is bool)) return false;
			return (bool)v;
		}

		public static void SetState(Visual n, bool paused)
		{
			var v = IsPaused(n);
			if (v != paused)
			{
				n.Properties.Set(_whilePausedProp, paused);
				for (var wl = n.FirstChild<WhilePaused>(); wl != null; wl = wl.NextSibling<WhilePaused>())
					wl.SetActive(paused);
			}
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			SetActive(IsPaused(Parent));
		}
	}

	/**
		Active while the @Video is completed.

		This trigger is for use inside the `Video` element.

		@examples Docs/VideoTriggers.md
	*/
	public class WhileCompleted : WhileTrigger
	{
		static PropertyHandle _whileCompletedProp = Properties.CreateHandle();

		static bool IsCompleted(Visual n)
		{
			var v = n.Properties.Get(_whileCompletedProp);
			if (!(v is bool)) return false;
			return (bool)v;
		}

		public static void SetState(Visual n, bool paused)
		{
			var v = IsCompleted(n);
			if (v != paused)
			{
				n.Properties.Set(_whileCompletedProp, paused);
				for (var wl = n.FirstChild<WhileCompleted>(); wl != null; wl = wl.NextSibling<WhileCompleted>())
					if (wl.IsRootingCompleted) wl.SetActive(paused);
			}
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			SetActive(IsCompleted(Parent));
		}
	}

}
