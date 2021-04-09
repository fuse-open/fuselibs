using Uno;
using Uno.UX;

using Fuse.Scripting;
using Fuse.Resources;

namespace Fuse.Controls
{
	public partial class Image
	{
		static Image()
		{
			ScriptClass.Register(typeof(Image),
				new ScriptMethod<Image>("load", load),
				new ScriptMethod<Image>("reload", reload),
				new ScriptMethod<Image>("retry", retry),
				new ScriptMethod<Image>("clearCache", clearCache));
		}

		/**
			Reload the image source.

			@scriptmethod reload( )
		*/
		static void load(Image img)
		{
			img.Load();
		}

		/**
			Reload the image source.

			@scriptmethod reload( )
		*/
		static void reload(Image img)
		{
			img.Reload();
		}

		/**
			Reload the image source if it is in a failed state.

			@scriptmethod retry( )
		*/
		static void retry(Image img)
		{
			var src = img.Source;
			if (src != null && src.State == Fuse.Resources.ImageSourceState.Failed)
				img.Reload();
		}

		/**
			Clear the image cache from disk. only applicable if image source is from Url

			@scriptmethod clearCache( )
		*/
		static void clearCache(Image img)
		{
			var src = img.Source;
			if (src != null)
			{
				var http = src as HttpImageSource;
				if (http != null)
					http.ClearCache();
			}
		}
	}
}
