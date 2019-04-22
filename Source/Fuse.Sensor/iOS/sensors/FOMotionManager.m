#import "FOMotionManager.h"


@implementation FOMotionManager

+ (CMMotionManager *)sharedMotionManager
{
    static CMMotionManager *sharedMotionManager;
    @synchronized(self)
    {
        if (!sharedMotionManager)
        {
            sharedMotionManager = [[CMMotionManager alloc] init];
        }

        return sharedMotionManager;
    }
    return sharedMotionManager;
}

@end