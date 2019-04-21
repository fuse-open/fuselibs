#import <Foundation/Foundation.h>
#import "FOReachability.h"
#import "FOConnectionStateData.h"

@interface FOConnection : NSObject

@property (nonatomic, readonly, getter=isSensing) BOOL sensing;
@property (nonatomic, copy) void (^_onDataChanged)(FOConnectionStateData * status);
@property (nonatomic, copy) void (^_onError)(NSError* error);

- (instancetype)initWithBlock:(void (^)(FOConnectionStateData * status))onDataChanged error:(void (^)(NSError* err))onError;

- (BOOL)startSensing;

- (BOOL)stopSensing;

@end