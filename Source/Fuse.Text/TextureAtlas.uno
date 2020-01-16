using Fuse.Internal;
using Uno.Collections;
using Uno.Graphics;
using Uno.Graphics.Utils;
using Uno;

namespace Fuse.Text
{
	public struct SubTexture
	{
		// Assumes a global texture list shared by any involved texture atlases
		public readonly int TextureIndex;
		public readonly Recti Rect;

		public SubTexture(int textureIndex, Recti rect)
		{
			TextureIndex = textureIndex;
			Rect = rect;
		}
	}

	public class TextureAtlas
	{
		readonly int2 _minimumTextureSize;
		readonly Format _format;

		readonly List<texture2D> _textures;
		int _textureIndex;

		Bitmap _bitmap;
		RectPacker _packer;
		bool _dirty;

		public TextureAtlas(int2 minimumTextureSize, Format format, List<Texture2D> textures)
		{
			_minimumTextureSize = minimumTextureSize;
			_format = format;
			_textures = textures;
			NewTexture(_minimumTextureSize);
		}

		// Note: After this has been run, the underlying texture might
		// not be updated yet; it can be brought up-to-date with a call
		// to Commit().
		//
		// Note also that there will be at least a one-pixel margin
		// between all SubTextures.
		public SubTexture Add(Bitmap bitmap)
		{
			assert bitmap.Format == _format;

			Recti rectWithBorder;
			var sizeWithBorder = bitmap.Size + int2(1, 1);

			if (!_packer.TryAdd(sizeWithBorder, out rectWithBorder))
			{
				var newTextureSize = int2(
					Math.NextPow2(sizeWithBorder.X + 1),
					Math.NextPow2(sizeWithBorder.Y + 1));
				NewTexture(Math.Max(_minimumTextureSize, newTextureSize));
				if (!_packer.TryAdd(sizeWithBorder, out rectWithBorder))
				{
					throw new Exception("Bitmap too large for the texture atlas size");
				}
			}

			var rect = new Recti(rectWithBorder.Position + int2(1, 1), bitmap.Size);

			Blit(_bitmap, bitmap, rect.Position);
			_dirty = true;

			return new SubTexture(_textureIndex, rect);
		}

		public void Commit()
		{
			if (_dirty)
			{
				_dirty = false;
				var texture = _textures[_textureIndex];
				texture.Update(_bitmap.Data);
			}
		}

		void NewTexture(int2 size)
		{
			Commit();
			_packer = new RectPacker(size - int2(1, 1));
			_bitmap = new Bitmap(size, _format);
			_textureIndex = _textures.Count;
			_textures.Add(new Texture2D(size, _format, false));
		}

		static void Blit(Bitmap dst, Bitmap src, int2 dstPos)
		{
			assert new Recti(int2(0), dst.Size).Contains(new Recti(dstPos, src.Size));
			assert src.Format == dst.Format;

			var bpp = FormatHelpers.GetStrideInBytes(src.Format);

			var bsrcSize = int2(src.Size.X * bpp, src.Size.Y);
			var bdstSize = int2(dst.Size.X * bpp, dst.Size.Y);
			var bdstPos = int2(dstPos.X * bpp, dstPos.Y);

			for (int y = 0; y < bsrcSize.Y; ++y)
			{
				int srcRow = y * bsrcSize.X;
				int dstRow = (bdstPos.Y + y) * bdstSize.X + bdstPos.X;
				for (int x = 0; x < bsrcSize.X; ++x)
				{
					dst.Data[dstRow + x] = src.Data[srcRow + x];
				}
			}
		}
	}
}
