#import "FOMediaPicker.h"

#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <Photos/Photos.h>
#import <PhotosUI/PHPhotoLibrary+PhotosUISupport.h>
#import <PhotosUI/PhotosUI.h>
#import <UIKit/UIKit.h>

#import "FOMediaPickerImageUtil.h"
#import "FOMediaPickerMetaDataUtil.h"
#import "FOMediaPickerPhotoAssetUtil.h"
#import "FOPHPickerSaveImageOps.h"
#import "Uno-iOS/AppDelegate.h"


@interface FOMediaPicker () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, PHPickerViewControllerDelegate, UIAdaptivePresentationControllerDelegate>

@property(copy, nonatomic) StringAction result;

@property(copy, nonatomic) StringAction error;

@property(assign, nonatomic) int maxImagesAllowed;

@property(copy, nonatomic) NSDictionary *arguments;

@property(strong, nonatomic) PHPickerViewController *pickerViewController API_AVAILABLE(ios(14));

@end

static const int SOURCE_CAMERA = 0;
static const int SOURCE_GALLERY = 1;

typedef NS_ENUM(NSInteger, ImagePickerClassType) { UIImagePickerClassType, PHPickerClassType };

@implementation FOMediaPicker
{
	UIImagePickerController *_imagePickerController;
}

static FOMediaPicker* _instance;

+(FOMediaPicker*) instance
{
	if(_instance == nil) _instance = [[FOMediaPicker alloc] init];
	return _instance;
}

- (UIImagePickerControllerCameraDevice)getCameraDeviceFromArguments:(NSDictionary *)arguments
{
	NSInteger cameraDevice = [[arguments objectForKey:@"cameraDevice"] intValue];
	return (cameraDevice == 1) ? UIImagePickerControllerCameraDeviceFront : UIImagePickerControllerCameraDeviceRear;
}

- (void)pickImageWithPHPicker:(int)maxImagesAllowed API_AVAILABLE(ios(14))
{
	PHPickerConfiguration *config =
			[[PHPickerConfiguration alloc] initWithPhotoLibrary:PHPhotoLibrary.sharedPhotoLibrary];
	config.selectionLimit = maxImagesAllowed;  // Setting to zero allow us to pick unlimited photos
	config.filter = [PHPickerFilter imagesFilter];

	_pickerViewController = [[PHPickerViewController alloc] initWithConfiguration:config];
	_pickerViewController.delegate = self;
	_pickerViewController.presentationController.delegate = self;

	self.maxImagesAllowed = maxImagesAllowed;

	[self checkPhotoAuthorizationForAccessLevel];
}

- (void)pickImageWithUIImagePicker
{
	_imagePickerController = [[UIImagePickerController alloc] init];
	_imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
	_imagePickerController.delegate = self;
	_imagePickerController.mediaTypes = @[ (NSString *)kUTTypeImage ];

	int imageSource = [[_arguments objectForKey:@"source"] intValue];

	self.maxImagesAllowed = 1;

	switch (imageSource) {
		case SOURCE_CAMERA:
			[self checkCameraAuthorization];
			break;
		case SOURCE_GALLERY:
			[self checkPhotoAuthorization];
			break;
	}
}

- (void)pickSingleImageWithArgs:(NSDictionary *)argument withResult:(StringAction)result error:(StringAction)error
{
	_arguments = argument;
	self.result = result;
	self.error = error;
	int imageSource = [[_arguments objectForKey:@"source"] intValue];
	if (imageSource == SOURCE_GALLERY) {  // Capture is not possible with PHPicker
		if (@available(iOS 14, *)) {
			// PHPicker is used
			[self pickImageWithPHPicker:1];
		} else {
			// UIImagePicker is used
			[self pickImageWithUIImagePicker];
		}
	} else {
		[self pickImageWithUIImagePicker];
	}
}

- (void)pickMultiImageWithArgs:(NSDictionary *)argument withResult:(StringAction)result error:(StringAction)error
{
	self.result = result;
	self.error = error;
	_arguments = argument;
	if (@available(iOS 14, *)) {
		int maxImages = [[_arguments objectForKey:@"maxImages"] intValue];
		[self pickImageWithPHPicker:maxImages];
	} else {
		[self pickImageWithUIImagePicker];
	}
}

