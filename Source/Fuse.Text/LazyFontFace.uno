using Fuse.Internal;
using Uno.Threading;

namespace Fuse.Text
{
	public class LazyFontFace : FontFace
	{
		FontFaceDescriptor _descriptor;
		FontFace _loadedFontFace;
		readonly object _loadedFontFaceMutex = new object();

		internal LazyFontFace(FontFaceDescriptor descriptor)
		{
			_descriptor = descriptor;
		}

		public override void Dispose()
		{
			base.Dispose();
			lock (_loadedFontFaceMutex)
			{
				if (_loadedFontFace != null)
				{
					_loadedFontFace.Dispose();
					_loadedFontFace = null;
				}
			}
		}

		override Font GetOfPixelSizeInternal(int size)
		{
			return new LazyFont(this, size);
		}

		internal FontFace Force()
		{
			if (_loadedFontFace == null)
			{
				lock (_loadedFontFaceMutex)
				{
					if (_loadedFontFace == null)
					{
						_loadedFontFace = FontFace.Load(_descriptor);
						_descriptor = null;
					}
				}
			}
			return _loadedFontFace;
		}
	}

	public class LazyFont : Font
	{
		readonly LazyFontFace _fontFace;
		readonly int _pixelSize;

		CacheItem<int, Font> _loadedFont;
		readonly object _loadedFontMutex = new object();

		Font Force()
		{
			if (_loadedFont == default(CacheItem<int, Font>))
			{
				lock (_loadedFontMutex)
				{
					if (_loadedFont == default(CacheItem<int, Font>))
					{
						_loadedFont = _fontFace.Force().GetOfPixelSize(_pixelSize);
					}
				}
			}
			return _loadedFont.Value;
		}

		internal LazyFont(LazyFontFace fontFace, int pixelSize)
		{
			_fontFace = fontFace;
			_pixelSize = pixelSize;
		}

		public override void Dispose()
		{
			base.Dispose();
			lock (_loadedFontMutex)
			{
				if (_loadedFont != default(CacheItem<int, Font>))
				{
					_loadedFont.Dispose();
					_loadedFont = default(CacheItem<int, Font>);
				}
			}
		}

		public override float Ascender { get { return Force().Ascender; } }
		public override float Descender { get { return Force().Descender; } }
		public override float LineHeight { get { return Force().LineHeight; } }
		public override int PixelSize { get { return _pixelSize; } }
		public override int NumGlyphs { get { return Force().NumGlyphs; } }
		public override RenderedGlyph Render(Glyph glyph) { return Force().Render(glyph); }
		public override PositionedGlyph[] Shape(Substring text, int fontIndex, TextDirection dir) { return Force().Shape(text, fontIndex, dir); }

		public override GlyphTexture GetCachedGlyphTexture(Glyph glyph, GlyphAtlas atlas, int version)
		{
			return Force().GetCachedGlyphTexture(glyph, atlas, version);
		}
	}
}
