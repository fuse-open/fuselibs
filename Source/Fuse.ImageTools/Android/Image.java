package com.fuse.camera;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.media.ThumbnailUtils;
import android.media.ExifInterface;
import android.net.Uri;
import android.provider.MediaStore;
import android.util.Log;
import android.util.Base64;
import android.os.Build;

import java.io.File;
import java.io.FileOutputStream;
import java.io.ByteArrayOutputStream;


public class Image {

	public final static String DEFAULT_FORMAT = "jpg";
	private class Pt
	{
		public int x;
		public int y;
		public Pt(int x, int y)
		{
			this.x = x;
			this.y = y;
		}
	}

	Pt _dims;

	private static final String TAG = Image.class.getSimpleName();

	private Uri _fileUri;
	public Uri getFileUri()
	{
		return _fileUri;
	}

	public File getFile()
	{
		return new File(_fileUri.getPath());
	}

	public String getFileName()
	{
		return ImageStorageTools.getFileName(getFilePath());
	}

	public String getExtension()
	{
		String filenameArray[] = getFileName().split("\\.");
		return filenameArray[filenameArray.length-1];
	}

	public String getFilePath()
	{
		return getFile().getAbsolutePath();
	}

	public static BitmapFactory.Options getBitmapOptionsWithoutDecoding(String url){
		BitmapFactory.Options opts = new BitmapFactory.Options();
		opts.inJustDecodeBounds = true;
		BitmapFactory.decodeFile(url, opts);
		return opts;
	}

	//ref: https://stackoverflow.com/a/32206045/2139770
	public static int getBitmapSizeWithoutDecoding(String url){
		BitmapFactory.Options opts = getBitmapOptionsWithoutDecoding(url);
		return opts.outHeight*opts.outWidth*32/(1024*1024*8);
	}

	//ref: http://stackoverflow.com/questions/6073744/android-how-to-check-how-much-memory-is-remaining
	public static double availableMemoryMB(){
		Runtime runtime = Runtime.getRuntime();
		long maxHeapSizeInMB=runtime.maxMemory() / 1048576L;
		long usedMemInMB=(runtime.totalMemory() - runtime.freeMemory()) / 1048576L;
		return maxHeapSizeInMB - usedMemInMB;
	}

	static Bitmap rotateImage(Bitmap source, float angle) {
		Matrix matrix = new Matrix();
		matrix.postRotate(angle);
		return Bitmap.createBitmap(source, 0, 0, source.getWidth(), source.getHeight(), matrix, true);
	}

	//ref: https://developer.android.com/topic/performance/graphics/load-bitmap
	public static int calculateInSampleSize(BitmapFactory.Options options, int reqWidth, int reqHeight) {
		// Raw height and width of image
		final int height = options.outHeight;
		final int width = options.outWidth;
		int inSampleSize = 1;

		if (height > reqHeight || width > reqWidth) {

			final int halfHeight = height / 2;
			final int halfWidth = width / 2;

			// Calculate the largest inSampleSize value that is a power of 2 and keeps both
			// height and width larger than the requested height and width.
			while ((halfHeight / inSampleSize) >= reqHeight
							&& (halfWidth / inSampleSize) >= reqWidth) {
				inSampleSize *= 2;
			}
		}

		return inSampleSize;
	}

