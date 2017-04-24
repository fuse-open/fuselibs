package com.fusetools.camera;

import android.app.Activity;
import android.content.ContentResolver;
import android.content.Context;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.os.Environment;
import android.provider.MediaStore;
import android.util.Log;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.text.SimpleDateFormat;
import java.util.Date;
import android.webkit.MimeTypeMap;
import java.util.UUID;

public class ImageStorageTools {
	private static final String TAG = ImageStorageTools.class.getSimpleName();

	// Hmmm when to run this?
	public static void clearCache()
	{
		try{
			File[] files = new File(getTempFileDir()).listFiles();
			for(File f : files){
				f.delete();
			}
		}catch(Exception e){
			e.printStackTrace();
		}
	}

	public static String getFileName(String path)
	{
		return path.substring(path.lastIndexOf(File.separator)+1);
	}

	static void copyStream(InputStream in, OutputStream out) throws Exception
	{
		byte[] buffer = new byte[1024];
		int read;
		while ((read = in.read(buffer)) != -1) {
			out.write(buffer, 0, read);
		}

		in.close();
		in = null;
		out.flush();
		out.close();
		out = null;
	}

	public static Image copyImage(File inputFile, File targetFile, boolean move) throws Exception
	{
		copyStream(new FileInputStream(inputFile), new FileOutputStream(targetFile));

		if(move)
			inputFile.delete();

		return Image.fromPath(targetFile.getAbsolutePath());
	}

	static String getAppName()
	{
		return com.fuse.Activity.getRootActivity().getPackageName();
	}

	public static Image saveBitmapAndGetImage(Bitmap bmp, boolean temp, Bitmap.CompressFormat fmt) throws Exception
	{
		String ext = fmt == Bitmap.CompressFormat.PNG ? "png" : "jpg";

		File f = new File(createFilePath(ext, temp));
		FileOutputStream fOut = new FileOutputStream(f);
		bmp.compress(fmt, 100, fOut);
		fOut.flush();
		fOut.close();
		Image i = Image.fromPath(f.getAbsolutePath());
		i.setDims(bmp.getWidth(), bmp.getHeight());
		bmp.recycle();
		return i;
	}
	
	public static void saveBitmap(Bitmap bmp, String path) throws Exception
	{
		String ext = path.substring(path.lastIndexOf('.') + 1).toLowerCase();
		Bitmap.CompressFormat fmt = ext == "png" ? Bitmap.CompressFormat.PNG : Bitmap.CompressFormat.JPEG;
		File f = new File(path);
		FileOutputStream fOut = new FileOutputStream(f);
		bmp.compress(fmt, 100, fOut);
		fOut.flush();
		fOut.close();
		bmp.recycle();
	}

	public static String createFilePath(String ext, boolean temp) throws Exception
	{
		return getOutputMediaFile(temp, getImageFileName(ext)).getAbsolutePath();
	}

	public static String getTempFileDir()
	{
		return com.fuse.Activity.getRootActivity().getExternalCacheDir().getAbsolutePath() + File.separator + "images";
	}

	public static String getPublicPicturesDir()
	{
		return new File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), getAppName()).getAbsolutePath();
	}

	public static File getOutputMediaFile(boolean temp, String fileName) throws Exception {

		File mediaStorageDir;
		if(temp)
			mediaStorageDir = new File(getTempFileDir());
		else
			mediaStorageDir = new File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), getAppName()); //TODO: Fall back on internal?

		if (!mediaStorageDir.exists()) {
			if (!mediaStorageDir.mkdirs()) {
				Log.e(getAppName(), "failed to create directory");
				throw new Exception("Failed to create application directory for: "+getAppName());
			}
		}

		return new File(mediaStorageDir.getAbsolutePath() + File.separator + fileName);
	}

	public static String getImageFileName(String extension)
	{
		return "IMG_" + UUID.randomUUID().toString() + "." + extension;
	}

	public static Bitmap getBitmapFromContentUri(Uri contentUri) throws Exception
	{
		ContentResolver cr = com.fuse.Activity.getRootActivity().getContentResolver();
		return MediaStore.Images.Media.getBitmap(cr, contentUri);
	}
	
	public static String getMimeType(Uri uriImage)
	{
		ContentResolver cr = com.fuse.Activity.getRootActivity().getContentResolver();
		String strMimeType = null;
		Cursor cursor = cr.query(uriImage,
												new String[] { MediaStore.MediaColumns.MIME_TYPE },
												null, null, null);

		if (cursor != null && cursor.moveToNext())
		{
			strMimeType = cursor.getString(0);
		}

		return strMimeType;
	}
	
	public static Image createScratchFromUri(Uri contentUri) throws Exception
	{
		String type = getMimeType(contentUri);
		String ext = MimeTypeMap.getSingleton().getExtensionFromMimeType(type);
		String name = getImageFileName(ext);
		File outFile = getOutputMediaFile(true, name);
		ContentResolver cr = com.fuse.Activity.getRootActivity().getContentResolver();
		copyStream(cr.openInputStream(contentUri), new FileOutputStream(outFile));
		return Image.fromUri(Uri.fromFile(outFile));
	}

	public static String getRealPathFromURI(Uri contentUri) {
		Cursor cursor = null;
		try {
			String[] proj = { MediaStore.Images.Media.DATA };
			ContentResolver r = com.fuse.Activity.getRootActivity().getContentResolver();
			cursor = r.query(contentUri, proj, null, null, null);
			int column_index = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA);
			cursor.moveToFirst();
			return cursor.getString(column_index);
		}catch(java.lang.IllegalArgumentException e){
			Log.e(getAppName(), "Failed to get file path from uri " + contentUri);
			e.printStackTrace();
			throw(e);
		} finally {
			if (cursor != null)
				cursor.close();
		}
	}
}
