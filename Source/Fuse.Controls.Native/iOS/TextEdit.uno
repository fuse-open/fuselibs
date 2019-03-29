using Fuse.Internal;
using Fuse.Input;
using Fuse.Resources;
using Uno.Compiler.ExportTargetInterop;
using Uno;

namespace Fuse.Controls.Native.iOS
{
	[Require("Source.Include", "UIKit/UIKit.h")]
	[Require("Source.Include", "iOS/Helpers.h")]
	extern(iOS) public class SingleLineTextEdit :
		LeafView,
		ITextEdit,
		INativeFocusListener
	{
		ITextEditHost _textEditHost;
		IDisposable _editingEvents;
		ObjC.Object _delegate;
		FontFaceDescriptor _descriptor;
		bool _isReadonly;

		public SingleLineTextEdit(ITextEditHost textEditHost) : base(Create())
		{
			TextEditSpeedHack.Run();
			_textEditHost = textEditHost;
			_editingEvents = UIControlEvent.AddAllEditingEventsCallback(Handle, OnTextEdit);
			_delegate = CreateDelegate(Handle, OnAction, ShouldEditingCallback);
			NativeFocus.AddListener(Handle, this);
		}

		public override void Dispose()
		{
			NativeFocus.RemoveListener(Handle);
			_editingEvents.Dispose();
			_editingEvents = null;
			_delegate = null;
			_textEditHost = null;
			base.Dispose();
		}

		bool OnAction(ObjC.Object sender)
		{
			OnValueChanged();
			return _textEditHost.OnInputAction(TextInputActionType.Primary);
		}

		bool ShouldEditingCallback(ObjC.Object sender)
		{
			return !_isReadonly;
		}

		void OnTextEdit(ObjC.Object sender, ObjC.Object args)
		{
			OnValueChanged();
		}

		void OnValueChanged()
		{
			_textEditHost.OnValueChanged(GetValue(Handle));
		}

		[Foreign(Language.ObjC)]
		static ObjC.Object Create()
		@{
			return [[::UITextField alloc] init];
		@}

		[Foreign(Language.ObjC)]
		static ObjC.Object CreateDelegate(ObjC.Object handle, Func<ObjC.Object,bool> callback, Func<ObjC.Object,bool> shouldEditingCallback)
		@{
			::UITextField* textField = (::UITextField*)handle;
			::TextFieldDelegate* textFieldDelegate = [[::TextFieldDelegate alloc] init];
			[textFieldDelegate setOnActionCallback:callback];
			[textFieldDelegate setMaxLength: INT_MAX];
			[textFieldDelegate setShouldEditingCallback:shouldEditingCallback];
			[textField setDelegate: textFieldDelegate];
			return textFieldDelegate;
		@}

		string ITextView.Value
		{
			set { SetValue(Handle, value); }
		}

		int ITextView.MaxLength
		{
			// TODO: fix the value == 0 crap
			set { SetMaxLength(_delegate, (value == 0) ? int.MaxValue : value); }
		}

		[Foreign(Language.ObjC)]
		static void SetMaxLength(ObjC.Object delegateHandle, int maxLength)
		@{
			::TextFieldDelegate* textFieldDelegate = (::TextFieldDelegate*)delegateHandle;
			[textFieldDelegate setMaxLength: maxLength];
		@}

		TextWrapping ITextView.TextWrapping
		{
			set { /* TODO */ }
		}

		float ITextView.LineSpacing
		{
			set { /* TODO */ }
		}

		float _fontSize = 12.0f;
		float ITextView.FontSize
		{
			set
			{
				if (_fontSize != value)
				{
					_fontSize = value;
					if (_descriptor != null)
					{
						SetFont(Handle, FontCache.Get(_descriptor, _fontSize));
					}
				}
			}
		}

		Font ITextView.Font
		{
			set
			{
				// We only use the first descriptor since
				// UIFonts handle font fallback cascading
				// automatically.
				if (value.Descriptors.Count > 0)
				{
					_descriptor = value.Descriptors[0];
					SetFont(Handle, FontCache.Get(_descriptor, _fontSize));
				}
			}
		}

		TextAlignment ITextView.TextAlignment
		{
			set
			{
				switch(value)
				{
					case TextAlignment.Left: SetTextAlignment(Handle, extern<int>"NSTextAlignmentLeft"); break;
					case TextAlignment.Center: SetTextAlignment(Handle, extern<int>"NSTextAlignmentCenter"); break;
					case TextAlignment.Right: SetTextAlignment(Handle, extern<int>"NSTextAlignmentRight"); break;
				}
			}
		}

		float4 ITextView.TextColor
		{
			set { SetTextColor(Handle, value.X, value.Y, value.Z, value.W); }
		}

		TextTruncation ITextView.TextTruncation
		{
			set { /* TODO */ }
		}

		bool ITextEdit.IsMultiline
		{
			set { /* TODO */ }
		}

		bool ITextEdit.IsPassword
		{
			set { SetIsPassword(Handle, value); }
		}

		bool ITextEdit.IsReadOnly
		{
			set { _isReadonly = value; }
		}

		TextInputHint ITextEdit.InputHint
		{
			set
			{
				switch (value)
				{
					case TextInputHint.Default: SetInputHint(Handle, extern<int>"UIKeyboardTypeDefault"); break;
					case TextInputHint.Email: SetInputHint(Handle, extern<int>"UIKeyboardTypeEmailAddress"); break;
					case TextInputHint.URL: SetInputHint(Handle, extern<int>"UIKeyboardTypeURL"); break;
					case TextInputHint.Phone: SetInputHint(Handle, extern<int>"UIKeyboardTypePhonePad"); break;
					case TextInputHint.Integer: SetInputHint(Handle, extern<int>"UIKeyboardTypeNumberPad"); break;
					case TextInputHint.Decimal: SetInputHint(Handle, extern<int>"UIKeyboardTypeDecimalPad"); break;
				}
			}
		}

		float4 ITextEdit.CaretColor
		{
			set { SetCaretColor(Handle, value.X, value.Y, value.Z, value.W); }
		}

		[Foreign(Language.ObjC)]
		static void SetCaretColor(ObjC.Object handle, float r, float g, float b, float a)
		@{
			::UITextField* textField = (::UITextField*)handle;
			::UIColor* color = [::UIColor colorWithRed:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b alpha:(CGFloat)a];
			[textField setTintColor:color];
		@}

		float4 ITextEdit.SelectionColor
		{
			set { }
		}

		TextInputActionStyle ITextEdit.ActionStyle
		{
			set
			{
				switch(value)
				{
					case TextInputActionStyle.Default: SetActionStyle(Handle, extern<int>"UIReturnKeyDefault"); break;
					case TextInputActionStyle.Done: SetActionStyle(Handle, extern<int>"UIReturnKeyDone"); break;
					case TextInputActionStyle.Next: SetActionStyle(Handle, extern<int>"UIReturnKeyNext"); break;
					case TextInputActionStyle.Go: SetActionStyle(Handle, extern<int>"UIReturnKeyGo"); break;
					case TextInputActionStyle.Search: SetActionStyle(Handle, extern<int>"UIReturnKeySearch"); break;
					case TextInputActionStyle.Send: SetActionStyle(Handle, extern<int>"UIReturnKeySend"); break;
				}
			}
		}

		AutoCorrectHint ITextEdit.AutoCorrectHint
		{
			set
			{
				switch (value)
				{
					case AutoCorrectHint.Disabled: SetAutoCorrectHint(Handle, extern<int>"UITextAutocorrectionTypeNo"); break;
					case AutoCorrectHint.Default: SetAutoCorrectHint(Handle, extern<int>"UITextAutocorrectionTypeDefault"); break;
					case AutoCorrectHint.Enabled: SetAutoCorrectHint(Handle, extern<int>"UITextAutocorrectionTypeYes"); break;
				}
			}
		}

		AutoCapitalizationHint ITextEdit.AutoCapitalizationHint
		{
			set
			{
				switch (value)
				{
					case AutoCapitalizationHint.None: SetAutoCapitalizationHint(Handle, extern<int>"UITextAutocapitalizationTypeNone"); break;
					case AutoCapitalizationHint.Characters: SetAutoCapitalizationHint(Handle, extern<int>"UITextAutocapitalizationTypeAllCharacters"); break;
					case AutoCapitalizationHint.Words: SetAutoCapitalizationHint(Handle, extern<int>"UITextAutocapitalizationTypeWords"); break;
					case AutoCapitalizationHint.Sentences: SetAutoCapitalizationHint(Handle, extern<int>"UITextAutocapitalizationTypeSentences"); break;
				}
			}
		}

		string _placeholderText = "";
		string ITextEdit.PlaceholderText
		{
			set
			{
				var c = _placeholderColor;
				SetPlaceholderText(Handle, (_placeholderText = value), c.X, c.Y, c.Z, c.W);
			}
		}

		float4 _placeholderColor = float4(0.0f, 0.0f, 0.0f, 1.0f);
		float4 ITextEdit.PlaceholderColor
		{
			set
			{
				var c = _placeholderColor = value;
				SetPlaceholderText(Handle, _placeholderText, c.X, c.Y, c.Z, c.W);
			}
		}

		void ITextEdit.FocusGained()
		{
			FocusHelpers.ScheduleBecomeFirstResponder(Handle);
		}

		void ITextEdit.FocusLost()
		{
			FocusHelpers.ScheduleResignFirstResponder(Handle);
		}

		void INativeFocusListener.FocusGained()
		{
			_textEditHost.OnFocusGained();
		}

		void INativeFocusListener.FocusLost()
		{
			_textEditHost.OnFocusLost();
		}

		[Foreign(Language.ObjC)]
		static void GiveFocus(ObjC.Object handle)
		@{
			::UITextField* textField = (::UITextField*)handle;
			[textField becomeFirstResponder];
		@}

		[Foreign(Language.ObjC)]
		static void SetPlaceholderText(ObjC.Object handle, string text, float r, float g, float b, float a)
		@{
			::UITextField* textField = (::UITextField*)handle;
			::UIColor* color = [::UIColor colorWithRed:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b alpha:(CGFloat)a];
  			textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:text attributes:[NSDictionary dictionaryWithObjects:@[color] forKeys:@[NSForegroundColorAttributeName]]];
		@}

