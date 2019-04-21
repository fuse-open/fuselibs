#import <Foundation/Foundation.h>
#include <CoreMotion/CoreMotion.h>

@interface FOMotionManager : NSObject

- (instancetype)init NS_UNAVAILABLE;

+ (CMMotionManager *)sharedMotionManager;

@end