using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.UX;

using Fuse.Drawing;
using Fuse.Internal.Drawing;
using Fuse.Elements;
using Fuse.Resources;
using Fuse.Internal;
using Fuse.Triggers;
using Fuse.Gestures;
using Fuse.Controls.Native;

namespace Fuse.Controls
{
	/** Displays an Image
	
		Image provides several features for working with images in fuse, we will go through them in some short examples.

		Displaying an image from a file or an url:

			<StackPanel>
				<Image File="some_file.png" />
				<Image Url="some_url" />
			</StackPanel>
	

		## Displaying a multi-density image from files:

			<StackPanel>
				<Image Files="logo.png, logo@2x.png, logo@4x.png" />
				<Image>
					<MultiDensityImageSource>
						<FileImageSource Density="1" File="logo.png" />
						<FileImageSource Density="2" File="logo@2x.png" />
						<FileImageSource Density="3" File="logo@4x.png" />
					</MultiDensityImageSource>
				</Image>
			</StackPanel/>


		## Displaying a multi-density image from urls:

			<StackPanel>
				<Image>
					<MultiDensityImageSource>
						<HttpImageSource Density="1" Url="..." />
						<HttpImageSource Density="2" Url="...@2x" />
						<HttpImageSource Density="3" Url="...@4x" />
					</MultiDensityImageSource>
				</Image>
			</StackPanel>
		
		## Displaying an image from a file specified from JavaScript
		Uno cannot automatically bundle images when their path is defined in JavaScript. Because of this, you have to manually bundle those by manually importing them in your unproj file. You can either bundle one file like this:
		
			"Includes": [
				"*",
				"image.jpg:Bundle"
			]
		
		Or bundle an entire folder, or all files of a specific type, using wildcards:
		
			"Includes": [
				"*.jpg:Bundle"
			]

		You can read more on bundling files with your project [here.](/docs/assets/bundle).
		
		When you have bundled your image files, you can refer to them from javascript like this:
		
			<JavaScript>
				module.exports = {
					image: "image.jpg"
				};
			</JavaScript>
			<Image File="{image}" />
		
	*/
	public partial class Image : LayoutControl, ISizeConstraint
	{
		ImageContainer _container = new ImageContainer();
		internal ImageContainer Container
		{
			get { return _container; }
		}
		
		protected override void OnRooted()
		{
			base.OnRooted();

			_markedFailed = false;
			AddDrawCost(1.0);

			IsVisibleChanged += OnIsVisibleChanged;
			_container.ParamChanged += OnContainerParamChanged;
			_container.SourceChanged += OnContainerSourceChanged;
			_container.SourceError += OnContainerSourceError;
			_container.IsRooted = true;
		}
		
		protected override void OnUnrooted()
		{
			IsVisibleChanged -= OnIsVisibleChanged;
			_container.IsRooted = false;
			_container.ParamChanged -= OnContainerParamChanged;
			_container.SourceChanged -= OnContainerSourceChanged;
			_container.SourceError -= OnContainerSourceError;

			RemoveDrawCost(1.0);

			base.OnUnrooted();
		}
		
		void OnContainerParamChanged(object s, object a )
		{
			OnParamChanged();
		}
		void OnContainerSourceChanged(object s, object a )
		{
			OnSourceChanged();
		}
		
		ImageSourceErrorArgs _lastError;
		void OnContainerSourceError(object s, ImageSourceErrorArgs args)
		{
			_lastError = args;
			//avoid updating if already failed, otherwise we can get an invalidate loop in layout if a syncload image
			//fails to load
			if (!_markedFailed && _container.Source.State == ImageSourceState.Failed)
				OnSourceChanged();
		}
		
		void OnIsVisibleChanged(object s, object a)
		{
			_container.IsVisible = IsVisible;
		}
		
		/**
			Loads an image from a File.

			Only one of `File`, `Url` or `Source` can be specified.
		*/
		public FileSource File
		{
			get { return _container.File; }
			set { _container.File = value; }
		}

		/**
			Loads an image at the given URL.

			Only one of `File`, `Url` or `Source` can be specified.
		*/
		public string Url
		{
			get { return _container.Url; }
			set { _container.Url = value; }
		}

		/**
			Specifies the density of the image in relation to layout; the number of image pixels per logical point.
		*/
		public float Density
		{
			get { return _container.Density; }
			set { _container.Density = value; }
		}

		[UXContent]
		/** The list of image files in different pixel densities. 
			To specify a multi-density image, please use @MultiDensityImageSource
		*/
		public IList<FileSource> Files
		{
			get { return _container.Files; }
		}

		[UXContent]
		/** The source of this image. Can be specified as an inline object, e.g. @MultiDensityImageSource.
			Using this property can not be combined with using `Url` or `File`.
		*/
		public Resources.ImageSource Source
		{
			get { return _container.Source; }
			set { _container.Source = value; }
		}

		float4 _color = float4(1);
		/**
			Specifies a mask color used while drawing the image. This color is multiplied by the source color.

		 	For more information on what notations Color supports, check out [this subpage](articles:ux-markup/literals#colors).
		*/
		public float4 Color
		{
			get { return _color; }
			set
			{
				if (_color != value)
				{
					_color = value;
					OnParamChanged();
				}
			}
		}

