using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Controls.Native.iOS
{
	extern(!iOS) public class ScrollView
	{
		[UXConstructor]
		public ScrollView([UXParameter("Host")]IScrollViewHost host) { }
	}

	[Require("source.include", "iOS/Helpers.h")]
	[Require("source.include", "UIKit/UIKit.h")]
	[Require("source.include", "CoreGraphics/CoreGraphics.h")]
	extern(iOS) public class ScrollView : View, IScrollView
	{
		readonly ObjC.Object _delegateHandle;
		IScrollViewHost _host;

		public ScrollDirections AllowedScrollDirections
		{
			set { }
		}

		public bool UserScroll
		{
			set { SetUserScroll(Handle, value); }
		}

		[Foreign(Language.ObjC)]
		static void SetUserScroll(ObjC.Object handle, bool isScroll)
		@{
			::UIScrollView* scrollView = (::UIScrollView*)handle;
			scrollView.scrollEnabled = isScroll;
		@}

		public float2 ScrollPosition
		{
			set { SetContentOffset(Handle, value.X, value.Y, false); }
		}

		public float2 Goto
		{
			set { SetContentOffset(Handle, value.X, value.Y, true); }
		}

		[UXConstructor]
		public ScrollView([UXParameter("Host")]IScrollViewHost host) : base(Create())
		{
			_host = host;
			_delegateHandle = AddCallback(Handle, OnScrollViewDidScroll, OnInteractionChanged);
		}

		public override void Dispose()
		{
			_host = null;
			base.Dispose();
		}

		[Foreign(Language.ObjC)]
		static ObjC.Object Create()
		@{
			::UIScrollView* scrollView = [[::UIScrollView alloc] init];
			[scrollView setMultipleTouchEnabled:true];
			[scrollView setOpaque:true];
			scrollView.showsHorizontalScrollIndicator = false;
			scrollView.showsVerticalScrollIndicator = false;
			return  scrollView;
		@}

		[Foreign(Language.ObjC)]
		static ObjC.Object AddCallback(ObjC.Object handle, Action<ObjC.Object> callback, Action<bool> interactingCallback)
		@{
			ScrollViewDelegate* del = [[ScrollViewDelegate alloc] init];
			[del setDidScrollCallback: callback];
			[del setDidInteractinglCallback: interactingCallback];
			::UIScrollView* scrollView =  (::UIScrollView*)handle;
			[scrollView setDelegate:del];
			return del;
		@}

		void OnScrollViewDidScroll(ObjC.Object scrollViewHandle)
		{
			float x = 0.0f;
			float y = 0.0f;
			GetContentOffset(Handle, out x, out y);
			_host.OnScrollPositionChanged(float2(x, y));
		}

		void OnInteractionChanged(bool isInteracting)
		{
			_host.OnInteractionChanged(isInteracting);
		}

		internal protected override void OnSizeChanged()
		{
			var contentSize = _host.ContentSize;
			SetContentSize(Handle, contentSize.X, contentSize.Y);
		}

		[Foreign(Language.ObjC)]
		static void SetContentOffset(ObjC.Object handle, float x, float y, bool animated)
		@{
			::UIScrollView* scrollView = (::UIScrollView*)handle;
			CGPoint p = { 0 };
			p.x = (CGFloat)x;
			p.y = (CGFloat)y;
			[scrollView setContentOffset:p animated:animated];
		@}

		[Foreign(Language.ObjC)]
		static void GetContentOffset(ObjC.Object handle, out float x, out float y)
		@{
			::UIScrollView* scrollView = (::UIScrollView*)handle;
			CGPoint offset = [scrollView contentOffset];
			*x = offset.x;
			*y = offset.y;
		@}

		[Foreign(Language.ObjC)]
		static void SetContentSize(ObjC.Object handle, float w, float h)
		@{
			::UIScrollView* scrollView = (::UIScrollView*)handle;
			CGSize size = { 0 };
			size.width = (CGFloat)w;
			size.height = (CGFloat)h;
			[scrollView setContentSize:size];
		@}

		[Foreign(Language.ObjC)]
		static void GetContentSize(ObjC.Object handle, out float w, out float h)
		@{
			::UIScrollView* scrollView = (::UIScrollView*)handle;
			CGSize size = [scrollView contentSize];
			*w = (float)size.width;
			*h = (float)size.height;
		@}

	}
}