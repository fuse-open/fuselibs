using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Uno.UX;

namespace Fuse.Controls.Native.iOS
{
	using Fuse.Input;

	[TargetSpecificImplementation]
	[Require("Source.Include", "iOS/UIViewInputDispatch.h")]
	extern(iOS) internal static class InputDispatch
	{
		public static void OnTouchesBegan(Visual origin, ObjC.Object touches)
		{
			var rootInfo = GetRootInfo(origin);
			foreach (var data in MakePointerEventData(touches, rootInfo.RootView))
				RaisePressed(rootInfo.RootVisual, data);
		}

		public static void OnTouchesMoved(Visual origin, ObjC.Object touches)
		{
			var rootInfo = GetRootInfo(origin);
			foreach (var data in MakePointerEventData(touches, rootInfo.RootView))
				RaiseMoved(rootInfo.RootVisual, data);
		}

		public static void OnTouchesEnded(Visual origin, ObjC.Object touches)
		{
			var rootInfo = GetRootInfo(origin);
			var count = NSArrayCount(touches);
			for (var i = 0; i < count; i++)
			{
				var uiTouch = NSArrayObjectAtIndex(touches, i);
				RaiseReleased(rootInfo.RootVisual, NewPointerEventData(uiTouch, rootInfo.RootView));
				DeactivateTouch(uiTouch);
			}
		}

		public static void OnTouchesCancelled(Visual origin, ObjC.Object touches)
		{
			var rootInfo = GetRootInfo(origin);
			var count = NSArrayCount(touches);
			for (var i = 0; i < count; i++)
			{
				var uiTouch = NSArrayObjectAtIndex(touches, i);
				RaiseCancelled(rootInfo.RootVisual, NewPointerEventData(uiTouch, rootInfo.RootView));
				DeactivateTouch(uiTouch);
			}
		}

		[Foreign(Language.ObjC)]
		public static void AddInputHandler(Visual owner, ViewHandle viewHandle)
		@{
			UIView* view = (UIView*)@{Fuse.Controls.Native.ViewHandle:Of(viewHandle).HitTestHandle:Get()};
			addInputHandler(view, ^void(int type, id<UnoObject> visual, id touches) {
				switch(type)
				{
					case EVENTTYPE_PRESSED:
						@{InputDispatch.OnTouchesBegan(Visual,ObjC.Object):Call(visual, touches)};
						break;
					case EVENTTYPE_MOVED:
						@{InputDispatch.OnTouchesMoved(Visual,ObjC.Object):Call(visual, touches)};
						break;
					case EVENTTYPE_RELEASED:
						@{InputDispatch.OnTouchesEnded(Visual,ObjC.Object):Call(visual, touches)};
						break;
					case EVENTTYPE_CANCELLED:
						@{InputDispatch.OnTouchesCancelled(Visual,ObjC.Object):Call(visual, touches)};
						break;
					default:
						break;
				}
			}, owner);
		@}

		[Foreign(Language.ObjC)]
		public static void RemoveInputHandler(ViewHandle viewHandle)
		@{
			UIView* view = (UIView*)@{Fuse.Controls.Native.ViewHandle:Of(viewHandle).HitTestHandle:Get()};
			removeInputHandler(view);
		@}

		struct RootInfo
		{
			public readonly Visual RootVisual;
			public readonly ObjC.Object RootView;

			public RootInfo(Visual rootVisual, ObjC.Object rootView)
			{
				RootVisual = rootVisual;
				RootView = rootView;
			}
		}

		static RootInfo GetRootInfo(Visual origin)
		{
			var rootVisual = FindRoot(origin);
			ObjC.Object rootView = null;
			var rootViewport = rootVisual as NativeRootViewport;
			if (rootViewport != null)
				rootView = rootViewport.RootView.NativeHandle;
			return new RootInfo(rootVisual, rootView);
		}

		static List<ObjC.Object> _activePointers = new List<ObjC.Object>();

		static int GetPointIndex(ObjC.Object uiTouch)
		{
			var firstUnused = -1;
			for (var i = 0; i < _activePointers.Count; ++i)
			{
				var pointer = _activePointers[i];
				if (CompareUITouch(pointer, null) && firstUnused < 0)
					firstUnused = i;
				else if (CompareUITouch(pointer, uiTouch))
					return i;
			}
			if (firstUnused < 0)
			{
				_activePointers.Add(uiTouch);
				firstUnused = _activePointers.Count - 1;
			}
			_activePointers[firstUnused] = uiTouch;
			return firstUnused;
		}

		static void DeactivateTouch(ObjC.Object uiTouch)
		{
			for (var i = 0; i < _activePointers.Count; i++)
			{
				if (CompareUITouch(_activePointers[i], uiTouch))
				{
					_activePointers[i] = null;
					return;
				}
			}
		}

		static float2 GetWindowPoint(ObjC.Object uiTouch, ObjC.Object rootView)
		{
			float x;
			float y;
			GetWindowPoint(uiTouch, rootView, out x, out y);
			return float2(x, y);
		}

		[Foreign(Language.ObjC)]
		static void GetWindowPoint(ObjC.Object uiTouch, ObjC.Object rootView, out float x, out float y)
		@{
			::UITouch* touch = (::UITouch*)uiTouch;
			UIView* relativeView = (UIView*)rootView;
			UIWindow* window = [touch window];
			CGPoint location = [touch locationInView:window];
			CGPoint localLocation = [window convertPoint:location toView:relativeView];
			*x = (float)localLocation.x;
			*y = (float)localLocation.y;
		@}

		[Foreign(Language.ObjC)]
		static double GetTimestamp(ObjC.Object uiTouch)
		@{
			::UITouch* touch = (::UITouch*)uiTouch;
			return [touch timestamp];
		@}

		[Foreign(Language.ObjC)]
		static bool CompareUITouch(ObjC.Object a, ObjC.Object b)
		@{
			return (UITouch*)a == (UITouch*)b;
		@}

		static PointerEventData[] MakePointerEventData(ObjC.Object touches, ObjC.Object rootView)
		{
			var count = NSArrayCount(touches);
			var data = new PointerEventData[count];
			for (var i = 0; i < count; i++)
				data[i] = NewPointerEventData(NSArrayObjectAtIndex(touches, i), rootView);
			return data;
		}

		static PointerEventData NewPointerEventData(ObjC.Object uiTouch, ObjC.Object rootView)
		{
			var pointIndex = GetPointIndex(uiTouch);
			return new PointerEventData()
			{
				PointIndex = pointIndex,
				WindowPoint = GetWindowPoint(uiTouch, rootView),
				Timestamp = GetTimestamp(uiTouch) - Time.FrameTimeBase,
				PointerType = Uno.Platform.PointerType.Touch,
				IsPrimary = pointIndex == 0,
			};
		}

		[Foreign(Language.ObjC)]
		static int NSArrayCount(ObjC.Object nsArray)
		@{
			return (int)((NSArray*)nsArray).count;
		@}

		[Foreign(Language.ObjC)]
		static ObjC.Object NSArrayObjectAtIndex(ObjC.Object nsArray, int index)
		@{
			return [((NSArray*)nsArray) objectAtIndex:index];
		@}

		static Visual FindRoot(Visual visual)
		{
			return visual.Parent != null ? FindRoot(visual.Parent) : visual;
		}

		static void RaisePressed(Visual root, PointerEventData data)
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

		static void RaiseMoved(Visual root, PointerEventData data)
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

		static void RaiseReleased(Visual root, PointerEventData data)
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
	}
}