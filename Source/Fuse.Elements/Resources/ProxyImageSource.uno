using Uno;
using Fuse.Resources.Exif;

namespace Fuse.Resources
{
	//TODO: this should actually disconnect the events when the caller disconnects, otherwise it creates a loop on the backend cache object
	sealed class ProxyImageSource
	{
		ImageSource _outer;
		public ProxyImageSource( ImageSource outer )
		{
			_outer = outer;
		}

		ImageSource _impl;
		public ImageSource Impl { get { return _impl; } }

		public void OnPinChanged()
		{
			if (_impl == null)
				return;

			if (_outer.IsPinned)
				_impl.Pin();
			else
				_impl.Unpin();
		}

		bool _isDefaultPolicy = true;
		MemoryPolicy _policy = MemoryPolicy.PreloadRetain;
		public MemoryPolicy Policy
		{
			get { return _policy; }
			set
			{
				_policy = value;
				_isDefaultPolicy = false;
				UpdatePolicy();
			}
		}

		//allows for locally set policies not to be overriden by those specified in `Image.MemoryPolicy`
		public void DefaultSetPolicy(MemoryPolicy mp)
		{
			if (!_isDefaultPolicy)
				return;

			_policy = mp;
			UpdatePolicy();
		}

		void UpdatePolicy()
		{
			var loading = _impl as LoadingImageSource;
			if (loading != null)
				loading.Policy = _policy;
		}

		public ImageOrientation Orientation
		{
			get
			{
				if (_impl != null)
					return _impl.Orientation;
				return ImageOrientation.Identity;
			}
		}

		public float2 Size
		{
			get
			{
				if (_impl == null)
					return float2(0);

				var ps = _impl.PixelSize;
				return float2(ps.X, ps.Y) / Density;
			}
		}

		public int2 PixelSize
		{
			get
			{
				if (_impl == null)
					return int2(0);

				return _impl.PixelSize;
			}
		}

		//allow overriding loaded density here. This allows each Source using the same backend data
		//to have a different value.
		float _density = 1;
		bool _hasDensity;
		public float Density
		{
			get
			{
				if (_hasDensity || _impl == null)
					return _density;
				return _impl.SizeDensity;
			}
			set
			{
				_density = value;
				_hasDensity = true;
			}
		}

		public ImageSourceState State
		{
			get { return _impl == null ? ImageSourceState.Pending : _impl.State; }
		}

		public texture2D GetTexture()
		{
			return _impl == null ? null : _impl.GetTexture();
		}

		public byte[] GetBytes()
		{
			return _impl == null ? null : _impl.GetBytes();
		}

		public void Reload()
		{
			if (_impl != null)
				_impl.Reload();
		}

		public void Release()
		{
			if (_impl != null)
			{
				if (_outer.IsPinned)
					_impl.Unpin();
				_impl.Changed -= ProxyOnChanged;
				_impl.Error -= ProxyOnError;
				_impl = null;
			}
		}

		void ProxyOnChanged(object s, EventArgs a)
		{
			_outer.ProxyChanged( this, a );
		}

		void ProxyOnError(object s, ImageSourceErrorArgs a)
		{
			_outer.ProxyError( this, a );
		}

		public void Attach( ImageSource impl )
		{
			_impl = impl;
			_impl.Changed += ProxyOnChanged;
			_impl.Error += ProxyOnError;
			if (_outer.IsPinned)
				_impl.Pin();

			var loading = impl as LoadingImageSource;
			if (loading != null)
				loading.Policy = _policy;

			_outer.ProxyChanged( this, new EventArgs() );
		}
	}

}
