package com.fuse.android.views;

import android.content.Context;
import android.content.res.AssetManager;
import android.content.res.TypedArray;
import android.graphics.Matrix;
import android.graphics.SurfaceTexture;
import android.media.MediaPlayer;
import android.net.Uri;
import android.os.Build;
import android.util.AttributeSet;
import android.view.Surface;
import android.view.TextureView;

import java.io.FileDescriptor;
import java.io.IOException;
import java.util.Map;


public class VideoView extends TextureView implements TextureView.SurfaceTextureListener,
        MediaPlayer.OnVideoSizeChangedListener {

    protected MediaPlayer mMediaPlayer;
    protected ScalableType mScalableType = ScalableType.NONE;

    public VideoView(Context context) {
        super(context);
        initializeMediaPlayer();
    }

    @Override
    public void onSurfaceTextureAvailable(SurfaceTexture surfaceTexture, int width, int height) {
        Surface surface = new Surface(surfaceTexture);
        if (mMediaPlayer != null) {
            mMediaPlayer.setSurface(surface);
        }
    }

    @Override
    public void onSurfaceTextureSizeChanged(SurfaceTexture surface, int width, int height) {
    }

    @Override
    public boolean onSurfaceTextureDestroyed(SurfaceTexture surface) {
        return false;
    }

    @Override
    public void onSurfaceTextureUpdated(SurfaceTexture surface) {
    }

    @Override
    public void onVideoSizeChanged(MediaPlayer mp, int width, int height) {
        scaleVideoSize(width, height);
    }

    private void scaleVideoSize(int videoWidth, int videoHeight) {
        if (videoWidth == 0 || videoHeight == 0) {
            return;
        }

        Size viewSize = new Size(getWidth(), getHeight());
        Size videoSize = new Size(videoWidth, videoHeight);
        ScaleManager scaleManager = new ScaleManager(viewSize, videoSize);
        Matrix matrix = scaleManager.getScaleMatrix(mScalableType);
        if (matrix != null) {
            setTransform(matrix);
        }
    }

    private void initializeMediaPlayer() {
        if (mMediaPlayer == null) {
            mMediaPlayer = new MediaPlayer();
            mMediaPlayer.setOnVideoSizeChangedListener(this);
            setSurfaceTextureListener(this);
        } else {
            reset();
        }
    }

    public void setDataSource(String path) throws IOException {
        initializeMediaPlayer();
        mMediaPlayer.setDataSource(path);
    }

    public void setDataSource(Context context, Uri uri,
            Map<String, String> headers) throws IOException {
        initializeMediaPlayer();
        mMediaPlayer.setDataSource(context, uri, headers);
    }

    public void setDataSource(Context context, Uri uri) throws IOException {
        initializeMediaPlayer();
        mMediaPlayer.setDataSource(context, uri);
    }

    public void setDataSource (FileDescriptor fd, long offset, long length) throws IOException {
        initializeMediaPlayer();
        mMediaPlayer.setDataSource(fd, offset, length);
    }

    public void setScalableType(ScalableType scalableType) {
        mScalableType = scalableType;
        scaleVideoSize(getVideoWidth(), getVideoHeight());
    }

    public void prepare(MediaPlayer.OnPreparedListener listener)
            throws IOException, IllegalStateException {
        mMediaPlayer.prepare();
    }

    public void prepareAsync(MediaPlayer.OnPreparedListener listener)
            throws IllegalStateException {
        mMediaPlayer.prepareAsync();
    }

    public void prepare() throws IOException, IllegalStateException {
        prepare(null);
    }

    public void prepareAsync() throws IllegalStateException {
        prepareAsync(null);
    }

    public void setOnPreparedListener(MediaPlayer.OnPreparedListener listener) {
        mMediaPlayer.setOnPreparedListener(listener);
    }

    public void setOnErrorListener(MediaPlayer.OnErrorListener listener) {
        mMediaPlayer.setOnErrorListener(listener);
    }

    public void setOnCompletionListener(MediaPlayer.OnCompletionListener listener) {
        mMediaPlayer.setOnCompletionListener(listener);
    }

    public void setOnInfoListener(MediaPlayer.OnInfoListener listener) {
        mMediaPlayer.setOnInfoListener(listener);
    }

    public int getCurrentPosition() {
        return mMediaPlayer.getCurrentPosition();
    }

    public int getDuration() {
        return mMediaPlayer.getDuration();
    }

    public long getPosition() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (mMediaPlayer.getTimestamp() != null)
                return mMediaPlayer.getTimestamp().getAnchorMediaTimeUs() / 1000;
        }
        return 0;
    }

    public int getVideoHeight() {
        return mMediaPlayer.getVideoHeight();
    }

    public int getVideoWidth() {
        return mMediaPlayer.getVideoWidth();
    }

    public boolean isLooping() {
        return mMediaPlayer.isLooping();
    }

    public boolean isPlaying() {
        return mMediaPlayer.isPlaying();
    }

    public void pause() {
        mMediaPlayer.pause();
    }

    public void seekTo(int sec) {
        mMediaPlayer.seekTo(sec);
    }

    public void setLooping(boolean looping) {
        mMediaPlayer.setLooping(looping);
    }

    public void setVolume(float leftVolume, float rightVolume) {
        mMediaPlayer.setVolume(leftVolume, rightVolume);
    }

    public void start() {
        mMediaPlayer.start();
    }

    public void stop() {
        mMediaPlayer.stop();
    }

    public void reset() {
        mMediaPlayer.reset();
    }

    public void release() {
        if (isPlaying()) {
            stop();
        }
        reset();
        mMediaPlayer.release();
        mMediaPlayer = null;
    }

    enum PivotPoint {
        LEFT_TOP,
        LEFT_CENTER,
        LEFT_BOTTOM,
        CENTER_TOP,
        CENTER,
        CENTER_BOTTOM,
        RIGHT_TOP,
        RIGHT_CENTER,
        RIGHT_BOTTOM
    }

    private class Size {

        private int mWidth;
        private int mHeight;

        public Size(int width, int height) {
            mWidth = width;
            mHeight = height;
        }

        public int getWidth() {
            return mWidth;
        }

        public int getHeight() {
            return mHeight;
        }
    }

    private class ScaleManager {

        private Size mViewSize;
        private Size mVideoSize;

        public ScaleManager(Size viewSize, Size videoSize) {
            mViewSize = viewSize;
            mVideoSize = videoSize;
        }

        public Matrix getScaleMatrix(ScalableType scalableType) {
            switch (scalableType) {
                case NONE:
                    return getNoScale();

                case FIT_XY:
                    return fitXY();
                case FIT_CENTER:
                    return fitCenter();
                case FIT_START:
                    return fitStart();
                case FIT_END:
                    return fitEnd();

                case LEFT_TOP:
                    return getOriginalScale(PivotPoint.LEFT_TOP);
                case LEFT_CENTER:
                    return getOriginalScale(PivotPoint.LEFT_CENTER);
                case LEFT_BOTTOM:
                    return getOriginalScale(PivotPoint.LEFT_BOTTOM);
                case CENTER_TOP:
                    return getOriginalScale(PivotPoint.CENTER_TOP);
                case CENTER:
                    return getOriginalScale(PivotPoint.CENTER);
                case CENTER_BOTTOM:
                    return getOriginalScale(PivotPoint.CENTER_BOTTOM);
                case RIGHT_TOP:
                    return getOriginalScale(PivotPoint.RIGHT_TOP);
                case RIGHT_CENTER:
                    return getOriginalScale(PivotPoint.RIGHT_CENTER);
                case RIGHT_BOTTOM:
                    return getOriginalScale(PivotPoint.RIGHT_BOTTOM);

                case LEFT_TOP_CROP:
                    return getCropScale(PivotPoint.LEFT_TOP);
                case LEFT_CENTER_CROP:
                    return getCropScale(PivotPoint.LEFT_CENTER);
                case LEFT_BOTTOM_CROP:
                    return getCropScale(PivotPoint.LEFT_BOTTOM);
                case CENTER_TOP_CROP:
                    return getCropScale(PivotPoint.CENTER_TOP);
                case CENTER_CROP:
                    return getCropScale(PivotPoint.CENTER);
                case CENTER_BOTTOM_CROP:
                    return getCropScale(PivotPoint.CENTER_BOTTOM);
                case RIGHT_TOP_CROP:
                    return getCropScale(PivotPoint.RIGHT_TOP);
                case RIGHT_CENTER_CROP:
                    return getCropScale(PivotPoint.RIGHT_CENTER);
                case RIGHT_BOTTOM_CROP:
                    return getCropScale(PivotPoint.RIGHT_BOTTOM);

                case START_INSIDE:
                    return startInside();
                case CENTER_INSIDE:
                    return centerInside();
                case END_INSIDE:
                    return endInside();

                default:
                    return null;
            }
        }

        private Matrix getMatrix(float sx, float sy, float px, float py) {
            Matrix matrix = new Matrix();
            matrix.setScale(sx, sy, px, py);
            return matrix;
        }

        private Matrix getMatrix(float sx, float sy, PivotPoint pivotPoint) {
            switch (pivotPoint) {
                case LEFT_TOP:
                    return getMatrix(sx, sy, 0, 0);
                case LEFT_CENTER:
                    return getMatrix(sx, sy, 0, mViewSize.getHeight() / 2f);
                case LEFT_BOTTOM:
                    return getMatrix(sx, sy, 0, mViewSize.getHeight());
                case CENTER_TOP:
                    return getMatrix(sx, sy, mViewSize.getWidth() / 2f, 0);
                case CENTER:
                    return getMatrix(sx, sy, mViewSize.getWidth() / 2f, mViewSize.getHeight() / 2f);
                case CENTER_BOTTOM:
                    return getMatrix(sx, sy, mViewSize.getWidth() / 2f, mViewSize.getHeight());
                case RIGHT_TOP:
                    return getMatrix(sx, sy, mViewSize.getWidth(), 0);
                case RIGHT_CENTER:
                    return getMatrix(sx, sy, mViewSize.getWidth(), mViewSize.getHeight() / 2f);
                case RIGHT_BOTTOM:
                    return getMatrix(sx, sy, mViewSize.getWidth(), mViewSize.getHeight());
                default:
                    throw new IllegalArgumentException("Illegal PivotPoint");
            }
        }

        private Matrix getNoScale() {
            float sx = mVideoSize.getWidth() / (float) mViewSize.getWidth();
            float sy = mVideoSize.getHeight() / (float) mViewSize.getHeight();
            return getMatrix(sx, sy, PivotPoint.LEFT_TOP);
        }

        private Matrix getFitScale(PivotPoint pivotPoint) {
            float sx = (float) mViewSize.getWidth() / mVideoSize.getWidth();
            float sy = (float) mViewSize.getHeight() / mVideoSize.getHeight();
            float minScale = Math.min(sx, sy);
            sx = minScale / sx;
            sy = minScale / sy;
            return getMatrix(sx, sy, pivotPoint);
        }

        private Matrix fitXY() {
            return getMatrix(1, 1, PivotPoint.LEFT_TOP);
        }

        private Matrix fitStart() {
            return getFitScale(PivotPoint.LEFT_TOP);
        }

        private Matrix fitCenter() {
            return getFitScale(PivotPoint.CENTER);
        }

        private Matrix fitEnd() {
            return getFitScale(PivotPoint.RIGHT_BOTTOM);
        }

        private Matrix getOriginalScale(PivotPoint pivotPoint) {
            float sx = mVideoSize.getWidth() / (float) mViewSize.getWidth();
            float sy = mVideoSize.getHeight() / (float) mViewSize.getHeight();
            return getMatrix(sx, sy, pivotPoint);
        }

        private Matrix getCropScale(PivotPoint pivotPoint) {
            float sx = (float) mViewSize.getWidth() / mVideoSize.getWidth();
            float sy = (float) mViewSize.getHeight() / mVideoSize.getHeight();
            float maxScale = Math.max(sx, sy);
            sx = maxScale / sx;
            sy = maxScale / sy;
            return getMatrix(sx, sy, pivotPoint);
        }

        private Matrix startInside() {
            if (mVideoSize.getHeight() <= mViewSize.getWidth()
                    && mVideoSize.getHeight() <= mViewSize.getHeight()) {
                return getOriginalScale(PivotPoint.LEFT_TOP);
            } else {
                return fitStart();
            }
        }

        private Matrix centerInside() {
            if (mVideoSize.getHeight() <= mViewSize.getWidth()
                    && mVideoSize.getHeight() <= mViewSize.getHeight()) {
                return getOriginalScale(PivotPoint.CENTER);
            } else {
                return fitCenter();
            }
        }

        private Matrix endInside() {
            if (mVideoSize.getHeight() <= mViewSize.getWidth()
                    && mVideoSize.getHeight() <= mViewSize.getHeight()) {
                return getOriginalScale(PivotPoint.RIGHT_BOTTOM);
            } else {
                return fitEnd();
            }
        }
    }
}