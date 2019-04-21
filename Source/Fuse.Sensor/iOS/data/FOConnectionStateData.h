#import <Foundation/Foundation.h>

@interface FOConnectionStateData : NSObject

@property (nonatomic, readonly, getter=getStatus) bool _status;

@property (nonatomic, readonly, copy, getter=getStatusString) NSString* _statusString;

- (instancetype)initWithwithState:(bool)state;

@end