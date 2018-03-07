using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Controls.Native.iOS
{

	extern(iOS) internal interface INativeFocusListener
	{
		void FocusGained();
		void FocusLost();
	}

	extern(iOS) internal static class NativeFocus
	{

		static readonly Dictionary<ObjC.Object, INativeFocusListener> _listeners =
			new Dictionary<ObjC.Object, INativeFocusListener>();

		public static void AddListener(ObjC.Object handle, INativeFocusListener listener)
		{
			_listeners.Add(handle, listener);
		}

		public static void RemoveListener(ObjC.Object handle)
		{
			_listeners.Remove(handle);
		}

		public static void RaiseFocusGained(ObjC.Object handle)
		{
			INativeFocusListener listener;
			if (_listeners.TryGetValue(handle, out listener))
			{
				listener.FocusGained();
			}
		}

		public static void RaiseFocusLost(ObjC.Object handle)
		{
			INativeFocusListener listener;
			if (_listeners.TryGetValue(handle, out listener))
			{
				listener.FocusLost();
			}
		}
	}

	[Require("Source.Include", "UIKit/UIKit.h")]
	[Require("Source.Include", "iOS/Helpers.h")]
	extern(iOS) internal static class FocusHelpers
	{

		static FocusHelpers()
		{
			_keyboardView = new KeyboardView();
		}

		static readonly KeyboardView _keyboardView;
		public static KeyboardView KeyboardView
		{
			get { return _keyboardView; }
		}

		[Foreign(Language.ObjC)]
		public static void BecomeFirstResponder(ObjC.Object uiView)
		@{
			::UIView* view = (::UIView*)uiView;
			[view becomeFirstResponder];
		@}

		[Foreign(Language.ObjC)]
		public static void ResignFirstResponder(ObjC.Object uiView)
		@{
			::UIView* view = (::UIView*)uiView;
			[view resignFirstResponder];
		@}

		[Foreign(Language.ObjC)]
		public static bool IsFirstResponder(ObjC.Object handle)
		@{
			::UIView* view = (::UIView*)handle;
			return [view isFirstResponder];
		@}

		[Foreign(Language.ObjC)]
		public static ObjC.Object GetCurrentFirstResponder()
		@{
			id responder = [UIResponder currentFirstResponder];
			if ([responder isKindOfClass: [::UIView class]])
			{
				return responder;
			}
			else
			{
				return nil;
			}
		@}

		public static void ScheduleResignFirstResponder(ObjC.Object target)
		{
			KeyboardView.HoldFocus(target);
			UpdateManager.PerformNextFrame(KeyboardView.HideKeyboard);
		}

		public static void ScheduleBecomeFirstResponder(ObjC.Object target)
		{
			BecomeFirstResponder(target);
			UpdateManager.PerformNextFrame(new PerformBecomeFirstResponder(target).BecomeFirstResponder);
		}

		class PerformResignFirstResponder
		{
			ObjC.Object _target;

			public PerformResignFirstResponder(ObjC.Object target)
			{
				_target = target;
			}

			public void ResignFirstResponder()
			{
				_keyboardView.HideKeyboard();
			}
		}

		class PerformBecomeFirstResponder
		{
			ObjC.Object _target;

			public PerformBecomeFirstResponder(ObjC.Object target)
			{
				_target = target;
			}

			public void BecomeFirstResponder()
			{
				FocusHelpers.BecomeFirstResponder(_target);
			}
		}
	}
}