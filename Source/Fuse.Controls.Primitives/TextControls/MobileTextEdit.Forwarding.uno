using Uno.UX;
using Fuse.Input;
using Fuse.Controls.Native;

namespace Fuse.Controls
{
	partial class MobileTextEdit
	{
		ITextEdit GetITextEdit()
		{
			return NativeView as ITextEdit;
		}

		protected override void PushPropertiesToNativeView()
		{
			base.PushPropertiesToNativeView();
			var tv = NativeView as ITextEdit;
			tv.IsPassword = IsPassword;
			tv.IsReadOnly = IsReadOnly;
			tv.InputHint = InputHint;
			tv.CaretColor = CaretColor;
			tv.SelectionColor = SelectionColor;
			tv.ActionStyle = ActionStyle;
			tv.AutoCorrectHint = AutoCorrectHint;
			tv.AutoCapitalizationHint = AutoCapitalizationHint;
			tv.PlaceholderText = PlaceholderText;
			tv.PlaceholderColor = PlaceholderColor;
		}

		protected override void OnIsPasswordChanged()
		{
			base.OnIsPasswordChanged();
			var edit = GetITextEdit();
			if (edit != null) edit.IsPassword = IsPassword;
		}

		protected override void OnIsReadOnlyChanged()
		{
			base.OnIsReadOnlyChanged();
			var edit = GetITextEdit();
			if (edit != null) edit.IsReadOnly = IsReadOnly;
		}

		protected override void OnInputHintChanged()
		{
			base.OnInputHintChanged();
			var edit = GetITextEdit();
			if (edit != null) edit.InputHint = InputHint;
		}

		protected override void OnCaretColorChanged()
		{
			base.OnCaretColorChanged();
			var edit = GetITextEdit();
			if (edit != null) edit.CaretColor = CaretColor;
		}

		protected override void OnSelectionColorChanged()
		{
			base.OnSelectionColorChanged();
			var edit = GetITextEdit();
			if (edit != null) edit.SelectionColor = SelectionColor;
		}

		protected override void OnActionStyleChanged()
		{
			base.OnActionStyleChanged();
			var edit = GetITextEdit();
			if (edit != null) edit.ActionStyle = ActionStyle;
		}

		protected override void OnAutoCorrectHintChanged()
		{
			base.OnAutoCorrectHintChanged();
			var edit = GetITextEdit();
			if (edit != null) edit.AutoCorrectHint = AutoCorrectHint;
		}

		protected override void OnAutoCapitalizationHintChanged()
		{
			base.OnAutoCapitalizationHintChanged();
			var edit = GetITextEdit();
			if (edit != null) edit.AutoCapitalizationHint = AutoCapitalizationHint;
		}

		protected override void OnPlaceholderTextChanged()
		{
			base.OnPlaceholderTextChanged();
			var edit = GetITextEdit();
			if (edit != null) edit.PlaceholderText = PlaceholderText;

			InvalidateVisual();
			InvalidateLayout();
			InvalidateRenderer();
		}

		protected override void OnPlaceholderColorChanged()
		{
			base.OnPlaceholderColorChanged();
			var edit = GetITextEdit();
			if (edit != null) edit.PlaceholderColor = PlaceholderColor;

			InvalidateVisual();
			InvalidateRenderer();
		}
	}
}
