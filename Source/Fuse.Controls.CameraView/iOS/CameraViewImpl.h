#ifndef CameraView_h
#define CameraView_h

#include <UIKit/UIKit.h>
#include <Foundation/Foundation.h>
#include <AVFoundation/AVFoundation.h>

#include "RecordingSession.h"
#include "CameraPreview.h"

namespace fcv {
	typedef void* disposable_t;

	struct CameraView;

	enum CaptureMode {
		CAPTURE_MODE_PHOTO = 0,
		CAPTURE_MODE_VIDEO = 1,
	};

	enum CaptureState {
		CAPTURE_STATE_IDLE = 0,
		CAPTURE_STATE_CAPTURING_PHOTO = 1,
		CAPTURE_STATE_RECORDING_VIDEO = 2,
	};

	enum CameraFacing {
		CAMERA_FACING_FRONT = 0,
		CAMERA_FACING_BACK = 1,
	};

	enum FlashMode {
		FLASH_MODE_AUTO = AVCaptureFlashModeAuto,
		FLASH_MODE_ON = AVCaptureFlashModeOn,
		FLASH_MODE_OFF = AVCaptureFlashModeOff,
	};

	struct CameraInfo {
		CaptureMode captureMode;
		FlashMode flashMode;
		CameraFacing cameraFacing;
		NSArray<NSNumber*>* supportedFlashModes;
	};

	disposable_t loadCameraView(CameraPreview* cameraPreview, void(^onResolve)(void*), void(^onReject)(NSString*));
	void setCaptureMode(CameraView* cameraView, int captureMode, void(^onResolve)(int), void(^onReject)(NSString*));
	void capturePhoto(CameraView* cameraView, void(^onResolve)(void*,int), void(^onReject)(NSString*));
	void startRecording(CameraView* cameraView, void(^onResolve)(RecordingSession*), void(^onReject)(NSString*));
	void setCameraFacing(CameraView* cameraView, int cameraFacing, void(^onResolve)(int), void(^onReject)(NSString*));
	void setCameraFocusPoint(CameraView* cameraView, double x, double y, int cameraWidth, int cameraHeight, int isFocusLocked, void(^onResolve)(id), void(^onReject)(NSString*));
	void setFlashMode(CameraView* cameraView, int flashMode, void(^onResolve)(int), void(^onReject)(NSString*));
	void getCameraInfo(CameraView* cameraView, void(^callback)(CameraInfo));
	void dispose(disposable_t disposable);
}

#endif