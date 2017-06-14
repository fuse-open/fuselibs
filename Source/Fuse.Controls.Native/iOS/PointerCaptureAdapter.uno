using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse;
using Fuse.Input;

namespace Fuse.Controls.Native.iOS
{
	extern(iOS) internal class PointerCaptureAdapter : IDisposable
	{
		Visual _visual;
		ObjC.Object _control;
		List<ObjC.Object> _activeTouches;
		IDisposable _touchEvents;

		public PointerCaptureAdapter(Visual visual, ObjC.Object control)
		{
			if (visual == null)
				throw new ArgumentException("PointerCaptureAdapter requires Visual", "visual");
			if (!control.IsUIControl())
				throw new ArgumentException("PointerCaptureAdapter requires UIControl", "control");

			_visual = visual;
			_control = control;
			_activeTouches = new List<ObjC.Object>();
			_touchEvents = UIControlEvent.AddAllTouchEventsCallback(_control, OnTouchEvent);
		}

		void OnTouchEvent(ObjC.Object sender, ObjC.Object uiEvent)
		{
			if (sender.IsUIControl() && uiEvent.IsUIEvent())
			{
				var touchEnded = false;
				var touches = uiEvent.GetTouchesForView(sender);
				for (var i = 0; i < touches.Length; i++)
				{
					var touch = touches[i];

					if (!_activeTouches.Contains(touch))
						_activeTouches.Add(touch);
					var pointerIndex = _activeTouches.IndexOf(touch);

					var phase = touch.GetTouchPhase();
					if (phase == TouchPhase.Began)
						Pointer.ModifyCapture(touch, _visual, LostCallback, CaptureType.Hard, pointerIndex);
					else if (phase == TouchPhase.Ended || phase == TouchPhase.Cancelled)
						touchEnded = true;
				}

				if (touchEnded)
				{
					for (var i = 0; i < _activeTouches.Count; i++)
						Pointer.ReleaseCapture(_activeTouches[i]);
					_activeTouches.Clear();
				}
			}
		}

		void LostCallback() {}

		public void Dispose()
		{
			_touchEvents.Dispose();
			_touchEvents = null;
			_activeTouches = null;
			_visual = null;
			_control = null;
		}
	}

	internal enum TouchPhase
	{
		Began = 0,
		Moved,
		Stationary,
		Ended,
		Cancelled,
	}

	extern(iOS) internal static class UITouchExtensions
	{
		[Foreign(Language.ObjC)]
		[Require("Source.Include", "UIKit/UIKit.h")]
		public static TouchPhase GetTouchPhase(this ObjC.Object handle)
		@{
			::UITouch* touch = (::UITouch*)handle;
			UITouchPhase phase = [touch phase];

			switch (phase)
			{
				case UITouchPhaseBegan:
					return @{TouchPhase.Began};
				case UITouchPhaseMoved:
					return @{TouchPhase.Moved};
				case UITouchPhaseStationary:
					return @{TouchPhase.Stationary};
				case UITouchPhaseEnded:
					return @{TouchPhase.Ended};
				case UITouchPhaseCancelled:
					return @{TouchPhase.Cancelled};
				default:
					[NSException raise:@"Unknown touchphase" format:@"Touch phase of %ld is invalid", (long)phase];
					break;
			}
		@}
	}

	extern(iOS) internal static class UIEventExtensions
	{
		public static ObjC.Object[] GetTouchesForView(this ObjC.Object handle, ObjC.Object viewHandle)
		{
			var touchCount = (int)GetTouchesForViewCount(handle, viewHandle);
			var touches = new ObjC.Object[touchCount];
			for (var i = 0; i < touchCount; i++)
				touches[i] = GetTouchForView(handle, viewHandle, i);
			return touches;
		}

		[Foreign(Language.ObjC)]
		[Require("Source.Include", "UIKit/UIKit.h")]
		static long GetTouchesForViewCount(ObjC.Object handle, ObjC.Object viewHandle)
		@{
			::UIEvent* ev = (::UIEvent*)handle;
			::UIView* view = (::UIView*)viewHandle;
			return [[[ev touchesForView:view] allObjects] count];
		@}

		[Foreign(Language.ObjC)]
		[Require("Source.Include", "UIKit/UIKit.h")]
		static ObjC.Object GetTouchForView(ObjC.Object handle, ObjC.Object viewHandle, int index)
		@{
			::UIEvent* ev = (::UIEvent*)handle;
			::UIView* view = (::UIView*)viewHandle;
			return [[[ev touchesForView:view] allObjects] objectAtIndex:index];
		@}
	}
}