#import <Foundation/Foundation.h>

#include "CameraViewImpl.h"

#include <stdlib.h>
#include <ImageIO/ImageIO.h>

namespace fcv {

	dispatch_queue_t cameraDispatch = dispatch_queue_create("sessionQueue", DISPATCH_QUEUE_SERIAL);

	struct AVState {
		CameraPreview* preview;
		AVCaptureSession* session;
		AVCaptureDeviceInput* deviceInput;
		AVCaptureDeviceInput* audioDeviceInput;
		AVCaptureStillImageOutput* imageOutput;
		AVCaptureMovieFileOutput* movieFileOutput;
		RecordingSession* recordingSession;
		dispatch_queue_t queue;
	};

	struct CameraView {
		AVState* avState;
		CaptureMode captureMode;
		CaptureState captureState;
		CameraFacing cameraFacing;
	};

	void dispose(AVState* avState) {
		avState->preview = NULL;
		if (avState->session) {
			if (avState->session.running)
				[avState->session stopRunning];
			avState->session = NULL;
		}
		avState->deviceInput = NULL;
		avState->audioDeviceInput = NULL;
		avState->imageOutput = NULL;
		avState->movieFileOutput = NULL;
		avState->recordingSession = NULL;
		avState->queue = NULL;
		free(avState);
	}

	disposable_t loadCameraView(CameraPreview* cameraPreview, void(^onResolve)(void*), void(^onReject)(NSString*)) {

		AVState* avState = (AVState*)malloc(sizeof(AVState));
		memset(avState, 0, sizeof(AVState));
		avState->preview = cameraPreview;
		avState->session = [[AVCaptureSession alloc] init];
		avState->preview.session = avState->session;
		avState->queue = cameraDispatch;

		CameraView* cameraView = (CameraView*)malloc(sizeof(CameraView));
		memset(cameraView, 0, sizeof(CameraView));
		cameraView->avState = avState;
		cameraView->captureMode = CAPTURE_MODE_PHOTO;
		cameraView->captureState = CAPTURE_STATE_IDLE;

		auto configureSession = ^{
			[avState->session beginConfiguration];
			avState->session.sessionPreset = AVCaptureSessionPresetPhoto;

			CameraFacing cameraFacing = CAMERA_FACING_BACK;

			AVCaptureDevice* backDevice = NULL;
			AVCaptureDevice* frontDevice = NULL;
			for (AVCaptureDevice* device in [AVCaptureDevice devices]) {
				if ([device hasMediaType:AVMediaTypeVideo]) {
					if (device.position == AVCaptureDevicePositionFront) {
						frontDevice = device;
					} else if (device.position == AVCaptureDevicePositionBack) {
						backDevice = device;
					}
				}
			}

			AVCaptureDevice* device;
			if (backDevice) {
				device = backDevice;
			} else if (frontDevice) {
				device = frontDevice;
				cameraFacing = CAMERA_FACING_FRONT;
			} else {
				[avState->session commitConfiguration];
				onReject(@"Failed to find a usable AVCaptureDevice");
				return;
			}

			NSError* error = NULL;
			AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
			if (!input) {;
				[avState->session commitConfiguration];
				onReject([NSString stringWithFormat:@"Could not create video device input: %@", error]);
				dispose(avState);
				return;
			}

			if ([avState->session canAddInput:input] ) {
				[avState->session addInput:input];
				avState->deviceInput = input;

				CameraPreview* preview = avState->preview;
				dispatch_async(dispatch_get_main_queue(), ^{
					UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
					preview.videoPreviewLayer.connection.videoOrientation = (statusBarOrientation != UIInterfaceOrientationUnknown)
						? (AVCaptureVideoOrientation)statusBarOrientation
						: AVCaptureVideoOrientationPortrait;
				});
			} else {
				[avState->session commitConfiguration];
				onReject(@"Could not add video device input to the session");
				dispose(avState);
				return;
			}

			avState->imageOutput = [[AVCaptureStillImageOutput alloc] init];
			if ([avState->session canAddOutput:avState->imageOutput]) {
				[avState->imageOutput setOutputSettings:@{ (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA] }];
				[avState->session addOutput:avState->imageOutput];
			} else {
				[avState->session commitConfiguration];
				onReject(@"Could not add still image output to the session");
				dispose(avState);
				return;
			}

			[avState->session commitConfiguration];
			[avState->session startRunning];

			cameraView->cameraFacing = cameraFacing;

			onResolve(cameraView);
		};

		switch([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo])
		{
			case AVAuthorizationStatusAuthorized:
				dispatch_async(avState->queue, configureSession);
				break;

			case AVAuthorizationStatusNotDetermined: {
				dispatch_queue_t queue = avState->queue;
				dispatch_suspend(queue);
				bool* isPermissionGranted = (bool*)malloc(sizeof(bool));
				*isPermissionGranted = false;
				dispatch_async(queue, ^{
					if (*isPermissionGranted) {
						configureSession();
					} else {
						onReject(@"Permission to camera denied");
					}
					free(isPermissionGranted);
				});
				[AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL permissionGranted) {
					*isPermissionGranted = permissionGranted;
					dispatch_resume(queue);
				}];
				break;
			}
			default:
				// Permission already denied
				onReject(@"Permission to camera denied");
				break;
		}

