#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import "Actions.h"

@interface ImageHelper : NSObject
+(NSArray*)getImageSize:(NSString*)path;
+(NSString*) applicationDocumentsDirectory;
+(NSString*) applicationTempDirectory;
+(UIImage*) correctImageOrientation:(UIImage*)image;
+(UIImage*) imageFromDictionary:(NSDictionary*)dictionary;

+(void)imageFromData:(NSData*)data
		onComplete:(StringAction)onComplete
		onFail:(StringAction)onFail;
		
+(NSString*)imageFromDataSync:(NSData*)data;

+(void)resizeImage:(NSString*)path
		width:(float)desiredWidth
		height:(float)desiredHeight
		mode:(int)mode
		onComplete:(StringAction)onComplete
		onFail:(StringAction)onFail
		performInPlace:(BOOL)inPlace;

+(void)cropImage:(NSString*)path
		desiredRect:(CGRect)rect
		onComplete:(StringAction)onComplete
		onFail:(StringAction)onFail
		performInPlace:(BOOL)inPlace;

+(void)saveImage:(UIImage*)image
		path:(NSString*)path;

+(void) imageFromBase64String:(NSString*)b64
		onComplete:(StringAction)a
		onFail:(StringAction)b;

+(void) base64FromImageAtPath:(NSString*)path
		onComplete:(StringAction)a
		onFail:(StringAction)b;

+(NSString*) createImagePathWithExtension:(NSString*)extension
		temp:(BOOL)temp;

+(NSString*) localPathFromPHImageFileURL:(NSURL*)url
		temp:(BOOL)temp;
@end
