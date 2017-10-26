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
				return TextEditRenderer.NewRenderer(this, _isMultiline);
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
					return new Fuse.Controls.Native.iOS.MultiLineTextEdit(_parent, _parent);
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

	extern(Android) internal class TextEditRenderer
	{
		public static IViewHandleRenderer NewRenderer(TextEdit textEdit, bool isMultiline)
		{
			return new Renderer(textEdit, isMultiline);
		}

		class Renderer : IViewHandleRenderer
		{
			IViewHandleRenderer _renderer = new NativeViewRenderer();

			readonly bool _isMultiline;

			TextEdit _textEdit;
			TextAlignment _prevTextAlignment;
			bool _firstFrame = true;

			public Renderer(TextEdit textEdit, bool isMultiline)
			{
				_textEdit = textEdit;
				_isMultiline = isMultiline;
				_prevTextAlignment = _textEdit.TextAlignment;
			}

			void IViewHandleRenderer.Draw(
				ViewHandle viewHandle,
				float4x4 localToClipTransform,
				float2 position,
				float2 size,
				float density)
			{
				var updateTextAlignment = _firstFrame || _prevTextAlignment != _textEdit.TextAlignment;
				_prevTextAlignment = _textEdit.TextAlignment;
				TextEditRenderer.Instance.Draw(
					_renderer,
					viewHandle,
					localToClipTransform,
					position,
					size,
					density,
					updateTextAlignment,
					_isMultiline);
				_firstFrame = false;
			}

			void IViewHandleRenderer.Invalidate()
			{
				_renderer.Invalidate();
			}

			void IDisposable.Dispose()
			{
				_renderer.Dispose();
				_renderer = null;
			}
		}

		static readonly TextEditRenderer Instance = new TextEditRenderer();

		ViewHandle _renderView;

		TextEditRenderer()
		{
			_renderView = new ViewHandle(CreateTextEdit());
		}

		void Draw(
			IViewHandleRenderer renderer,
			ViewHandle viewHandle,
			float4x4 localToClipTransform,
			float2 position,
			float2 size,
			float density,
			bool updateTextAlignment,
			bool isMultiline)
		{
			var pixelSize = (int2)Math.Ceil(size * density);
			CopyState(viewHandle.NativeHandle, _renderView.NativeHandle, updateTextAlignment, isMultiline, pixelSize.X, pixelSize.Y);
			renderer.Draw(_renderView, localToClipTransform, position, size, density);
		}

		[Foreign(Language.Java)]
		static void CopyState(Java.Object sourceHandle, Java.Object targetHandle, bool updateTextAlignment, bool isMultiline, int width, int height)
		@{
			android.widget.EditText source = (android.widget.EditText)sourceHandle;
			android.widget.EditText target = (android.widget.EditText)targetHandle;

			// Use setText and setTextColor for both text and hint.
			// Setting the hint and hintTextColor breaks text alignment
			// when the alignment is set to right.
			java.lang.String text = source.getText().toString();
			boolean isHint = text.length() == 0;

			target.setText(isHint ? source.getHint() : text);
			target.setTextColor(isHint ? source.getCurrentHintTextColor() : source.getCurrentTextColor());

			target.setImeOptions(source.getImeOptions());
			target.setIncludeFontPadding(source.getIncludeFontPadding());
			target.setTransformationMethod(isHint ? null : source.getTransformationMethod());

			// Setting the inputtype causes bugs when rendering RTL text,
			// it triggers the same symptoms as the TextAlignment bug below.
			// Assuming not copying this state is safe since it does not affect
			// the rendering. No idea why this happens...

			// target.setInputType(source.getInputType());

			target.setTextSize(android.util.TypedValue.COMPLEX_UNIT_PX, source.getTextSize());
			target.setTypeface(source.getTypeface());
			target.setLineSpacing(source.getLineSpacingExtra(), source.getLineSpacingMultiplier());
			target.setPadding(
				source.getPaddingLeft(),
				source.getPaddingTop(),
				source.getPaddingRight(),
				source.getPaddingBottom());
			target.setTextScaleX(source.getTextScaleX());

			target.setLayoutParams(new android.widget.FrameLayout.LayoutParams(width, height));

			if (android.os.Build.VERSION.SDK_INT >= 17)
				target.setTextAlignment(android.view.View.TEXT_ALIGNMENT_GRAVITY);

			target.setGravity(source.getGravity());

			target.setHorizontallyScrolling(!isMultiline);

			if (updateTextAlignment)
			{
				// This piece of code fixes the textalignment issues we have
				// been having for a long time. What happens is that TextView/EditText
				// has some internal state for text alignment that is not updated when
				// setting properties like textAlignment/gravity/scroll etc.
				// Reading the TextView code, I found that the following method
				// calls will hit the codepaths that update the text alignment state
				target.setSelection(source.getSelectionStart(), source.getSelectionEnd());
				target.layout(0, 0, width, height);
				target.onPreDraw();
			}
			else
			{
				// One cause of the issue above is that the source TextEdit's scrollposition
				// does not have a valid value. One frame after changing textalignment this state
				// will be valid
				target.setScrollX(source.getScrollX());
				target.setScrollY(source.getScrollY());
			}
		@}

		[Foreign(Language.Java)]
		static Java.Object CreateTextEdit()
		@{
			android.widget.EditText tv = new android.widget.EditText(com.fuse.Activity.getRootActivity());
			tv.setBackgroundResource(0);
			return tv;
		@}
	}
}
