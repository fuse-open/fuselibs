#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "Arguments.h"

typedef void(^Callback)(Arguments*);

@interface ViewHandle : NSObject

@property (readonly) UIView* view;

-(void) setDataJson:(NSString*)json;
-(void) setDataString:(NSString*)value forKey:(NSString*)key;
-(void) setCallback:(Callback)callback forKey:(NSString*)key;

@end