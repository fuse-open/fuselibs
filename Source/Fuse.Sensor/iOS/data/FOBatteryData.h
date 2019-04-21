#import <Foundation/Foundation.h>
#import <UIKit/UIDevice.h>

@interface FOBatteryData : NSObject

@property (nonatomic, readonly, getter=getLevel) CGFloat _level;

@property (nonatomic, readonly) UIDeviceBatteryState _state;

@property (nonatomic, readonly, copy) NSString *stateString;

- (instancetype)initWithLevel:(CGFloat)level state:(UIDeviceBatteryState)state;

@end