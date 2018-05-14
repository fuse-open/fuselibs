package com.fuse.controls.cameraview;

public interface IStartRecordingSession {
    void onSuccess(RecordingSession recordingSession);
    void onException(String message);
}