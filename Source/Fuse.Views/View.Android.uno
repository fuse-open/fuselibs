using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse;
using Fuse.Reactive;
using Fuse.Controls;
using Fuse.Controls.Native;

namespace Fuse.Views
{

	extern(Android)
	class Root : INativeViewRoot
	{

		ViewHandle _nativeView;

		public Root(ViewHandle nativeView)
		{
			_nativeView = nativeView;
		}

		void INativeViewRoot.Add(ViewHandle handle)
		{
			_nativeView.InsertChild(handle);
		}

		void INativeViewRoot.Remove(ViewHandle handle)
		{
			_nativeView.RemoveChild(handle);
		}
	}

	extern(Android)
	internal class View : IFrame
	{
		enum MeasureSpecMode : uint
		{
			Unspecified = 0x00000000,
			Exactly = 0x40000000,
			AtMost = 0x80000000,
		}

		public Java.Object GetNativeView()
		{
			return _nativeView.NativeHandle;
		}

		public event EventHandler FrameChanged;

		float2 _size = float2(0.0f);
		public float2 Size
		{
			get { return _size; }
		}

		ViewHandle _nativeView;
		Java.Object _callbacks;

		RootViewport _rootViewport;
		TreeRendererPanel _renderPanel;

		Visual _visual;

		DataContext _dataContext;

		public View(Visual visual)
		{
			_callbacks = InitCallbacks();
			_nativeView = new ViewHandle(InitFuseView(_callbacks));

			_visual = visual;

			_rootViewport = new NativeRootViewport(_nativeView, this);
			_renderPanel = new TreeRendererPanel(new Root(_nativeView));

			_rootViewport.Children.Add(_renderPanel);
			_renderPanel.Children.Add(_visual);

			Fuse.Controls.Native.Android.InputDispatch.AddListener(_nativeView, _renderPanel);

			_dataContext = new DataContext(_renderPanel);
		}

		[Foreign(Language.Java)]
		int GetMeasureSpecMode(int ms) @{ return android.view.View.MeasureSpec.getMode(ms); @}

		[Foreign(Language.Java)]
		int GetMeasureSpecSize(int ms) @{ return android.view.View.MeasureSpec.getSize(ms); @}

		[Foreign(Language.Java)]
		Java.Object InitCallbacks()
		@{
			return new com.fuse.views.internal.IFuseView() {
				public void onMeasure(int widthMeasureSpec, int heightMeasureSpec, int[] result) {
					com.uno.IntArray a = @{global::Fuse.Views.View:Of(_this).OnMeasure(int,int):Call(widthMeasureSpec, heightMeasureSpec)};
					result[0] = a.get(0);
					result[1] = a.get(1);
				}
			    public void onSizeChanged(int w, int h, int oldw, int oldh) {
			    	@{global::Fuse.Views.View:Of(_this).OnSizeChanged(int,int,int,int):Call(w, h, oldw, oldh)};
			    }
			    public void onLayout(boolean changed, int left, int top, int right, int bottom) {
					@{global::Fuse.Views.View:Of(_this).OnLayout(bool,int,int,int,int):Call(changed, left, top, right, bottom)};
			    }
			    public void onAttachedToWindow() {
			    	@{global::Fuse.Views.View:Of(_this).OnAttachedToWindow():Call()};
			    }
			    public void onDetachedFromWindow() {
			    	@{global::Fuse.Views.View:Of(_this).OnDetachedFromWindow():Call()};
			    }
			    public void setDataJson(String json) {
					@{global::Fuse.Views.View:Of(_this).SetDataJson(string):Call(json)};
			    }
			    public void setDataString(String key, String value) {
					@{global::Fuse.Views.View:Of(_this).SetDataString(string,string):Call(key,value)};
			    }
			    public void setCallback(String key, com.fuse.views.ICallback callback) {
			    	@{global::Fuse.Views.View:Of(_this).SetCallback(string,Java.Object):Call(key,callback)};
			    }
			};
		@}

		[Foreign(Language.Java)]
		Java.Object InitFuseView(Java.Object iFuseView)
		@{
			return new com.fuse.views.internal.FuseView(com.fuse.Activity.getRootActivity(), (com.fuse.views.internal.IFuseView)iFuseView) {
				android.view.MotionEvent _currentEvent;

					public boolean onInterceptTouchEvent(android.view.MotionEvent motionEvent) {
						_currentEvent = motionEvent;
						return super.onInterceptTouchEvent(motionEvent);
					}

					public boolean onTouchEvent(android.view.MotionEvent motionEvent) {
						if (_currentEvent != motionEvent)
							return false;
						boolean result = super.onTouchEvent(motionEvent);
						@{global::Fuse.Views.View:Of(_this).OnTouchEvent(Java.Object):Call(motionEvent)};
						return _currentEvent == motionEvent;
					}
			};
		@}

