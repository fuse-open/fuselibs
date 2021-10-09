package com.fuse.mediapicker;

import android.app.Activity;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import androidx.annotation.NonNull;
import androidx.annotation.VisibleForTesting;
import java.io.File;
import java.util.Map;
import com.foreign.Uno.Action_String;

@SuppressWarnings("deprecation")
public class MediaPicker {

	private static final int CAMERA_DEVICE_FRONT = 1;

	private static final int SOURCE_CAMERA = 0;
	private static final int SOURCE_GALLERY = 1;

	private MediaPickerImpl mediaPickerImpl;
	private Activity activity;


	public MediaPicker() {
		this.mediaPickerImpl = MediaPickerImpl.getInstance();
	}

	private void setupCamera(Map<String, Object> arguments) {
		if (arguments.get("cameraDevice") != null) {
			CameraDevice device;
			int deviceIntValue = (int)arguments.get("cameraDevice");
			if (deviceIntValue == CAMERA_DEVICE_FRONT) {
				device = CameraDevice.FRONT;
			} else {
				device = CameraDevice.REAR;
			}
			mediaPickerImpl.setArguments(arguments);
			mediaPickerImpl.setCameraDevice(device);
		}
	}

	public void pickImage(Map<String, Object> arguments, Action_String result, Action_String reject) {
		this.setupCamera(arguments);
		mediaPickerImpl.setArguments(arguments);
		mediaPickerImpl.setResult(result);
		mediaPickerImpl.setReject(reject);
		int imageSource = (int)arguments.get("source");
		switch (imageSource) {
			case SOURCE_GALLERY:
				mediaPickerImpl.launchPickImageFromGalleryIntent();
				break;
			case SOURCE_CAMERA:
				mediaPickerImpl.takeImageWithCamera();
				break;
			default:
				throw new IllegalArgumentException("Invalid image source: " + imageSource);
		}
	}

	public void pickMultiImage(Map<String, Object> arguments, Action_String result, Action_String reject) {
		this.setupCamera(arguments);
		mediaPickerImpl.setArguments(arguments);
		mediaPickerImpl.setResult(result);
		mediaPickerImpl.setReject(reject);
		mediaPickerImpl.launchMultiPickImageFromGalleryIntent();
	}

	public void pickVideo(Map<String, Object> arguments, Action_String result, Action_String reject) {
		this.setupCamera(arguments);
		mediaPickerImpl.setArguments(arguments);
		mediaPickerImpl.setResult(result);
		mediaPickerImpl.setReject(reject);
		int imageSource = (int)arguments.get("source");
		switch (imageSource) {
			case SOURCE_GALLERY:
				mediaPickerImpl.launchPickVideoFromGalleryIntent();
				break;
			case SOURCE_CAMERA:
				mediaPickerImpl.takeVideoWithCamera();
				break;
			default:
				throw new IllegalArgumentException("Invalid video source: " + imageSource);
		}
	}
}
