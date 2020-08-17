using Uno;
using Uno.UX;

using Fuse.Elements;
using Fuse.Scripting;
using Fuse.Triggers;
using Fuse.Controls.Native;
using Fuse.Platform;

namespace Fuse.Controls
{
	/**
		Exposes the common interface for text controls.

		This class is abstract. It retains the state for the common properties,
		and calls protected virtual OnSomethingChanged-methods that derived classes
		can override to implement the desired behavior.

		Implements the general purpose low level text rendering mechanism that can be
		controlled in derived classes by overriding the @RenderValue and @RenderColor
		properties. To disable the built-in rendering, return `null` from @RenderValue.
	*/
	public abstract partial class TextControl : IValue<string>
	{
		string _value = "";
		[UXOriginSetter("SetValue"), UXContent]
		public string Value
		{
			get { return _value; }
			set { SetValue(value, this); }
		}

		public void SetValue(string value, IPropertyListener origin)
		{
			var newValue = value ?? "";
			bool forced = EnforceMaxLength(ref newValue);

			if (forced || _value != newValue)
			{
				_value = newValue;

				var edit = GetITextView();
				if (edit != null)
					edit.Value = _value;

				OnValueChanged(origin);
				InvalidateTextRenderer();
			}
		}

		/** Sets the value without notifying the native view.
			Used by ITextEditHost implementation in TextEdit.
		*/
		protected void SetValueInternal(string newValue)
		{
			if (_value != newValue)
			{
				_value = newValue;
				OnValueChanged(this);
			}
		}

		public event ValueChangedHandler<string> ValueChanged;

		int _maxLength = 0;
		/** Specifies the max number of characters that the Value can have
		*/
		public int MaxLength
		{
			get { return _maxLength; }
			set
			{
				if (_maxLength != value)
				{
					_maxLength = value;
					OnMaxLengthChanged();
					var v = Value;
					if (EnforceMaxLength(ref v)) Value = v;
				}
			}
		}

		bool EnforceMaxLength(ref string v)
		{
			if (MaxLength > 0 && v.Length > MaxLength)
			{
				v = v.Substring(0, MaxLength);
				return true;
			}
			return false;
		}

		/** Specifies how the TextControl is going to wrap its text
		*/
		public TextWrapping TextWrapping
		{
			get { return Get(FastProperty2.TextWrapping, TextWrapping.NoWrap); }
			set
			{
				if (TextWrapping != value)
				{
					Set(FastProperty2.TextWrapping, value, TextWrapping.NoWrap);
					OnTextWrappingChanged();
				}
			}
		}

		/** Specifies the spacing in points between each line of text
		*/
		public float LineSpacing
		{
			get { return Get(FastProperty2.LineSpacing, 1.0f); }
			set
			{
				if (LineSpacing != value)
				{
					Set(FastProperty2.LineSpacing, value, 1.0f);
					OnLineSpacingChanged();
				}
			}
		}

		float _fontSize = Font.PlatformDefaultSize;
		public float FontSize
		{
			get
			{
				return _fontSize;
			}
			set
			{
				if (_fontSize != value)
				{
					_fontSize = value;

					OnFontSizeChanged();
					InvalidateVisual();
				}
			}
		}

		public float FontSizeScaled
		{
			get
			{
				if defined(IGNORE_FONT_SCALING)
					return _fontSize;
				if (_minFontScale == 0 && _maxFontScale == 0)
					return _fontSize * SystemUI.TextScaleFactor;
				else
				{
					if (_minFontScale == 1 && _maxFontScale == 1)
						return _fontSize;
					else
						return _fontSize * Math.Max(_minFontScale, Math.Min(_maxFontScale, SystemUI.TextScaleFactor));
				}
			}
		}

		/**
		Specifies the maximum text scale factor to accommodate if there is a change in the phone setting (Text Accessibility)

		Set value `MaxFontScale` and `MinFontScale` to 1 if you want to ignore the text scale factor value that has been set in the phone setting.
		Or if you want to ignore completely the font text scaling in your app, you can add `IGNORE_FONT_SCALING` compiler flag when building the app
		*/
		float _maxFontScale = 0.0f;
		public float MaxFontScale
		{
			get
			{
				return _maxFontScale;
			}
			set
			{
				if (_maxFontScale != value)
				{
					_maxFontScale = value;

					OnFontSizeChanged();
					InvalidateVisual();
				}
			}
		}

		/**
		Specifies the minimum text scale factor to accommodate if there is a change in the phone setting (Text Accessibility)

		Set value `MaxFontScale` and `MinFontScale` to 1 if you want to ignore the text scale factor value that has been set in the phone setting.
		Or if you want to ignore completely the font text scaling in your app, you can add `IGNORE_FONT_SCALING` compiler flag when building the app
		*/
		float _minFontScale = 0.0f;
		public float MinFontScale
		{
			get
			{
				return _minFontScale;
			}
			set
			{
				if (_minFontScale != value)
				{
					_minFontScale = value;

					OnFontSizeChanged();
					InvalidateVisual();
				}
			}
		}

		Font _font;
		[UXContent]
		public Font Font
		{
			get { return _font ?? Font.PlatformDefault; }
			set
			{
				if (_font != value)
				{
					_font = value;
					OnFontChanged();
				}
			}
		}

		public TextAlignment TextAlignment
		{
			get { return Get(FastProperty2.TextAlignment, TextAlignment.Left); }
			set
			{
				if (TextAlignment != value)
				{
					Set(FastProperty2.TextAlignment, value, TextAlignment.Left);
					OnTextAlignmentChanged();
				}
			}
		}


		/** The color of the text.

			`Color` is an alias for this property, which is recommended to use for consistency.
		*/
		public float4 TextColor
		{
			get { return Color; }
			set { Color = value; }
		}

		float4 _color = Font.PlatformDefaultTextColor;

		/**
			The color of the text (alias for @TextColor).

		 	For more information on what notations Color supports, check out [this subpage](articles:ux-markup/literals#colors).
		*/
		[UXOriginSetter("SetColor")]
		public float4 Color
		{
			get { return _color; }
			set
			{
				SetColor(value, this);
			}
		}
		public void SetColor(float4 color, IPropertyListener origin)
		{
			if (_color != color)
			{
				_color = color;
				OnColorChanged(origin);
			}
		}

		public virtual TextTruncation TextTruncation
		{
			get { return Get(FastProperty2.TextTruncation, TextTruncation.Standard); }
			set
			{
				if (TextTruncation != value)
				{
					Set(FastProperty2.TextTruncation, value, TextTruncation.Standard);
					OnTextTruncationChanged();
				}
			}
		}

		bool _loadAsync;
		protected bool InternalLoadAsync
		{
			get { return _loadAsync; }
			set
			{
				if (_loadAsync != value)
				{
					_loadAsync = value;
					OnLoadAsyncChanged();
				}
			}
		}
	}
}
