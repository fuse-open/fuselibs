#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import "ImagePicker.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface CameraRollHelper : ImagePicker
+(CameraRollHelper*) instance;
+(void) addNewAssetWithImagePath:(NSString*)imagePath onSuccess:(Action)a onFail:(StringAction)b;
-(void) selectPictureWithCompletionHandler:(StringAction)onComplete onFail:(StringAction)onFail;
@property (atomic, copy) StringAction onCompleteHandler;
@property (atomic, copy) StringAction onFailHandler;
@end