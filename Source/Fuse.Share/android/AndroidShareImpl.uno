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
					"java.util.ArrayList",
					"android.os.Build",
					"android.net.Uri",
					"android.util.Log", 
					"android.content.Intent",
					"androidx.core.content.FileProvider", 
					"android.content.Context")]
	public extern(Android) class AndroidShareImpl
	{
		[Foreign(Language.Java)]
		public static void ShareText(string text, string description)
		@{
			Intent sendIntent = new Intent();
			sendIntent.setAction(Intent.ACTION_SEND);
			sendIntent.putExtra(Intent.EXTRA_TEXT, text);
			sendIntent.putExtra(Intent.EXTRA_SUBJECT, description);
			sendIntent.setType("text/plain");
			com.fuse.Activity.getRootActivity().startActivity(Intent.createChooser(sendIntent, description));
		@}

		[Foreign(Language.Java)]
		public static void ShareFile(string path, string mimeType, string description)
		@{
			Context context = com.fuse.Activity.getRootActivity();
			Intent shareIntent = new Intent();
			shareIntent.setAction(Intent.ACTION_SEND);
			shareIntent.putExtra(Intent.EXTRA_SUBJECT, description);
			//new way for Marshmallow+ (API 23)
			if (Build.VERSION.SDK_INT > Build.VERSION_CODES.LOLLIPOP) {
				/*
					content:// must be used ~ https://developer.android.com/training/sharing/send
				*/
				Uri uri = Uri.parse("content://" + path);
				File newFile = new File(uri.getPath());
				/* 
					Note: The XML file is the only way you can specify the directories 
					you want to share; you can't programmatically add a directory.
					~ https://developer.android.com/training/secure-file-sharing/setup-sharing 
					~ https://developer.android.com/reference/android/support/v4/content/FileProvider
				*/
				Uri contentUri = FileProvider.getUriForFile(context,
												 "@(Activity.Package).share_file_provider",
												 newFile);
				shareIntent.putExtra(Intent.EXTRA_STREAM, contentUri);
			} else {
				//for older droids 
				Uri uri = Uri.parse("file://" + path);
				shareIntent.putExtra(Intent.EXTRA_STREAM, uri);
			}
			//give temporary read access to file
			shareIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
			shareIntent.setType(mimeType);
			context.startActivity(Intent.createChooser(shareIntent, description));

		@}
	}
}
