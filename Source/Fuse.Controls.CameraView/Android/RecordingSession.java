package com.fuse.controls.cameraview;

import android.media.MediaRecorder;
import android.hardware.Camera;
import java.util.UUID;
import java.io.File;
import android.os.Environment;
import java.text.SimpleDateFormat;
import java.util.Date;
import android.media.CamcorderProfile;

public class RecordingSession {

    Camera _camera;
    MediaRecorder _mediaRecorder;
    String _outputFilePath;

    public RecordingSession(Camera camera, int orientationHintDegrees) throws Exception {
        _camera = camera;
        _outputFilePath = makeOutputFilePath();
        _mediaRecorder = new MediaRecorder();
        _mediaRecorder.setCamera(camera);
        _mediaRecorder.setAudioSource(MediaRecorder.AudioSource.CAMCORDER);
        _mediaRecorder.setVideoSource(MediaRecorder.VideoSource.DEFAULT);
        _mediaRecorder.setProfile(CamcorderProfile.get(CamcorderProfile.QUALITY_HIGH));
        _mediaRecorder.setOutputFile(_outputFilePath);
        _mediaRecorder.setOrientationHint(orientationHintDegrees);
        _mediaRecorder.prepare();
        _mediaRecorder.start();
    }

    String makeOutputFilePath() {
        File storageDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES);
        String timeStamp = new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date());
        File videoFile = new File(storageDir.getPath() + File.separator + "VID_" + timeStamp + ".mp4");
        return videoFile.getAbsolutePath();
    }

    public void stop(IStopRecordingSession stopRecordingSession) {
        try {
            _mediaRecorder.stop();
            _mediaRecorder.reset();
            _mediaRecorder.release();
            _camera.lock();
            stopRecordingSession.onSuccess(_outputFilePath);
        } catch(Exception e) {
            stopRecordingSession.onException(e.getMessage());
        }
    }
}