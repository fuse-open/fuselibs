using Uno.Compiler.ExportTargetInterop;
using Uno.Graphics.Utils.Text;
using Uno;

namespace Fuse.Text.Implementation
{
	[Require("Source.Include", "harfbuzz/hb.h")]
	[Require("Source.Include", "harfbuzz/hb-ft.h")]
	[Require("Source.Include", "hb-ft-cached.h")]
	[Require("Source.Include", "ft2build.h")]
	[Require("Source.Declaration", "#include FT_ADVANCES_H")]
	[extern(APPLE) Require("IncludeDirectory", "@('../harfbuzz/include':Path)")]
	[extern(ANDROID) Require("IncludeDirectory", "@('../harfbuzz/lib/Android/include':Path)")] // Android use a newer version of Harfbuzz
	[extern(WIN32) Require("IncludeDirectory", "@('../harfbuzz/lib/Windows/include':Path)")] // Windows use a newer version of Harfbuzz
	[extern(iOS) Require("Source.Include", "harfbuzz/hb-coretext.h")]
	[extern(iOS) Require("LinkDirectory", "@('../harfbuzz/lib/iOS':Path)")]
	[extern((PInvoke || NATIVE) && HOST_MAC) Require("LinkDirectory", "@('../harfbuzz/lib/OSX':Path)")]
	[extern((PInvoke || NATIVE) && HOST_MAC) Require("Xcode.Framework", "CoreText")]
	[extern(Android) Require("StaticLibrary", "@('../harfbuzz/lib/Android/lib/${ANDROID_ABI}/libharfbuzz.a':Path)")]
	[extern((PInvoke || NATIVE) && HOST_WINDOWS) Require("LinkDirectory", "@('../harfbuzz/lib/Windows':Path)")]
	[extern(!Android) Require("LinkLibrary", "harfbuzz")]
	[TargetSpecificImplementation]
	static extern(DOTNET || CPlusPlus || PInvoke) class Harfbuzz
	{
		[Foreign(Language.CPlusPlus)]
		public static IntPtr ft_font_create(IntPtr face)
		@{
			hb_font_t* result = hb_ft_font_create((FT_Face)face, NULL);
			return result;
		@}

		[Foreign(Language.CPlusPlus)]
		public static void ft_font_set_default_load_flags(IntPtr hbFont)
		@{
			hb_ft_font_set_load_flags((hb_font_t*)hbFont, FT_LOAD_DEFAULT);
		@}

		[Foreign(Language.CPlusPlus)]
		public static void ft_font_cached_set_funcs(IntPtr hbFont)
		@{
			hb_ft_font_cached_set_funcs((hb_font_t*)hbFont);
		@}

		[Foreign(Language.CPlusPlus)]
		public extern(iOS) static IntPtr ct_face_create(IntPtr cgFont)
		@{
			return hb_coretext_face_create((CGFontRef)cgFont);
		@}

		[Foreign(Language.CPlusPlus)]
		public static IntPtr font_create(IntPtr hbFace)
		@{
			return hb_font_create((hb_face_t*)hbFace);
		@}

		[Foreign(Language.CPlusPlus)]
		public static void font_destroy(IntPtr font)
		@{
			hb_font_destroy((hb_font_t*)font);
		@}

		[Foreign(Language.CPlusPlus)]
		public static void font_set_scale(IntPtr hbFont, int x_scale, int y_scale)
		@{
			hb_font_set_scale((hb_font_t*)hbFont, x_scale, y_scale);
		@}

		[Foreign(Language.CPlusPlus)]
		public static void face_destroy(IntPtr face)
		@{
			hb_face_destroy((hb_face_t*)face);
		@}

		public static IntPtr buffer_create(IntPtr font, Substring text, bool ltr)
		{
			return buffer_create_Raw(font, text._parent, text._start, text.Length, ltr);
		}

		[Foreign(Language.CPlusPlus)]
		static IntPtr buffer_create_Raw(IntPtr font, string text, int offset, int length, bool ltr)
		@{
			hb_buffer_t* buffer = hb_buffer_create();
			hb_buffer_pre_allocate(buffer, (unsigned int)length);

			hb_buffer_add_utf16(buffer, (uint16_t*)(text + offset), length, 0, -1);
			hb_buffer_set_direction(buffer, ltr ? HB_DIRECTION_LTR : HB_DIRECTION_RTL);
			hb_buffer_guess_segment_properties(buffer);
			hb_shape((hb_font_t*)font, buffer, NULL, 0);

			return (void*)buffer;
		@}

		[Foreign(Language.CPlusPlus)]
		public static uint buffer_get_length(IntPtr buffer)
		@{
			return hb_buffer_get_length((hb_buffer_t*)buffer);
		@}

		[Foreign(Language.CPlusPlus)]
		public static void buffer_destroy(IntPtr buffer)
		@{
			hb_buffer_destroy((hb_buffer_t*)buffer);
		@}

		[Foreign(Language.CPlusPlus)]
		public static void get_shape_data(IntPtr font, IntPtr buffer, byte[] output)
		@{
			unsigned int glyphCount = hb_buffer_get_length((hb_buffer_t*)buffer);
			hb_glyph_info_t* glyphInfo = hb_buffer_get_glyph_infos((hb_buffer_t*)buffer, nullptr);
			hb_glyph_position_t* glyphPos = hb_buffer_get_glyph_positions((hb_buffer_t*)buffer, nullptr);

			struct
			{
				uint32_t codepoint;
				uint32_t cluster;
				float x_advance; float y_advance;
				float x_offset; float y_offset;
			} current;

			for (unsigned int i = 0; i < glyphCount; ++i)
			{
				hb_glyph_info_t info = glyphInfo[i];
				hb_glyph_position_t pos = glyphPos[i];

				current.codepoint = info.codepoint;
				current.cluster = info.cluster;
				current.x_advance = pos.x_advance / 64.f;
				current.y_advance = pos.y_advance / 64.f;
				current.x_offset = pos.x_offset / 64.f;
				current.y_offset = pos.y_offset / 64.f;

				memcpy(output + sizeof(current) * i, &current, sizeof(current));
			}
		@}

		[Foreign(Language.CPlusPlus)]
		public static void font_get_h_extents(IntPtr font, ref float ascender, ref float descender, ref float lineGap)
		@{
			hb_font_extents_t extents;
			hb_font_get_h_extents((hb_font_t*)font, &extents);
			*ascender = extents.ascender / 64.f;
			*descender = - extents.descender / 64.f;
			*lineGap = extents.line_gap / 64.f;
		@}
	}
}
