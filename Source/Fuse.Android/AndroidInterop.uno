using Uno;
using Uno.IO;
using Uno.UX;
using Uno.Platform;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using Fuse;
using Fuse.Drawing;

namespace Fuse.Android.Bindings
{
	[ForeignInclude(Language.Java, "android.content.Intent", "android.net.Uri", "android.app.Activity",
					"android.content.res.AssetFileDescriptor", "android.content.res.AssetManager")]
	[Require("Source.Include", "@{Uno.Platform.CoreApp:Include}")]
	internal extern(Android) static class AndroidDeviceInterop
	{
		[Foreign(Language.Java)]
		public static extern(Android) Java.Object LaunchIntent(string action, string uri, string packageName=null, string className=null)
		@{
			Intent pendingIntent = new Intent(action);
			pendingIntent.setData(Uri.parse(uri));

			if (packageName!=null && className!=null)
				pendingIntent.setClassName(packageName, className);

			Activity a = com.fuse.Activity.getRootActivity();
			a.startActivity(pendingIntent);
			return pendingIntent;
		@}

		[Foreign(Language.Java)]
		public static extern(Android) Java.Object LaunchApp(string action, string applicationId)
		@{
			Intent pendingIntent = null;
			Activity a = com.fuse.Activity.getRootActivity();

			try
			{
				pendingIntent = a.getPackageManager().getLaunchIntentForPackage(applicationId);
				a.startActivity(pendingIntent);
			} 
			catch (Exception e) 
			{
				pendingIntent = new Intent(action).setData(Uri.parse("https://play.google.com/store/apps/details?id=" + applicationId));
				a.startActivity(pendingIntent);
			}

			return pendingIntent;
		@}

		public static Java.Object OpenAssetFileDescriptor(BundleFileSource fileSource)
		{
			return OpenAssetFileDescriptor(fileSource.BundleFile);
		}

		[Foreign(Language.Java)]
		public static Java.Object OpenAssetFileDescriptor(BundleFile bundle)
		@{
			try
			{
				String uri = @{BundleFile:Of(bundle).BundlePath:Get()};
				AssetManager am = com.fuse.Activity.getRootActivity().getAssets();
				AssetFileDescriptor afd = am.openFd(uri);
				return afd;
			}
			catch (Throwable e)
			{
				com.fuse.AndroidInteropHelper.UncheckedThrow(e);
				return null;
			}
		@}

		public static Java.Object MakeMediaDataSource(byte[] unoArr)
		{
			var buf = ForeignDataView.Create(unoArr);
			return MakeMediaDataSource(buf);
		}

		[Foreign(Language.Java)]
		public static Java.Object MakeMediaDataSource(Java.Object buf) // UnoBackedByteBuffer buf
		@{
			return new com.fuse.android.ByteBufferMediaDataSource((com.uno.UnoBackedByteBuffer)buf);
		@}

		public static Java.Object MakeBufferInputStream(byte[] unoArr)
		{
			var buf = ForeignDataView.Create(unoArr);
			return MakeBufferInputStream(buf);
		}

		[Foreign(Language.Java)]
		public static Java.Object MakeBufferInputStream(Java.Object buf) // UnoBackedByteBuffer buf
		@{
			return new com.fuse.android.ByteBufferInputStream((com.uno.UnoBackedByteBuffer)buf);
		@}
	}
}
