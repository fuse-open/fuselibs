#import "FOMediaPickerMetaDataUtil.h"
#import <Photos/Photos.h>

static const uint8_t kFirstByteJPEG = 0xFF;
static const uint8_t kFirstBytePNG = 0x89;
static const uint8_t kFirstByteGIF = 0x47;

NSString *const kFOImagePickerDefaultSuffix = @".jpg";
const FOImagePickerMIMEType kFOImagePickerMIMETypeDefault = FOImagePickerMIMETypeJPEG;

@implementation FOMediaPickerMetaDataUtil

+ (FOImagePickerMIMEType)getImageMIMETypeFromImageData:(NSData *)imageData {
	uint8_t firstByte;
	[imageData getBytes:&firstByte length:1];
	switch (firstByte) {
		case kFirstByteJPEG:
			return FOImagePickerMIMETypeJPEG;
		case kFirstBytePNG:
			return FOImagePickerMIMETypePNG;
		case kFirstByteGIF:
			return FOImagePickerMIMETypeGIF;
	}
	return FOImagePickerMIMETypeOther;
}

+ (NSString *)imageTypeSuffixFromType:(FOImagePickerMIMEType)type {
	switch (type) {
		case FOImagePickerMIMETypeJPEG:
			return @".jpg";
		case FOImagePickerMIMETypePNG:
			return @".png";
		case FOImagePickerMIMETypeGIF:
			return @".gif";
		default:
			return nil;
	}
}

+ (NSDictionary *)getMetaDataFromImageData:(NSData *)imageData {
	CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
	NSDictionary *metadata = (NSDictionary *)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source, 0, NULL));
	CFRelease(source);
	return metadata;
}

+ (NSData *)imageFromImage:(NSData *)imageData withMetaData:(NSDictionary *)metadata {
	NSMutableData *targetData = [NSMutableData data];
	CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
	if (source == NULL) {
		return nil;
	}
	CGImageDestinationRef destination = NULL;
	CFStringRef sourceType = CGImageSourceGetType(source);
	if (sourceType != NULL) {
		destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)targetData, sourceType, 1, nil);
	}
	if (destination == NULL) {
		CFRelease(source);
		return nil;
	}
	CGImageDestinationAddImageFromSource(destination, source, 0, (__bridge CFDictionaryRef)metadata);
	CGImageDestinationFinalize(destination);
	CFRelease(source);
	CFRelease(destination);
	return targetData;
}

+ (NSData *)convertImage:(UIImage *)image usingType:(FOImagePickerMIMEType)type quality:(nullable NSNumber *)quality {
	if (quality && type != FOImagePickerMIMETypeJPEG) {
		NSLog(@"media_picker: compressing is not supported for type %@. Returning the image with "
					@"original quality",
					[FOMediaPickerMetaDataUtil imageTypeSuffixFromType:type]);
	}

	switch (type) {
		case FOImagePickerMIMETypeJPEG: {
			CGFloat qualityFloat = (quality != nil) ? quality.floatValue : 1;
			return UIImageJPEGRepresentation(image, qualityFloat);
		}
		case FOImagePickerMIMETypePNG:
			return UIImagePNGRepresentation(image);
		default: {
			// converts to JPEG by default.
			CGFloat qualityFloat = (quality != nil) ? quality.floatValue : 1;
			return UIImageJPEGRepresentation(image, qualityFloat);
		}
	}
}

@end
