#include <iOS/LocationManagerDelegate.h>

@implementation LocationManagerDelegate

@synthesize _onLocationChanged;
@synthesize _onError;

- (id)initWithBlock:(void (^)(CLLocation* location))onLocationChanged error:(void (^)(NSError* err))onError {
	self = [super init];
	if (self) {
		self._onLocationChanged = onLocationChanged;
		self._onError = onError;
	}
	return self;
}

- (void)locationManager:(CLLocationManager*)manager didUpdateLocations:(NSArray*)locations {
	for (CLLocation* location in locations) {
		_onLocationChanged(location);
	}
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager*)manager {
	return NO;
}

- (void)locationManager:(CLLocationManager*)manager didFailWithError:(NSError*)error {
	_onError(error);
}

@end
