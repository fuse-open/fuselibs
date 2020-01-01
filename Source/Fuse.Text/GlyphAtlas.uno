using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Graphics.Utils;

namespace Fuse.Text
{
	public class GlyphAtlas : IDisposable
	{
		public readonly List<texture2D> Textures;
		readonly TextureAtlas _textureAtlasL8;
		readonly TextureAtlas _textureAtlasRGBA;

		public GlyphAtlas(int2 size)
		{
			Textures = new List<texture2D>();
			_textureAtlasL8 = new TextureAtlas(size, Format.L8, Textures);
			_textureAtlasRGBA = new TextureAtlas(size, Format.RGBA8888, Textures);
		}

		// Note: After this has been run, the underlying texture might
		// not be updated yet; it can be brought up-to-date with a call
		// to Commit().
		public SubTexture Add(Bitmap bitmap)
		{
			var format = bitmap.Format;
			assert format == Format.L8 || format == Format.RGBA8888;
			var atlas = format == Format.L8 ? _textureAtlasL8 : _textureAtlasRGBA;
			return atlas.Add(bitmap);
		}

		public void Commit()
		{
			_textureAtlasL8.Commit();
			_textureAtlasRGBA.Commit();
		}

		public void Dispose()
		{
			foreach (var texture in Textures)
			{
				texture.Dispose();
			}
			Textures.Clear();
		}
	}
}
