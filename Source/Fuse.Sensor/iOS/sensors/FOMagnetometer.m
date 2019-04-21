#import "FOMagnetometer.h"
#import "FOMotionManager.h"

@interface FOMagnetometer ()

@property (nonatomic, strong) CMMotionManager *motionManager;

@end


@implementation FOMagnetometer

@synthesize _onDataChanged;
@synthesize _onError;

- (instancetype)initWithBlock:(void (^)(CMMagnetometerData* magnetoData))onDataChanged error:(void (^)(NSError* err))onError
{
    if (self = [super init])
    {
        self.motionManager = [FOMotionManager sharedMotionManager];
        self.motionManager.magnetometerUpdateInterval = 1.0 / 100.0;  // Convert Hz into interval
        self._onDataChanged = onDataChanged;
        self._onError = onError;
    }
    return self;
}

#pragma mark Sensing

+ (BOOL)isSensorAvailable
{
    return [FOMotionManager sharedMotionManager].isMagnetometerAvailable;
}

- (BOOL)startSensing
{
    if (![FOMagnetometer isSensorAvailable])
    {
        return NO;
    }
    [self.motionManager startMagnetometerUpdatesToQueue:[[NSOperationQueue alloc] init]
                                             withHandler:^(CMMagnetometerData  *magnetoData, NSError *error) {
                                                 if (error) {
                                                     self._onError(error);
                                                 } else {
                                                     self._onDataChanged(magnetoData);
                                                 }
                                             }];
    _sensing = YES;
    return YES;
}

- (BOOL)stopSensing
{
    [self.motionManager stopMagnetometerUpdates];
    _sensing = NO;
    return YES;
}

@end