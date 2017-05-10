using Uno;
using Uno.UX;
using Uno.Platform;
using Fuse.Input;
using Fuse.Internal;
using Fuse.Scripting;
using Fuse.Internal.Drawing;
using Uno.Diagnostics;
using Fuse.Elements;
using Fuse.Scripting;
using Fuse.Controls.Native;

namespace Fuse.Controls
{
	/**
		Allows TextEdit and TextInput to be treated the same in triggers.
	*/
	public interface ITextEditControl
	{
		event TextInputActionHandler ActionTriggered;
		bool IsPassword { get; set; }
	}
	
	abstract class TextEdit : TextControl, ITextEditControl
	{
		readonly bool _isMultiline;
		protected bool IsMultiline { get { return _isMultiline; } }

		protected TextEdit(bool multiline)
		{
			_isMultiline = multiline;
			Focus.SetIsFocusable(this, true);
			ClipToBounds = true;
		}

		static readonly Selector IsPasswordPropertyName = "IsPassword";
		static readonly Selector IsReadOnlyPropertyName = "IsReadOnly";
		static readonly Selector InputHintPropertyName = "InputHint";
		static readonly Selector CaretColorPropertyName = "CaretColor";
		static readonly Selector SelectionColorPropertyName = "SelectionColor";
		static readonly Selector ActionStylePropertyName = "ActionStyle";
		static readonly Selector AutoCorrectHintPropertyName = "AutoCorrectHint";
		static readonly Selector AutoCapitalizationHintPropertyName = "AutoCapitalizationHint";
		static readonly Selector PlaceholderTextPropertyName = "PlaceholderText";
		static readonly Selector PlaceholderColorPropertyName = "PlaceholderColor";

		public bool IsPassword
		{
			get { return HasBit(FastProperty2.IsPassword);}
			set 
			{ 
				if (IsPassword != value)
				{
					SetBit(FastProperty2.IsPassword, value);
					OnIsPasswordChanged();
				}
			}
		}
		protected virtual void OnIsPasswordChanged()
		{
			OnPropertyChanged(IsPasswordPropertyName);
			InvalidateLayout();
			InvalidateRenderBounds();
		}


		public bool IsReadOnly
		{
			get { return HasBit(FastProperty2.IsReadOnly);}
			set 
			{ 
				if (IsReadOnly != value)
				{
					SetBit(FastProperty2.IsReadOnly, value);
					OnIsReadOnlyChanged();	
				}
			}
		}
		protected virtual void OnIsReadOnlyChanged()
		{
			OnPropertyChanged(IsReadOnlyPropertyName);
		}


		public TextInputHint InputHint
		{
			get { return Get(FastProperty2.InputHint, TextInputHint.Default); }
			set 
			{ 
				if (InputHint != value)
				{
					Set(FastProperty2.InputHint, value, TextInputHint.Default);
					OnInputHintChanged();
				}
			}
		}
		protected virtual void OnInputHintChanged()
		{
			OnPropertyChanged(InputHintPropertyName);
		}


		public float4 CaretColor
		{
			get { return Get(FastProperty2.CaretColor, float4(0,0,0,1)); }
			set 
			{ 
				if (CaretColor != value)
				{
					Set(FastProperty2.CaretColor, value, float4(0,0,0,1));
					OnCaretColorChanged();
				}
			}
		}
		protected virtual void OnCaretColorChanged()
		{
			OnPropertyChanged(CaretColorPropertyName);
			InvalidateVisual();
		}


		public float4 SelectionColor
		{
			get { return Get(FastProperty2.SelectionColor, float4(.6f, .8f, 1.0f, .5f)); }
			set 
			{ 
				if (SelectionColor != value)
				{
					Set(FastProperty2.SelectionColor, value, float4(.6f, .8f, 1.0f, .5f));
					OnSelectionColorChanged();
				}
			}
		}
		protected virtual void OnSelectionColorChanged()
		{
			OnPropertyChanged(SelectionColorPropertyName);
			InvalidateVisual();
		}


		public TextInputActionStyle ActionStyle
		{
			get { return Get(FastProperty2.ActionStyle, TextInputActionStyle.Next); }
			set 
			{
				if (ActionStyle != value)
				{
					Set(FastProperty2.ActionStyle, value, TextInputActionStyle.Next);
					OnActionStyleChanged();
				}
			}
		}
		protected virtual void OnActionStyleChanged()
		{
			OnPropertyChanged(ActionStylePropertyName);
		}


		public AutoCorrectHint AutoCorrectHint
		{
			get { return Get(FastProperty2.AutoCorrectHint, AutoCorrectHint.Default); }
			set 
			{ 
				if (AutoCorrectHint != value)
				{
					Set(FastProperty2.AutoCorrectHint, value, AutoCorrectHint.Default);
					OnAutoCorrectHintChanged();
				}
			}
		}
		protected virtual void OnAutoCorrectHintChanged()
		{
			OnPropertyChanged(AutoCorrectHintPropertyName);
		}


		public AutoCapitalizationHint AutoCapitalizationHint
		{
			get { return Get(FastProperty2.AutoCapitalizationHint, AutoCapitalizationHint.None); }
			set 
			{ 
				if (AutoCapitalizationHint != value)
				{
					Set(FastProperty2.AutoCapitalizationHint, value, AutoCapitalizationHint.None);
					OnAutoCapitalizationHintChanged();
				}
			}
		}
		protected virtual void OnAutoCapitalizationHintChanged()
		{
			OnPropertyChanged(AutoCapitalizationHintPropertyName);
		}


		public string PlaceholderText
		{
			get { return Get(FastProperty2.PlaceholderText, ""); }
			set 
			{ 
				if (PlaceholderText != value)
				{
					Set(FastProperty2.PlaceholderText, value ?? string.Empty, "");
					OnPlaceholderTextChanged();
				}
			}
		}
		protected virtual void OnPlaceholderTextChanged()
		{
			OnPropertyChanged(PlaceholderTextPropertyName);
			InvalidateLayout();
			InvalidateRenderBounds();
		}

		public float4 PlaceholderColor
		{
			get { return Get(FastProperty2.PlaceholderColor, float4(0,0,0,1)); }
			set 
			{ 
				if (PlaceholderColor != value)
				{
					Set(FastProperty2.PlaceholderColor, value, float4(0,0,0,1));
					OnPlaceholderColorChanged();
				}
			}
		}
		protected virtual void OnPlaceholderColorChanged()
		{
			OnPropertyChanged(PlaceholderColorPropertyName);
			InvalidateVisual();
		}

		public override TextTruncation TextTruncation
		{
			get { return Get(FastProperty2.TextTruncation, TextTruncation.None); }
			set
			{
				if (TextTruncation != value)
				{
					Set(FastProperty2.TextTruncation, value, TextTruncation.None);
					OnTextTruncationChanged();
				}
			}
		}

		public event TextInputActionHandler	 ActionTriggered;

		internal bool OnAction(TextInputActionType type)
		{
			if (ActionTriggered != null)
			{
				var args = new TextInputActionArgs(this, type);
				ActionTriggered(this, args);
				return true;
			}

			//just assume we have only a single "primary" action for now
			if (ActionStyle == TextInputActionStyle.Next)
				Focus.Move(FocusNavigationDirection.Down);
				
			return true;
		}
		
		protected override VisualBounds CalcRenderBounds()
		{
			var b = base.CalcRenderBounds();
			//mortoray: This is a bit of a backwards compatible hack (Element used to do this). Ideally
			//the bits and peices actually reponsive for this render bounds should do this
			b = b.AddRect(float2(0),ActualSize);
			return b;
		}
	}
}
