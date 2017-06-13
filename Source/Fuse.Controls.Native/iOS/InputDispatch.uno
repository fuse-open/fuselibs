using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Uno.UX;

namespace Fuse.Controls.Native.iOS
{
	using Fuse.Input;

	[TargetSpecificImplementation]
	extern(iOS) internal static class InputDispatch
	{
		static readonly Dictionary<ObjC.Object, Visual> _listeners;
		static readonly List<UITouch> _activeTouches;
		static readonly ObjC.Object _eventHandler;

		static InputDispatch()
		{
			_listeners = new Dictionary<ObjC.Object, Visual>();
			_activeTouches = new List<UITouch>();
			_eventHandler = CreateEventHandler(OnTouchEvent);
		}

		static void OnTouchEvent(ObjC.Object sender, ObjC.Object uiEvent)
		{
			if (sender.IsUIControl() && uiEvent.IsUIEvent())
			{
				if (_listeners.ContainsKey(sender))
				{
					var visual = _listeners[sender];
					var ev = new UIEvent(uiEvent);
					HandleEvent(sender, visual, ev);
				}
			}
		}

		static void ActivateTouch(UITouch touch)
		{
			if (!_activeTouches.Contains(touch))
				_activeTouches.Add(touch);
		}

		static int GetPointerIndex(UITouch touch)
		{
			return _activeTouches.IndexOf(touch);
		}

		static void DeactivateAllTouches()
		{
			_activeTouches.Clear();
		}

		public static void HandleEvent(ObjC.Object viewHandle, Visual origin, ObjC.Object uiEvent)
		{
			if (uiEvent.IsUIEvent())
				HandleEvent(viewHandle, origin, new UIEvent(uiEvent));
		}

		public static void HandleEvent(ObjC.Object viewHandle, Visual origin, UIEvent uiEvent)
		{
			var rootVisual = FindRoot(origin);
			var touches = uiEvent.GetTouchesForView(viewHandle);
			var touchEnded = false;

			ObjC.Object rootView = null;
			var rootViewport = rootVisual as NativeRootViewport;
			if (rootViewport != null)
				rootView = rootViewport.RootView.NativeHandle;

			for (var i = 0; i < touches.Length; i++)
			{
				var touch = touches[i];

				ActivateTouch(touch);
				var pointerIndex = GetPointerIndex(touch);
				var data = MakePointerEventData(touch, rootView, pointerIndex);

				if (touch.Phase == UITouch.TouchPhase.Began)
				{
					RaisePressed(rootVisual, origin, data);
				}
				else if (touch.Phase == UITouch.TouchPhase.Moved)
				{
					RaiseMoved(rootVisual, origin, data);
				}
				/*
				else if (touch.Phase == UITouch.TouchPhase.Staionary) { }
				*/
				else if (touch.Phase == UITouch.TouchPhase.Ended)
				{
					RaiseReleased(rootVisual, origin, data);
					touchEnded = true;
				}
				else if (touch.Phase == UITouch.TouchPhase.Cancelled)
				{
					RaiseCancelled(origin, data);
					touchEnded = true;
				}
			}

			if (touchEnded)
			{
				//iOS stops tracking all other touches when one of them releases
				for (var i = 0; i < touches.Length; i++)
				{
					var touch = touches[i];
					var pointerIndex = GetPointerIndex(touch);
					if (touch.Phase != UITouch.TouchPhase.Ended)
						RaiseReleased(rootVisual, origin, MakePointerEventData(touch, rootView, pointerIndex));
				}
				DeactivateAllTouches();
			}
		}

		static void LostCallback() { }

		static PointerEventData MakePointerEventData(UITouch touch, ObjC.Object rootView, int pointIndex)
		{
			var windowPoint = touch.LocationInView(rootView);
			return new PointerEventData()
			{
				PointIndex = pointIndex,
				WindowPoint = windowPoint,
				Timestamp = touch.Timestamp - Time.FrameTimeBase,
				PointerType = Uno.Platform.PointerType.Touch,
				IsPrimary = (pointIndex == 0),
			};
		}

		static Visual FindRoot(Visual visual)
		{
			return visual.Parent != null ? FindRoot(visual.Parent) : visual;
		}

		static void RaisePressed(Visual root, Visual visual, PointerEventData data)
		{
			try
			{
				var args = Fuse.Input.Pointer.RaisePressed(root, data);
			}
			catch(Exception e)
			{
				Fuse.AppBase.OnUnhandledExceptionInternal(e);
			}
		}

		static void RaiseMoved(Visual root, Visual visual, PointerEventData data)
		{
			try
			{
				var args = Fuse.Input.Pointer.RaiseMoved(root, data);
			}
			catch(Exception e)
			{
				Fuse.AppBase.OnUnhandledExceptionInternal(e);
			}
		}

		static void RaiseReleased(Visual root, Visual visual, PointerEventData data)
		{
			try
			{
				var args = Fuse.Input.Pointer.RaiseReleased(root, data);
			}
			catch(Exception e)
			{
				Fuse.AppBase.OnUnhandledExceptionInternal(e);
			}
		}

		static object _captureIdentity = new object();
		static void RaiseCancelled(Visual visual, PointerEventData data)
		{
			try
			{
				Fuse.Input.Pointer.LoseCapture(data.PointIndex);
			}
			catch(Exception e)
			{
				Fuse.AppBase.OnUnhandledExceptionInternal(e);
			}
		}

		public static void AddListener(Visual visual, ObjC.Object handle)
		{
			if (!handle.IsUIControl())
				throw new Exception("Can only listen to events on UIControls");

			_listeners.Add(handle, visual);
			AddListener(_eventHandler, handle);
		}

		public static void RemoveListener(Visual visual, ObjC.Object handle)
		{
			if (_listeners.ContainsKey(handle))
			{
				RemoveListener(_eventHandler, handle);
				_listeners.Remove(handle);
			}
		}

		[Foreign(Language.ObjC)]
		[Require("Source.Include", "iOS/Helpers.h")]
		static ObjC.Object CreateEventHandler(Action<ObjC.Object, ObjC.Object> callback)
		@{
			UIControlEventHandler* handler = [[UIControlEventHandler alloc] init];
			[handler setCallback: callback];
			return handler;
		@}

		[Foreign(Language.ObjC)]
		[Require("Source.Include", "UIKit/UIKit.h")]
		[Require("Source.Include", "iOS/Helpers.h")]
		static void AddListener(ObjC.Object eventHandler, ObjC.Object uicontrol)
		@{
			UIControlEventHandler* handler = (UIControlEventHandler*)eventHandler;
			::UIControl* control = (::UIControl*)uicontrol;
			[control addTarget:handler action:@selector(action:forEvent:) forControlEvents:UIControlEventAllTouchEvents];
		@}

		[Foreign(Language.ObjC)]
		[Require("Source.Include", "UIKit/UIKit.h")]
		[Require("Source.Include", "iOS/Helpers.h")]
		static void RemoveListener(ObjC.Object eventHandler, ObjC.Object uicontrol)
		@{
			UIControlEventHandler* handler = (UIControlEventHandler*)eventHandler;
			::UIControl* control = (::UIControl*)uicontrol;
			[control removeTarget:handler action:@selector(action:forEvent:) forControlEvents:UIControlEventAllTouchEvents];
		@}

	}
}