using Uno.Collections;
using Uno;

namespace Fuse.Text.Implementation
{
	extern(DOTNET || CPlusPlus) abstract class HarfbuzzFont : Font
	{
		protected IntPtr _hbFont; // hb_font_t*

		// Note: Takes ownership of hbFont
		internal HarfbuzzFont(IntPtr hbFont)
		{
			_hbFont = hbFont;
		}

		public override void Dispose()
		{
			base.Dispose();
			if (_hbFont != IntPtr.Zero)
			{
				Harfbuzz.font_destroy(_hbFont);
				_hbFont = IntPtr.Zero;
			}
		}

		public override float Ascender
		{
			get
			{
				float ascender = 0.f; float descender = 0.f; float lineGap = 0.f;
				Harfbuzz.font_get_h_extents(_hbFont, ref ascender, ref descender, ref lineGap);
				return ascender * Scale;
			}
		}

		public override float Descender
		{
			get
			{
				float ascender = 0.f; float descender = 0.f; float lineGap = 0.f;
				Harfbuzz.font_get_h_extents(_hbFont, ref ascender, ref descender, ref lineGap);
				return descender * Scale;
			}
		}
		protected virtual float Scale { get { return 1.f; } }

		public override float LineHeight
		{
			get
			{
				float ascender = 0.f; float descender = 0.f; float lineGap = 0.f;
				Harfbuzz.font_get_h_extents(_hbFont, ref ascender, ref descender, ref lineGap);
				return (ascender + descender + lineGap) * Scale;
			}
		}

		public override PositionedGlyph[] Shape(Substring text, int fontIndex, TextDirection dir)
		{
			var buffer = Harfbuzz.buffer_create(_hbFont, text, dir == TextDirection.LeftToRight);

			var len = (int)Harfbuzz.buffer_get_length(buffer);
			var stride = sizeof(uint) * 2 + sizeof(float) * 4;
			var shapeData = new byte[len * stride];
			Harfbuzz.get_shape_data(_hbFont, buffer, shapeData);
			var result = new PositionedGlyph[len];

			var littleEndian = true;

			for (int i = 0; i < len; ++i)
			{
				var pos = i * stride;

				var codepoint = shapeData.GetUInt(pos, littleEndian);
				pos += sizeof(uint);

				var cluster = shapeData.GetUInt(pos, littleEndian);
				pos += sizeof(uint);

				var a1 = shapeData.GetFloat(pos, littleEndian);
				pos += sizeof(float);

				var a2 = shapeData.GetFloat(pos, littleEndian);
				pos += sizeof(float);

				var o1 = shapeData.GetFloat(pos, littleEndian);
				pos += sizeof(float);

				var o2 = shapeData.GetFloat(pos, littleEndian);
				pos += sizeof(float);

				var advance = Scale * float2(1, -1) * float2(a1, a2);
				var offset = Scale * float2(1, -1) * float2(o1, o2);
				result[i] = new PositionedGlyph(new Glyph(fontIndex, codepoint), advance, offset, (int)cluster);
			}

			Harfbuzz.buffer_destroy(buffer);
			return result;
		}
	}
}
