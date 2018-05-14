#import "UCameraView.h"

@implementation UCameraView

- (void)setFrame:(CGRect)frame 
{
	[super setFrame:frame];

	for(CALayer *layer in self.layer.sublayers)
	{   
		[layer setFrame:frame];
	}
}

- (void)viewDidUnload
{
	[self detachCameras];
	self.captureSession = nil;
}

- (void)dealloc {
	[self detachCameras];
	self.captureSession = nil;
}

// start up a capture session, defaulting to the back camera
-(void) startSession
{
	self.captureSession = [[AVCaptureSession alloc] init];
	self.currentlyInFocus = false;
}

// attach the camera to the capture session
-(void) attachCamera 
{
	[self detachCameras];

	if (self.isBackCamera) 
	{
		self.videoCaptureDevice = [self backCamera];
	}
	else 
	{
		self.videoCaptureDevice = [self frontCamera];
	}

	// add an observe register
	int flags = NSKeyValueObservingOptionNew;
	[self.videoCaptureDevice addObserver:self forKeyPath:@"adjustingFocus" options:flags context:nil];


	NSError *error = nil;
	[self.videoCaptureDevice lockForConfiguration:NULL];
	AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:self.videoCaptureDevice error:&error];
	if (error == nil && videoInput != nil && [self.captureSession canAddInput:videoInput])
	{
		[self.captureSession addInput:videoInput];
	}
	else 
	{
		if (error != nil)
		{
			NSLog(@"Error: %@",[error localizedDescription]);
		}
		NSLog(@"Unable to find video device!");
		return;
	}
	[self.videoCaptureDevice unlockForConfiguration];

	// if we don't have a still image attached, add a new one
	if (self.stillImageOutput == nil)
	{
		self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
		NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
		[self.stillImageOutput setOutputSettings:outputSettings];
		[self.captureSession addOutput:self.stillImageOutput];
	}

	if (self.movieFileOutput == nil)
	{
		self.movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
		[self.captureSession addOutput:self.movieFileOutput];
	}

	// if the session is not currently running, start it up and add it to the layer
	if (!self.captureSession.isRunning)
	{
		AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
		
		[previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
		[self.layer addSublayer:previewLayer];
		[self.layer setMasksToBounds:YES];
		
		[self.captureSession startRunning];
	}

	[self setNeedsUpdateConstraints];
	[self layoutIfNeeded];
}

/* Swap the set camera, then detach + reattach the camera
*/
-(void) swapCamera
{
	self.isBackCamera = !self.isBackCamera;
	[self attachCamera];
}

-(void) setCamera:(bool)isBack
{
	self.isBackCamera = isBack;
	[self attachCamera];
}

-(bool) setFlash:(bool)enableFlash
{
	// This is a case of making things feel nice as opoosed to what is normal. THe idea is that
	// in a dark setting we will use the torch as then you can see what you are taking a picture of
	// as opposed to only being able to see as the flash happens
	[self.videoCaptureDevice lockForConfiguration: nil];
	if (!enableFlash)
	{
		if ([self.videoCaptureDevice isTorchModeSupported:AVCaptureTorchModeOff])
		{
			[self.videoCaptureDevice setTorchMode:AVCaptureTorchModeOff];
			[self.videoCaptureDevice unlockForConfiguration];
		}
		return false;
	}
	else 
	{
		if ([self.videoCaptureDevice isTorchModeSupported:AVCaptureTorchModeOn])
		{
			[self.videoCaptureDevice setTorchMode:AVCaptureTorchModeOn];
			[self.videoCaptureDevice unlockForConfiguration];
			return true;
		}
		return false;
	}
}
/** Make sure that no camera remains attached to the camera capture session
*/
-(void) detachCameras
{
	if (self.videoCaptureDevice != nil) [self.videoCaptureDevice removeObserver:self forKeyPath:@"adjustingFocus"];

	for (AVCaptureInput* input in self.captureSession.inputs) {
		[self.captureSession removeInput:input];
	}

	self.videoCaptureDevice = nil;
}

// listen to all events
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if( [keyPath isEqualToString:@"adjustingFocus"] ){
		// This is how we keep track if we are in focus. This lets us capture an image immediately when it is already in focus
		BOOL adjustingFocus = [ [change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:[NSNumber numberWithInt:1] ];
		self.currentlyInFocus = !adjustingFocus;
		// if we were focusing because we want to take a picture
		if (self.currentlyInFocus && self.wantsToCapture) {
			[self takePicture];
		}
	}
}

-(AVCaptureConnection*) findVideoConnection 
{
	for (AVCaptureConnection *connection in self.stillImageOutput.connections) 
	{
		for (AVCaptureInputPort *port in [connection inputPorts]) 
		{
			if ([[port mediaType] isEqual:AVMediaTypeVideo] ) 
			{
				return connection;
			}
		}
	}

	return nil;
} 

-(void) takePicture
{
	self.wantsToCapture = false;
	
	AVCaptureConnection *videoConnection = [self findVideoConnection];

	[self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
		NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];

		[self imageFromData:imageData onComplete:self.onPictureComplete onFail:self.onPictureFail];
	}];
}

