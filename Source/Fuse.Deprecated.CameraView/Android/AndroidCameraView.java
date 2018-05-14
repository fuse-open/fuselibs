package com.fuse.cameraview;

import android.content.Context;
import android.graphics.ImageFormat;
import android.graphics.Matrix;
import android.graphics.Point;
import android.graphics.RectF;
import android.graphics.SurfaceTexture;
import android.media.ImageReader;
import android.os.Bundle;
import android.os.Handler;
import android.os.HandlerThread;
import android.util.SparseIntArray;
import android.view.LayoutInflater;
import android.view.Surface;
import android.view.TextureView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.graphics.Color;
import android.hardware.Camera;
import android.hardware.Camera.PictureCallback;
import android.util.Log;
import android.os.Environment;
import android.net.Uri;
import android.view.Display;
import android.content.res.Configuration;
import android.media.MediaRecorder;
import android.media.MediaCodecList;
import android.media.CamcorderProfile;
import android.graphics.PixelFormat;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;

import java.io.File;
import java.io.FileOutputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;
import java.util.Date;
import java.lang.Runnable;
import java.lang.Math;

import com.foreign.Uno.Action_String;
import com.fusetools.camera.ImageStorageTools;
import com.fusetools.camera.Image;
import com.fuse.cameraview.AndroidOrientationHelpers;

public class AndroidCameraView extends FrameLayout implements TextureView.SurfaceTextureListener {
	static final String TAG = "AndroidCameraView";

	public static final int MEDIA_TYPE_IMAGE = 1;
	public static final int MEDIA_TYPE_VIDEO = 2;

	private Camera camera = null;
	private int cameraId = 0;
	private TextureView mTextureView = null;

	private int _pictureRotation = 0;

	private Action_String onImageComplete = null;
	private Action_String onImageFail = null;

	private boolean isBackCamera = true;
	private MediaRecorder recorder = null;
	private File videoPath = null;

	private boolean hasAutoFocus = false;

	private int _width = 0;
	private int _height = 0;
	private boolean _isRecording = false;
	private boolean _isTakingPicture = false;
	private boolean _usingFlash = false;
	private int _maxTextureSize = -1;


	public AndroidCameraView()
	{
		super(com.fuse.Activity.getRootActivity());
	}

	public void createAndAddTextureView()
	{
		if (mTextureView != null)
			removeView(mTextureView);

		mTextureView = new TextureView(com.fuse.Activity.getRootActivity());
		mTextureView.setSurfaceTextureListener(this);
		addView(mTextureView);
	}

	public void updateCamera(boolean isBackCamera)
	{
		if (this.isBackCamera == isBackCamera)
			return;

		this.isBackCamera = isBackCamera;
		if (camera == null) return;

		createAndAddTextureView();
	}

	public void takePicture(Action_String onComplete, Action_String onFail, boolean isFullRes, int maxTextureSize)
	{
		if (_isRecording)
			stopRecorder();

		if (_isTakingPicture){
			onFail.run("A picture is being taken already!");
			return;
		}

		if (camera == null) 
		{
			onFail.run("No camera exists!");
			return;
		}

		onImageComplete = onComplete;
		onImageFail = onFail;
		_maxTextureSize = maxTextureSize;

		if (isFullRes)
		{
			Camera.Parameters parameters = camera.getParameters();
			setLargestPictureSize(parameters);
			camera.setParameters(parameters);
		}

		_isTakingPicture = true;

		if (hasAutoFocus)
		{
			try {
				camera.autoFocus(mAutoFocus);
			} catch (Exception exception) {
				// if we fail to auto focus for any reason, try to 
				// just a take a picture with the current focus
				camera.takePicture(null, null, mPicture);
			}
		}
		else 
			camera.takePicture(null, null, mPicture);
	}

	public void startRecording()
	{
		if (_isRecording )
		{
			stopRecorder();
		}

		_isRecording = true;

		recorder = new MediaRecorder();
		camera.unlock();

		recorder.setOrientationHint(_pictureRotation);
		recorder.setCamera(camera);
		videoPath = getOutputMediaFile(MEDIA_TYPE_VIDEO);

		try {
			recorder.setAudioSource(MediaRecorder.AudioSource.DEFAULT);
			recorder.setVideoSource(MediaRecorder.VideoSource.DEFAULT);
			CamcorderProfile cpHigh = CamcorderProfile.get(CamcorderProfile.QUALITY_HIGH);
			recorder.setProfile(cpHigh);
			FileOutputStream fos = new FileOutputStream(videoPath);
			recorder.setOutputFile(fos.getFD());
			recorder.prepare();
			recorder.start();
		} catch (FileNotFoundException e) {
			_isRecording = false;
			Log.d(TAG, "File not found: " + e.getMessage());
		} catch (IOException e) {
			_isRecording = false;
			Log.d(TAG, "Error accessing file: " + e.getMessage());
		}
	}

	/* Stop the recorder, releasing the assets associated with it.
	*/
	private void stopRecorder()
	{
		if (recorder == null) return;

		recorder.stop();
		recorder.reset();
		recorder.release();
	}

