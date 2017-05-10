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
}