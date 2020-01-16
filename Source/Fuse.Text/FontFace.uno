using Fuse.Internal;
using Fuse.Resources;
using Uno.Collections;
using Uno.Graphics.Utils;
using Uno.IO;
using Uno;

namespace Fuse.Text
{
	public struct Glyph
	{
		public readonly int FontIndex;
		public readonly uint Index;

		internal Glyph(int fontIndex, uint index)
		{
			FontIndex = fontIndex;
			Index = index;
		}
	}

	public struct PositionedGlyph
	{
		public Glyph Glyph { get; private set; }
		public float2 Advance { get; private set; }
		public readonly float2 Offset;
		public readonly int Cluster;

		internal PositionedGlyph(Glyph glyph, float2 advance, float2 offset, int cluster)
		{
			Glyph = glyph;
			Advance = advance;
			Offset = offset;
			Cluster = cluster;
		}
	}

	public struct RenderedGlyph
	{
		public readonly Bitmap Bitmap;
		public readonly float2 Offset;
		public readonly float Scale;

		internal RenderedGlyph(Bitmap bitmap, float2 offset, float scale)
		{
			Bitmap = bitmap;
			Offset = offset;
			Scale = scale;
		}
	}

	public abstract class FontFace : IDisposable
	{
		internal static FontFace Load(FontFaceDescriptor descriptor)
		{
			if (descriptor.FileSource is SystemFileSource)
			{
				return Fuse.Text.FontFace.Load(descriptor.FileSource.Name, descriptor.Index, descriptor.Match);
			}
			else
			{
				return Fuse.Text.FontFace.Load(descriptor.FileSource.ReadAllBytes(), descriptor.Index, descriptor.Match);
			}
		}

		// If index < 0: The first face in the file whose style string
		// matches the predicate (e.g. `.ttc` files often contain
		// several faces).
		//
		// If index >= 0: The face with index `index` in the file.
		public static FontFace Load(byte[] data, int index = -1, Predicate<string> stylePredicate = null)
		{
			if defined(DOTNET || CPlusPlus)
				return new Implementation.FreeTypeFontFace(data, index, stylePredicate);
			else build_error;
		}

		public static FontFace Load(string fileName, int index = -1, Predicate<string> stylePredicate = null)
		{
			if defined(iOS)
				return new Implementation.CoreTextFontFace(fileName, index, stylePredicate);
			else if defined(DOTNET || CPlusPlus)
				return new Implementation.FreeTypeFontFace(fileName, index, stylePredicate);
			else build_error;
		}

		abstract Font GetOfPixelSizeInternal(int size);

		Cache<int, Font> _fontCache;
		public CacheItem<int, Font> GetOfPixelSize(int size)
		{
			if (_fontCache == null)
				_fontCache = new Cache<int, Font>(GetOfPixelSizeInternal);

			return _fontCache.Get(size);
		}

		public virtual void Dispose()
		{
			if (_fontCache != null)
			{
				_fontCache.Dispose();
				_fontCache = null;
			}
		}
	}

	public enum TextDirection
	{
		LeftToRight,
		RightToLeft,
	}

	public abstract class Font : IDisposable
	{
		public static readonly string Truncation = "...";
		PositionedGlyph[] _shapedTruncation;
		public PositionedGlyph[] ShapedTruncation
		{
			get
			{
				if (_shapedTruncation == null)
					_shapedTruncation = Shape(Truncation, TextDirection.LeftToRight);
				return _shapedTruncation;
			}
		}
		float2 _truncationMeasurements;
		public float2 TruncationMeasurements
		{
			get
			{
				if (_truncationMeasurements == default(float2))
					_truncationMeasurements = Measure(ShapedTruncation);
				return _truncationMeasurements;
			}
		}

		public abstract float Ascender { get; }
		public abstract float Descender { get; }
		public abstract float LineHeight { get; }
		public abstract int PixelSize { get; }
		public abstract int NumGlyphs { get; }

		public abstract RenderedGlyph Render(Glyph glyph);

		public abstract PositionedGlyph[] Shape(Substring text, int fontIndex, TextDirection dir);
		public PositionedGlyph[] Shape(string text, TextDirection dir)
		{
			return Shape(new Substring(text), 0, dir);
		}

		public float2 Measure(PositionedGlyph[] shapedRun)
		{
			var result = float2(0, 0);
			foreach (var positionedGlyph in shapedRun)
			{
				result += positionedGlyph.Advance;
			}
			return result;
		}

		GlyphTexture[] _glyphTextureCache;
		int _glyphTextureCacheVersion;
		public virtual GlyphTexture GetCachedGlyphTexture(Glyph glyph, GlyphAtlas atlas, int currentVersion)
		{
			if (_glyphTextureCacheVersion != currentVersion)
			{
				_glyphTextureCacheVersion = currentVersion;
				if (_glyphTextureCache != null)
					for (int i = 0; i < _glyphTextureCache.Length; ++i)
						_glyphTextureCache[i] = new GlyphTexture();
			}
			if (_glyphTextureCache == null)
			{
				_glyphTextureCache = new GlyphTexture[NumGlyphs];
			}

			var result = _glyphTextureCache[(int)glyph.Index];
			if (result.IsValid)
				return result;

			var renderedGlyph = new RenderedGlyph();
			bool renderedGlyphValid = false;
			try
			{
				renderedGlyph = Render(glyph);
				renderedGlyphValid = true;
			}
			catch (Exception e)
			{
				Fuse.Diagnostics.InternalError("Error loading glyph: " + glyph.Index + " " + e.Message);
			}

			if (renderedGlyphValid)
			{
				var subTexture = atlas.Add(renderedGlyph.Bitmap);
				result = new GlyphTexture(subTexture, renderedGlyph.Offset, renderedGlyph.Scale);
			}
			else
			{
				result = new GlyphTexture(new SubTexture(), float2(0), 1);
			}

			_glyphTextureCache[(int)glyph.Index] = result;
			return result;
		}

		public virtual void Dispose()
		{
			if (_glyphTextureCache != null)
			{
				_glyphTextureCache = null;
				Renderer.RecreateGlyphAtlas(_glyphTextureCacheVersion);
			}
		}
	}
}
