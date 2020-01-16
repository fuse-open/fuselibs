using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Uno.Graphics.Utils.Text;
using Uno.Graphics;
using Uno.Runtime.InteropServices;
using Uno.Threading;
using Uno;

namespace Fuse.Text.Implementation
{
	extern(DOTNET || CPlusPlus) class FreeTypeFontFace : FontFace
	{
		readonly byte[] _faceBuffer;
		extern(DOTNET) GCHandle _faceBufferHandle;
		protected IntPtr _ftFace;
		readonly object _faceMutex = new object();
		static readonly object _freeTypeMutex = new object();

		public FreeTypeFontFace(byte[] buffer, int index, Predicate<string> stylePredicate)
		{
			_faceBuffer = buffer;
			if defined(DOTNET)
			{
				_faceBufferHandle = GCHandle.Alloc(_faceBuffer, GCHandleType.Pinned);
			}
			lock (_freeTypeMutex)
			{
				if (index >= 0)
				{
					FreeType.New_Memory_Face(buffer, index, ref _ftFace);
					return;
				}

				FreeType.New_Memory_Face(buffer, 0, ref _ftFace);
				if (stylePredicate != null && !stylePredicate(FreeType.Style_Name(_ftFace)))
				{
					var numFaces = FreeType.Num_Faces(_ftFace);
					for (int i = 1; i < numFaces; ++i)
					{
						FreeType.Done_Face(_ftFace);
						FreeType.New_Memory_Face(buffer, i, ref _ftFace);
						if (stylePredicate(FreeType.Style_Name(_ftFace)))
						{
							return;
						}
					}
					throw new Exception("FreeType: No matching face in font file");
				}
			}
		}

		public FreeTypeFontFace(string fileName, int index, Predicate<string> stylePredicate)
		{
			lock (_freeTypeMutex)
			{
				if (index >= 0)
				{
					FreeType.New_Face(fileName, index, ref _ftFace);
					return;
				}
				FreeType.New_Face(fileName, 0, ref _ftFace);
				if (stylePredicate != null && !stylePredicate(FreeType.Style_Name(_ftFace)))
				{
					var numFaces = FreeType.Num_Faces(_ftFace);
					for (int i = 1; i < numFaces; ++i)
					{
						FreeType.Done_Face(_ftFace);
						FreeType.New_Face(fileName, i, ref _ftFace);
						if (stylePredicate(FreeType.Style_Name(_ftFace)))
						{
							return;
						}
					}
					throw new Exception("FreeType: No matching face in font file");
				}
			}
		}

		public override void Dispose()
		{
			base.Dispose();
			if defined(DOTNET)
			{
				_faceBufferHandle.Free();
				_faceBufferHandle = default(GCHandle);
			}
			lock (_freeTypeMutex)
			{
				if (_ftFace != IntPtr.Zero)
				{
					FreeType.Done_Face(_ftFace);
					_ftFace = IntPtr.Zero;
				}
			}
		}

		public string FamilyName
		{
			get
			{
				lock (_faceMutex)
					return FreeType.Family_Name(_ftFace);
			}
		}

		public string StyleName
		{
			get
			{
				lock (_faceMutex)
					return FreeType.Style_Name(_ftFace);
			}
		}

		override Font GetOfPixelSizeInternal(int pixelSize)
		{
			lock (_faceMutex)
			{
				IntPtr ftSize = IntPtr.Zero;
				FreeType.New_Size(_ftFace, ref ftSize);
				FreeType.Activate_Size(ftSize);
				float scale;
				FreeType.Set_Pixel_Sizes(_ftFace, 0, pixelSize, out scale);
				return new FreeTypeFont(_ftFace, ftSize, pixelSize, scale);
			}
		}
	}

	extern(DOTNET || CPlusPlus) class FreeTypeFont : HarfbuzzFont
	{
		readonly int _pixelSize;
		public override int PixelSize { get { return _pixelSize; } }
		readonly IntPtr _ftFace; // FT_Face
		IntPtr _ftSize; // FT_Size
		readonly object _faceMutex = new object();
		readonly float _scale;
		protected override float Scale { get { return _scale; } }

		// Note; Takes ownership of ftSize
		internal FreeTypeFont(IntPtr ftFace, IntPtr ftSize, int pixelSize, float scale)
			: base(Harfbuzz.ft_font_create(ftFace))
		{
			Harfbuzz.ft_font_set_default_load_flags(_hbFont);
			Harfbuzz.ft_font_cached_set_funcs(_hbFont);
			_ftFace = ftFace;
			_ftSize = ftSize;
			_pixelSize = pixelSize;
			_scale = scale;
		}

		public override void Dispose()
		{
			base.Dispose();
			lock (_faceMutex)
			{
				if (_ftSize != IntPtr.Zero)
				{
					FreeType.Done_Size(_ftSize);
					_ftSize = IntPtr.Zero;
				}
			}
		}

		public override float Ascender
		{
			get
			{
				lock (_faceMutex)
				{
					FreeType.Activate_Size(_ftSize);
					return base.Ascender;
				}
			}
		}

		public override float Descender
		{
			get
			{
				lock (_faceMutex)
				{
					FreeType.Activate_Size(_ftSize);
					return base.Descender;
				}
			}
		}

		public override float LineHeight
		{
			get
			{
				lock (_faceMutex)
				{
					FreeType.Activate_Size(_ftSize);
					return base.LineHeight;
				}
			}
		}

		public override int NumGlyphs
		{
			get
			{
				lock (_faceMutex)
				{
					return FreeType.Num_Glyphs(_ftFace);
				}
			}
		}

		// Note: Not thread safe, so take care (it's expected to be run
		// from the glyph cache, which will already be mutex guarded).
		public override RenderedGlyph Render(Glyph glyph)
		{
			FreeType.Activate_Size(_ftSize);
			FreeType.Load_Render_Glyph(_ftFace, glyph.Index);

			var bitmap = FreeType.Current_Glyph_Bitmap(_ftFace);
			var offset = (float2)FreeType.Current_Glyph_Bitmap_Offset(_ftFace) * Scale;
			return new RenderedGlyph(
				bitmap,
				float2(offset.X, base.LineHeight - base.Ascender - base.Descender - offset.Y),
				Scale);
		}

		public override PositionedGlyph[] Shape(Substring text, int fontIndex, TextDirection dir)
		{
			lock (_faceMutex)
			{
				FreeType.Activate_Size(_ftSize);
				return base.Shape(text, fontIndex, dir);
			}
		}
	}
}
