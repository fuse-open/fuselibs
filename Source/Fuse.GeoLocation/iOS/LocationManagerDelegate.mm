#include <iOS/LocationManagerDelegate.h>

@implementation LocationManagerDelegate

@synthesize _onLocationChanged;
@synthesize _onError;
@synthesize _onChangeAuthorizationStatus;

- (id)initWithBlock:(void (^)(CLLocation* location))onLocationChanged error:(void (^)(NSError* err))onError
										 changeAuthorizationStatus:(void (^)(int status))onChangeAuthorizationStatus {
	self = [super init];
	if (self) {
		self._onChangeAuthorizationStatus = onChangeAuthorizationStatus;
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

- (void)locationManager:(CLLocationManager*)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
	_onChangeAuthorizationStatus((int)status);
}

@end