		[Foreign(Language.ObjC)]
		static void SetValue(ObjC.Object handle, string value)
		@{
			::UITextField* textField = (::UITextField*)handle;
			[textField setText:value];
		@}

		[Foreign(Language.ObjC)]
		static string GetValue(ObjC.Object handle)
		@{
			::UITextField* textField = (::UITextField*)handle;
			return [textField text];
		@}

		[Foreign(Language.ObjC)]
		static void SetTextColor(ObjC.Object handle, float r, float g, float b, float a)
		@{
			::UITextField* textField = (::UITextField*)handle;
			[textField setTextColor:[::UIColor colorWithRed:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b alpha:(CGFloat)a]];
		@}

		[Foreign(Language.ObjC)]
		static void SetTextAlignment(ObjC.Object handle, int alignmnet)
		@{
			::UITextField* textField = (::UITextField*)handle;
			[textField setTextAlignment: (NSTextAlignment)alignmnet];
		@}

		[Foreign(Language.ObjC)]
		static void SetIsPassword(ObjC.Object handle, bool isPassword)
		@{
			::UITextField* textField = (::UITextField*)handle;
			BOOL isFirstResponder = textField.isFirstResponder;

			if (isFirstResponder)
				[textField resignFirstResponder];

			[textField setSecureTextEntry: isPassword];

			if (isFirstResponder)
				[textField becomeFirstResponder];
		@}

