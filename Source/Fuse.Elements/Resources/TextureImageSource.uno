using Uno;
using Uno.Graphics;
using Uno.UX;
using Fuse.Resources.Exif;

namespace Fuse.Resources
{
	/** Specifies a @texture2D object to be displayed by an @Image element.

		## Example

			<Image>
				<TextureImageSource Texture="MyTexture" />
			</Image>

	*/
	public class TextureImageSource : ImageSource
	{
		texture2D _texture;
		[UXContent]
		public texture2D Texture
		{
			get { return _texture; }
			set
			{
				if (_texture != value)
				{
					_texture = value;
					OnChanged();
				}
			}
		}

		public override ImageOrientation Orientation
		{
			get { return ImageOrientation.Identity; }
		}

		float _density = 1;
		/** Specifies the source's pixel density.
		*/
		public float Density
		{
			get { return _density; }
			set
			{
				if (_density != value)
				{
					_density = value;
					OnChanged();
				}
			}
		}

		public override float SizeDensity
		{
			get { return Density; }
		}

		public override float2 Size
		{
			get
			{
				if( _texture != null )
					return float2(_texture.Size.X, _texture.Size.Y) / _density;
				return float2(0);
			}
		}

		public override int2 PixelSize
		{
			get
			{
				if (_texture != null)
					return _texture.Size;
				return int2(0);
			}
		}

		public override ImageSourceState State
		{
			get
			{
				if( _texture != null )
					return ImageSourceState.Ready;
				return ImageSourceState.Pending;
			}
		}

		public override texture2D GetTexture()
		{
			return _texture;
		}

		public override byte[] GetBytes()
		{
			return null;
		}

	}
}
