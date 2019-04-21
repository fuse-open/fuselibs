#import "FOConnection.h"

@interface FOConnection ()

@property (nonatomic, strong) FOReachability* reach;

@end

@implementation FOConnection

@synthesize _onDataChanged;
@synthesize _onError;

- (instancetype)initWithBlock:(void (^)(FOConnectionStateData * status))onDataChanged error:(void (^)(NSError* err))onError
{
    if (self = [super init])
    {
        self._onDataChanged = onDataChanged;
        self._onError = onError;
        self.reach = [FOReachability reachabilityWithHostname:@"www.google.com"];
        self.reach.reachableBlock = ^(FOReachability*reach)
        {
            FOConnectionStateData* internetData = [[FOConnectionStateData alloc] initWithwithState:YES];
            self._onDataChanged(internetData);
        };

        self.reach.unreachableBlock = ^(FOReachability*reach)
        {
            FOConnectionStateData* internetData = [[FOConnectionStateData alloc] initWithwithState:NO];
            self._onDataChanged(internetData);
        };
    }
    return self;
}

#pragma mark Sensing

- (BOOL)startSensing
{
    [self.reach startNotifier];
    _sensing = YES;
    return YES;
}

- (BOOL)stopSensing
{
    [self.reach stopNotifier];
    _sensing = NO;
    return YES;
}

@end