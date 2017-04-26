using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Input;
using Fuse.Controls.Native;

namespace Fuse.Controls
{
	partial class MobileTextEdit: TextEdit, ITextEditHost, INotifyFocus
	{
		readonly bool _isMultiline;

		public MobileTextEdit(bool multiline): base(multiline)
		{
			_isMultiline = multiline;
			var androidAppearance = new AndroidTemplate(this);
			var iosAppearance = new iOSTemplate(this);
			Templates.Add(androidAppearance);
			Templates.Add(iosAppearance);
		}

		ITextEdit NativeEdit
		{
			get { return _textEdit ?? (NativeView as ITextEdit); }
		}

		// disable the built-in rendering
		internal override string RenderValue
		{
			get { return null; }
		}

		ITextEdit _textEdit;

		extern(Android || iOS)
		SingleViewHost _singelViewHost;

		extern(Android || iOS)
		protected override void OnRooted()
		{
			base.OnRooted();
			if (VisualContext == VisualContext.Graphics)
			{
				_textEdit = InstatiateTextEdit();
				NativeView = _textEdit;
				_singelViewHost = new SingleViewHost(
					SingleViewHost.RenderState.Enabled,
					_textEdit as ViewHandle,
					InstatiateRenderer());
				Children.Add(_singelViewHost);
				PushPropertiesToNativeView();
				InvalidateNativeViewHost();
			}
		}

		extern(Android || iOS)
		ITextEdit InstatiateTextEdit()
		{
			if defined(Android)
				return FindTemplate("AndroidAppearance").New() as ITextEdit;
			else if defined(iOS)
				return FindTemplate("iOSAppearance").New() as ITextEdit;
		}

		extern(Android || iOS)
		IViewHandleRenderer InstatiateRenderer()
		{
			if defined(Android)
				return new TextEditRenderer();
			else if defined(iOS)
				return new NativeViewRenderer();
		}

		extern(Android || iOS)
		protected override void OnUnrooted()
		{
			base.OnUnrooted();
			if (_singelViewHost != null)
			{
				Children.Remove(_singelViewHost);
				_singelViewHost.Dispose();
				_singelViewHost = null;
			}
			if (_textEdit != null)
			{
				_textEdit.Dispose();
				_textEdit = null;
			}
			NativeView = null;
		}

		protected override void OnValueChanged(IPropertyListener origin)
		{
			base.OnValueChanged(origin);
		}

		void ITextEditHost.OnValueChanged(string newValue)
		{
			SetValueInternal(newValue);
		}

		bool ITextEditHost.OnInputAction(TextInputActionType type)
		{
			return OnAction(type);
		}

		void ITextEditHost.OnFocusGained()
		{
			Focus.Obtained(this);
			DisableRenderToTexture();
		}

		void ITextEditHost.OnFocusLost()
		{
			Focus.ReleaseFrom(this);
			EnabledRenderToTexture();
		}

		void INotifyFocus.OnFocusGained()
		{
			DisableRenderToTexture();
			if (NativeEdit != null)
				NativeEdit.FocusGained();
		}

		void INotifyFocus.OnFocusLost()
		{
			if (NativeEdit != null)
				NativeEdit.FocusLost();
			EnabledRenderToTexture();
		}

		protected override void InvalidateRenderer()
		{
			InvalidateNativeViewHost();
			InvalidateRenderBounds();
		}

		extern(!Android && !iOS)
		void DisableRenderToTexture() { }
		extern(Android || iOS)
		void DisableRenderToTexture()
		{
			if (_singelViewHost != null)
			{
				_singelViewHost.RenderToTexture = SingleViewHost.RenderState.Disabled;
			}
		}

		extern(!Android && !iOS)
		void EnabledRenderToTexture() { }
		extern(Android || iOS)
		void EnabledRenderToTexture()
		{
			if (_singelViewHost != null)
			{
				_singelViewHost.RenderToTexture = SingleViewHost.RenderState.Enabled;
				_singelViewHost.InvalidateVisual();
				_singelViewHost.InvalidateRenderBounds();
			}
		}

		extern(!Android && !iOS)
		void InvalidateNativeViewHost() { }
		extern(Android || iOS)
		void InvalidateNativeViewHost()
		{
			if (_singelViewHost != null)
			{
				_singelViewHost.InvalidateVisual();
				_singelViewHost.InvalidateLayout();
			}
		}

