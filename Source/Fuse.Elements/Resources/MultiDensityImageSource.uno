using Uno;
using Uno.Graphics;
using Uno.Collections;
using Uno.UX;
using Fuse.Drawing;
using Fuse.Resources.Exif;

namespace Fuse.Resources
{

	/** Used to specify multiple image sources that an @Image element can display at different pixel densities.

		In order to ensure a given image looks best across multiple screens with different pixel densities,
		it's often useful to be able to specify different pre-scaled versions of an image, instead of just
		specifying one and relying on image scaling while rendering. This allows Fuse to pick the one that's
		best suited for a particular screen.

		## Example

			<Image StretchMode="PointPrefer">
				<MultiDensityImageSource>
					<FileImageSource File="Icon.png" Density="1"/>
					<FileImageSource File="Icon.png@2x.png" Density="2"/>
				</MultiDensityImageSource>
			</Image>

	*/
	public sealed class MultiDensityImageSource : ImageSource
	{
		ObservableList<ImageSource> _sources;
		[UXContent]
		/** The list of @ImageSources to choose from. This is given as children of the MultiDensityImageSource. */
		public IList<ImageSource> Sources
		{
			get
			{
				return _sources;
			}
		}

		//ProxyImageSource composition
		ProxyImageSource _proxy;
		public MultiDensityImageSource()
		{
			_sources = new ObservableList<ImageSource>(OnImageAdded, OnImageRemoved);
			_proxy = new ProxyImageSource(this);
		}

		internal event Action ActiveChanged;

		void OnActiveChanged()
		{
			var handler = ActiveChanged;
			if (handler != null)
			{
				handler();
			}
		}

		void OnImageAdded(ImageSource img)
		{
			if (IsPinned)
				SelectActive();
		}

		void OnImageRemoved(ImageSource img)
		{
			if (IsPinned)
				SelectActive();
		}

		float _matchDensity;
		bool _hasMatchDensity;
		/** Used to override the current screen's detected density when selecting a source to display.
		*/
		public float MatchDensity
		{
			get { return _matchDensity; }
			set
			{
				if (_hasMatchDensity && _matchDensity == value)
					return;

				_hasMatchDensity = true;
				_matchDensity = value;
				SelectActive();
			}
		}

		ImageSource _active;

		internal ImageSource Active
		{
			get { return _active; }
		}

		void SelectActive()
		{
			var screen = _hasMatchDensity ? _matchDensity : AppBase.Current.PixelsPerPoint;

			var diff = float.PositiveInfinity;
			ImageSource use = null;
			foreach (var source in _sources)
			{
				var d = Math.Abs(source.SizeDensity - screen);
				if (d < diff)
				{
					use = source;
					diff = d;
				}
			}

			SwapActive(use);
		}

		void SwapActive(ImageSource use)
		{
			if (use == _active)
				return;

			if (_active != null)
				_proxy.Release();
			_active = use;
			if (use != null)
				_proxy.Attach( use );

			OnActiveChanged();
		}

		internal MemoryPolicy Policy
		{
			get { return _proxy.Policy; }
			set { _proxy.Policy = value; }
		}

		protected override void OnPinChanged()
		{
			SelectActive();
			_proxy.OnPinChanged();
		}

		public override float2 Size
		{
			get
			{
				return _proxy.Size;
			}
		}

		public override int2 PixelSize
		{
			get
			{
				return _proxy.PixelSize;
			}
		}

		public override ImageOrientation Orientation
		{
			get
			{
				return _proxy.Orientation;
			}
		}

		public override ImageSourceState State
		{
			get
			{
				return _proxy.State;
			}
		}

		public override texture2D GetTexture()
		{
			return _proxy.GetTexture();
		}

		public override byte[] GetBytes()
		{
			return _proxy.GetBytes();
		}

		public override void Reload()
		{
			_proxy.Reload();
		}

		public override float SizeDensity
		{
			get
			{
				return _proxy.Density;
			}
		}
	}
}
