#include <CoreLocation/CoreLocation.h>

@interface LocationManagerDelegate : NSObject<CLLocationManagerDelegate>
@property (nonatomic, copy) void (^_onLocationChanged)(CLLocation* location);
@property (nonatomic, copy) void (^_onError)(NSError* location);
@property (nonatomic, copy) void (^_onChangeAuthorizationStatus)(int status);
- (id)initWithBlock:(void (^)(CLLocation* location))onLocationChanged error:(void (^)(NSError* err))onError
										 changeAuthorizationStatus:(void (^)(int status))onChangeAuthorizationStatus;
@end
