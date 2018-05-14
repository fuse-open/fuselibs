package com.fuse.cameraview;

import android.annotation.TargetApi;
import android.content.Context;
import android.hardware.Camera;
import android.media.MediaRecorder;
import android.os.Build;
import android.view.OrientationEventListener;
import android.view.Surface;
import android.view.WindowManager;

import com.fuse.Activity;

public class AndroidOrientationHelpers {
    public static int configureStillCamera(Camera.CameraInfo info, Camera camera, Camera.Parameters params) 
    {
      int displayOrientation = getDisplayOrientation(info, true);
      int cameraDisplayOrientation = displayOrientation;
      int outputOrientation = displayOrientation;

      // orientations are flipped if you're facing front
      if (info.facing == Camera.CameraInfo.CAMERA_FACING_FRONT) {
        outputOrientation = (360 - displayOrientation) % 360;
      }

      params.setRotation(outputOrientation);
      camera.setDisplayOrientation(cameraDisplayOrientation);
      return outputOrientation - 90;
    }

    private static int getDisplayOrientation(Camera.CameraInfo info, boolean isPicture) 
    {
      // Heavily inspired by https://github.com/commonsguy/cwac-cam2/blob/master/cam2/src/main/java/com/commonsware/cwac/cam2/plugin/OrientationPlugin.java#L203
	  // special casing for Huawei is done in all decent camera libs as that device is nuts
      int rotation = com.fuse.Activity.getRootActivity().getWindowManager().getDefaultDisplay().getRotation();
      int degrees = 0;

      switch (rotation) {
        case Surface.ROTATION_0:
          degrees = 0;
          break;
        case Surface.ROTATION_90:
          degrees = 90;
          break;
        case Surface.ROTATION_180:
          degrees = 180;
          break;
        case Surface.ROTATION_270:
          degrees = 270;
          break;
      }

      int displayOrientation;

      if (info.facing == Camera.CameraInfo.CAMERA_FACING_FRONT) {
        displayOrientation = (info.orientation + degrees) % 360;
        displayOrientation = (360 - displayOrientation) % 360;

        if (!isPicture && displayOrientation==90) {
          displayOrientation = 270;
        }

        if ("Huawei".equals(Build.MANUFACTURER) &&
          "angler".equals(Build.PRODUCT) && displayOrientation==270) {
          displayOrientation = 90;
        }
      }
      else {
        displayOrientation = (info.orientation - degrees + 360) % 360;
      }

      return displayOrientation;
    }
}
