#import "FOMediaPickerPhotoAssetUtil.h"
#import "FOMediaPickerImageUtil.h"
#import "FOMediaPickerPhotoAssetUtil.h"
#import "FOMediaPickerMetaDataUtil.h"

#import <MobileCoreServices/MobileCoreServices.h>

@implementation FOMediaPickerPhotoAssetUtil

+ (PHAsset *)getAssetFromImagePickerInfo:(NSDictionary *)info {
	if (@available(iOS 11, *)) {
		return [info objectForKey:UIImagePickerControllerPHAsset];
	}
	NSURL *referenceURL = [info objectForKey:UIImagePickerControllerReferenceURL];
	if (!referenceURL) {
		return nil;
	}
	PHFetchResult<PHAsset *> *result = [PHAsset fetchAssetsWithALAssetURLs:@[referenceURL] options:nil];
	return result.firstObject;
}

+ (PHAsset *)getAssetFromPHPickerResult:(PHPickerResult *)result API_AVAILABLE(ios(14)) {
	PHFetchResult *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[ result.assetIdentifier ] options:nil];
	return fetchResult.firstObject;
}

+ (NSString *)saveImageWithOriginalImageData:(NSData *)originalImageData image:(UIImage *)image
																	maxWidth:(NSNumber *)maxWidth
																	maxHeight:(NSNumber *)maxHeight
																	imageQuality:(NSNumber *)imageQuality {
	NSString *suffix = kFOImagePickerDefaultSuffix;
	FOImagePickerMIMEType type = kFOImagePickerMIMETypeDefault;
	NSDictionary *metaData = nil;
	if (originalImageData) {
		type = [FOMediaPickerMetaDataUtil getImageMIMETypeFromImageData:originalImageData];
		suffix =
				[FOMediaPickerMetaDataUtil imageTypeSuffixFromType:type] ?: kFOImagePickerDefaultSuffix;
		metaData = [FOMediaPickerMetaDataUtil getMetaDataFromImageData:originalImageData];
	}
	return [self saveImageWithMetaData:metaData image:image suffix:suffix type:type imageQuality:imageQuality];
}

+ (NSString *)saveImageWithPickerInfo:(nullable NSDictionary *)info
																image:(UIImage *)image
												 imageQuality:(NSNumber *)imageQuality {
	NSDictionary *metaData = info[UIImagePickerControllerMediaMetadata];
	return [self saveImageWithMetaData:metaData image:image suffix:kFOImagePickerDefaultSuffix type:kFOImagePickerMIMETypeDefault imageQuality:imageQuality];
}

+ (NSString *)saveImageWithMetaData:(NSDictionary *)metaData image:(UIImage *)image suffix:(NSString *)suffix type:(FOImagePickerMIMEType)type imageQuality:(NSNumber *)imageQuality {
	NSData *data = [FOMediaPickerMetaDataUtil convertImage:image usingType:type quality:imageQuality];
	if (metaData) {
		NSData *updatedData = [FOMediaPickerMetaDataUtil imageFromImage:data withMetaData:metaData];
		if (updatedData) {
			data = updatedData;
		}
	}

	return [self createFile:data suffix:suffix];
}

+ (NSString *)temporaryFilePath:(NSString *)suffix {
	NSString *fileExtension = [@"media_picker_%@" stringByAppendingString:suffix];
	NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString];
	NSString *tmpFile = [NSString stringWithFormat:fileExtension, guid];
	NSString *tmpDirectory = NSTemporaryDirectory();
	NSString *tmpPath = [tmpDirectory stringByAppendingPathComponent:tmpFile];
	return tmpPath;
}

+ (NSString *)createFile:(NSData *)data suffix:(NSString *)suffix {
	NSString *tmpPath = [self temporaryFilePath:suffix];
	if ([[NSFileManager defaultManager] createFileAtPath:tmpPath contents:data attributes:nil]) {
		return tmpPath;
	} else {
		nil;
	}
	return tmpPath;
}

@end