		return cameraView;
	}


	void setCaptureMode(CameraView* cameraView, int captureMode, void(^onResolve)(int), void(^onReject)(NSString*)) {
		dispatch_async(cameraView->avState->queue, ^{
			if (cameraView->captureState != CAPTURE_STATE_IDLE) {
				onReject(@"Cannot set CaptureMode while recording video or capturing photo");
				return;
			}

			if (cameraView->captureMode == captureMode) {
				onResolve(captureMode);
				return;
			}

			AVState* avState = cameraView->avState;
			[avState->session beginConfiguration];

			if (captureMode == CAPTURE_MODE_VIDEO) {
				NSError* error = nil;
				AVCaptureDevice* audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
				AVCaptureDeviceInput* audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
				if (!audioDeviceInput) {
					NSLog(@"Could not create audio device input: %@", error);
				} else if ([avState->session canAddInput:audioDeviceInput]) {
					[avState->session addInput:audioDeviceInput];
					avState->audioDeviceInput = audioDeviceInput;
				} else {
					NSLog(@"Could not add audio device input to the session");
				}

				AVCaptureMovieFileOutput* movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
				if ([avState->session canAddOutput:movieFileOutput]) {
					[avState->session addOutput:movieFileOutput];
					avState->session.sessionPreset = AVCaptureSessionPresetHigh;

					AVCaptureConnection* connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
					if (connection.isVideoStabilizationSupported) {
						connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
					}
					avState->movieFileOutput = movieFileOutput;
				} else {
					[avState->session commitConfiguration];
					onReject(@"Cannot add AVCaptureMovieFileOutput as an output");
					return;
				}
			} else if (captureMode == CAPTURE_MODE_PHOTO) {
				if (avState->movieFileOutput) {
					[avState->session removeOutput:avState->movieFileOutput];
					avState->movieFileOutput = NULL;
				}
				if (avState->audioDeviceInput) {
					[avState->session removeInput:avState->audioDeviceInput];
					avState->audioDeviceInput = NULL;
				}
				avState->session.sessionPreset = AVCaptureSessionPresetPhoto;
			}
			[avState->session commitConfiguration];
			cameraView->captureMode = (CaptureMode)captureMode;
			onResolve(captureMode);
		});
	}

	void capturePhoto(CameraView* cameraView, void(^onResolve)(void*,int), void(^onReject)(NSString*)) {
		AVState* avState = cameraView->avState;
		AVCaptureVideoOrientation orientation = avState->preview.videoPreviewLayer.connection.videoOrientation;
		dispatch_async(avState->queue, ^{
			if (cameraView->captureState != CAPTURE_STATE_IDLE) {
				onReject(@"Cannot capture photo while capturing photo or recording video");
				return;
			}
			if (cameraView->captureMode != CAPTURE_MODE_PHOTO) {
				onReject(@"Cannot capture photo, CaptureMode not set to Photo");
				return;
			}

			cameraView->captureState = CAPTURE_STATE_CAPTURING_PHOTO;

			// Sucky, but from apples sample code...
			AVCaptureConnection* videoConnection = NULL;
			for (AVCaptureConnection* connection in avState->imageOutput.connections) {
				for (AVCaptureInputPort* port in [connection inputPorts]) {
					if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
						videoConnection = connection;
						break;
					}
				}
				if (videoConnection)
					break;
			}

			// Should not happen
			if (!videoConnection) {
				onReject(@"Cannot find a AVCaptureConnection for image capture");
				return;
			}

			if (videoConnection.supportsVideoOrientation) {
				videoConnection.videoOrientation = orientation;
			}

			[avState->imageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
				cameraView->captureState = CAPTURE_STATE_IDLE;
				if (error) {
					onReject([NSString stringWithFormat:@"Failed to capture photo: %@", error]);
					return;
				}
				int orientation = -1;
				CFDictionaryRef attachments = (CFDictionaryRef)CMCopyDictionaryOfAttachments(kCFAllocatorDefault, imageSampleBuffer, kCMAttachmentMode_ShouldPropagate);;
				if (attachments && CFDictionaryContainsKey(attachments, kCGImagePropertyOrientation)) {
					// EXIF orientation
					auto value = CFDictionaryGetValue(attachments, kCGImagePropertyOrientation);
					if (CFGetTypeID(value) == CFNumberGetTypeID()) {
						orientation = ((__bridge NSNumber*)(CFNumberRef)value).intValue;
					}
				}
				onResolve(imageSampleBuffer, orientation);
				CFRelease(attachments);
			}];
		});
	}

	void startRecording(CameraView* cameraView, void(^onResolve)(RecordingSession*), void(^onReject)(NSString*)) {
		AVState* avState = cameraView->avState;
		AVCaptureVideoOrientation orientation = avState->preview.videoPreviewLayer.connection.videoOrientation;
		dispatch_async(avState->queue, ^{
			if (cameraView->captureState != CAPTURE_STATE_IDLE) {
				onReject(@"Cannot start video recording while capturing photo or recording video");
				return;
			}

			if (cameraView->captureMode != CAPTURE_MODE_VIDEO) {
				onReject(@"Cannot start recording video, CaptureMode not set to Video");
				return;
			}

			cameraView->captureState = CAPTURE_STATE_RECORDING_VIDEO;

			UIBackgroundTaskIdentifier currentBackgroundTaskId = UIBackgroundTaskInvalid;
			if ([UIDevice currentDevice].isMultitaskingSupported) {
				currentBackgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
			}

			AVCaptureConnection* movieFileOutputConnection = [avState->movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
			movieFileOutputConnection.videoOrientation = orientation;

			NSString* outputFileName = [NSUUID UUID].UUIDString;
			NSString* outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[outputFileName stringByAppendingPathExtension:@"mov"]];

			avState->recordingSession = [[RecordingSession alloc] initWithMovieFileOutput:avState->movieFileOutput withCleanupHandler:^(NSURL* outputFileURL) {
				if ([[NSFileManager defaultManager] fileExistsAtPath:outputFileURL.path]) {
					[[NSFileManager defaultManager] removeItemAtPath:outputFileURL.path error:NULL];
				}

				if (currentBackgroundTaskId != UIBackgroundTaskInvalid) {
					[[UIApplication sharedApplication] endBackgroundTask:currentBackgroundTaskId];
				}
				avState->recordingSession = NULL;
				cameraView->captureState = CAPTURE_STATE_IDLE;
			} withDispatchQueue:avState->queue];

			[avState->movieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:outputFilePath] recordingDelegate:avState->recordingSession];
			onResolve(avState->recordingSession);
		});
	}

	void setCameraFacing(CameraView* cameraView, int cameraFacing, void(^onResolve)(int), void(^onReject)(NSString*)) {
		AVState* avState = cameraView->avState;
		dispatch_async(avState->queue, ^{
			if (cameraView->captureState != CAPTURE_STATE_IDLE) {
				onReject(@"Cannot set CameraFacing while capturing photo or video");
				return;
			}

			if (cameraView->cameraFacing == cameraFacing) {
				onResolve(cameraFacing);
				return;
			}

			AVCaptureDevice* currentDevice = avState->deviceInput.device;
			AVCaptureDevicePosition currentPosition = currentDevice.position;

			AVCaptureDevicePosition preferredPosition;

			switch (cameraFacing) {
				case CAMERA_FACING_FRONT:
					preferredPosition = AVCaptureDevicePositionFront;
					break;
				case CAMERA_FACING_BACK:
					preferredPosition = AVCaptureDevicePositionBack;
					break;
			}

			NSArray<AVCaptureDevice*>* devices = [AVCaptureDevice devices];
			AVCaptureDevice* newDevice = nil;

			for (AVCaptureDevice* device in devices) {
				if (device.position == preferredPosition) {
					newDevice = device;
					break;
				}
			}

			if (!newDevice) {
				onReject(@"Could not set camerafacing, facing not supported or not present");
				return;
			}

			AVCaptureDeviceInput* deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:newDevice error:NULL];

			[avState->session beginConfiguration];
			[avState->session removeInput:avState->deviceInput];
			if ([avState->session canAddInput:deviceInput]) {
				[avState->session addInput:deviceInput];
				avState->deviceInput = deviceInput;
			} else {
				[avState->session addInput:avState->deviceInput];
				[avState->session commitConfiguration];
				onReject(@"Could not set cameraFacing, cannot add new facing as session input");
				return;
			}

			if (avState->movieFileOutput) {
				AVCaptureConnection* movieFileOutputConnection = [avState->movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
				if (movieFileOutputConnection.isVideoStabilizationSupported) {
					movieFileOutputConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
				}
			}
			[avState->session commitConfiguration];
			cameraView->cameraFacing = (CameraFacing)cameraFacing;
			onResolve(cameraView->cameraFacing);
		});
	}


	void setCameraFocusPoint(CameraView* cameraView,
		double x, double y, int cameraWidth, int cameraHeight,
		int isFocusLocked,
		void(^onResolve)(id), void(^onReject)(NSString*)) {

		AVState* avState = cameraView->avState;
		dispatch_async(avState->queue, ^{

			AVCaptureDevice* currentDevice = avState->deviceInput.device;

			if(!currentDevice)
				return;

			if([currentDevice isFocusPointOfInterestSupported]
				&& [currentDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]
				&& [currentDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]
				) {

				NSError* error;

				//check to unlock
				if (isFocusLocked != 1 && [currentDevice lockForConfiguration:&error]) {

					[currentDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
					[currentDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
					[currentDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
					[currentDevice unlockForConfiguration];

					[avState->session commitConfiguration];
				}

				if([currentDevice lockForConfiguration:&error]) {
					CGPoint focusPoint;

					float focus_x = x/cameraWidth;
					float focus_y = y/cameraHeight;

					switch([[UIDevice currentDevice] orientation]) {
						case UIDeviceOrientationPortrait:
							focusPoint = CGPointMake(focus_y, 1.f - focus_x);
							break;
						case UIDeviceOrientationPortraitUpsideDown:
							focusPoint = CGPointMake(1.f - focus_y, focus_x);
							break;
						case UIDeviceOrientationLandscapeLeft:
							focusPoint = CGPointMake(focus_y, 1.f - focus_x);
							break;
						case UIDeviceOrientationLandscapeRight:
							focusPoint = CGPointMake(1.f - focus_x, focus_y);
							break;
						default:
							focusPoint = CGPointMake(focus_y, 1.f - focus_x);
							break;
					}

					if ([currentDevice isFocusPointOfInterestSupported]) {
						[currentDevice setFocusPointOfInterest:focusPoint];
					}

					if ([currentDevice isExposurePointOfInterestSupported]) {
						[currentDevice setExposurePointOfInterest:focusPoint];
					}

					[currentDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
					[currentDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
					[currentDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
					[currentDevice unlockForConfiguration];

					[avState->session commitConfiguration];

					if(isFocusLocked == 1 && [currentDevice lockForConfiguration:&error]) {

						[currentDevice setFocusMode:AVCaptureFocusModeLocked];
						[currentDevice setExposureMode:AVCaptureExposureModeLocked];
						[currentDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeLocked];
						[currentDevice unlockForConfiguration];

						[avState->session commitConfiguration];

						onResolve(NULL);
						return;

					} else {
						onResolve(NULL);
						return;
					}
				} else {
					onReject(@"Could not lock for configuration AVCaptureDevice.");
				}
			}
		});
	}

	void setFlashMode(CameraView* cameraView, int flashMode, void(^onResolve)(int), void(^onReject)(NSString*)) {
		AVState* avState = cameraView->avState;
		dispatch_async(avState->queue, ^{
			if (cameraView->captureState != CAPTURE_STATE_IDLE) {
				onReject(@"Cannot set FlashMode while capturing photo or video");
				return;
			}

			AVCaptureDevice* device = avState->deviceInput.device;
			NSError* error = NULL;
			if ([device lockForConfiguration:&error]) {
				if ([device isFlashModeSupported:(AVCaptureFlashMode)flashMode]) {
					[device setFlashMode:(AVCaptureFlashMode)flashMode];
					onResolve(flashMode);
				} else {
					onReject(@"FlashMode not supported");
				}
			} else {
				onReject([NSString stringWithFormat:@"Failed to set flash mode: %@", error]);
			}
		});
	}

	void getCameraInfo(CameraView* cameraView, void(^callback)(CameraInfo)) {
		AVState* avState = cameraView->avState;
		dispatch_async(avState->queue, ^{
			CameraInfo cameraInfo = {};
			memset(&cameraInfo, 0, sizeof(CameraInfo));
			cameraInfo.captureMode = cameraView->captureMode;
			cameraInfo.flashMode = (FlashMode)avState->deviceInput.device.flashMode;
			cameraInfo.cameraFacing = cameraView->cameraFacing;

			NSMutableArray* supportedFlashModes = [[NSMutableArray alloc] init];
			AVCaptureDevice* device = avState->deviceInput.device;
			if ([device isFlashModeSupported:AVCaptureFlashModeAuto])
				[supportedFlashModes addObject:[NSNumber numberWithInt:AVCaptureFlashModeAuto]];

			if ([device isFlashModeSupported:AVCaptureFlashModeOn])
				[supportedFlashModes addObject:[NSNumber numberWithInt:AVCaptureFlashModeOn]];

			if ([device isFlashModeSupported:AVCaptureFlashModeOff])
				[supportedFlashModes addObject:[NSNumber numberWithInt:AVCaptureFlashModeOff]];

			cameraInfo.supportedFlashModes = supportedFlashModes;

			callback(cameraInfo);
		});
	}

	void dispose(disposable_t disposable) {
		CameraView* cameraView = (CameraView*)disposable;
		dispatch_queue_t queue = cameraView->avState->queue;
		dispatch_async(queue, ^{
			dispose(cameraView->avState);
			cameraView->avState = NULL;
			free(cameraView);
		});
	}
}