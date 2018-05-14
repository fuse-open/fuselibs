using Uno;
using Uno.Compiler.ExportTargetInterop;
using Fuse;
using Fuse.Reactive;
using Fuse.Controls;
using Fuse.Controls.Native;
using Uno.Collections;

namespace Fuse.Views
{
	extern(iOS)
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

	[Require("Source.Include", "UIKit/UIKit.h")]
	[Require("Source.Include", "iOS/ViewHost.h")]
	[Require("Source.Include", "@{float2:Include}")]
	extern(iOS)
	internal class View : IFrame
	{
		public ObjC.Object GetNativeView()
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

		RootViewport _rootViewport;
		TreeRendererPanel _renderPanel;

		Visual _visual;

		DataContext _dataContext;

		public View(Visual visual)
		{
			_nativeView = new ViewHandle(InitNativeView(
				SizeThatFits,
				SetFrame,
				HandleInputEvent,
				SetDataJson,
				SetDataString,
				SetCallback));

			_visual = visual;

			_rootViewport = new NativeRootViewport(_nativeView, this);
			_renderPanel = new TreeRendererPanel(new Root(_nativeView));

			_rootViewport.Children.Add(_renderPanel);
			_renderPanel.Children.Add(_visual);


			_dataContext = new DataContext(_renderPanel);
		}

		float2 SizeThatFits(float2 size)
		{
			var hasX = true;
			var hasY = true;
			var width = 0.0f;
			var height = 0.0f;

			width = size.X;
			height = size.Y;

			var lp = LayoutParams.CreateXY(float2(width, height), hasX, hasY);

			if (hasX)
				lp.ConstrainMaxX(width);

			if (hasY)
				lp.ConstrainMaxY(height);

			var measuredSize = _renderPanel.GetMarginSize(lp);
			return measuredSize;
		}

		void SetFrame(float2 pos, float2 size)
		{
			var pixelSize = size * _rootViewport.PixelsPerPoint;
			_size = pixelSize;
			if (FrameChanged != null)
				FrameChanged(this, EventArgs.Empty);
		}

		void HandleInputEvent(ObjC.Object s, ObjC.Object e)
		{
		}

		void SetDataJson(string json)
		{
			_dataContext.SetDataJson(json);
		}

		void SetDataString(string value, string key)
		{
			_dataContext.SetDataString(key, value);
		}

		[Require("Source.Include", "iOS/ArgumentsImpl.h")]
		class CallbackClosure : IEventHandler
		{
			Action<ObjC.Object> _callback;

			public CallbackClosure(Action<ObjC.Object> callback)
			{
				_callback = callback;
			}

			void IEventHandler.Dispatch(IEventRecord e)
			{
				_callback(NewObjCEventRecord(e));
			}

			[Foreign(Language.ObjC)]
			static ObjC.Object NewObjCEventRecord(object e)
			@{
				ArgumentsImpl* args = [[ArgumentsImpl alloc] init];
				[args setGetArgsHandler: ^id () {
					return @{CallbackClosure.GetArgs(object):Call(e)};
				}];
				[args setGetDataJsonHandler: ^id () {
					return @{CallbackClosure.SerializeData(object):Call(e)};
				}];
				return args;
			@}

			static string SerializeData(object eventRecord)
			{
				var e = (IEventRecord)eventRecord;
				return e.Data != null? Fuse.Json.Stringify(e.Data) : "{}";
			}

			static ObjC.Object GetArgs(object eventRecord)
			{
				var e = (IEventRecord)eventRecord;
				var nsDict = NewNSDictionary();
				foreach (var a in e.Args)
					InsertKeyValue(nsDict, a.Key, Fuse.Json.Stringify(a.Value));
				return nsDict;
			}

			[Foreign(Language.ObjC)]
			static ObjC.Object NewNSDictionary()
			@{
				return [[NSMutableDictionary<NSString*,NSString*> alloc] init];
			@}

			[Foreign(Language.ObjC)]
			static void InsertKeyValue(ObjC.Object nsDict, string key, string value)
			@{
				NSMutableDictionary<NSString*,NSString*>* d = (NSMutableDictionary<NSString*,NSString*>*)nsDict;
				[d setObject:value forKey:key];
			@}

		}

		void SetCallback(Action<ObjC.Object> callback, string key)
		{
			_dataContext.SetCallback(key, new CallbackClosure(callback));
		}

		[Foreign(Language.ObjC)]
		ObjC.Object InitNativeView(
			Func<float2,float2> sizeThatFitsCallback,
			Action<float2,float2> setFrameCallback,
			Action<ObjC.Object,ObjC.Object> inputHandler,
			Action<string> setDataJsonHandler,
			Action<string,string> setDataStringHandler,
			Action<Action<ObjC.Object>,string> setCallbackHandler)
		@{
			ViewHost* viewHost = [[ViewHost alloc] init];

			[viewHost setSizeThatFitsHandler:^CGSize (CGSize size) {
				float width = (float)size.width;
				float height = (float)size.height;
				auto result = sizeThatFitsCallback(@{float2(float,float):New(width,height)});
				return CGSizeMake(result.X, result.Y);
			}];

			[viewHost setSetFrameHandler:^void(CGRect frame) {
				auto x = frame.origin.x;
				auto y = frame.origin.y;
				auto width = frame.size.width;
				auto height = frame.size.height;
				auto pos = @{float2(float,float):New(x,y)};
				auto size = @{float2(float,float):New(width,height)};
				setFrameCallback(pos, size);
			}];

			[viewHost setInputEventHandler:^void(id s,id e) {
				inputHandler(s, e);
			}];

			[viewHost setSetDataJsonHandler:setDataJsonHandler];
			[viewHost setSetDataStringHandler:setDataStringHandler];
			[viewHost setSetCallbackHandler:^void(::Callback cb, NSString* key) {
				setCallbackHandler(cb, key);
			}];
			return viewHost;
		@}

	}
}
