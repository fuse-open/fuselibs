using Uno.Compiler.ExportTargetInterop;
using Uno.Graphics.Utils.Text;
using Uno.Graphics.Utils;
using Uno.Graphics;
using Uno.Text;
using Uno;

namespace Fuse.Text.Implementation
{
	[Require("Source.Include", "ft2build.h")]
	[Require("Source.Declaration", "#include FT_FREETYPE_H")]
	static extern(DOTNET || CPlusPlus || PInvoke) class FT_Error
	{
		public static void Check(int err)
		{
			if (err != 0)
			{
				throw new Exception("FreeType error: " + ErrorString(err));
			}
		}

		static string ErrorString(int err)
		{
			return CString.ToString(ErrorCString(err));
		}

		[Foreign(Language.CPlusPlus)]
		static IntPtr ErrorCString(int err)
		@{
			#undef __FTERRORS_H__
			#define FT_ERRORDEF(e, v, s) case e: return (void*)s;
			#define FT_ERROR_START_LIST switch (err) {
			#define FT_ERROR_END_LIST default: return nullptr; }
			#include FT_ERRORS_H
		@}
	}

	[Require("Source.Include", "ft2build.h")]
	[Require("Source.Include", "climits")]
	[Require("Source.Declaration", "#include FT_FREETYPE_H")]
	[Require("Source.Declaration", "#include FT_SIZES_H")]
	[extern(PInvoke) Require("LinkLibrary", "freetype")]
	[extern(PInvoke) Require("LinkLibrary", "z")]
	[extern(PInvoke) Require("LinkLibrary", "png")]
	[extern(PInvoke && OSX) Require("LinkLibrary", "bz2")]
	static extern(DOTNET || CPlusPlus || PInvoke) class FreeType
	{
		static IntPtr _library;
		static bool _initialized;
		static IntPtr Library
		{
			get
			{
				Init();
				return _library;
			}
		}

		static void Init()
		{
			if (_initialized) return;

			FT_Error.Check(Init_FreeType(ref _library));

			// TODO
			/* @{
				atexit([](){ @{Done():Call()}; });
			@} */
			_initialized = true;
		}

		[Foreign(Language.CPlusPlus)]
		static int Init_FreeType(ref IntPtr library)
		@{
			return FT_Init_FreeType((FT_Library*)library);
		@}

		[Foreign(Language.CPlusPlus)]
		static void Done(IntPtr library)
		@{
			FT_Done_FreeType((FT_Library)library);
		@}

		public static void New_Memory_Face(byte[] buffer, int index, ref IntPtr face)
		{
			FT_Error.Check(New_Memory_Face_Raw(Library, buffer, buffer.Length, index, ref face));
		}

		[Foreign(Language.CPlusPlus)]
		static int New_Memory_Face_Raw(IntPtr library, byte[] buffer, int length, int index, ref IntPtr face)
		@{
			return FT_New_Memory_Face((FT_Library)library, (FT_Byte*)buffer, (FT_Long)length, (FT_Long)index, (FT_Face*)face);
		@}

		public static void New_Face(string fileName, int index, ref IntPtr face)
		{
			var cStr = Utf8.GetBytes(fileName);
			var len = cStr.Length;
			var ntCStr = new byte[len + 1];
			for (int i = 0; i < len; ++i)
			{
				ntCStr[i] = cStr[i];
			}
			ntCStr[len] = 0;
			FT_Error.Check(New_Face_Raw(Library, ntCStr, index, ref face));
		}

		[Foreign(Language.CPlusPlus)]
		static int New_Face_Raw(IntPtr library, byte[] fileName, int index, ref IntPtr face)
		@{
			return FT_New_Face((FT_Library)library, (const char*)fileName, (FT_Long)index, (FT_Face*)face);
		@}

		public static void Done_Face(IntPtr face)
		{
			FT_Error.Check(Done_Face_Raw(face));
		}

		[Foreign(Language.CPlusPlus)]
		static int Done_Face_Raw(IntPtr face)
		@{
			return FT_Done_Face((FT_Face)face);
		@}

		public static void New_Size(IntPtr face, ref IntPtr size)
		{
			FT_Error.Check(New_Size_Raw(face, ref size));
		}

		[Foreign(Language.CPlusPlus)]
		static int New_Size_Raw(IntPtr face, ref IntPtr size)
		@{
			return FT_New_Size((FT_Face)face, (FT_Size*)size);
		@}

		public static void Done_Size(IntPtr size)
		{
			FT_Error.Check(Done_Size_Raw(size));
		}

		[Foreign(Language.CPlusPlus)]
		static int Done_Size_Raw(IntPtr size)
		@{
			return FT_Done_Size((FT_Size)size);
		@}

		public static void Activate_Size(IntPtr size)
		{
			FT_Error.Check(Activate_Size_Raw(size));
		}

		[Foreign(Language.CPlusPlus)]
		static int Activate_Size_Raw(IntPtr size)
		@{
			return FT_Activate_Size((FT_Size)size);
		@}

		public static void Set_Pixel_Sizes(IntPtr face, int w, int h, out float scale)
		{
			scale = 1;
			FT_Error.Check(Set_Pixel_Sizes_Raw(face, w, h, ref scale));
		}

		[Foreign(Language.CPlusPlus)]
		static int Set_Pixel_Sizes_Raw(IntPtr rawFace, int w, int h, ref float scale)
		@{
			*scale = 1.0f;
			FT_Face face = (FT_Face)rawFace;
			if (FT_IS_SCALABLE(face))
			{
				return FT_Set_Pixel_Sizes(face, (FT_UInt)w, (FT_UInt)h);
			}
			else if (FT_HAS_FIXED_SIZES(face))
			{
				w *= 64; // 26.6 fractional pixels
				h *= 64;
				int bestIndex = -1;
				int bestDiff = INT_MAX;
				for (int i = 0; i < face->num_fixed_sizes; ++i)
				{
					int w2 = (int)face->available_sizes[i].x_ppem;
					int h2 = (int)face->available_sizes[i].y_ppem;
					int xdiff = w - w2;
					int ydiff = h - h2;
					int diff = xdiff * xdiff + ydiff * ydiff;
					if (diff < bestDiff)
					{
						*scale = h == 0
							? (w == 0 ? 1.0f : (float)w / (float)w2)
							: (float)h / (float)h2;
						bestIndex = i;
						bestDiff = diff;
					}
				}
				if (bestIndex != -1)
				{
					return FT_Select_Size(face, bestIndex);
				}
			}
			return 0x17; // Invalid pixel size
		@}

		public static void Load_Render_Glyph(IntPtr face, uint glyph)
		{
			FT_Error.Check(Load_Render_Glyph_Raw(face, glyph));
		}

		[Foreign(Language.CPlusPlus)]
		static int Load_Render_Glyph_Raw(IntPtr face, uint glyph)
		@{
			return FT_Load_Glyph((FT_Face)face, glyph, FT_LOAD_DEFAULT | FT_LOAD_RENDER | FT_LOAD_COLOR);
		@}

		public static void Load_Glyph(IntPtr face, uint glyph, int flags)
		{
			FT_Error.Check(Load_Glyph_Raw(face, glyph, flags));
		}

		[Foreign(Language.CPlusPlus)]
		static int Load_Glyph_Raw(IntPtr face, uint glyph, int flags)
		@{
			return FT_Load_Glyph((FT_Face)face, glyph, flags);
		@}

		public static int2 Current_Glyph_Bitmap_Size(IntPtr face)
		{
			var result = int2(0);
			Current_Glyph_Bitmap_Size_Raw(face, ref result.X, ref result.Y);
			return result;
		}

		[Foreign(Language.CPlusPlus)]
		static void Current_Glyph_Bitmap_Size_Raw(IntPtr face, ref int width, ref int rows)
		@{
			*width = ((FT_Face)face)->glyph->bitmap.width;
			*rows = ((FT_Face)face)->glyph->bitmap.rows;
		@}

		public static int2 Current_Glyph_Bitmap_Offset(IntPtr face)
		{
			var result = int2(0);
			Current_Glyph_Bitmap_Offset_Raw(face, ref result.X, ref result.Y);
			return result;
		}

		[Foreign(Language.CPlusPlus)]
		static void Current_Glyph_Bitmap_Offset_Raw(IntPtr face, ref int x, ref int y)
		@{
			FT_Face f = (FT_Face)face;
			*x = f->glyph->bitmap_left;
			*y = f->glyph->bitmap_top;
		@}

		[Foreign(Language.CPlusPlus)]
		static IntPtr Current_Glyph_Bitmap_Buffer(IntPtr face)
		@{
			return (void*)((FT_Face)face)->glyph->bitmap.buffer;
		@}

		[Foreign(Language.CPlusPlus)]
		static bool Current_Glyph_Bitmap_Buffer_Is_BGRA(IntPtr face)
		@{
			return ((FT_Face)face)->glyph->bitmap.pixel_mode == FT_PIXEL_MODE_BGRA;
		@}

		public static Bitmap Current_Glyph_Bitmap(IntPtr face)
		{
			int2 size = Current_Glyph_Bitmap_Size(face);
			if (Current_Glyph_Bitmap_Buffer_Is_BGRA(face))
			{
				var numBytes = size.X * size.Y * 4;
				var data = new byte[numBytes];
				Memory.Copy(data, Current_Glyph_Bitmap_Buffer(face), numBytes);
				BGRAToRGBA(data);
				return new Bitmap(size, Format.RGBA8888, data);
			}
			else // grayscale
			{
				var numBytes = size.X * size.Y;
				var data = new byte[numBytes];
				Memory.Copy(data, Current_Glyph_Bitmap_Buffer(face), numBytes);
				return new Bitmap(size, Format.L8, data);
			}
		}

		public static void BGRAToRGBA(byte[] buffer)
		{
			for (int i = 0; i < buffer.Length; i += 4)
			{
				var b = buffer[i + 0];
				var r = buffer[i + 2];
				buffer[i + 0] = r;
				buffer[i + 2] = b;
			}
		}

		[Foreign(Language.CPlusPlus)]
		public static int Ascender(IntPtr face)
		@{
			return (int)((FT_Face)face)->size->metrics.ascender;
		@}

		[Foreign(Language.CPlusPlus)]
		public static int Descender(IntPtr face)
		@{
			return (int)((FT_Face)face)->size->metrics.descender;
		@}

		[Foreign(Language.CPlusPlus)]
		public static int Height(IntPtr face)
		@{
			return (int)((FT_Face)face)->size->metrics.height;
		@}

		public static string Family_Name(IntPtr face)
		{
			return CString.ToString(Family_Name_Raw(face));
		}

		[Foreign(Language.CPlusPlus)]
		static IntPtr Family_Name_Raw(IntPtr face)
		@{
			return ((FT_Face)face)->family_name;
		@}

		public static string Style_Name(IntPtr face)
		{
			return CString.ToString(Style_Name_Raw(face));
		}

		[Foreign(Language.CPlusPlus)]
		static IntPtr Style_Name_Raw(IntPtr face)
		@{
			return ((FT_Face)face)->style_name;
		@}

		[Foreign(Language.CPlusPlus)]
		public static int Num_Faces(IntPtr face)
		@{
			return (int)((FT_Face)face)->num_faces;
		@}

		[Foreign(Language.CPlusPlus)]
		public static int Num_Glyphs(IntPtr face)
		@{
			return (int)((FT_Face)face)->num_glyphs;
		@}
	}
}
