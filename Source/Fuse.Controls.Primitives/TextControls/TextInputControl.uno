using Uno.UX;

using Fuse.Input;
using Fuse.Layouts;
using Fuse.Elements;
using Fuse.Triggers;

namespace Fuse.Controls
{
	public class TextInputActionArgs : VisualEventArgs
	{
		public TextInputActionType Type { get; private set; }

		public TextInputActionArgs(Visual visual, TextInputActionType type)
			: base(visual)
		{
			Type = type;
		}
	}

	public delegate void TextInputActionHandler(object sender, TextInputActionArgs args);

	/**	
		Base class for text editing controls.
	*/
	public abstract class TextInputControl: LayoutControl, IValue<string>
	{
		readonly TextEdit _editor;
		internal TextEdit Editor { get { return _editor; } }

		internal TextInputControl(TextEdit editor)
		{
			Focus.SetIsFocusable(this, true);
			Focus.SetDelegator(this, FocusDelegator);
			HitTestMode = HitTestMode.LocalBoundsAndChildren;
			_editor = editor;
			Children.Add(_editor);
			Layout = new DockLayout();
		}

		void OnTapped(object sender, Uno.EventArgs args)
		{
			Focus.GiveTo(this);
		}
		
		Visual FocusDelegator()
		{
			return _editor;
		}

		Gestures.Tapped _tapped = new Gestures.Tapped();

		protected override void OnRooted()
		{
			base.OnRooted();
			_editor.AddPropertyListener(this);
			_tapped.Handler += OnTapped;
			Children.Add(_tapped);
		}

		protected override void OnUnrooted()
		{
			_tapped.Handler -= OnTapped;
			Children.Remove(_tapped);
			_editor.RemovePropertyListener(this);
			base.OnUnrooted();
		}

		public override void OnPropertyChanged(PropertyObject obj, Selector prop)
		{
			base.OnPropertyChanged(obj, prop);

			if (obj == _editor)
				OnPropertyChanged(prop, this);
		}

		[UXOriginSetter("SetValue"), UXContent]
		public string Value 
		{ 
			get { return _editor.Value; } 
			set { SetValue(value, this); }
		}
		
		public void SetValue(string v, IPropertyListener origin) 
		{ 
			_editor.SetValue(v, origin); 
			
			//if we're the origin force the property changed event since we won't get the OnPropertyChanged
			//callback from the editor
			if (origin == this)
				OnPropertyChanged("Value", this);
		}
		
		public event ValueChangedHandler<string> ValueChanged
		{
			add { _editor.ValueChanged += value; }
			remove { _editor.ValueChanged -= value; }
		}

		/** Max number of characters in the Value string
		*/
		public int MaxLength { get { return _editor.MaxLength; } set { _editor.MaxLength = value; } }

		/** How text should wrap. Default is NoWrap
		*/
		public TextWrapping TextWrapping { get { return _editor.TextWrapping; } set { _editor.TextWrapping = value; } }

		/** Spacing in points between each line of text
		*/
		public float LineSpacing { get { return _editor.LineSpacing; } set { _editor.LineSpacing = value; } }

		/** Font size in points
		*/
		public float FontSize { get { return _editor.FontSize; } set { _editor.FontSize = value; } }

		/** @seealso Fuse.Font
		*/
		public Font Font { get { return _editor.Font; } set { _editor.Font = value; } }

		public TextAlignment TextAlignment { get { return _editor.TextAlignment; } set { _editor.TextAlignment = value; } }

		public float4 TextColor { get { return _editor.TextColor; } set { _editor.TextColor = value; } }

		public TextTruncation TextTruncation { get { return _editor.TextTruncation; } set { _editor.TextTruncation = value; } }

		/** Text can be selected and copied only
		*/
		public bool IsReadOnly { get { return _editor.IsReadOnly; } set { _editor.IsReadOnly = value; } }

		/** InputHint can change what kind of onscreen-keyboard will show on mobile export targets.
			For example `InputHint="Phone"` will give a numerical keyboard and `InputHint="Email"`
			will give keyboard with `@` and no autocorrect
		*/
		public TextInputHint InputHint { get { return _editor.InputHint; } set { _editor.InputHint = value; } }

		/** The color of the caret (also know as cursor) shown when editing text
		*/
		public float4 CaretColor { get { return _editor.CaretColor; } set { _editor.CaretColor = value; } }

		/** The color of the selected-text rectangle
		*/
		public float4 SelectionColor { get { return _editor.SelectionColor; } set { _editor.SelectionColor = value; } }

		/** Hint for systems that support autocorrect (Like Android and iOS)
		*/
		public AutoCorrectHint AutoCorrectHint { get { return _editor.AutoCorrectHint; } set { _editor.AutoCorrectHint = value; } }

		/** Hint for systems that support autocapitalization (Like Android and iOS)
		*/
		public AutoCapitalizationHint AutoCapitalizationHint { get { return _editor.AutoCapitalizationHint; } set { _editor.AutoCapitalizationHint = value; } }

	}
}

