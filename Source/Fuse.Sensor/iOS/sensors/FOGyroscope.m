#import "FOGyroscope.h"
#import "FOMotionManager.h"

@interface FOGyroscope ()

@property (nonatomic, strong) CMMotionManager *motionManager;

@end


@implementation FOGyroscope

@synthesize _onDataChanged;
@synthesize _onError;

- (instancetype)initWithBlock:(void (^)(CMGyroData* gyroscopeData))onDataChanged error:(void (^)(NSError* err))onError
{
    if (self = [super init])
    {
        self.motionManager = [FOMotionManager sharedMotionManager];
        self.motionManager.gyroUpdateInterval = 1.0 / 100.0;  // Convert Hz into interval
        self._onDataChanged = onDataChanged;
        self._onError = onError;
    }
    return self;
}

#pragma mark Sensing

+ (BOOL)isSensorAvailable
{
    return [FOMotionManager sharedMotionManager].isGyroAvailable;
}

- (BOOL)startSensing
{
    if (![FOGyroscope isSensorAvailable])
    {
        return NO;
    }
    [self.motionManager startGyroUpdatesToQueue:[[NSOperationQueue alloc] init]
                                             withHandler:^(CMGyroData  *gyroData, NSError *error) {
                                                 if (error) {
                                                     self._onError(error);
                                                 } else {
                                                     self._onDataChanged(gyroData);
                                                 }
                                             }];
    _sensing = YES;
    return YES;
}

- (BOOL)stopSensing
{
    [self.motionManager stopGyroUpdates];
    _sensing = NO;
    return YES;
}

@end