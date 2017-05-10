#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import "Actions.h"
#import "ImagePicker.h"

@interface CameraHelper : ImagePicker
+(CameraHelper*) instance;
-(void)takePictureWithCompletionHandler:(StringAction)onComplete onFail:(StringAction)onFail;
@property (atomic, copy) StringAction onCompleteHandler;
@property (atomic, copy) StringAction onFailHandler;
@end