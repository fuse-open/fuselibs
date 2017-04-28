using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;
using Fuse;
using Fuse.Input;

namespace Fuse.Controls.Native.Android
{
	extern(Android) internal static class InputDispatch
	{

		internal static float2 RootOffset { get; set; }

		static readonly Dictionary<Java.Object, Visual> _listeners = new Dictionary<Java.Object, Visual>();
		static readonly HashSet<int> _activePointers = new HashSet<int>();

		static Java.Object _touchListenerHandle;
		static Java.Object TouchListener
		{
			get { return _touchListenerHandle ?? (_touchListenerHandle = CreateTouchListener()); }
		}

		static bool OnTouch(Java.Object view, Java.Object motionEvent)
		{
			if (ViewVisualMap.ContainsKey(view))
			{
				var me = new MotionEvent(motionEvent);
				var visual = (Visual)ViewVisualMap.Get(view);

				if (visual == null)
					return false;

				RaiseEvent(visual, view, me);
			}
			return false;
		}

		public static void RaiseEvent(Visual visual, Java.Object viewHandle, MotionEvent motionEvent)
		{
			var rootVisual = FindRoot(visual);

			Java.Object rootView = null;
			var rootViewport = rootVisual as NativeRootViewport;
			if (rootViewport != null)
				rootView = rootViewport.RootView.NativeHandle;

			var action = motionEvent.ActionMasked;
			var data = motionEvent.PointerEventDataForView(rootView, viewHandle, visual.Viewport.PixelsPerPoint);

			switch (action)
			{
			case 3: // android.view.MotionEvent.ACTION_CANCEL:
				for (var i = 0; i < data.Length; i++)
					RaiseReleased(rootVisual, visual, data[i]);
				break;

			case 0: // android.view.MotionEvent.ACTION_DOWN:
			case 5: // android.view.MotionEvent.ACTION_POINTER_DOWN:
				for (var i = 0; i < data.Length; i++)
					RaisePressed(rootVisual, visual, data[i]);
				break;

			case 2: // android.view.MotionEvent.ACTION_MOVE:
				for (var i = 0; i < data.Length; i++)
					RaiseMoved(rootVisual, visual, data[i]);
				break;

			case 1: // android.view.MotionEvent.ACTION_UP:
			case 6: // android.view.MotionEvent.ACTION_POINTER_UP:
				{
					/// Uhhh... android why
					int pointerMask = MotionEvent.PointerIndexMask;
					int pointerShit = MotionEvent.PointerIndexShift;
					int pointerIndex = (motionEvent.Action & pointerMask) >> pointerShit;
					RaiseReleased(rootVisual, visual, data[pointerIndex]);
				}
				break;
			}
		}

		static bool IsPointerActive(int pointerId)
		{
			if (!_activePointers.Contains(pointerId))
			{
				_activePointers.Add(pointerId);
				return false;
			}
			return true;
		}

		static void DeactivatePointer(int pointerId)
		{
			if (_activePointers.Contains(pointerId))
				_activePointers.Remove(pointerId);
		}

		static void RaisePressed(Visual rootVisual, Visual visual, PointerEventData data)
		{
			if (IsPointerActive(data.PointIndex))
				return;

			try
			{
				Fuse.Input.Pointer.RaisePressed(rootVisual, data);
			}
			catch (Exception e)
			{
				Fuse.AppBase.OnUnhandledExceptionInternal(e);
			}
		}

		static void RaiseMoved(Visual rootVisual, Visual visual, PointerEventData data)
		{
			try
			{
				Fuse.Input.Pointer.RaiseMoved(rootVisual, data);
			}
			catch (Exception e)
			{
				Fuse.AppBase.OnUnhandledExceptionInternal(e);
			}
		}

		static void RaiseReleased(Visual rootVisual, Visual visual, PointerEventData data)
		{
			DeactivatePointer(data.PointIndex);
			try
			{
				Fuse.Input.Pointer.RaiseReleased(rootVisual, data);
			}
			catch (Exception e)
			{
				Fuse.AppBase.OnUnhandledExceptionInternal(e);
			}
		}

		/*static readonly object _captureIdentiy = new object();
		static void RaiseCancel(Visual visual, PointerEventData data)
		{
			DeactivatePointer(data.PointIndex);
			try
			{
				if (Fuse.Input.Pointer.HardCapture(data.PointIndex, visual, _captureIdentiy, LostCallback))
					Fuse.Input.Pointer.ReleaseHardCapture(data.PointIndex);
			}
			catch (Exception e)
			{
				Fuse.AppBase.OnUnhandledExceptionInternal(e);
			}
		}

		static void LostCallback() { }*/

		static JavaMap _viewVisualMap;
		static JavaMap ViewVisualMap
		{
			get { return _viewVisualMap ?? (_viewVisualMap = new JavaMap()); }
		}

		public static void AddListener(Java.Object nativeHandle, Visual owner)
		{
			ViewVisualMap.Put(nativeHandle, owner);
			SetOnTouchListener(nativeHandle, TouchListener);
		}

		public static void AddListener(ViewHandle viewHandle, Visual owner)
		{
			AddListener(viewHandle.NativeHandle, owner);
		}

		public static void RemoveListener(Java.Object nativeHandle)
		{
			ViewVisualMap.Remove(nativeHandle);
			ClearOnTouchListener(nativeHandle);
		}

		public static void RemoveListener(ViewHandle viewHandle)
		{
			RemoveListener(viewHandle.NativeHandle);
		}

		static Visual FindRoot(Visual visual)
		{
			return visual.Parent != null ? FindRoot(visual.Parent) : visual;
		}

		[Foreign(Language.Java)]
		static Java.Object CreateTouchListener()
		@{
			return new android.view.View.OnTouchListener() {
					public boolean onTouch(android.view.View view, android.view.MotionEvent e) {
						return @{OnTouch(Java.Object,Java.Object):Call(view, e)};
					}
				};
		@}

		[Foreign(Language.Java)]
		static void SetOnTouchListener(Java.Object viewHandle, Java.Object listenerHandle)
		@{
			((android.view.View)viewHandle).setOnTouchListener(((android.view.View.OnTouchListener)listenerHandle));
		@}

		[Foreign(Language.Java)]
		static void ClearOnTouchListener(Java.Object viewHandle)
		@{
			((android.view.View)viewHandle).setOnTouchListener(null);
		@}

	}

