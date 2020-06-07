#import "CameraRollHelper.h"
#import "ImageHelper.h"

#pragma clang diagnostic push
#pragma ide diagnostic ignored "UnavailableInDeploymentTarget"
@implementation CameraRollHelper {
}

static CameraRollHelper* _instance;
+(CameraRollHelper*) instance{
	if(_instance == nil) _instance = [[CameraRollHelper alloc] init];
	return _instance;
}

+(void) addNewAssetWithImagePath:(NSString*)imagePath onSuccess:(Action)a onFail:(StringAction)b {

	Action successAction = a;
	StringAction failAction = b;
	NSURL* imageUrl = [NSURL fileURLWithPath:imagePath];
	[[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
		//TODO: Add to named asset collection
		PHAssetChangeRequest *createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:imageUrl];
	} completionHandler:^(BOOL success, NSError *error) {
		if(success) successAction();
		else failAction([error localizedDescription]);
	}];
}

-(void) selectPictureWithCompletionHandler:(StringAction)onComplete onFail:(StringAction)onFail {

	self.onCompleteHandler = onComplete;
	self.onFailHandler = onFail;

	BOOL canPick = [self openImagePickerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary
													then:^(NSDictionary *dictionary) {
														[self handlePictureSelected:dictionary];
													} or:^{
														self.onFailHandler(@"User cancelled");
			}];

	if(!canPick)
	{
		self.onFailHandler(@"Image library not available");
	}
}

-(void) handlePictureSelected:(NSDictionary *)info {

	NSURL* imageUrl = info[@"UIImagePickerControllerReferenceURL"];

	PHFetchResult* result = [PHAsset fetchAssetsWithALAssetURLs:@[imageUrl] options:nil];
	PHAsset* imageInfo = [result firstObject];

	if(imageInfo) {

		UIImage* image = [ImageHelper imageFromDictionary:info];
		image = [ImageHelper correctImageOrientation:image];

		PHImageRequestOptions* imageRequestOptions = [[PHImageRequestOptions alloc] init];

		imageRequestOptions.synchronous = YES;
		@try {
			if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"13.0")) {

				PHContentEditingInputRequestOptions *editOptions = [[PHContentEditingInputRequestOptions alloc] init];

				[imageInfo requestContentEditingInputWithOptions:editOptions completionHandler:^(PHContentEditingInput *contentEditingInput, NSDictionary *info) {

					if (contentEditingInput.fullSizeImageURL) {
						NSURL* path = contentEditingInput.fullSizeImageURL;
						@try {
							NSString* newPath = [ImageHelper localPathFromPHImageFileURL:path temp:YES];
							[ImageHelper saveImage:image path:newPath];
							self.onCompleteHandler(newPath);
						} @catch (NSException *exception) {
							self.onFailHandler([exception reason]);
						}
					}
				}];
			} else {

				[[PHImageManager defaultManager] requestImageDataForAsset:imageInfo options:imageRequestOptions
				resultHandler:^(NSData *imageData, NSString *dataUTI,UIImageOrientation orientation, NSDictionary *info)
					{
						if (info[@"PHImageFileURLKey"]) {

							NSURL* path = info[@"PHImageFileURLKey"];
							@try {

								NSString* newPath = [ImageHelper localPathFromPHImageFileURL:path temp:YES];

								[ImageHelper saveImage:image path:newPath];

								self.onCompleteHandler(newPath);
							} @catch (NSException *exception) {

								self.onFailHandler([exception reason]);
							}
						}
					}
				];

			}
		} @catch (NSException *exception) {

			self.onFailHandler([exception reason]);
		}

	}else{

		self.onFailHandler(@"Picture could not be selected for an unknown reason");
	}
}

@end
#pragma clang diagnostic pop
