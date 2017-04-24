using Uno;
using Uno.UX;
using Uno.Diagnostics;

using Fuse.Animations;
using Fuse.Elements;

namespace Fuse.Gestures
{
	public enum Edge
	{
		Left,
		Right,
		Top,
		Bottom
	}

	/**
		DEPRECATED: Use `SwipeGesture` with `EdgeNavigator` instead

	*/
	public class EdgeSwipeAnimation : Fuse.Triggers.Trigger
	{
		Internal.EdgeSwiper _swiper = new Internal.EdgeSwiper();

		public Edge Edge
		{
			get { return _swiper.Edge; }
			set { _swiper.Edge = value; }
		}

		public float EdgeThreshold
		{
			get { return _swiper.EdgeThreshold; }
			set { _swiper.EdgeThreshold = value; }
		}

		public Element Target
		{
			get { return _swiper.Target; }
			set { _swiper.Target = value; }
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			var element = Parent as Element;
			if (element == null)
				throw new Exception( "EdgeSwipeAnimation must be attached to an Element" );

			_swiper.Rooted(element);
			_swiper.Seek(0);
			_swiper.ProgressChanged += OnProgressChanged;
		}

		protected override void OnUnrooted()
		{
			_swiper.Unrooted();
			_swiper.ProgressChanged -= OnProgressChanged;
			base.OnUnrooted();
		}

		void OnProgressChanged(object s, double progress)
		{
			Seek( progress );
		}

		public void Enable()
		{
			_swiper.Enable();
		}

		public void Disable()
		{
			_swiper.Disable();
		}

		public bool IsEnabled
		{
			get { return _swiper.IsEnabled; }
			set
			{
				if (value)
					Enable();
				else
					Disable();
			}
		}
	}
}
