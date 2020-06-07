package com.fuse.controls.cameraview;

import android.widget.FrameLayout;
import android.view.TextureView;
import android.content.Context;
import android.view.ViewGroup;
import android.hardware.Camera;
import android.hardware.Camera.Size;
import android.view.Surface;
import java.util.List;
import java.util.ArrayList;
import android.graphics.SurfaceTexture;
import android.graphics.Matrix;
import android.graphics.Rect;
import android.media.MediaRecorder;
import android.view.OrientationEventListener;
import android.util.Log;
import android.view.Display;

public class CameraImpl extends TextureView implements TextureView.SurfaceTextureListener {

    final Camera _camera;
    boolean _autoFocus;
    final int _maxWidth;
    final int _maxHeight;
    final int _cameraId;
    final OrientationEventListener _orientationListener;

    int _cameraRotation = 0;
    int _previewWidth;
    int _previewHeight;

    public CameraImpl(Context context, Camera camera, int cameraId, int maxWidth, int maxHeight) {
        super(context);
        _maxWidth = maxWidth;
        _maxHeight = maxHeight;
        _camera = camera;
        _cameraId = cameraId;
        _autoFocus = initFocus();
        setSurfaceTextureListener(this);
        _orientationListener = new OrientationEventListener(context) {

            // This logic is from https://developer.android.com/reference/android/hardware/Camera.Parameters.html#setRotation(int)
            public void onOrientationChanged(int orientation) {
                if (orientation == OrientationEventListener.ORIENTATION_UNKNOWN)
                    return;
                Camera.CameraInfo info = new Camera.CameraInfo();
                Camera.getCameraInfo(_cameraId, info);
                int displayRotation = getDisplayRotationDegrees();
                orientation = (orientation + 45) / 90 * 90;
                int rotation = 0;
                if (info.facing == Camera.CameraInfo.CAMERA_FACING_FRONT) {
                    if (((orientation / 90) % 2) > 0) {
                        rotation = 360 - info.orientation;
                    } else {
                        rotation = info.orientation;
                    }
                } else {
                    rotation = info.orientation;
                }
                // Account for display orientation, where orientation is whether
                // the os UI is in protrait/landscape
                rotation = (360 - displayRotation + rotation) % 360;
                _cameraRotation = rotation;
            }
        };
        _orientationListener.enable();
    }

    void resumeFocus() {
        if (!_autoFocus)
            return;
        List<String> focusModes = _camera.getParameters().getSupportedFocusModes();
        if (focusModes.contains(Camera.Parameters.FOCUS_MODE_CONTINUOUS_PICTURE)) {
            _camera.cancelAutoFocus();
        }
    }

    boolean initFocus() {
        Camera.Parameters parameters = _camera.getParameters();
        List<String> focusModes = parameters.getSupportedFocusModes();
        boolean autoFocus = false;
        if (focusModes.contains(Camera.Parameters.FOCUS_MODE_CONTINUOUS_PICTURE)) {
            parameters.setFocusMode(Camera.Parameters.FOCUS_MODE_CONTINUOUS_PICTURE);
            autoFocus = true;
        } else if (focusModes.contains(Camera.Parameters.FOCUS_MODE_AUTO)) {
            parameters.setFocusMode(Camera.Parameters.FOCUS_MODE_AUTO);
            autoFocus = true;
        }
        _camera.setParameters(parameters);
        return autoFocus;
    }

    boolean _previewRunning = false;

    public void onSurfaceTextureAvailable(SurfaceTexture surface, int width, int height) {
        Camera.Parameters parameters = _camera.getParameters();
        Size pictureSize = getPictureSize(parameters.getSupportedPictureSizes(), width, height);
        parameters.setPictureSize(pictureSize.width, pictureSize.height);
        Camera.Size previewSize = getOptimalPreviewSize(parameters.getSupportedPreviewSizes(), width, height, pictureSize);
        UpdateTransform(previewSize, width, height);
        parameters.setPreviewSize(previewSize.width, previewSize.height);
        try {
            _camera.setParameters(parameters);
            _camera.setDisplayOrientation(getPreviewRotation());
            _camera.setPreviewTexture(surface);
            _camera.startPreview();
            _previewRunning = true;
        } catch(Exception e) {
            android.util.Log.d(toString(), e.getMessage());
        }
    }

    public boolean onSurfaceTextureDestroyed(SurfaceTexture surface) {
        _camera.stopPreview();
        try {
            _camera.setPreviewTexture(null);
        } catch(Exception e) {
            android.util.Log.d(toString(), e.getMessage());
        }
        return true;
    }

    public void onSurfaceTextureSizeChanged(SurfaceTexture surface, int width, int height) {
        updatePreview(width, height);
    }

