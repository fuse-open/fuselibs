#import "FODeviceMotion.h"
#import "FOMotionManager.h"

@interface FODeviceMotion ()

@property (nonatomic, strong) CMMotionManager *motionManager;

@end


@implementation FODeviceMotion

@synthesize _onDataChanged;
@synthesize _onError;

- (instancetype)initWithBlock:(void (^)(CMDeviceMotion* deviceMotionData))onDataChanged error:(void (^)(NSError* err))onError
{
    if (self = [super init])
    {
        self.motionManager = [FOMotionManager sharedMotionManager];
        self.motionManager.accelerometerUpdateInterval = 1.0 / 100.0;  // Convert Hz into interval
        self._onDataChanged = onDataChanged;
        self._onError = onError;
    }
    return self;
}

#pragma mark Sensing

+ (BOOL)isSensorAvailable
{
    return [FOMotionManager sharedMotionManager].isDeviceMotionAvailable;
}

- (BOOL)startSensing
{
    if (![FODeviceMotion isSensorAvailable])
    {
        return NO;
    }
    [self.motionManager startDeviceMotionUpdatesToQueue:[[NSOperationQueue alloc] init]
                                             withHandler:^(CMDeviceMotion  *deviceMotionData, NSError *error) {
                                                 if (error) {
                                                     self._onError(error);
                                                 } else {
                                                     self._onDataChanged(deviceMotionData);
                                                 }
                                             }];
    _sensing = YES;
    return YES;
}

- (BOOL)stopSensing
{
    [self.motionManager stopDeviceMotionUpdates];
    _sensing = NO;
    return YES;
}

@end