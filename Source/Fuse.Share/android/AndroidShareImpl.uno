using Uno.Compiler.ExportTargetInterop;
using Uno.Threading;

namespace Fuse.Share
{
	[TargetSpecificImplementation]
	[ForeignInclude(Language.Java,
					"android.content.Context",
					"java.io.File",
					"java.io.InputStream",
					"java.io.FileOutputStream",
					"android.net.Uri",
					"android.content.Intent",
					"android.content.Context")]
	public extern(Android) class AndroidShareImpl
	{
		[Foreign(Language.Java)]
		public static void ShareText(string text, string description)
		@{
			Intent sendIntent = new Intent();
			sendIntent.setAction(Intent.ACTION_SEND);
			sendIntent.putExtra(Intent.EXTRA_TEXT, text);
			sendIntent.setType("text/plain");
			com.fuse.Activity.getRootActivity().startActivity(Intent.createChooser(sendIntent, description));
		@}

		[Foreign(Language.Java)]
		public static void ShareFile(string path, string mimeType, string description)
		@{
			Context context = com.fuse.Activity.getRootActivity();
			Intent shareIntent = new Intent();
			shareIntent.setAction(Intent.ACTION_SEND);
			Uri uri = Uri.parse(path);
			shareIntent.putExtra(Intent.EXTRA_STREAM, uri);
			shareIntent.setType(mimeType);
			context.startActivity(Intent.createChooser(shareIntent, description));
		@}
	}
}
