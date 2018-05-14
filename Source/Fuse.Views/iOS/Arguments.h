#import <Foundation/Foundation.h>

@interface Arguments : NSObject

@property (readonly) NSDictionary<NSString*,NSString*>* args;
@property (readonly) NSString* dataJson;

@end