    public void onSurfaceTextureUpdated(SurfaceTexture surface) {}

    boolean _shouldFill = false;
    public void updateStretchMode(boolean shouldFill) {
        _shouldFill = shouldFill;
        if (_previewRunning)
            updatePreview(getWidth(), getHeight());
    }

    void updatePreview(int width, int height) {
        _camera.stopPreview();
        Camera.Parameters parameters = _camera.getParameters();
        Size pictureSize = getPictureSize(parameters.getSupportedPictureSizes(), width, height);
        parameters.setPictureSize(pictureSize.width, pictureSize.height);
        Camera.Size previewSize = getOptimalPreviewSize(parameters.getSupportedPreviewSizes(), width, height, pictureSize);
        UpdateTransform(previewSize, width, height);
        parameters.setPreviewSize(previewSize.width, previewSize.height);
        _camera.setDisplayOrientation(getPreviewRotation());
        _camera.setParameters(parameters);
        _camera.startPreview();
    }

    void UpdateTransform(Size previewSize, int width, int height) {

        if (isPortrait()) {
            _previewWidth = previewSize.height;
            _previewHeight = previewSize.width;
        } else {
            _previewWidth = previewSize.width;
            _previewHeight = previewSize.height;
        }

        float scaleX = (float)height / _previewHeight * _previewWidth / width;
        float scaleY = (float)width / _previewWidth * _previewHeight / height;

        if (_shouldFill) {
            scaleX = Math.max(scaleX, 1);
            scaleY = Math.max(scaleY, 1);
        } else {
            scaleX = Math.min(scaleX, 1);
            scaleY = Math.min(scaleY, 1);
        }

        float scaledWidth = width * scaleX;
        float scaledHeight = height * scaleY;
        float dx = (width - scaledWidth) / 2;
        float dy = (height - scaledHeight) / 2;

        Matrix matrix = new Matrix();

        matrix.setScale(scaleX, scaleY);
        matrix.postTranslate(dx, dy);

        setTransform(matrix);
    }

    public String saveParameters() {
        return _camera.getParameters().flatten();
    }

    public void restoreParameters(String str) {
        Camera.Parameters parameters = _camera.getParameters();
        parameters.unflatten(str);
        _camera.setParameters(parameters);
    }

    Size _userPictureSize = null;
    public void setPictureSize(int width, int height) {
        _userPictureSize = _camera.new Size(width, height);
        if (_previewRunning)
            updatePreview(getWidth(), getHeight());
    }

    Size getPictureSize(final List<Size> sizes, int width, int height) {
        if (_userPictureSize != null)
            return _userPictureSize;

        return getOptimalSize(sizes, _maxWidth, _maxHeight, width, height);
    }

    void updateRotation() {
        Camera.Parameters parameters = _camera.getParameters();
        parameters.setRotation(_cameraRotation);
        _camera.setParameters(parameters);
    }

    public void takePicture(final IPictureCallback pictureCallback) {
        final Camera.PictureCallback jpegCallback = new Camera.PictureCallback() {
            public void onPictureTaken(byte[] data, Camera camera) {
                pictureCallback.onPictureTaken(data);
                camera.startPreview();
                resumeFocus();
            }
        };
        try {
            updateRotation();
            if (_autoFocus) {
                _camera.autoFocus(new Camera.AutoFocusCallback() {
                    public void onAutoFocus(boolean success, Camera camera) {
                        try {
                            _camera.takePicture(null, null, null, jpegCallback);
                        } catch (Exception e) {
                            pictureCallback.onError(e);
                        }
                    }
                });
            } else {
                _camera.takePicture(null, null, null, jpegCallback);
            }
        }
        catch(Exception e) {
            pictureCallback.onError(e);
        }
    }

    public void startRecording(IStartRecordingSession startRecordingSession) {
        try {
            updateRotation();
            _camera.unlock();
            startRecordingSession.onSuccess(new RecordingSession(_camera, _cameraRotation));
        } catch (Exception e) {
            _camera.lock();
            startRecordingSession.onException(e.getMessage());
        }
    }

    public void setFlashMode(String flashMode) {
        android.hardware.Camera.Parameters p = _camera.getParameters();
        p.setFlashMode(flashMode);
        _camera.setParameters(p);
    }

