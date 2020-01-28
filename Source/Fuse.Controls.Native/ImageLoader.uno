using Uno;
using Uno.Collections;
using Uno;
using Uno.Threading;
using Uno.IO;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;
using Uno.Collections;
using Fuse.Resources;
using Fuse.Elements;

namespace Fuse.Controls.Native
{

	extern(Android || iOS) internal class ImageHandle : IDisposable
	{
		public object Handle
		{
			get
			{
				if (_isDisposed)
					throw new Exception("ImageHandle is disposed");
				return _handle;
			}
		}

		public string Name
		{
			get { return _name; }
		}

		object _handle;
		string _name;
		int _pinCount = 0;

		public ImageHandle(string name, object handle)
		{
			_handle = handle;
			_name = name;
			Pin();
		}

		public void Pin()
		{
			_pinCount++;
		}

		bool _isDisposed = false;
		public void Dispose()
		{
			if (!_isDisposed)
			{
				_pinCount--;
				if (_pinCount == 0)
				{
					ImageLoader.ReleaseHandle(this);
					_isDisposed = true;
				}
			}
		}
	}

	extern(Android || iOS) internal static class ImageLoader
	{

		static Dictionary<string, ImageHandle> _imageHandleCache =
			new Dictionary<string, ImageHandle>();

		static Dictionary<string, ImageHandlePromise> _pendingeImages =
			new Dictionary<string, ImageHandlePromise>();

		public static ImageHandle Load(FileSource fileSource)
		{
			ImageHandle handle = null;
			if (fileSource is BundleFileSource)
			{
				handle = Load(((BundleFileSource)fileSource).BundleFile);
			}
			else if (_imageHandleCache.TryGetValue(fileSource.Name, out handle))
			{
				handle.Pin();
			}
			else
			{
				var data = fileSource.ReadAllBytes();
				var path = Uno.IO.Directory.GetUserDirectory(Uno.IO.UserDirectory.Data) + "/tempImage";
				Uno.IO.File.WriteAllBytes(path, data);

				if defined(Android)
					handle = new ImageHandle(fileSource.Name, LoadFile(path));
				else if defined(iOS)
					handle = new ImageHandle(fileSource.Name, LoadUri("file://" + path));

				Uno.IO.File.Delete(path);
				_imageHandleCache.Add(fileSource.Name, handle);
			}
			return handle;
		}

		public static ImageHandle Load(BundleFile bundleFile)
		{
			if defined(Android)
			{
				return Load(bundleFile.BundlePath);
			}
			else if defined(iOS)
			{
				return Load(GetBundleAbsolutePath("data/" + bundleFile.BundlePath));
			}
		}

		public static ImageHandle Load(string uri)
		{
			ImageHandle handle = null;
			if (_imageHandleCache.TryGetValue(uri, out handle))
			{
				handle.Pin();
			}
			else
			{
				handle = new ImageHandle(uri, LoadUri(uri));
				_imageHandleCache.Add(uri, handle);
			}
			return handle;
		}

		public static Future<ImageHandle> Load(HttpImageSource http)
		{
			ImageHandlePromise pending = null;
			if (_imageHandleCache.ContainsKey(http.Url))
			{
				var h = _imageHandleCache[http.Url];
				h.Pin();
				return new Promise<ImageHandle>(h);
			}
			else if (_pendingeImages.TryGetValue(http.Url, out pending))
			{
				return new PendingPromise(pending);
			}
			else
			{
				return new ImageHandlePromise(http.Url);
			}
		}

		class PendingPromise : Promise<ImageHandle>
		{
			readonly Future<ImageHandle> _future;

			public PendingPromise(Future<ImageHandle> future)
			{
				_future = future;
				_future.Then(OnResolve);
			}

			void OnResolve(ImageHandle handle)
			{
				handle.Pin();
				Resolve(handle);
			}

			public override void Dispose()
			{
				base.Dispose();
				_future.Dispose();
			}
		}

		extern(iOS) class ImageHandlePromise : Promise<ImageHandle>
		{

			readonly string _url;
			readonly List<Future<ObjC.Object>> _dispose = new List<Future<ObjC.Object>>();

			public ImageHandlePromise(string url) : base(UpdateManager.Dispatcher)
			{
				ImageLoader._pendingeImages.Add(url, this);
				_url = url;
				var download = Promise<ObjC.Object>.Run(UpdateManager.Dispatcher, Download);
				var then = download.Then(OnDone);
				_dispose.Add(download);
				_dispose.Add(then);
			}

			void OnDone(ObjC.Object obj)
			{
				if (obj == null)
				{
					Reject(new Exception("Failed to load image from: " + _url));
				}
				else
				{
					var imageHandle = new ImageHandle(_url, obj);
					ImageLoader._imageHandleCache.Add(_url, imageHandle);
					Resolve(imageHandle);
				}
				ImageLoader._pendingeImages.Remove(_url);
			}

			ObjC.Object Download()
			{
				return Download(_url);
			}

			[Foreign(Language.ObjC)]
			static ObjC.Object Download(string url)
			@{
				NSData* data = [NSData dataWithContentsOfURL: [NSURL URLWithString: url]];
				return [UIImage imageWithData:data];
			@}

			public override void Dispose()
			{
				base.Dispose();
				foreach(var p in _dispose)
					p.Dispose();
			}
		}

		extern(Android) class ImageHandlePromise : Promise<ImageHandle>
		{

			readonly string _url;
			readonly List<Future<Java.Object>> _dispose = new List<Future<Java.Object>>();

			public ImageHandlePromise(string url) : base(UpdateManager.Dispatcher)
			{
				ImageLoader._pendingeImages.Add(url, this);
				_url = url;
				var download = Promise<Java.Object>.Run(UpdateManager.Dispatcher, Download);
				var then = download.Then(OnDone);
				_dispose.Add(download);
				_dispose.Add(then);
			}

			void OnDone(Java.Object obj)
			{
				if (obj == null)
				{
					Reject(new Exception("Failed to load image from: " + _url));
				}
				else
				{
					var imageHandle = new ImageHandle(_url, obj);
					ImageLoader._imageHandleCache.Add(_url, imageHandle);
					Resolve(imageHandle);
				}
				ImageLoader._pendingeImages.Remove(_url);
			}

			Java.Object Download()
			{
				return Download(_url);
			}

			[Foreign(Language.Java)]
			static Java.Object Download(string url)
			@{
				try
				{
					java.net.URL javaUrl = new java.net.URL(url);
					java.net.HttpURLConnection connection = (java.net.HttpURLConnection)javaUrl.openConnection();
					connection.setDoInput(true);
					connection.connect();
					java.io.InputStream input = connection.getInputStream();
					android.graphics.Bitmap bitmap = android.graphics.BitmapFactory.decodeStream(input);
					return bitmap;
				}
				catch(java.io.IOException e)
				{
					return null;
				}
			@}

			public override void Dispose()
			{
				base.Dispose();
				foreach(var p in _dispose)
					p.Dispose();
			}
		}

		public static void ReleaseHandle(ImageHandle handle)
		{
			if (_imageHandleCache.ContainsKey(handle.Name))
			{
				_imageHandleCache.Remove(handle.Name);
				if defined(Android)
					Release((Java.Object)handle.Handle);
			}
		}

		[Foreign(Language.Java)]
		extern(Android) static void Release(Java.Object bitmap)
		@{
			((android.graphics.Bitmap)bitmap).recycle();
		@}

		[Foreign(Language.Java)]
		extern(Android) static Java.Object LoadUri(string uri)
		@{
			android.graphics.Bitmap bitmap = null;
			try
			{
				java.io.InputStream stream = com.fuse.Activity.getRootActivity()
					.getAssets()
					.open(uri);
				bitmap = android.graphics.BitmapFactory.decodeStream(stream);
				stream.close();
				return bitmap;
			}
			catch (Exception e)
			{
				android.util.Log.e("Fuse.Controls.Native.Android.ImageView", e.getMessage());
			}
			return null;
		@}

		[Foreign(Language.Java)]
		extern(Android) static Java.Object LoadFile(string filePath)
		@{
			android.graphics.Bitmap bitmap = null;
			try
			{
				bitmap = android.graphics.BitmapFactory.decodeFile(filePath);
				return bitmap;
			}
			catch (Exception e)
			{
				android.util.Log.e("Fuse.Controls.Native.Android.ImageView", e.getMessage());
			}
			return null;
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) static ObjC.Object LoadUri(string uri)
		@{
			NSData* data = [NSData dataWithContentsOfURL: [NSURL URLWithString: uri]];
			return [UIImage imageWithData:data];
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) static string GetBundleAbsolutePath(string bundlePath)
		@{
			return [[[NSBundle bundleForClass:[StrongUnoObject class]] URLForResource:bundlePath withExtension:@""] absoluteString];
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) static ObjC.Object LoadUrl(string url)
		@{
			return [UIImage imageWithCIImage:[CIImage imageWithContentsOfURL:[NSURL URLWithString: url]]];
		@}

	}

}
