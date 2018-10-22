using Uno;
using Uno.Graphics;
using Uno.Collections;
using Uno.UX;
using Fuse.Drawing;
using Fuse.Resources.Exif;

using Experimental.TextureLoader;
using Experimental.Http;

namespace Fuse.Resources
{
	/** Provides an image fetched via HTTP which can be displayed by the @Image control.
	
		> *Note* @Image provides a shorthand for this, using its [Url](api:fuse/controls/image/url) property.

		## Example

			<Image>
				<HttpImageSource Url="https://upload.wikimedia.org/wikipedia/commons/0/06/Kitten_in_Rizal_Park%2C_Manila.jpg" />
			</Image>

	*/
	public sealed class HttpImageSource : ImageSource
	{
		/** The URL of the image.
		*/
		public String Url
		{
			get { return _proxy.Impl == null ? "" : (_proxy.Impl as HttpImageSourceImpl).Url; }
			set
			{
				_proxy.Release();
				if(value == null || value == "" )
					return;

				_proxy.Attach( HttpImageSourceCache.GetUrl( value ) );
			}
		}

		//ProxyImageSource composition
		ProxyImageSource _proxy;
		public HttpImageSource()
		{
			_proxy = new ProxyImageSource(this);
		}

		public HttpImageSource(String url)
		{
			_proxy = new ProxyImageSource(this);
			Url = url;
		}

		public MemoryPolicy DefaultPolicy { set { _proxy.DefaultSetPolicy(value); } }
		/** Specifies a hint for how the image should be managed in memory. See @MemoryPolicy. */
		public MemoryPolicy Policy { get { return _proxy.Policy; } set { _proxy.Policy = value; } }
		protected override void OnPinChanged() {  _proxy.OnPinChanged(); }

		public override ImageOrientation Orientation { get { return _proxy.Orientation; } }
		public override float2 Size { get { return _proxy.Size; } }
		public override int2 PixelSize { get { return _proxy.PixelSize; } }
		public override ImageSourceState State { get { return _proxy.State; } }
		public override texture2D GetTexture() { return _proxy.GetTexture(); }
		public override void Reload() { _proxy.Reload(); }
		public override float SizeDensity { get { return Density; } }

		//shared public interface
		/** Specifies the source's pixel density.
		*/
		public float Density { get { return _proxy.Density; } set { _proxy.Density = value; } }
	}

	static class HttpImageSourceCache
	{
		static Dictionary<String,WeakReference<HttpImageSourceImpl>> _cache = new Dictionary<String,WeakReference<HttpImageSourceImpl>>();
		static public HttpImageSourceImpl GetUrl( String url )
		{
			WeakReference<HttpImageSourceImpl> value = null;
			if( _cache.TryGetValue( url, out value ) )
			{
				HttpImageSourceImpl his;
				if( value.TryGetTarget( out his ) )
				{
					if (his.State == ImageSourceState.Failed)
						his.Reload();
					return his;
				}
				_cache.Remove( url );
			}

			var nv = new HttpImageSourceImpl( url );
			_cache.Add( url, new WeakReference<HttpImageSourceImpl>(nv) );
			return nv;
		}
	}

	class HttpImageSourceImpl : LoadingImageSource
	{
		String _url;
		public String Url { get { return _url; } }
		String _contentType;

		public HttpImageSourceImpl( String url )
		{
			_url = url;
		}

		protected override void AttemptLoad()
		{
			try
			{
				HttpLoader.LoadBinary(Url, HttpCallback, LoadFailed);
				_loading = true;
				OnChanged();
			}
			catch( Exception e )
			{
				Fail("Loading image from '" + Url + "' failed. " + e.Message, e);
			}
		}

		void SuccessCallback(texture2D texture)
		{
			_loading = false;
			SetTexture(texture);
		}

		void FailureCallback(Exception e)
		{
			_loading = false;
			Fail("Loading image from HTTP failed. " + e.Message, e);
		}

		ImageOrientation _orientation = ImageOrientation.Identity;
		public override ImageOrientation Orientation
		{
			get { return _orientation; }
		}

		void HttpCallback(HttpResponseHeader response, byte[] data)
		{
			if (response.StatusCode != 200)
			{
				Fail("Loading image from HTTP failed with HTTP Status: " + response.StatusCode + " " +
					response.ReasonPhrase);
				return;
			}

			string ct;
			if (!response.Headers.TryGetValue("content-type",out ct))
				_contentType = "x-missing";
			else
				_contentType = ct;

			_orientation = ExifData.FromByteArray(data).Orientation;

			new BackgroundLoad(data, _contentType, SuccessCallback, FailureCallback);
		}

		class BackgroundLoad
		{
			byte[] _data;
			string _contentType;
			Action<texture2D> _done;
			Action<Exception> _fail;
			Exception _exception;
			public BackgroundLoad(byte[] data, string contentType, Action<texture2D> done, Action<Exception> fail)
			{
				_data = data;
				_contentType = contentType;
				_done = done;
				_fail = fail;

				GraphicsWorker.Dispatch(Run);
			}
			public void Run()
			{
				try
				{
					GWDoneCallback(TextureLoader.ByteArrayToTexture2DContentType(_data, _contentType));
				}
				catch (Exception e)
				{
					_exception = e;
					UpdateManager.AddOnceAction(UIFailCallback);
				}
			}

			texture2D _tex;
			void GWDoneCallback(texture2D tex)
			{
				if defined(OpenGL)
					OpenGL.GL.Finish();

				_tex = tex;
				UpdateManager.AddOnceAction(UIDoneCallback);
			}

			void UIDoneCallback()
			{
				_done(_tex);
			}

			void UIFailCallback()
			{
				var e = _exception;
				_exception = null;
				_fail(e);
			}
		}

		void LoadFailed( string reason )
		{
			Fail("Loading image from '" + Url + "' failed: " + reason);
		}

		void Fail( string msg, Exception e = null )
		{
			Cleanup(CleanupReason.Failed);
			OnError(msg, e);
		}
	}
}
