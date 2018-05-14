#import <UIKit/UIKit.h>

#import "ViewHandle.h"

@interface ViewHost : UIView

@property (copy) CGSize (^sizeThatFitsHandler)(CGSize);
@property (copy) void (^setFrameHandler)(CGRect);
@property (copy) void (^inputEventHandler)(id, id);
@property (copy) void (^setDataJsonHandler)(NSString*);
@property (copy) void (^setDataStringHandler)(NSString*,NSString*);
@property (copy) void (^setCallbackHandler)(Callback,NSString*);

@end