- (void)pickVideoWithArgs:(NSDictionary *)argument withResult:(StringAction)result error:(StringAction)error
{
	self.result = result;
	self.error = error;
	_arguments = argument;

	_imagePickerController = [[UIImagePickerController alloc] init];
	_imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
	_imagePickerController.delegate = self;
	_imagePickerController.mediaTypes = @[
		(NSString *)kUTTypeMovie, (NSString *)kUTTypeAVIMovie, (NSString *)kUTTypeVideo,
		(NSString *)kUTTypeMPEG4
	];
	_imagePickerController.videoQuality = UIImagePickerControllerQualityTypeHigh;

	int imageSource = [[_arguments objectForKey:@"source"] intValue];
	if ([[_arguments objectForKey:@"maxDuration"] isKindOfClass:[NSNumber class]]) {
		NSTimeInterval max = [[_arguments objectForKey:@"maxDuration"] doubleValue];
		if (max > 0.0) {
			_imagePickerController.allowsEditing = YES;
			_imagePickerController.videoMaximumDuration = max;
		}
	}

	switch (imageSource) {
		case SOURCE_CAMERA:
			[self checkCameraAuthorization];
			break;
		case SOURCE_GALLERY:
			[self checkPhotoAuthorization];
			break;
	}
}

- (void)showCamera
{
	@synchronized(self) {
		if (_imagePickerController.beingPresented) {
			return;
		}
	}
	UIImagePickerControllerCameraDevice device = [self getCameraDeviceFromArguments:_arguments];
	// Camera is not available on simulators
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] &&
			[UIImagePickerController isCameraDeviceAvailable:device]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			self->_imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
            self->_imagePickerController.cameraDevice = device;
			[(uAppDelegate*)[[UIApplication sharedApplication] delegate] presentViewController:self->_imagePickerController animated:YES completion:nil];
		});
	} else {
		dispatch_async(dispatch_get_main_queue(), ^{
			UIAlertController *cameraErrorAlert = [UIAlertController
				alertControllerWithTitle:@"Camera Unvailable" message:@"Camera not available."
									preferredStyle:UIAlertControllerStyleAlert];
			[cameraErrorAlert
				addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}]];
			[(uAppDelegate*)[[UIApplication sharedApplication] delegate]
					presentViewController:cameraErrorAlert animated:YES completion:nil];
		});
		self.result = nil;
		self.error = nil;
		_arguments = nil;
	}
}

- (void)checkCameraAuthorization
{
	AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];

	switch (status) {
		case AVAuthorizationStatusAuthorized:
			[self showCamera];
			break;
		case AVAuthorizationStatusNotDetermined: {
			[AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
															completionHandler:^(BOOL granted) {
																dispatch_async(dispatch_get_main_queue(), ^{
																	if (granted) {
																		[self showCamera];
																	} else {
																		[self errorNoCameraAccess:AVAuthorizationStatusDenied];
																	}
																});
															}];
			break;
		}
		case AVAuthorizationStatusDenied:
		case AVAuthorizationStatusRestricted:
		default:
			[self errorNoCameraAccess:status];
			break;
	}
}

- (void)checkPhotoAuthorization
{
	PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
	switch (status) {
		case PHAuthorizationStatusNotDetermined: {
			[PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
				dispatch_async(dispatch_get_main_queue(), ^{
					if (status == PHAuthorizationStatusAuthorized) {
						[self showPhotoLibrary:UIImagePickerClassType];
					} else {
						[self errorNoPhotoAccess:status];
					}
				});
			}];
			break;
		}
		case PHAuthorizationStatusAuthorized:
			[self showPhotoLibrary:UIImagePickerClassType];
			break;
		case PHAuthorizationStatusDenied:
		case PHAuthorizationStatusRestricted:
		default:
			[self errorNoPhotoAccess:status];
			break;
	}
}