	[ForeignInclude(Language.Java, "java.util.HashMap")]
	[ForeignInclude(Language.Java, "java.util.Map")]
	extern(Android) class JavaMap
	{
		readonly Java.Object _handle;

		public JavaMap()
		{
			_handle = Create();
		}

		public void Put(Java.Object key, object value)
		{
			Put(_handle, key, value);
		}

		public void Remove(Java.Object key)
		{
			Remove(_handle, key);
		}

		public bool ContainsKey(Java.Object key)
		{
			return ContainsKey(_handle, key);
		}

		public object Get(Java.Object key)
		{
			return (object)Get(_handle, key);
		}

		[Foreign(Language.Java)]
		static Java.Object Create()
		@{
			return new HashMap<Object, Object>();
		@}

		[Foreign(Language.Java)]
		static void Put(Java.Object handle, Java.Object key, object value)
		@{
			@SuppressWarnings("unchecked")
			Map<Object, Object> map = (Map<Object, Object>)handle;
			map.put(key, value);
		@}

		[Foreign(Language.Java)]
		static void Remove(Java.Object handle, Java.Object key)
		@{
			@SuppressWarnings("unchecked")
			Map<Object, Object> map = (Map<Object, Object>)handle;
			map.remove(key);
		@}

		[Foreign(Language.Java)]
		static bool ContainsKey(Java.Object handle, Java.Object key)
		@{
			@SuppressWarnings("unchecked")
			Map<Object, Object> map = (Map<Object, Object>)handle;
			return map.containsKey(key);
		@}

		[Foreign(Language.Java)]
		static object Get(Java.Object handle, Java.Object key)
		@{
			@SuppressWarnings("unchecked")
			Map<Object, Object> map = (Map<Object, Object>)handle;
			return map.get(key);
		@}

	}

