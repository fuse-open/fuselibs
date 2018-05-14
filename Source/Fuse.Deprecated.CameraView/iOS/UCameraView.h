#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>	
#import "ImageHelper.h"

@interface UCameraView : UIView <AVCaptureFileOutputRecordingDelegate>

@property (atomic, strong) AVCaptureSession *captureSession;
@property (atomic, strong) AVCaptureStillImageOutput* stillImageOutput;
@property (atomic, strong) AVCaptureMovieFileOutput* movieFileOutput;
@property (atomic, strong) AVCaptureDevice* videoCaptureDevice;
@property bool isBackCamera;
@property bool isRecording;
@property bool currentlyInFocus;
@property (strong) StringAction onVideoComplete;
@property (strong) StringAction onVideoFail;
@property bool wantsToCapture;
@property (strong) StringAction onPictureComplete;
@property (strong) StringAction onPictureFail;

-(void) startSession;
-(void) swapCamera;
-(void) setCamera:(bool)isBackCamera;
-(void) captureNow:(StringAction)onComplete onFail:(StringAction)onFail isFullRes:(bool)isFullRes maxTextureSize:(int)maxTextureSize;
-(void)imageFromData:(NSData*)data
		onComplete:(StringAction)onComplete
		onFail:(StringAction)onFail;
-(void) takePicture;
-(void) attachCamera;
-(void) startRecording;
-(void) stopRecording:(StringAction)onComplete onFail:(StringAction)onFail;
-(bool) setFlash:(bool)enableFlash;
-(AVCaptureConnection*) findVideoConnection;
-(UIImage*)flipImage:(UIImage *)image;


-(NSString*) createVideoPathWithExtension:(NSString*)extension;
- (NSString*) createVideoPath;
@end