- (UIImage *)flipImage:(UIImage *)image
{
	// This is weird :D see here for the inspiration https://stackoverflow.com/a/24799281/574033
	// Is handling Fuse coordinate system strangeness
	UIGraphicsBeginImageContext(CGSizeMake(image.size.height, image.size.width));
	CGContextDrawImage(UIGraphicsGetCurrentContext(),CGRectMake(0., 0., image.size.height, image.size.width),image.CGImage);
	UIImage *i = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return i;
}

-(void)imageFromData:(NSData*)data onComplete:(StringAction)onComplete onFail:(StringAction)onFail
{
	// this one is interesting. When iOS previews an image it is like you are looking in a mirror.
	// However when you capture it flips it horizontally so it is what someone would see looking at
	// you. This only applies to the front camera
	@try {
		NSString* extension = @"jpg";
		UIImage* newImage = [UIImage imageWithData:data];

		// if we're using the front camera, flip it
		if (!self.isBackCamera)
		{
			UIImage* flippedImage = [self flipImage:newImage];
			NSString* path = [ImageHelper createImagePathWithExtension:extension temp:YES];
			[ImageHelper saveImage:flippedImage path:path];
			onComplete(path);
		}
		else

		{
			NSString* path = [ImageHelper createImagePathWithExtension:extension temp:YES];
			[ImageHelper saveImage:newImage path:path];
			onComplete(path);
		}
	}
	@catch (NSException* e) {
		onFail([NSString stringWithFormat:@"Image load error: %@", e]);
	}
}



/** Capture a picture now with the given callbacks for completion
*/
-(void) captureNow:(StringAction)onComplete onFail:(StringAction)onFail isFullRes:(bool)isFullRes maxTextureSize:(int)maxTextureSize
{
	if (isFullRes)
	{
		// if switching to fullres then give ios time to refocus
		self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
		[NSThread sleepForTimeInterval:0.2f];
	}

	self.onPictureComplete = onComplete;
	self.onPictureFail = onFail;
	self.wantsToCapture = true;

	// This 'if' boils down to 'are we in focus'
	// if focus mode is locked then there is some kind of continuous focus going on so we are ready to go
	// if phasedetection is being used then again we have a different kind of autofocus happening (this
	// also means we wont get the usual focus events)
	if (   self.videoCaptureDevice.focusMode == AVCaptureFocusModeLocked 
		|| self.videoCaptureDevice.activeFormat.autoFocusSystem == AVCaptureAutoFocusSystemPhaseDetection
		|| self.currentlyInFocus
	   ) 
	{
		[self takePicture];
	}
}

/** Start recording, ensuring that recording is stopped prior to starting. 
	Saves the file to a temp location
*/
-(void) startRecording 
{
	// on iOS, must ensure we stop recording before starting again
	if (self.isRecording)
	{
		[self stopRecording];
	}
	self.isRecording = true;

	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *moviePath = [self createVideoPathWithExtension:@".mp4"];
	NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:moviePath];

	[self.movieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
}

/** 
	Stops recording without calling any callbacks
*/
-(void) stopRecording 
{
	self.onVideoComplete = nil;
	self.onVideoFail = nil;
	self.isRecording = false;
	[self.movieFileOutput stopRecording];
}

/**
	Stops recording, registering the two given callbacks for completion
*/
-(void) stopRecording:(StringAction)onComplete onFail:(StringAction)onFail
{
	self.onVideoComplete = onComplete;
	self.onVideoFail = onFail;

	self.isRecording = false;
	[self.movieFileOutput stopRecording];
}

/**
	Get the default front camera
*/
- (AVCaptureDevice *)frontCamera {
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	for (AVCaptureDevice *device in devices) {
		if ([device position] == AVCaptureDevicePositionFront) {
			return device;
		}
	}
	return nil;
}

/**
	Get the default back camera
*/
- (AVCaptureDevice *)backCamera {
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	for (AVCaptureDevice *device in devices) {
		if ([device position] == AVCaptureDevicePositionBack) {
			return device;
		}
	}
	return nil;
}

/**
	Called when a video has been recorded. 
	Here, we call our video callbacks that we registered via `stopRecording`
*/
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput
didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
	  fromConnections:(NSArray *)connections
				error:(NSError *)error
{
	BOOL recordedSuccessfully = YES;
	if ([error code] != noErr)
	{
		// A problem occurred: Find out if the recording was successful.
		id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
		if (value)
		{
			recordedSuccessfully = [value boolValue];
		}
	}
	if (recordedSuccessfully)
	{
		if (self.onVideoComplete != nil)
		{
			self.onVideoComplete([outputFileURL path]);
		}
	} 
	else 
	{
		if (self.onVideoFail != nil)
		{
			self.onVideoFail(@"Failed to save video correctly");
		}
	}
	self.onVideoComplete = nil;
	self.onVideoFail = nil;
}

/** A helper function for creating a temp video path
*/
-(NSString*) createVideoPathWithExtension:(NSString*)extension
{
	NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyyMMdd_HHmmss"];
	NSString* date = [formatter stringFromDate:[NSDate date]];
	return [NSString stringWithFormat:@"%@/VID_%@.%@", [self createVideoPath], date, extension];
}

-(NSString*) createVideoPath
{
	NSString* p = [NSString stringWithFormat:@"%@videos", NSTemporaryDirectory()];
	NSError * error = nil;
	[[NSFileManager defaultManager] createDirectoryAtPath:p withIntermediateDirectories:YES attributes:nil error:&error];
	if (error != nil) {
		NSLog(@"error creating directory: %@", error);
	}
	return p;
}
@end