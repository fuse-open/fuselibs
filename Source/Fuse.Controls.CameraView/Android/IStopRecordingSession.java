package com.fuse.controls.cameraview;

public interface IStopRecordingSession {
    void onSuccess(String outputFilePath);
    void onException(String message);
}