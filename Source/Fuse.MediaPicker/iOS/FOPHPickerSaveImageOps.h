#import <Foundation/Foundation.h>
#import <PhotosUI/PhotosUI.h>

#import "FOMediaPickerImageUtil.h"
#import "FOMediaPickerMetaDataUtil.h"
#import "FOMediaPickerPhotoAssetUtil.h"

@interface FOPHPickerSaveImageOps : NSOperation

- (instancetype)initWithResult:(PHPickerResult *)result
                     maxHeight:(NSNumber *)maxHeight
                      maxWidth:(NSNumber *)maxWidth
           desiredImageQuality:(NSNumber *)desiredImageQuality
                savedPathBlock:(void (^)(NSString *))savedPathBlock API_AVAILABLE(ios(14));

@end
