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
				new ScriptMethod<Image>("reload", reload, ExecutionThread.MainThread),
				new ScriptMethod<Image>("retry", retry, ExecutionThread.MainThread));
		}
		
		/**
			Reload the image source.
			
			@scriptmethod reload( )
		*/
		static void reload(Context c, Image img, object[] args)
		{
			if (args.Length != 0)
			{
				Fuse.Diagnostics.UserError( "reload takes no parameters", img );
				return;
			}

			var src = img.Source;
			if (src != null)
				src.Reload();
		}

		/**
			Reload the image source if it is in a failed state.
			
			@scriptmethod retry( )
		*/
		static void retry(Context c, Image img, object[] args)
		{
			if (args.Length != 0)
			{
				Fuse.Diagnostics.UserError( "retry takes no parameters", img );
				return;
			}

			var src = img.Source;
			if (src != null && src.State == Fuse.Resources.ImageSourceState.Failed)
				src.Reload();
		}
	}
}