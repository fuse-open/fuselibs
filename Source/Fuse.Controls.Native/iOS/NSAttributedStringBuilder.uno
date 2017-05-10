using Uno;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Controls.Native.iOS
{
	[Require("Source.Include", "Foundation/Foundation.h")]
	extern(iOS) internal class NSAttributedStringBuilder
	{

		float4 _color = float4(0.0f, 0.0f, 0.0f, 1.0f);
		float _lineSpacing = 0.0f;
		string _value;
		ObjC.Object _font;
		TextAlignment _alignment;
		TextWrapping _textWrapping;

		public NSAttributedStringBuilder() { }

		[Foreign(Language.ObjC)]
		static ObjC.Object NewDictionary()
		@{
			return [[NSMutableDictionary alloc] init];
		@}

		public NSAttributedStringBuilder SetValue(string value)
		{
			_value = value;
			return this;
		}

		public NSAttributedStringBuilder SetTextColor(float4 color)
		{
			_color = color;
			return this;
		}

		public NSAttributedStringBuilder SetLineSpacing(float lineSpacing)
		{
			_lineSpacing = lineSpacing;
			return this;
		}

		public NSAttributedStringBuilder SetFont(ObjC.Object font)
		{
			_font = font;
			return this;
		}

		public NSAttributedStringBuilder SetTextAlignment(TextAlignment alignment)
		{
			_alignment = alignment;
			return this;
		}

		public NSAttributedStringBuilder SetTextWrapping(TextWrapping wrapping)
		{
			_textWrapping = wrapping;
			return this;
		}

		int GetTextAlignment(TextAlignment alignment)
		{
			int nsAlignment = 0;
			switch(alignment)
			{
				case TextAlignment.Left: nsAlignment = extern<int>"NSTextAlignmentLeft"; break;
				case TextAlignment.Center: nsAlignment = extern<int>"NSTextAlignmentCenter"; break;
				case TextAlignment.Right: nsAlignment = extern<int>"NSTextAlignmentRight"; break;
			}
			return nsAlignment;
		}

		public ObjC.Object BuildAttributedString()
		{
			return Create(_value ?? "", BuildAttributes());
		}

		public ObjC.Object BuildAttributes()
		{
			var attributes = NewDictionary();
			SetForegroundColor(attributes, _color.X, _color.Y, _color.Z, _color.W);
			SetParagraphStyle(attributes, _lineSpacing, GetTextAlignment(_alignment), (_textWrapping == TextWrapping.Wrap));
			SetFont(attributes, _font);
			return attributes;
		}

		[Foreign(Language.ObjC)]
		static ObjC.Object Create(string value, ObjC.Object attributes)
		@{
			return [[NSAttributedString alloc] initWithString:value attributes:attributes];
		@}

		[Foreign(Language.ObjC)]
		static void SetForegroundColor(ObjC.Object handle, float r, float g, float b, float a)
		@{
			auto dict = (NSMutableDictionary*)handle;
			auto color = [::UIColor colorWithRed:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b alpha:(CGFloat)a];
			dict[NSForegroundColorAttributeName] = color;
		@}

		[Foreign(Language.ObjC)]
		static void SetParagraphStyle(ObjC.Object handle, float lineSpacing, int textAlignment, bool wrapText)
		@{
			auto dict = (NSMutableDictionary*)handle;
			auto paragraphStyle = [[NSMutableParagraphStyle alloc] init];
			paragraphStyle.lineSpacing = lineSpacing;
			paragraphStyle.alignment = (NSTextAlignment)textAlignment;
			paragraphStyle.lineBreakMode = wrapText
				? NSLineBreakByWordWrapping
				: NSLineBreakByTruncatingTail;
			dict[NSParagraphStyleAttributeName] = paragraphStyle;
		@}

		[Foreign(Language.ObjC)]
		static void SetFont(ObjC.Object handle, ObjC.Object fontHandle)
		@{
			auto dict = (NSMutableDictionary*)handle;
			auto font = (UIFont*)fontHandle;
			if (font != nil)
				dict[NSFontAttributeName] = font;
		@}

	}
}