#import "FOPressure.h"

@interface FOPressure ()

@property (nonatomic, strong) CMAltimeter *altemeter;;

@end


@implementation FOPressure

@synthesize _onDataChanged;
@synthesize _onError;

- (instancetype)initWithBlock:(void (^)(CMAltitudeData* altimerData))onDataChanged error:(void (^)(NSError* err))onError
{
    if (self = [super init])
    {
        self.altemeter = [[CMAltimeter alloc] init];
        self._onDataChanged = onDataChanged;
        self._onError = onError;
    }
    return self;
}

#pragma mark Sensing

+ (BOOL)isSensorAvailable
{
    return [CMAltimeter isRelativeAltitudeAvailable];
}

- (BOOL)startSensing
{
    if (![FOPressure isSensorAvailable])
    {
        return NO;
    }
    [self.altemeter startRelativeAltitudeUpdatesToQueue:[[NSOperationQueue alloc] init]
                                             withHandler:^(CMAltitudeData* altimerData, NSError *error) {
                                                 if (error != nil) {
                                                     self._onError(error);
                                                 } else {
                                                     self._onDataChanged(altimerData);
                                                 }
                                             }];
    _sensing = YES;
    return YES;
}

- (BOOL)stopSensing
{
    [self.altemeter stopRelativeAltitudeUpdates];
    _sensing = NO;
    return YES;
}

@end