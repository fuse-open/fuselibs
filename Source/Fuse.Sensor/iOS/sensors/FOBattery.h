#import <Foundation/Foundation.h>
#import "FOBatteryData.h"

@interface FOBattery : NSObject

@property (nonatomic, readonly, getter=isSensing) BOOL sensing;
@property (nonatomic, copy) void (^_onDataChanged)(FOBatteryData* batteryData);
@property (nonatomic, copy) void (^_onError)(NSError* error);

- (instancetype)initWithBlock:(void (^)(FOBatteryData* batteryData))onDataChanged error:(void (^)(NSError* err))onError;

- (BOOL)startSensing;

- (BOOL)stopSensing;

@end