using Uno;
using Fuse.Platform;
using Uno.UX;

namespace Fuse.Triggers
{
	/**
		Active whenever the on-screen keyboard is visible.
	*/
	public class WhileKeyboardVisible: Trigger
	{
		float _baseHeight;

		float _threshold = 150;
		public float Threshold
		{
			get { return _threshold; }
		}


		protected override void OnRooted()
		{
			base.OnRooted();

			if defined(iOS || Android)
			{
				SystemUI.BottomFrameWillResize += OnBottomBarResize;

				if defined(iOS)
				{
					_baseHeight = 0;
				}
				else
				{
					_baseHeight = GetHeight(SystemUI.BottomFrame);
				}
			}
		}

		protected override void OnUnrooted()
		{
			if defined(iOS || Android)
			{
				SystemUI.BottomFrameWillResize -= OnBottomBarResize;
			}

			base.OnUnrooted();
		}

		float GetHeight(Rect r)
		{
			return r.Bottom - r.Top;
		}

		static float _deltaY;

		void OnBottomBarResize(object sender, SystemUIWillResizeEventArgs args)
		{
			var newHeight = GetHeight(args.EndFrame);

			// Temp hack because backends report SystemUI.BottomFrame differentl
			// Joao is on fixing that
			if defined(iOS)
			{
				newHeight = Rect.Intersect(SystemUI.Frame, args.EndFrame).Size.Y;
			}

			var density = 1.0f;
			var vp = Parent.Viewport;
			if (vp != null) density = vp.PixelsPerPoint; //TODO: is this perhaps meant to be PixelsPerOSPoint?

			var newDeltaY = (newHeight - _baseHeight) / density;

			if (newDeltaY > Threshold)
			{
				_deltaY = newDeltaY;
				Activate();
			}
			else
			{
				if defined(!iOS)
					_baseHeight = GetHeight(args.EndFrame);
				Deactivate();
			}

		}

		class RelativeToKeyboardMode: ITranslationMode
		{
			public float3 GetAbsVector(Translation t)
			{
				return t.Vector * float3(0, WhileKeyboardVisible._deltaY, 0);
			}
			//TODO: events for keyboard?
			public object Subscribe(ITransformRelative transform) { return null; }
			public void Unsubscribe(ITransformRelative transform, object sub)  { }
		}

		[UXGlobalResource("Keyboard")]
		public static readonly ITranslationMode Keyboard = new RelativeToKeyboardMode();


	}
}