		class AndroidTemplate: Uno.UX.Template
		{
			[Uno.WeakReference]
			internal readonly Fuse.Controls.MobileTextEdit _parent;

			public AndroidTemplate(Fuse.Controls.MobileTextEdit parent): base("AndroidAppearance", false)
			{
				_parent = parent;
			}
			extern(Android)
			public override object New()
			{
				return new Fuse.Controls.Native.Android.TextEdit(_parent, _parent._isMultiline);
			}

			extern(!Android)
			public override object New() { throw new Exception("Cannot instantiate Android templates on non-android platforms!"); }
		}
		class iOSTemplate: Uno.UX.Template
		{
			[Uno.WeakReference]
			internal readonly Fuse.Controls.MobileTextEdit _parent;

			public iOSTemplate(Fuse.Controls.MobileTextEdit parent): base("iOSAppearance", false)
			{
				_parent = parent;
			}
			extern(iOS)
			public override object New()
			{
				if (_parent._isMultiline)
				{
					return new Fuse.Controls.Native.iOS.MultiLineTextEdit(_parent);
				}
				else
				{
					return new Fuse.Controls.Native.iOS.SingleLineTextEdit(_parent);
				}
			}
			extern(!iOS)
			public override object New() { throw new Exception("Cannot instantiate iOS templates on non-ios platforms!"); }
		}
	}

	extern(Android) internal class TextEditRenderer : IViewHandleRenderer
	{

		ViewHandle _target;

		IViewHandleRenderer _nativeViewRenderer;

		public TextEditRenderer()
		{
			_target = new ViewHandle(CreateTextEdit());
			_nativeViewRenderer = new NativeViewRenderer();
		}

		bool _valid = false;
		void IViewHandleRenderer.Draw(ViewHandle viewHandle, float4x4 localToClipTransform, float2 position, float2 size, float density)
		{
			if (!_valid)
			{
				CopyState(viewHandle.NativeHandle, _target.NativeHandle);
				_valid = true;
			}
			_nativeViewRenderer.Draw(_target, localToClipTransform, position, size, density);
		}

		void IViewHandleRenderer.Invalidate()
		{
			_nativeViewRenderer.Invalidate();
			_valid = false;
		}

		void IDisposable.Dispose()
		{
			_nativeViewRenderer.Dispose();
			_nativeViewRenderer = null;
			_target = null;
		}

		[Foreign(Language.Java)]
		static void CopyState(Java.Object sourceHandle, Java.Object targetHandle)
		@{
			android.widget.TextView source = (android.widget.TextView)sourceHandle;
			android.widget.TextView target = (android.widget.TextView)targetHandle;

			java.lang.String text = source.getText().toString();
			java.lang.CharSequence hint = text.length() == 0 ? source.getHint() : "";
			target.setText(text);
			target.setHint(hint);
			target.setBackgroundResource(0);
			target.setTextColor(source.getCurrentTextColor());
			target.setHintTextColor(source.getCurrentHintTextColor());
			target.setIncludeFontPadding(source.getIncludeFontPadding());
			target.setTransformationMethod(source.getTransformationMethod());
			target.setTextSize(android.util.TypedValue.COMPLEX_UNIT_PX, source.getTextSize());
			target.setTypeface(source.getTypeface());
			target.setLineSpacing(source.getLineSpacingExtra(), source.getLineSpacingMultiplier());
			target.setPadding(
				source.getPaddingLeft(),
				source.getPaddingTop(),
				source.getPaddingRight(),
				source.getPaddingBottom());

			if (android.os.Build.VERSION.SDK_INT >= 17)
				target.setTextAlignment(source.getTextAlignment());

			target.setGravity(source.getGravity());
			target.setHorizontallyScrolling(source.getScrollX() > 0);
			target.setScrollX(source.getScrollX());
		@}

		[Foreign(Language.Java)]
		static Java.Object CreateTextEdit()
		@{
			android.widget.TextView tv = new android.widget.TextView(com.fuse.Activity.getRootActivity());
			tv.setBackgroundResource(0);
			tv.setLayoutParams(
				new android.widget.FrameLayout.LayoutParams(
					android.view.ViewGroup.LayoutParams.MATCH_PARENT,
					android.view.ViewGroup.LayoutParams.MATCH_PARENT));
			return tv;
		@}

	}

}
