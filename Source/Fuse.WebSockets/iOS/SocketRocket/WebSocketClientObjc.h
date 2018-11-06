#import <Foundation/Foundation.h>

@interface WebSocketClientObjc: NSObject

- (instancetype)initWithUrl:(NSString *)url
				protocols:(NSArray*)protocols
				eventHandler:(void (^)(NSString *, NSString *))eventHandler
				onReceivedMessage:(void (^)(NSString *))receivedMessage
				onReceivedData:(void (^)(uint8_t *, NSUInteger))receivedData;
- (void)sendString:(NSString *) data;
- (void)sendData:(const uint8_t *) data length:(NSUInteger)length;
- (void)connect;
- (void)disconnect;
- (void)setHeaderKey:(NSString *)key withValue:(NSString *)value;

@end
