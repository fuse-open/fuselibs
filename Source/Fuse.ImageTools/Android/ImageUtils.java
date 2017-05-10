package com.fusetools.camera;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.ThumbnailUtils;
import android.net.Uri;
import android.provider.MediaStore;
import android.util.Log;
import android.util.Base64;

import java.io.File;
import java.io.FileOutputStream;
import java.io.ByteArrayOutputStream;

public class ImageUtils {

	private static final String TAG = ImageUtils.class.getSimpleName();

	public enum ResizeMode
	{
		IGNORE_ASPECT,
		KEEP_ASPECT,
		SCALE_AND_CROP
	}

	public static Image crop(Image inImage, int x, int y, int width, int height, int quality, boolean performInPlace) throws Exception{
		BitmapFactory.Options options = new BitmapFactory.Options();
		Bitmap srcBmp = BitmapFactory.decodeFile(inImage.getFilePath(), options);
		Bitmap dstBmp = Bitmap.createBitmap(srcBmp, x, y, width, height);
		srcBmp.recycle();

		Bitmap.CompressFormat fmt;
		String lowerCaseType = options.outMimeType.toLowerCase();

		if(lowerCaseType.contains("jpeg") || lowerCaseType.contains("jpg")) {
			fmt = Bitmap.CompressFormat.JPEG;
		}else if(lowerCaseType.contains("png")) {
			fmt = Bitmap.CompressFormat.PNG;
		}else{
			throw new Exception("Unknown image file type");
		}

		if(performInPlace)
		{
			File f = inImage.getFile();
			FileOutputStream fOut = new FileOutputStream(f);
			dstBmp.compress(fmt, quality, fOut);
			fOut.flush();
			fOut.close();
			inImage.setDims(dstBmp.getWidth(), dstBmp.getHeight());
			dstBmp.recycle();
			return inImage;
		}else{
			return ImageStorageTools.saveBitmapAndGetImage(dstBmp, true, fmt);
		}
	}

	public static String getContentTypeForImageData(byte[] bytes) {
	    int c = bytes[0];
	    switch (c) {
			  case 0xFF:
			      return "jpg";
			  case 0x89:
			      return "png";
				default:
						return null;
	    }
	}

	public static Image resize(Image inImage, int desiredWidth, int desiredHeight, ResizeMode mode, int quality, boolean performInPlace) throws Exception{
		float width = inImage.getWidth();
		float height = inImage.getHeight();
		float ratio;
		Bitmap temp;
		Bitmap srcBmp = null;
		BitmapFactory.Options options = new BitmapFactory.Options();

		if((int)width == desiredWidth && (int)height == desiredHeight)
			return inImage;

		options.inScaled = true;

		if(width<height){
			options.inDensity = (int)height;
			options.inTargetDensity = desiredHeight;
		}else{
			options.inDensity = (int)width;
			options.inTargetDensity = desiredWidth;
		}

		srcBmp = BitmapFactory.decodeFile(inImage.getFilePath(), options);

		switch(mode){
			case SCALE_AND_CROP:
				ratio = 1.0f;
				if (width > height) {
					if (height > desiredHeight)
					{
						ratio = desiredHeight / height;
					}else if (width > desiredWidth)
					{
						ratio = desiredWidth / width;
					}
				}else {
					if (width > desiredWidth)
					{
						ratio = desiredWidth / width;
					}else if (height > desiredHeight)
					{
						ratio = desiredHeight / height;
					}
				}
				width *= ratio;
				height *= ratio;

				temp = Bitmap.createScaledBitmap(
						srcBmp,
						(int)width,
						(int)height,
						true);
				srcBmp.recycle();
				srcBmp = temp;

				temp = Bitmap.createBitmap(
						srcBmp,
						Math.max(0, (int)width/2 - desiredWidth/2),
						Math.max(0, (int)height/2 - desiredHeight/2),
						Math.min(desiredWidth, (int)width),
						Math.min(desiredHeight, (int)height));
				srcBmp.recycle();
				srcBmp = temp;

				break;
			case IGNORE_ASPECT:
				//Use width/height as given
				temp = Bitmap.createScaledBitmap(
						srcBmp,
						desiredWidth,
						desiredHeight,
						true);
				srcBmp.recycle();
				srcBmp = temp;
		}

		Bitmap.CompressFormat fmt = compressFormatFromOptions(options);

		try{
			if(performInPlace)
			{
				File f = inImage.getFile();
				FileOutputStream fOut = new FileOutputStream(f);
				srcBmp.compress(fmt, quality, fOut);
				fOut.flush();
				fOut.close();
				inImage.setDims(srcBmp.getWidth(), srcBmp.getHeight());
				return inImage;
			}else{
				return ImageStorageTools.saveBitmapAndGetImage(srcBmp, true, fmt);
			}
		}finally{
			srcBmp.recycle();
		}
	}


	public static Bitmap.CompressFormat compressFormatFromOptions(BitmapFactory.Options options) throws Exception
	{
		Bitmap.CompressFormat fmt;
		String lowerCaseType = options.outMimeType.toLowerCase();

		if( lowerCaseType.contains("jpeg") || lowerCaseType.contains("jpg") ) {
			return Bitmap.CompressFormat.JPEG;
		}else if( lowerCaseType.contains("png") ) {
			return Bitmap.CompressFormat.PNG;
		}else{
			throw new Exception("Invalid image format");
		}
	}

	public static String getBase64FromImage(Image inImage)
	{
		ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
		Bitmap bmp = inImage.getBitmap();
		bmp.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOutputStream);
		bmp.recycle();
		byte[] byteArray = byteArrayOutputStream.toByteArray();
		return Base64.encodeToString(byteArray, Base64.DEFAULT);
	}
}