	public void stopRecording(Action_String onComplete, Action_String onFail)
	{
		if (recorder == null || !_isRecording) return;

		stopRecorder();
		onComplete.run(videoPath.getAbsolutePath());
		_isRecording = false;
	}

	public boolean setFlash(boolean enableFlash)
	{
		if (camera == null) return false;

		Camera.Parameters parameters = camera.getParameters();

		String flashMode = enableFlash ? "torch" : "off";

		parameters.setFlashMode(flashMode);
		camera.setParameters(parameters);

		parameters = camera.getParameters();

		_usingFlash = enableFlash;

		return parameters.getFlashMode() == flashMode;
	}

	// surface texture callbacks

	public void onSurfaceTextureAvailable(SurfaceTexture surface, int width, int height) {
		// We are using a TextureView so check that api for details on when these get called
		if (mTextureView == null) return;
		
		cameraId = isBackCamera ? getBackCamera() : getFrontCamera();
		try {
			camera = Camera.open(cameraId);
		} catch (RuntimeException e) {
			System.out.println("Unable to open camera");
			e.printStackTrace();
			return;
		}
		
		Camera.Parameters parameters = camera.getParameters();
		List<String> focusModes = parameters.getSupportedFocusModes();

		// On devices where autofocus available (frontfacing cameras) we will take a picture
		// immediately, if there is a focus option we trigger that and when that completes we
		// take the picture
		if (focusModes.contains(Camera.Parameters.FOCUS_MODE_AUTO)) 
		{
			parameters.setFocusMode(Camera.Parameters.FOCUS_MODE_AUTO);
			hasAutoFocus = true;
		} else if (focusModes.contains(Camera.Parameters.FOCUS_MODE_CONTINUOUS_PICTURE)) 
		{
			parameters.setFocusMode(Camera.Parameters.FOCUS_MODE_CONTINUOUS_PICTURE);
			hasAutoFocus = true;
		}
		else 
		{
			hasAutoFocus = false;
		}
		
		// This is a case of making things feel nice as opoosed to what is normal. THe idea is that
		// in a dark setting we will use the torch as then you can see what you are taking a picture of
		// as opposed to only being able to see as the flash happens
		String flashMode = _usingFlash ? "torch" : "off";
		parameters.setFlashMode(flashMode);


		Camera.CameraInfo info = new Camera.CameraInfo(); 
		Camera.getCameraInfo(cameraId, info);
		_pictureRotation = AndroidOrientationHelpers.configureStillCamera(info, camera, parameters);

		// set zoom, etc
		camera.setParameters(parameters);

		// set the actual picture size, which _may_ fail
		setClosestPictureSize(parameters, width, height);
		try {
			camera.setParameters(parameters);
		} catch (RuntimeException e) {
			System.out.println("Unable to set preferred image size: falling back to default");
		}

		try {
			camera.setPreviewTexture(surface);
			camera.startPreview();
		} catch (IOException ioe) {
			System.out.println("Unable to start preview due to " + ioe);
		}
	}

	public void onSurfaceTextureSizeChanged(SurfaceTexture surface, int width, int height) {
		Camera.Parameters parameters = camera.getParameters();
		Camera.CameraInfo info = new Camera.CameraInfo(); 
		Camera.getCameraInfo(cameraId, info);

		_pictureRotation = AndroidOrientationHelpers.configureStillCamera(info, camera, parameters);

		try {
			camera.setParameters(parameters);
		}
		catch (Exception e)
		{
			System.err.println("Something went wrong" + e);
		}
	}

	public boolean onSurfaceTextureDestroyed(SurfaceTexture surface) {
		camera.stopPreview();
		camera.release();
		return true;
	}

	public void onSurfaceTextureUpdated(SurfaceTexture surface) {
		// Invoked every time there's a new Camera preview frame
	}

	// helpers for taking pictures

	private PictureCallback mPicture = new PictureCallback() {
		@Override
		public void onPictureTaken(byte[] data, Camera camera) {
			_isTakingPicture = false;

			File pictureFile = null;

			try {
				pictureFile = new File(ImageStorageTools.createFilePath("jpeg", true));

				// if it's the back camera, we can just write it as-is
				if (isBackCamera)
				{
					FileOutputStream fos = new FileOutputStream(pictureFile);
					fos.write(data);
					fos.close();
				}
				// otherwise, we need to manipulate the image to be the correct orientation
				else
				{
					Bitmap bitmap = rotateAndFlipImage(BitmapFactory.decodeByteArray(data, 0, data.length), _pictureRotation);
					ImageStorageTools.saveBitmap(bitmap, pictureFile.getAbsolutePath());
				} 
			} catch (FileNotFoundException e) {
				Log.d(TAG, "File not found: " + e.getMessage());
			} catch (IOException e) {
				Log.d(TAG, "Error accessing file: " + e.getMessage());
			} catch (Exception e) {
				onImageFail.run("Failed to create an image path correctly");
			}

			if (pictureFile == null){
				Log.d(TAG, "Error creating media file, check storage permissions: ");
				return;
			}

			if (onImageComplete != null)
				onImageComplete.run(pictureFile.getAbsolutePath());

			onImageComplete = null;
			onImageFail = null;
		}
	};

