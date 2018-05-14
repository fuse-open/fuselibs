#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ViewHandle.h"

@interface ExportedViews : NSObject

+(ViewHandle*)instantiate:(NSString*)templateName;
+(void)initialize:(ViewHandle* (^)(NSString*))templateFactory;

@end
