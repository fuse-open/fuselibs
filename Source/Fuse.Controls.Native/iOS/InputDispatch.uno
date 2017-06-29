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
			RaiseEvent(EventType.Pressed, origin, touches);
		}

		public static void OnTouchesMoved(Visual origin, ObjC.Object touches)
		{
			RaiseEvent(EventType.Moved, origin, touches);
		}

		public static void OnTouchesEnded(Visual origin, ObjC.Object touches)
		{
			RaiseEvent(EventType.Released, origin, touches);
		}

		public static void OnTouchesCancelled(Visual origin, ObjC.Object touches)
		{
			RaiseEvent(EventType.Cancelled, origin, touches);
		}

		[Foreign(Language.ObjC)]
		public static void AddInputHandler(Visual owner, ViewHandle viewHandle)
		@{
			UIView* view = (UIView*)@{Fuse.Controls.Native.ViewHandle:Of(viewHandle).HitTestHandle:Get()};
			addInputHandler(view, ^void(int type, id<UnoObject> visual, id touches) { @{Fuse.Controls.Native.iOS.InputDispatch.RaiseEvent(int,object,ObjC.Object):Call(type,visual,touches)}; }, owner);
		@}

		[Foreign(Language.ObjC)]
		public static void RemoveInputHandler(ViewHandle viewHandle)
		@{
			UIView* view = (UIView*)@{Fuse.Controls.Native.ViewHandle:Of(viewHandle).HitTestHandle:Get()};
			removeInputHandler(view);
		@}

		static void RaiseEvent(int eventType, object origin, ObjC.Object touches)
		{
			RaiseEvent((EventType)eventType, (Visual)origin, touches);
		}

		enum EventType : int
		{
			Pressed = 0,
			Moved = 1,
			Released = 2,
			Cancelled = 3,
		}

		static readonly Action<Visual,PointerEventData>[] _handlers = new Action<Visual,PointerEventData>[] {
			RaisePressed,
			RaiseMoved,
			RaiseReleased,
			RaiseCancelled,
		};

		static void RaiseEvent(EventType type, Visual origin, ObjC.Object touches)
		{
			var rootInfo = GetRootInfo(origin);
			var count = NSArrayCount(touches);
			var handler = _handlers[(int)type];
			var deactivate = ((int)type) > ((int)EventType.Moved);
			for (var i = 0; i < count; i++)
			{
				var uiTouch = NSArrayObjectAtIndex(touches, i);
				handler(rootInfo.RootVisual, NewPointerEventData(uiTouch, rootInfo.RootView));
				if (deactivate)
					DeactivateTouch(uiTouch);
			}
		}

		class RootInfo
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

		const int PointerCount = 10;

		static ObjC.Object[] _activePointers = new ObjC.Object[PointerCount];

		static int GetPointIndex(ObjC.Object uiTouch)
		{
			var availableIndex = -1;
			for (var i = PointerCount; i-- > 0;)
			{
				var pointer = _activePointers[i];
				if (CompareUITouch(pointer, null))
					availableIndex = i;
				else if (CompareUITouch(pointer, uiTouch))
					return i;
			}
			_activePointers[availableIndex] = uiTouch;
			return availableIndex;
		}

		static void DeactivateTouch(ObjC.Object uiTouch)
		{
			for (var i = 0; i < PointerCount; i++)
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
			float x = 0.0f;
			float y = 0.0f;
			GetWindowPoint(uiTouch, rootView, extern<IntPtr>"&x", extern<IntPtr>"&y");
			return float2(x, y);
		}

		[Foreign(Language.ObjC)]
		static void GetWindowPoint(ObjC.Object uiTouch, ObjC.Object rootView, IntPtr x, IntPtr y)
		@{
			::UITouch* touch = (::UITouch*)uiTouch;
			UIView* relativeView = (UIView*)rootView;
			UIWindow* window = [touch window];
			CGPoint location = [touch locationInView:window];
			CGPoint localLocation = [window convertPoint:location toView:relativeView];
			*((float*)x) = (float)localLocation.x;
			*((float*)y) = (float)localLocation.y;
		@}

		[Foreign(Language.ObjC)]
		static double GetTimestamp(ObjC.Object uiTouch)
		@{
			::UITouch* touch = (::UITouch*)uiTouch;
			return [touch timestamp];
		@}

		[Foreign(Language.ObjC)]
		static bool CompareUITouch(ObjC.Object x, ObjC.Object y)
		@{
			UITouch* touch1 = (UITouch*)x;
			UITouch* touch2 = (UITouch*)y;
			return x == y;
		@}

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