    public void setCameraFocusPoint(Double x, Double y, int cameraWidth, int cameraHeight, int isFocusLocked) {

        _camera.cancelAutoFocus();

        android.hardware.Camera.Parameters parameters = _camera.getParameters();

        if (parameters.getMaxNumMeteringAreas() > 0) {

            try {

                List<String> focusModes = parameters.getSupportedFocusModes();

                if (isFocusLocked != 1) {

                    if (focusModes.contains(Camera.Parameters.FOCUS_MODE_MACRO)) {

                        if (focusModes.contains(Camera.Parameters.FOCUS_MODE_AUTO)) {
                            parameters.setFocusMode(Camera.Parameters.FOCUS_MODE_AUTO);
                        }
                    }

                    if (parameters.isAutoExposureLockSupported()) {

                        parameters.setAutoExposureLock(false);
                    }

                    if (parameters.isAutoWhiteBalanceLockSupported()) {

                        parameters.setAutoWhiteBalanceLock(false);
                    }

                    _camera.setParameters(parameters);
                }

                /*
                Get focus coordinates according to camera dimensions and focus area size
                Reference - https://developer.android.com/reference/android/hardware/Camera.Parameters#getFocusAreas%28%29
                - Each focus area is a rectangle with specified weight.
                - Coordinates of the rectangle range from -1000 to 1000
                - (-1000, -1000) is the upper left point.
                - (1000, 1000) is the lower right point.
                - The width and height of focus areas cannot be 0 or negative.
                */
                int focus_area_size = 300;
                int left = clamp(Float.valueOf((float)(x / cameraWidth) * 2000 - 1000).intValue(), focus_area_size);
                int top = clamp(Float.valueOf((float)(y / cameraHeight) * 2000 - 1000).intValue(), focus_area_size);

                Display display = com.fuse.Activity.getRootActivity().getWindowManager().getDefaultDisplay();
                Double tmp;
                Rect rect;
                switch(display.getRotation()) {
                    default: //compiler complains if there's a possibility of rect not being defined
                    case Surface.ROTATION_0: //portrait
                        rect = new Rect(left, top, left + focus_area_size, top + focus_area_size);
                        break;
                    case Surface.ROTATION_90: //landscape right
                        rect = new Rect(top, left, top + focus_area_size, left + focus_area_size);
                        break;
                    case Surface.ROTATION_180: //portrait upsidedown
                        rect = new Rect(top, left, top + focus_area_size, left + focus_area_size);
                        break;
                    case Surface.ROTATION_270: //landscape left
                        rect = new Rect(left, top, left + focus_area_size, top + focus_area_size);
                        break;
                }

                /*
                Reference - https://developer.android.com/reference/android/hardware/Camera.Area
                Camera.Area(rect, weight)
                - rect - Bounds of the area.
                - weight - Weight of the area.
                  The weight must range from 1 to 1000, and represents a weight for every pixel in the area.
                */
                List<Camera.Area> meteringAreas = new ArrayList<Camera.Area>();
                meteringAreas.add(new Camera.Area(rect, 1000));
                parameters.setFocusAreas(meteringAreas);

                if (focusModes.contains(Camera.Parameters.FOCUS_MODE_AUTO)) {
                    parameters.setFocusMode(Camera.Parameters.FOCUS_MODE_AUTO);
                }

                if (parameters.getMinExposureCompensation() != 0
                    && parameters.getMaxExposureCompensation() != 0
                    && parameters.isAutoExposureLockSupported()
                ) {

                    int exposureAmount = (parameters.getMinExposureCompensation() - parameters.getMaxExposureCompensation()) * -1;
                    int designAdjustment = 1; //added 1 to account for a control panel covered area on the bottom of the camera that can't be tapped on for focus
                    if ((y/cameraHeight) < 0.5) { //apply adjustment only if tap is in upper half of camera area
                        designAdjustment = 0;
                    }

                    /*
                    - determine the amount of exposure to apply according to the position of the tap
                    - taps closer to the bottom controls or user are closer so typically require more exposure
                    */
                    int amountApplied = (int)Math.round( (exposureAmount * (y/cameraHeight)) ) + designAdjustment;
                    amountApplied = (amountApplied > exposureAmount) ? exposureAmount : amountApplied;

                    parameters.setExposureCompensation(parameters.getMinExposureCompensation() + amountApplied);

                    parameters.setAutoExposureLock(false);
                }

                _camera.setParameters(parameters);

                //check for lock
                if (isFocusLocked == 1) {

                    if (focusModes.contains(Camera.Parameters.FOCUS_MODE_MACRO)) {
                        parameters.setFocusMode(Camera.Parameters.FOCUS_MODE_MACRO);
                    }

                    if (parameters.isAutoExposureLockSupported()) {

                        parameters.setAutoExposureLock(true);
                    }

                    if (parameters.isAutoWhiteBalanceLockSupported()) {

                        parameters.setAutoWhiteBalanceLock(true);
                    }

                    _camera.setParameters(parameters);

                }

                _autoFocus = false;

                /*
                "shimmy" to make sure focus is set to continously focus on more android devices
                Reference: https://stackoverflow.com/questions/17993751/whats-the-correct-way-to-implement-tap-to-focus-for-camera/23754117#23754117
                */
                _camera.startPreview();

                _camera.autoFocus(new Camera.AutoFocusCallback() {
                    @Override
                    public void onAutoFocus(boolean success, Camera camera) {

                        if (_camera.getParameters().getFocusMode().equals(Camera.Parameters.FOCUS_MODE_CONTINUOUS_PICTURE)) {

                            android.hardware.Camera.Parameters parameters = _camera.getParameters();
                            parameters.setFocusMode(Camera.Parameters.FOCUS_MODE_CONTINUOUS_PICTURE);
                            if (parameters.getMaxNumFocusAreas() > 0) {
                                parameters.setFocusAreas(null);
                            }
                            _camera.setParameters(parameters);
                            _camera.startPreview();
                        }
                    }
                });

            } catch(Exception e) {
                android.util.Log.d(toString(), e.getMessage());
            }
        }
    }

