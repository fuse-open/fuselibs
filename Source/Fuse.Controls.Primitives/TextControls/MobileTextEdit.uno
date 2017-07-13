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
				return TextEditRenderer.NewRenderer();
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
		public static IViewHandleRenderer NewRenderer()
		{
			return new Renderer();
		}

		class Renderer : IViewHandleRenderer
		{
			IViewHandleRenderer _renderer = new NativeViewRenderer();

			void IViewHandleRenderer.Draw(
				ViewHandle viewHandle,
				float4x4 localToClipTransform,
				float2 position,
				float2 size,
				float density)
			{
				TextEditRenderer.Instance.Draw(
					_renderer,
					viewHandle,
					localToClipTransform,
					position,
					size,
					density);
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
		ViewHandle _container;

		TextEditRenderer()
		{
			_renderView = new ViewHandle(CreateTextEdit());
			_container = new ViewHandle(CreateContainer());
		}

		void Draw(
			IViewHandleRenderer renderer,
			ViewHandle viewHandle,
			float4x4 localToClipTransform,
			float2 position,
			float2 size,
			float density)
		{
			CopyState(_container.NativeHandle, viewHandle.NativeHandle, _renderView.NativeHandle);
			renderer.Draw(_container, localToClipTransform, position, size, density);
		}

		[Foreign(Language.Java)]
		static void CopyState(Java.Object container, Java.Object sourceHandle, Java.Object targetHandle)
		@{
			android.widget.GridLayout gridLayout = (android.widget.GridLayout)container;
			android.widget.TextView source = (android.widget.TextView)sourceHandle;
			android.widget.TextView target = (android.widget.TextView)targetHandle;

			if (target.getParent() == gridLayout)
			{
				gridLayout.removeView(target);
			}

			java.lang.String text = source.getText().toString();
			java.lang.CharSequence hint = text.length() == 0 ? source.getHint() : "";
			target.setText(text);
			target.setHint(hint);
			target.setTextColor(source.getCurrentTextColor());
			target.setHintTextColor(source.getCurrentHintTextColor());
			target.setImeOptions(source.getImeOptions());
			target.setIncludeFontPadding(source.getIncludeFontPadding());
			target.setTransformationMethod(source.getTransformationMethod());

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

			/*
				Nasty workaround to avoid Android rendering bug when textalignment is set to center,
				doing it the normal way makes all the characters render on top of eachother...
			*/
			android.widget.GridLayout.LayoutParams lp = new android.widget.GridLayout.LayoutParams();
			lp.rowSpec = android.widget.GridLayout.spec(0, android.widget.GridLayout.FILL);
			int gravity = source.getGravity();
			if ((gravity & android.view.Gravity.LEFT) == android.view.Gravity.LEFT)
			{
				lp.setGravity(android.view.Gravity.LEFT);
				lp.columnSpec = android.widget.GridLayout.spec(0, android.widget.GridLayout.LEFT);
			}
			else if ((gravity & android.view.Gravity.RIGHT) == android.view.Gravity.RIGHT)
			{
				lp.setGravity(android.view.Gravity.RIGHT);
				lp.columnSpec = android.widget.GridLayout.spec(0, android.widget.GridLayout.RIGHT);
			}
			else if ((gravity & android.view.Gravity.CENTER_HORIZONTAL) == android.view.Gravity.CENTER_HORIZONTAL)
			{
				lp.setGravity(android.view.Gravity.CENTER_HORIZONTAL);
				lp.columnSpec = android.widget.GridLayout.spec(0, android.widget.GridLayout.CENTER);
			}
			target.setLayoutParams(lp);
			gridLayout.addView(target);
		@}

		[Foreign(Language.Java)]
		static Java.Object CreateTextEdit()
		@{
			android.widget.TextView tv = new android.widget.TextView(com.fuse.Activity.getRootActivity());
			tv.setBackgroundResource(0);
			return tv;
		@}

		[Foreign(Language.Java)]
		static Java.Object CreateContainer()
		@{
			android.widget.GridLayout gridLayout = new android.widget.GridLayout(com.fuse.Activity.getRootActivity());
			gridLayout.setLayoutParams(
				new android.widget.RelativeLayout.LayoutParams(
					android.view.ViewGroup.LayoutParams.MATCH_PARENT,
					android.view.ViewGroup.LayoutParams.MATCH_PARENT));
			return gridLayout;
		@}

	}

}
