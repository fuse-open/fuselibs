#import "CameraHelper.h"
#import "ImageHelper.h"

@implementation CameraHelper {
	UIImagePickerController* _imagePicker;
}

static CameraHelper* _instance;
+(CameraHelper*) instance{
	if(_instance == nil) _instance = [[CameraHelper alloc] init];
	return _instance;
}
-(void) takePictureWithCompletionHandler:(StringAction)onComplete onFail:(StringAction)onFail {
	self.onCompleteHandler = onComplete;
	self.onFailHandler = onFail;
	BOOL canTake = [self openImagePickerWithSourceType:UIImagePickerControllerSourceTypeCamera
								   then:^(NSDictionary *dictionary) {
									   [self handlePictureTaken:dictionary];
								   } or:^{
										self.onFailHandler(@"User cancelled");

			}];
	if(!canTake)
	{
		self.onFailHandler(@"Camera not available");
	}
}

-(void) handlePictureTaken:(NSDictionary*)info {
	NSString* path = [ImageHelper createImagePathWithExtension:@"jpg" temp:YES];
	UIImage* img = [ImageHelper imageFromDictionary:info];
	img = [ImageHelper correctImageOrientation:img];

	[ImageHelper saveImage:img path:path];
	self.onCompleteHandler(path);
}

@end