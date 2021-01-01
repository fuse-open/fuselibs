using Uno;
using Uno.Graphics;
using Uno.UX;

using Fuse.Drawing;
using Fuse.Scripting;

using Uno.Net.Http;
using Fuse.Resources.Exif;

namespace Fuse.Resources
{
	public enum ImageSourceState
	{
		//resource is not available nor loading
		Pending,
		//source is completely available
		Ready,
		//source is currently loading
		Loading,
		//source has failed to load correctly
		Failed,
	}

	public class ImageSourceErrorArgs : EventArgs, IScriptEvent
	{
		public String Reason;
		//may be null
		public Exception ExceptionCause;

		void IScriptEvent.Serialize(IEventSerializer s)
		{
			s.AddString("reason", Reason);
		}

		ImageSource _imageSource;

		internal ImageSourceErrorArgs(ImageSource imageSource)
		{
			_imageSource = imageSource;
		}

		internal void Post()
		{
			_imageSource.FireError(this);
		}
	}

	public delegate void ImageSourceErrorHandler(object sender, ImageSourceErrorArgs args);

	class ImageSourceChangedArgs : EventArgs
	{
		ImageSource _imageSource;

		internal ImageSourceChangedArgs(ImageSource imageSource)
		{
			_imageSource = imageSource;
		}

		internal void Post()
		{
			_imageSource.FireChanged(this);
		}
	}

	/** Provides an image from a source such as a file, url, or other source.

		## Example

		The following example displays an @Image from a @FileImageSource:

			<Image>
				<FileImageSource File="fuse.png" />
			</Image>

		A common pattern is to declare `ImageSource`s as global resources, as shown below.

			<FileImageSource ux:Global="FuseLogo" File="fuse.png" />

			<Image Source="FuseLogo" />

		## Available image source types:

		[subclass Fuse.Resources.ImageSource]
	*/
	public abstract class ImageSource : PropertyObject
	{
		public event EventHandler Changed;
		protected void OnChanged()
		{
			//the message is deferred since some sources are lazy-loading on request and would
			//otherwise cause a layout invalidation during layout.
			//mortoray: it feels wrong to have this here, that somehow this is layout's problem, not ImageSource's
			if (Changed != null)
				UpdateManager.AddDeferredAction( new ImageSourceChangedArgs(this).Post );
		}
		internal void ProxyChanged(object s, EventArgs a)
		{
			if (Changed != null)
				Changed( s, a );
		}
		internal void FireChanged(ImageSourceChangedArgs args)
		{
			if (Changed != null)
				Changed(this, args);
		}

		public event ImageSourceErrorHandler Error;
		protected void OnError( String msg, Exception e = null )
		{
			Fuse.Diagnostics.UnknownException( "ImageSource error: '"+msg+"'", e, this );
			if (Error != null)
			{
				var sa = new ImageSourceErrorArgs(this);
				sa.Reason = msg;
				sa.ExceptionCause = e;
				UpdateManager.AddDeferredAction( sa.Post );
			}
		}
		internal void ProxyError(object s, ImageSourceErrorArgs a)
		{
			if (Error != null)
				Error(s, a);
		}
		internal void FireError(ImageSourceErrorArgs args)
		{
			if (Error != null)
				Error(this, args);
		}

		int _pinCount;
		public void Pin()
		{
			_pinCount++;
			if (_pinCount == 1)
				OnPinChanged();
		}
		public void Unpin()
		{
			_pinCount--;
			if (_pinCount == 0)
				OnPinChanged();
		}
		public bool IsPinned
		{
			get { return _pinCount > 0; }
		}
		protected virtual void OnPinChanged() { }

		public abstract ImageOrientation Orientation { get; }
		public abstract float2 Size { get; }
		public abstract int2 PixelSize { get; }
		public abstract ImageSourceState State { get; }
		public abstract texture2D GetTexture();
		public abstract byte[] GetBytes();
		public virtual void Reload() {}

		//We can't use just `Density` here: https://stackoverflow.com/questions/82437/why-is-it-impossible-to-override-a-getter-only-property-and-add-a-setter
		public abstract float SizeDensity { get; }

		/** This is an internal interface, used to check memory leaks, thus it can't be part of the actual
			interface definition */
		internal static bool TestIsClean(ImageSource image)
		{
			var file = image as FileImageSource;
			if (file != null)
				return file.TestIsClean;

			throw new Exception( "Unrecognized ImageSource in Test:" + image );
		}
	}
}
