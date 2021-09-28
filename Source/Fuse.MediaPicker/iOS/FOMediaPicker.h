#import <PhotosUI/PhotosUI.h>

typedef void (^StringAction)(NSString*);

@interface FOMediaPicker : NSObject

+ (FOMediaPicker*) instance;
- (void)pickSingleImageWithArgs:(NSDictionary *)argument withResult:(StringAction)result error:(StringAction)error;
- (void)pickMultiImageWithArgs:(NSDictionary *)argument withResult:(StringAction)result error:(StringAction)error;
- (void)pickVideoWithArgs:(NSDictionary *)argument withResult:(StringAction)result error:(StringAction)error;

@end