	extern(Android) public class MotionEvent
	{

		readonly Java.Object _handle;

		public MotionEvent(Java.Object handle)
		{
			_handle = handle;
		}

		public int GetPointerId(int pointerIndex)
		{
			return GetPointerId(_handle, pointerIndex);
		}

		public int ActionMasked
		{
			get { return GetActionMasked(_handle); }
		}

		public int Action
		{
			get { return GetAction(_handle); }
		}

		public long EventTime
		{
			get { return GetEventTime(_handle); }
		}

		public int PointerCount
		{
			get { return GetPointerCount(_handle); }
		}

		public float2 GetPosition(int pointerIndex)
		{
			return float2(GetX(_handle, pointerIndex), GetY(_handle, pointerIndex));
		}

		public PointerEventData[] PointerEventDataForView(Java.Object rootView, Java.Object view, float pointDensity)
		{
			var pointerEventData = new PointerEventData[PointerCount];
			var locationOnScreen = GetLocationOnScreen(view) - GetLocationOnScreen(rootView);

			for (var i = 0; i < pointerEventData.Length; i++)
			{
				var windowPoint = (locationOnScreen + GetPosition(i)) / pointDensity;
				var pointerId = GetPointerId(i);

				pointerEventData[i] = new PointerEventData()
				{
					PointIndex = pointerId,
					WindowPoint = windowPoint,
					Timestamp = (EventTime / 1000.0) - Time.FrameTimeBase,
					PointerType = Uno.Platform.PointerType.Touch,
					IsPrimary = (pointerId == 0),
				};
			}

			return pointerEventData;
		}

		public override bool Equals(object obj)
		{
			if (obj is MotionEvent)
			{
				return Compare(_handle, ((MotionEvent)obj)._handle);
			}
			else
			{
				return false;
			}
		}

		static int[] _locationOnScreen = new int[2];
		float2 GetLocationOnScreen(Java.Object viewHandle)
		{
			GetLocationOnScreen(viewHandle, _locationOnScreen);
			return float2(_locationOnScreen[0], _locationOnScreen[1]);
		}

		[Foreign(Language.Java)]
		void GetLocationOnScreen(Java.Object viewHandle, int[] result)
		@{
			int[] array = new int[2];
			((android.view.View)viewHandle).getLocationOnScreen(array);
			result.set(0, array[0]);
			result.set(1, array[1]);
		@}

		[Foreign(Language.Java)]
		int GetAction(Java.Object handle)
		@{
			return ((android.view.MotionEvent)handle).getAction();
		@}

		[Foreign(Language.Java)]
		int GetPointerId(Java.Object handle, int pointerIndex)
		@{
			return ((android.view.MotionEvent)handle).getPointerId(pointerIndex);
		@}

		[Foreign(Language.Java)]
		int GetActionMasked(Java.Object handle)
		@{
			return ((android.view.MotionEvent)handle).getActionMasked();
		@}

		[Foreign(Language.Java)]
		long GetEventTime(Java.Object handle)
		@{
			return ((android.view.MotionEvent)handle).getEventTime();
		@}

		[Foreign(Language.Java)]
		int GetPointerCount(Java.Object handle)
		@{
			return ((android.view.MotionEvent)handle).getPointerCount();
		@}

		[Foreign(Language.Java)]
		float GetX(Java.Object handle, int pointerIndex)
		@{
			return ((android.view.MotionEvent)handle).getX(pointerIndex);
		@}

		[Foreign(Language.Java)]
		float GetY(Java.Object handle, int pointerIndex)
		@{
			return ((android.view.MotionEvent)handle).getY(pointerIndex);
		@}

		[Foreign(Language.Java)]
		float GetXPrecision(Java.Object handle)
		@{
			return ((android.view.MotionEvent)handle).getXPrecision();
		@}

		[Foreign(Language.Java)]
		float GetYPrecision(Java.Object handle)
		@{
			return ((android.view.MotionEvent)handle).getYPrecision();
		@}

		public static int PointerIndexMask
		{
			get { return GetPointerIndexMask(); }
		}

		public static int PointerIndexShift
		{
			get { return GetPointerIndexShift(); }
		}

		[Foreign(Language.Java)]
		static int GetPointerIndexMask()
		@{
			return android.view.MotionEvent.ACTION_POINTER_INDEX_MASK;
		@}

		[Foreign(Language.Java)]
		static int GetPointerIndexShift()
		@{
			return android.view.MotionEvent.ACTION_POINTER_INDEX_SHIFT;
		@}

		[Foreign(Language.Java)]
		static bool Compare(Java.Object handle1, Java.Object handle2)
		@{
			return (((android.view.MotionEvent)handle1) == ((android.view.MotionEvent)handle2));
		@}

	}
}
