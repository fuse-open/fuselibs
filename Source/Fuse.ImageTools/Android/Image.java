package com.fusetools.camera;

import android.app.ActivityManager;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.media.ExifInterface;
import android.net.Uri;
import android.util.Log;
import android.util.Base64;

import com.fuse.Activity;

import java.io.File;


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
	
	static Bitmap rotateImage(Bitmap source, float angle) {
		Matrix matrix = new Matrix();
		matrix.postRotate(angle);
		return Bitmap.createBitmap(source, 0, 0, source.getWidth(), source.getHeight(), matrix, true);
	}
	
	public void correctOrientationFromExif()
	{
		try{
			int orientation = 
				new ExifInterface(getFilePath())
					.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_UNDEFINED);
			
			Bitmap out = null;
			
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
			// Check if we have space to decompress twice in memory
			int sizeInMb2X = (getWidth() * getHeight() * 4 * 2) / 1000;
			ActivityManager.MemoryInfo mi = new ActivityManager.MemoryInfo();
			ActivityManager activityManager = (ActivityManager)com.fuse.Activity.getRootActivity().getSystemService(Context.ACTIVITY_SERVICE);
			activityManager.getMemoryInfo(mi);
			long availableMemMb = mi.availMem / 1048576L;
			if(sizeInMb2X > availableMemMb){
				Log.w(TAG, "Not enough memory to rotate image, result may be unexpected.");
				throw new Exception("Not enough memory to rotate image");
			}
			
			Bitmap bmp = getBitmap();
			out = rotateImage(bmp, angle);
			bmp.recycle();
			ImageStorageTools.saveBitmap(out, getFilePath());
			out.recycle();
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
