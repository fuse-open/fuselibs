using Uno;
using Uno.IO;
using Uno.UX;
using Uno.Threading;
using Fuse.Android.Bindings;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Audio
{
	[ForeignInclude(Language.Java,
					"java.io.ByteArrayInputStream",
					"java.io.File",
					"java.io.FileOutputStream",
					"java.io.IOException",
					"java.io.InputStream",
					"android.net.Uri",
					"android.content.Context",
					"android.media.AudioTrack",
					"android.media.MediaPlayer",
					"android.media.MediaDataSource",
					"android.content.res.AssetFileDescriptor",
					"com.uno.UnoBackedByteBuffer")]
	internal extern(Android) class SoundPlayer
	{
		public static void PlaySoundFromBundle(BundleFileSource fileSource)
		{
			PlaySoundFromAFD(AndroidDeviceInterop.OpenAssetFileDescriptor(fileSource));
		}

		[Foreign(Language.Java)]
		static void PlaySoundFromAFD(Java.Object afd)
		@{
			final AssetFileDescriptor fd = (AssetFileDescriptor)afd;
			final MediaPlayer mp = new MediaPlayer();
			try
			{
				mp.setDataSource(fd.getFileDescriptor(), fd.getStartOffset(), fd.getLength());
				fd.close();
				mp.prepare();
			}
			catch (Throwable e)
			{
				com.fuse.AndroidInteropHelper.UncheckedThrow(e);
				return;
			}
			mp.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
				@Override
				public void onCompletion(MediaPlayer mediaPlayer) {
					mediaPlayer.reset();
					mediaPlayer.release();
				}
			});
			mp.start();
		@}

		[Foreign(Language.Java)]
		static void PlaySoundFromMediaDataSource(Java.Object mediaDataSource)
		@{
			final MediaDataSource mds = (MediaDataSource)mediaDataSource;
			final MediaPlayer mp = new MediaPlayer();
			try
			{
				mp.setDataSource(mds);
				mp.prepare();
			}
			catch (Throwable e)
			{
				com.fuse.AndroidInteropHelper.UncheckedThrow(e);
				return;
			}
			mp.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
				@Override
				public void onCompletion(MediaPlayer mediaPlayer) {
					mediaPlayer.reset();
					mediaPlayer.release();
				}
			});
			mp.start();
		@}

		[Foreign(Language.Java)]
		static void PlaySoundFromByteArrayInner(Java.Object unoStream)
		@{
			InputStream inStream = (InputStream)unoStream;
			Context context = com.fuse.Activity.getRootActivity();
			File file = null;
			try {
				file = File.createTempFile("tmp",".wav", context.getCacheDir());
				file.deleteOnExit();
				FileOutputStream out = new FileOutputStream(file);
				byte[] buffer = new byte[1024];
				int read;
				while ((read = inStream.read(buffer)) != -1) {
					out.write(buffer, 0, read);
				}
				out.close();
				inStream.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
			if(file==null) return;

			final File fileToPlay = file;
			final MediaPlayer mp = MediaPlayer.create(context, Uri.fromFile(fileToPlay));
			mp.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
				@Override
				public void onCompletion(MediaPlayer mediaPlayer) {
					mediaPlayer.reset();
					mediaPlayer.release();
					fileToPlay.delete();
				}
			});
			mp.start();
		@}

		public static void PlaySoundFromByteArray(byte[] byteArray)
		{
			var buf = ForeignDataView.Create(byteArray);

			if (global::Android.Base.Versions.ApiLevel < 23)
				PlaySoundFromByteArrayInner(AndroidDeviceInterop.MakeBufferInputStream(byteArray));
			else
				PlaySoundFromMediaDataSource(AndroidDeviceInterop.MakeMediaDataSource(byteArray));
		}
	}
}
