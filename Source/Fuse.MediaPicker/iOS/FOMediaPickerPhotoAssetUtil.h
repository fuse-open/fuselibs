#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>

#import "FOMediaPickerImageUtil.h"

NS_ASSUME_NONNULL_BEGIN

@interface FOMediaPickerPhotoAssetUtil : NSObject

+ (nullable PHAsset *)getAssetFromImagePickerInfo:(NSDictionary *)info;

+ (nullable PHAsset *)getAssetFromPHPickerResult:(PHPickerResult *)result API_AVAILABLE(ios(14));

// Save image with correct meta data and extention copied from the original asset.
// maxWidth and maxHeight are used only for GIF images.
+ (NSString *)saveImageWithOriginalImageData:(NSData *)originalImageData
                                       image:(UIImage *)image
                                    maxWidth:(nullable NSNumber *)maxWidth
                                   maxHeight:(nullable NSNumber *)maxHeight
                                imageQuality:(nullable NSNumber *)imageQuality;

// Save image with correct meta data and extention copied from image picker result info.
+ (NSString *)saveImageWithPickerInfo:(nullable NSDictionary *)info
                                image:(UIImage *)image
                         imageQuality:(nullable NSNumber *)imageQuality;

@end

NS_ASSUME_NONNULL_END
