#import <Foundation/Foundation.h>
#include <CoreMotion/CoreMotion.h>

@interface FOMagnetometer : NSObject

@property (nonatomic, readonly, getter=isSensing) BOOL sensing;
@property (nonatomic, copy) void (^_onDataChanged)(CMMagnetometerData* magnetoData);
@property (nonatomic, copy) void (^_onError)(NSError* error);

+ (BOOL)isSensorAvailable;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithBlock:(void (^)(CMMagnetometerData* magnetoData))onDataChanged error:(void (^)(NSError* err))onError;

- (BOOL)startSensing;

- (BOOL)stopSensing;

@end