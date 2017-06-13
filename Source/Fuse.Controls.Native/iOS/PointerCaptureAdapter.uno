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
		List<UITouch> _activeTouches;
		IDisposable _touchEvents;

		public PointerCaptureAdapter(Visual visual, ObjC.Object control)
		{
			if (visual == null)
				throw new ArgumentException("PointerCaptureAdapter requires Visual", "visual");
			if (!control.IsUIControl())
				throw new ArgumentException("PointerCaptureAdapter requires UIControl", "control");

			_visual = visual;
			_control = control;
			_activeTouches = new List<UITouch>();
			_touchEvents = UIControlEvent.AddAllTouchEventsCallback(_control, OnTouchEvent);
		}

		void OnTouchEvent(ObjC.Object sender, ObjC.Object uiEvent)
		{
			if (sender.IsUIControl() && uiEvent.IsUIEvent())
			{
				var touchEnded = false;
				var touches = new UIEvent(uiEvent).GetTouchesForView(sender);
				for (var i = 0; i < touches.Length; i++)
				{
					var touch = touches[i];

					if (!_activeTouches.Contains(touch))
						_activeTouches.Add(touch);
					var pointerIndex = _activeTouches.IndexOf(touch);

					if (touch.Phase == UITouch.TouchPhase.Began)
						Pointer.ModifyCapture(touch, _visual, LostCallback, CaptureType.Hard, pointerIndex);
					else if (touch.Phase == UITouch.TouchPhase.Ended || touch.Phase == UITouch.TouchPhase.Cancelled)
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

	extern(iOS) public class UITouch
	{
		public enum TouchPhase
		{
			Began = 0,
			Moved,
			Stationary,
			Ended,
			Cancelled,
		}

		readonly ObjC.Object _handle;

		public UITouch(ObjC.Object handle)
		{
			_handle = handle;
		}

		public float2 LocationInView(ObjC.Object view)
		{
			float x = 0;
			float y = 0;
			LocationInView(_handle, view,
				extern<IntPtr>"&x",
				extern<IntPtr>"&y");
			return float2(x, y);
		}

		public double Timestamp
		{
			get { return GetTimestamp(_handle); }
		}

		public TouchPhase Phase
		{
			get { return GetTouchPhase(_handle); }
		}

		public override bool Equals(object obj)
		{
			return obj is UITouch
				? Compare(_handle, ((UITouch)obj)._handle)
				: false;
		}

		public override int GetHashCode()
		{
			return _handle.GetHashCode();
		}

		[Foreign(Language.ObjC)]
		[Require("Source.Include", "UIKit/UIKit.h")]
		static TouchPhase GetTouchPhase(ObjC.Object handle)
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

		[Foreign(Language.ObjC)]
		[Require("Source.Include", "UIKit/UIKit.h")]
		static void LocationInView(ObjC.Object handle, ObjC.Object relativeViewHandle, IntPtr x, IntPtr y)
		@{
			::UITouch* touch = (::UITouch*)handle;
			UIView* relativeView = (UIView*)relativeViewHandle;
			UIWindow* window = [touch window];
			CGPoint location = [touch locationInView:window];
			CGPoint localLocation = [window convertPoint:location toView:relativeView];
			*((float*)x) = (float)localLocation.x;
			*((float*)y) = (float)localLocation.y;
		@}

		[Foreign(Language.ObjC)]
		[Require("Source.Include", "UIKit/UIKit.h")]
		static double GetTimestamp(ObjC.Object handle)
		@{
			::UITouch* touch = (::UITouch*)handle;
			return [touch timestamp];
		@}

		[Foreign(Language.ObjC)]
		[Require("Source.Include", "UIKit/UIKit.h")]
		static bool Compare(ObjC.Object handle1, ObjC.Object handle2)
		@{
			::UITouch* touch1 = (::UITouch*)handle1;
			::UITouch* touch2 = (::UITouch*)handle2;
			return touch1 == touch2;
		@}
	}

	extern(iOS) public class UIEvent
	{

		readonly ObjC.Object _handle;

		public UIEvent(ObjC.Object handle)
		{
			_handle = handle;
		}

		public UITouch[] GetTouchesForView(ObjC.Object viewHandle)
		{
			var touchCount = (int)GetTouchesForViewCount(_handle, viewHandle);
			var touches = new UITouch[touchCount];
			for (var i = 0; i < touchCount; i++)
				touches[i] = new UITouch(GetTouchForView(_handle, viewHandle, i));
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