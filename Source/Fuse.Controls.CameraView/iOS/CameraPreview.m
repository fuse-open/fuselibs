#import "CameraPreview.h"

@interface CameraPreview () {
	BOOL _fillView;
}
@end

@implementation CameraPreview

+(Class)layerClass {
	return [AVCaptureVideoPreviewLayer class];
}

-(AVCaptureVideoPreviewLayer*)videoPreviewLayer {
	return (AVCaptureVideoPreviewLayer*)self.layer;
}

-(AVCaptureSession*)session {
	return self.videoPreviewLayer.session;
}

-(void)setSession:(AVCaptureSession*)session {
	self.videoPreviewLayer.session = session;
}

-(void)setFrame:(CGRect)frame {
	[super setFrame:frame];

	if (!self.session)
		return;

	UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;

	if (UIDeviceOrientationIsPortrait(deviceOrientation) ||
		UIDeviceOrientationIsLandscape(deviceOrientation)) {
		self.videoPreviewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)deviceOrientation;
	}
}

-(BOOL)fillView {
	return _fillView;
}

-(void)setFillView:(BOOL)value {
	_fillView = value;
	if (_fillView) {
		self.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	} else {
		self.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
	}
}

@end