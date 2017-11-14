using Uno;
using Uno.UX;

using Fuse.Scripting;

namespace Fuse.Controls
{
	public partial class Image
	{
		static Image()
		{
			ScriptClass.Register(typeof(Image),
				new ScriptMethod<Image>("reload", reload),
				new ScriptMethod<Image>("retry", retry));
		}
		
		/**
			Reload the image source.
			
			@scriptmethod reload( )
		*/
		static void reload(Image img)
		{
			var src = img.Source;
			if (src != null)
				src.Reload();
		}

		/**
			Reload the image source if it is in a failed state.
			
			@scriptmethod retry( )
		*/
		static void retry(Image img)
		{
			var src = img.Source;
			if (src != null && src.State == Fuse.Resources.ImageSourceState.Failed)
				src.Reload();
		}
	}
}
