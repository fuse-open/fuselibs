package com.fuse.mediapicker;

import android.content.ContentResolver;
import android.content.Context;
import android.net.Uri;
import android.webkit.MimeTypeMap;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

class FileUtils {

	String getPathFromUri(final Context context, final Uri uri) {
		File file = null;
		InputStream inputStream = null;
		OutputStream outputStream = null;
		boolean success = false;
		try {
			String extension = getImageExtension(context, uri);
			inputStream = context.getContentResolver().openInputStream(uri);
			file = File.createTempFile("media_picker", extension, context.getCacheDir());
			file.deleteOnExit();
			outputStream = new FileOutputStream(file);
			if (inputStream != null) {
				copy(inputStream, outputStream);
				success = true;
			}
		} catch (IOException ignored) {
		} finally {
			try {
				if (inputStream != null) inputStream.close();
			} catch (IOException ignored) {
			}
			try {
				if (outputStream != null) outputStream.close();
			} catch (IOException ignored) {
				// If closing the output stream fails, we cannot be sure that the
				// target file was written in full. Flushing the stream merely moves
				// the bytes into the OS, not necessarily to the file.
				success = false;
			}
		}
		return success ? file.getPath() : null;
	}

	private static String getImageExtension(Context context, Uri uriImage) {
		String extension = null;

		try {
			String imagePath = uriImage.getPath();
			if (uriImage.getScheme().equals(ContentResolver.SCHEME_CONTENT)) {
				final MimeTypeMap mime = MimeTypeMap.getSingleton();
				extension = mime.getExtensionFromMimeType(context.getContentResolver().getType(uriImage));
			} else {
				extension =
						MimeTypeMap.getFileExtensionFromUrl(
								Uri.fromFile(new File(uriImage.getPath())).toString());
			}
		} catch (Exception e) {
			extension = null;
		}

		if (extension == null || extension.isEmpty()) {
			//default extension for matches the previous behavior of the plugin
			extension = "jpg";
		}

		return "." + extension;
	}

	private static void copy(InputStream in, OutputStream out) throws IOException {
		final byte[] buffer = new byte[4 * 1024];
		int bytesRead;
		while ((bytesRead = in.read(buffer)) != -1) {
			out.write(buffer, 0, bytesRead);
		}
		out.flush();
	}
}
