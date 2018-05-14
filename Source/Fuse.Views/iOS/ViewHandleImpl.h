#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ViewHandle.h"
#import "ViewHost.h"

@interface ViewHandleImpl : ViewHandle

-(instancetype)initWith:(id)unoObject withViewHost:(ViewHost*)view;

@property (readonly) UIView* view;

@end