- (void)checkPhotoAuthorizationForAccessLevel API_AVAILABLE(ios(14))
{
	PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
	switch (status) {
		case PHAuthorizationStatusNotDetermined: {
			[PHPhotoLibrary
					requestAuthorizationForAccessLevel:PHAccessLevelReadWrite
																		handler:^(PHAuthorizationStatus status) {
																			dispatch_async(dispatch_get_main_queue(), ^{
																				if (status == PHAuthorizationStatusAuthorized) {
																					[self showPhotoLibrary:PHPickerClassType];
																				} else if (status == PHAuthorizationStatusLimited) {
																					[self showPhotoLibrary:PHPickerClassType];
																				} else {
																					[self errorNoPhotoAccess:status];
																				}
																			});
																		}];
			break;
		}
		case PHAuthorizationStatusAuthorized:
		case PHAuthorizationStatusLimited:
			[self showPhotoLibrary:PHPickerClassType];
			break;
		case PHAuthorizationStatusDenied:
		case PHAuthorizationStatusRestricted:
		default:
			[self errorNoPhotoAccess:status];
			break;
	}
}

- (void)errorNoCameraAccess:(AVAuthorizationStatus)status
{
	switch (status) {
		case AVAuthorizationStatusRestricted:
			self.error(@"The user is not allowed to use the camera.");
			break;
		case AVAuthorizationStatusDenied:
		default:
			self.error(@"The user did not allow camera access.");
			break;
	}
}

- (void)errorNoPhotoAccess:(PHAuthorizationStatus)status
{
	switch (status) {
		case PHAuthorizationStatusRestricted:
			self.error(@"The user is not allowed to use the photo.");
			break;
		case PHAuthorizationStatusDenied:
		default:
			self.error(@"The user did not allow photo access.");
			break;
	}
}

- (void)showPhotoLibrary:(ImagePickerClassType)imagePickerClassType
{
	switch (imagePickerClassType) {
		case PHPickerClassType:
            [(uAppDelegate*)[[UIApplication sharedApplication] delegate]
                presentViewController:_pickerViewController animated:YES completion:nil];
			break;
		case UIImagePickerClassType:
            _imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            [(uAppDelegate*)[[UIApplication sharedApplication] delegate]
                presentViewController:_imagePickerController animated:YES completion:nil];
			break;
	}
}

- (NSNumber *)getDesiredImageQuality:(NSNumber *)imageQuality
{
	if (![imageQuality isKindOfClass:[NSNumber class]]) {
		imageQuality = @1;
	} else if (imageQuality.intValue < 0 || imageQuality.intValue > 100) {
		imageQuality = @1;
	} else {
        imageQuality = [[NSNumber alloc] initWithFloat:[imageQuality floatValue] / 100];
	}
	return imageQuality;
}

- (void)presentationControllerDidDismiss:(UIPresentationController *)presentationController
{
	if (self.result != nil) {
		self.result = nil;
		self.error = nil;
		self->_arguments = nil;
	}
}

- (void)picker:(PHPickerViewController *)picker
		didFinishPicking:(NSArray<PHPickerResult *> *)results API_AVAILABLE(ios(14))
{
	[picker dismissViewControllerAnimated:YES completion:nil];
	if (results.count == 0) {
		if (self.result != nil) {
			self.result = nil;
			self.error = nil;
			self->_arguments = nil;
		}
		return;
	}
	dispatch_queue_t backgroundQueue =
			dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
	dispatch_async(backgroundQueue, ^{
		NSNumber *maxWidth = [self->_arguments objectForKey:@"maxWidth"];
		NSNumber *maxHeight = [self->_arguments objectForKey:@"maxHeight"];
		NSNumber *imageQuality = [self->_arguments objectForKey:@"imageQuality"];
		NSNumber *desiredImageQuality = [self getDesiredImageQuality:imageQuality];
		NSOperationQueue *operationQueue = [NSOperationQueue new];
		NSMutableArray *pathList = [self createNSMutableArrayWithSize:results.count];

		for (int i = 0; i < results.count; i++) {
			PHPickerResult *result = results[i];
			FOPHPickerSaveImageOps *operation =
					[[FOPHPickerSaveImageOps alloc] initWithResult:result maxHeight:maxHeight maxWidth:maxWidth desiredImageQuality:desiredImageQuality
									savedPathBlock:^(NSString *savedPath) {
										pathList[i] = savedPath;
									}];
			[operationQueue addOperation:operation];
		}
		[operationQueue waitUntilAllOperationsAreFinished];
		dispatch_async(dispatch_get_main_queue(), ^{
			[self handleSavedPathList:pathList];
		});
	});
}

- (NSMutableArray *)createNSMutableArrayWithSize:(NSUInteger)size
{
	NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithCapacity:size];
	for (int i = 0; i < size; [mutableArray addObject:[NSNull null]], i++)
		;
	return mutableArray;
}

