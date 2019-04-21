#import "FOAccelerometer.h"
#import "FOMotionManager.h"

@interface FOAccelerometer ()

@property (nonatomic, strong) CMMotionManager *motionManager;

@end


@implementation FOAccelerometer

@synthesize _onDataChanged;
@synthesize _onError;

- (instancetype)initWithBlock:(void (^)(CMAccelerometerData* accelerometerData))onDataChanged error:(void (^)(NSError* err))onError
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
    return [FOMotionManager sharedMotionManager].isAccelerometerAvailable;
}

- (BOOL)startSensing
{
    if (![FOAccelerometer isSensorAvailable])
    {
        return NO;
    }
    [self.motionManager startAccelerometerUpdatesToQueue:[[NSOperationQueue alloc] init]
                                             withHandler:^(CMAccelerometerData  *accelerometerData, NSError *error) {
                                                 if (error != nil) {
                                                     self._onError(error);
                                                 } else {
                                                     self._onDataChanged(accelerometerData);
                                                 }
                                             }];
    _sensing = YES;
    return YES;
}

- (BOOL)stopSensing
{
    [self.motionManager stopAccelerometerUpdates];
    _sensing = NO;
    return YES;
}

@end