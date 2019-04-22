#import "FOBatteryData.h"

@implementation FOBatteryData

@synthesize _level;
@synthesize _state;

- (instancetype)initWithLevel:(CGFloat)level state:(UIDeviceBatteryState)state
{
    if (self = [super init])
    {
        _level = level;
        _state = state;
    }
    return self;
}

- (NSString *)stateString
{
    switch (_state) {
        case UIDeviceBatteryStateCharging:
            return @"Charging";

        case UIDeviceBatteryStateFull:
            return @"Full";

        case UIDeviceBatteryStateUnplugged:
            return @"Unplugged";

        case UIDeviceBatteryStateUnknown:
            return @"Unknown";

        default:
            NSLog(@"Warning: Unknown state: %d", (int)_state);
            return @"Unknown";
    }
}

@end