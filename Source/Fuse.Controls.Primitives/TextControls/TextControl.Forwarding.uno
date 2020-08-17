using Uno.UX;
using Fuse.Scripting;
using Fuse.Controls.Native;

namespace Fuse.Controls
{
	public partial class TextControl
	{
		public static readonly Selector ValuePropertyName = "Value";
		public static readonly Selector MaxLengthPropertyName = "MaxLength";
		public static readonly Selector TextWrappingPropertyName = "TextWrapping";
		public static readonly Selector LineSpacingPropertyName = "LineSpacing";
		public static readonly Selector FontSizePropertyName = "FontSize";
		public static readonly Selector FontPropertyName = "Font";
		public static readonly Selector TextAlignmentPropertyName = "TextAlignment";
		public static readonly Selector ColorPropertyName = "Color";
		public static readonly Selector TextColorPropertyName = "TextColor";
		public static readonly Selector TextTruncationPropertyName = "TextTruncation";
		public static readonly Selector LoadAsyncPropertyName = "LoadAsync";

		protected ITextView GetITextView()
		{
			return NativeView as ITextView;
		}

		protected override void PushPropertiesToNativeView()
		{
			base.PushPropertiesToNativeView();
			var tv = NativeView as ITextView;
			tv.Value = Value;
			tv.MaxLength = MaxLength;
			tv.TextWrapping = TextWrapping;
			tv.LineSpacing = LineSpacing;
			tv.FontSize = FontSize;
			tv.Font = Font;
			tv.TextAlignment = TextAlignment;
			tv.TextColor = Color;
			tv.TextTruncation = TextTruncation;
		}

		protected virtual void OnValueChanged(IPropertyListener origin)
		{
			OnPropertyChanged(ValuePropertyName, origin);
			InvalidateLayout();
			InvalidateVisual();
			InvalidateRenderer();

			if (ValueChanged != null)
			{
				var args = new StringChangedArgs(Value);
				ValueChanged(this, args);
			}
		}

		protected virtual void OnMaxLengthChanged()
		{
			OnPropertyChanged(MaxLengthPropertyName);
			var edit = GetITextView();
			if (edit != null) edit.MaxLength = MaxLength;
			InvalidateLayout();
			InvalidateVisual();
			InvalidateRenderer();
		}

		protected virtual void OnTextWrappingChanged()
		{
			OnPropertyChanged(TextWrappingPropertyName);
			var edit = GetITextView();
			if (edit != null) edit.TextWrapping = TextWrapping;
			InvalidateLayout();
			InvalidateVisual();
			InvalidateRenderer();
		}

		protected virtual void OnLineSpacingChanged()
		{
			OnPropertyChanged(LineSpacingPropertyName);
			var edit = GetITextView();
			if (edit != null) edit.LineSpacing = LineSpacing;
			InvalidateLayout();
			InvalidateVisual();
			InvalidateRenderer();
		}

		protected virtual void OnFontSizeChanged()
		{
			OnPropertyChanged(FontSizePropertyName);
			var edit = GetITextView();
			if (edit != null)
				edit.FontSize = FontSizeScaled;
			InvalidateLayout();
			InvalidateVisual();
			InvalidateRenderer();
		}

		protected virtual void OnFontChanged()
		{
			OnPropertyChanged(FontPropertyName);
			var edit = GetITextView();
			if (edit != null) edit.Font = Font;
			InvalidateLayout();
			InvalidateVisual();
			InvalidateRenderer();
		}

		protected virtual void OnTextAlignmentChanged()
		{
			OnPropertyChanged(TextAlignmentPropertyName);
			var edit = GetITextView();
			if (edit != null) edit.TextAlignment = TextAlignment;
			InvalidateLayout();
			InvalidateVisual();
			InvalidateRenderer();
		}

		protected virtual void OnColorChanged(IPropertyListener origin)
		{
			OnPropertyChanged(ColorPropertyName, origin);
			OnPropertyChanged(TextColorPropertyName, origin);
			var edit = GetITextView();
			if (edit != null) edit.TextColor = Color;
			InvalidateVisual();
			InvalidateRenderer();
		}

		protected virtual void OnTextTruncationChanged()
		{
			OnPropertyChanged(TextTruncationPropertyName);
			var edit = GetITextView();
			if (edit != null) edit.TextTruncation = TextTruncation;
			InvalidateLayout();
			InvalidateVisual();
			InvalidateRenderer();
		}

		protected virtual void OnLoadAsyncChanged()
		{
			if (VisualContext == VisualContext.Graphics)
			{
				if defined(USE_HARFBUZZ)
				{
					if (_textRenderer != null)
					{
						_textRenderer.SoftDispose();
						_textRenderer = new FuseTextRenderer.TextRenderer(this, InternalLoadAsync);
					}
				}
			}
			OnPropertyChanged(LoadAsyncPropertyName);
			InvalidateRenderer();
		}
	}
}
