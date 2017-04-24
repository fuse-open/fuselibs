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
			if (IsUIControl(sender) && IsUIEvent(uiEvent))
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
			if (IsUIEvent(uiEvent))
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
			if (!IsUIControl(handle))
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
		[Require("Source.Include", "UIKit/UIKit.h")]
		public static bool IsUIControl(ObjC.Object handle)
		@{
			NSObject* obj = (NSObject*)handle;
			return [obj isKindOfClass:[UIControl class]];
		@}

		[Foreign(Language.ObjC)]
		[Require("Source.Include", "UIKit/UIKit.h")]
		static bool IsUIEvent(ObjC.Object handle)
		@{
			NSObject* obj = (NSObject*)handle;
			return [obj isKindOfClass:[::UIEvent class]];
		@}

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