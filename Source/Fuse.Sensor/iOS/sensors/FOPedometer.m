#import "FOPedometer.h"
#import "FOMotionManager.h"

@interface FOPedometer ()

@property (nonatomic, strong) CMPedometer *pedometer;

@end


@implementation FOPedometer

@synthesize _onDataChanged;
@synthesize _onError;

- (instancetype)initWithBlock:(void (^)(CMPedometerData* pedometerData))onDataChanged error:(void (^)(NSError* err))onError
{
    if (self = [super init])
    {
        self.pedometer = [[CMPedometer alloc] init];
        self._onDataChanged = onDataChanged;
        self._onError = onError;
    }
    return self;
}

#pragma mark Sensing

+ (BOOL)isSensorAvailable
{
    return [CMPedometer isStepCountingAvailable];
}

- (BOOL)startSensing
{
    if (![FOPedometer isSensorAvailable])
    {
        return NO;
    }
    [self.pedometer startPedometerUpdatesFromDate:[NSDate date]
                                        withHandler:^(CMPedometerData* pedometerData, NSError *error) {
                                             if (error != nil) {
                                                 self._onError(error);
                                             } else {
                                                 self._onDataChanged(pedometerData);
                                             }
                                        }];
    _sensing = YES;
    return YES;
}

- (BOOL)stopSensing
{
    [self.pedometer stopPedometerUpdates];
    _sensing = NO;
    return YES;
}

@end