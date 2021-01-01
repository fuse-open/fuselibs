using Uno;
using Uno.Graphics;
using Uno.UX;
using Uno.Collections;
using Fuse.Resources;
using Fuse.Drawing;
using Fuse.Elements;

namespace Fuse.Internal
{
	interface IImageContainerOwner
	{
		void OnSourceChanged();
		void OnParamChanged();
		void OnSizingChanged();
	}

	class ImageContainer
	{
		[WeakReference]
		IImageContainerOwner _owner;

		public ImageContainer(IImageContainerOwner owner = null)
		{
			_owner = owner;
		}

		public SizingContainer Sizing = new SizingContainer();

		public FileSource File
		{
			get
			{
				if (_files == null) return null;
				else return _files[0];
			}
			set
			{
				var files = Files;
				if (files.Count == 0 || files.Count > 1 || files[0] != value)
				{
					files.Clear();
					files.Add(value);
				}
			}
		}

		public String Url
		{
			get
			{
				var http = Source as HttpImageSource;
				if (http == null)
					return null;
				return http.Url;
			}
			set
			{
				Source = new HttpImageSource{ Url = value,  Density = Density, DefaultPolicy = MemoryPolicy };
			}
		}

		float _density = 1.0f;
		public float Density
		{
			get { return _density; }
			set
			{
				if (_density != value)
				{
					_density = value;
					OnParamChanged();
				}
			}
		}

		//UNO: https://github.com/fusetools/Uno/issues/106
		//internal static MemoryPolicy DefaultMemoryPolicy = MemoryPolicy.PreloadRetain;
		MemoryPolicy _memoryPolicy = MemoryPolicy.PreloadRetain;
		public MemoryPolicy MemoryPolicy
		{
			get { return _memoryPolicy; }
			set
			{
				_memoryPolicy = value;
				ReapplyOptions(Source);
				CheckPinning();
			}
		}

		void ReapplyOptions( ImageSource src )
		{
			var f = src as FileImageSource;
			if (f != null && MemoryPolicy != null)
				f.DefaultPolicy = MemoryPolicy;

			var hf = src as HttpImageSource;
			if (hf != null && MemoryPolicy != null)
				hf.DefaultPolicy = MemoryPolicy;

			var mf = src as MultiDensityImageSource;
			if (mf != null)
			{
				foreach (var s in mf.Sources)
					ReapplyOptions(s);
			}
		}

		RootableList<FileSource> _files;
		public IList<FileSource> Files
		{
			get
			{
				if (_files == null)
				{
					_files = new RootableList<FileSource>();
					if (IsRooted)
						_files.Subscribe(OnFilesChanged, OnFilesChanged);
				}
				return _files;
			}
		}

		void OnFilesChanged(FileSource ignoreFile)
		{
			if (_files.Count == 0)
			{
				Source = null;
			}
			else if (_files.Count == 1)
			{
				Source = new FileImageSource{ Density = Density, File = _files[0], DefaultPolicy = MemoryPolicy };
			}
			else
			{
				CreateMultiDensitySource();
			}
		}

		void CreateMultiDensitySource()
		{
			var s = new MultiDensityImageSource();

			foreach (var f in _files)
				s.Sources.Add(new FileImageSource(f) { Density = Density, DefaultPolicy = MemoryPolicy });

			Source = s;
		}

		bool _sourcePinned;
		Resources.ImageSource _source;
		public Resources.ImageSource Source
		{
			get { return _source; }
			set
			{
				if (_source != value)
				{
					ReleaseSource();
					_source = value;
					UpdateSourceListen();
					OnSourceChanged(null, null);
				}
			}
		}

		bool _isSourceListen;
		void UpdateSourceListen(bool forceOff = false)
		{
			bool should = !forceOff && _source != null && IsRooted;
			if (should == _isSourceListen)
				return;

			//defensive check
			if (_source == null)
			{
				Fuse.Diagnostics.InternalError( "Switching listen state on null Image", this );
				_isSourceListen = false;
				return;
			}

			_isSourceListen = should;
			if (should)
			{
				_source.Changed += OnSourceChanged;
				_source.Error += OnSourceError;
			}
			else
			{
				_source.Changed -= OnSourceChanged;
				_source.Error -= OnSourceError;
			}
		}