		[Foreign(Language.ObjC)]
		static void SetFont(ObjC.Object handle, ObjC.Object fontHandle)
		@{
			::UITextField* textField = (::UITextField*)handle;
			::UIFont* font = (::UIFont*)fontHandle;
			[textField setFont: font];
		@}

		[Foreign(Language.ObjC)]
		static void SetInputHint(ObjC.Object handle, int hint)
		@{
			::UITextField* textField = (::UITextField*)handle;
			[textField setKeyboardType:(UIKeyboardType)hint];
		@}

		[Foreign(Language.ObjC)]
		static void SetActionStyle(ObjC.Object handle, int style)
		@{
			::UITextField* textField = (::UITextField*)handle;
			[textField setReturnKeyType: (UIReturnKeyType)style];
		@}

		[Foreign(Language.ObjC)]
		static void SetAutoCorrectHint(ObjC.Object handle, int hint)
		@{
			::UITextField* textField = (::UITextField*)handle;
			[textField setAutocorrectionType: (UITextAutocorrectionType)hint];
		@}

		[Foreign(Language.ObjC)]
		static void SetAutoCapitalizationHint(ObjC.Object handle, int hint)
		@{
			::UITextField* textField = (::UITextField*)handle;
			[textField setAutocapitalizationType: (UITextAutocapitalizationType)hint];
		@}
	}

	[Require("Source.Include", "UIKit/UIKit.h")]
	[Require("Source.Include", "iOS/Helpers.h")]
	extern(iOS) public class MultiLineTextEdit : LeafView, ITextEdit, INativeFocusListener
	{

		internal protected override void OnSizeChanged()
		{
			UpdateContentOffset(Handle);
		}

		[Foreign(Language.ObjC)]
		static void UpdateContentOffset(ObjC.Object handle)
		@{
			// If viewSize == contentSize the contentOffset should no change.
			// However iOS sets the contentOffset if viewSize and contentSize changes
			// even if the condition above is true.
			// This prevents spastic behavior like https://github.com/fusetools/ManualTestApp/issues/334
			auto contentSize = [handle contentSize];
			auto viewSize = [handle frame].size;
			// viewSize is sometimes 0.5 smaller than contentSize
			viewSize = CGSizeMake(ceilf(viewSize.width), ceilf(viewSize.height));
			if (viewSize.width >= contentSize.width && viewSize.height >= contentSize.height)
			{
				[handle setContentOffset: CGPointMake(0.0, 0.0) animated:false];
			}
		@}

		ITextEditHost _host;
		ObjC.Object _delegate;
		FontFaceDescriptor _descriptor;
		Visual _visual;

		readonly NSAttributedStringBuilder _builder = new NSAttributedStringBuilder();

		public MultiLineTextEdit(ITextEditHost host, Visual visual) : base(Create())
		{
			TextEditSpeedHack.Run();
			_host = host;
			_visual = visual;
			_delegate = CreateDelegate(Handle, OnTextChanged, OnDidBeginEditing);
			NativeFocus.AddListener(Handle, this);
			Pointer.AddHandlers(_visual, OnPointerPressed, OnPointerMoved, OnPointerReleased);
		}

		public override void Dispose()
		{
			NativeFocus.RemoveListener(Handle);
			Pointer.RemoveHandlers(_visual, OnPointerPressed, OnPointerMoved, OnPointerReleased);
			_host = null;
			_delegate = null;
			_visual = null;
			base.Dispose();
		}

		[Foreign(Language.ObjC)]
		static ObjC.Object Create()
		@{
			::UITextView* tv = [[::UITextView alloc] init];
			[tv setBackgroundColor:[::UIColor colorWithRed:(CGFloat)0.0f green:(CGFloat)0.0f blue:(CGFloat)0.0f alpha:(CGFloat)0.0f]];
			return tv;
		@}

		[Foreign(Language.ObjC)]
		static ObjC.Object CreateDelegate(ObjC.Object handle, Action<ObjC.Object> callback, Action didBeginEditingCallback)
		@{
			::UITextView* textView = (::UITextView*)handle;
			::TextViewDelegate* del = [[::TextViewDelegate alloc] init];
			[del setTextChangedCallback: callback];
			[del setDidBeginEditingCallback: didBeginEditingCallback];
			[del setMaxLength: INT_MAX];
			[textView setDelegate:del];
			return del;
		@}

		void OnDidBeginEditing()
		{
			SetTypingAttributes(Handle, _builder.BuildAttributes());
		}

		[Foreign(Language.ObjC)]
		static void SetTypingAttributes(ObjC.Object handle, ObjC.Object typingAttributes)
		@{
			UITextView* textView = (UITextView*)handle;
			textView.typingAttributes = typingAttributes;
		@}

		void ITextEdit.FocusGained()
		{
			FocusHelpers.ScheduleBecomeFirstResponder(Handle);
			UpdateCaretPosition();
		}

		void ITextEdit.FocusLost()
		{
			FocusHelpers.ScheduleResignFirstResponder(Handle);
		}

		void INativeFocusListener.FocusGained()
		{
			_host.OnFocusGained();
		}

		void INativeFocusListener.FocusLost()
		{
			_host.OnFocusLost();
		}

		void OnTextChanged(ObjC.Object uitextView)
		{
			var value = GetValue(Handle);
			_builder.SetValue(value);
			_host.OnValueChanged(value);
		}

		int _inputFrame = -1;
		float2 _pointerPosition = float2(0.0f);
		void UpdatePointer(PointerEventArgs args)
		{
			if (args.IsPrimary)
			{
				_pointerPosition = args.WindowPoint;
				_inputFrame = UpdateManager.FrameIndex;
			}
		}

		void UpdateCaretPosition()
		{
			if (_inputFrame == UpdateManager.FrameIndex)
			{
				var p = _visual.WindowToLocal(_pointerPosition);
				SetCaretPosition(Handle, p.X, p.Y);
			}
		}

		[Foreign(Language.ObjC)]
		static void SetCaretPosition(ObjC.Object handle, float x, float y)
		@{
			UITextView* textView = (::UITextView*)handle;
			UITextPosition* textPos = [textView closestPositionToPoint: CGPointMake(x, y)];
			auto offset = [textView offsetFromPosition:textView.beginningOfDocument toPosition:textPos];
			[textView setSelectedRange:NSMakeRange(offset, 0)];
		@}

		void OnPointerPressed(object sender, PointerPressedArgs args) { UpdatePointer(args); }

		void OnPointerMoved(object sender, PointerMovedArgs args) { UpdatePointer(args); }

		void OnPointerReleased(object sender, PointerReleasedArgs args) { UpdatePointer(args); }

		string ITextView.Value
		{
			set { SetValue(Handle, _builder.SetValue(value).BuildAttributedString()); }
		}

		int ITextView.MaxLength
		{
			// TODO: fix the value == 0 crap
			set { SetMaxLength(_delegate, (value == 0) ? int.MaxValue : value); }
		}

		[Foreign(Language.ObjC)]
		static void SetMaxLength(ObjC.Object delegateHandle, int maxLength)
		@{
			::TextViewDelegate* textViewDelegate = (::TextViewDelegate*)delegateHandle;
			[textViewDelegate setMaxLength: maxLength];
		@}

		TextWrapping ITextView.TextWrapping
		{
			set { SetValue(Handle, _builder.SetTextWrapping(value).BuildAttributedString()); }
		}

		float ITextView.LineSpacing
		{
			set { SetValue(Handle, _builder.SetLineSpacing(value).BuildAttributedString()); }
		}

		float _fontSize = 12.0f;
		float ITextView.FontSize
		{
			set
			{
				if (_fontSize != value)
				{
					_fontSize = value;
					if (_descriptor != null)
						SetValue(Handle, _builder.SetFont(FontCache.Get(_descriptor, _fontSize)).BuildAttributedString());
				}
			}
		}

		Font ITextView.Font
		{
			set
			{
				// We only use the first descriptor since
				// UIFonts handle font fallback cascading
				// automatically.
				if (value.Descriptors.Count > 0)
				{
					var descriptor = value.Descriptors[0];
					_descriptor = descriptor;
					SetValue(Handle, _builder.SetFont(FontCache.Get(_descriptor, _fontSize)).BuildAttributedString());
				}
			}
		}

		TextAlignment ITextView.TextAlignment
		{
			set { SetValue(Handle, _builder.SetTextAlignment(value).BuildAttributedString()); }
		}

		float4 ITextView.TextColor
		{
			set { SetValue(Handle, _builder.SetTextColor(value).BuildAttributedString()); }
		}

		TextTruncation ITextView.TextTruncation
		{
			set { /* TODO */ }
		}

		bool ITextEdit.IsMultiline
		{
			set { SetIsMultiline(Handle, value); }
		}

		bool ITextEdit.IsPassword
		{
			set { SetIsPassword(Handle, value); }
		}

		bool ITextEdit.IsReadOnly
		{
			set { SetIsReadOnly(Handle, value); }
		}

		TextInputHint ITextEdit.InputHint
		{
			set
			{
				switch (value)
				{
					case TextInputHint.Default: SetInputHint(Handle, extern<int>"UIKeyboardTypeDefault"); break;
					case TextInputHint.Email: SetInputHint(Handle, extern<int>"UIKeyboardTypeEmailAddress"); break;
					case TextInputHint.URL: SetInputHint(Handle, extern<int>"UIKeyboardTypeURL"); break;
					case TextInputHint.Phone: SetInputHint(Handle, extern<int>"UIKeyboardTypePhonePad"); break;
					case TextInputHint.Integer: SetInputHint(Handle, extern<int>"UIKeyboardTypeNumberPad"); break;
					case TextInputHint.Decimal: SetInputHint(Handle, extern<int>"UIKeyboardTypeDecimalPad"); break;
				}
			}
		}

		float4 ITextEdit.CaretColor
		{
			set { SetCaretColor(Handle, value.X, value.Y, value.Z, value.W); }
		}

		[Foreign(Language.ObjC)]
		static void SetCaretColor(ObjC.Object handle, float r, float g, float b, float a)
		@{
			::UITextView* textView = (::UITextView*)handle;
			::UIColor* color = [::UIColor colorWithRed:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b alpha:(CGFloat)a];
			[textView setTintColor:color];
		@}

		float4 ITextEdit.SelectionColor
		{
			set { }
		}

		TextInputActionStyle ITextEdit.ActionStyle
		{
			set { /* Does not apply to MultilineTextEdit */ }
		}

		AutoCorrectHint ITextEdit.AutoCorrectHint
		{
			set
			{
				switch (value)
				{
					case AutoCorrectHint.Disabled: SetAutoCorrectHint(Handle, extern<int>"UITextAutocorrectionTypeNo"); break;
					case AutoCorrectHint.Default: SetAutoCorrectHint(Handle, extern<int>"UITextAutocorrectionTypeDefault"); break;
					case AutoCorrectHint.Enabled: SetAutoCorrectHint(Handle, extern<int>"UITextAutocorrectionTypeYes"); break;
				}
			}
		}

		AutoCapitalizationHint ITextEdit.AutoCapitalizationHint
		{
			set
			{
				switch (value)
				{
					case AutoCapitalizationHint.None: SetAutoCapitalizationHint(Handle, extern<int>"UITextAutocapitalizationTypeNone"); break;
					case AutoCapitalizationHint.Characters: SetAutoCapitalizationHint(Handle, extern<int>"UITextAutocapitalizationTypeAllCharacters"); break;
					case AutoCapitalizationHint.Words: SetAutoCapitalizationHint(Handle, extern<int>"UITextAutocapitalizationTypeWords"); break;
					case AutoCapitalizationHint.Sentences: SetAutoCapitalizationHint(Handle, extern<int>"UITextAutocapitalizationTypeSentences"); break;
				}
			}
		}

		string ITextEdit.PlaceholderText
		{
			set { /* TODO */ }
		}

		float4 ITextEdit.PlaceholderColor
		{
			set { /* TODO */ }
		}

		[Foreign(Language.ObjC)]
		static void GiveFocus(ObjC.Object handle)
		@{
			::UITextView* textView = (::UITextView*)handle;
			[textView becomeFirstResponder];
		@}

		[Foreign(Language.ObjC)]
		static void SetValue(ObjC.Object handle, ObjC.Object value)
		@{
			::UITextView* textView = (::UITextView*)handle;
			textView.attributedText = (NSAttributedString*)value;
		@}

		[Foreign(Language.ObjC)]
		static string GetValue(ObjC.Object handle)
		@{
			::UITextView* textView = (::UITextView*)handle;
			return [textView text];
		@}

		[Foreign(Language.ObjC)]
		static void SetIsReadOnly(ObjC.Object handle, bool isReadOnly)
		@{
			::UITextView* textView = (::UITextView*)handle;
			[textView setEditable: !isReadOnly];
		@}

		[Foreign(Language.ObjC)]
		static void SetIsPassword(ObjC.Object handle, bool isPassword)
		@{
			::UITextView* textView = (::UITextView*)handle;
			[textView setSecureTextEntry: isPassword];
		@}

		[Foreign(Language.ObjC)]
		static void SetIsMultiline(ObjC.Object handle, bool isMultiline)
		@{
			::UITextView* textView = (::UITextView*)handle;
			[[textView textContainer] setMaximumNumberOfLines:((isMultiline) ? 0 : 1)];
		@}

		[Foreign(Language.ObjC)]
		static void SetInputHint(ObjC.Object handle, int hint)
		@{
			::UITextView* textView = (::UITextView*)handle;
			[textView setKeyboardType:(UIKeyboardType)hint];
		@}

		[Foreign(Language.ObjC)]
		static void SetAutoCorrectHint(ObjC.Object handle, int hint)
		@{
			::UITextView* textView = (::UITextView*)handle;
			[textView setAutocorrectionType: (UITextAutocorrectionType)hint];
		@}

		[Foreign(Language.ObjC)]
		static void SetAutoCapitalizationHint(ObjC.Object handle, int hint)
		@{
			::UITextView* textView = (::UITextView*)handle;
			[textView setAutocapitalizationType: (UITextAutocapitalizationType)hint];
		@}

	}

	[Require("Source.Include", "@{Uno.Platform.iOSDisplay:Include}")]
	static extern(iOS) class TextEditSpeedHack
	{
		static bool _done;

		public static void Run()
		{
			if (_done)
				return;
			_done = true;
			var d = (Uno.Platform.iOSDisplay)Uno.Platform.Displays.MainDisplay;
			var wobj = extern<ObjC.Object>(d)"@{Uno.Platform.iOSDisplay:Of($0)._handle}";
			RunInner(wobj);
		}

		// Workaround for slow-to-open text input fields (#2253)
		// See: http://stackoverflow.com/questions/9357026/super-slow-lag-delay-on-initial-keyboard-animation-of-uitextfield
		[Foreign(Language.ObjC)]
		static void RunInner(ObjC.Object win)
		@{
			  UITextField* lagFreeField = [[UITextField alloc] init];
			  UIWindow* window = (UIWindow*)win;
			  [window addSubview:lagFreeField];
			  [lagFreeField becomeFirstResponder];
			  [lagFreeField resignFirstResponder];
			  [lagFreeField removeFromSuperview];
		@}
	}

}