    private int clamp(int touchCoordinateInCameraReper, int focusAreaSize) {

        if (Math.abs(touchCoordinateInCameraReper)+focusAreaSize/2>1000) {

            //return the maximums less the focus area size
            if (touchCoordinateInCameraReper>0) {
                return 1000 - focusAreaSize/2;
            } else {
                return -1000 + focusAreaSize/2;
            }
        } else {
            return touchCoordinateInCameraReper - focusAreaSize/2;
        }
    }

    public void dispose() {
        setSurfaceTextureListener(null);
        _camera.stopPreview();
        _orientationListener.disable();
    }

    static Size getLargestSize(final List<Size> sizes) {
        Camera.Size current = null;
        int largestArea = 0;
        for (Size s : sizes) {
            int area = s.width * s.height;
            if (area > largestArea) {
                largestArea = area;
                current = s;
            }
        }
        return current;
    }

    Size getOptimalPreviewSize(final List<Size> sizes, int width, int height, Size aspectTarget) {
        return getOptimalSize(sizes, width, height, aspectTarget.width, aspectTarget.height);
    }

    static Size getOptimalSize(final List<Size> sizes, int width, int height, int aspectWidth, int aspectHeight) {
        final double aspectTolerance = 0.1;
        final double targetAspect = (double)aspectWidth / aspectHeight;
        final int targetHeight = height;

        Camera.Size optimalSize = null;
        int minHeightDiff = Integer.MAX_VALUE;

        for (Size s : sizes) {
            double aspect = (double)s.width / s.height;
            if (Math.abs(aspect - targetAspect) <= aspectTolerance) {
                int heightDiff = Math.abs(s.height - targetHeight);
                if (heightDiff < minHeightDiff) {
                    optimalSize = s;
                    minHeightDiff = heightDiff;
                }
            }
        }

        if (optimalSize == null) {
            minHeightDiff = Integer.MAX_VALUE;
            for (Size s : sizes) {
                int heightDiff = Math.abs(s.height - targetHeight);
                if (heightDiff < minHeightDiff) {
                    optimalSize = s;
                    minHeightDiff = heightDiff;
                }
            }
        }
        return optimalSize;
    }

    // Logic from https://developer.android.com/reference/android/hardware/Camera.html#setDisplayOrientation(int)
    int getPreviewRotation() {
        Camera.CameraInfo info = new Camera.CameraInfo();
        Camera.getCameraInfo(_cameraId, info);
        int degrees = getDisplayRotationDegrees();
        int result;
        if (info.facing == Camera.CameraInfo.CAMERA_FACING_FRONT) {
            result = (info.orientation + degrees) % 360;
            result = (360 - result) % 360;
        } else {
            result = (info.orientation - degrees + 360) % 360;
        }
        return result;
    }

    static int getDisplayRotationDegrees() {
        int degrees = 0;
        switch (getDisplayOrientation()) {
            case Surface.ROTATION_0: degrees = 0; break;
            case Surface.ROTATION_90: degrees = 90; break;
            case Surface.ROTATION_180: degrees = 180; break;
            case Surface.ROTATION_270: degrees = 270; break;
        }
        return degrees;
    }

    static boolean isPortrait() {
        switch (getDisplayOrientation()) {
            case Surface.ROTATION_0:
            case Surface.ROTATION_180:
                return true;
            case Surface.ROTATION_90:
            case Surface.ROTATION_270:
            default:
                return false;
        }
    }

    static int getDisplayOrientation() {
        return com.fuse.Activity.getRootActivity().getWindowManager().getDefaultDisplay().getRotation();
    }
}