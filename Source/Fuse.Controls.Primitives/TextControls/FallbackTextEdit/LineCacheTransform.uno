using Uno;
using Uno.Collections;
using Uno.Graphics.Utils.Text;
using Fuse.Controls.FallbackTextRenderer;

namespace Fuse.Controls.FallbackTextEdit
{
	//The LineCache mechanism only supports a transform that does a 1:1 character  line-by-line mapping
	interface LineCacheTransform
	{
		string Transform( string text );
	}

	class LineCachePasswordTransform : LineCacheTransform
	{
		int _reveal = -1;
		public bool SetReveal( int r ) 
		{
			var b = r != _reveal;
			_reveal = r;
			return b;
		}
		
		public string Transform( string text )
		{
			if (string.IsNullOrEmpty(text)) return text;

			char replacement = '\u2022';

			char[] buffer = new char[text.Length];
			for (int i = 0; i < buffer.Length; ++i)
				buffer[i] = replacement;

			if (_reveal != -1)
				buffer[_reveal] = text[_reveal];

			return new string(buffer);
		}
	}
}