		public event EventHandler SourceChanged;
		void OnSourceChanged(object s, object a)
		{
			CheckPinning();
			if (SourceChanged != null)
				SourceChanged(this, EventArgs.Empty);
			if (_owner != null)
				_owner.OnSourceChanged();
		}

		public event ImageSourceErrorHandler SourceError;
		void OnSourceError(object s, ImageSourceErrorArgs args)
		{
			if (SourceError != null)
				SourceError(this, args);
		}

		void ReleaseSource()
		{
			if(_source == null)
				return;

			UpdateSourceListen(true);
			if(_sourcePinned)
			{
				_source.Unpin();
				_sourcePinned = false;
			}
			_source = null;
		}

		bool _isRooted;
		public bool IsRooted
		{
			get { return _isRooted; }
			set
			{
				if (_isRooted == value)
					return;

				_isRooted = value;
				if (_isRooted)
					OnRooted();
				else
					OnUnrooted();

				CheckPinning();
				UpdateSourceListen();
			}
		}

		void OnRooted()
		{
			if (_files != null)
			{
				_files.Subscribe(OnFilesChanged, OnFilesChanged);
				OnFilesChanged(null);
			}
		}

		void OnUnrooted()
		{
			if (_files != null)
				_files.Unsubscribe();
		}

		/**
			Pinning is used to ensure an ImageSource is not released while in use on this image even if it
			isn't actively being drawn (since there may be a static screen without updates).
		*/
		void CheckPinning()
		{
			if( _source == null )
				return;

			bool on = _isRooted;
			if (MemoryPolicy.UnpinInvisible && !_isVisible)
				on = false;

			if( on != _sourcePinned )
			{
				if( on )
					_source.Pin();
				else
					_source.Unpin();
				_sourcePinned = on;
			}
		}

		ResampleMode _resampleMode = ResampleMode.Linear;
		public ResampleMode ResampleMode
		{
			get { return _resampleMode; }
			set
			{
				if (_resampleMode != value)
				{
					if (value == ResampleMode.Mipmap)
						Fuse.Diagnostics.Deprecated("ResampleMode.Mipmap has been deprecated. Use ResampleMode.Linear instead.", this);
					_resampleMode = value;
					OnParamChanged();
				}
			}
		}

		public event EventHandler ParamChanged;
		void OnParamChanged()
		{
			if (ParamChanged != null)
				ParamChanged(this, EventArgs.Empty);
			if (_owner != null)
				_owner.OnParamChanged();
		}

		public StretchMode StretchMode
		{
			get { return Sizing.stretchMode; }
			set
			{
				if (Sizing.SetStretchMode(value))
					OnSizingChanged();
			}
		}

		void OnSizingChanged()
		{
			OnParamChanged();
			if (_owner != null)
				_owner.OnSizingChanged();
		}

		public StretchDirection StretchDirection
		{
			get { return Sizing.stretchDirection; }
			set
			{
				if (Sizing.SetStretchDirection(value))
					OnSizingChanged();
			}
		}

		public StretchSizing StretchSizing
		{
			get { return Sizing.stretchSizing; }
			set
			{
				if (Sizing.SetStretchSizing(value))
					OnSizingChanged();
			}
		}

		public Fuse.Elements.Alignment ContentAlignment
		{
			get { return Sizing.align; }
			set
			{
				if (Sizing.SetAlignment(value) )
					OnSizingChanged();
			}
		}

		public texture2D GetTexture()
		{
			if (Source != null)
				return Source.GetTexture();
			return null;
		}

		bool _isVisible = true;
		public bool IsVisible
		{
			get { return _isVisible; }
			set
			{
				if (_isVisible != value)
				{
					_isVisible = value;
					CheckPinning();
				}
			}
		}

		internal bool TestIsClean
		{
			get { return Source == null || ImageSource.TestIsClean(Source); }
		}
	}
}

