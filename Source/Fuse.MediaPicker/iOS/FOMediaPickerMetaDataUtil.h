#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
	FOImagePickerMIMETypePNG,
	FOImagePickerMIMETypeJPEG,
	FOImagePickerMIMETypeGIF,
	FOImagePickerMIMETypeOther,
} FOImagePickerMIMEType;

extern NSString *const kFOImagePickerDefaultSuffix;
extern const FOImagePickerMIMEType kFOImagePickerMIMETypeDefault;

@interface FOMediaPickerMetaDataUtil : NSObject

// Retrieve MIME type by reading the image data. We currently only support some popular types.
+ (FOImagePickerMIMEType)getImageMIMETypeFromImageData:(NSData *)imageData;

// Get corresponding surfix from type.
+ (nullable NSString *)imageTypeSuffixFromType:(FOImagePickerMIMEType)type;

+ (NSDictionary *)getMetaDataFromImageData:(NSData *)imageData;

// Creates and returns data for a new image based on imageData, but with the
// given metadata.
//
// If creating a new image fails, returns nil.
+ (nullable NSData *)imageFromImage:(NSData *)imageData withMetaData:(NSDictionary *)metadata;

// Converting UIImage to a NSData with the type proveide.
//
// The quality is for JPEG type only, it defaults to 1. It throws exception if setting a non-nil
// quality with type other than FOImagePickerMIMETypeJPEG. Converting UIImage to
// FOImagePickerMIMETypeGIF or FOImagePickerMIMETypeTIFF is not supported in iOS. This
// method throws exception if trying to do so.
+ (nonnull NSData *)convertImage:(nonnull UIImage *)image
									usingType:(FOImagePickerMIMEType)type
									quality:(nullable NSNumber *)quality;

@end

NS_ASSUME_NONNULL_END