		void OnTouchEvent(Java.Object motionEvent)
		{
			Fuse.Controls.Native.Android.InputDispatch.RaiseEvent(_renderPanel, _nativeView.NativeHandle, new Fuse.Controls.Native.Android.MotionEvent(motionEvent));
		}

		int[] OnMeasure(int widthMeasureSpec, int heightMeasureSpec)
		{
			var widthMode = (MeasureSpecMode)GetMeasureSpecMode(widthMeasureSpec);
			var heightMode = (MeasureSpecMode)GetMeasureSpecMode(heightMeasureSpec);

			var hasX = false;
			var hasY = false;
			var width = 0;
			var height = 0;

			switch (widthMode)
			{
				case MeasureSpecMode.Unspecified: break;
				case MeasureSpecMode.Exactly:
				case MeasureSpecMode.AtMost:
					hasX = true;
					width = GetMeasureSpecSize(widthMeasureSpec);
					break;
			}

			switch (heightMode)
			{
				case MeasureSpecMode.Unspecified: break;
				case MeasureSpecMode.Exactly:
				case MeasureSpecMode.AtMost:
					hasY = true;
					height = GetMeasureSpecSize(heightMeasureSpec);
					break;
			}

			var density = _rootViewport.PixelsPerPoint;
			var size = float2(width / density, height / density);
			var lp = LayoutParams.CreateXY(size, hasX, hasY);

			if (hasX)
				lp.ConstrainMaxX(size.X);

			if (hasY)
				lp.ConstrainMaxY(size.Y);

			var measuredSize = _renderPanel.GetMarginSize(lp);
			var pixelSize = (int2)(measuredSize * density);

			return new [] { pixelSize.X, pixelSize.Y };
		}

		void OnSizeChanged(int w, int h, int oldw, int oldh)
		{
			_size = (float2)int2(w, h);
			if (FrameChanged != null)
				FrameChanged(this, EventArgs.Empty);
		}

		void OnLayout(bool changed, int left, int top, int right, int bottom)
		{
		}

		void SetDataJson(string json)
		{
			_dataContext.SetDataJson(json);
		}

		void SetDataString(string key, string value)
		{
			_dataContext.SetDataString(key, value);
		}

		class CallbackClosure : IEventHandler
		{
			Java.Object _callback;

			public CallbackClosure(Java.Object callback)
			{
				_callback = callback;
			}

			void IEventHandler.Dispatch(IEventRecord e)
			{
				InvokeCallback(_callback, e);
			}

			[Foreign(Language.Java)]
			void InvokeCallback(Java.Object callback, object eventRecord)
			@{
				com.fuse.views.ICallback x = (com.fuse.views.ICallback)callback;
				x.invoke(new com.fuse.views.IArguments() {
					public java.util.HashMap<String,String> getArgs() {
						return (java.util.HashMap<String,String>)@{CallbackClosure.MakeArgs(object):Call(eventRecord)};
					}
					public String getDataJson() {
						return @{CallbackClosure.SerializeData(object):Call(eventRecord)};
					}
				});
			@}

			static Java.Object MakeArgs(object eventRecord)
			{
				var e = (IEventRecord)eventRecord;
				var hashMap = NewHashMap();
				foreach (var a in e.Args)
					InsertKeyValue(hashMap, a.Key, Fuse.Json.Stringify(a.Value));
				return hashMap;
			}

			[Foreign(Language.Java)]
			static Java.Object NewHashMap()
			@{
				return new java.util.HashMap<String,String>();
			@}

			[Foreign(Language.Java)]
			static void InsertKeyValue(Java.Object hashMap, string key, string value)
			@{
				((java.util.HashMap<String,String>)hashMap).put(key, value);
			@}

			static string SerializeData(object eventRecord)
			{
				var e = (IEventRecord)eventRecord;
				return e.Data != null? Fuse.Json.Stringify(e.Data) : "{}";
			}
		}

		void SetCallback(string key, Java.Object callback)
		{
			_dataContext.SetCallback(key, new CallbackClosure(callback));
		}

		void OnAttachedToWindow()
		{
			// OnRooted
		}

		void OnDetachedFromWindow()
		{
			// OnUnrooted
		}

	}
}