- (void)imagePickerController:(UIImagePickerController *)picker
		didFinishPickingMediaWithInfo:(NSDictionary<NSString *, id> *)info
{
	NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
	[_imagePickerController dismissViewControllerAnimated:YES completion:nil];
	if (!self.result) {
		return;
	}
	if (videoURL != nil) {
		if (@available(iOS 13.0, *)) {
			NSString *fileName = [videoURL lastPathComponent];
			NSURL *destination = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];

			if ([[NSFileManager defaultManager] isReadableFileAtPath:[videoURL path]]) {
				NSError *error;
				if (![[videoURL path] isEqualToString:[destination path]]) {
					[[NSFileManager defaultManager] copyItemAtURL:videoURL toURL:destination error:&error];

					if (error) {
						self.error(@"Could not cache the video file.");
						self.error = nil;
						return;
					}
				}
				videoURL = destination;
			}
		}
		dispatch_async(dispatch_get_main_queue(), ^{
			[self handleSavedPathList:@[videoURL.path]];
		});
	} else {
		UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
		if (image == nil) {
			image = [info objectForKey:UIImagePickerControllerOriginalImage];
		}
		NSNumber *maxWidth = [_arguments objectForKey:@"maxWidth"];
		NSNumber *maxHeight = [_arguments objectForKey:@"maxHeight"];
		NSNumber *imageQuality = [_arguments objectForKey:@"imageQuality"];
		NSNumber *desiredImageQuality = [self getDesiredImageQuality:imageQuality];

		PHAsset *originalAsset = [FOMediaPickerPhotoAssetUtil getAssetFromImagePickerInfo:info];

		if (maxWidth != (id)[NSNull null] || maxHeight != (id)[NSNull null]) {
			image = [FOMediaPickerImageUtil scaledImage:image maxWidth:maxWidth maxHeight:maxHeight isMetadataAvailable:YES];
		}

		if (!originalAsset) {
			[self saveImageWithPickerInfo:info image:image imageQuality:desiredImageQuality];
		} else {
			[[PHImageManager defaultManager]
					requestImageDataForAsset:originalAsset options:nil
										resultHandler:^(NSData *_Nullable imageData, NSString *_Nullable dataUTI,	UIImageOrientation orientation, NSDictionary *_Nullable info) {
											 // maxWidth and maxHeight are used only for GIF images.
											[self saveImageWithOriginalImageData:imageData image:image maxWidth:maxWidth maxHeight:maxHeight imageQuality:desiredImageQuality];
										}];
		}
	}
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[_imagePickerController dismissViewControllerAnimated:YES completion:nil];
	if (!self.result) {
		return;
	}
	self.result = nil;
	_arguments = nil;
}

- (void)saveImageWithOriginalImageData:(NSData *)originalImageData image:(UIImage *)image maxWidth:(NSNumber *)maxWidth maxHeight:(NSNumber *)maxHeight imageQuality:(NSNumber *)imageQuality
{
	NSString *savedPath = [FOMediaPickerPhotoAssetUtil saveImageWithOriginalImageData:originalImageData image:image maxWidth:maxWidth maxHeight:maxHeight imageQuality:imageQuality];
	[self handleSavedPathList:@[ savedPath ]];
}

- (void)saveImageWithPickerInfo:(NSDictionary *)info image:(UIImage *)image imageQuality:(NSNumber *)imageQuality
{
	NSString *savedPath = [FOMediaPickerPhotoAssetUtil saveImageWithPickerInfo:info image:image imageQuality:imageQuality];
	[self handleSavedPathList:@[ savedPath ]];
}

- (void)handleSavedPathList:(NSArray *)pathList
{
	if (!self.result) {
		return;
	}

	if (pathList) {
		if (![pathList containsObject:[NSNull null]]) {
			if ((self.maxImagesAllowed == 1)) {
				self.result(pathList.firstObject);
			} else {
				self.result([pathList componentsJoinedByString:@","]);
			}
		} else {
			self.error(@"pathList's items should not be null");
		}
	} else {
		// This should never happen.
		self.error(@"pathList should not be nil");
	}
	self.result = nil;
	self.error = nil;
	_arguments = nil;
}

@end