		/** Specifies the resampling mode for drawing an image. */
		public ResampleMode ResampleMode
		{
			get { return _container.ResampleMode; }
			set { _container.ResampleMode = value; }
		}

		float4 _scale9Margin = float4(10);
		bool _hasScale9Margin;
		/** For `StretchMode="Scale9"` this defines the four margin that split the image into 9-esctions for scaling. */
		public float4 Scale9Margin
		{
			get { return _scale9Margin; }
			set
			{
				if (!_hasScale9Margin || _scale9Margin != value)
				{
					_scale9Margin = value;
					_hasScale9Margin = true;
					OnParamChanged();
				}
			}
		}
		
		/** @advanced */
		public event EventHandler ParamChanged;
		void OnParamChanged()
		{
			if (ParamChanged != null)
				ParamChanged(this, EventArgs.Empty);
				
			InvalidateLayout();
			InvalidateRenderBounds();
			UpdateNativeImageSource();
		}

		BusyTask _loadingTask;

		/** @advanced */
		public event EventHandler SourceChanged;
		bool _markedFailed;
		void OnSourceChanged()
		{
			if (_container.Source != null)
			{
				_markedFailed = _container.Source.State == ImageSourceState.Failed;
				bool isLoading = _container.Source.State == ImageSourceState.Loading;
				BusyTask.SetBusy(this, ref _loadingTask, 
					_markedFailed ? BusyTaskActivity.Failed :
					isLoading ? BusyTaskActivity.Loading : BusyTaskActivity.None,
					_markedFailed ? (_lastError == null ? "unknown failure" : _lastError.Reason) : "");
			}
			
			if (SourceChanged != null)
				SourceChanged(this, EventArgs.Empty);
				
			InvalidateLayout();
			InvalidateRenderBounds();

			UpdateNativeImageSource();
		}

		/** @advanced
			Raised when an error occurs loading the image. */
		public event ImageSourceErrorHandler Error
		{
			add { _container.SourceError += value; }
			remove { _container.SourceError -= value; }
		}

		[UXContent]
		/**
			Specifies a policy to control the loading and unloading of the image. The two common policies are `PreloadRetain`, the default which loads images at startup and keeps them loaded, and `UnloadUnused` which keeps only used images loaded.

			For dynamic images, such as those coming from HTTP, you should use the `UnloadUnused` policy, otherwise you'll continue to consume more memory as more images are loaded. For example:

				<Image Url="{imageLocation}" MemoryPolicy="UnloadUnused"/>
		*/
		public MemoryPolicy MemoryPolicy
		{
			get { return _container.MemoryPolicy; }
			set { _container.MemoryPolicy = value; }
		}

		/** Specifies how the size of the image element is calculated and how the image is stretched inside it. */
		public StretchMode StretchMode
		{
			get { return _container.StretchMode; }
			set { _container.StretchMode = value; }
		}

		/** Specifies whether an image can become larger or smaller to fill the available space. */
		public StretchDirection StretchDirection
		{
			get { return _container.StretchDirection; }
			set { _container.StretchDirection = value; }
		}

		/**
			During layout this indicates how the size of the image should be reported.

			This is typically modified when using larger images in a layout where you don't want the image to influence the size of the panel but to just stretch to fill it.
		*/
		public StretchSizing StretchSizing
		{
			get { return _container.StretchSizing; }
			set { _container.StretchSizing = value; }
		}

		/** Specifies the alignment of the image inside the element. This is used when the image itself does not fill, or overfills, the available space. */
		public Fuse.Elements.Alignment ContentAlignment
		{
			get { return _container.ContentAlignment; }
			set { _container.ContentAlignment = value; }
		}

		static void UpdateParam(Image img)
		{
			//do nothing as setters will trigger OnParamChanged via ImageContainer
		}

		//TODO: drop this storage now that Visual is inlined?
		internal bool _hasContentBox;
		internal float4 _contentBox;
		/**
			The ISizeConstraint interface needs to know the true size of the displayed image, since
			using the size of the control won't be visually pleasing at times (it would allow scrolling
			into empty edge areas).
		*/
		internal void SetContentBox(float4 contentBox)
		{
			_hasContentBox = true;
			_contentBox = contentBox;
		}
		
		float2 ISizeConstraint.ContentSize
		{
			get
			{
				return _hasContentBox ? (_contentBox.ZW-_contentBox.XY) : ActualSize;
			}
		}
		float2 ISizeConstraint.TrimSize
		{
			get
			{
				return _hasContentBox ? (ActualSize - (_contentBox.ZW - _contentBox.XY))
					: float2(0);
			}
		}

		protected override void PushPropertiesToNativeView()
		{
			base.PushPropertiesToNativeView();
			UpdateNativeImageSource();
			UpdateNativeImageTransform();
		}

		void UpdateNativeImageSource()
		{
			var imageView = ImageView;
			if (imageView != null)
			{
				imageView.ImageSource = Source;
				ImageView.TintColor = Color;
			}
		}

		IImageView ImageView
		{
			get { return NativeView as IImageView; }
		}

		protected override IView CreateNativeView()
		{
			if defined(Android)
			{
				return new Fuse.Controls.Native.Android.ImageView();
			}
			else if defined(iOS)
			{
				return new Fuse.Controls.Native.iOS.ImageView();
			}
			else
			{
				return base.CreateNativeView();
			}
		}

	}
}
