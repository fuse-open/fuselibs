package com.fuse.controls.cameraview;

public interface IPictureCallback {
	void onPictureTaken(byte[] data);
	void onError(Exception e);
}