	public void correctOrientationFromExif()
	{
		try{
			int orientation =
				new ExifInterface(getFilePath())
					.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_UNDEFINED);

			int angle = 0;
			switch(orientation) {
				case ExifInterface.ORIENTATION_ROTATE_90:
					angle = 90;
				break;
				case ExifInterface.ORIENTATION_ROTATE_180:
					angle = 180;
				break;
				case ExifInterface.ORIENTATION_ROTATE_270:
					angle = 270;
				break;
				default:
					return;
			}

			Bitmap bmp = getBitmap();
			try {
				bmp = rotateImage(bmp, angle);
			} catch (OutOfMemoryError oome1) {

				/*
				Attempt to downsize image, else dont do anything to the image.
				Detect only for less than Oreo cos harder to get OutOfMemory errors on Oreo+
				~ https://stackoverflow.com/questions/48091403/how-does-bitmap-allocation-work-on-oreo-and-how-to-investigate-their-memory
				*/
				if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {

					// First decode with inJustDecodeBounds=true to check dimensions
					final BitmapFactory.Options options = new BitmapFactory.Options();
					options.inJustDecodeBounds = true;
					BitmapFactory.decodeFile(_fileUri.getPath(), options);

					//determine reduced resolution
					long imageSize = getBitmapSizeWithoutDecoding(_fileUri.getPath());

					double targetMB = availableMemoryMB() / 2;

					if (targetMB < imageSize) {

						double reductionPerc = targetMB / imageSize;
						int newWidth = (int) Math.round(options.outWidth * reductionPerc);
						int newHeight = (int) Math.round(options.outHeight * reductionPerc);

						// Calculate inSampleSize
						options.inSampleSize = calculateInSampleSize(options, newWidth, newHeight);

						// Decode bitmap with inSampleSize set
						options.inJustDecodeBounds = false;
						try {
							bmp = BitmapFactory.decodeFile(_fileUri.getPath(), options);
							bmp = rotateImage(bmp, angle);
						} catch (OutOfMemoryError oome2) {
							//do nothing to image
						}
					}
				}
			}
			ImageStorageTools.saveBitmap(bmp, getFilePath());
			bmp.recycle();
		}catch(Exception e){
			e.printStackTrace();
		}

	}

	public Bitmap getBitmap(){
		return BitmapFactory.decodeFile(_fileUri.getPath(), null);
	}

	void setDims(int width, int height)
	{
		_dims = new Pt(width, height);
	}

	public int getWidth()
	{
		checkDims();
		return _dims.x;
	}
	public int getHeight()
	{
		checkDims();
		return _dims.y;
	}

	private void checkDims()
	{
		if(_dims!=null) return;
		BitmapFactory.Options options = new BitmapFactory.Options();
		options.inJustDecodeBounds = true;
		Bitmap bmp = BitmapFactory.decodeFile(_fileUri.getPath(), options);
		_dims = new Pt(options.outWidth, options.outHeight);
	}

	private Image(Uri fileUri) {
		_fileUri = fileUri;
	}

	private Image() throws Exception
	{
		_fileUri = Uri.fromFile(new File(ImageStorageTools.createFilePath(DEFAULT_FORMAT, true)));
	}

	public static Image fromUri(Uri fileUri)
	{
		return new Image(fileUri);
	}

	public static Image fromPath(String filePath)
	{
		return new Image(Uri.fromFile(new File(filePath)));
	}

	public static Image fromBase64(String b64) throws Exception
	{
		byte[] decodedString = Base64.decode(b64, Base64.DEFAULT);
		Bitmap bmp = BitmapFactory.decodeByteArray(decodedString, 0, decodedString.length);
		return ImageStorageTools.saveBitmapAndGetImage(bmp, true, Bitmap.CompressFormat.JPEG);
	}

	public static Image fromBitmap(Bitmap bmp) throws Exception
	{
		return ImageStorageTools.saveBitmapAndGetImage(bmp, true, Bitmap.CompressFormat.PNG);
	}


	public static Image fromBytes(byte[] bitmapdata) throws Exception
	{
		BitmapFactory.Options options = new BitmapFactory.Options();
		Bitmap bmp = BitmapFactory.decodeByteArray(bitmapdata, 0, bitmapdata.length, options);
		Bitmap.CompressFormat fmt = ImageUtils.compressFormatFromOptions(options);
		return ImageStorageTools.saveBitmapAndGetImage(bmp, true, fmt);
	}

	public static Image create() throws Exception
	{
		return new Image();
	}
}
