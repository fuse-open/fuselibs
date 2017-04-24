#include <CoreLocation/CoreLocation.h>

@interface LocationManagerDelegate : NSObject<CLLocationManagerDelegate>
@property (nonatomic, copy) void (^_onLocationChanged)(CLLocation* location);
@property (nonatomic, copy) void (^_onError)(NSError* location);
- (id)initWithBlock:(void (^)(CLLocation* location))onLocationChanged error:(void (^)(NSError* err))onError;
@end
