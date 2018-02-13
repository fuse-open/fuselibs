using Uno;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Controls.Native.iOS
{
	extern(iOS) internal class KeyboardView
	{
		public ObjC.Object Handle
		{
			get { return _handle; }
		}

		readonly ObjC.Object _handle;

		bool IsFocusable
		{
			get { return GetIsFocusable(_handle); }
			set { SetIsFocusable(_handle, value); }
		}

		public KeyboardView()
		{
			_handle = Create();
		}

		[Foreign(Language.ObjC)]
		[Require("Source.Include", "iOS/Helpers.h")]
		static ObjC.Object Create()
		@{
			return [[::KeyboardView alloc] init];
		@}

		public void HoldFocus(ObjC.Object focusedObject)
		{
			CopyKeyboardType(Handle, focusedObject);
			IsFocusable = true;
			FocusHelpers.BecomeFirstResponder(Handle);
			IsFocusable = false;
		}

		[Foreign(Language.ObjC)]
		[Require("Source.Include", "iOS/Helpers.h")]
		static bool GetIsFocusable(ObjC.Object handle)
		@{
			return [handle isFocusable];
		@}

		[Foreign(Language.ObjC)]
		[Require("Source.Include", "iOS/Helpers.h")]
		static void SetIsFocusable(ObjC.Object handle, bool value)
		@{
			return [handle setIsFocusable:value];
		@}

		[Foreign(Language.ObjC)]
		[Require("Source.Include", "iOS/Helpers.h")]
		static void CopyKeyboardType(ObjC.Object handle, ObjC.Object source)
		@{
			::KeyboardView* kv = (::KeyboardView*)handle;

			if (source != nil && [source isKindOfClass: [NSObject<UIKeyInput> class]])
			{
				[kv setKeyboardType: [((NSObject<UIKeyInput>*)source) keyboardType]];
				[kv setReturnKeyType: [((NSObject<UIKeyInput>*)source) returnKeyType]];
			}
			else
			{
				[kv setKeyboardType: UIKeyboardTypeDefault];
				[kv setReturnKeyType:UIReturnKeyDefault];
			}
		@}

		public void HideKeyboard()
		{
			if (FocusHelpers.IsFirstResponder(_handle))
				FocusHelpers.ResignFirstResponder(_handle);
		}
	}
	
}