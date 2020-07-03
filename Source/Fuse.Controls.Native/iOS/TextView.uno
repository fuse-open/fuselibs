using Uno;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Controls.Native.iOS
{
	extern(!iOS) public class TextView { }

	[Require("Source.Include", "UIKit/UIKit.h")]
	extern(iOS) public class TextView : LeafView, ITextView
	{

		public TextView(ObjC.Object handle) : base(handle) { }

		public TextView() : this(Create()) { }

		[Foreign(Language.ObjC)]
		static ObjC.Object Create()
		@{
			auto label = [[::UILabel alloc] init];
			label.numberOfLines = 0;
			return label;
		@}

		readonly NSAttributedStringBuilder _builder = new NSAttributedStringBuilder();

		string ITextView.Value
		{
			set
			{
				_builder.SetValue(value);
				UpdateText();
			}
		}

		int ITextView.MaxLength
		{
			set { }
		}

		TextWrapping ITextView.TextWrapping
		{
			set
			{
				_builder.SetTextWrapping(value);
				UpdateText();
			}
		}

		float ITextView.LineSpacing
		{
			set
			{
				_builder.SetLineSpacing(value);
				UpdateText();
			}
		}

		float _fontSize = 12.0f;
		float ITextView.FontSize
		{
			set
			{
				_fontSize = value;
				((ITextView)this).Font = _font;
			}
		}

		TextAlignment ITextView.TextAlignment
		{
			set
			{
				_builder.SetTextAlignment(value);
				UpdateText();
			}
		}

		Font _font;
		Font ITextView.Font
		{
			set
			{
				_font = value;
				if (value == null)
					return;

				if (value.Descriptors.Count > 0)
				{
					var font = FontCache.Get(value.Descriptors[0], _fontSize);
					_builder.SetFont(font);
					UpdateText();
				}
			}
		}

		float4 ITextView.TextColor
		{
			set
			{
				_builder.SetTextColor(value);
				UpdateText();
			}
		}

		TextTruncation ITextView.TextTruncation
		{
			set
			{
				if (value == TextTruncation.Standard)
					SetTextTruncation(Handle);
			}
		}

		void UpdateText()
		{
			SetValue(Handle, _builder.BuildAttributedString());
		}

		[Foreign(Language.ObjC)]
		static void SetValue(ObjC.Object handle, ObjC.Object attributedString)
		@{
			::UILabel* label = (::UILabel*)handle;
			label.attributedText = (NSAttributedString*)attributedString;
		@}

		[Foreign(Language.ObjC)]
		static void SetTextTruncation(ObjC.Object handle)
		@{
			::UILabel* label = (::UILabel*)handle;
			label.numberOfLines = 1;
			label.lineBreakMode = NSLineBreakByTruncatingTail;
		@}
	}
}
