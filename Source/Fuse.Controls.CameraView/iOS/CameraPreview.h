#ifndef CAMERAPREVIEW_H
#define CAMERAPREVIEW_H

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface CameraPreview : UIView

@property (nonatomic, readonly) AVCaptureVideoPreviewLayer* videoPreviewLayer;
@property (nonatomic) AVCaptureSession* session;
@property (nonatomic) BOOL fillView;

@end

#endif