	/** Will take a picture after the camera has auto-focused
	*/
	private Camera.AutoFocusCallback mAutoFocus = new Camera.AutoFocusCallback() {
		@Override
		public void onAutoFocus(boolean success, Camera camera)
		{
			camera.takePicture(null, null, mPicture);
		}
	};

	/** Create a File for saving an image or video 
	*/
	private static File getOutputMediaFile(int type){
		File outputDir = com.fuse.Activity.getRootActivity().getExternalCacheDir(); 
		File mediaStorageDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES);

		// Create a media file name
		String timeStamp = new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date());
		File mediaFile;

		try {
			if (type == MEDIA_TYPE_IMAGE){
				mediaFile = File.createTempFile("IMG_"+ timeStamp, ".jpg", outputDir);
			} else if(type == MEDIA_TYPE_VIDEO) {
				mediaFile = File.createTempFile("VID_"+ timeStamp, ".mp4", outputDir);
			} else {
				return null;
			}
		} catch (IOException e)
		{
			return null;
		}

		return mediaFile;
	}

	/** returns the id of the first front camera found, or -1 if not found
	*/
	public static int getFrontCamera() 
	{
		Camera.CameraInfo cameraInfo = new Camera.CameraInfo();

		for (int cameraId = 0; cameraId < Camera.getNumberOfCameras(); cameraId++)
		{
			Camera.getCameraInfo(cameraId, cameraInfo);

			if (cameraInfo.facing == Camera.CameraInfo.CAMERA_FACING_FRONT)
				return cameraId;
		}

		return -1;
	}

	/** returns the id of the first back camera found, or -1 if not found
	*/
	public static int getBackCamera() 
	{
		Camera.CameraInfo cameraInfo = new Camera.CameraInfo();

		for (int cameraId = 0; cameraId < Camera.getNumberOfCameras(); cameraId++)
		{
			Camera.getCameraInfo(cameraId, cameraInfo);

			if (cameraInfo.facing == Camera.CameraInfo.CAMERA_FACING_BACK)
				return cameraId;
		}

		return -1;
	}

	/** Attempts to find the closest possible width and height supported by the camera for recording
		It uses a combination of the difference in ratios and a different in size
	*/
	void setClosestPictureSize (Camera.Parameters parameters, int width, int height) 
	{
		// Here we are trying to match the ratio of the camera view's element rather than the screen's
		// ratio. Attempts to minimize the ratio difference and the size difference. Does not try to
		// take rotation into account
		float ratioDiff = 99999;
		float sizeDiff = 99999;
		List<Camera.Size> allSizes = parameters.getSupportedPictureSizes();
		Camera.Size size = allSizes.get(0); 

		for (int i = allSizes.size() - 1; i >= 0; i--) {
			Camera.Size currentSize = allSizes.get(i);
			if (currentSize.width < width || currentSize.height < height)
				continue;

			float currentRatioDiff = Math.abs(1 - Math.abs((float)width / (float)currentSize.width) + Math.abs((float)height / (float)currentSize.height));
			float currentSizeDiff = (currentSize.width - width) + (currentSize.height - height);

			if ( (currentRatioDiff < ratioDiff && currentSizeDiff < sizeDiff))
			{
				size = currentSize;
				ratioDiff = currentRatioDiff;
				sizeDiff = currentSizeDiff;
			}
		}

		_width = size.width;
		_height = size.height;
		// These two are HINTS, read the android docs for more details.
		parameters.setPreviewSize(size.width, size.height);
		parameters.setPictureSize(size.width, size.height);

		parameters.setPictureFormat(PixelFormat.JPEG);
		parameters.setJpegQuality(95);
	}

	void setLargestPictureSize (Camera.Parameters parameters) 
	{
		// Find the largest image that the camera can take that Fuse can support.
		int largestWidth = 0;
		int largestHeight = 0;

		List<Camera.Size> allSizes = parameters.getSupportedPictureSizes();
		Camera.Size size = allSizes.get(0); 

		for (int i = allSizes.size() - 1; i >= 0; i--) {
			Camera.Size currentSize = allSizes.get(i);
			if (currentSize.width < largestWidth || currentSize.height < largestHeight)
				continue;

			// avoid capturing images which are bigger than the max texture size 
			if (_maxTextureSize > -1 && (currentSize.width > _maxTextureSize || currentSize.height > _maxTextureSize))
				continue;

			size = currentSize;
			largestWidth = size.width;
			largestHeight = size.height;
		}

		parameters.setPictureSize(largestWidth, largestHeight);

		parameters.setPictureFormat(PixelFormat.JPEG);
		parameters.setJpegQuality(95);
	}

	/** Rotates and flips an image to match what the user expects to see saved
	*/
	static Bitmap rotateAndFlipImage(Bitmap source, float angle) {
		Matrix matrix = new Matrix();
		matrix.postRotate(angle);
		matrix.postScale(1, -1);
		return Bitmap.createBitmap(source, 0, 0, source.getWidth(), source.getHeight(), matrix, true);
	}
}
