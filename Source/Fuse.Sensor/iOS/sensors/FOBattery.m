#import "FOBattery.h"

@implementation FOBattery

@synthesize _onDataChanged;
@synthesize _onError;

- (instancetype)initWithBlock:(void (^)(FOBatteryData* batteryData))onDataChanged error:(void (^)(NSError* err))onError
{
    if (self = [super init])
    {
        // Register for battery level and state change notifications.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(batteryLevelChanged:)
                                                     name:UIDeviceBatteryLevelDidChangeNotification object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(batteryStateChanged:)
                                                     name:UIDeviceBatteryStateDidChangeNotification object:nil];

        self._onDataChanged = onDataChanged;
        self._onError = onError;
    }
    return self;
}

#pragma mark Sensing

- (BOOL)startSensing
{
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    _sensing = YES;
    return YES;
}

- (BOOL)stopSensing
{
    [UIDevice currentDevice].batteryMonitoringEnabled = NO;
    _sensing = NO;
    return YES;
}

- (void)batteryLevelChanged:(NSNotification *)notification
{
    FOBatteryData *data = [[FOBatteryData alloc] initWithLevel:[UIDevice currentDevice].batteryLevel
                                                     state:[UIDevice currentDevice].batteryState];

    self._onDataChanged(data);
}

- (void)batteryStateChanged:(NSNotification *)notification
{
    FOBatteryData *data = [[FOBatteryData alloc] initWithLevel:[UIDevice currentDevice].batteryLevel
                                                     state:[UIDevice currentDevice].batteryState];

    self._onDataChanged(data);
}

@end