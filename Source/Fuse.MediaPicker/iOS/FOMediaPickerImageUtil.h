#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GIFInfo : NSObject

@property(strong, nonatomic, readonly) NSArray<UIImage *> *images;
@property(assign, nonatomic, readonly) NSTimeInterval interval;

- (instancetype)initWithImages:(NSArray<UIImage *> *)images interval:(NSTimeInterval)interval;

@end

@interface FOMediaPickerImageUtil : NSObject

+ (UIImage *)scaledImage:(UIImage *)image
                maxWidth:(NSNumber *)maxWidth
               maxHeight:(NSNumber *)maxHeight
     isMetadataAvailable:(BOOL)isMetadataAvailable;

@end

NS_ASSUME_NONNULL_END
