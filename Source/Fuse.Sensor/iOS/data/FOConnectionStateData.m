#import "FOConnectionStateData.h"

@implementation FOConnectionStateData

@synthesize _status;
@synthesize _statusString;

- (instancetype)initWithwithState:(bool)state
{
    if (self = [super init])
    {
        _status = state;
        _statusString = state ? @"connected" : @"disconnected";
    }
    return self;
}

@end