
using Uno;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Controls.Native.Android
{
	extern(Android) public class TextEdit : TextInput
	{
		public TextEdit(ITextEditHost host, bool isMultiline) : base(host, isMultiline)
		{
			MakeItPlain(Handle);
		}

		[Foreign(Language.Java)]
		static void MakeItPlain(Java.Object handle)
		@{
			android.widget.TextView t = (android.widget.TextView)handle;
			t.setIncludeFontPadding(false);
			t.setBackgroundResource(0);
			t.setPadding(0, 0, 0, 0);
			if (android.os.Build.VERSION.SDK_INT >= 17)
				t.setPaddingRelative(0, 0, 0, 0);
		@}
	}

	[ForeignInclude(Language.Java, "android.view.View.MeasureSpec")]
	extern(Android) public class TextInput : TextView, ITextEdit
	{
		ITextEditHost _host;

		public TextInput(ITextEditHost host, bool isMultiline) : base(Create())
		{
			_host = host;
			IsMultiline = isMultiline;
			AddEditorActionListener(Handle);
			_focusEvent = FocusChangedListener.AddHandler(Handle, OnNativeFocusChanged);
			AddTextChangedListener(Handle);
		}

		void OnNativeFocusChanged(Java.Object view, bool hasFocus)
		{
			if (!hasFocus)
			{
				_host.OnFocusLost();
				ScheduleFocusLoss();
			}
			else
			{
				_host.OnFocusGained();
				FocusManager.Singleton.HideKeyboardContext = null;
				SoftKeyboard.ShowKeyboard(Handle);
			}
		}

		void ScheduleFocusLoss()
		{
			FocusManager.Singleton.LoseFocus = Handle;
			FocusManager.Singleton.HideKeyboardContext = FocusManager.GetContext(Handle);
			FocusManager.Singleton.HideKeyboardWindowToken = FocusManager.GetWindowToken(Handle);
			UpdateManager.AddDeferredAction(FocusManager.Singleton.CompleteFocusLoss);
		}

		IDisposable _focusEvent;

		public override void Dispose()
		{
			_host = null;
			_focusEvent.Dispose();
			_focusEvent = null;
			base.Dispose();
		}

		void ITextEdit.FocusGained()
		{
			RequestFocus(Handle);
		}

		void ITextEdit.FocusLost()
		{
			if (HasFocus(Handle))
				ScheduleFocusLoss();
		}

		[Foreign(Language.Java)]
		static bool HasFocus(Java.Object viewHandle)
		@{
			return ((android.view.View)viewHandle).hasFocus();
		@}

		[Foreign(Language.Java)]
		static void RequestFocus(Java.Object viewHandle)
		@{
			((android.view.View)viewHandle).requestFocus();
		@}

		[Foreign(Language.Java)]
		static void ClearFocus(Java.Object handle)
		@{
			android.widget.TextView t = (android.widget.TextView)handle;
			t.clearFocus();
		@}

		bool _isMultiline;
		public bool IsMultiline
		{
			set
			{
				_isMultiline = value;
				UpdateFlags();
			}
		}

		bool _isPassword;
		public bool IsPassword
		{
			set
			{
				_isPassword = value;
				UpdateFlags();
			}
		}

		bool _isReadOnly;
		public bool IsReadOnly
		{
			set
			{
				_isReadOnly = value;
				UpdateFlags();
			}
		}

		AutoCorrectHint _autoCorrentHint;
		public AutoCorrectHint AutoCorrectHint
		{
			set
			{
				_autoCorrentHint = value;
				UpdateFlags();
			}
		}

		AutoCapitalizationHint _autoCapitalizationHint;
		public AutoCapitalizationHint AutoCapitalizationHint
		{
			set
			{
				_autoCapitalizationHint = value;
				UpdateFlags();
			}
		}

		TextInputHint _inputHint;
		public TextInputHint InputHint
		{
			set
			{
				_inputHint = value;
				UpdateFlags();
			}
		}

		TextInputActionStyle _actionStyle;
		public TextInputActionStyle ActionStyle
		{
			set
			{
				_actionStyle = value;
				UpdateFlags();
			}
		}

		void UpdateFlags()
		{
			//do not mix convenience functions on TextView with the flags, if you get the wrong order
			//it'll ignore some settings

			int flags = 0;

			switch (_inputHint)
			{
			case Fuse.Controls.TextInputHint.Email:
				flags |= 0x00000021; //TYPE_CLASS_TEXT | TYPE_TEXT_VARIATION_EMAIL_ADDRESS
				break;

			case Fuse.Controls.TextInputHint.URL:
				flags |= 0x00000011; //TYPE_CLASS_TEXT | TYPE_TEXT_VARIATION_URI
				break;

			case Fuse.Controls.TextInputHint.Phone:
				flags |= 0x00000003; //TYPE_CLASS_PHONE
				break;

			case Fuse.Controls.TextInputHint.Integer:
				flags |= 0x00000002; //TYPE_CLASS_NUMBER | TYPE_NUMBER_VARIATION_NORMAL
				break;

			case Fuse.Controls.TextInputHint.Decimal:
				flags |= 0x00000002 | 0x00002000; //TYPE_CLASS_NUMBER | TYPE_NUMBER_FLAG_DECIMAL
				break;

			default:
				flags |= 0x00000001; //TYPE_CLASS_TEXT

				// TYPE_TEXT_FLAG_AUTO_CORRECT only applies to TYPE_CLASS_TEXT, according to the docs
				switch (_autoCorrentHint)
				{
					case Fuse.Controls.AutoCorrectHint.Default:
						// default, because the docs say:
						// "You should always set this flag unless you really expect users to type non-words in this field [...]"
						flags |= 0x00008000; //TYPE_TEXT_FLAG_AUTO_CORRECT
						break;

					case Fuse.Controls.AutoCorrectHint.Disabled: break;

					case Fuse.Controls.AutoCorrectHint.Enabled:
						flags |= 0x00008000; //TYPE_TEXT_FLAG_AUTO_CORRECT
						break;
				}

				switch (_autoCapitalizationHint)
				{
					case Fuse.Controls.AutoCapitalizationHint.None:
						break;

					case Fuse.Controls.AutoCapitalizationHint.Characters:
						flags |= 0x00001000; //TYPE_TEXT_FLAG_CAP_CHARACTERS
						break;

					case Fuse.Controls.AutoCapitalizationHint.Words:
						flags |= 0x00002000; //TYPE_TEXT_FLAG_CAP_WORDS
						break;

					case Fuse.Controls.AutoCapitalizationHint.Sentences:
						flags |= 0x00004000; //TYPE_TEXT_FLAG_CAP_SENTENCES
						break;
				}

				break;
			}

			if (_isMultiline)
				flags |= 0x00020000; //TYPE_TEXT_FLAG_MULTI_LINE*/

			if (_isPassword)
				flags |= 0x00000080; //TYPE_TEXT_VARIATION_PASSWORD

			if (_isReadOnly)
			{
				SetInputType(Handle, 0);
				SetFocusable(Handle, false);
				SetFocusableInTouchMode(Handle, false);
			}
			else
			{
				SetInputType(Handle, flags);
				SetImeOptions(Handle, ReturnKeyType);
				SetFocusable(Handle, true);
				SetFocusableInTouchMode(Handle, true);
			}
		}

		public float4 CaretColor
		{
			set { SetCursorDrawableColor(Handle, (int)Color.ToArgb(value)); }
		}

		public float4 SelectionColor
		{
			set { SetSelectionColor(Handle, (int)Color.ToArgb(value)); }
		}

		public string PlaceholderText
		{
			set { SetPlaceholderText(Handle, value); }
		}

		public float4 PlaceholderColor
		{
			set { SetPlaceholderColor(Handle, (int)Color.ToArgb(value)); }
		}

		[Foreign(Language.Java)]
		static void SetPlaceholderColor(Java.Object handle, int value)
		@{
			((android.widget.TextView)handle).setHintTextColor(value);
		@}

		[Foreign(Language.Java)]
		static void SetPlaceholderText(Java.Object handle, string value)
		@{
			((android.widget.TextView)handle).setHint(value);
		@}

		int ReturnKeyType
		{
			get
			{
				switch(_actionStyle)
				{
					case Fuse.Controls.TextInputActionStyle.Done : return 0x00000006 /*IME_ACTION_DONE*/;
					case Fuse.Controls.TextInputActionStyle.Next : return 0x00000005 /*IME_ACTION_NEXT*/;
					case Fuse.Controls.TextInputActionStyle.Go : return 0x00000002 /*IME_ACTION_GO*/;
					case Fuse.Controls.TextInputActionStyle.Search : return 0x00000003 /*IME_ACTION_SEARCH*/;
					case Fuse.Controls.TextInputActionStyle.Send : return 0x00000004 /*IME_ACTION_SEND*/;
				}
				return 0x00000000 /*IME_ACTION_UNSPECIFIED*/;
			}
		}

		[Foreign(Language.Java)]
		static void SetSelectionColor(Java.Object handle, int color)
		@{
			((android.widget.TextView)handle).setHighlightColor(color);
		@}

		[Foreign(Language.Java)]
		static void SetInputType(Java.Object handle, int value)
		@{
			android.widget.EditText et = (android.widget.EditText)handle;

			// preserve selection, setInputType() might reset it
			int start = et.getSelectionStart();
			int end = et.getSelectionEnd();

			// get typeface and set after setInputType is called,
			// InputType.TYPE_TEXT_VARIATION_PASSWORD sets the typeface to monospace
			android.graphics.Typeface tf = et.getTypeface();

			// call setTransformationMethod before setInputType
			// ref: https://code.google.com/p/android/issues/detail?id=7092
			et.setTransformationMethod((((value & 0x80) != 0) ? android.text.method.PasswordTransformationMethod.getInstance() : null));
			et.setInputType(value);
			et.setTypeface(tf);

			et.setSelection(start, end);

		@}

		[Foreign(Language.Java)]
		static void SetImeOptions(Java.Object handle, int value)
		@{
			((android.widget.TextView)handle).setImeOptions(value);
		@}

		[Foreign(Language.Java)]
		static void SetFocusable(Java.Object handle, bool value)
		@{
			((android.widget.EditText)handle).setFocusable(value);
		@}

		[Foreign(Language.Java)]
		static void SetFocusableInTouchMode(Java.Object handle, bool value)
		@{
			((android.widget.EditText)handle).setFocusableInTouchMode(value);
		@}

		[Foreign(Language.Java)]
		static Java.Object Create()
		@{
			return new android.widget.EditText(com.fuse.Activity.getRootActivity());
		@}

		[Foreign(Language.Java)]
		void SetCursorDrawableColor(Java.Object handle, int color)
		@{
			android.widget.EditText editText = (android.widget.EditText)handle;
			try {
				/*
					(ﾉಥДಥ)ﾉ︵┻━┻･/
				*/
				java.lang.reflect.Field fCursorDrawableRes = android.widget.TextView.class.getDeclaredField("mCursorDrawableRes");
				fCursorDrawableRes.setAccessible(true);
				int mCursorDrawableRes = fCursorDrawableRes.getInt(editText);
				java.lang.reflect.Field fEditor = android.widget.TextView.class.getDeclaredField("mEditor");
				fEditor.setAccessible(true);
				java.lang.Object editor = fEditor.get(editText);
				Class<?> clazz = editor.getClass();
				java.lang.reflect.Field fCursorDrawable = clazz.getDeclaredField("mCursorDrawable");
				fCursorDrawable.setAccessible(true);
				android.graphics.drawable.Drawable[] drawables = new android.graphics.drawable.Drawable[2];
				drawables[0] = androidx.core.content.ContextCompat.getDrawable(com.fuse.Activity.getRootActivity(), mCursorDrawableRes);
				drawables[1] = androidx.core.content.ContextCompat.getDrawable(com.fuse.Activity.getRootActivity(), mCursorDrawableRes);
				drawables[0].setColorFilter(color, android.graphics.PorterDuff.Mode.SRC_IN);
				drawables[1].setColorFilter(color, android.graphics.PorterDuff.Mode.SRC_IN);
				fCursorDrawable.set(editor, drawables);
			} catch (Throwable ignored) {

			}
		@}

		[Foreign(Language.Java)]
		void AddTextChangedListener(Java.Object handle)
		@{
			((android.widget.TextView)handle).addTextChangedListener(new android.text.TextWatcher() {
				public void afterTextChanged(android.text.Editable e) {

				}
				public void beforeTextChanged(java.lang.CharSequence cs, int start, int count, int after) {

				}
				public void onTextChanged(java.lang.CharSequence cs, int start, int before, int count) {
					java.lang.String str = cs.toString();
					@{global::Fuse.Controls.Native.Android.TextInput:Of(_this).OnTextChanged(string):Call(str)};
				}
			});
		@}


		public override float2 Measure(LayoutParams lp, float density)
		{
			if (_isMultiline)
			{
				var handle = NativeHandle;
				var measuredSize = new int[2];
				Measure(handle, (int)(lp.X * density), (int)(lp.Y * density), lp.HasX, lp.HasY, measuredSize);
				return float2(measuredSize[0] / density, measuredSize[1] / density);
			}
			else
			{
				return base.Measure(lp, density);
			}
		}

		[Foreign(Language.Java)]
		static void Measure(Java.Object handle, int w, int h, bool hasX, bool hasY, int[] measuredSize)
		@{
			int wSpec = MeasureSpec.makeMeasureSpec(w, hasX ? MeasureSpec.EXACTLY : MeasureSpec.UNSPECIFIED);
			int hSpec = MeasureSpec.makeMeasureSpec(h, hasY ? MeasureSpec.EXACTLY : MeasureSpec.UNSPECIFIED);
			android.view.View view = (android.view.View)handle;
			android.view.ViewGroup.LayoutParams lp = view.getLayoutParams();
			view.setLayoutParams(new android.widget.FrameLayout.LayoutParams(w, 0xfffffffe));
			view.measure(wSpec, hSpec);
			if (lp != null) {
				view.setLayoutParams(lp);
			}
			measuredSize.set(0, view.getMeasuredWidth());
			measuredSize.set(1, view.getMeasuredHeight());
		@}

		/*[Foreign(Language.Java)]
		void AddFocusChangedListener(Java.Object handle)
		@{
			((android.widget.TextView)handle).setOnFocusChangeListener(new android.view.View.OnFocusChangeListener() {
				public void onFocusChange(android.view.View v, boolean hasFocus) {
					@{global::Fuse.Controls.Native.Android.TextInput:Of(_this).OnFocusChanged(bool):Call(hasFocus)};
				}
			});
		@}

		void OnFocusChanged(bool hasFocus)
		{
			if (hasFocus)
			{
				_host.OnFocusGained();
			}
			else
			{
				_host.OnFocusLost();
			}
		}*/

		[Foreign(Language.Java)]
		void AddEditorActionListener(Java.Object handle)
		@{
			((android.widget.TextView)handle).setOnEditorActionListener(new android.widget.TextView.OnEditorActionListener() {
				public boolean onEditorAction(android.widget.TextView v, int actionId, android.view.KeyEvent ke) {
					return @{global::Fuse.Controls.Native.Android.TextInput:Of(_this).OnEditorAction(int):Call(actionId)};
				}
			});
		@}

		void OnTextChanged(string value)
		{
			_host.OnValueChanged(value);
		}

		bool OnEditorAction(int actionCode)
		{
			// _host.OnAction();
			//https://developer.android.com/reference/android/view/inputmethod/EditorInfo.html#IME_ACTION_PREVIOUS
			switch (actionCode) {
				//as in ReturnKeyType
				case 6:
				case 5:
				case 2:
				case 3:
				case 4:
					return _host.OnInputAction(TextInputActionType.Primary);
			}
			return false;
		}

	}

	extern(Android) internal class FocusManager
	{
		public static readonly FocusManager Singleton = new FocusManager();

		public Java.Object LoseFocus;
		public Java.Object HideKeyboardContext;
		public Java.Object HideKeyboardWindowToken;

		public void CompleteFocusLoss()
		{
			if (LoseFocus != null)
			{
				if (HasFocus(LoseFocus))
					RequestRootViewFocus(LoseFocus);
				LoseFocus = null;
			}

			if (HideKeyboardContext != null)
			{
				SoftKeyboard.HideKeyboard(HideKeyboardContext, HideKeyboardWindowToken);
				HideKeyboardContext = null;
			}
		}

		[Foreign(Language.Java)]
		static bool HasFocus(Java.Object viewHandle)
		@{
			return ((android.view.View)viewHandle).hasFocus();
		@}

		[Foreign(Language.Java)]
		static void RequestRootViewFocus(Java.Object viewHandle)
		@{
			((android.view.View)viewHandle).getRootView().requestFocus();
		@}

		[Foreign(Language.Java)]
		public static Java.Object GetContext(Java.Object viewHandle)
		@{
			return ((android.view.View)viewHandle).getContext();
		@}

		[Foreign(Language.Java)]
		public static Java.Object GetWindowToken(Java.Object viewHandle)
		@{
			return ((android.view.View)viewHandle).getWindowToken();
		@}

	}

	extern(Android) internal static class SoftKeyboard
	{

		[Foreign(Language.Java)]
		public static void HideKeyboard(Java.Object hideKeyboardContext, Java.Object hideKeyboardWindowToken)
		@{
			android.content.Context ctx = (android.content.Context)hideKeyboardContext;
			android.os.IBinder binder = (android.os.IBinder)hideKeyboardWindowToken;
			android.view.inputmethod.InputMethodManager imm = (android.view.inputmethod.InputMethodManager)ctx.getSystemService(android.content.Context.INPUT_METHOD_SERVICE);
			imm.hideSoftInputFromWindow(binder, 0);
		@}

		[Foreign(Language.Java)]
		public static void ShowKeyboard(Java.Object viewHandle)
		@{
			android.view.View view = (android.view.View)viewHandle;
			android.view.inputmethod.InputMethodManager imm = (android.view.inputmethod.InputMethodManager)view.getContext().getSystemService(android.content.Context.INPUT_METHOD_SERVICE);
			imm.showSoftInput(view, android.view.inputmethod.InputMethodManager.SHOW_FORCED);
		@}

	}

	extern(Android) internal class FocusChangedListener : IDisposable
	{

		readonly Java.Object _listener;
		readonly Java.Object _view;
		readonly Action<Java.Object, bool> _callback;

		FocusChangedListener(
			Java.Object view,
			Action<Java.Object, bool> callback)
		{
			_view = view;
			_callback = callback;
			_listener = Create();
			SetListener(_view, _listener);
		}

		void OnFocusChange(bool hasFocus)
		{
			_callback(_view, hasFocus);
		}

		public static IDisposable AddHandler(
			Java.Object view,
			Action<Java.Object, bool> callback)
		{
			return new FocusChangedListener(view, callback);
		}

		public void Dispose()
		{
			ClearListener(_view);
		}

		[Foreign(Language.Java)]
		Java.Object Create()
		@{
			android.view.View.OnFocusChangeListener listener = new android.view.View.OnFocusChangeListener() {
				public void onFocusChange(android.view.View view, boolean hasFocus) {
					@{FocusChangedListener:Of(_this).OnFocusChange(bool):Call(hasFocus)};
				}
			};
			return listener;
		@}

		[Foreign(Language.Java)]
		static void SetListener(Java.Object viewHandle, Java.Object listenerHandle)
		@{
			((android.view.View)viewHandle).setOnFocusChangeListener(((android.view.View.OnFocusChangeListener)listenerHandle));
		@}

		[Foreign(Language.Java)]
		static void ClearListener(Java.Object viewHandle)
		@{
			((android.view.View)viewHandle).setOnFocusChangeListener(null);
		@}

	}

}
