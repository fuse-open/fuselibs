#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import "ImagePicker.h"


@interface CameraRollHelper : ImagePicker
+(CameraRollHelper*) instance;
+(void) addNewAssetWithImagePath:(NSString*)imagePath onSuccess:(Action)a onFail:(StringAction)b;
-(void) selectPictureWithCompletionHandler:(StringAction)onComplete onFail:(StringAction)onFail;
@property (atomic, copy) StringAction onCompleteHandler;
@property (atomic, copy) StringAction onFailHandler;
@end