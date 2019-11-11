using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Uno.UX;
using Fuse.Controls.Native;

namespace Fuse
{
	[Require("Source.Include", "UIKit/UIKit.h")]
	[Require("Source.Include", "@{Fuse.Platform.SystemUI:Include}")]
	extern(iOS) internal static class AppRoot
	{

		public static ObjC.Object Handle { get { return _appRootView; } }

		static readonly ObjC.Object _appRootView;

		static AppRoot()
		{
			_appRootView = CreateAppRootView(Fuse.Controls.Native.iOS.FocusHelpers.KeyboardView.Handle);
			SetClearColor(_appRootView, _clearColor.X, _clearColor.Y, _clearColor.Z, _clearColor.W);
		}

		[Foreign(Language.ObjC)]
		static ObjC.Object CreateAppRootView(ObjC.Object handle)
		@{
			UIControl* root = (UIControl*)handle;
			[root setUserInteractionEnabled: true];
			[root setMultipleTouchEnabled: true];
			[root setOpaque: false];
			[[root layer] setAnchorPoint: { 0.0f, 0.0f }];
			@{Fuse.Platform.SystemUI.RootView:Set(root)};
			[root sizeToFit];
			root.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
			
			return root;
		@}

		
		static float4 _clearColor = float4(1f);
		public static float4 ClearColor
		{
			get { return _clearColor; }
			set
			{
				if (_clearColor == value)
					return;
					
				_clearColor = value;
				SetClearColor(_appRootView, value.X, value.Y, value.Z, value.W);
			}
		}

		[Foreign(Language.ObjC)]
		static void SetClearColor(ObjC.Object handle, float r, float g, float b, float a)
		@{
			UIView* view = (UIView*)handle;
			[view setBackgroundColor: [UIColor colorWithRed:(CGFloat)r green: (CGFloat)g blue:(CGFloat)b alpha:(CGFloat)a]];
		@}

		static ViewHandle _root;
		public static void SetRootView(ViewHandle root)
		{
			if (_root != null)
				throw new Exception("Root already set to: " + _root);

			_root = root;
			Set(_appRootView, _root.NativeHandle);
		}

		public static void ClearRoot(ViewHandle root)
		{
			if (_root == null || root != _root)
				throw new Exception(root + " not set as root");

			Remove(_root.NativeHandle);
			_root = null;
		}

		[Foreign(Language.ObjC)]
		static void Set(ObjC.Object handle, ObjC.Object childHandle)
		@{
			UIView* parent = (UIView*)handle;
			UIView* child = (UIView*)childHandle;
			[parent addSubview: child];
		@}

		[Foreign(Language.ObjC)]
		static void Remove(ObjC.Object childHandle)
		@{
			UIView* child = (UIView*)childHandle;
			[child removeFromSuperview];
		@}

	}

}