using Fuse.Internal;
using Uno;
using Uno.Collections;

namespace Fuse.Text
{
	public class FallingBackFontFace : FontFace
	{
		public CacheItem<FontFaceDescriptor, FontFace>[] FontFaces;

		public FallingBackFontFace(params CacheItem<FontFaceDescriptor, FontFace>[] fontFaces)
		{
			assert fontFaces.Length > 0;
			FontFaces = fontFaces;
		}

		public override void Dispose()
		{
			base.Dispose();
			if (FontFaces != null)
			{
				foreach (var fontFace in FontFaces)
					fontFace.Dispose();
				FontFaces = null;
			}
		}

		override Font GetOfPixelSizeInternal(int size)
		{
			var fonts = new CacheItem<int, Font>[FontFaces.Length];
			for (int i = 0; i < FontFaces.Length; ++i)
			{
				fonts[i] = FontFaces[i].Value.GetOfPixelSize(size);
			}
			return new FallingBackFont(fonts);
		}
	}

	public class FallingBackFont : Font
	{
		CacheItem<int, Font>[] Fonts;

		public FallingBackFont(params CacheItem<int, Font>[] fonts)
		{
			assert fonts.Length > 0;
			Fonts = fonts;
		}

		public override void Dispose()
		{
			base.Dispose();
			if (Fonts != null)
			{
				foreach (var font in Fonts)
				{
					font.Dispose();
				}
				Fonts = null;
			}
		}

		public override float Ascender { get { return Fonts[0].Value.Ascender; } }
		public override float Descender { get { return Fonts[0].Value.Descender; } }
		public override float LineHeight { get { return Fonts[0].Value.LineHeight; } }
		public override int PixelSize { get { return Fonts[0].Value.PixelSize; } }
		public override int NumGlyphs { get { return 0; } }

		public override RenderedGlyph Render(Glyph glyph)
		{
			return Fonts[glyph.FontIndex].Value.Render(glyph);
		}

		public override PositionedGlyph[] Shape(Substring text, int fontIndex, TextDirection dir)
		{
			// Note: For performance reasons, nested FallingBackFonts are not supported
			assert fontIndex == 0;
			return ShapeInner(text, 0, dir);
		}

		PositionedGlyph[] ShapeInner(Substring text, int fontIndex, TextDirection dir)
		{
			var positionedGlyphs = Fonts[fontIndex].Value.Shape(text, fontIndex, dir);

			int i = 0, start = 0, end = 0;
			if (fontIndex + 1 < Fonts.Length && TryFindUnhandledSegment(positionedGlyphs, i, out start, out end))
			{
				var result = new List<PositionedGlyph>(positionedGlyphs.Length);
				do
				{
					for (int j = i; j < start; ++j)
						result.Add(positionedGlyphs[j]);

					var firstCluster = positionedGlyphs[start].Cluster;
					var lastCluster = positionedGlyphs[end - 1].Cluster;
					// These values can be backwards in RTL fonts
					var startCluster = Math.Min(firstCluster, lastCluster);
					var endCluster = Math.Max(firstCluster, lastCluster);
					var subText = text.InclusiveRange(startCluster, endCluster);
					foreach (var g in ShapeInner(subText, fontIndex + 1, dir))
						result.Add(new PositionedGlyph(g.Glyph, g.Advance, g.Offset, g.Cluster + startCluster));

					i = end;
				}
				while (TryFindUnhandledSegment(positionedGlyphs, i, out start, out end));

				for (; i < positionedGlyphs.Length; ++i)
					result.Add(positionedGlyphs[i]);

				return result.ToArray();
			}
			return positionedGlyphs;
		}

		bool TryFindUnhandledSegment(PositionedGlyph[] glyphs, int startIndex, out int start, out int end)
		{
			for (int i = startIndex; i < glyphs.Length; ++i)
			{
				if (glyphs[i].Glyph.Index == 0)
				{
					start = i;
					while (i < glyphs.Length && glyphs[i].Glyph.Index == 0)
						++i;
					end = i;
					return true;
				}
			}
			start = end = 0;
			return false;
		}

		public override GlyphTexture GetCachedGlyphTexture(Glyph glyph, GlyphAtlas atlas, int version)
		{
			return Fonts[glyph.FontIndex].Value.GetCachedGlyphTexture(new Glyph(0, glyph.Index), atlas, version);
		}
	}
}
